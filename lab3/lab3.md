### 练习
对实验报告的要求：
 - 基于markdown格式来完成，以文本方式为主
 - 填写各个基本练习中要求完成的报告内容
 - 完成实验后，请分析ucore_lab中提供的参考答案，并请在实验报告中说明你的实现与参考答案的区别
 - 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
 - 列出你认为OS原理中很重要，但在实验中没有对应上的知识点
 
### 练习0：填写已有实验
本实验依赖实验1/2。请把你做的实验1/2的代码填入本实验中代码中有“LAB1”,“LAB2”的注释相应部分。

### 练习1：理解基于FIFO的页面替换算法（思考题）
**函数部分**：
+ `do_pgfault`:发生缺页后，trapFrame传递了badvaddr给do_pgfault()函数，先检查虚拟地址是否可用，如果可用，获取地址对应的页表项，找到pte之后调用函数进行替换。
+ `swap_in`:do_pgfault调用的第一个函数，用于换入页面，首先调用pmm.c中的alloc_page，申请分配物理页，然后调用get_pte找到或者构建对应的页表项，最后调用swapfs_read将数据从磁盘写入内存。
+ `swapfs_read`:用于从磁盘读入数据。
+ `alloc_pages`:调用pmm_manager请求分配物理空间，如果获得的页为空，说明需要换出页，调用swap_out
+ `local_intr_save、local_intr_restore`:在请求物理内存分配前后需要依次调用这两个函数，目的是保证操作的原子性，前者禁用中断，并保存当前的中断状态，后者恢复之前的中断状态。
+ `swap_out`:用于换出页面。首先需要循环调用sm->swap_out_victim，对应于swap_fifo中的_fifo_swap_out_victim。然后调用get_pte获取对应的页表项，将该页面写入磁盘，如果写入成功，释放该页面；如果写入失败，调用_fifo_map_swappable更新FIFO队列。最后刷新TLB。
+ `swap_out_victim`:用于获得需要换出的页面。根据FIFO算法，找到最先进入链表的页，将其地址赋值给ptr_page返回
+ `map_swappable`:将新保存到内存中的页加入可交换页链表末尾
+ `swapfs_write`:用于将页面写入磁盘。
+ `tlb_invalidate`:刷新页表
+ `page_insert`:构建物理地址与虚拟地址的映射，即插入页表项

### 练习2：深入理解不同分页模式的工作原理（思考题）
- sv32，sv39，sv48的区别在于地址表示长度的不同，同时SV32使用2级页表结构，SV39使用3级页表结构，SV48使用4级页表结构，由于sv39是三级页表包括页全局目录（PGD）、中间页目录（PUD）和页表（PT），因此需要进行两次索引，第一段代码处理的是一级页表项（PDE）的创建和映射。它首先检查页全局目录项（PDE）是否有效，如果无效，则分配一个新的物理页，并设置相应的页表项；第二段代码处理的是二级页表项（PTE）的创建和映射。它同样检查页表项是否有效，如果无效，则分配一个新的物理页，并设置相应的页表项。主要区别在于PDX1(la) 和 PDX0(la) 分别用于计算虚拟地址在一级和二级页表中的索引，前者从GiGa Page中查找PDX1的地址，后者中查找PDX1的地址。类似地，PTX(la) 用于计算在页表中的最终页表项索引；相同点在于两段代码都检查页表项的有效性，如果页表项无效，则分配一个新的物理页，并设置页表项的引用计数、清零页面内容、创建页表项，并设置有效和用户位。
- 写法好，因为合并后的函数使得其他代码在调用函数获取页表项时更为简单，不需要关心页表项是否已经存在，只需调用一个函数即可。
### 练习3：给未被映射的地址映射上物理页（需要编程）
 - **设计实现过程**：
    + swap_in(mm,addr,&page)：首先需要根据页表基地址和虚拟地址完成磁盘的读取，写入内存，返回内存中的物理页。
    + page_insert(mm->pgdir,page,addr,perm)：然后完成虚拟地址和内存中物理页的映射。
    + swap_map_swappable(mm,addr,page,0)：最后设置该页面是可交换的。
 - **PDE与PTE潜在用处**:页目录项和页表项中的合法位可以用来判断该页面是否存在，可读可写位用于CLOCK算法或LRU算法。修改位可以决定在换出页面时是否需要写回磁盘。
 - **硬件作用**：
    + 保存当前异常原因，根据stvec的地址跳转到中断处理程序，即trap.c文件中的trap函数。
    + 跳转到exception_handler中的CAUSE_LOAD_ACCESS处理缺页异常。
    + 跳转到pgfault_handler，再到do_pgfault具体处理缺页异常。
    + 处理成功则返回到发生异常处继续执行,否则输出unhandled page fault。
 - **对应关系**:有对应关系，如果一个虚拟地址映射到了一个物理页，那么这个映射关系就会成为页表中的一个页目录项或者页表项，同时一个page可能会对应多个页表项或者页目录项

### 练习4：补充完成Clock页替换算法（需要编程）
通过之前的练习，相信大家对FIFO的页面替换算法有了更深入的了解，现在请在我们给出的框架上，填写代码，实现 Clock页替换算法（mm/swap_clock.c）。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
 - 比较Clock页替换算法和FIFO算法的不同。
 
 
- **代码实现**：

  + 初始化：链表，节点指针，`sm_priv`指针：

    ```c
    list_init(&pra_list_head);
	mm->sm_priv = &pra_list_head;
    curr_ptr = &pra_list_head;
    ```

  + 将页面page插入到页面链表pra_list_head的末尾，并将页面的visited标志置为1，表示该页面已被访问

    ```c
    list_add_before((list_entry_t*) mm->sm_priv,entry);
    page->visited = 1;
    ```

  +遍历页面链表pra_list_head，查找最早未被访问的页面并获取当前页面对应的Page结构指针。如果当前页面已被访问，则将visited置为0，表示该页面已被重新访问；如果没有则重置`visited`，直到找到一个`visited = 0`的页面为止。

    ```c
        curr_ptr = list_next(curr_ptr);
        //check if list is empty
        if(curr_ptr == head) {
            curr_ptr = list_next(curr_ptr);
            if(curr_ptr == head) {
                *ptr_page = NULL;
                break;
            }
        }
        //make list entry a page
        struct Page* page = le2page(curr_ptr, pra_page_link);
        if(page->visited==1) {
            page->visited = 0;
        } else {
            *ptr_page = page;
            list_del(curr_ptr);
            break;
        }
    }
    ```
- **不同：**

  + Clock算法会每次添加新页面到链表尾部，换出页面时都会遍历查找最近没有使用的页面，并且实现简洁，有点类似于LRU。
  + FIFO算法会把将链表当作队列，添加新页面到队尾，换出时直接将队头换出。
### 练习5：阅读代码和实现手册，理解页表映射方式相关知识（思考题）
- 好处：
    + 减少页表项（PTE）数量：由于每个大页覆盖更大的内存区域，因此需要更少的页表项来映射相同的内存空间，这减少了页表的大小。
    + 减少TLB缺失：TLB是CPU缓存，用于快速转换虚拟地址到物理地址。大页减少了页表项的数量，从而增加了TLB缓存这些映射的概率，减少了TLB缺失，提高了内存访问速度。
    + 减少内存访问次数：如果一个进程需要很多个页，那么需要多次访问获取这些页，但是大页访问一次内存即可得到一段较大连续的物理空间
- 坏处：
    + 内存碎片：如果进程没有恰好使用整个大页，那么大页中未使用的部分就会造成内部碎片。在分级页表中，可以通过更小的页来减少这种碎片。
    + 交换开销：如果一个大页中的某些部分很少被访问，而其他部分频繁被访问，那么整个大页都需要被交换到磁盘，这比只交换小页的部分要浪费更多的时间和I/O资源。
    + 增加内存分配的复杂性：对于需要频繁分配和释放内存的应用程序，使用大页可能会增加内存分配的复杂性，因为需要为大页找到合适的内存块。
    + 兼容性问题：并不是所有的操作系统和硬件都支持大页，这可能导致兼容性问题。

### 扩展练习 Challenge：实现不考虑实现开销和效率的LRU页替换算法
- 总体思路：
  LRU的基本思想是将最近最少使用的页面替换出去。在本次实验中，没有相应的硬件支持，我们无法获悉内存页被访问的具体时间，只有当发生pageFault的时候才能够确认。所以在不考虑开销和效率的情况下，可以利用时钟中断。因为内存页被访问时，其PTE_A位会被相应的置位，我们可以借助时钟中断，确认在两次时钟中断期间，哪些页面被进行了访问，进而调整其在置换链表中的位置。理论上，只要时钟中断频率够高，该设计就越近似于LRU。
- 具体流程：
  + 使用页表中的 PTE_A 位来记录一个页面是否在最近的时间内被访问过。
  + 每次访问一个页面时，硬件会自动设置该页面的 PTE_A 位。
  + 使用一个双向链表来记录页面的访问顺序。链表的尾部是最近访问的页面，头部是最久未被访问的页面。
  + 每次页面被访问时，将该页面从链表中移除并移动到链表的尾部。
  + 当内存满且需要加载新页面时，选择链表头部的页面进行替换。
  + 替换后，将新加载的页面插入到链表的尾部。
- 相关代码：
  除了tick_event外均可套用FIFO的代码。
 ```c
  static int
static int
_lru_tick_event(struct mm_struct *mm) {
    list_entry_t *head = (list_entry_t*) mm->sm_priv;
    list_entry_t *cur = head->next;

    assert(head != NULL);

    while (cur != head) {
        struct Page *page = le2page(cur, pra_page_link);
        pte_t *ptep = get_pte(mm->pgdir, page->pra_vaddr, 0);
        if (*ptep & PTE_A) {  // 页面在一段时间内被访问了，拿到最前，置零
            list_entry_t *temp = cur->next;
            list_del(cur);
            *ptep &= ~PTE_A;
            list_add(head, cur);
            cur = temp;
        } else {
            cur = cur->next;
        }
    }

    // 打印链表状态
    cur = head->next;
    cprintf("LRU list after tick event: ");
    while (cur != head) {
        struct Page *page = le2page(cur, pra_page_link);
        cprintf("0x%x ", page->pra_vaddr);
        cur = cur->next;
    }
    cprintf("\n");

    return 0;
}
 ```
- 测试代码：
  ```c
    static int
    _lru_check_swap(void) {
    // 初始化页面状态
    cprintf("Initial page state: d1 c1 b1 a1\n");

    // 假设发生一次时钟中断，导致 LRU
    swap_tick_event(check_mm_struct);
    cprintf("After first tick event: a0 b0 c0 d0\n");
    assert(pgfault_num == 4);  // 初始时已经有4个页面访问

    // 写入页面 c
    cprintf("write Virt Page c in lru_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num == 4);  // 页面 c 已经在内存中，不会导致 page fault

    // 写入页面 a
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 4);  // 页面 a 已经在内存中，不会导致 page fault

    // 写入页面 d
    cprintf("write Virt Page d in lru_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num == 4);  // 页面 d 已经在内存中，不会导致 page fault

    // 写入页面 b
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 4);  // 页面 b 已经在内存中，不会导致 page fault

    // 写入新页面 e
    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num == 5);  // 写入新页面 e，导致一次页面替换

    // 再次写入页面 b
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 5);  // 页面 b 已经在内存中，不会导致 page fault

    // 再次写入页面 a
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 6);  // 页面 a 已经在内存中，但之前被替换出去，再次写入导致一次页面替换

    
    return 0;
}
```
  

### 知识点补充
- **实验整体流程**：整个实验过程以ucore的总控函数init为起点。在初始化阶段，首先调用pmm_init函数完成物理内存的管理初始化。接下来，执行中断和异常相关的初始化工作。调用pic_init函数和idt_init函数，初始化处理器中断控制器（PIC）和中断描述符表（IDT）。随后，调用vmm_init函数进行虚拟内存管理机制的初始化。接下来调用ide_init函数完成对用于页面换入和换出的硬盘的初始化工作。最后，完成整个初始化过程，调用swap_init函数用于初始化页面置换算法，这其中包括Clock页替换算法的相关数据结构和初始化步骤。通过swap_init，ucore确保页面置换算法准备就绪，可以在需要时执行页面换入和换出操作。
- **硬盘模拟**：在QEMU里并没有真正模拟“硬盘”。为了实现“页面置换”的效果，从内核的静态存储(static)区里面分出一块内存， 声称这块存储区域是”硬盘“，然后包裹一下给出”硬盘IO“的接口。实际上，内存和硬盘除了一个掉电后数据易失一个不易失，一个访问快一个访问慢，其实并没有本质的区别。
- **内核映射的实现**：在entry.S里，虽然构造了一个简单映射使得内核能够运行在虚拟空间上，但是这个映射是比较粗糙的。一个程序通常含有下面几段：
    + .text段：存放代码，需要是可读、可执行的，但不可写。
    + .rodata 段：存放只读数据，顾名思义，需要可读，但不可写亦不可执行。
    + .data 段：存放经过初始化的数据，需要可读、可写。
    + .bss段：存放经过零初始化的数据，需要可读、可写。与 .data 段的区别在于由于我们知道它被零初始化，因此在可执行文件中可以只存放该段的开头地址和大小而不用存全为 0的数据。在执行时由操作系统进行处理。
    
    各个段需要的访问权限是不同的。但是现在使用一个大大页(Giga Page)进行映射时，它们都拥有相同的权限，那么在现在的映射下，甚至可以修改内核 .text 段的代码，因为通过一个标志位 W=1 的页表项就可以完成映射，但这显然会带来安全隐患。因此，考虑对这些段分别进行重映射，使得他们的访问权限可以被正确设置。虽然还是每个段都还是映射以同样的偏移量映射到相同的地方，但实现过程需要更加精细。同时最开始已经用特殊方式映射的一个大大页(Giga Page)，为了对这个地址重新进行映射，新建一个页表，在新页表里面完成重映射，然后把satp指向新的页表，这样就实现了重新映射。
- **页替换算法补充说明**：
    + FIFO页替换算法：FIFO 算法只是在应用程序按线性顺序访问地址空间时效果才好，否则效率不高。因为那些常被访问的页，往往在内存中也停留得最久，结果它们因变“老”而不得不被置换出去。FIFO 算法的另一个缺点是，它有一种异常现象（Belady 现象），即在增加放置页的物理页帧的情况下，反而使页访问异常次数增多。
    + CLOCK算法：该算法近似地体现了 LRU 的思想，且易于实现，开销少，需要硬件支持来设置访问位。时钟页替换算法在本质上与 FIFO 算法是类似的，不同之处是在时钟页替换算法中跳过了访问位为 1 的页。
    + 改进的时钟页替换算法：该算法不但希望淘汰的页面是最近未使用的页，而且还希望被淘汰的页是在主存驻留期间其页面内容未被修改过的。这需要为每一页的对应页表项内容中增加一位引用位和一位修改位。当该页被访问时，CPU 中的 MMU 硬件将把访问位置“1”。当该页被“写”时，CPU 中的 MMU 硬件将把修改位置“1”。这样这两位就存在四种可能的组合情况：（0，0）表示最近未被引用也未被修改，首先选择此页淘汰；（0，1）最近未被使用，但被修改，其次选择；（1，0）最近使用而未修改，再次选择；（1，1）最近使用且修改，最后选择。该算法与时钟算法相比，可进一步减少磁盘的 I/O 操作次数，但为了查找到一个尽可能适合淘汰的页面，可能需要经过多次扫描，增加了算法本身的执行开销。




