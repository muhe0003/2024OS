#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>

free_area_t free_area2;

#define free_list (free_area2.free_list)
#define nr_free (free_area2.nr_free)

static size_t total_size;             // 物理区域的总大小
static size_t full_tree_size;         // 完整二叉树的大小
static size_t record_area_size;       // 记录节点信息的页数
static size_t real_tree_size;         // 实际分配的页数
//节点信息区可以用来保存每个节点对应子树中可用空间的信息，用于在分配内存的时候便于检查子树中是否有足够的空间来满足请求大小，在 32 位操作系统中，最大页数不会超过 4GB/4KB=1M，所有使用一个 32 位整数即可表示每个节点的信息
//节点信息区的大小为2^(m)*2*4字节，每页大小为 4KB，内存占用按照页面大小对齐，所以占用 max{1,2^m-9}页
static size_t *record_area;           // 节点信息区
static struct Page *physical_area;    // 物理内存的头指针
static struct Page *allocate_area;    // 分配内存的头指针

//宏定义
#define TREE_ROOT               (1)
    //计算左右子节点、父节点
#define LEFT_CHILD(a)           ((a)<<1)
#define RIGHT_CHILD(a)          (((a)<<1)+1)
#define PARENT(a)               ((a)>>1)
    //计算节点个数
#define NODE_LENGTH(a)          (full_tree_size/POWER_ROUND_DOWN(a))
    //计算节点的起始与结束地址
#define NODE_BEGINNING(a)       (POWER_REMAINDER(a)*NODE_LENGTH(a))      //the head address of a node
#define NODE_ENDDING(a)         ((POWER_REMAINDER(a)+1)*NODE_LENGTH(a))  //the end address of a node
    //计算节点下标
#define BUDDY_BLOCK(a,b)        (full_tree_size/((b)-(a))+(a)/((b)-(a))) //get the index of a node by its address
#define BUDDY_EMPTY(a)          (record_area[(a)] == NODE_LENGTH(a))

#define OR_SHIFT_RIGHT(a,n)     ((a)|((a)>>(n)))   
#define ALL_BIT_TO_ONE(a)       (OR_SHIFT_RIGHT(OR_SHIFT_RIGHT(OR_SHIFT_RIGHT(OR_SHIFT_RIGHT(OR_SHIFT_RIGHT(a,1),2),4),8),16))    
#define POWER_REMAINDER(a)      ((a)&(ALL_BIT_TO_ONE(a)>>1))
    //向上向下取整
#define POWER_ROUND_UP(a)       (POWER_REMAINDER(a)?(((a)-POWER_REMAINDER(a))<<1):(a))
#define POWER_ROUND_DOWN(a)     (POWER_REMAINDER(a)?((a)-POWER_REMAINDER(a)):(a))

static void buddy_init(void) {
    list_init(&free_list);
    nr_free = 0;
}

static void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p;
    for (p = base; p < base + n; p++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
    }
    total_size = n;
    //1.区分页大小小于512还是大于512,也就是说保存信息的页是1还是大于1，分配信息页大小
	if (n < 512) {
		full_tree_size = POWER_ROUND_UP(n-1);
		record_area_size = 1;
	} else {
		full_tree_size = POWER_ROUND_DOWN(n);
		record_area_size = full_tree_size * sizeof(size_t) * 2 / PGSIZE;
		if (n > full_tree_size + (record_area_size << 1)) {
			full_tree_size <<= 1;
			record_area_size <<= 1;
		}
	}
    //计算可分配页的数量
	real_tree_size = (full_tree_size < total_size - record_area_size) ? full_tree_size : total_size - record_area_size;

	physical_area = base;
	record_area = KADDR(page2pa(base));
    //计算实际分配页的地址位置
	allocate_area = base + record_area_size;
	memset(record_area, 0, record_area_size*PGSIZE);

	nr_free += real_tree_size;
	size_t block = TREE_ROOT;
	size_t real_subtree_size = real_tree_size;
	size_t full_subtree_size = full_tree_size;

	record_area[block] = real_subtree_size;//根节点初始化时可分配页数为所有页
	while (real_subtree_size > 0 && real_subtree_size < full_subtree_size) {
        //子节点可分配数减半
		full_subtree_size >>= 1;
		if (real_subtree_size > full_subtree_size) {
			struct Page *page = &allocate_area[NODE_BEGINNING(block)];
			page->property = full_subtree_size;
			list_add(&(free_list), &(page->page_link));
			set_page_ref(page, 0);
			SetPageProperty(page);
			record_area[LEFT_CHILD(block)] = full_subtree_size;
			real_subtree_size -= full_subtree_size;
			record_area[RIGHT_CHILD(block)] = real_subtree_size;
			block = RIGHT_CHILD(block);
		} else {
            //2.由于buddysystem每次需要分配2的整数次幂页，但是内存总页数可能并不对应2的整数次幂， 因此在构建的过程中需要设置一定的虚拟分配区域，也就是说实际不能分配（大于内存大小）的区域需要设置为已经分配
			record_area[LEFT_CHILD(block)] = real_subtree_size;
			record_area[RIGHT_CHILD(block)] = 0;
			block = LEFT_CHILD(block);
		}
	}
    //实际n小于信息页+内存页
	if (real_subtree_size > 0) {
		struct Page *page = &allocate_area[NODE_BEGINNING(block)];
		page->property = real_subtree_size;
		set_page_ref(page, 0);
		SetPageProperty(page);
		list_add(&(free_list), &(page->page_link));
	}
}

static struct Page *buddy_allocate_pages(size_t n) {
    assert(n > 0);
    struct Page *page;
    size_t block = TREE_ROOT;
    //先将请求页向上扩展到2次幂
    size_t length = POWER_ROUND_UP(n);

    //从二叉树的根节点（1号节点）开始查找满足要求的节点
    while (length <= record_area[block] && length < NODE_LENGTH(block)) {
        size_t left = LEFT_CHILD(block);
        size_t right = RIGHT_CHILD(block);
        if (BUDDY_EMPTY(block)) {
            //子树的最大可用空间大于等于请求空间，并且总空间大小等于请求空间，说明这个节点对应的空间没有被分割和分配，并且满足请求空间大小，那么分配这个空间；
            size_t begin = NODE_BEGINNING(block);
            size_t end = NODE_ENDDING(block);
            size_t mid = (begin + end)>>1;
            list_del(&(allocate_area[begin].page_link));
            allocate_area[begin].property >>= 1;
            allocate_area[mid].property = allocate_area[begin].property;
            record_area[left] = record_area[block]>>1;
            record_area[right] = record_area[block]>>1;
            list_add(&free_list,&(allocate_area[begin].page_link));
            list_add(&free_list,&(allocate_area[mid].page_link));
            block = left;
        }
        //如果子树的最大可用空间大于等于请求空间，并且总空间大小大于请求空间，那么在这个节点的子树中查找 
            //如果这个节点对应的空间没有被分割过（最大可用空间等于总空间大小），那么分割空间，在左子树（左半部分）继续查找；
        else if (length & record_area[left])
            block = left;
        else if (length & record_area[right])
            block = right;
        else if (length <= record_area[left])
            block = left;
        else if (length <= record_area[right])
            block = right;
    }
    if (length > record_area[block])
        //子树的最大可用空间小于请求空间，分配失败
        return NULL;
    page = &(allocate_area[NODE_BEGINNING(block)]);
    list_del(&(page->page_link));
    record_area[block] = 0;
    nr_free -= length;
    //3.当一个空间被分配之后，这个空间对应节点的所有父节点的可用空间表都会受到影响，需要自地向上重新更新可用空间信息。
    while (block != TREE_ROOT) {
        block = PARENT(block);
        record_area[block] = record_area[LEFT_CHILD(block)] | record_area[RIGHT_CHILD(block)];
    }
    return page;
}

static void buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    size_t length = POWER_ROUND_UP(n);
    size_t begin = (base - allocate_area);
    size_t end = begin + length;
    size_t block = BUDDY_BLOCK(begin, end);
    //4.释放之前，需要确定要释放的空间对应的节点，然后将空间标记为可用。接下来进行自底向上的操作：
    for (;p != base + n;p++) {
        assert(!PageReserved(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    //将可用页重新加入链表当中
    base->property = length;
    list_add(&free_list,&(base->page_link));
    nr_free += length;
    record_area[block] = length;

    while (block != TREE_ROOT) {
        block = PARENT(block);
        size_t left = LEFT_CHILD(block);
        size_t right = RIGHT_CHILD(block);
        //如果某节点的两个子节点对应的空间都未分割和分配，那么合并这两个空间，形成一个更大的空间；
        if (BUDDY_EMPTY(left) && BUDDY_EMPTY(right)) {
            size_t lbegin = NODE_BEGINNING(left);
            size_t rbegin = NODE_BEGINNING(right);
            list_del(&(allocate_area[lbegin].page_link));
            list_del(&(allocate_area[rbegin].page_link));
            record_area[block] = record_area[left]<<1;
            allocate_area[lbegin].property = record_area[left]<<1;
            list_add(&free_list,&(allocate_area[lbegin].page_link));
        } else
            record_area[block] = record_area[LEFT_CHILD(block)] | record_area[RIGHT_CHILD(block)];
    }
}

static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}

static void alloc_check(void) {
    size_t total_size_store = total_size;
    struct Page *p;
    for (p = physical_area; p < physical_area + 1026; p++)
        SetPageReserved(p);
    buddy_init();
    buddy_init_memmap(physical_area, 1026);

    struct Page *p0, *p1, *p2, *p3;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);
    assert((p3 = alloc_page()) != NULL);

    assert(p0 + 1 == p1);
    assert(p1 + 1 == p2);
    assert(p2 + 1 == p3);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0 && page_ref(p3) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);
    assert(page2pa(p3) < npage * PGSIZE);

    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        p = le2page(le, page_link);
        assert(buddy_allocate_pages(p->property) != NULL);
    }

    assert(alloc_page() == NULL);

    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);

    assert((p1 = alloc_page()) != NULL);
    assert((p0 = alloc_pages(2)) != NULL);
    assert(p0 + 2 == p1);

    assert(alloc_page() == NULL);

    free_pages(p0, 2);
    free_page(p1);
    free_page(p3);

    assert((p = alloc_pages(4)) == p0);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);

    for (p = physical_area; p < physical_area + total_size_store; p++)
        SetPageReserved(p);
    buddy_init();
    buddy_init_memmap(physical_area,total_size_store);

}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_allocate_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = alloc_check,
};
