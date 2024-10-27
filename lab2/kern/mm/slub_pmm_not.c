#include <pmm.h>
#include <list.h>
#include <string.h>
#include <slub_pmm.h>
#include <stdio.h>

#define PAGE_SIZE 4096
#define ALIGN_UP(x, align) (((x) + (align - 1)) & ~(align - 1))

extern free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

// 第一层：基于页大小的内存管理
static void slub_init(void) {
    list_init(&free_list);
    nr_free = 0;
}

static void slub_init_memmap(struct Page *base, size_t n) {
    struct Page *p = base;
    for (; p != base + n; p++) {
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    list_add(&free_list, &(base->page_link));
}

static struct Page *slub_alloc_pages(size_t n) {
    if (n > nr_free) return NULL;

    list_entry_t *le = list_next(&free_list);
    while (le != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            list_del(&p->page_link);
            nr_free -= n;
            if (p->property > n) {
                struct Page *remaining = p + n;
                remaining->property = p->property - n;
                SetPageProperty(remaining);
                list_add_before(le, &(remaining->page_link));
            }
            ClearPageProperty(p);
            return p;
        }
        le = list_next(le);
    }
    return NULL;
}

static void slub_free_pages(struct Page *base, size_t n) {
    struct Page *p = base;
    for (; p != base + n; p++) {
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *page = le2page(le, page_link);
        if (base < page) {
            list_add_before(le, &(base->page_link));
            return;
        }
    }
    list_add(&free_list, &(base->page_link));
}

// 第二层：基于任意大小的内存管理
typedef struct slub_cache {
    size_t obj_size;
    list_entry_t free_objects;
} slub_cache_t;

slub_cache_t create_slub_cache(size_t obj_size) {
    slub_cache_t cache;
    cache.obj_size = ALIGN_UP(obj_size, 8);
    list_init(&cache.free_objects);
    return cache;
}

void *slub_alloc_object(slub_cache_t *cache) {
    if (!list_empty(&cache->free_objects)) {
        list_entry_t *le = list_next(&cache->free_objects);
        list_del(le);
        return le;
    } else {
        struct Page *page = slub_alloc_pages(1);
        if (page == NULL) return NULL;
       
        void *page_mem = (void*)page2pa(page);
        for (size_t offset = 0; offset + cache->obj_size <= PAGE_SIZE; offset += cache->obj_size) {
            void *obj = (char *)page_mem + offset;
            list_add(&cache->free_objects, obj);
        }
       
        return slub_alloc_object(cache);
    }
}

void slub_free_object(slub_cache_t *cache, void *obj) {
    list_add(&cache->free_objects, obj);
}

// 测试检查函数
static void slub_check(void) {
    slub_cache_t cache = create_slub_cache(32);
    void *obj1 = slub_alloc_object(&cache);
    void *obj2 = slub_alloc_object(&cache);
    slub_free_object(&cache, obj1);
    slub_free_object(&cache, obj2);
}


