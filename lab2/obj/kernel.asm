
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200024:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	00006517          	auipc	a0,0x6
ffffffffc0200036:	fe650513          	addi	a0,a0,-26 # ffffffffc0206018 <free_area>
ffffffffc020003a:	00006617          	auipc	a2,0x6
ffffffffc020003e:	44660613          	addi	a2,a2,1094 # ffffffffc0206480 <end>
int kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
int kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	219010ef          	jal	ra,ffffffffc0201a62 <memset>
    cons_init();  // init the console
ffffffffc020004e:	3fc000ef          	jal	ra,ffffffffc020044a <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00002517          	auipc	a0,0x2
ffffffffc0200056:	a2650513          	addi	a0,a0,-1498 # ffffffffc0201a78 <etext+0x4>
ffffffffc020005a:	090000ef          	jal	ra,ffffffffc02000ea <cputs>

    print_kerninfo();
ffffffffc020005e:	0dc000ef          	jal	ra,ffffffffc020013a <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200062:	402000ef          	jal	ra,ffffffffc0200464 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc0200066:	30c010ef          	jal	ra,ffffffffc0201372 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc020006a:	3fa000ef          	jal	ra,ffffffffc0200464 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc020006e:	39a000ef          	jal	ra,ffffffffc0200408 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200072:	3e6000ef          	jal	ra,ffffffffc0200458 <intr_enable>



    /* do nothing */
    while (1)
ffffffffc0200076:	a001                	j	ffffffffc0200076 <kern_init+0x44>

ffffffffc0200078 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200078:	1141                	addi	sp,sp,-16
ffffffffc020007a:	e022                	sd	s0,0(sp)
ffffffffc020007c:	e406                	sd	ra,8(sp)
ffffffffc020007e:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200080:	3cc000ef          	jal	ra,ffffffffc020044c <cons_putc>
    (*cnt) ++;
ffffffffc0200084:	401c                	lw	a5,0(s0)
}
ffffffffc0200086:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200088:	2785                	addiw	a5,a5,1
ffffffffc020008a:	c01c                	sw	a5,0(s0)
}
ffffffffc020008c:	6402                	ld	s0,0(sp)
ffffffffc020008e:	0141                	addi	sp,sp,16
ffffffffc0200090:	8082                	ret

ffffffffc0200092 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200092:	1101                	addi	sp,sp,-32
ffffffffc0200094:	862a                	mv	a2,a0
ffffffffc0200096:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200098:	00000517          	auipc	a0,0x0
ffffffffc020009c:	fe050513          	addi	a0,a0,-32 # ffffffffc0200078 <cputch>
ffffffffc02000a0:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a2:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a4:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a6:	4cc010ef          	jal	ra,ffffffffc0201572 <vprintfmt>
    return cnt;
}
ffffffffc02000aa:	60e2                	ld	ra,24(sp)
ffffffffc02000ac:	4532                	lw	a0,12(sp)
ffffffffc02000ae:	6105                	addi	sp,sp,32
ffffffffc02000b0:	8082                	ret

ffffffffc02000b2 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b2:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b4:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000b8:	8e2a                	mv	t3,a0
ffffffffc02000ba:	f42e                	sd	a1,40(sp)
ffffffffc02000bc:	f832                	sd	a2,48(sp)
ffffffffc02000be:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c0:	00000517          	auipc	a0,0x0
ffffffffc02000c4:	fb850513          	addi	a0,a0,-72 # ffffffffc0200078 <cputch>
ffffffffc02000c8:	004c                	addi	a1,sp,4
ffffffffc02000ca:	869a                	mv	a3,t1
ffffffffc02000cc:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000ce:	ec06                	sd	ra,24(sp)
ffffffffc02000d0:	e0ba                	sd	a4,64(sp)
ffffffffc02000d2:	e4be                	sd	a5,72(sp)
ffffffffc02000d4:	e8c2                	sd	a6,80(sp)
ffffffffc02000d6:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000d8:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000da:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000dc:	496010ef          	jal	ra,ffffffffc0201572 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e0:	60e2                	ld	ra,24(sp)
ffffffffc02000e2:	4512                	lw	a0,4(sp)
ffffffffc02000e4:	6125                	addi	sp,sp,96
ffffffffc02000e6:	8082                	ret

ffffffffc02000e8 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000e8:	a695                	j	ffffffffc020044c <cons_putc>

ffffffffc02000ea <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000ea:	1101                	addi	sp,sp,-32
ffffffffc02000ec:	e822                	sd	s0,16(sp)
ffffffffc02000ee:	ec06                	sd	ra,24(sp)
ffffffffc02000f0:	e426                	sd	s1,8(sp)
ffffffffc02000f2:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f4:	00054503          	lbu	a0,0(a0)
ffffffffc02000f8:	c51d                	beqz	a0,ffffffffc0200126 <cputs+0x3c>
ffffffffc02000fa:	0405                	addi	s0,s0,1
ffffffffc02000fc:	4485                	li	s1,1
ffffffffc02000fe:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200100:	34c000ef          	jal	ra,ffffffffc020044c <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200104:	00044503          	lbu	a0,0(s0)
ffffffffc0200108:	008487bb          	addw	a5,s1,s0
ffffffffc020010c:	0405                	addi	s0,s0,1
ffffffffc020010e:	f96d                	bnez	a0,ffffffffc0200100 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200110:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200114:	4529                	li	a0,10
ffffffffc0200116:	336000ef          	jal	ra,ffffffffc020044c <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011a:	60e2                	ld	ra,24(sp)
ffffffffc020011c:	8522                	mv	a0,s0
ffffffffc020011e:	6442                	ld	s0,16(sp)
ffffffffc0200120:	64a2                	ld	s1,8(sp)
ffffffffc0200122:	6105                	addi	sp,sp,32
ffffffffc0200124:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200126:	4405                	li	s0,1
ffffffffc0200128:	b7f5                	j	ffffffffc0200114 <cputs+0x2a>

ffffffffc020012a <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020012a:	1141                	addi	sp,sp,-16
ffffffffc020012c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020012e:	326000ef          	jal	ra,ffffffffc0200454 <cons_getc>
ffffffffc0200132:	dd75                	beqz	a0,ffffffffc020012e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200134:	60a2                	ld	ra,8(sp)
ffffffffc0200136:	0141                	addi	sp,sp,16
ffffffffc0200138:	8082                	ret

ffffffffc020013a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020013a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020013c:	00002517          	auipc	a0,0x2
ffffffffc0200140:	95c50513          	addi	a0,a0,-1700 # ffffffffc0201a98 <etext+0x24>
void print_kerninfo(void) {
ffffffffc0200144:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200146:	f6dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014a:	00000597          	auipc	a1,0x0
ffffffffc020014e:	ee858593          	addi	a1,a1,-280 # ffffffffc0200032 <kern_init>
ffffffffc0200152:	00002517          	auipc	a0,0x2
ffffffffc0200156:	96650513          	addi	a0,a0,-1690 # ffffffffc0201ab8 <etext+0x44>
ffffffffc020015a:	f59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020015e:	00002597          	auipc	a1,0x2
ffffffffc0200162:	91658593          	addi	a1,a1,-1770 # ffffffffc0201a74 <etext>
ffffffffc0200166:	00002517          	auipc	a0,0x2
ffffffffc020016a:	97250513          	addi	a0,a0,-1678 # ffffffffc0201ad8 <etext+0x64>
ffffffffc020016e:	f45ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200172:	00006597          	auipc	a1,0x6
ffffffffc0200176:	ea658593          	addi	a1,a1,-346 # ffffffffc0206018 <free_area>
ffffffffc020017a:	00002517          	auipc	a0,0x2
ffffffffc020017e:	97e50513          	addi	a0,a0,-1666 # ffffffffc0201af8 <etext+0x84>
ffffffffc0200182:	f31ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200186:	00006597          	auipc	a1,0x6
ffffffffc020018a:	2fa58593          	addi	a1,a1,762 # ffffffffc0206480 <end>
ffffffffc020018e:	00002517          	auipc	a0,0x2
ffffffffc0200192:	98a50513          	addi	a0,a0,-1654 # ffffffffc0201b18 <etext+0xa4>
ffffffffc0200196:	f1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020019a:	00006597          	auipc	a1,0x6
ffffffffc020019e:	6e558593          	addi	a1,a1,1765 # ffffffffc020687f <end+0x3ff>
ffffffffc02001a2:	00000797          	auipc	a5,0x0
ffffffffc02001a6:	e9078793          	addi	a5,a5,-368 # ffffffffc0200032 <kern_init>
ffffffffc02001aa:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ae:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001b2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001b8:	95be                	add	a1,a1,a5
ffffffffc02001ba:	85a9                	srai	a1,a1,0xa
ffffffffc02001bc:	00002517          	auipc	a0,0x2
ffffffffc02001c0:	97c50513          	addi	a0,a0,-1668 # ffffffffc0201b38 <etext+0xc4>
}
ffffffffc02001c4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001c6:	b5f5                	j	ffffffffc02000b2 <cprintf>

ffffffffc02001c8 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001c8:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001ca:	00002617          	auipc	a2,0x2
ffffffffc02001ce:	99e60613          	addi	a2,a2,-1634 # ffffffffc0201b68 <etext+0xf4>
ffffffffc02001d2:	04e00593          	li	a1,78
ffffffffc02001d6:	00002517          	auipc	a0,0x2
ffffffffc02001da:	9aa50513          	addi	a0,a0,-1622 # ffffffffc0201b80 <etext+0x10c>
void print_stackframe(void) {
ffffffffc02001de:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001e0:	1cc000ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02001e4 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001e4:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001e6:	00002617          	auipc	a2,0x2
ffffffffc02001ea:	9b260613          	addi	a2,a2,-1614 # ffffffffc0201b98 <etext+0x124>
ffffffffc02001ee:	00002597          	auipc	a1,0x2
ffffffffc02001f2:	9ca58593          	addi	a1,a1,-1590 # ffffffffc0201bb8 <etext+0x144>
ffffffffc02001f6:	00002517          	auipc	a0,0x2
ffffffffc02001fa:	9ca50513          	addi	a0,a0,-1590 # ffffffffc0201bc0 <etext+0x14c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001fe:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200200:	eb3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200204:	00002617          	auipc	a2,0x2
ffffffffc0200208:	9cc60613          	addi	a2,a2,-1588 # ffffffffc0201bd0 <etext+0x15c>
ffffffffc020020c:	00002597          	auipc	a1,0x2
ffffffffc0200210:	9ec58593          	addi	a1,a1,-1556 # ffffffffc0201bf8 <etext+0x184>
ffffffffc0200214:	00002517          	auipc	a0,0x2
ffffffffc0200218:	9ac50513          	addi	a0,a0,-1620 # ffffffffc0201bc0 <etext+0x14c>
ffffffffc020021c:	e97ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200220:	00002617          	auipc	a2,0x2
ffffffffc0200224:	9e860613          	addi	a2,a2,-1560 # ffffffffc0201c08 <etext+0x194>
ffffffffc0200228:	00002597          	auipc	a1,0x2
ffffffffc020022c:	a0058593          	addi	a1,a1,-1536 # ffffffffc0201c28 <etext+0x1b4>
ffffffffc0200230:	00002517          	auipc	a0,0x2
ffffffffc0200234:	99050513          	addi	a0,a0,-1648 # ffffffffc0201bc0 <etext+0x14c>
ffffffffc0200238:	e7bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    }
    return 0;
}
ffffffffc020023c:	60a2                	ld	ra,8(sp)
ffffffffc020023e:	4501                	li	a0,0
ffffffffc0200240:	0141                	addi	sp,sp,16
ffffffffc0200242:	8082                	ret

ffffffffc0200244 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200244:	1141                	addi	sp,sp,-16
ffffffffc0200246:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200248:	ef3ff0ef          	jal	ra,ffffffffc020013a <print_kerninfo>
    return 0;
}
ffffffffc020024c:	60a2                	ld	ra,8(sp)
ffffffffc020024e:	4501                	li	a0,0
ffffffffc0200250:	0141                	addi	sp,sp,16
ffffffffc0200252:	8082                	ret

ffffffffc0200254 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200254:	1141                	addi	sp,sp,-16
ffffffffc0200256:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200258:	f71ff0ef          	jal	ra,ffffffffc02001c8 <print_stackframe>
    return 0;
}
ffffffffc020025c:	60a2                	ld	ra,8(sp)
ffffffffc020025e:	4501                	li	a0,0
ffffffffc0200260:	0141                	addi	sp,sp,16
ffffffffc0200262:	8082                	ret

ffffffffc0200264 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200264:	7115                	addi	sp,sp,-224
ffffffffc0200266:	ed5e                	sd	s7,152(sp)
ffffffffc0200268:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020026a:	00002517          	auipc	a0,0x2
ffffffffc020026e:	9ce50513          	addi	a0,a0,-1586 # ffffffffc0201c38 <etext+0x1c4>
kmonitor(struct trapframe *tf) {
ffffffffc0200272:	ed86                	sd	ra,216(sp)
ffffffffc0200274:	e9a2                	sd	s0,208(sp)
ffffffffc0200276:	e5a6                	sd	s1,200(sp)
ffffffffc0200278:	e1ca                	sd	s2,192(sp)
ffffffffc020027a:	fd4e                	sd	s3,184(sp)
ffffffffc020027c:	f952                	sd	s4,176(sp)
ffffffffc020027e:	f556                	sd	s5,168(sp)
ffffffffc0200280:	f15a                	sd	s6,160(sp)
ffffffffc0200282:	e962                	sd	s8,144(sp)
ffffffffc0200284:	e566                	sd	s9,136(sp)
ffffffffc0200286:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200288:	e2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020028c:	00002517          	auipc	a0,0x2
ffffffffc0200290:	9d450513          	addi	a0,a0,-1580 # ffffffffc0201c60 <etext+0x1ec>
ffffffffc0200294:	e1fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (tf != NULL) {
ffffffffc0200298:	000b8563          	beqz	s7,ffffffffc02002a2 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020029c:	855e                	mv	a0,s7
ffffffffc020029e:	3a4000ef          	jal	ra,ffffffffc0200642 <print_trapframe>
ffffffffc02002a2:	00002c17          	auipc	s8,0x2
ffffffffc02002a6:	a2ec0c13          	addi	s8,s8,-1490 # ffffffffc0201cd0 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002aa:	00002917          	auipc	s2,0x2
ffffffffc02002ae:	9de90913          	addi	s2,s2,-1570 # ffffffffc0201c88 <etext+0x214>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b2:	00002497          	auipc	s1,0x2
ffffffffc02002b6:	9de48493          	addi	s1,s1,-1570 # ffffffffc0201c90 <etext+0x21c>
        if (argc == MAXARGS - 1) {
ffffffffc02002ba:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002bc:	00002b17          	auipc	s6,0x2
ffffffffc02002c0:	9dcb0b13          	addi	s6,s6,-1572 # ffffffffc0201c98 <etext+0x224>
        argv[argc ++] = buf;
ffffffffc02002c4:	00002a17          	auipc	s4,0x2
ffffffffc02002c8:	8f4a0a13          	addi	s4,s4,-1804 # ffffffffc0201bb8 <etext+0x144>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002cc:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002ce:	854a                	mv	a0,s2
ffffffffc02002d0:	624010ef          	jal	ra,ffffffffc02018f4 <readline>
ffffffffc02002d4:	842a                	mv	s0,a0
ffffffffc02002d6:	dd65                	beqz	a0,ffffffffc02002ce <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002d8:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002dc:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002de:	e1bd                	bnez	a1,ffffffffc0200344 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02002e0:	fe0c87e3          	beqz	s9,ffffffffc02002ce <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002e4:	6582                	ld	a1,0(sp)
ffffffffc02002e6:	00002d17          	auipc	s10,0x2
ffffffffc02002ea:	9ead0d13          	addi	s10,s10,-1558 # ffffffffc0201cd0 <commands>
        argv[argc ++] = buf;
ffffffffc02002ee:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f0:	4401                	li	s0,0
ffffffffc02002f2:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002f4:	73a010ef          	jal	ra,ffffffffc0201a2e <strcmp>
ffffffffc02002f8:	c919                	beqz	a0,ffffffffc020030e <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002fa:	2405                	addiw	s0,s0,1
ffffffffc02002fc:	0b540063          	beq	s0,s5,ffffffffc020039c <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200300:	000d3503          	ld	a0,0(s10)
ffffffffc0200304:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200306:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200308:	726010ef          	jal	ra,ffffffffc0201a2e <strcmp>
ffffffffc020030c:	f57d                	bnez	a0,ffffffffc02002fa <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020030e:	00141793          	slli	a5,s0,0x1
ffffffffc0200312:	97a2                	add	a5,a5,s0
ffffffffc0200314:	078e                	slli	a5,a5,0x3
ffffffffc0200316:	97e2                	add	a5,a5,s8
ffffffffc0200318:	6b9c                	ld	a5,16(a5)
ffffffffc020031a:	865e                	mv	a2,s7
ffffffffc020031c:	002c                	addi	a1,sp,8
ffffffffc020031e:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200322:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200324:	fa0555e3          	bgez	a0,ffffffffc02002ce <kmonitor+0x6a>
}
ffffffffc0200328:	60ee                	ld	ra,216(sp)
ffffffffc020032a:	644e                	ld	s0,208(sp)
ffffffffc020032c:	64ae                	ld	s1,200(sp)
ffffffffc020032e:	690e                	ld	s2,192(sp)
ffffffffc0200330:	79ea                	ld	s3,184(sp)
ffffffffc0200332:	7a4a                	ld	s4,176(sp)
ffffffffc0200334:	7aaa                	ld	s5,168(sp)
ffffffffc0200336:	7b0a                	ld	s6,160(sp)
ffffffffc0200338:	6bea                	ld	s7,152(sp)
ffffffffc020033a:	6c4a                	ld	s8,144(sp)
ffffffffc020033c:	6caa                	ld	s9,136(sp)
ffffffffc020033e:	6d0a                	ld	s10,128(sp)
ffffffffc0200340:	612d                	addi	sp,sp,224
ffffffffc0200342:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200344:	8526                	mv	a0,s1
ffffffffc0200346:	706010ef          	jal	ra,ffffffffc0201a4c <strchr>
ffffffffc020034a:	c901                	beqz	a0,ffffffffc020035a <kmonitor+0xf6>
ffffffffc020034c:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200350:	00040023          	sb	zero,0(s0)
ffffffffc0200354:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200356:	d5c9                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200358:	b7f5                	j	ffffffffc0200344 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc020035a:	00044783          	lbu	a5,0(s0)
ffffffffc020035e:	d3c9                	beqz	a5,ffffffffc02002e0 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200360:	033c8963          	beq	s9,s3,ffffffffc0200392 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200364:	003c9793          	slli	a5,s9,0x3
ffffffffc0200368:	0118                	addi	a4,sp,128
ffffffffc020036a:	97ba                	add	a5,a5,a4
ffffffffc020036c:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200370:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200374:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200376:	e591                	bnez	a1,ffffffffc0200382 <kmonitor+0x11e>
ffffffffc0200378:	b7b5                	j	ffffffffc02002e4 <kmonitor+0x80>
ffffffffc020037a:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020037e:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200380:	d1a5                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200382:	8526                	mv	a0,s1
ffffffffc0200384:	6c8010ef          	jal	ra,ffffffffc0201a4c <strchr>
ffffffffc0200388:	d96d                	beqz	a0,ffffffffc020037a <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038a:	00044583          	lbu	a1,0(s0)
ffffffffc020038e:	d9a9                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200390:	bf55                	j	ffffffffc0200344 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200392:	45c1                	li	a1,16
ffffffffc0200394:	855a                	mv	a0,s6
ffffffffc0200396:	d1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020039a:	b7e9                	j	ffffffffc0200364 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020039c:	6582                	ld	a1,0(sp)
ffffffffc020039e:	00002517          	auipc	a0,0x2
ffffffffc02003a2:	91a50513          	addi	a0,a0,-1766 # ffffffffc0201cb8 <etext+0x244>
ffffffffc02003a6:	d0dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    return 0;
ffffffffc02003aa:	b715                	j	ffffffffc02002ce <kmonitor+0x6a>

ffffffffc02003ac <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003ac:	00006317          	auipc	t1,0x6
ffffffffc02003b0:	08430313          	addi	t1,t1,132 # ffffffffc0206430 <is_panic>
ffffffffc02003b4:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003b8:	715d                	addi	sp,sp,-80
ffffffffc02003ba:	ec06                	sd	ra,24(sp)
ffffffffc02003bc:	e822                	sd	s0,16(sp)
ffffffffc02003be:	f436                	sd	a3,40(sp)
ffffffffc02003c0:	f83a                	sd	a4,48(sp)
ffffffffc02003c2:	fc3e                	sd	a5,56(sp)
ffffffffc02003c4:	e0c2                	sd	a6,64(sp)
ffffffffc02003c6:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003c8:	020e1a63          	bnez	t3,ffffffffc02003fc <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003cc:	4785                	li	a5,1
ffffffffc02003ce:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003d2:	8432                	mv	s0,a2
ffffffffc02003d4:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003d6:	862e                	mv	a2,a1
ffffffffc02003d8:	85aa                	mv	a1,a0
ffffffffc02003da:	00002517          	auipc	a0,0x2
ffffffffc02003de:	93e50513          	addi	a0,a0,-1730 # ffffffffc0201d18 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02003e2:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003e4:	ccfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003e8:	65a2                	ld	a1,8(sp)
ffffffffc02003ea:	8522                	mv	a0,s0
ffffffffc02003ec:	ca7ff0ef          	jal	ra,ffffffffc0200092 <vcprintf>
    cprintf("\n");
ffffffffc02003f0:	00001517          	auipc	a0,0x1
ffffffffc02003f4:	77050513          	addi	a0,a0,1904 # ffffffffc0201b60 <etext+0xec>
ffffffffc02003f8:	cbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003fc:	062000ef          	jal	ra,ffffffffc020045e <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200400:	4501                	li	a0,0
ffffffffc0200402:	e63ff0ef          	jal	ra,ffffffffc0200264 <kmonitor>
    while (1) {
ffffffffc0200406:	bfed                	j	ffffffffc0200400 <__panic+0x54>

ffffffffc0200408 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200408:	1141                	addi	sp,sp,-16
ffffffffc020040a:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc020040c:	02000793          	li	a5,32
ffffffffc0200410:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200414:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200418:	67e1                	lui	a5,0x18
ffffffffc020041a:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020041e:	953e                	add	a0,a0,a5
ffffffffc0200420:	5a2010ef          	jal	ra,ffffffffc02019c2 <sbi_set_timer>
}
ffffffffc0200424:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200426:	00006797          	auipc	a5,0x6
ffffffffc020042a:	0007b923          	sd	zero,18(a5) # ffffffffc0206438 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020042e:	00002517          	auipc	a0,0x2
ffffffffc0200432:	90a50513          	addi	a0,a0,-1782 # ffffffffc0201d38 <commands+0x68>
}
ffffffffc0200436:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200438:	b9ad                	j	ffffffffc02000b2 <cprintf>

ffffffffc020043a <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043a:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043e:	67e1                	lui	a5,0x18
ffffffffc0200440:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200444:	953e                	add	a0,a0,a5
ffffffffc0200446:	57c0106f          	j	ffffffffc02019c2 <sbi_set_timer>

ffffffffc020044a <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020044a:	8082                	ret

ffffffffc020044c <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020044c:	0ff57513          	zext.b	a0,a0
ffffffffc0200450:	5580106f          	j	ffffffffc02019a8 <sbi_console_putchar>

ffffffffc0200454 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200454:	5880106f          	j	ffffffffc02019dc <sbi_console_getchar>

ffffffffc0200458 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200458:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020045c:	8082                	ret

ffffffffc020045e <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045e:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200462:	8082                	ret

ffffffffc0200464 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200464:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200468:	00000797          	auipc	a5,0x0
ffffffffc020046c:	39078793          	addi	a5,a5,912 # ffffffffc02007f8 <__alltraps>
ffffffffc0200470:	10579073          	csrw	stvec,a5
}
ffffffffc0200474:	8082                	ret

ffffffffc0200476 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200476:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200478:	1141                	addi	sp,sp,-16
ffffffffc020047a:	e022                	sd	s0,0(sp)
ffffffffc020047c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047e:	00002517          	auipc	a0,0x2
ffffffffc0200482:	8da50513          	addi	a0,a0,-1830 # ffffffffc0201d58 <commands+0x88>
void print_regs(struct pushregs *gpr) {
ffffffffc0200486:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200488:	c2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020048c:	640c                	ld	a1,8(s0)
ffffffffc020048e:	00002517          	auipc	a0,0x2
ffffffffc0200492:	8e250513          	addi	a0,a0,-1822 # ffffffffc0201d70 <commands+0xa0>
ffffffffc0200496:	c1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020049a:	680c                	ld	a1,16(s0)
ffffffffc020049c:	00002517          	auipc	a0,0x2
ffffffffc02004a0:	8ec50513          	addi	a0,a0,-1812 # ffffffffc0201d88 <commands+0xb8>
ffffffffc02004a4:	c0fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004a8:	6c0c                	ld	a1,24(s0)
ffffffffc02004aa:	00002517          	auipc	a0,0x2
ffffffffc02004ae:	8f650513          	addi	a0,a0,-1802 # ffffffffc0201da0 <commands+0xd0>
ffffffffc02004b2:	c01ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004b6:	700c                	ld	a1,32(s0)
ffffffffc02004b8:	00002517          	auipc	a0,0x2
ffffffffc02004bc:	90050513          	addi	a0,a0,-1792 # ffffffffc0201db8 <commands+0xe8>
ffffffffc02004c0:	bf3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004c4:	740c                	ld	a1,40(s0)
ffffffffc02004c6:	00002517          	auipc	a0,0x2
ffffffffc02004ca:	90a50513          	addi	a0,a0,-1782 # ffffffffc0201dd0 <commands+0x100>
ffffffffc02004ce:	be5ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d2:	780c                	ld	a1,48(s0)
ffffffffc02004d4:	00002517          	auipc	a0,0x2
ffffffffc02004d8:	91450513          	addi	a0,a0,-1772 # ffffffffc0201de8 <commands+0x118>
ffffffffc02004dc:	bd7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e0:	7c0c                	ld	a1,56(s0)
ffffffffc02004e2:	00002517          	auipc	a0,0x2
ffffffffc02004e6:	91e50513          	addi	a0,a0,-1762 # ffffffffc0201e00 <commands+0x130>
ffffffffc02004ea:	bc9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004ee:	602c                	ld	a1,64(s0)
ffffffffc02004f0:	00002517          	auipc	a0,0x2
ffffffffc02004f4:	92850513          	addi	a0,a0,-1752 # ffffffffc0201e18 <commands+0x148>
ffffffffc02004f8:	bbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02004fc:	642c                	ld	a1,72(s0)
ffffffffc02004fe:	00002517          	auipc	a0,0x2
ffffffffc0200502:	93250513          	addi	a0,a0,-1742 # ffffffffc0201e30 <commands+0x160>
ffffffffc0200506:	badff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020050a:	682c                	ld	a1,80(s0)
ffffffffc020050c:	00002517          	auipc	a0,0x2
ffffffffc0200510:	93c50513          	addi	a0,a0,-1732 # ffffffffc0201e48 <commands+0x178>
ffffffffc0200514:	b9fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200518:	6c2c                	ld	a1,88(s0)
ffffffffc020051a:	00002517          	auipc	a0,0x2
ffffffffc020051e:	94650513          	addi	a0,a0,-1722 # ffffffffc0201e60 <commands+0x190>
ffffffffc0200522:	b91ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200526:	702c                	ld	a1,96(s0)
ffffffffc0200528:	00002517          	auipc	a0,0x2
ffffffffc020052c:	95050513          	addi	a0,a0,-1712 # ffffffffc0201e78 <commands+0x1a8>
ffffffffc0200530:	b83ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200534:	742c                	ld	a1,104(s0)
ffffffffc0200536:	00002517          	auipc	a0,0x2
ffffffffc020053a:	95a50513          	addi	a0,a0,-1702 # ffffffffc0201e90 <commands+0x1c0>
ffffffffc020053e:	b75ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200542:	782c                	ld	a1,112(s0)
ffffffffc0200544:	00002517          	auipc	a0,0x2
ffffffffc0200548:	96450513          	addi	a0,a0,-1692 # ffffffffc0201ea8 <commands+0x1d8>
ffffffffc020054c:	b67ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200550:	7c2c                	ld	a1,120(s0)
ffffffffc0200552:	00002517          	auipc	a0,0x2
ffffffffc0200556:	96e50513          	addi	a0,a0,-1682 # ffffffffc0201ec0 <commands+0x1f0>
ffffffffc020055a:	b59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020055e:	604c                	ld	a1,128(s0)
ffffffffc0200560:	00002517          	auipc	a0,0x2
ffffffffc0200564:	97850513          	addi	a0,a0,-1672 # ffffffffc0201ed8 <commands+0x208>
ffffffffc0200568:	b4bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020056c:	644c                	ld	a1,136(s0)
ffffffffc020056e:	00002517          	auipc	a0,0x2
ffffffffc0200572:	98250513          	addi	a0,a0,-1662 # ffffffffc0201ef0 <commands+0x220>
ffffffffc0200576:	b3dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020057a:	684c                	ld	a1,144(s0)
ffffffffc020057c:	00002517          	auipc	a0,0x2
ffffffffc0200580:	98c50513          	addi	a0,a0,-1652 # ffffffffc0201f08 <commands+0x238>
ffffffffc0200584:	b2fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200588:	6c4c                	ld	a1,152(s0)
ffffffffc020058a:	00002517          	auipc	a0,0x2
ffffffffc020058e:	99650513          	addi	a0,a0,-1642 # ffffffffc0201f20 <commands+0x250>
ffffffffc0200592:	b21ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200596:	704c                	ld	a1,160(s0)
ffffffffc0200598:	00002517          	auipc	a0,0x2
ffffffffc020059c:	9a050513          	addi	a0,a0,-1632 # ffffffffc0201f38 <commands+0x268>
ffffffffc02005a0:	b13ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005a4:	744c                	ld	a1,168(s0)
ffffffffc02005a6:	00002517          	auipc	a0,0x2
ffffffffc02005aa:	9aa50513          	addi	a0,a0,-1622 # ffffffffc0201f50 <commands+0x280>
ffffffffc02005ae:	b05ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b2:	784c                	ld	a1,176(s0)
ffffffffc02005b4:	00002517          	auipc	a0,0x2
ffffffffc02005b8:	9b450513          	addi	a0,a0,-1612 # ffffffffc0201f68 <commands+0x298>
ffffffffc02005bc:	af7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c0:	7c4c                	ld	a1,184(s0)
ffffffffc02005c2:	00002517          	auipc	a0,0x2
ffffffffc02005c6:	9be50513          	addi	a0,a0,-1602 # ffffffffc0201f80 <commands+0x2b0>
ffffffffc02005ca:	ae9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005ce:	606c                	ld	a1,192(s0)
ffffffffc02005d0:	00002517          	auipc	a0,0x2
ffffffffc02005d4:	9c850513          	addi	a0,a0,-1592 # ffffffffc0201f98 <commands+0x2c8>
ffffffffc02005d8:	adbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005dc:	646c                	ld	a1,200(s0)
ffffffffc02005de:	00002517          	auipc	a0,0x2
ffffffffc02005e2:	9d250513          	addi	a0,a0,-1582 # ffffffffc0201fb0 <commands+0x2e0>
ffffffffc02005e6:	acdff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005ea:	686c                	ld	a1,208(s0)
ffffffffc02005ec:	00002517          	auipc	a0,0x2
ffffffffc02005f0:	9dc50513          	addi	a0,a0,-1572 # ffffffffc0201fc8 <commands+0x2f8>
ffffffffc02005f4:	abfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005f8:	6c6c                	ld	a1,216(s0)
ffffffffc02005fa:	00002517          	auipc	a0,0x2
ffffffffc02005fe:	9e650513          	addi	a0,a0,-1562 # ffffffffc0201fe0 <commands+0x310>
ffffffffc0200602:	ab1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200606:	706c                	ld	a1,224(s0)
ffffffffc0200608:	00002517          	auipc	a0,0x2
ffffffffc020060c:	9f050513          	addi	a0,a0,-1552 # ffffffffc0201ff8 <commands+0x328>
ffffffffc0200610:	aa3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200614:	746c                	ld	a1,232(s0)
ffffffffc0200616:	00002517          	auipc	a0,0x2
ffffffffc020061a:	9fa50513          	addi	a0,a0,-1542 # ffffffffc0202010 <commands+0x340>
ffffffffc020061e:	a95ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200622:	786c                	ld	a1,240(s0)
ffffffffc0200624:	00002517          	auipc	a0,0x2
ffffffffc0200628:	a0450513          	addi	a0,a0,-1532 # ffffffffc0202028 <commands+0x358>
ffffffffc020062c:	a87ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200630:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200632:	6402                	ld	s0,0(sp)
ffffffffc0200634:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	00002517          	auipc	a0,0x2
ffffffffc020063a:	a0a50513          	addi	a0,a0,-1526 # ffffffffc0202040 <commands+0x370>
}
ffffffffc020063e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200640:	bc8d                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200642 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200642:	1141                	addi	sp,sp,-16
ffffffffc0200644:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200646:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200648:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc020064a:	00002517          	auipc	a0,0x2
ffffffffc020064e:	a0e50513          	addi	a0,a0,-1522 # ffffffffc0202058 <commands+0x388>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200652:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200654:	a5fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200658:	8522                	mv	a0,s0
ffffffffc020065a:	e1dff0ef          	jal	ra,ffffffffc0200476 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020065e:	10043583          	ld	a1,256(s0)
ffffffffc0200662:	00002517          	auipc	a0,0x2
ffffffffc0200666:	a0e50513          	addi	a0,a0,-1522 # ffffffffc0202070 <commands+0x3a0>
ffffffffc020066a:	a49ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020066e:	10843583          	ld	a1,264(s0)
ffffffffc0200672:	00002517          	auipc	a0,0x2
ffffffffc0200676:	a1650513          	addi	a0,a0,-1514 # ffffffffc0202088 <commands+0x3b8>
ffffffffc020067a:	a39ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020067e:	11043583          	ld	a1,272(s0)
ffffffffc0200682:	00002517          	auipc	a0,0x2
ffffffffc0200686:	a1e50513          	addi	a0,a0,-1506 # ffffffffc02020a0 <commands+0x3d0>
ffffffffc020068a:	a29ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020068e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200692:	6402                	ld	s0,0(sp)
ffffffffc0200694:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	00002517          	auipc	a0,0x2
ffffffffc020069a:	a2250513          	addi	a0,a0,-1502 # ffffffffc02020b8 <commands+0x3e8>
}
ffffffffc020069e:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006a0:	bc09                	j	ffffffffc02000b2 <cprintf>

ffffffffc02006a2 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006a2:	11853783          	ld	a5,280(a0)
ffffffffc02006a6:	472d                	li	a4,11
ffffffffc02006a8:	0786                	slli	a5,a5,0x1
ffffffffc02006aa:	8385                	srli	a5,a5,0x1
ffffffffc02006ac:	06f76e63          	bltu	a4,a5,ffffffffc0200728 <interrupt_handler+0x86>
ffffffffc02006b0:	00002717          	auipc	a4,0x2
ffffffffc02006b4:	ae870713          	addi	a4,a4,-1304 # ffffffffc0202198 <commands+0x4c8>
ffffffffc02006b8:	078a                	slli	a5,a5,0x2
ffffffffc02006ba:	97ba                	add	a5,a5,a4
ffffffffc02006bc:	439c                	lw	a5,0(a5)
ffffffffc02006be:	97ba                	add	a5,a5,a4
ffffffffc02006c0:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006c2:	00002517          	auipc	a0,0x2
ffffffffc02006c6:	a6e50513          	addi	a0,a0,-1426 # ffffffffc0202130 <commands+0x460>
ffffffffc02006ca:	b2e5                	j	ffffffffc02000b2 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006cc:	00002517          	auipc	a0,0x2
ffffffffc02006d0:	a4450513          	addi	a0,a0,-1468 # ffffffffc0202110 <commands+0x440>
ffffffffc02006d4:	baf9                	j	ffffffffc02000b2 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006d6:	00002517          	auipc	a0,0x2
ffffffffc02006da:	9fa50513          	addi	a0,a0,-1542 # ffffffffc02020d0 <commands+0x400>
ffffffffc02006de:	bad1                	j	ffffffffc02000b2 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006e0:	00002517          	auipc	a0,0x2
ffffffffc02006e4:	a7050513          	addi	a0,a0,-1424 # ffffffffc0202150 <commands+0x480>
ffffffffc02006e8:	b2e9                	j	ffffffffc02000b2 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02006ea:	1141                	addi	sp,sp,-16
ffffffffc02006ec:	e406                	sd	ra,8(sp)
ffffffffc02006ee:	e022                	sd	s0,0(sp)
    /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
	            clock_set_next_event();
ffffffffc02006f0:	d4bff0ef          	jal	ra,ffffffffc020043a <clock_set_next_event>
	            ticks+=1;
ffffffffc02006f4:	00006797          	auipc	a5,0x6
ffffffffc02006f8:	d4478793          	addi	a5,a5,-700 # ffffffffc0206438 <ticks>
ffffffffc02006fc:	6398                	ld	a4,0(a5)
	            if(ticks==100){
ffffffffc02006fe:	06400693          	li	a3,100
	            ticks+=1;
ffffffffc0200702:	0705                	addi	a4,a4,1
ffffffffc0200704:	e398                	sd	a4,0(a5)
	            if(ticks==100){
ffffffffc0200706:	639c                	ld	a5,0(a5)
ffffffffc0200708:	02d78163          	beq	a5,a3,ffffffffc020072a <interrupt_handler+0x88>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc020070c:	60a2                	ld	ra,8(sp)
ffffffffc020070e:	6402                	ld	s0,0(sp)
ffffffffc0200710:	0141                	addi	sp,sp,16
ffffffffc0200712:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200714:	00002517          	auipc	a0,0x2
ffffffffc0200718:	a6450513          	addi	a0,a0,-1436 # ffffffffc0202178 <commands+0x4a8>
ffffffffc020071c:	ba59                	j	ffffffffc02000b2 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc020071e:	00002517          	auipc	a0,0x2
ffffffffc0200722:	9d250513          	addi	a0,a0,-1582 # ffffffffc02020f0 <commands+0x420>
ffffffffc0200726:	b271                	j	ffffffffc02000b2 <cprintf>
            print_trapframe(tf);
ffffffffc0200728:	bf29                	j	ffffffffc0200642 <print_trapframe>
		            num+=1;
ffffffffc020072a:	00006417          	auipc	s0,0x6
ffffffffc020072e:	d1640413          	addi	s0,s0,-746 # ffffffffc0206440 <num>
ffffffffc0200732:	601c                	ld	a5,0(s0)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200734:	06400593          	li	a1,100
ffffffffc0200738:	00002517          	auipc	a0,0x2
ffffffffc020073c:	a3050513          	addi	a0,a0,-1488 # ffffffffc0202168 <commands+0x498>
		            num+=1;
ffffffffc0200740:	0785                	addi	a5,a5,1
ffffffffc0200742:	e01c                	sd	a5,0(s0)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200744:	96fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
		            ticks=0;
ffffffffc0200748:	00006797          	auipc	a5,0x6
ffffffffc020074c:	ce07b823          	sd	zero,-784(a5) # ffffffffc0206438 <ticks>
		        if(num==10){
ffffffffc0200750:	6018                	ld	a4,0(s0)
ffffffffc0200752:	47a9                	li	a5,10
ffffffffc0200754:	faf71ce3          	bne	a4,a5,ffffffffc020070c <interrupt_handler+0x6a>
}
ffffffffc0200758:	6402                	ld	s0,0(sp)
ffffffffc020075a:	60a2                	ld	ra,8(sp)
ffffffffc020075c:	0141                	addi	sp,sp,16
			    sbi_shutdown();
ffffffffc020075e:	29a0106f          	j	ffffffffc02019f8 <sbi_shutdown>

ffffffffc0200762 <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200762:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200766:	1141                	addi	sp,sp,-16
ffffffffc0200768:	e022                	sd	s0,0(sp)
ffffffffc020076a:	e406                	sd	ra,8(sp)
    switch (tf->cause) {
ffffffffc020076c:	470d                	li	a4,3
void exception_handler(struct trapframe *tf) {
ffffffffc020076e:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200770:	04e78663          	beq	a5,a4,ffffffffc02007bc <exception_handler+0x5a>
ffffffffc0200774:	02f76c63          	bltu	a4,a5,ffffffffc02007ac <exception_handler+0x4a>
ffffffffc0200778:	4709                	li	a4,2
ffffffffc020077a:	02e79563          	bne	a5,a4,ffffffffc02007a4 <exception_handler+0x42>
             /* LAB1 CHALLENGE3   YOUR CODE : 2213893 */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
	    cprintf("Exception type:Illegal instruction\n");
ffffffffc020077e:	00002517          	auipc	a0,0x2
ffffffffc0200782:	a4a50513          	addi	a0,a0,-1462 # ffffffffc02021c8 <commands+0x4f8>
ffffffffc0200786:	92dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
	    cprintf("Illegal instruction caught at %d",tf->badvaddr);
ffffffffc020078a:	11043583          	ld	a1,272(s0)
ffffffffc020078e:	00002517          	auipc	a0,0x2
ffffffffc0200792:	a6250513          	addi	a0,a0,-1438 # ffffffffc02021f0 <commands+0x520>
ffffffffc0200796:	91dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
	    tf->epc+=4;
ffffffffc020079a:	10843783          	ld	a5,264(s0)
ffffffffc020079e:	0791                	addi	a5,a5,4
ffffffffc02007a0:	10f43423          	sd	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc02007a4:	60a2                	ld	ra,8(sp)
ffffffffc02007a6:	6402                	ld	s0,0(sp)
ffffffffc02007a8:	0141                	addi	sp,sp,16
ffffffffc02007aa:	8082                	ret
    switch (tf->cause) {
ffffffffc02007ac:	17f1                	addi	a5,a5,-4
ffffffffc02007ae:	471d                	li	a4,7
ffffffffc02007b0:	fef77ae3          	bgeu	a4,a5,ffffffffc02007a4 <exception_handler+0x42>
}
ffffffffc02007b4:	6402                	ld	s0,0(sp)
ffffffffc02007b6:	60a2                	ld	ra,8(sp)
ffffffffc02007b8:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc02007ba:	b561                	j	ffffffffc0200642 <print_trapframe>
	    cprintf("Exception type:breakpoint\n");
ffffffffc02007bc:	00002517          	auipc	a0,0x2
ffffffffc02007c0:	a5c50513          	addi	a0,a0,-1444 # ffffffffc0202218 <commands+0x548>
ffffffffc02007c4:	8efff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
	    cprintf("ebreak caught at %d",tf->badvaddr);
ffffffffc02007c8:	11043583          	ld	a1,272(s0)
ffffffffc02007cc:	00002517          	auipc	a0,0x2
ffffffffc02007d0:	a6c50513          	addi	a0,a0,-1428 # ffffffffc0202238 <commands+0x568>
ffffffffc02007d4:	8dfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
	    tf->epc+=4;
ffffffffc02007d8:	10843783          	ld	a5,264(s0)
}
ffffffffc02007dc:	60a2                	ld	ra,8(sp)
	    tf->epc+=4;
ffffffffc02007de:	0791                	addi	a5,a5,4
ffffffffc02007e0:	10f43423          	sd	a5,264(s0)
}
ffffffffc02007e4:	6402                	ld	s0,0(sp)
ffffffffc02007e6:	0141                	addi	sp,sp,16
ffffffffc02007e8:	8082                	ret

ffffffffc02007ea <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc02007ea:	11853783          	ld	a5,280(a0)
ffffffffc02007ee:	0007c363          	bltz	a5,ffffffffc02007f4 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc02007f2:	bf85                	j	ffffffffc0200762 <exception_handler>
        interrupt_handler(tf);
ffffffffc02007f4:	b57d                	j	ffffffffc02006a2 <interrupt_handler>
	...

ffffffffc02007f8 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc02007f8:	14011073          	csrw	sscratch,sp
ffffffffc02007fc:	712d                	addi	sp,sp,-288
ffffffffc02007fe:	e002                	sd	zero,0(sp)
ffffffffc0200800:	e406                	sd	ra,8(sp)
ffffffffc0200802:	ec0e                	sd	gp,24(sp)
ffffffffc0200804:	f012                	sd	tp,32(sp)
ffffffffc0200806:	f416                	sd	t0,40(sp)
ffffffffc0200808:	f81a                	sd	t1,48(sp)
ffffffffc020080a:	fc1e                	sd	t2,56(sp)
ffffffffc020080c:	e0a2                	sd	s0,64(sp)
ffffffffc020080e:	e4a6                	sd	s1,72(sp)
ffffffffc0200810:	e8aa                	sd	a0,80(sp)
ffffffffc0200812:	ecae                	sd	a1,88(sp)
ffffffffc0200814:	f0b2                	sd	a2,96(sp)
ffffffffc0200816:	f4b6                	sd	a3,104(sp)
ffffffffc0200818:	f8ba                	sd	a4,112(sp)
ffffffffc020081a:	fcbe                	sd	a5,120(sp)
ffffffffc020081c:	e142                	sd	a6,128(sp)
ffffffffc020081e:	e546                	sd	a7,136(sp)
ffffffffc0200820:	e94a                	sd	s2,144(sp)
ffffffffc0200822:	ed4e                	sd	s3,152(sp)
ffffffffc0200824:	f152                	sd	s4,160(sp)
ffffffffc0200826:	f556                	sd	s5,168(sp)
ffffffffc0200828:	f95a                	sd	s6,176(sp)
ffffffffc020082a:	fd5e                	sd	s7,184(sp)
ffffffffc020082c:	e1e2                	sd	s8,192(sp)
ffffffffc020082e:	e5e6                	sd	s9,200(sp)
ffffffffc0200830:	e9ea                	sd	s10,208(sp)
ffffffffc0200832:	edee                	sd	s11,216(sp)
ffffffffc0200834:	f1f2                	sd	t3,224(sp)
ffffffffc0200836:	f5f6                	sd	t4,232(sp)
ffffffffc0200838:	f9fa                	sd	t5,240(sp)
ffffffffc020083a:	fdfe                	sd	t6,248(sp)
ffffffffc020083c:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200840:	100024f3          	csrr	s1,sstatus
ffffffffc0200844:	14102973          	csrr	s2,sepc
ffffffffc0200848:	143029f3          	csrr	s3,stval
ffffffffc020084c:	14202a73          	csrr	s4,scause
ffffffffc0200850:	e822                	sd	s0,16(sp)
ffffffffc0200852:	e226                	sd	s1,256(sp)
ffffffffc0200854:	e64a                	sd	s2,264(sp)
ffffffffc0200856:	ea4e                	sd	s3,272(sp)
ffffffffc0200858:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc020085a:	850a                	mv	a0,sp
    jal trap
ffffffffc020085c:	f8fff0ef          	jal	ra,ffffffffc02007ea <trap>

ffffffffc0200860 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200860:	6492                	ld	s1,256(sp)
ffffffffc0200862:	6932                	ld	s2,264(sp)
ffffffffc0200864:	10049073          	csrw	sstatus,s1
ffffffffc0200868:	14191073          	csrw	sepc,s2
ffffffffc020086c:	60a2                	ld	ra,8(sp)
ffffffffc020086e:	61e2                	ld	gp,24(sp)
ffffffffc0200870:	7202                	ld	tp,32(sp)
ffffffffc0200872:	72a2                	ld	t0,40(sp)
ffffffffc0200874:	7342                	ld	t1,48(sp)
ffffffffc0200876:	73e2                	ld	t2,56(sp)
ffffffffc0200878:	6406                	ld	s0,64(sp)
ffffffffc020087a:	64a6                	ld	s1,72(sp)
ffffffffc020087c:	6546                	ld	a0,80(sp)
ffffffffc020087e:	65e6                	ld	a1,88(sp)
ffffffffc0200880:	7606                	ld	a2,96(sp)
ffffffffc0200882:	76a6                	ld	a3,104(sp)
ffffffffc0200884:	7746                	ld	a4,112(sp)
ffffffffc0200886:	77e6                	ld	a5,120(sp)
ffffffffc0200888:	680a                	ld	a6,128(sp)
ffffffffc020088a:	68aa                	ld	a7,136(sp)
ffffffffc020088c:	694a                	ld	s2,144(sp)
ffffffffc020088e:	69ea                	ld	s3,152(sp)
ffffffffc0200890:	7a0a                	ld	s4,160(sp)
ffffffffc0200892:	7aaa                	ld	s5,168(sp)
ffffffffc0200894:	7b4a                	ld	s6,176(sp)
ffffffffc0200896:	7bea                	ld	s7,184(sp)
ffffffffc0200898:	6c0e                	ld	s8,192(sp)
ffffffffc020089a:	6cae                	ld	s9,200(sp)
ffffffffc020089c:	6d4e                	ld	s10,208(sp)
ffffffffc020089e:	6dee                	ld	s11,216(sp)
ffffffffc02008a0:	7e0e                	ld	t3,224(sp)
ffffffffc02008a2:	7eae                	ld	t4,232(sp)
ffffffffc02008a4:	7f4e                	ld	t5,240(sp)
ffffffffc02008a6:	7fee                	ld	t6,248(sp)
ffffffffc02008a8:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc02008aa:	10200073          	sret

ffffffffc02008ae <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02008ae:	00005797          	auipc	a5,0x5
ffffffffc02008b2:	76a78793          	addi	a5,a5,1898 # ffffffffc0206018 <free_area>
ffffffffc02008b6:	e79c                	sd	a5,8(a5)
ffffffffc02008b8:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02008ba:	0007a823          	sw	zero,16(a5)
}
ffffffffc02008be:	8082                	ret

ffffffffc02008c0 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02008c0:	00005517          	auipc	a0,0x5
ffffffffc02008c4:	76856503          	lwu	a0,1896(a0) # ffffffffc0206028 <free_area+0x10>
ffffffffc02008c8:	8082                	ret

ffffffffc02008ca <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc02008ca:	c14d                	beqz	a0,ffffffffc020096c <best_fit_alloc_pages+0xa2>
    if (n > nr_free) {
ffffffffc02008cc:	00005617          	auipc	a2,0x5
ffffffffc02008d0:	74c60613          	addi	a2,a2,1868 # ffffffffc0206018 <free_area>
ffffffffc02008d4:	01062803          	lw	a6,16(a2)
ffffffffc02008d8:	86aa                	mv	a3,a0
ffffffffc02008da:	02081793          	slli	a5,a6,0x20
ffffffffc02008de:	9381                	srli	a5,a5,0x20
ffffffffc02008e0:	08a7e463          	bltu	a5,a0,ffffffffc0200968 <best_fit_alloc_pages+0x9e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02008e4:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc02008e6:	0018059b          	addiw	a1,a6,1
ffffffffc02008ea:	1582                	slli	a1,a1,0x20
ffffffffc02008ec:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc02008ee:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc02008f0:	06c78b63          	beq	a5,a2,ffffffffc0200966 <best_fit_alloc_pages+0x9c>
        if (p->property >= n && p->property < min_size) {
ffffffffc02008f4:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02008f8:	00d76763          	bltu	a4,a3,ffffffffc0200906 <best_fit_alloc_pages+0x3c>
ffffffffc02008fc:	00b77563          	bgeu	a4,a1,ffffffffc0200906 <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc0200900:	fe878513          	addi	a0,a5,-24
ffffffffc0200904:	85ba                	mv	a1,a4
ffffffffc0200906:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200908:	fec796e3          	bne	a5,a2,ffffffffc02008f4 <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc020090c:	cd29                	beqz	a0,ffffffffc0200966 <best_fit_alloc_pages+0x9c>
    __list_del(listelm->prev, listelm->next);
ffffffffc020090e:	711c                	ld	a5,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200910:	6d18                	ld	a4,24(a0)
        if (page->property > n) {
ffffffffc0200912:	490c                	lw	a1,16(a0)
            p->property = page->property - n;
ffffffffc0200914:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200918:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020091a:	e398                	sd	a4,0(a5)
        if (page->property > n) {
ffffffffc020091c:	02059793          	slli	a5,a1,0x20
ffffffffc0200920:	9381                	srli	a5,a5,0x20
ffffffffc0200922:	02f6f863          	bgeu	a3,a5,ffffffffc0200952 <best_fit_alloc_pages+0x88>
            struct Page *p = page + n;
ffffffffc0200926:	00269793          	slli	a5,a3,0x2
ffffffffc020092a:	97b6                	add	a5,a5,a3
ffffffffc020092c:	078e                	slli	a5,a5,0x3
ffffffffc020092e:	97aa                	add	a5,a5,a0
            p->property = page->property - n;
ffffffffc0200930:	411585bb          	subw	a1,a1,a7
ffffffffc0200934:	cb8c                	sw	a1,16(a5)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200936:	4689                	li	a3,2
ffffffffc0200938:	00878593          	addi	a1,a5,8
ffffffffc020093c:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200940:	6714                	ld	a3,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc0200942:	01878593          	addi	a1,a5,24
        nr_free -= n;
ffffffffc0200946:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc020094a:	e28c                	sd	a1,0(a3)
ffffffffc020094c:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc020094e:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc0200950:	ef98                	sd	a4,24(a5)
ffffffffc0200952:	4118083b          	subw	a6,a6,a7
ffffffffc0200956:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020095a:	57f5                	li	a5,-3
ffffffffc020095c:	00850713          	addi	a4,a0,8
ffffffffc0200960:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc0200964:	8082                	ret
}
ffffffffc0200966:	8082                	ret
        return NULL;
ffffffffc0200968:	4501                	li	a0,0
ffffffffc020096a:	8082                	ret
static struct Page * best_fit_alloc_pages(size_t n) {
ffffffffc020096c:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020096e:	00002697          	auipc	a3,0x2
ffffffffc0200972:	8e268693          	addi	a3,a3,-1822 # ffffffffc0202250 <commands+0x580>
ffffffffc0200976:	00002617          	auipc	a2,0x2
ffffffffc020097a:	8e260613          	addi	a2,a2,-1822 # ffffffffc0202258 <commands+0x588>
ffffffffc020097e:	06d00593          	li	a1,109
ffffffffc0200982:	00002517          	auipc	a0,0x2
ffffffffc0200986:	8ee50513          	addi	a0,a0,-1810 # ffffffffc0202270 <commands+0x5a0>
static struct Page * best_fit_alloc_pages(size_t n) {
ffffffffc020098a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020098c:	a21ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200990 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0200990:	715d                	addi	sp,sp,-80
ffffffffc0200992:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0200994:	00005417          	auipc	s0,0x5
ffffffffc0200998:	68440413          	addi	s0,s0,1668 # ffffffffc0206018 <free_area>
ffffffffc020099c:	641c                	ld	a5,8(s0)
ffffffffc020099e:	e486                	sd	ra,72(sp)
ffffffffc02009a0:	fc26                	sd	s1,56(sp)
ffffffffc02009a2:	f84a                	sd	s2,48(sp)
ffffffffc02009a4:	f44e                	sd	s3,40(sp)
ffffffffc02009a6:	f052                	sd	s4,32(sp)
ffffffffc02009a8:	ec56                	sd	s5,24(sp)
ffffffffc02009aa:	e85a                	sd	s6,16(sp)
ffffffffc02009ac:	e45e                	sd	s7,8(sp)
ffffffffc02009ae:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02009b0:	26878b63          	beq	a5,s0,ffffffffc0200c26 <best_fit_check+0x296>
    int count = 0, total = 0;
ffffffffc02009b4:	4481                	li	s1,0
ffffffffc02009b6:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02009b8:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02009bc:	8b09                	andi	a4,a4,2
ffffffffc02009be:	26070863          	beqz	a4,ffffffffc0200c2e <best_fit_check+0x29e>
        count ++, total += p->property;
ffffffffc02009c2:	ff87a703          	lw	a4,-8(a5)
ffffffffc02009c6:	679c                	ld	a5,8(a5)
ffffffffc02009c8:	2905                	addiw	s2,s2,1
ffffffffc02009ca:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02009cc:	fe8796e3          	bne	a5,s0,ffffffffc02009b8 <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02009d0:	89a6                	mv	s3,s1
ffffffffc02009d2:	167000ef          	jal	ra,ffffffffc0201338 <nr_free_pages>
ffffffffc02009d6:	33351c63          	bne	a0,s3,ffffffffc0200d0e <best_fit_check+0x37e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02009da:	4505                	li	a0,1
ffffffffc02009dc:	0df000ef          	jal	ra,ffffffffc02012ba <alloc_pages>
ffffffffc02009e0:	8a2a                	mv	s4,a0
ffffffffc02009e2:	36050663          	beqz	a0,ffffffffc0200d4e <best_fit_check+0x3be>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02009e6:	4505                	li	a0,1
ffffffffc02009e8:	0d3000ef          	jal	ra,ffffffffc02012ba <alloc_pages>
ffffffffc02009ec:	89aa                	mv	s3,a0
ffffffffc02009ee:	34050063          	beqz	a0,ffffffffc0200d2e <best_fit_check+0x39e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009f2:	4505                	li	a0,1
ffffffffc02009f4:	0c7000ef          	jal	ra,ffffffffc02012ba <alloc_pages>
ffffffffc02009f8:	8aaa                	mv	s5,a0
ffffffffc02009fa:	2c050a63          	beqz	a0,ffffffffc0200cce <best_fit_check+0x33e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02009fe:	253a0863          	beq	s4,s3,ffffffffc0200c4e <best_fit_check+0x2be>
ffffffffc0200a02:	24aa0663          	beq	s4,a0,ffffffffc0200c4e <best_fit_check+0x2be>
ffffffffc0200a06:	24a98463          	beq	s3,a0,ffffffffc0200c4e <best_fit_check+0x2be>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200a0a:	000a2783          	lw	a5,0(s4)
ffffffffc0200a0e:	26079063          	bnez	a5,ffffffffc0200c6e <best_fit_check+0x2de>
ffffffffc0200a12:	0009a783          	lw	a5,0(s3)
ffffffffc0200a16:	24079c63          	bnez	a5,ffffffffc0200c6e <best_fit_check+0x2de>
ffffffffc0200a1a:	411c                	lw	a5,0(a0)
ffffffffc0200a1c:	24079963          	bnez	a5,ffffffffc0200c6e <best_fit_check+0x2de>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200a20:	00006797          	auipc	a5,0x6
ffffffffc0200a24:	a307b783          	ld	a5,-1488(a5) # ffffffffc0206450 <pages>
ffffffffc0200a28:	40fa0733          	sub	a4,s4,a5
ffffffffc0200a2c:	870d                	srai	a4,a4,0x3
ffffffffc0200a2e:	00002597          	auipc	a1,0x2
ffffffffc0200a32:	f125b583          	ld	a1,-238(a1) # ffffffffc0202940 <error_string+0x38>
ffffffffc0200a36:	02b70733          	mul	a4,a4,a1
ffffffffc0200a3a:	00002617          	auipc	a2,0x2
ffffffffc0200a3e:	f0e63603          	ld	a2,-242(a2) # ffffffffc0202948 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200a42:	00006697          	auipc	a3,0x6
ffffffffc0200a46:	a066b683          	ld	a3,-1530(a3) # ffffffffc0206448 <npage>
ffffffffc0200a4a:	06b2                	slli	a3,a3,0xc
ffffffffc0200a4c:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200a4e:	0732                	slli	a4,a4,0xc
ffffffffc0200a50:	22d77f63          	bgeu	a4,a3,ffffffffc0200c8e <best_fit_check+0x2fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200a54:	40f98733          	sub	a4,s3,a5
ffffffffc0200a58:	870d                	srai	a4,a4,0x3
ffffffffc0200a5a:	02b70733          	mul	a4,a4,a1
ffffffffc0200a5e:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200a60:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200a62:	3ed77663          	bgeu	a4,a3,ffffffffc0200e4e <best_fit_check+0x4be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200a66:	40f507b3          	sub	a5,a0,a5
ffffffffc0200a6a:	878d                	srai	a5,a5,0x3
ffffffffc0200a6c:	02b787b3          	mul	a5,a5,a1
ffffffffc0200a70:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200a72:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200a74:	3ad7fd63          	bgeu	a5,a3,ffffffffc0200e2e <best_fit_check+0x49e>
    assert(alloc_page() == NULL);
ffffffffc0200a78:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200a7a:	00043c03          	ld	s8,0(s0)
ffffffffc0200a7e:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200a82:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200a86:	e400                	sd	s0,8(s0)
ffffffffc0200a88:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200a8a:	00005797          	auipc	a5,0x5
ffffffffc0200a8e:	5807af23          	sw	zero,1438(a5) # ffffffffc0206028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200a92:	029000ef          	jal	ra,ffffffffc02012ba <alloc_pages>
ffffffffc0200a96:	36051c63          	bnez	a0,ffffffffc0200e0e <best_fit_check+0x47e>
    free_page(p0);
ffffffffc0200a9a:	4585                	li	a1,1
ffffffffc0200a9c:	8552                	mv	a0,s4
ffffffffc0200a9e:	05b000ef          	jal	ra,ffffffffc02012f8 <free_pages>
    free_page(p1);
ffffffffc0200aa2:	4585                	li	a1,1
ffffffffc0200aa4:	854e                	mv	a0,s3
ffffffffc0200aa6:	053000ef          	jal	ra,ffffffffc02012f8 <free_pages>
    free_page(p2);
ffffffffc0200aaa:	4585                	li	a1,1
ffffffffc0200aac:	8556                	mv	a0,s5
ffffffffc0200aae:	04b000ef          	jal	ra,ffffffffc02012f8 <free_pages>
    assert(nr_free == 3);
ffffffffc0200ab2:	4818                	lw	a4,16(s0)
ffffffffc0200ab4:	478d                	li	a5,3
ffffffffc0200ab6:	32f71c63          	bne	a4,a5,ffffffffc0200dee <best_fit_check+0x45e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200aba:	4505                	li	a0,1
ffffffffc0200abc:	7fe000ef          	jal	ra,ffffffffc02012ba <alloc_pages>
ffffffffc0200ac0:	89aa                	mv	s3,a0
ffffffffc0200ac2:	30050663          	beqz	a0,ffffffffc0200dce <best_fit_check+0x43e>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ac6:	4505                	li	a0,1
ffffffffc0200ac8:	7f2000ef          	jal	ra,ffffffffc02012ba <alloc_pages>
ffffffffc0200acc:	8aaa                	mv	s5,a0
ffffffffc0200ace:	2e050063          	beqz	a0,ffffffffc0200dae <best_fit_check+0x41e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ad2:	4505                	li	a0,1
ffffffffc0200ad4:	7e6000ef          	jal	ra,ffffffffc02012ba <alloc_pages>
ffffffffc0200ad8:	8a2a                	mv	s4,a0
ffffffffc0200ada:	2a050a63          	beqz	a0,ffffffffc0200d8e <best_fit_check+0x3fe>
    assert(alloc_page() == NULL);
ffffffffc0200ade:	4505                	li	a0,1
ffffffffc0200ae0:	7da000ef          	jal	ra,ffffffffc02012ba <alloc_pages>
ffffffffc0200ae4:	28051563          	bnez	a0,ffffffffc0200d6e <best_fit_check+0x3de>
    free_page(p0);
ffffffffc0200ae8:	4585                	li	a1,1
ffffffffc0200aea:	854e                	mv	a0,s3
ffffffffc0200aec:	00d000ef          	jal	ra,ffffffffc02012f8 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200af0:	641c                	ld	a5,8(s0)
ffffffffc0200af2:	1a878e63          	beq	a5,s0,ffffffffc0200cae <best_fit_check+0x31e>
    assert((p = alloc_page()) == p0);
ffffffffc0200af6:	4505                	li	a0,1
ffffffffc0200af8:	7c2000ef          	jal	ra,ffffffffc02012ba <alloc_pages>
ffffffffc0200afc:	52a99963          	bne	s3,a0,ffffffffc020102e <best_fit_check+0x69e>
    assert(alloc_page() == NULL);
ffffffffc0200b00:	4505                	li	a0,1
ffffffffc0200b02:	7b8000ef          	jal	ra,ffffffffc02012ba <alloc_pages>
ffffffffc0200b06:	50051463          	bnez	a0,ffffffffc020100e <best_fit_check+0x67e>
    assert(nr_free == 0);
ffffffffc0200b0a:	481c                	lw	a5,16(s0)
ffffffffc0200b0c:	4e079163          	bnez	a5,ffffffffc0200fee <best_fit_check+0x65e>
    free_page(p);
ffffffffc0200b10:	854e                	mv	a0,s3
ffffffffc0200b12:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200b14:	01843023          	sd	s8,0(s0)
ffffffffc0200b18:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200b1c:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200b20:	7d8000ef          	jal	ra,ffffffffc02012f8 <free_pages>
    free_page(p1);
ffffffffc0200b24:	4585                	li	a1,1
ffffffffc0200b26:	8556                	mv	a0,s5
ffffffffc0200b28:	7d0000ef          	jal	ra,ffffffffc02012f8 <free_pages>
    free_page(p2);
ffffffffc0200b2c:	4585                	li	a1,1
ffffffffc0200b2e:	8552                	mv	a0,s4
ffffffffc0200b30:	7c8000ef          	jal	ra,ffffffffc02012f8 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200b34:	4515                	li	a0,5
ffffffffc0200b36:	784000ef          	jal	ra,ffffffffc02012ba <alloc_pages>
ffffffffc0200b3a:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200b3c:	48050963          	beqz	a0,ffffffffc0200fce <best_fit_check+0x63e>
ffffffffc0200b40:	651c                	ld	a5,8(a0)
ffffffffc0200b42:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200b44:	8b85                	andi	a5,a5,1
ffffffffc0200b46:	46079463          	bnez	a5,ffffffffc0200fae <best_fit_check+0x61e>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200b4a:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200b4c:	00043a83          	ld	s5,0(s0)
ffffffffc0200b50:	00843a03          	ld	s4,8(s0)
ffffffffc0200b54:	e000                	sd	s0,0(s0)
ffffffffc0200b56:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200b58:	762000ef          	jal	ra,ffffffffc02012ba <alloc_pages>
ffffffffc0200b5c:	42051963          	bnez	a0,ffffffffc0200f8e <best_fit_check+0x5fe>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200b60:	4589                	li	a1,2
ffffffffc0200b62:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200b66:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200b6a:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200b6e:	00005797          	auipc	a5,0x5
ffffffffc0200b72:	4a07ad23          	sw	zero,1210(a5) # ffffffffc0206028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200b76:	782000ef          	jal	ra,ffffffffc02012f8 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200b7a:	8562                	mv	a0,s8
ffffffffc0200b7c:	4585                	li	a1,1
ffffffffc0200b7e:	77a000ef          	jal	ra,ffffffffc02012f8 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200b82:	4511                	li	a0,4
ffffffffc0200b84:	736000ef          	jal	ra,ffffffffc02012ba <alloc_pages>
ffffffffc0200b88:	3e051363          	bnez	a0,ffffffffc0200f6e <best_fit_check+0x5de>
ffffffffc0200b8c:	0309b783          	ld	a5,48(s3)
ffffffffc0200b90:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200b92:	8b85                	andi	a5,a5,1
ffffffffc0200b94:	3a078d63          	beqz	a5,ffffffffc0200f4e <best_fit_check+0x5be>
ffffffffc0200b98:	0389a703          	lw	a4,56(s3)
ffffffffc0200b9c:	4789                	li	a5,2
ffffffffc0200b9e:	3af71863          	bne	a4,a5,ffffffffc0200f4e <best_fit_check+0x5be>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200ba2:	4505                	li	a0,1
ffffffffc0200ba4:	716000ef          	jal	ra,ffffffffc02012ba <alloc_pages>
ffffffffc0200ba8:	8baa                	mv	s7,a0
ffffffffc0200baa:	38050263          	beqz	a0,ffffffffc0200f2e <best_fit_check+0x59e>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200bae:	4509                	li	a0,2
ffffffffc0200bb0:	70a000ef          	jal	ra,ffffffffc02012ba <alloc_pages>
ffffffffc0200bb4:	34050d63          	beqz	a0,ffffffffc0200f0e <best_fit_check+0x57e>
    assert(p0 + 4 == p1);
ffffffffc0200bb8:	337c1b63          	bne	s8,s7,ffffffffc0200eee <best_fit_check+0x55e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200bbc:	854e                	mv	a0,s3
ffffffffc0200bbe:	4595                	li	a1,5
ffffffffc0200bc0:	738000ef          	jal	ra,ffffffffc02012f8 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200bc4:	4515                	li	a0,5
ffffffffc0200bc6:	6f4000ef          	jal	ra,ffffffffc02012ba <alloc_pages>
ffffffffc0200bca:	89aa                	mv	s3,a0
ffffffffc0200bcc:	30050163          	beqz	a0,ffffffffc0200ece <best_fit_check+0x53e>
    assert(alloc_page() == NULL);
ffffffffc0200bd0:	4505                	li	a0,1
ffffffffc0200bd2:	6e8000ef          	jal	ra,ffffffffc02012ba <alloc_pages>
ffffffffc0200bd6:	2c051c63          	bnez	a0,ffffffffc0200eae <best_fit_check+0x51e>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200bda:	481c                	lw	a5,16(s0)
ffffffffc0200bdc:	2a079963          	bnez	a5,ffffffffc0200e8e <best_fit_check+0x4fe>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200be0:	4595                	li	a1,5
ffffffffc0200be2:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200be4:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc0200be8:	01543023          	sd	s5,0(s0)
ffffffffc0200bec:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc0200bf0:	708000ef          	jal	ra,ffffffffc02012f8 <free_pages>
    return listelm->next;
ffffffffc0200bf4:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200bf6:	00878963          	beq	a5,s0,ffffffffc0200c08 <best_fit_check+0x278>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200bfa:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200bfe:	679c                	ld	a5,8(a5)
ffffffffc0200c00:	397d                	addiw	s2,s2,-1
ffffffffc0200c02:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c04:	fe879be3          	bne	a5,s0,ffffffffc0200bfa <best_fit_check+0x26a>
    }
    assert(count == 0);
ffffffffc0200c08:	26091363          	bnez	s2,ffffffffc0200e6e <best_fit_check+0x4de>
    assert(total == 0);
ffffffffc0200c0c:	e0ed                	bnez	s1,ffffffffc0200cee <best_fit_check+0x35e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200c0e:	60a6                	ld	ra,72(sp)
ffffffffc0200c10:	6406                	ld	s0,64(sp)
ffffffffc0200c12:	74e2                	ld	s1,56(sp)
ffffffffc0200c14:	7942                	ld	s2,48(sp)
ffffffffc0200c16:	79a2                	ld	s3,40(sp)
ffffffffc0200c18:	7a02                	ld	s4,32(sp)
ffffffffc0200c1a:	6ae2                	ld	s5,24(sp)
ffffffffc0200c1c:	6b42                	ld	s6,16(sp)
ffffffffc0200c1e:	6ba2                	ld	s7,8(sp)
ffffffffc0200c20:	6c02                	ld	s8,0(sp)
ffffffffc0200c22:	6161                	addi	sp,sp,80
ffffffffc0200c24:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c26:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200c28:	4481                	li	s1,0
ffffffffc0200c2a:	4901                	li	s2,0
ffffffffc0200c2c:	b35d                	j	ffffffffc02009d2 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200c2e:	00001697          	auipc	a3,0x1
ffffffffc0200c32:	65a68693          	addi	a3,a3,1626 # ffffffffc0202288 <commands+0x5b8>
ffffffffc0200c36:	00001617          	auipc	a2,0x1
ffffffffc0200c3a:	62260613          	addi	a2,a2,1570 # ffffffffc0202258 <commands+0x588>
ffffffffc0200c3e:	10d00593          	li	a1,269
ffffffffc0200c42:	00001517          	auipc	a0,0x1
ffffffffc0200c46:	62e50513          	addi	a0,a0,1582 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200c4a:	f62ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200c4e:	00001697          	auipc	a3,0x1
ffffffffc0200c52:	6ca68693          	addi	a3,a3,1738 # ffffffffc0202318 <commands+0x648>
ffffffffc0200c56:	00001617          	auipc	a2,0x1
ffffffffc0200c5a:	60260613          	addi	a2,a2,1538 # ffffffffc0202258 <commands+0x588>
ffffffffc0200c5e:	0d900593          	li	a1,217
ffffffffc0200c62:	00001517          	auipc	a0,0x1
ffffffffc0200c66:	60e50513          	addi	a0,a0,1550 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200c6a:	f42ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200c6e:	00001697          	auipc	a3,0x1
ffffffffc0200c72:	6d268693          	addi	a3,a3,1746 # ffffffffc0202340 <commands+0x670>
ffffffffc0200c76:	00001617          	auipc	a2,0x1
ffffffffc0200c7a:	5e260613          	addi	a2,a2,1506 # ffffffffc0202258 <commands+0x588>
ffffffffc0200c7e:	0da00593          	li	a1,218
ffffffffc0200c82:	00001517          	auipc	a0,0x1
ffffffffc0200c86:	5ee50513          	addi	a0,a0,1518 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200c8a:	f22ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200c8e:	00001697          	auipc	a3,0x1
ffffffffc0200c92:	6f268693          	addi	a3,a3,1778 # ffffffffc0202380 <commands+0x6b0>
ffffffffc0200c96:	00001617          	auipc	a2,0x1
ffffffffc0200c9a:	5c260613          	addi	a2,a2,1474 # ffffffffc0202258 <commands+0x588>
ffffffffc0200c9e:	0dc00593          	li	a1,220
ffffffffc0200ca2:	00001517          	auipc	a0,0x1
ffffffffc0200ca6:	5ce50513          	addi	a0,a0,1486 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200caa:	f02ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200cae:	00001697          	auipc	a3,0x1
ffffffffc0200cb2:	75a68693          	addi	a3,a3,1882 # ffffffffc0202408 <commands+0x738>
ffffffffc0200cb6:	00001617          	auipc	a2,0x1
ffffffffc0200cba:	5a260613          	addi	a2,a2,1442 # ffffffffc0202258 <commands+0x588>
ffffffffc0200cbe:	0f500593          	li	a1,245
ffffffffc0200cc2:	00001517          	auipc	a0,0x1
ffffffffc0200cc6:	5ae50513          	addi	a0,a0,1454 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200cca:	ee2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200cce:	00001697          	auipc	a3,0x1
ffffffffc0200cd2:	62a68693          	addi	a3,a3,1578 # ffffffffc02022f8 <commands+0x628>
ffffffffc0200cd6:	00001617          	auipc	a2,0x1
ffffffffc0200cda:	58260613          	addi	a2,a2,1410 # ffffffffc0202258 <commands+0x588>
ffffffffc0200cde:	0d700593          	li	a1,215
ffffffffc0200ce2:	00001517          	auipc	a0,0x1
ffffffffc0200ce6:	58e50513          	addi	a0,a0,1422 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200cea:	ec2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(total == 0);
ffffffffc0200cee:	00002697          	auipc	a3,0x2
ffffffffc0200cf2:	84a68693          	addi	a3,a3,-1974 # ffffffffc0202538 <commands+0x868>
ffffffffc0200cf6:	00001617          	auipc	a2,0x1
ffffffffc0200cfa:	56260613          	addi	a2,a2,1378 # ffffffffc0202258 <commands+0x588>
ffffffffc0200cfe:	14f00593          	li	a1,335
ffffffffc0200d02:	00001517          	auipc	a0,0x1
ffffffffc0200d06:	56e50513          	addi	a0,a0,1390 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200d0a:	ea2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(total == nr_free_pages());
ffffffffc0200d0e:	00001697          	auipc	a3,0x1
ffffffffc0200d12:	58a68693          	addi	a3,a3,1418 # ffffffffc0202298 <commands+0x5c8>
ffffffffc0200d16:	00001617          	auipc	a2,0x1
ffffffffc0200d1a:	54260613          	addi	a2,a2,1346 # ffffffffc0202258 <commands+0x588>
ffffffffc0200d1e:	11000593          	li	a1,272
ffffffffc0200d22:	00001517          	auipc	a0,0x1
ffffffffc0200d26:	54e50513          	addi	a0,a0,1358 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200d2a:	e82ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d2e:	00001697          	auipc	a3,0x1
ffffffffc0200d32:	5aa68693          	addi	a3,a3,1450 # ffffffffc02022d8 <commands+0x608>
ffffffffc0200d36:	00001617          	auipc	a2,0x1
ffffffffc0200d3a:	52260613          	addi	a2,a2,1314 # ffffffffc0202258 <commands+0x588>
ffffffffc0200d3e:	0d600593          	li	a1,214
ffffffffc0200d42:	00001517          	auipc	a0,0x1
ffffffffc0200d46:	52e50513          	addi	a0,a0,1326 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200d4a:	e62ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d4e:	00001697          	auipc	a3,0x1
ffffffffc0200d52:	56a68693          	addi	a3,a3,1386 # ffffffffc02022b8 <commands+0x5e8>
ffffffffc0200d56:	00001617          	auipc	a2,0x1
ffffffffc0200d5a:	50260613          	addi	a2,a2,1282 # ffffffffc0202258 <commands+0x588>
ffffffffc0200d5e:	0d500593          	li	a1,213
ffffffffc0200d62:	00001517          	auipc	a0,0x1
ffffffffc0200d66:	50e50513          	addi	a0,a0,1294 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200d6a:	e42ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d6e:	00001697          	auipc	a3,0x1
ffffffffc0200d72:	67268693          	addi	a3,a3,1650 # ffffffffc02023e0 <commands+0x710>
ffffffffc0200d76:	00001617          	auipc	a2,0x1
ffffffffc0200d7a:	4e260613          	addi	a2,a2,1250 # ffffffffc0202258 <commands+0x588>
ffffffffc0200d7e:	0f200593          	li	a1,242
ffffffffc0200d82:	00001517          	auipc	a0,0x1
ffffffffc0200d86:	4ee50513          	addi	a0,a0,1262 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200d8a:	e22ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d8e:	00001697          	auipc	a3,0x1
ffffffffc0200d92:	56a68693          	addi	a3,a3,1386 # ffffffffc02022f8 <commands+0x628>
ffffffffc0200d96:	00001617          	auipc	a2,0x1
ffffffffc0200d9a:	4c260613          	addi	a2,a2,1218 # ffffffffc0202258 <commands+0x588>
ffffffffc0200d9e:	0f000593          	li	a1,240
ffffffffc0200da2:	00001517          	auipc	a0,0x1
ffffffffc0200da6:	4ce50513          	addi	a0,a0,1230 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200daa:	e02ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200dae:	00001697          	auipc	a3,0x1
ffffffffc0200db2:	52a68693          	addi	a3,a3,1322 # ffffffffc02022d8 <commands+0x608>
ffffffffc0200db6:	00001617          	auipc	a2,0x1
ffffffffc0200dba:	4a260613          	addi	a2,a2,1186 # ffffffffc0202258 <commands+0x588>
ffffffffc0200dbe:	0ef00593          	li	a1,239
ffffffffc0200dc2:	00001517          	auipc	a0,0x1
ffffffffc0200dc6:	4ae50513          	addi	a0,a0,1198 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200dca:	de2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200dce:	00001697          	auipc	a3,0x1
ffffffffc0200dd2:	4ea68693          	addi	a3,a3,1258 # ffffffffc02022b8 <commands+0x5e8>
ffffffffc0200dd6:	00001617          	auipc	a2,0x1
ffffffffc0200dda:	48260613          	addi	a2,a2,1154 # ffffffffc0202258 <commands+0x588>
ffffffffc0200dde:	0ee00593          	li	a1,238
ffffffffc0200de2:	00001517          	auipc	a0,0x1
ffffffffc0200de6:	48e50513          	addi	a0,a0,1166 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200dea:	dc2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 3);
ffffffffc0200dee:	00001697          	auipc	a3,0x1
ffffffffc0200df2:	60a68693          	addi	a3,a3,1546 # ffffffffc02023f8 <commands+0x728>
ffffffffc0200df6:	00001617          	auipc	a2,0x1
ffffffffc0200dfa:	46260613          	addi	a2,a2,1122 # ffffffffc0202258 <commands+0x588>
ffffffffc0200dfe:	0ec00593          	li	a1,236
ffffffffc0200e02:	00001517          	auipc	a0,0x1
ffffffffc0200e06:	46e50513          	addi	a0,a0,1134 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200e0a:	da2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e0e:	00001697          	auipc	a3,0x1
ffffffffc0200e12:	5d268693          	addi	a3,a3,1490 # ffffffffc02023e0 <commands+0x710>
ffffffffc0200e16:	00001617          	auipc	a2,0x1
ffffffffc0200e1a:	44260613          	addi	a2,a2,1090 # ffffffffc0202258 <commands+0x588>
ffffffffc0200e1e:	0e700593          	li	a1,231
ffffffffc0200e22:	00001517          	auipc	a0,0x1
ffffffffc0200e26:	44e50513          	addi	a0,a0,1102 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200e2a:	d82ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e2e:	00001697          	auipc	a3,0x1
ffffffffc0200e32:	59268693          	addi	a3,a3,1426 # ffffffffc02023c0 <commands+0x6f0>
ffffffffc0200e36:	00001617          	auipc	a2,0x1
ffffffffc0200e3a:	42260613          	addi	a2,a2,1058 # ffffffffc0202258 <commands+0x588>
ffffffffc0200e3e:	0de00593          	li	a1,222
ffffffffc0200e42:	00001517          	auipc	a0,0x1
ffffffffc0200e46:	42e50513          	addi	a0,a0,1070 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200e4a:	d62ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e4e:	00001697          	auipc	a3,0x1
ffffffffc0200e52:	55268693          	addi	a3,a3,1362 # ffffffffc02023a0 <commands+0x6d0>
ffffffffc0200e56:	00001617          	auipc	a2,0x1
ffffffffc0200e5a:	40260613          	addi	a2,a2,1026 # ffffffffc0202258 <commands+0x588>
ffffffffc0200e5e:	0dd00593          	li	a1,221
ffffffffc0200e62:	00001517          	auipc	a0,0x1
ffffffffc0200e66:	40e50513          	addi	a0,a0,1038 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200e6a:	d42ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(count == 0);
ffffffffc0200e6e:	00001697          	auipc	a3,0x1
ffffffffc0200e72:	6ba68693          	addi	a3,a3,1722 # ffffffffc0202528 <commands+0x858>
ffffffffc0200e76:	00001617          	auipc	a2,0x1
ffffffffc0200e7a:	3e260613          	addi	a2,a2,994 # ffffffffc0202258 <commands+0x588>
ffffffffc0200e7e:	14e00593          	li	a1,334
ffffffffc0200e82:	00001517          	auipc	a0,0x1
ffffffffc0200e86:	3ee50513          	addi	a0,a0,1006 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200e8a:	d22ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 0);
ffffffffc0200e8e:	00001697          	auipc	a3,0x1
ffffffffc0200e92:	5b268693          	addi	a3,a3,1458 # ffffffffc0202440 <commands+0x770>
ffffffffc0200e96:	00001617          	auipc	a2,0x1
ffffffffc0200e9a:	3c260613          	addi	a2,a2,962 # ffffffffc0202258 <commands+0x588>
ffffffffc0200e9e:	14300593          	li	a1,323
ffffffffc0200ea2:	00001517          	auipc	a0,0x1
ffffffffc0200ea6:	3ce50513          	addi	a0,a0,974 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200eaa:	d02ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200eae:	00001697          	auipc	a3,0x1
ffffffffc0200eb2:	53268693          	addi	a3,a3,1330 # ffffffffc02023e0 <commands+0x710>
ffffffffc0200eb6:	00001617          	auipc	a2,0x1
ffffffffc0200eba:	3a260613          	addi	a2,a2,930 # ffffffffc0202258 <commands+0x588>
ffffffffc0200ebe:	13d00593          	li	a1,317
ffffffffc0200ec2:	00001517          	auipc	a0,0x1
ffffffffc0200ec6:	3ae50513          	addi	a0,a0,942 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200eca:	ce2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200ece:	00001697          	auipc	a3,0x1
ffffffffc0200ed2:	63a68693          	addi	a3,a3,1594 # ffffffffc0202508 <commands+0x838>
ffffffffc0200ed6:	00001617          	auipc	a2,0x1
ffffffffc0200eda:	38260613          	addi	a2,a2,898 # ffffffffc0202258 <commands+0x588>
ffffffffc0200ede:	13c00593          	li	a1,316
ffffffffc0200ee2:	00001517          	auipc	a0,0x1
ffffffffc0200ee6:	38e50513          	addi	a0,a0,910 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200eea:	cc2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200eee:	00001697          	auipc	a3,0x1
ffffffffc0200ef2:	60a68693          	addi	a3,a3,1546 # ffffffffc02024f8 <commands+0x828>
ffffffffc0200ef6:	00001617          	auipc	a2,0x1
ffffffffc0200efa:	36260613          	addi	a2,a2,866 # ffffffffc0202258 <commands+0x588>
ffffffffc0200efe:	13400593          	li	a1,308
ffffffffc0200f02:	00001517          	auipc	a0,0x1
ffffffffc0200f06:	36e50513          	addi	a0,a0,878 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200f0a:	ca2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200f0e:	00001697          	auipc	a3,0x1
ffffffffc0200f12:	5d268693          	addi	a3,a3,1490 # ffffffffc02024e0 <commands+0x810>
ffffffffc0200f16:	00001617          	auipc	a2,0x1
ffffffffc0200f1a:	34260613          	addi	a2,a2,834 # ffffffffc0202258 <commands+0x588>
ffffffffc0200f1e:	13300593          	li	a1,307
ffffffffc0200f22:	00001517          	auipc	a0,0x1
ffffffffc0200f26:	34e50513          	addi	a0,a0,846 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200f2a:	c82ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200f2e:	00001697          	auipc	a3,0x1
ffffffffc0200f32:	59268693          	addi	a3,a3,1426 # ffffffffc02024c0 <commands+0x7f0>
ffffffffc0200f36:	00001617          	auipc	a2,0x1
ffffffffc0200f3a:	32260613          	addi	a2,a2,802 # ffffffffc0202258 <commands+0x588>
ffffffffc0200f3e:	13200593          	li	a1,306
ffffffffc0200f42:	00001517          	auipc	a0,0x1
ffffffffc0200f46:	32e50513          	addi	a0,a0,814 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200f4a:	c62ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200f4e:	00001697          	auipc	a3,0x1
ffffffffc0200f52:	54268693          	addi	a3,a3,1346 # ffffffffc0202490 <commands+0x7c0>
ffffffffc0200f56:	00001617          	auipc	a2,0x1
ffffffffc0200f5a:	30260613          	addi	a2,a2,770 # ffffffffc0202258 <commands+0x588>
ffffffffc0200f5e:	13000593          	li	a1,304
ffffffffc0200f62:	00001517          	auipc	a0,0x1
ffffffffc0200f66:	30e50513          	addi	a0,a0,782 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200f6a:	c42ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f6e:	00001697          	auipc	a3,0x1
ffffffffc0200f72:	50a68693          	addi	a3,a3,1290 # ffffffffc0202478 <commands+0x7a8>
ffffffffc0200f76:	00001617          	auipc	a2,0x1
ffffffffc0200f7a:	2e260613          	addi	a2,a2,738 # ffffffffc0202258 <commands+0x588>
ffffffffc0200f7e:	12f00593          	li	a1,303
ffffffffc0200f82:	00001517          	auipc	a0,0x1
ffffffffc0200f86:	2ee50513          	addi	a0,a0,750 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200f8a:	c22ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f8e:	00001697          	auipc	a3,0x1
ffffffffc0200f92:	45268693          	addi	a3,a3,1106 # ffffffffc02023e0 <commands+0x710>
ffffffffc0200f96:	00001617          	auipc	a2,0x1
ffffffffc0200f9a:	2c260613          	addi	a2,a2,706 # ffffffffc0202258 <commands+0x588>
ffffffffc0200f9e:	12300593          	li	a1,291
ffffffffc0200fa2:	00001517          	auipc	a0,0x1
ffffffffc0200fa6:	2ce50513          	addi	a0,a0,718 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200faa:	c02ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!PageProperty(p0));
ffffffffc0200fae:	00001697          	auipc	a3,0x1
ffffffffc0200fb2:	4b268693          	addi	a3,a3,1202 # ffffffffc0202460 <commands+0x790>
ffffffffc0200fb6:	00001617          	auipc	a2,0x1
ffffffffc0200fba:	2a260613          	addi	a2,a2,674 # ffffffffc0202258 <commands+0x588>
ffffffffc0200fbe:	11a00593          	li	a1,282
ffffffffc0200fc2:	00001517          	auipc	a0,0x1
ffffffffc0200fc6:	2ae50513          	addi	a0,a0,686 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200fca:	be2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 != NULL);
ffffffffc0200fce:	00001697          	auipc	a3,0x1
ffffffffc0200fd2:	48268693          	addi	a3,a3,1154 # ffffffffc0202450 <commands+0x780>
ffffffffc0200fd6:	00001617          	auipc	a2,0x1
ffffffffc0200fda:	28260613          	addi	a2,a2,642 # ffffffffc0202258 <commands+0x588>
ffffffffc0200fde:	11900593          	li	a1,281
ffffffffc0200fe2:	00001517          	auipc	a0,0x1
ffffffffc0200fe6:	28e50513          	addi	a0,a0,654 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0200fea:	bc2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 0);
ffffffffc0200fee:	00001697          	auipc	a3,0x1
ffffffffc0200ff2:	45268693          	addi	a3,a3,1106 # ffffffffc0202440 <commands+0x770>
ffffffffc0200ff6:	00001617          	auipc	a2,0x1
ffffffffc0200ffa:	26260613          	addi	a2,a2,610 # ffffffffc0202258 <commands+0x588>
ffffffffc0200ffe:	0fb00593          	li	a1,251
ffffffffc0201002:	00001517          	auipc	a0,0x1
ffffffffc0201006:	26e50513          	addi	a0,a0,622 # ffffffffc0202270 <commands+0x5a0>
ffffffffc020100a:	ba2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc020100e:	00001697          	auipc	a3,0x1
ffffffffc0201012:	3d268693          	addi	a3,a3,978 # ffffffffc02023e0 <commands+0x710>
ffffffffc0201016:	00001617          	auipc	a2,0x1
ffffffffc020101a:	24260613          	addi	a2,a2,578 # ffffffffc0202258 <commands+0x588>
ffffffffc020101e:	0f900593          	li	a1,249
ffffffffc0201022:	00001517          	auipc	a0,0x1
ffffffffc0201026:	24e50513          	addi	a0,a0,590 # ffffffffc0202270 <commands+0x5a0>
ffffffffc020102a:	b82ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020102e:	00001697          	auipc	a3,0x1
ffffffffc0201032:	3f268693          	addi	a3,a3,1010 # ffffffffc0202420 <commands+0x750>
ffffffffc0201036:	00001617          	auipc	a2,0x1
ffffffffc020103a:	22260613          	addi	a2,a2,546 # ffffffffc0202258 <commands+0x588>
ffffffffc020103e:	0f800593          	li	a1,248
ffffffffc0201042:	00001517          	auipc	a0,0x1
ffffffffc0201046:	22e50513          	addi	a0,a0,558 # ffffffffc0202270 <commands+0x5a0>
ffffffffc020104a:	b62ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc020104e <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc020104e:	1141                	addi	sp,sp,-16
ffffffffc0201050:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201052:	14058a63          	beqz	a1,ffffffffc02011a6 <best_fit_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc0201056:	00259693          	slli	a3,a1,0x2
ffffffffc020105a:	96ae                	add	a3,a3,a1
ffffffffc020105c:	068e                	slli	a3,a3,0x3
ffffffffc020105e:	96aa                	add	a3,a3,a0
ffffffffc0201060:	87aa                	mv	a5,a0
ffffffffc0201062:	02d50263          	beq	a0,a3,ffffffffc0201086 <best_fit_free_pages+0x38>
ffffffffc0201066:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201068:	8b05                	andi	a4,a4,1
ffffffffc020106a:	10071e63          	bnez	a4,ffffffffc0201186 <best_fit_free_pages+0x138>
ffffffffc020106e:	6798                	ld	a4,8(a5)
ffffffffc0201070:	8b09                	andi	a4,a4,2
ffffffffc0201072:	10071a63          	bnez	a4,ffffffffc0201186 <best_fit_free_pages+0x138>
        p->flags = 0;
ffffffffc0201076:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020107a:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020107e:	02878793          	addi	a5,a5,40
ffffffffc0201082:	fed792e3          	bne	a5,a3,ffffffffc0201066 <best_fit_free_pages+0x18>
    base->property = n;
ffffffffc0201086:	2581                	sext.w	a1,a1
ffffffffc0201088:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020108a:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020108e:	4789                	li	a5,2
ffffffffc0201090:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201094:	00005697          	auipc	a3,0x5
ffffffffc0201098:	f8468693          	addi	a3,a3,-124 # ffffffffc0206018 <free_area>
ffffffffc020109c:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020109e:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02010a0:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02010a4:	9db9                	addw	a1,a1,a4
ffffffffc02010a6:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02010a8:	0ad78863          	beq	a5,a3,ffffffffc0201158 <best_fit_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc02010ac:	fe878713          	addi	a4,a5,-24
ffffffffc02010b0:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02010b4:	4581                	li	a1,0
            if (base < page) {
ffffffffc02010b6:	00e56a63          	bltu	a0,a4,ffffffffc02010ca <best_fit_free_pages+0x7c>
    return listelm->next;
ffffffffc02010ba:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02010bc:	06d70363          	beq	a4,a3,ffffffffc0201122 <best_fit_free_pages+0xd4>
    for (; p != base + n; p ++) {
ffffffffc02010c0:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02010c2:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02010c6:	fee57ae3          	bgeu	a0,a4,ffffffffc02010ba <best_fit_free_pages+0x6c>
ffffffffc02010ca:	c199                	beqz	a1,ffffffffc02010d0 <best_fit_free_pages+0x82>
ffffffffc02010cc:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02010d0:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc02010d2:	e390                	sd	a2,0(a5)
ffffffffc02010d4:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02010d6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02010d8:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc02010da:	02d70163          	beq	a4,a3,ffffffffc02010fc <best_fit_free_pages+0xae>
        p = le2page(le, page_link);
ffffffffc02010de:	fe870613          	addi	a2,a4,-24
        if ((unsigned int)(base - p) == p->property){
ffffffffc02010e2:	40c507b3          	sub	a5,a0,a2
ffffffffc02010e6:	00002597          	auipc	a1,0x2
ffffffffc02010ea:	85a5b583          	ld	a1,-1958(a1) # ffffffffc0202940 <error_string+0x38>
ffffffffc02010ee:	878d                	srai	a5,a5,0x3
ffffffffc02010f0:	02b787bb          	mulw	a5,a5,a1
ffffffffc02010f4:	ff872583          	lw	a1,-8(a4)
ffffffffc02010f8:	02b78f63          	beq	a5,a1,ffffffffc0201136 <best_fit_free_pages+0xe8>
    return listelm->next;
ffffffffc02010fc:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc02010fe:	00d70f63          	beq	a4,a3,ffffffffc020111c <best_fit_free_pages+0xce>
        if (base + base->property == p) {
ffffffffc0201102:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0201104:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc0201108:	02059613          	slli	a2,a1,0x20
ffffffffc020110c:	9201                	srli	a2,a2,0x20
ffffffffc020110e:	00261793          	slli	a5,a2,0x2
ffffffffc0201112:	97b2                	add	a5,a5,a2
ffffffffc0201114:	078e                	slli	a5,a5,0x3
ffffffffc0201116:	97aa                	add	a5,a5,a0
ffffffffc0201118:	04f68763          	beq	a3,a5,ffffffffc0201166 <best_fit_free_pages+0x118>
}
ffffffffc020111c:	60a2                	ld	ra,8(sp)
ffffffffc020111e:	0141                	addi	sp,sp,16
ffffffffc0201120:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201122:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201124:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201126:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201128:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020112a:	02d70463          	beq	a4,a3,ffffffffc0201152 <best_fit_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc020112e:	8832                	mv	a6,a2
ffffffffc0201130:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201132:	87ba                	mv	a5,a4
ffffffffc0201134:	b779                	j	ffffffffc02010c2 <best_fit_free_pages+0x74>
            p->property += base->property;
ffffffffc0201136:	490c                	lw	a1,16(a0)
ffffffffc0201138:	9fad                	addw	a5,a5,a1
ffffffffc020113a:	fef72c23          	sw	a5,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020113e:	57f5                	li	a5,-3
ffffffffc0201140:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201144:	6d0c                	ld	a1,24(a0)
ffffffffc0201146:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc0201148:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc020114a:	e59c                	sd	a5,8(a1)
    return listelm->next;
ffffffffc020114c:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc020114e:	e38c                	sd	a1,0(a5)
ffffffffc0201150:	b77d                	j	ffffffffc02010fe <best_fit_free_pages+0xb0>
ffffffffc0201152:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201154:	873e                	mv	a4,a5
ffffffffc0201156:	b761                	j	ffffffffc02010de <best_fit_free_pages+0x90>
}
ffffffffc0201158:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020115a:	e390                	sd	a2,0(a5)
ffffffffc020115c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020115e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201160:	ed1c                	sd	a5,24(a0)
ffffffffc0201162:	0141                	addi	sp,sp,16
ffffffffc0201164:	8082                	ret
            base->property += p->property;
ffffffffc0201166:	ff872783          	lw	a5,-8(a4)
ffffffffc020116a:	ff070693          	addi	a3,a4,-16
ffffffffc020116e:	9dbd                	addw	a1,a1,a5
ffffffffc0201170:	c90c                	sw	a1,16(a0)
ffffffffc0201172:	57f5                	li	a5,-3
ffffffffc0201174:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201178:	6314                	ld	a3,0(a4)
ffffffffc020117a:	671c                	ld	a5,8(a4)
}
ffffffffc020117c:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020117e:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201180:	e394                	sd	a3,0(a5)
ffffffffc0201182:	0141                	addi	sp,sp,16
ffffffffc0201184:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201186:	00001697          	auipc	a3,0x1
ffffffffc020118a:	3c268693          	addi	a3,a3,962 # ffffffffc0202548 <commands+0x878>
ffffffffc020118e:	00001617          	auipc	a2,0x1
ffffffffc0201192:	0ca60613          	addi	a2,a2,202 # ffffffffc0202258 <commands+0x588>
ffffffffc0201196:	09400593          	li	a1,148
ffffffffc020119a:	00001517          	auipc	a0,0x1
ffffffffc020119e:	0d650513          	addi	a0,a0,214 # ffffffffc0202270 <commands+0x5a0>
ffffffffc02011a2:	a0aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc02011a6:	00001697          	auipc	a3,0x1
ffffffffc02011aa:	0aa68693          	addi	a3,a3,170 # ffffffffc0202250 <commands+0x580>
ffffffffc02011ae:	00001617          	auipc	a2,0x1
ffffffffc02011b2:	0aa60613          	addi	a2,a2,170 # ffffffffc0202258 <commands+0x588>
ffffffffc02011b6:	09100593          	li	a1,145
ffffffffc02011ba:	00001517          	auipc	a0,0x1
ffffffffc02011be:	0b650513          	addi	a0,a0,182 # ffffffffc0202270 <commands+0x5a0>
ffffffffc02011c2:	9eaff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02011c6 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc02011c6:	1141                	addi	sp,sp,-16
ffffffffc02011c8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02011ca:	c9e1                	beqz	a1,ffffffffc020129a <best_fit_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc02011cc:	00259693          	slli	a3,a1,0x2
ffffffffc02011d0:	96ae                	add	a3,a3,a1
ffffffffc02011d2:	068e                	slli	a3,a3,0x3
ffffffffc02011d4:	96aa                	add	a3,a3,a0
ffffffffc02011d6:	87aa                	mv	a5,a0
ffffffffc02011d8:	00d50f63          	beq	a0,a3,ffffffffc02011f6 <best_fit_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02011dc:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02011de:	8b05                	andi	a4,a4,1
ffffffffc02011e0:	cf49                	beqz	a4,ffffffffc020127a <best_fit_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc02011e2:	0007a823          	sw	zero,16(a5)
ffffffffc02011e6:	0007b423          	sd	zero,8(a5)
ffffffffc02011ea:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02011ee:	02878793          	addi	a5,a5,40
ffffffffc02011f2:	fed795e3          	bne	a5,a3,ffffffffc02011dc <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc02011f6:	2581                	sext.w	a1,a1
ffffffffc02011f8:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02011fa:	4789                	li	a5,2
ffffffffc02011fc:	00850713          	addi	a4,a0,8
ffffffffc0201200:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201204:	00005697          	auipc	a3,0x5
ffffffffc0201208:	e1468693          	addi	a3,a3,-492 # ffffffffc0206018 <free_area>
ffffffffc020120c:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020120e:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201210:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201214:	9db9                	addw	a1,a1,a4
ffffffffc0201216:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201218:	04d78a63          	beq	a5,a3,ffffffffc020126c <best_fit_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc020121c:	fe878713          	addi	a4,a5,-24
ffffffffc0201220:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201224:	4581                	li	a1,0
            if (base < page){
ffffffffc0201226:	00e56a63          	bltu	a0,a4,ffffffffc020123a <best_fit_init_memmap+0x74>
    return listelm->next;
ffffffffc020122a:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list){
ffffffffc020122c:	02d70263          	beq	a4,a3,ffffffffc0201250 <best_fit_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc0201230:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201232:	fe878713          	addi	a4,a5,-24
            if (base < page){
ffffffffc0201236:	fee57ae3          	bgeu	a0,a4,ffffffffc020122a <best_fit_init_memmap+0x64>
ffffffffc020123a:	c199                	beqz	a1,ffffffffc0201240 <best_fit_init_memmap+0x7a>
ffffffffc020123c:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201240:	6398                	ld	a4,0(a5)
}
ffffffffc0201242:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201244:	e390                	sd	a2,0(a5)
ffffffffc0201246:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201248:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020124a:	ed18                	sd	a4,24(a0)
ffffffffc020124c:	0141                	addi	sp,sp,16
ffffffffc020124e:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201250:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201252:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201254:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201256:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201258:	00d70663          	beq	a4,a3,ffffffffc0201264 <best_fit_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc020125c:	8832                	mv	a6,a2
ffffffffc020125e:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201260:	87ba                	mv	a5,a4
ffffffffc0201262:	bfc1                	j	ffffffffc0201232 <best_fit_init_memmap+0x6c>
}
ffffffffc0201264:	60a2                	ld	ra,8(sp)
ffffffffc0201266:	e290                	sd	a2,0(a3)
ffffffffc0201268:	0141                	addi	sp,sp,16
ffffffffc020126a:	8082                	ret
ffffffffc020126c:	60a2                	ld	ra,8(sp)
ffffffffc020126e:	e390                	sd	a2,0(a5)
ffffffffc0201270:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201272:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201274:	ed1c                	sd	a5,24(a0)
ffffffffc0201276:	0141                	addi	sp,sp,16
ffffffffc0201278:	8082                	ret
        assert(PageReserved(p));
ffffffffc020127a:	00001697          	auipc	a3,0x1
ffffffffc020127e:	2f668693          	addi	a3,a3,758 # ffffffffc0202570 <commands+0x8a0>
ffffffffc0201282:	00001617          	auipc	a2,0x1
ffffffffc0201286:	fd660613          	addi	a2,a2,-42 # ffffffffc0202258 <commands+0x588>
ffffffffc020128a:	04a00593          	li	a1,74
ffffffffc020128e:	00001517          	auipc	a0,0x1
ffffffffc0201292:	fe250513          	addi	a0,a0,-30 # ffffffffc0202270 <commands+0x5a0>
ffffffffc0201296:	916ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc020129a:	00001697          	auipc	a3,0x1
ffffffffc020129e:	fb668693          	addi	a3,a3,-74 # ffffffffc0202250 <commands+0x580>
ffffffffc02012a2:	00001617          	auipc	a2,0x1
ffffffffc02012a6:	fb660613          	addi	a2,a2,-74 # ffffffffc0202258 <commands+0x588>
ffffffffc02012aa:	04700593          	li	a1,71
ffffffffc02012ae:	00001517          	auipc	a0,0x1
ffffffffc02012b2:	fc250513          	addi	a0,a0,-62 # ffffffffc0202270 <commands+0x5a0>
ffffffffc02012b6:	8f6ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02012ba <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02012ba:	100027f3          	csrr	a5,sstatus
ffffffffc02012be:	8b89                	andi	a5,a5,2
ffffffffc02012c0:	e799                	bnez	a5,ffffffffc02012ce <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02012c2:	00005797          	auipc	a5,0x5
ffffffffc02012c6:	1967b783          	ld	a5,406(a5) # ffffffffc0206458 <pmm_manager>
ffffffffc02012ca:	6f9c                	ld	a5,24(a5)
ffffffffc02012cc:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc02012ce:	1141                	addi	sp,sp,-16
ffffffffc02012d0:	e406                	sd	ra,8(sp)
ffffffffc02012d2:	e022                	sd	s0,0(sp)
ffffffffc02012d4:	842a                	mv	s0,a0
        intr_disable();
ffffffffc02012d6:	988ff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02012da:	00005797          	auipc	a5,0x5
ffffffffc02012de:	17e7b783          	ld	a5,382(a5) # ffffffffc0206458 <pmm_manager>
ffffffffc02012e2:	6f9c                	ld	a5,24(a5)
ffffffffc02012e4:	8522                	mv	a0,s0
ffffffffc02012e6:	9782                	jalr	a5
ffffffffc02012e8:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc02012ea:	96eff0ef          	jal	ra,ffffffffc0200458 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02012ee:	60a2                	ld	ra,8(sp)
ffffffffc02012f0:	8522                	mv	a0,s0
ffffffffc02012f2:	6402                	ld	s0,0(sp)
ffffffffc02012f4:	0141                	addi	sp,sp,16
ffffffffc02012f6:	8082                	ret

ffffffffc02012f8 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02012f8:	100027f3          	csrr	a5,sstatus
ffffffffc02012fc:	8b89                	andi	a5,a5,2
ffffffffc02012fe:	e799                	bnez	a5,ffffffffc020130c <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201300:	00005797          	auipc	a5,0x5
ffffffffc0201304:	1587b783          	ld	a5,344(a5) # ffffffffc0206458 <pmm_manager>
ffffffffc0201308:	739c                	ld	a5,32(a5)
ffffffffc020130a:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc020130c:	1101                	addi	sp,sp,-32
ffffffffc020130e:	ec06                	sd	ra,24(sp)
ffffffffc0201310:	e822                	sd	s0,16(sp)
ffffffffc0201312:	e426                	sd	s1,8(sp)
ffffffffc0201314:	842a                	mv	s0,a0
ffffffffc0201316:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201318:	946ff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020131c:	00005797          	auipc	a5,0x5
ffffffffc0201320:	13c7b783          	ld	a5,316(a5) # ffffffffc0206458 <pmm_manager>
ffffffffc0201324:	739c                	ld	a5,32(a5)
ffffffffc0201326:	85a6                	mv	a1,s1
ffffffffc0201328:	8522                	mv	a0,s0
ffffffffc020132a:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc020132c:	6442                	ld	s0,16(sp)
ffffffffc020132e:	60e2                	ld	ra,24(sp)
ffffffffc0201330:	64a2                	ld	s1,8(sp)
ffffffffc0201332:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201334:	924ff06f          	j	ffffffffc0200458 <intr_enable>

ffffffffc0201338 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201338:	100027f3          	csrr	a5,sstatus
ffffffffc020133c:	8b89                	andi	a5,a5,2
ffffffffc020133e:	e799                	bnez	a5,ffffffffc020134c <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201340:	00005797          	auipc	a5,0x5
ffffffffc0201344:	1187b783          	ld	a5,280(a5) # ffffffffc0206458 <pmm_manager>
ffffffffc0201348:	779c                	ld	a5,40(a5)
ffffffffc020134a:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc020134c:	1141                	addi	sp,sp,-16
ffffffffc020134e:	e406                	sd	ra,8(sp)
ffffffffc0201350:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201352:	90cff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201356:	00005797          	auipc	a5,0x5
ffffffffc020135a:	1027b783          	ld	a5,258(a5) # ffffffffc0206458 <pmm_manager>
ffffffffc020135e:	779c                	ld	a5,40(a5)
ffffffffc0201360:	9782                	jalr	a5
ffffffffc0201362:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201364:	8f4ff0ef          	jal	ra,ffffffffc0200458 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201368:	60a2                	ld	ra,8(sp)
ffffffffc020136a:	8522                	mv	a0,s0
ffffffffc020136c:	6402                	ld	s0,0(sp)
ffffffffc020136e:	0141                	addi	sp,sp,16
ffffffffc0201370:	8082                	ret

ffffffffc0201372 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201372:	00001797          	auipc	a5,0x1
ffffffffc0201376:	22678793          	addi	a5,a5,550 # ffffffffc0202598 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020137a:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc020137c:	1101                	addi	sp,sp,-32
ffffffffc020137e:	e426                	sd	s1,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201380:	00001517          	auipc	a0,0x1
ffffffffc0201384:	25050513          	addi	a0,a0,592 # ffffffffc02025d0 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201388:	00005497          	auipc	s1,0x5
ffffffffc020138c:	0d048493          	addi	s1,s1,208 # ffffffffc0206458 <pmm_manager>
void pmm_init(void) {
ffffffffc0201390:	ec06                	sd	ra,24(sp)
ffffffffc0201392:	e822                	sd	s0,16(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201394:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201396:	d1dfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pmm_manager->init();
ffffffffc020139a:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020139c:	00005417          	auipc	s0,0x5
ffffffffc02013a0:	0d440413          	addi	s0,s0,212 # ffffffffc0206470 <va_pa_offset>
    pmm_manager->init();
ffffffffc02013a4:	679c                	ld	a5,8(a5)
ffffffffc02013a6:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02013a8:	57f5                	li	a5,-3
ffffffffc02013aa:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc02013ac:	00001517          	auipc	a0,0x1
ffffffffc02013b0:	23c50513          	addi	a0,a0,572 # ffffffffc02025e8 <best_fit_pmm_manager+0x50>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02013b4:	e01c                	sd	a5,0(s0)
    cprintf("physcial memory map:\n");
ffffffffc02013b6:	cfdfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02013ba:	46c5                	li	a3,17
ffffffffc02013bc:	06ee                	slli	a3,a3,0x1b
ffffffffc02013be:	40100613          	li	a2,1025
ffffffffc02013c2:	16fd                	addi	a3,a3,-1
ffffffffc02013c4:	07e005b7          	lui	a1,0x7e00
ffffffffc02013c8:	0656                	slli	a2,a2,0x15
ffffffffc02013ca:	00001517          	auipc	a0,0x1
ffffffffc02013ce:	23650513          	addi	a0,a0,566 # ffffffffc0202600 <best_fit_pmm_manager+0x68>
ffffffffc02013d2:	ce1fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02013d6:	777d                	lui	a4,0xfffff
ffffffffc02013d8:	00006797          	auipc	a5,0x6
ffffffffc02013dc:	0a778793          	addi	a5,a5,167 # ffffffffc020747f <end+0xfff>
ffffffffc02013e0:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc02013e2:	00005517          	auipc	a0,0x5
ffffffffc02013e6:	06650513          	addi	a0,a0,102 # ffffffffc0206448 <npage>
ffffffffc02013ea:	00088737          	lui	a4,0x88
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02013ee:	00005597          	auipc	a1,0x5
ffffffffc02013f2:	06258593          	addi	a1,a1,98 # ffffffffc0206450 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02013f6:	e118                	sd	a4,0(a0)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02013f8:	e19c                	sd	a5,0(a1)
ffffffffc02013fa:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02013fc:	4701                	li	a4,0
ffffffffc02013fe:	4885                	li	a7,1
ffffffffc0201400:	fff80837          	lui	a6,0xfff80
ffffffffc0201404:	a011                	j	ffffffffc0201408 <pmm_init+0x96>
        SetPageReserved(pages + i);
ffffffffc0201406:	619c                	ld	a5,0(a1)
ffffffffc0201408:	97b6                	add	a5,a5,a3
ffffffffc020140a:	07a1                	addi	a5,a5,8
ffffffffc020140c:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201410:	611c                	ld	a5,0(a0)
ffffffffc0201412:	0705                	addi	a4,a4,1
ffffffffc0201414:	02868693          	addi	a3,a3,40
ffffffffc0201418:	01078633          	add	a2,a5,a6
ffffffffc020141c:	fec765e3          	bltu	a4,a2,ffffffffc0201406 <pmm_init+0x94>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201420:	6190                	ld	a2,0(a1)
ffffffffc0201422:	00279713          	slli	a4,a5,0x2
ffffffffc0201426:	973e                	add	a4,a4,a5
ffffffffc0201428:	fec006b7          	lui	a3,0xfec00
ffffffffc020142c:	070e                	slli	a4,a4,0x3
ffffffffc020142e:	96b2                	add	a3,a3,a2
ffffffffc0201430:	96ba                	add	a3,a3,a4
ffffffffc0201432:	c0200737          	lui	a4,0xc0200
ffffffffc0201436:	08e6ef63          	bltu	a3,a4,ffffffffc02014d4 <pmm_init+0x162>
ffffffffc020143a:	6018                	ld	a4,0(s0)
    if (freemem < mem_end) {
ffffffffc020143c:	45c5                	li	a1,17
ffffffffc020143e:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201440:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201442:	04b6e863          	bltu	a3,a1,ffffffffc0201492 <pmm_init+0x120>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201446:	609c                	ld	a5,0(s1)
ffffffffc0201448:	7b9c                	ld	a5,48(a5)
ffffffffc020144a:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020144c:	00001517          	auipc	a0,0x1
ffffffffc0201450:	24c50513          	addi	a0,a0,588 # ffffffffc0202698 <best_fit_pmm_manager+0x100>
ffffffffc0201454:	c5ffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201458:	00004597          	auipc	a1,0x4
ffffffffc020145c:	ba858593          	addi	a1,a1,-1112 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201460:	00005797          	auipc	a5,0x5
ffffffffc0201464:	00b7b423          	sd	a1,8(a5) # ffffffffc0206468 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201468:	c02007b7          	lui	a5,0xc0200
ffffffffc020146c:	08f5e063          	bltu	a1,a5,ffffffffc02014ec <pmm_init+0x17a>
ffffffffc0201470:	6010                	ld	a2,0(s0)
}
ffffffffc0201472:	6442                	ld	s0,16(sp)
ffffffffc0201474:	60e2                	ld	ra,24(sp)
ffffffffc0201476:	64a2                	ld	s1,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201478:	40c58633          	sub	a2,a1,a2
ffffffffc020147c:	00005797          	auipc	a5,0x5
ffffffffc0201480:	fec7b223          	sd	a2,-28(a5) # ffffffffc0206460 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201484:	00001517          	auipc	a0,0x1
ffffffffc0201488:	23450513          	addi	a0,a0,564 # ffffffffc02026b8 <best_fit_pmm_manager+0x120>
}
ffffffffc020148c:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020148e:	c25fe06f          	j	ffffffffc02000b2 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201492:	6705                	lui	a4,0x1
ffffffffc0201494:	177d                	addi	a4,a4,-1
ffffffffc0201496:	96ba                	add	a3,a3,a4
ffffffffc0201498:	777d                	lui	a4,0xfffff
ffffffffc020149a:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc020149c:	00c6d513          	srli	a0,a3,0xc
ffffffffc02014a0:	00f57e63          	bgeu	a0,a5,ffffffffc02014bc <pmm_init+0x14a>
    pmm_manager->init_memmap(base, n);
ffffffffc02014a4:	609c                	ld	a5,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02014a6:	982a                	add	a6,a6,a0
ffffffffc02014a8:	00281513          	slli	a0,a6,0x2
ffffffffc02014ac:	9542                	add	a0,a0,a6
ffffffffc02014ae:	6b9c                	ld	a5,16(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02014b0:	8d95                	sub	a1,a1,a3
ffffffffc02014b2:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02014b4:	81b1                	srli	a1,a1,0xc
ffffffffc02014b6:	9532                	add	a0,a0,a2
ffffffffc02014b8:	9782                	jalr	a5
}
ffffffffc02014ba:	b771                	j	ffffffffc0201446 <pmm_init+0xd4>
        panic("pa2page called with invalid pa");
ffffffffc02014bc:	00001617          	auipc	a2,0x1
ffffffffc02014c0:	1ac60613          	addi	a2,a2,428 # ffffffffc0202668 <best_fit_pmm_manager+0xd0>
ffffffffc02014c4:	06b00593          	li	a1,107
ffffffffc02014c8:	00001517          	auipc	a0,0x1
ffffffffc02014cc:	1c050513          	addi	a0,a0,448 # ffffffffc0202688 <best_fit_pmm_manager+0xf0>
ffffffffc02014d0:	eddfe0ef          	jal	ra,ffffffffc02003ac <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02014d4:	00001617          	auipc	a2,0x1
ffffffffc02014d8:	15c60613          	addi	a2,a2,348 # ffffffffc0202630 <best_fit_pmm_manager+0x98>
ffffffffc02014dc:	06e00593          	li	a1,110
ffffffffc02014e0:	00001517          	auipc	a0,0x1
ffffffffc02014e4:	17850513          	addi	a0,a0,376 # ffffffffc0202658 <best_fit_pmm_manager+0xc0>
ffffffffc02014e8:	ec5fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02014ec:	86ae                	mv	a3,a1
ffffffffc02014ee:	00001617          	auipc	a2,0x1
ffffffffc02014f2:	14260613          	addi	a2,a2,322 # ffffffffc0202630 <best_fit_pmm_manager+0x98>
ffffffffc02014f6:	08900593          	li	a1,137
ffffffffc02014fa:	00001517          	auipc	a0,0x1
ffffffffc02014fe:	15e50513          	addi	a0,a0,350 # ffffffffc0202658 <best_fit_pmm_manager+0xc0>
ffffffffc0201502:	eabfe0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201506 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201506:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020150a:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020150c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201510:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201512:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201516:	f022                	sd	s0,32(sp)
ffffffffc0201518:	ec26                	sd	s1,24(sp)
ffffffffc020151a:	e84a                	sd	s2,16(sp)
ffffffffc020151c:	f406                	sd	ra,40(sp)
ffffffffc020151e:	e44e                	sd	s3,8(sp)
ffffffffc0201520:	84aa                	mv	s1,a0
ffffffffc0201522:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201524:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201528:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020152a:	03067e63          	bgeu	a2,a6,ffffffffc0201566 <printnum+0x60>
ffffffffc020152e:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201530:	00805763          	blez	s0,ffffffffc020153e <printnum+0x38>
ffffffffc0201534:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201536:	85ca                	mv	a1,s2
ffffffffc0201538:	854e                	mv	a0,s3
ffffffffc020153a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020153c:	fc65                	bnez	s0,ffffffffc0201534 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020153e:	1a02                	slli	s4,s4,0x20
ffffffffc0201540:	00001797          	auipc	a5,0x1
ffffffffc0201544:	1b878793          	addi	a5,a5,440 # ffffffffc02026f8 <best_fit_pmm_manager+0x160>
ffffffffc0201548:	020a5a13          	srli	s4,s4,0x20
ffffffffc020154c:	9a3e                	add	s4,s4,a5
}
ffffffffc020154e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201550:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201554:	70a2                	ld	ra,40(sp)
ffffffffc0201556:	69a2                	ld	s3,8(sp)
ffffffffc0201558:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020155a:	85ca                	mv	a1,s2
ffffffffc020155c:	87a6                	mv	a5,s1
}
ffffffffc020155e:	6942                	ld	s2,16(sp)
ffffffffc0201560:	64e2                	ld	s1,24(sp)
ffffffffc0201562:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201564:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201566:	03065633          	divu	a2,a2,a6
ffffffffc020156a:	8722                	mv	a4,s0
ffffffffc020156c:	f9bff0ef          	jal	ra,ffffffffc0201506 <printnum>
ffffffffc0201570:	b7f9                	j	ffffffffc020153e <printnum+0x38>

ffffffffc0201572 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201572:	7119                	addi	sp,sp,-128
ffffffffc0201574:	f4a6                	sd	s1,104(sp)
ffffffffc0201576:	f0ca                	sd	s2,96(sp)
ffffffffc0201578:	ecce                	sd	s3,88(sp)
ffffffffc020157a:	e8d2                	sd	s4,80(sp)
ffffffffc020157c:	e4d6                	sd	s5,72(sp)
ffffffffc020157e:	e0da                	sd	s6,64(sp)
ffffffffc0201580:	fc5e                	sd	s7,56(sp)
ffffffffc0201582:	f06a                	sd	s10,32(sp)
ffffffffc0201584:	fc86                	sd	ra,120(sp)
ffffffffc0201586:	f8a2                	sd	s0,112(sp)
ffffffffc0201588:	f862                	sd	s8,48(sp)
ffffffffc020158a:	f466                	sd	s9,40(sp)
ffffffffc020158c:	ec6e                	sd	s11,24(sp)
ffffffffc020158e:	892a                	mv	s2,a0
ffffffffc0201590:	84ae                	mv	s1,a1
ffffffffc0201592:	8d32                	mv	s10,a2
ffffffffc0201594:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201596:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020159a:	5b7d                	li	s6,-1
ffffffffc020159c:	00001a97          	auipc	s5,0x1
ffffffffc02015a0:	190a8a93          	addi	s5,s5,400 # ffffffffc020272c <best_fit_pmm_manager+0x194>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02015a4:	00001b97          	auipc	s7,0x1
ffffffffc02015a8:	364b8b93          	addi	s7,s7,868 # ffffffffc0202908 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02015ac:	000d4503          	lbu	a0,0(s10)
ffffffffc02015b0:	001d0413          	addi	s0,s10,1
ffffffffc02015b4:	01350a63          	beq	a0,s3,ffffffffc02015c8 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02015b8:	c121                	beqz	a0,ffffffffc02015f8 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02015ba:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02015bc:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02015be:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02015c0:	fff44503          	lbu	a0,-1(s0)
ffffffffc02015c4:	ff351ae3          	bne	a0,s3,ffffffffc02015b8 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015c8:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02015cc:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02015d0:	4c81                	li	s9,0
ffffffffc02015d2:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02015d4:	5c7d                	li	s8,-1
ffffffffc02015d6:	5dfd                	li	s11,-1
ffffffffc02015d8:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02015dc:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015de:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02015e2:	0ff5f593          	zext.b	a1,a1
ffffffffc02015e6:	00140d13          	addi	s10,s0,1
ffffffffc02015ea:	04b56263          	bltu	a0,a1,ffffffffc020162e <vprintfmt+0xbc>
ffffffffc02015ee:	058a                	slli	a1,a1,0x2
ffffffffc02015f0:	95d6                	add	a1,a1,s5
ffffffffc02015f2:	4194                	lw	a3,0(a1)
ffffffffc02015f4:	96d6                	add	a3,a3,s5
ffffffffc02015f6:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02015f8:	70e6                	ld	ra,120(sp)
ffffffffc02015fa:	7446                	ld	s0,112(sp)
ffffffffc02015fc:	74a6                	ld	s1,104(sp)
ffffffffc02015fe:	7906                	ld	s2,96(sp)
ffffffffc0201600:	69e6                	ld	s3,88(sp)
ffffffffc0201602:	6a46                	ld	s4,80(sp)
ffffffffc0201604:	6aa6                	ld	s5,72(sp)
ffffffffc0201606:	6b06                	ld	s6,64(sp)
ffffffffc0201608:	7be2                	ld	s7,56(sp)
ffffffffc020160a:	7c42                	ld	s8,48(sp)
ffffffffc020160c:	7ca2                	ld	s9,40(sp)
ffffffffc020160e:	7d02                	ld	s10,32(sp)
ffffffffc0201610:	6de2                	ld	s11,24(sp)
ffffffffc0201612:	6109                	addi	sp,sp,128
ffffffffc0201614:	8082                	ret
            padc = '0';
ffffffffc0201616:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201618:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020161c:	846a                	mv	s0,s10
ffffffffc020161e:	00140d13          	addi	s10,s0,1
ffffffffc0201622:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201626:	0ff5f593          	zext.b	a1,a1
ffffffffc020162a:	fcb572e3          	bgeu	a0,a1,ffffffffc02015ee <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020162e:	85a6                	mv	a1,s1
ffffffffc0201630:	02500513          	li	a0,37
ffffffffc0201634:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201636:	fff44783          	lbu	a5,-1(s0)
ffffffffc020163a:	8d22                	mv	s10,s0
ffffffffc020163c:	f73788e3          	beq	a5,s3,ffffffffc02015ac <vprintfmt+0x3a>
ffffffffc0201640:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201644:	1d7d                	addi	s10,s10,-1
ffffffffc0201646:	ff379de3          	bne	a5,s3,ffffffffc0201640 <vprintfmt+0xce>
ffffffffc020164a:	b78d                	j	ffffffffc02015ac <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020164c:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201650:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201654:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201656:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020165a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020165e:	02d86463          	bltu	a6,a3,ffffffffc0201686 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201662:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201666:	002c169b          	slliw	a3,s8,0x2
ffffffffc020166a:	0186873b          	addw	a4,a3,s8
ffffffffc020166e:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201672:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201674:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201678:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020167a:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc020167e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201682:	fed870e3          	bgeu	a6,a3,ffffffffc0201662 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201686:	f40ddce3          	bgez	s11,ffffffffc02015de <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc020168a:	8de2                	mv	s11,s8
ffffffffc020168c:	5c7d                	li	s8,-1
ffffffffc020168e:	bf81                	j	ffffffffc02015de <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201690:	fffdc693          	not	a3,s11
ffffffffc0201694:	96fd                	srai	a3,a3,0x3f
ffffffffc0201696:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020169a:	00144603          	lbu	a2,1(s0)
ffffffffc020169e:	2d81                	sext.w	s11,s11
ffffffffc02016a0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02016a2:	bf35                	j	ffffffffc02015de <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02016a4:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016a8:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02016ac:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016ae:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02016b0:	bfd9                	j	ffffffffc0201686 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02016b2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02016b4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02016b8:	01174463          	blt	a4,a7,ffffffffc02016c0 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02016bc:	1a088e63          	beqz	a7,ffffffffc0201878 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02016c0:	000a3603          	ld	a2,0(s4)
ffffffffc02016c4:	46c1                	li	a3,16
ffffffffc02016c6:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02016c8:	2781                	sext.w	a5,a5
ffffffffc02016ca:	876e                	mv	a4,s11
ffffffffc02016cc:	85a6                	mv	a1,s1
ffffffffc02016ce:	854a                	mv	a0,s2
ffffffffc02016d0:	e37ff0ef          	jal	ra,ffffffffc0201506 <printnum>
            break;
ffffffffc02016d4:	bde1                	j	ffffffffc02015ac <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02016d6:	000a2503          	lw	a0,0(s4)
ffffffffc02016da:	85a6                	mv	a1,s1
ffffffffc02016dc:	0a21                	addi	s4,s4,8
ffffffffc02016de:	9902                	jalr	s2
            break;
ffffffffc02016e0:	b5f1                	j	ffffffffc02015ac <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02016e2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02016e4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02016e8:	01174463          	blt	a4,a7,ffffffffc02016f0 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02016ec:	18088163          	beqz	a7,ffffffffc020186e <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02016f0:	000a3603          	ld	a2,0(s4)
ffffffffc02016f4:	46a9                	li	a3,10
ffffffffc02016f6:	8a2e                	mv	s4,a1
ffffffffc02016f8:	bfc1                	j	ffffffffc02016c8 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016fa:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02016fe:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201700:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201702:	bdf1                	j	ffffffffc02015de <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201704:	85a6                	mv	a1,s1
ffffffffc0201706:	02500513          	li	a0,37
ffffffffc020170a:	9902                	jalr	s2
            break;
ffffffffc020170c:	b545                	j	ffffffffc02015ac <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020170e:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201712:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201714:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201716:	b5e1                	j	ffffffffc02015de <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201718:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020171a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020171e:	01174463          	blt	a4,a7,ffffffffc0201726 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201722:	14088163          	beqz	a7,ffffffffc0201864 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201726:	000a3603          	ld	a2,0(s4)
ffffffffc020172a:	46a1                	li	a3,8
ffffffffc020172c:	8a2e                	mv	s4,a1
ffffffffc020172e:	bf69                	j	ffffffffc02016c8 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201730:	03000513          	li	a0,48
ffffffffc0201734:	85a6                	mv	a1,s1
ffffffffc0201736:	e03e                	sd	a5,0(sp)
ffffffffc0201738:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020173a:	85a6                	mv	a1,s1
ffffffffc020173c:	07800513          	li	a0,120
ffffffffc0201740:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201742:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201744:	6782                	ld	a5,0(sp)
ffffffffc0201746:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201748:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020174c:	bfb5                	j	ffffffffc02016c8 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020174e:	000a3403          	ld	s0,0(s4)
ffffffffc0201752:	008a0713          	addi	a4,s4,8
ffffffffc0201756:	e03a                	sd	a4,0(sp)
ffffffffc0201758:	14040263          	beqz	s0,ffffffffc020189c <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020175c:	0fb05763          	blez	s11,ffffffffc020184a <vprintfmt+0x2d8>
ffffffffc0201760:	02d00693          	li	a3,45
ffffffffc0201764:	0cd79163          	bne	a5,a3,ffffffffc0201826 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201768:	00044783          	lbu	a5,0(s0)
ffffffffc020176c:	0007851b          	sext.w	a0,a5
ffffffffc0201770:	cf85                	beqz	a5,ffffffffc02017a8 <vprintfmt+0x236>
ffffffffc0201772:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201776:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020177a:	000c4563          	bltz	s8,ffffffffc0201784 <vprintfmt+0x212>
ffffffffc020177e:	3c7d                	addiw	s8,s8,-1
ffffffffc0201780:	036c0263          	beq	s8,s6,ffffffffc02017a4 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201784:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201786:	0e0c8e63          	beqz	s9,ffffffffc0201882 <vprintfmt+0x310>
ffffffffc020178a:	3781                	addiw	a5,a5,-32
ffffffffc020178c:	0ef47b63          	bgeu	s0,a5,ffffffffc0201882 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201790:	03f00513          	li	a0,63
ffffffffc0201794:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201796:	000a4783          	lbu	a5,0(s4)
ffffffffc020179a:	3dfd                	addiw	s11,s11,-1
ffffffffc020179c:	0a05                	addi	s4,s4,1
ffffffffc020179e:	0007851b          	sext.w	a0,a5
ffffffffc02017a2:	ffe1                	bnez	a5,ffffffffc020177a <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02017a4:	01b05963          	blez	s11,ffffffffc02017b6 <vprintfmt+0x244>
ffffffffc02017a8:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02017aa:	85a6                	mv	a1,s1
ffffffffc02017ac:	02000513          	li	a0,32
ffffffffc02017b0:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02017b2:	fe0d9be3          	bnez	s11,ffffffffc02017a8 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02017b6:	6a02                	ld	s4,0(sp)
ffffffffc02017b8:	bbd5                	j	ffffffffc02015ac <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02017ba:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02017bc:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02017c0:	01174463          	blt	a4,a7,ffffffffc02017c8 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02017c4:	08088d63          	beqz	a7,ffffffffc020185e <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02017c8:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02017cc:	0a044d63          	bltz	s0,ffffffffc0201886 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02017d0:	8622                	mv	a2,s0
ffffffffc02017d2:	8a66                	mv	s4,s9
ffffffffc02017d4:	46a9                	li	a3,10
ffffffffc02017d6:	bdcd                	j	ffffffffc02016c8 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02017d8:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02017dc:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02017de:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02017e0:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02017e4:	8fb5                	xor	a5,a5,a3
ffffffffc02017e6:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02017ea:	02d74163          	blt	a4,a3,ffffffffc020180c <vprintfmt+0x29a>
ffffffffc02017ee:	00369793          	slli	a5,a3,0x3
ffffffffc02017f2:	97de                	add	a5,a5,s7
ffffffffc02017f4:	639c                	ld	a5,0(a5)
ffffffffc02017f6:	cb99                	beqz	a5,ffffffffc020180c <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02017f8:	86be                	mv	a3,a5
ffffffffc02017fa:	00001617          	auipc	a2,0x1
ffffffffc02017fe:	f2e60613          	addi	a2,a2,-210 # ffffffffc0202728 <best_fit_pmm_manager+0x190>
ffffffffc0201802:	85a6                	mv	a1,s1
ffffffffc0201804:	854a                	mv	a0,s2
ffffffffc0201806:	0ce000ef          	jal	ra,ffffffffc02018d4 <printfmt>
ffffffffc020180a:	b34d                	j	ffffffffc02015ac <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020180c:	00001617          	auipc	a2,0x1
ffffffffc0201810:	f0c60613          	addi	a2,a2,-244 # ffffffffc0202718 <best_fit_pmm_manager+0x180>
ffffffffc0201814:	85a6                	mv	a1,s1
ffffffffc0201816:	854a                	mv	a0,s2
ffffffffc0201818:	0bc000ef          	jal	ra,ffffffffc02018d4 <printfmt>
ffffffffc020181c:	bb41                	j	ffffffffc02015ac <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020181e:	00001417          	auipc	s0,0x1
ffffffffc0201822:	ef240413          	addi	s0,s0,-270 # ffffffffc0202710 <best_fit_pmm_manager+0x178>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201826:	85e2                	mv	a1,s8
ffffffffc0201828:	8522                	mv	a0,s0
ffffffffc020182a:	e43e                	sd	a5,8(sp)
ffffffffc020182c:	1e6000ef          	jal	ra,ffffffffc0201a12 <strnlen>
ffffffffc0201830:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201834:	01b05b63          	blez	s11,ffffffffc020184a <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201838:	67a2                	ld	a5,8(sp)
ffffffffc020183a:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020183e:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201840:	85a6                	mv	a1,s1
ffffffffc0201842:	8552                	mv	a0,s4
ffffffffc0201844:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201846:	fe0d9ce3          	bnez	s11,ffffffffc020183e <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020184a:	00044783          	lbu	a5,0(s0)
ffffffffc020184e:	00140a13          	addi	s4,s0,1
ffffffffc0201852:	0007851b          	sext.w	a0,a5
ffffffffc0201856:	d3a5                	beqz	a5,ffffffffc02017b6 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201858:	05e00413          	li	s0,94
ffffffffc020185c:	bf39                	j	ffffffffc020177a <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc020185e:	000a2403          	lw	s0,0(s4)
ffffffffc0201862:	b7ad                	j	ffffffffc02017cc <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201864:	000a6603          	lwu	a2,0(s4)
ffffffffc0201868:	46a1                	li	a3,8
ffffffffc020186a:	8a2e                	mv	s4,a1
ffffffffc020186c:	bdb1                	j	ffffffffc02016c8 <vprintfmt+0x156>
ffffffffc020186e:	000a6603          	lwu	a2,0(s4)
ffffffffc0201872:	46a9                	li	a3,10
ffffffffc0201874:	8a2e                	mv	s4,a1
ffffffffc0201876:	bd89                	j	ffffffffc02016c8 <vprintfmt+0x156>
ffffffffc0201878:	000a6603          	lwu	a2,0(s4)
ffffffffc020187c:	46c1                	li	a3,16
ffffffffc020187e:	8a2e                	mv	s4,a1
ffffffffc0201880:	b5a1                	j	ffffffffc02016c8 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201882:	9902                	jalr	s2
ffffffffc0201884:	bf09                	j	ffffffffc0201796 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201886:	85a6                	mv	a1,s1
ffffffffc0201888:	02d00513          	li	a0,45
ffffffffc020188c:	e03e                	sd	a5,0(sp)
ffffffffc020188e:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201890:	6782                	ld	a5,0(sp)
ffffffffc0201892:	8a66                	mv	s4,s9
ffffffffc0201894:	40800633          	neg	a2,s0
ffffffffc0201898:	46a9                	li	a3,10
ffffffffc020189a:	b53d                	j	ffffffffc02016c8 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc020189c:	03b05163          	blez	s11,ffffffffc02018be <vprintfmt+0x34c>
ffffffffc02018a0:	02d00693          	li	a3,45
ffffffffc02018a4:	f6d79de3          	bne	a5,a3,ffffffffc020181e <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02018a8:	00001417          	auipc	s0,0x1
ffffffffc02018ac:	e6840413          	addi	s0,s0,-408 # ffffffffc0202710 <best_fit_pmm_manager+0x178>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02018b0:	02800793          	li	a5,40
ffffffffc02018b4:	02800513          	li	a0,40
ffffffffc02018b8:	00140a13          	addi	s4,s0,1
ffffffffc02018bc:	bd6d                	j	ffffffffc0201776 <vprintfmt+0x204>
ffffffffc02018be:	00001a17          	auipc	s4,0x1
ffffffffc02018c2:	e53a0a13          	addi	s4,s4,-429 # ffffffffc0202711 <best_fit_pmm_manager+0x179>
ffffffffc02018c6:	02800513          	li	a0,40
ffffffffc02018ca:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02018ce:	05e00413          	li	s0,94
ffffffffc02018d2:	b565                	j	ffffffffc020177a <vprintfmt+0x208>

ffffffffc02018d4 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02018d4:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02018d6:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02018da:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02018dc:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02018de:	ec06                	sd	ra,24(sp)
ffffffffc02018e0:	f83a                	sd	a4,48(sp)
ffffffffc02018e2:	fc3e                	sd	a5,56(sp)
ffffffffc02018e4:	e0c2                	sd	a6,64(sp)
ffffffffc02018e6:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02018e8:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02018ea:	c89ff0ef          	jal	ra,ffffffffc0201572 <vprintfmt>
}
ffffffffc02018ee:	60e2                	ld	ra,24(sp)
ffffffffc02018f0:	6161                	addi	sp,sp,80
ffffffffc02018f2:	8082                	ret

ffffffffc02018f4 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02018f4:	715d                	addi	sp,sp,-80
ffffffffc02018f6:	e486                	sd	ra,72(sp)
ffffffffc02018f8:	e0a6                	sd	s1,64(sp)
ffffffffc02018fa:	fc4a                	sd	s2,56(sp)
ffffffffc02018fc:	f84e                	sd	s3,48(sp)
ffffffffc02018fe:	f452                	sd	s4,40(sp)
ffffffffc0201900:	f056                	sd	s5,32(sp)
ffffffffc0201902:	ec5a                	sd	s6,24(sp)
ffffffffc0201904:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201906:	c901                	beqz	a0,ffffffffc0201916 <readline+0x22>
ffffffffc0201908:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc020190a:	00001517          	auipc	a0,0x1
ffffffffc020190e:	e1e50513          	addi	a0,a0,-482 # ffffffffc0202728 <best_fit_pmm_manager+0x190>
ffffffffc0201912:	fa0fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
readline(const char *prompt) {
ffffffffc0201916:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201918:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc020191a:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc020191c:	4aa9                	li	s5,10
ffffffffc020191e:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201920:	00004b97          	auipc	s7,0x4
ffffffffc0201924:	710b8b93          	addi	s7,s7,1808 # ffffffffc0206030 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201928:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc020192c:	ffefe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201930:	00054a63          	bltz	a0,ffffffffc0201944 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201934:	00a95a63          	bge	s2,a0,ffffffffc0201948 <readline+0x54>
ffffffffc0201938:	029a5263          	bge	s4,s1,ffffffffc020195c <readline+0x68>
        c = getchar();
ffffffffc020193c:	feefe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201940:	fe055ae3          	bgez	a0,ffffffffc0201934 <readline+0x40>
            return NULL;
ffffffffc0201944:	4501                	li	a0,0
ffffffffc0201946:	a091                	j	ffffffffc020198a <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201948:	03351463          	bne	a0,s3,ffffffffc0201970 <readline+0x7c>
ffffffffc020194c:	e8a9                	bnez	s1,ffffffffc020199e <readline+0xaa>
        c = getchar();
ffffffffc020194e:	fdcfe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201952:	fe0549e3          	bltz	a0,ffffffffc0201944 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201956:	fea959e3          	bge	s2,a0,ffffffffc0201948 <readline+0x54>
ffffffffc020195a:	4481                	li	s1,0
            cputchar(c);
ffffffffc020195c:	e42a                	sd	a0,8(sp)
ffffffffc020195e:	f8afe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i ++] = c;
ffffffffc0201962:	6522                	ld	a0,8(sp)
ffffffffc0201964:	009b87b3          	add	a5,s7,s1
ffffffffc0201968:	2485                	addiw	s1,s1,1
ffffffffc020196a:	00a78023          	sb	a0,0(a5)
ffffffffc020196e:	bf7d                	j	ffffffffc020192c <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201970:	01550463          	beq	a0,s5,ffffffffc0201978 <readline+0x84>
ffffffffc0201974:	fb651ce3          	bne	a0,s6,ffffffffc020192c <readline+0x38>
            cputchar(c);
ffffffffc0201978:	f70fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i] = '\0';
ffffffffc020197c:	00004517          	auipc	a0,0x4
ffffffffc0201980:	6b450513          	addi	a0,a0,1716 # ffffffffc0206030 <buf>
ffffffffc0201984:	94aa                	add	s1,s1,a0
ffffffffc0201986:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020198a:	60a6                	ld	ra,72(sp)
ffffffffc020198c:	6486                	ld	s1,64(sp)
ffffffffc020198e:	7962                	ld	s2,56(sp)
ffffffffc0201990:	79c2                	ld	s3,48(sp)
ffffffffc0201992:	7a22                	ld	s4,40(sp)
ffffffffc0201994:	7a82                	ld	s5,32(sp)
ffffffffc0201996:	6b62                	ld	s6,24(sp)
ffffffffc0201998:	6bc2                	ld	s7,16(sp)
ffffffffc020199a:	6161                	addi	sp,sp,80
ffffffffc020199c:	8082                	ret
            cputchar(c);
ffffffffc020199e:	4521                	li	a0,8
ffffffffc02019a0:	f48fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            i --;
ffffffffc02019a4:	34fd                	addiw	s1,s1,-1
ffffffffc02019a6:	b759                	j	ffffffffc020192c <readline+0x38>

ffffffffc02019a8 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02019a8:	4781                	li	a5,0
ffffffffc02019aa:	00004717          	auipc	a4,0x4
ffffffffc02019ae:	65e73703          	ld	a4,1630(a4) # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
ffffffffc02019b2:	88ba                	mv	a7,a4
ffffffffc02019b4:	852a                	mv	a0,a0
ffffffffc02019b6:	85be                	mv	a1,a5
ffffffffc02019b8:	863e                	mv	a2,a5
ffffffffc02019ba:	00000073          	ecall
ffffffffc02019be:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02019c0:	8082                	ret

ffffffffc02019c2 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc02019c2:	4781                	li	a5,0
ffffffffc02019c4:	00005717          	auipc	a4,0x5
ffffffffc02019c8:	ab473703          	ld	a4,-1356(a4) # ffffffffc0206478 <SBI_SET_TIMER>
ffffffffc02019cc:	88ba                	mv	a7,a4
ffffffffc02019ce:	852a                	mv	a0,a0
ffffffffc02019d0:	85be                	mv	a1,a5
ffffffffc02019d2:	863e                	mv	a2,a5
ffffffffc02019d4:	00000073          	ecall
ffffffffc02019d8:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc02019da:	8082                	ret

ffffffffc02019dc <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc02019dc:	4501                	li	a0,0
ffffffffc02019de:	00004797          	auipc	a5,0x4
ffffffffc02019e2:	6227b783          	ld	a5,1570(a5) # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
ffffffffc02019e6:	88be                	mv	a7,a5
ffffffffc02019e8:	852a                	mv	a0,a0
ffffffffc02019ea:	85aa                	mv	a1,a0
ffffffffc02019ec:	862a                	mv	a2,a0
ffffffffc02019ee:	00000073          	ecall
ffffffffc02019f2:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc02019f4:	2501                	sext.w	a0,a0
ffffffffc02019f6:	8082                	ret

ffffffffc02019f8 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc02019f8:	4781                	li	a5,0
ffffffffc02019fa:	00004717          	auipc	a4,0x4
ffffffffc02019fe:	61673703          	ld	a4,1558(a4) # ffffffffc0206010 <SBI_SHUTDOWN>
ffffffffc0201a02:	88ba                	mv	a7,a4
ffffffffc0201a04:	853e                	mv	a0,a5
ffffffffc0201a06:	85be                	mv	a1,a5
ffffffffc0201a08:	863e                	mv	a2,a5
ffffffffc0201a0a:	00000073          	ecall
ffffffffc0201a0e:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN,0,0,0);
ffffffffc0201a10:	8082                	ret

ffffffffc0201a12 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201a12:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201a14:	e589                	bnez	a1,ffffffffc0201a1e <strnlen+0xc>
ffffffffc0201a16:	a811                	j	ffffffffc0201a2a <strnlen+0x18>
        cnt ++;
ffffffffc0201a18:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201a1a:	00f58863          	beq	a1,a5,ffffffffc0201a2a <strnlen+0x18>
ffffffffc0201a1e:	00f50733          	add	a4,a0,a5
ffffffffc0201a22:	00074703          	lbu	a4,0(a4)
ffffffffc0201a26:	fb6d                	bnez	a4,ffffffffc0201a18 <strnlen+0x6>
ffffffffc0201a28:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201a2a:	852e                	mv	a0,a1
ffffffffc0201a2c:	8082                	ret

ffffffffc0201a2e <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a2e:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201a32:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a36:	cb89                	beqz	a5,ffffffffc0201a48 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201a38:	0505                	addi	a0,a0,1
ffffffffc0201a3a:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a3c:	fee789e3          	beq	a5,a4,ffffffffc0201a2e <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201a40:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201a44:	9d19                	subw	a0,a0,a4
ffffffffc0201a46:	8082                	ret
ffffffffc0201a48:	4501                	li	a0,0
ffffffffc0201a4a:	bfed                	j	ffffffffc0201a44 <strcmp+0x16>

ffffffffc0201a4c <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201a4c:	00054783          	lbu	a5,0(a0)
ffffffffc0201a50:	c799                	beqz	a5,ffffffffc0201a5e <strchr+0x12>
        if (*s == c) {
ffffffffc0201a52:	00f58763          	beq	a1,a5,ffffffffc0201a60 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201a56:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201a5a:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201a5c:	fbfd                	bnez	a5,ffffffffc0201a52 <strchr+0x6>
    }
    return NULL;
ffffffffc0201a5e:	4501                	li	a0,0
}
ffffffffc0201a60:	8082                	ret

ffffffffc0201a62 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201a62:	ca01                	beqz	a2,ffffffffc0201a72 <memset+0x10>
ffffffffc0201a64:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201a66:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201a68:	0785                	addi	a5,a5,1
ffffffffc0201a6a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201a6e:	fec79de3          	bne	a5,a2,ffffffffc0201a68 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201a72:	8082                	ret
