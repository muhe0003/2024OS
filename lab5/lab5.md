<h1><center>lab5：用户程序</center></h1>

## 练习0：

+ 为了实现用户进程切换，观察proc.c中的proc_struct结构发现新增了三个指向其他进程的指针，分别是cptr、optr、yptr、在`alloc_proc`中初始化这些指针：

  ```c
    proc->wait_state = 0;  // 进程等待状态初始化为0
    proc->cptr = proc->yptr = proc->optr = NULL;  // 进程间指针初始化为NULL
  ```

+ 在`do_fork`中修改代码如下，相比实验四新增将子进程的父进程设置为当前进程，同时在最后将进程插入列表当中，并设置进程的关联关系：

  ```c
    //    1. call alloc_proc to allocate a proc_struct
    if((proc = alloc_proc()) == NULL){
        goto fork_out;
    }

    // set child proc's parent to current process
    proc->parent = current;
    // make sure current process's wait_state is 0
    assert(current->wait_state == 0);

    //    2. call setup_kstack to allocate a kernel stack for child process
    if(setup_kstack(proc) != 0){
        goto bad_fork_cleanup_proc;  // 释放刚刚alloc的proc_struct
    }
    //    3. call copy_mm to dup OR share mm according clone_flag
    if(copy_mm(clone_flags, proc) != 0){
        goto bad_fork_cleanup_kstack;  // 释放刚刚setup的kstack
    }
    //    4. call copy_thread to setup tf & context in proc_struct
    copy_thread(proc, stack, tf);  // 复制trapframe，设置context

    //    5. insert proc_struct into hash_list && proc_list
    // insert proc_struct into hash_list && proc_list, set the relation links of process
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        proc->pid = get_pid();
        hash_proc(proc);  // 插入hash_list
        set_links(proc);  // 设置进程间的关系
    }
    local_intr_restore(intr_flag)
    // set_links里已经做了
    //list_add(&proc_list, &(proc->list_link));  // 插入proc_list
    //nr_process ++;

    //    6. call wakeup_proc to make the new child process RUNNABLE
    wakeup_proc(proc);  // 设置为RUNNABLE!!
    //    7. set ret vaule using child proc's pid
    return proc->pid;
  ```

## 练习1：

### 代码

设置`trapframe`的`sp`为用户态栈顶，`epc`也就是下一条可执行指令设置为elf的入口地址，`sstatus`的`SPP`位清零，表示U mode下触发异常，之后需要返回用户态；`SPIE`位清零，表示不启用中断。

```c
    tf->gpr.sp = USTACKTOP;  // 用户栈顶
    tf->epc = elf->e_entry;  // 用户程序入口
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP & ~SSTATUS_SPIE);  // 用户态
```

### 执行过程

1. 在`init_main`中调用`kernel_thread`，该函数调用`do_fork`创建并唤醒线程，使其执行函数`user_main`
2. 在`user_main`中通过宏`KERNEL_EXECVE`，调用`kernel_execve`
3. 在`kernel_execve`中执行`ebreak`，发生断点异常，转到`__alltraps`，转到`trap`，再到`trap_dispatch`，然后到`exception_handler`，最后到`CAUSE_BREAKPOINT`处调用`syscall`
5. 在`syscall`中根据参数，确定执行`sys_exec`，调用`do_execve`，再调用`load_icode`，加载elf格式的二进制代码
7. 加载完后返回`__alltraps`的末尾，接着执行`__trapret`后的内容，到`sret`，表示退出S态回到用户态

## 练习2：

### 代码

首先获取源地址和目的地址对应的内核虚拟地址，然后复制后的页插入到页表中。具体来说就是首先使用page2kva拿到两个page的虚拟地址，然后调用memcpy将父进程的内存空间复制给子进程，最后通过page_insert在子进程的页表中建立映射关系。

```c
        void* src_kvaddr = page2kva(page);
        void* dst_kvaddr = page2kva(npage);
        memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
        ret = page_insert(to, npage, start, perm);
```

####  设计并实现COW机制（含challenge）
- **如何设计实现 Copy on Write 机制？** 给出概要设计，鼓励给出详细设计。

> **Copy-on-write (简称COW)** 的基本概念是：如果有多个使用者对一个资源A（比如内存块）进行读操作，则每个使用者只需获得一个指向同一个资源A的指针，就可以该资源。若某使用者需要对该资源进行写操作，系统会对该资源进行拷贝操作，从而使得该“写操作”使用者获得一个该资源A的“私有”拷贝——资源B，可对资源B进行写操作。该“写操作”使用者对资源B的改变对于其他使用者而言是不可见的，因为其他使用者看到的还是资源A。


+ 首先在`do_fork`过程中，将父线程的所有页表项设置为只读；
+ 然后让子进程共享父进程的内存空间，让子进程的虚拟地址映射到父进程的物理页；
+ 当进程修改共享页面时，ucore会触发page_fault中断，此时需要判断是否是写一个只读页面。如果是，则需要将页面复制一份，然后修改子进程的页表，建立新的映射关系，使得子进程的内存空间与父进程的内存空间分离。
+ 最后还需查看原来共享的物理页是否只有一个进程在使用，如果是，则恢复原来的读写权限。


##### 代码实现
一方面需要修改`copy_range` 函数：根据share的值来判断是否需要共享内存空间。如果需要，则通过page_insert将子进程的虚拟地址空间映射到父进程的物理页，否则，将父进程的内存空间复制给子进程。
```c
    if(share){
        // COW，共享，初始两边都设置为只读
        page_insert(from, page, start, perm & (~PTE_W));
        ret = page_insert(to, page, start, perm & (~PTE_W));
    }
    else{
        struct Page *npage = alloc_page();
        assert(npage != NULL);
        void* src_kvaddr = page2kva(page);
        void* dst_kvaddr = page2kva(npage);
        memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
        ret = page_insert(to, npage, start, perm);
    }
```

另一方面需要修改 `do_pgfault` 函数：当发生缺页中断时，判断是否是写一个只读页面。
如果是，则需要将页面复制一份，然后修改子进程的页表，建立新的映射关系，使得子进程的内存空间与父进程的内存空间分离。
另外还需查看原来共享的物理页是否只有一个进程在使用，如果是，需恢复原来的读写权限。
```c
    // Copy on Write，发生写不可写页面错误时，tf->cause == 0xf
    else if((*ptep & PTE_V) && (error_code == 0xf)) {
        struct Page *page = pte2page(*ptep);
        if(page_ref(page) == 1) {
            // 该页面只有一个引用，直接修改权限
            page_insert(mm->pgdir, page, addr, perm);
        }
        else {
            // 该页面有多个引用，需要复制页面
            struct Page *npage = alloc_page();
            assert(npage != NULL);
            memcpy(page2kva(npage), page2kva(page), PGSIZE);
            if(page_insert(mm->pgdir, npage, addr, perm) != 0) {
                cprintf("page_insert in do_pgfault failed\n");
                goto failed;
            }
        }
    }

```
## 练习3：

### 函数分析

1. `fork`：函数调用：fork --> SYS_fork --> do_fork --> wakeup_proc

+ 父进程调用 fork() 。(用户态)
+  内核复制父进程资源，创建一个新的子进程。(内核态) 
+  fork 调用返回子进程，得到新的PID，父进程也从 fork 调用返回，得到子进程的PID。(用户态)

1. `exec`：函数调用：exec --> SYS_exec --> do_execve
+ 进程调用 exec 系统调用，加载执行新程序。 (用户态)
+ 内核加载新程序的代码和数据，并初始化。  (内核态)
+ 新程序开始执行，原来的程序替换为新程序。(用户态)
1. `wait`：函数调用：wait --> SYS_wait --> do_wait
+ 父进程调用 wait 或 waitpid 系统调用，等待子进程的退出。 (用户态)
+ 如果子进程已经退出，内核返回子进程的退出状态给父进程；如果子进程未退出，父进程阻塞，等待子进程退出。 (内核态)
+ 父进程得到子进程的退出状态，可以进行相应的处理。(用户态)
1. `exit`：函数调用：exit --> SYS_exit --> do_exit.
+ 进程调用 exit 系统调用，通知内核退出。(用户态) 
+ 内核清理进程资源，关闭文件，释放内存。 (内核态)
+ 进程退出，返回父进程。(用户态)




### 生命周期图

```shell
+------------------------------------------------ do_wait -------------------------------------+
+-------------+    alloc_proc     +-------------+    wakeup_proc     +-------------+    do_exit     +-------------+
|    none     | ----------------> | PROC_UNINIT | ----------------> |PROC_RUNNABLE| -------------> | PROC_ZOMBIE |
+-------------+                   +-------------+                   +-------------+                +-------------+
                                        ^                                    |   ^                           ^
                                        |                                    |   |                           |
                                        |                                    |   | do_wait ，wake_up                  |
                                        |                                    |   |                          |
                                        |                                    V   |                          |
                                        |                              +-------------+                     |
                                        +----------------------------- |PROC_SLEEPING| <-------------------+
                                                                       +-------------+        


```

## 扩展练习

### 实现 Copy on Write （COW）机制
具体见练习2

### 用户程序加载

+ **何时：** 该用户程序在操作系统加载时一起加载到内存里。内核目标文件（$(kernel)） 由内核的对象文件  （$(KOBJS)）和用户程序的二进制文件（$(USER_BINS)）决定。内核和用户程序的二进制文件通过链接器一起被链接到最终的二进制镜像文件中。
+ **区别：** 我们平时使用的程序在操作系统启动时还位于磁盘中，只有当我们需要运行该程序时才会被加载到内存里。当用户需要运行某个应用程序时，操作系统才会将其加载到内存中。

+ **原因：** 用户应用程序是要紧跟着内核的第二个线程 init_proc 执行的，所以它其实在系统一启动就执行了。在`Makefile`里执行了`ld`命令，把执行程序的代码连接在了内核代码的末尾。
```
$(kernel): $(KOBJS) $(USER_BINS)
	@echo + ld $@
	$(V)$(LD) $(LDFLAGS) -T tools/kernel.ld -o $@ $(KOBJS) --format=binary $(USER_BINS) --format=default
	@$(OBJDUMP) -S $@ > $(call asmfile,kernel)
	@$(OBJDUMP) -t $@ | $(SED) '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $(call symfile,kernel)
```