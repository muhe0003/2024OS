# lab0.5实验报告
## 实验目的
实验0.5主要讲解最小可执行内核和启动流程。我们的内核主要在 Qemu 模拟器上运行，它可以模拟一台 64 位 RISC-V 计算机。为了让我们的内核能够正确对接到 Qemu 模拟器上，需要了解 Qemu 模拟器的启动流程，还需要一些程序内存布局和编译流程（特别是链接）相关知识,以及通过opensbi固件来通过服务。

## 实验内容
练习1: 使用GDB验证启动流程：

为了熟悉使用qemu和gdb进行调试工作,使用gdb调试QEMU模拟的RISC-V计算机加电开始运行到执行应用程序的第一条指令（即跳转到0x80200000）这个阶段的执行过程，说明RISC-V硬件加电后的几条指令在哪里？完成了哪些功能？要求在报告中简要写出练习过程和回答。

首先打开两个终端，分别执行以下命令：
```
make debug
make gdb
```
在执行后者的终端中可以看到如下界面：
```
0x0000000000001000 in ?? ()
(gdb) 
```
这是由于QEMU模拟的这款riscv处理器的复位地址是0x1000

之后输入指令`x/10i $pc `查看即将执行的10条汇编指令:
```
(gdb) x/10i $pc
=> 0x1000:  auipc  t0,0x0        #  将当前 PC 加上立即数（0），结果存入寄存器 t0。
0x1004:	addi	a1,t0,32      # 将 t0 的值加 32，结果存入 a1（即 a1 = t0 + 32）
0x1008:	csrr	a0,mhartid     # 将机器硬件线程 ID（hart ID）读取到 a0 中
0x100c:	ld	t0,24(t0)       # 从 t0+24 的地址加载一个 64 位数到 t0 中
0x1010:	jr	t0              # 跳转到 t0 指向的地址
0x1014:	unimp              # 未实现
0x1016:	unimp              # 未实现
0x1018:	unimp             # 未实现
0x101a:	0x8000            # 跳转地址
0x101c:	unimp             # 未实现
```
各个指令的功能见代码注释。

之后通过`si`指令单步执行，并不断通过`info r t0`指令查看 t0 寄存器的值。
```
(gdb) info r t0
t0             0x0	0
(gdb) si       
0x0000000000001004 in ?? ()
(gdb) info r t0
t0             0x1000	4096
(gdb) si       
0x0000000000001008 in ?? ()
(gdb) info r t0
t0             0x1000	4096
(gdb) si       
0x000000000000100c in ?? ()
(gdb) info r t0
t0             0x1000	4096
(gdb) si       
0x0000000000001010 in ?? ()
(gdb) info r t0
t0             0x1000	4096
(gdb) si       
0x0000000000001014 in ?? ()
(gdb) info r t0
t0             0x80000000	2147483648
(gdb) si       
0x0000000080000000 in ?? ()     #跳转到地址0x80000000
```


之后跳转到地址`0x80000000`，进入Bootloader（OpeSBI）启动阶段

输入x/10i 0x80000000，显示0x80000000处的10条数据。
```
0x80000000: csrr a6,mhartid              # a6 = mhartid (获取当前硬件线程的ID)
0x80000000:	csrr	a6,mhartid     # 将当前硬件线程 ID (hart ID) 读取到寄存器 a6 中
0x80000004:	bgtz	a6,0x80000108   # 如果 a6 > 0，则跳转到地址 0x80000108
0x80000008:	auipc	t0,0x0         # 将当前指令地址的高 20 位加载到 t0 中（低 12 位为 0）
0x8000000c:	addi	t0,t0,1032      # 在 t0 的基础上加 1032，并将结果存入 t0（即 t0 = t0 + 1032）
0x80000010:	auipc	t1,0x0         # 将当前指令地址的高 20 位加载到 t1 中（低 12 位为 0）
0x80000014:	addi	t1,t1,-16       # 在 t1 的基础上加 -16，并将结果存入 t1（即 t1 = t1 - 16）
0x80000018:	sd	t1,0(t0)         # 将 t1 中的 64 位数据存储到地址 t0 指向的内存位置（即 t0 + 0）
0x8000001c:	auipc	t0,0x0         # 将当前指令地址的高 20 位加载到 t0 中（低 12 位为 0）
0x80000020:	addi	t0,t0,1020      # 在 t0 的基础上加 1020，并将结果存入 t0（即 t0 = t0 + 1020）
0x80000024:	ld	t0,0(t0)         # 从 t0 指向的内存地址加载一个 64 位数到 t0 中
```
这些指令主要包括了加载启动代码的地址、设置寄存器、获取处理器信息等功能。

之后输入`break *0x80200000`指令，在kern_entry的第一条指令处设置断点
```
(gdb) break *0x80200000
Breakpoint 1 at 0x80200000: file kern/init/entry.S, line 7.
(gdb) continue
Continuing.

Breakpoint 1, kern_entry () at kern/init/entry.S:7
7	    la sp, bootstacktop
(gdb) x/10i $pc
=>0x80200000 <kern_entry>: auipc sp,0x3            # 将当前 PC + (3 << 12) 的值存入 sp，设置栈指针位置
0x80200004 <kern_entry+4>: mv sp,sp              # sp 的值复制到 sp，可能是占位符指令
0x80200008 <kern_entry+8>: j 0x8020000c <kern_init>  # 跳转到内核初始化函数 kern_init
0x8020000c <kern_init>: auipc a0,0x3              # 将当前 PC + (3 << 12) 的值存入 a0，准备参数地址
0x80200010 <kern_init+4>: addi a0,a0,-4          # 将 a0 的值减去 4，调整地址指向特定结构
0x80200014 <kern_init+8>: auipc a2,0x3            # 将当前 PC + (3 << 12) 的值存入 a2，准备另一个参数地址
0x80200018 <kern_init+12>: addi a2,a2,-12        # 将 a2 的值减去 12，调整地址指向另一个结构
0x8020001c <kern_init+16>: addi sp,sp,-16        # 将 sp 的值减去 16，为局部变量分配栈空间
0x8020001e <kern_init+18>: li a1,0                 # 将立即数 0 加载到 a1，初始化 a1 的值
0x80200020 <kern_init+20>: sub a2,a2,a0            # 将 a0 的值从 a2 中减去，计算新的偏移量
```

在Debug的终端中OpenSBI也开始启动。
```
OpenSBI v0.4 (Jul  2 2019 11:53:53)
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name          : QEMU Virt Machine
Platform HART Features : RV64ACDFIMSU
Platform Max HARTs     : 8
Current Hart           : 0
Firmware Base          : 0x80000000
Firmware Size          : 112 KB
Runtime SBI Version    : 0.1

PMP0: 0x0000000080000000-0x000000008001ffff (A)
PMP1: 0x0000000000000000-0xffffffffffffffff (A,R,W,X)
```
至此完成了RISC-V计算机加电开始运行到执行应用程序的第一条指令（即跳转到0x80200000）这个阶段的执行过程。

## 问题回答及知识点
1. QEMU模拟的RISC-V计算机加电开始运行时复位地址是0x1000，之后的几条指令整体上完成了硬件线程的加载以及跳转到0x8000，准备OpenSBI的启动，具体代码见上面注释。

2. 最小可执行内核的执行流为:

加电 -> OpenSBI启动 -> 跳转到 0x80200000 (kern/init/entry.S）->进入kern_init()函数（kern/init/init.c) ->调用cprintf()输出一行信息->结束

其中加电复位的地址是0x1000，这是由QEMU模拟的这款riscv处理器所决定的。之后跳转到 OpenSBI启动的地址0x8000。

OpenSBI是bootloader的一种，作用是将操作系统加载到内存中。OpenSBI是一种固件，固件(firmware)是一种特定的计算机软件，它为设备的特定硬件提供低级控制，也可以进一步加载其他软件。固件可以为设备更复杂的软件（如操作系统）提供标准化的操作环境。对于不太复杂的设备，固件可以直接充当设备的完整操作系统，执行所有控制、监视和数据操作功能。

kern/init/entry.S: OpenSBI启动之后将要跳转到的一段汇编代码。在这里进行内核栈的分配，然后转入C语言编写的内核初始化函数。

kern/init/init.c： C语言编写的内核入口点。主要包含kern_init()函数，从kern/entry.S跳转过来完成其他初始化工作。

3. make 和 Makefile：
   
GNU make(简称make)是一种代码维护工具，在大中型项目中，它将根据程序各个模块的更新情况，自动的维护和生成目标代码。

make命令执行时，需要一个 makefile （或Makefile）文件，以告诉make命令需要怎么样的去编译和链接程序