<h1><center>lab4实验报告</center></h1>

## 练习一

### 代码实现

根据手册里的提示，将`state`设为`PROC_UNINIT`，`pid`设为`-1`，`cr3`设置为`boot_cr3`，其余需要初始化的变量中，指针设为`NULL`，变量设置为`0`，具体实现方式如下：

```c
proc->state = PROC_UNINIT;
proc->pid = -1;
proc->runs = 0;
proc->kstack = 0;
proc->need_resched = 0;
proc->parent = NULL;
proc->mm = NULL;
memset(&(proc->context), 0, sizeof(struct context));
proc->tf = NULL;
proc->cr3 = boot_cr3;
proc->flags = 0;
memset(proc->name, 0, PROC_NAME_LEN + 1);
```

### 问题解答
Q:请说明proc_struct中struct context context和struct trapframe *tf成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）
A: 
- 1.struct context context保存了进程的上下文，包含了ra，sp，s0~s11共14个寄存器，用于不同进程间的切换。当进程发生中断或调度切换时，需要保存当前进程的寄存器状态，以便在将来重新执行该进程时能够从之前的状态继续执行。
- 2.struct trapframe *tf：保存了进程的中断帧（32个通用寄存器、异常相关的寄存器）。struct trapframe 结构体中，包括寄存器的值、程序计数器（PC）等信息。在进程从用户空间跳转到内核空间时，系统调用会改变寄存器的值。我们可以通过调整中断帧来使的系统调用返回特定的值,在程序中创建子线程时，会将中断帧中的a0设为0，还有利用s0和s1传递线程执行的函数和参数；。




## 练习二

### 代码实现

按照实验手册上的流程，逐步调用相关函数，补充各参数。这里额外添加了一些必要的步骤：

+ `proc->parent = current;`：将新线程的父线程设置为`current`
+ `proc->pid = pid;`：将获取的线程`pid`赋给新线程的`pid`
+ `nr_process++;`：线程数量自增1

```c
proc = alloc_proc();
proc->parent = current;
setup_kstack(proc);
copy_mm(clone_flags, proc);
copy_thread(proc, stack, tf);
int pid = get_pid();
proc->pid = pid;
hash_proc(proc);
list_add(&proc_list, &(proc->list_link));
nr_process++;
proc->state = PROC_RUNNABLE;
ret = proc->pid;
```

### 问题解答
Q:请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。

A:`ucore`能做到给每个新`fork`的线程一个唯一的`id`。通过`get_pid`分配`id`。维护`last_pid`，遍历线程链表，判断是否有`id`相等的线程，有的话将`last_pid`加1，并且使得之后不会与当前的线程`id`冲突，且不会超过最大线程数，从头遍历链表；没有的话，更新下一个可能冲突的线程`id`。

从代码出发，如果```if (proc->pid == last_pid)```，之后会```++last_pid```，说明一旦循环时出现线程号相等的情况就会立刻自增，不会构造出重复的pid。
```C
static int
get_pid(void) {
    ...
    repeat:
    //PID 的确定过程中会检查所有进程的 PID，确保唯一
        le = list;
        while ((le = list_next(le)) != list) {
            proc = le2proc(le, list_link);
            if (proc->pid == last_pid) {  //确保新进程的pid不会与last_pid相等
                if (++ last_pid >= next_safe) { //自增
                    if (last_pid >= MAX_PID) {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid) {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}
```
## 练习三

### 代码实现

参考`schedule`函数里面的禁止和启用中断的过程，实现如下：

```c
    bool intr_flag;
    struct proc_struct *prev = current;
    struct proc_struct *next = proc;
    if(prev!=next){
        local_intr_save(intr_flag);
        {
        current = proc;
        lcr3(next->cr3);
        switch_to(&(prev->context), &(next->context));
        }
        local_intr_restore(intr_flag);
    }
```

### 问题解答
Q:在本实验的执行过程中，创建且运行了几个内核线程？

A:两个,0号线程`idleproc`和1号线程`initproc`。


## challenge
Q：说明语句local_intr_save(intr_flag);....local_intr_restore(intr_flag);是如何实现开关中断的？
A：在sync.h中可以找到如下相关代码：
```c
static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}

#define local_intr_save(x)      do { x = __intr_save(); } while (0)
#define local_intr_restore(x)   __intr_restore(x);
```
这段代码通过两个内联函数和两个宏定义实现了中断的保存和恢复。具体来说，local_intr_save(intr_flag)宏调用__intr_save函数，该函数首先读取读取CSR寄存器的sstatus位和SSTATUS_SIE位以检查当前是否启用了中断，如果是，则调用intr_disable禁用中断，并返回1表示中断原来是启用的；否则返回0。返回值被保存到变量intr_flag中。

随后，在关键代码段执行完毕后，local_intr_restore(intr_flag)宏调用__intr_restore函数，该函数根据intr_flag的值决定是否重新启用中断。如果intr_flag为1，则调用intr_enable重新启用中断；否则不做任何操作。这样可以确保在关键操作期间中断不会被误触发，同时在操作完成后恢复原始的中断状态。
## 知识点总结



#### **进程与线程**：
**进程**
- **定义**：进程是操作系统分配资源和调度的基本单位，通常指的是正在执行的程序的实例。每个进程都有自己的虚拟地址空间、代码、数据、文件描述符等资源。
- **特点**：
  - **独立的资源**：每个进程都有自己的独立的虚拟地址空间，操作系统为每个进程分配并保护其资源（内存、文件描述符等），进程间资源互不干扰。
  - **独立的执行**：进程有自己的执行状态，如运行、就绪、等待等，执行时会由操作系统进行调度（如时间片轮转、优先级等）。
  - **隔离性**：进程间彼此隔离，一个进程的崩溃不会直接影响到其他进程（除非共享资源发生冲突或其他异常）。
  - **多任务**：进程是多任务管理的基本单位，操作系统通过调度和管理不同进程的执行来实现多任务。

 **线程**：
- **定义**：线程是进程的执行单元，一个进程内可能有多个线程。线程共享进程的虚拟地址空间和资源，但每个线程都有独立的执行上下文（如程序计数器、寄存器、栈等）。
- **特点**：
  - **轻量级进程**：线程有时被称为“轻量级进程”，因为它们不需要拥有独立的虚拟地址空间和资源（这些由进程共享）。线程之间的通信更加高效，因为它们共享同一进程的地址空间。
  - **独立的执行**：线程有自己的执行状态，保存了每个线程独立的上下文（如寄存器、栈等），可以独立调度和执行。
  - **共享资源**：线程共享同一个进程的资源，如文件描述符、内存空间等，但每个线程有独立的栈，用来存放局部变量和函数调用信息。

#### **进程与线程的区别**：
| 特性             | 进程（Process）                              | 线程（Thread）                                  |
|------------------|---------------------------------------------|-------------------------------------------------|
| **资源管理**     | 每个进程都有独立的虚拟地址空间和资源       | 线程共享进程的虚拟地址空间和资源               |
| **执行单位**     | 进程是操作系统分配资源和调度的基本单位     | 线程是进程中的执行单位                         |
| **独立性**       | 进程之间相互独立，资源不共享               | 线程间共享同一进程的资源                       |
| **开销**         | 创建和销毁进程的开销较大                   | 线程开销较小，创建和销毁的成本低               |
| **通信方式**     | 进程间通信相对复杂，效率较低         | 线程间通信更为高效，因为它们共享同一进程空间 |
| **崩溃影响**     | 进程崩溃不会影响其他进程                   | 线程崩溃可能会影响同一进程内的其他线程         |
| **调度**         | 进程由操作系统调度，通常是较重的调度单元   | 线程是较轻的调度单元，线程切换的开销较低     |



#### **内核线程与用户线程**：
- **用户线程（User Thread）**：用户线程由用户程序创建和管理，用户进程会在内核态和用户态交替运行，用户进程需要维护各自的用户内存空间
- **内核线程（Kernel Thread）**：内核线程是由操作系统内核创建和管理的，内核线程只运行在内核态，所有内核线程共用ucore内存空间，不需要为每个内核线程维护单独的内存空间

#### **进程与线程在 ucore 中的区别**：

- uCore 的调度机制没有区分进程和线程，实际上它对进程和线程的管理是相似的，主要关注的是执行上下文的切换和调度。



#### 代码中的重要知识点
  **1.**  本次实验共创建且运行了两个线程，`idleproc`和 `initproc`
   + `idleproc`是第0个线程，表示空闲线程，空闲进程是一个特殊的进程，主要工作是完成内核中各个子系统的初始化，然后就通过执行cpu_idle函数被替代了；
 + `initproc`是第1个线程，输出一些字符串，然后就返回了；
  + `kern_init` 函数调用了` proc_init `函数，`proc_init `函数启动了创建内核线程的步骤,首先初始化进程控制块链表，然后调用` alloc_proc `函数来通过 `kmalloc `函数获得` proc_struct` 结构的一块内存块，对进程控制块进行初步初始化；
  + 其中`idleproc->need_resched `被设为1时说明这个线程是一个空闲线程，所以不执行他，调用 schedule 函数切换其他进程。



  **2.**  `kstack`是内核栈，process都有，是运行程序使用的栈，在内存栈里为中断帧分配空间
  + 内核栈位于内核地址空间，并且不进行共享， 好处是可以快速被定位，方便调试，但同时不受到` mm `的管理，如果溢出不容易被kernel管理。
  + 切换进程时，根据 `kstack `的值正确的设置好` tss`，以便发生中断使用正确的栈
  


  **3.** `kernel_thread` 函数通过调用 `do_fork `函数进行了内核线程的创建工作，`do_fork`函数的内容是：

  + 首先分配线程控制块
  + 并分配并初始化内核栈
  + 使用` clone_flags `判断复制或者共享
  + 设置中断帧和上下文
  + 将进程加入线程，新建的进程设为就绪态
  + 返回值为线程的id

  **4.** 线程的调度流程如下：
  + 将当前内核线程的 `current->need_resched` 成员设置为 0
  + 从` proc_list `队列中查找下一个处于就绪态的线程或进程
  + 调用` proc_run `函数，将指定的进程切换到 CPU 上运行，使用 `switch_to `进行上下文切换

