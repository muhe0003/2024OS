
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c020b2b7          	lui	t0,0xc020b
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
ffffffffc0200024:	c020b137          	lui	sp,0xc020b

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

int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	000a7517          	auipc	a0,0xa7
ffffffffc0200036:	3a650513          	addi	a0,a0,934 # ffffffffc02a73d8 <buf>
ffffffffc020003a:	000b3617          	auipc	a2,0xb3
ffffffffc020003e:	8fa60613          	addi	a2,a2,-1798 # ffffffffc02b2934 <end>
kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	408060ef          	jal	ra,ffffffffc0206452 <memset>
    cons_init();                // init the console
ffffffffc020004e:	52a000ef          	jal	ra,ffffffffc0200578 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200052:	00006597          	auipc	a1,0x6
ffffffffc0200056:	42e58593          	addi	a1,a1,1070 # ffffffffc0206480 <etext+0x4>
ffffffffc020005a:	00006517          	auipc	a0,0x6
ffffffffc020005e:	44650513          	addi	a0,a0,1094 # ffffffffc02064a0 <etext+0x24>
ffffffffc0200062:	11e000ef          	jal	ra,ffffffffc0200180 <cprintf>

    print_kerninfo();
ffffffffc0200066:	1a2000ef          	jal	ra,ffffffffc0200208 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006a:	4ee020ef          	jal	ra,ffffffffc0202558 <pmm_init>

    pic_init();                 // init interrupt controller
ffffffffc020006e:	5ba000ef          	jal	ra,ffffffffc0200628 <pic_init>
    idt_init();                 // init interrupt descriptor table
ffffffffc0200072:	5b8000ef          	jal	ra,ffffffffc020062a <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc0200076:	3a4040ef          	jal	ra,ffffffffc020441a <vmm_init>
    proc_init();                // init process table
ffffffffc020007a:	351050ef          	jal	ra,ffffffffc0205bca <proc_init>
    
    ide_init();                 // init ide devices
ffffffffc020007e:	56c000ef          	jal	ra,ffffffffc02005ea <ide_init>
    swap_init();                // init swap
ffffffffc0200082:	37c030ef          	jal	ra,ffffffffc02033fe <swap_init>

    clock_init();               // init clock interrupt
ffffffffc0200086:	4a0000ef          	jal	ra,ffffffffc0200526 <clock_init>
    intr_enable();              // enable irq interrupt
ffffffffc020008a:	592000ef          	jal	ra,ffffffffc020061c <intr_enable>
    
    cpu_idle();                 // run idle process
ffffffffc020008e:	4d5050ef          	jal	ra,ffffffffc0205d62 <cpu_idle>

ffffffffc0200092 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0200092:	715d                	addi	sp,sp,-80
ffffffffc0200094:	e486                	sd	ra,72(sp)
ffffffffc0200096:	e0a6                	sd	s1,64(sp)
ffffffffc0200098:	fc4a                	sd	s2,56(sp)
ffffffffc020009a:	f84e                	sd	s3,48(sp)
ffffffffc020009c:	f452                	sd	s4,40(sp)
ffffffffc020009e:	f056                	sd	s5,32(sp)
ffffffffc02000a0:	ec5a                	sd	s6,24(sp)
ffffffffc02000a2:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000a4:	c901                	beqz	a0,ffffffffc02000b4 <readline+0x22>
ffffffffc02000a6:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000a8:	00006517          	auipc	a0,0x6
ffffffffc02000ac:	40050513          	addi	a0,a0,1024 # ffffffffc02064a8 <etext+0x2c>
ffffffffc02000b0:	0d0000ef          	jal	ra,ffffffffc0200180 <cprintf>
readline(const char *prompt) {
ffffffffc02000b4:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000b6:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000b8:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ba:	4aa9                	li	s5,10
ffffffffc02000bc:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000be:	000a7b97          	auipc	s7,0xa7
ffffffffc02000c2:	31ab8b93          	addi	s7,s7,794 # ffffffffc02a73d8 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000c6:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000ca:	12e000ef          	jal	ra,ffffffffc02001f8 <getchar>
        if (c < 0) {
ffffffffc02000ce:	00054a63          	bltz	a0,ffffffffc02000e2 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000d2:	00a95a63          	bge	s2,a0,ffffffffc02000e6 <readline+0x54>
ffffffffc02000d6:	029a5263          	bge	s4,s1,ffffffffc02000fa <readline+0x68>
        c = getchar();
ffffffffc02000da:	11e000ef          	jal	ra,ffffffffc02001f8 <getchar>
        if (c < 0) {
ffffffffc02000de:	fe055ae3          	bgez	a0,ffffffffc02000d2 <readline+0x40>
            return NULL;
ffffffffc02000e2:	4501                	li	a0,0
ffffffffc02000e4:	a091                	j	ffffffffc0200128 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000e6:	03351463          	bne	a0,s3,ffffffffc020010e <readline+0x7c>
ffffffffc02000ea:	e8a9                	bnez	s1,ffffffffc020013c <readline+0xaa>
        c = getchar();
ffffffffc02000ec:	10c000ef          	jal	ra,ffffffffc02001f8 <getchar>
        if (c < 0) {
ffffffffc02000f0:	fe0549e3          	bltz	a0,ffffffffc02000e2 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000f4:	fea959e3          	bge	s2,a0,ffffffffc02000e6 <readline+0x54>
ffffffffc02000f8:	4481                	li	s1,0
            cputchar(c);
ffffffffc02000fa:	e42a                	sd	a0,8(sp)
ffffffffc02000fc:	0ba000ef          	jal	ra,ffffffffc02001b6 <cputchar>
            buf[i ++] = c;
ffffffffc0200100:	6522                	ld	a0,8(sp)
ffffffffc0200102:	009b87b3          	add	a5,s7,s1
ffffffffc0200106:	2485                	addiw	s1,s1,1
ffffffffc0200108:	00a78023          	sb	a0,0(a5)
ffffffffc020010c:	bf7d                	j	ffffffffc02000ca <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc020010e:	01550463          	beq	a0,s5,ffffffffc0200116 <readline+0x84>
ffffffffc0200112:	fb651ce3          	bne	a0,s6,ffffffffc02000ca <readline+0x38>
            cputchar(c);
ffffffffc0200116:	0a0000ef          	jal	ra,ffffffffc02001b6 <cputchar>
            buf[i] = '\0';
ffffffffc020011a:	000a7517          	auipc	a0,0xa7
ffffffffc020011e:	2be50513          	addi	a0,a0,702 # ffffffffc02a73d8 <buf>
ffffffffc0200122:	94aa                	add	s1,s1,a0
ffffffffc0200124:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0200128:	60a6                	ld	ra,72(sp)
ffffffffc020012a:	6486                	ld	s1,64(sp)
ffffffffc020012c:	7962                	ld	s2,56(sp)
ffffffffc020012e:	79c2                	ld	s3,48(sp)
ffffffffc0200130:	7a22                	ld	s4,40(sp)
ffffffffc0200132:	7a82                	ld	s5,32(sp)
ffffffffc0200134:	6b62                	ld	s6,24(sp)
ffffffffc0200136:	6bc2                	ld	s7,16(sp)
ffffffffc0200138:	6161                	addi	sp,sp,80
ffffffffc020013a:	8082                	ret
            cputchar(c);
ffffffffc020013c:	4521                	li	a0,8
ffffffffc020013e:	078000ef          	jal	ra,ffffffffc02001b6 <cputchar>
            i --;
ffffffffc0200142:	34fd                	addiw	s1,s1,-1
ffffffffc0200144:	b759                	j	ffffffffc02000ca <readline+0x38>

ffffffffc0200146 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200146:	1141                	addi	sp,sp,-16
ffffffffc0200148:	e022                	sd	s0,0(sp)
ffffffffc020014a:	e406                	sd	ra,8(sp)
ffffffffc020014c:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020014e:	42c000ef          	jal	ra,ffffffffc020057a <cons_putc>
    (*cnt) ++;
ffffffffc0200152:	401c                	lw	a5,0(s0)
}
ffffffffc0200154:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200156:	2785                	addiw	a5,a5,1
ffffffffc0200158:	c01c                	sw	a5,0(s0)
}
ffffffffc020015a:	6402                	ld	s0,0(sp)
ffffffffc020015c:	0141                	addi	sp,sp,16
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200160:	1101                	addi	sp,sp,-32
ffffffffc0200162:	862a                	mv	a2,a0
ffffffffc0200164:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200166:	00000517          	auipc	a0,0x0
ffffffffc020016a:	fe050513          	addi	a0,a0,-32 # ffffffffc0200146 <cputch>
ffffffffc020016e:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200170:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200172:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200174:	6e1050ef          	jal	ra,ffffffffc0206054 <vprintfmt>
    return cnt;
}
ffffffffc0200178:	60e2                	ld	ra,24(sp)
ffffffffc020017a:	4532                	lw	a0,12(sp)
ffffffffc020017c:	6105                	addi	sp,sp,32
ffffffffc020017e:	8082                	ret

ffffffffc0200180 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200180:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200182:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200186:	8e2a                	mv	t3,a0
ffffffffc0200188:	f42e                	sd	a1,40(sp)
ffffffffc020018a:	f832                	sd	a2,48(sp)
ffffffffc020018c:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020018e:	00000517          	auipc	a0,0x0
ffffffffc0200192:	fb850513          	addi	a0,a0,-72 # ffffffffc0200146 <cputch>
ffffffffc0200196:	004c                	addi	a1,sp,4
ffffffffc0200198:	869a                	mv	a3,t1
ffffffffc020019a:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc020019c:	ec06                	sd	ra,24(sp)
ffffffffc020019e:	e0ba                	sd	a4,64(sp)
ffffffffc02001a0:	e4be                	sd	a5,72(sp)
ffffffffc02001a2:	e8c2                	sd	a6,80(sp)
ffffffffc02001a4:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001a6:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001a8:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02001aa:	6ab050ef          	jal	ra,ffffffffc0206054 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001ae:	60e2                	ld	ra,24(sp)
ffffffffc02001b0:	4512                	lw	a0,4(sp)
ffffffffc02001b2:	6125                	addi	sp,sp,96
ffffffffc02001b4:	8082                	ret

ffffffffc02001b6 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02001b6:	a6d1                	j	ffffffffc020057a <cons_putc>

ffffffffc02001b8 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02001b8:	1101                	addi	sp,sp,-32
ffffffffc02001ba:	e822                	sd	s0,16(sp)
ffffffffc02001bc:	ec06                	sd	ra,24(sp)
ffffffffc02001be:	e426                	sd	s1,8(sp)
ffffffffc02001c0:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02001c2:	00054503          	lbu	a0,0(a0)
ffffffffc02001c6:	c51d                	beqz	a0,ffffffffc02001f4 <cputs+0x3c>
ffffffffc02001c8:	0405                	addi	s0,s0,1
ffffffffc02001ca:	4485                	li	s1,1
ffffffffc02001cc:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001ce:	3ac000ef          	jal	ra,ffffffffc020057a <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001d2:	00044503          	lbu	a0,0(s0)
ffffffffc02001d6:	008487bb          	addw	a5,s1,s0
ffffffffc02001da:	0405                	addi	s0,s0,1
ffffffffc02001dc:	f96d                	bnez	a0,ffffffffc02001ce <cputs+0x16>
    (*cnt) ++;
ffffffffc02001de:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001e2:	4529                	li	a0,10
ffffffffc02001e4:	396000ef          	jal	ra,ffffffffc020057a <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001e8:	60e2                	ld	ra,24(sp)
ffffffffc02001ea:	8522                	mv	a0,s0
ffffffffc02001ec:	6442                	ld	s0,16(sp)
ffffffffc02001ee:	64a2                	ld	s1,8(sp)
ffffffffc02001f0:	6105                	addi	sp,sp,32
ffffffffc02001f2:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001f4:	4405                	li	s0,1
ffffffffc02001f6:	b7f5                	j	ffffffffc02001e2 <cputs+0x2a>

ffffffffc02001f8 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc02001f8:	1141                	addi	sp,sp,-16
ffffffffc02001fa:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001fc:	3b2000ef          	jal	ra,ffffffffc02005ae <cons_getc>
ffffffffc0200200:	dd75                	beqz	a0,ffffffffc02001fc <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200202:	60a2                	ld	ra,8(sp)
ffffffffc0200204:	0141                	addi	sp,sp,16
ffffffffc0200206:	8082                	ret

ffffffffc0200208 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200208:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020020a:	00006517          	auipc	a0,0x6
ffffffffc020020e:	2a650513          	addi	a0,a0,678 # ffffffffc02064b0 <etext+0x34>
void print_kerninfo(void) {
ffffffffc0200212:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200214:	f6dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200218:	00000597          	auipc	a1,0x0
ffffffffc020021c:	e1a58593          	addi	a1,a1,-486 # ffffffffc0200032 <kern_init>
ffffffffc0200220:	00006517          	auipc	a0,0x6
ffffffffc0200224:	2b050513          	addi	a0,a0,688 # ffffffffc02064d0 <etext+0x54>
ffffffffc0200228:	f59ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020022c:	00006597          	auipc	a1,0x6
ffffffffc0200230:	25058593          	addi	a1,a1,592 # ffffffffc020647c <etext>
ffffffffc0200234:	00006517          	auipc	a0,0x6
ffffffffc0200238:	2bc50513          	addi	a0,a0,700 # ffffffffc02064f0 <etext+0x74>
ffffffffc020023c:	f45ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200240:	000a7597          	auipc	a1,0xa7
ffffffffc0200244:	19858593          	addi	a1,a1,408 # ffffffffc02a73d8 <buf>
ffffffffc0200248:	00006517          	auipc	a0,0x6
ffffffffc020024c:	2c850513          	addi	a0,a0,712 # ffffffffc0206510 <etext+0x94>
ffffffffc0200250:	f31ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200254:	000b2597          	auipc	a1,0xb2
ffffffffc0200258:	6e058593          	addi	a1,a1,1760 # ffffffffc02b2934 <end>
ffffffffc020025c:	00006517          	auipc	a0,0x6
ffffffffc0200260:	2d450513          	addi	a0,a0,724 # ffffffffc0206530 <etext+0xb4>
ffffffffc0200264:	f1dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200268:	000b3597          	auipc	a1,0xb3
ffffffffc020026c:	acb58593          	addi	a1,a1,-1333 # ffffffffc02b2d33 <end+0x3ff>
ffffffffc0200270:	00000797          	auipc	a5,0x0
ffffffffc0200274:	dc278793          	addi	a5,a5,-574 # ffffffffc0200032 <kern_init>
ffffffffc0200278:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020027c:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200280:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200282:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200286:	95be                	add	a1,a1,a5
ffffffffc0200288:	85a9                	srai	a1,a1,0xa
ffffffffc020028a:	00006517          	auipc	a0,0x6
ffffffffc020028e:	2c650513          	addi	a0,a0,710 # ffffffffc0206550 <etext+0xd4>
}
ffffffffc0200292:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200294:	b5f5                	j	ffffffffc0200180 <cprintf>

ffffffffc0200296 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200296:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200298:	00006617          	auipc	a2,0x6
ffffffffc020029c:	2e860613          	addi	a2,a2,744 # ffffffffc0206580 <etext+0x104>
ffffffffc02002a0:	04d00593          	li	a1,77
ffffffffc02002a4:	00006517          	auipc	a0,0x6
ffffffffc02002a8:	2f450513          	addi	a0,a0,756 # ffffffffc0206598 <etext+0x11c>
void print_stackframe(void) {
ffffffffc02002ac:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002ae:	1cc000ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02002b2 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002b2:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002b4:	00006617          	auipc	a2,0x6
ffffffffc02002b8:	2fc60613          	addi	a2,a2,764 # ffffffffc02065b0 <etext+0x134>
ffffffffc02002bc:	00006597          	auipc	a1,0x6
ffffffffc02002c0:	31458593          	addi	a1,a1,788 # ffffffffc02065d0 <etext+0x154>
ffffffffc02002c4:	00006517          	auipc	a0,0x6
ffffffffc02002c8:	31450513          	addi	a0,a0,788 # ffffffffc02065d8 <etext+0x15c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002cc:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002ce:	eb3ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc02002d2:	00006617          	auipc	a2,0x6
ffffffffc02002d6:	31660613          	addi	a2,a2,790 # ffffffffc02065e8 <etext+0x16c>
ffffffffc02002da:	00006597          	auipc	a1,0x6
ffffffffc02002de:	33658593          	addi	a1,a1,822 # ffffffffc0206610 <etext+0x194>
ffffffffc02002e2:	00006517          	auipc	a0,0x6
ffffffffc02002e6:	2f650513          	addi	a0,a0,758 # ffffffffc02065d8 <etext+0x15c>
ffffffffc02002ea:	e97ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc02002ee:	00006617          	auipc	a2,0x6
ffffffffc02002f2:	33260613          	addi	a2,a2,818 # ffffffffc0206620 <etext+0x1a4>
ffffffffc02002f6:	00006597          	auipc	a1,0x6
ffffffffc02002fa:	34a58593          	addi	a1,a1,842 # ffffffffc0206640 <etext+0x1c4>
ffffffffc02002fe:	00006517          	auipc	a0,0x6
ffffffffc0200302:	2da50513          	addi	a0,a0,730 # ffffffffc02065d8 <etext+0x15c>
ffffffffc0200306:	e7bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    }
    return 0;
}
ffffffffc020030a:	60a2                	ld	ra,8(sp)
ffffffffc020030c:	4501                	li	a0,0
ffffffffc020030e:	0141                	addi	sp,sp,16
ffffffffc0200310:	8082                	ret

ffffffffc0200312 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200312:	1141                	addi	sp,sp,-16
ffffffffc0200314:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200316:	ef3ff0ef          	jal	ra,ffffffffc0200208 <print_kerninfo>
    return 0;
}
ffffffffc020031a:	60a2                	ld	ra,8(sp)
ffffffffc020031c:	4501                	li	a0,0
ffffffffc020031e:	0141                	addi	sp,sp,16
ffffffffc0200320:	8082                	ret

ffffffffc0200322 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200322:	1141                	addi	sp,sp,-16
ffffffffc0200324:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200326:	f71ff0ef          	jal	ra,ffffffffc0200296 <print_stackframe>
    return 0;
}
ffffffffc020032a:	60a2                	ld	ra,8(sp)
ffffffffc020032c:	4501                	li	a0,0
ffffffffc020032e:	0141                	addi	sp,sp,16
ffffffffc0200330:	8082                	ret

ffffffffc0200332 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200332:	7115                	addi	sp,sp,-224
ffffffffc0200334:	ed5e                	sd	s7,152(sp)
ffffffffc0200336:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200338:	00006517          	auipc	a0,0x6
ffffffffc020033c:	31850513          	addi	a0,a0,792 # ffffffffc0206650 <etext+0x1d4>
kmonitor(struct trapframe *tf) {
ffffffffc0200340:	ed86                	sd	ra,216(sp)
ffffffffc0200342:	e9a2                	sd	s0,208(sp)
ffffffffc0200344:	e5a6                	sd	s1,200(sp)
ffffffffc0200346:	e1ca                	sd	s2,192(sp)
ffffffffc0200348:	fd4e                	sd	s3,184(sp)
ffffffffc020034a:	f952                	sd	s4,176(sp)
ffffffffc020034c:	f556                	sd	s5,168(sp)
ffffffffc020034e:	f15a                	sd	s6,160(sp)
ffffffffc0200350:	e962                	sd	s8,144(sp)
ffffffffc0200352:	e566                	sd	s9,136(sp)
ffffffffc0200354:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200356:	e2bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020035a:	00006517          	auipc	a0,0x6
ffffffffc020035e:	31e50513          	addi	a0,a0,798 # ffffffffc0206678 <etext+0x1fc>
ffffffffc0200362:	e1fff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    if (tf != NULL) {
ffffffffc0200366:	000b8563          	beqz	s7,ffffffffc0200370 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020036a:	855e                	mv	a0,s7
ffffffffc020036c:	4a4000ef          	jal	ra,ffffffffc0200810 <print_trapframe>
ffffffffc0200370:	00006c17          	auipc	s8,0x6
ffffffffc0200374:	378c0c13          	addi	s8,s8,888 # ffffffffc02066e8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200378:	00006917          	auipc	s2,0x6
ffffffffc020037c:	32890913          	addi	s2,s2,808 # ffffffffc02066a0 <etext+0x224>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200380:	00006497          	auipc	s1,0x6
ffffffffc0200384:	32848493          	addi	s1,s1,808 # ffffffffc02066a8 <etext+0x22c>
        if (argc == MAXARGS - 1) {
ffffffffc0200388:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020038a:	00006b17          	auipc	s6,0x6
ffffffffc020038e:	326b0b13          	addi	s6,s6,806 # ffffffffc02066b0 <etext+0x234>
        argv[argc ++] = buf;
ffffffffc0200392:	00006a17          	auipc	s4,0x6
ffffffffc0200396:	23ea0a13          	addi	s4,s4,574 # ffffffffc02065d0 <etext+0x154>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039a:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020039c:	854a                	mv	a0,s2
ffffffffc020039e:	cf5ff0ef          	jal	ra,ffffffffc0200092 <readline>
ffffffffc02003a2:	842a                	mv	s0,a0
ffffffffc02003a4:	dd65                	beqz	a0,ffffffffc020039c <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003a6:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003aa:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003ac:	e1bd                	bnez	a1,ffffffffc0200412 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02003ae:	fe0c87e3          	beqz	s9,ffffffffc020039c <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003b2:	6582                	ld	a1,0(sp)
ffffffffc02003b4:	00006d17          	auipc	s10,0x6
ffffffffc02003b8:	334d0d13          	addi	s10,s10,820 # ffffffffc02066e8 <commands>
        argv[argc ++] = buf;
ffffffffc02003bc:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003be:	4401                	li	s0,0
ffffffffc02003c0:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003c2:	05c060ef          	jal	ra,ffffffffc020641e <strcmp>
ffffffffc02003c6:	c919                	beqz	a0,ffffffffc02003dc <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003c8:	2405                	addiw	s0,s0,1
ffffffffc02003ca:	0b540063          	beq	s0,s5,ffffffffc020046a <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ce:	000d3503          	ld	a0,0(s10)
ffffffffc02003d2:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003d6:	048060ef          	jal	ra,ffffffffc020641e <strcmp>
ffffffffc02003da:	f57d                	bnez	a0,ffffffffc02003c8 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003dc:	00141793          	slli	a5,s0,0x1
ffffffffc02003e0:	97a2                	add	a5,a5,s0
ffffffffc02003e2:	078e                	slli	a5,a5,0x3
ffffffffc02003e4:	97e2                	add	a5,a5,s8
ffffffffc02003e6:	6b9c                	ld	a5,16(a5)
ffffffffc02003e8:	865e                	mv	a2,s7
ffffffffc02003ea:	002c                	addi	a1,sp,8
ffffffffc02003ec:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003f0:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003f2:	fa0555e3          	bgez	a0,ffffffffc020039c <kmonitor+0x6a>
}
ffffffffc02003f6:	60ee                	ld	ra,216(sp)
ffffffffc02003f8:	644e                	ld	s0,208(sp)
ffffffffc02003fa:	64ae                	ld	s1,200(sp)
ffffffffc02003fc:	690e                	ld	s2,192(sp)
ffffffffc02003fe:	79ea                	ld	s3,184(sp)
ffffffffc0200400:	7a4a                	ld	s4,176(sp)
ffffffffc0200402:	7aaa                	ld	s5,168(sp)
ffffffffc0200404:	7b0a                	ld	s6,160(sp)
ffffffffc0200406:	6bea                	ld	s7,152(sp)
ffffffffc0200408:	6c4a                	ld	s8,144(sp)
ffffffffc020040a:	6caa                	ld	s9,136(sp)
ffffffffc020040c:	6d0a                	ld	s10,128(sp)
ffffffffc020040e:	612d                	addi	sp,sp,224
ffffffffc0200410:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200412:	8526                	mv	a0,s1
ffffffffc0200414:	028060ef          	jal	ra,ffffffffc020643c <strchr>
ffffffffc0200418:	c901                	beqz	a0,ffffffffc0200428 <kmonitor+0xf6>
ffffffffc020041a:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc020041e:	00040023          	sb	zero,0(s0)
ffffffffc0200422:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200424:	d5c9                	beqz	a1,ffffffffc02003ae <kmonitor+0x7c>
ffffffffc0200426:	b7f5                	j	ffffffffc0200412 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200428:	00044783          	lbu	a5,0(s0)
ffffffffc020042c:	d3c9                	beqz	a5,ffffffffc02003ae <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc020042e:	033c8963          	beq	s9,s3,ffffffffc0200460 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200432:	003c9793          	slli	a5,s9,0x3
ffffffffc0200436:	0118                	addi	a4,sp,128
ffffffffc0200438:	97ba                	add	a5,a5,a4
ffffffffc020043a:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020043e:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200442:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200444:	e591                	bnez	a1,ffffffffc0200450 <kmonitor+0x11e>
ffffffffc0200446:	b7b5                	j	ffffffffc02003b2 <kmonitor+0x80>
ffffffffc0200448:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020044c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020044e:	d1a5                	beqz	a1,ffffffffc02003ae <kmonitor+0x7c>
ffffffffc0200450:	8526                	mv	a0,s1
ffffffffc0200452:	7eb050ef          	jal	ra,ffffffffc020643c <strchr>
ffffffffc0200456:	d96d                	beqz	a0,ffffffffc0200448 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200458:	00044583          	lbu	a1,0(s0)
ffffffffc020045c:	d9a9                	beqz	a1,ffffffffc02003ae <kmonitor+0x7c>
ffffffffc020045e:	bf55                	j	ffffffffc0200412 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200460:	45c1                	li	a1,16
ffffffffc0200462:	855a                	mv	a0,s6
ffffffffc0200464:	d1dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc0200468:	b7e9                	j	ffffffffc0200432 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020046a:	6582                	ld	a1,0(sp)
ffffffffc020046c:	00006517          	auipc	a0,0x6
ffffffffc0200470:	26450513          	addi	a0,a0,612 # ffffffffc02066d0 <etext+0x254>
ffffffffc0200474:	d0dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    return 0;
ffffffffc0200478:	b715                	j	ffffffffc020039c <kmonitor+0x6a>

ffffffffc020047a <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020047a:	000b2317          	auipc	t1,0xb2
ffffffffc020047e:	42630313          	addi	t1,t1,1062 # ffffffffc02b28a0 <is_panic>
ffffffffc0200482:	00033e03          	ld	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200486:	715d                	addi	sp,sp,-80
ffffffffc0200488:	ec06                	sd	ra,24(sp)
ffffffffc020048a:	e822                	sd	s0,16(sp)
ffffffffc020048c:	f436                	sd	a3,40(sp)
ffffffffc020048e:	f83a                	sd	a4,48(sp)
ffffffffc0200490:	fc3e                	sd	a5,56(sp)
ffffffffc0200492:	e0c2                	sd	a6,64(sp)
ffffffffc0200494:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200496:	020e1a63          	bnez	t3,ffffffffc02004ca <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020049a:	4785                	li	a5,1
ffffffffc020049c:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004a0:	8432                	mv	s0,a2
ffffffffc02004a2:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004a4:	862e                	mv	a2,a1
ffffffffc02004a6:	85aa                	mv	a1,a0
ffffffffc02004a8:	00006517          	auipc	a0,0x6
ffffffffc02004ac:	28850513          	addi	a0,a0,648 # ffffffffc0206730 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004b0:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b2:	ccfff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004b6:	65a2                	ld	a1,8(sp)
ffffffffc02004b8:	8522                	mv	a0,s0
ffffffffc02004ba:	ca7ff0ef          	jal	ra,ffffffffc0200160 <vcprintf>
    cprintf("\n");
ffffffffc02004be:	00007517          	auipc	a0,0x7
ffffffffc02004c2:	22a50513          	addi	a0,a0,554 # ffffffffc02076e8 <default_pmm_manager+0x518>
ffffffffc02004c6:	cbbff0ef          	jal	ra,ffffffffc0200180 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004ca:	4501                	li	a0,0
ffffffffc02004cc:	4581                	li	a1,0
ffffffffc02004ce:	4601                	li	a2,0
ffffffffc02004d0:	48a1                	li	a7,8
ffffffffc02004d2:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004d6:	14c000ef          	jal	ra,ffffffffc0200622 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004da:	4501                	li	a0,0
ffffffffc02004dc:	e57ff0ef          	jal	ra,ffffffffc0200332 <kmonitor>
    while (1) {
ffffffffc02004e0:	bfed                	j	ffffffffc02004da <__panic+0x60>

ffffffffc02004e2 <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004e2:	715d                	addi	sp,sp,-80
ffffffffc02004e4:	832e                	mv	t1,a1
ffffffffc02004e6:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004e8:	85aa                	mv	a1,a0
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004ea:	8432                	mv	s0,a2
ffffffffc02004ec:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004ee:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc02004f0:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004f2:	00006517          	auipc	a0,0x6
ffffffffc02004f6:	25e50513          	addi	a0,a0,606 # ffffffffc0206750 <commands+0x68>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004fa:	ec06                	sd	ra,24(sp)
ffffffffc02004fc:	f436                	sd	a3,40(sp)
ffffffffc02004fe:	f83a                	sd	a4,48(sp)
ffffffffc0200500:	e0c2                	sd	a6,64(sp)
ffffffffc0200502:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200504:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	c7bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020050a:	65a2                	ld	a1,8(sp)
ffffffffc020050c:	8522                	mv	a0,s0
ffffffffc020050e:	c53ff0ef          	jal	ra,ffffffffc0200160 <vcprintf>
    cprintf("\n");
ffffffffc0200512:	00007517          	auipc	a0,0x7
ffffffffc0200516:	1d650513          	addi	a0,a0,470 # ffffffffc02076e8 <default_pmm_manager+0x518>
ffffffffc020051a:	c67ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    va_end(ap);
}
ffffffffc020051e:	60e2                	ld	ra,24(sp)
ffffffffc0200520:	6442                	ld	s0,16(sp)
ffffffffc0200522:	6161                	addi	sp,sp,80
ffffffffc0200524:	8082                	ret

ffffffffc0200526 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200526:	67e1                	lui	a5,0x18
ffffffffc0200528:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd570>
ffffffffc020052c:	000b2717          	auipc	a4,0xb2
ffffffffc0200530:	38f73223          	sd	a5,900(a4) # ffffffffc02b28b0 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200534:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200538:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020053a:	953e                	add	a0,a0,a5
ffffffffc020053c:	4601                	li	a2,0
ffffffffc020053e:	4881                	li	a7,0
ffffffffc0200540:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200544:	02000793          	li	a5,32
ffffffffc0200548:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020054c:	00006517          	auipc	a0,0x6
ffffffffc0200550:	22450513          	addi	a0,a0,548 # ffffffffc0206770 <commands+0x88>
    ticks = 0;
ffffffffc0200554:	000b2797          	auipc	a5,0xb2
ffffffffc0200558:	3407ba23          	sd	zero,852(a5) # ffffffffc02b28a8 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020055c:	b115                	j	ffffffffc0200180 <cprintf>

ffffffffc020055e <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020055e:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200562:	000b2797          	auipc	a5,0xb2
ffffffffc0200566:	34e7b783          	ld	a5,846(a5) # ffffffffc02b28b0 <timebase>
ffffffffc020056a:	953e                	add	a0,a0,a5
ffffffffc020056c:	4581                	li	a1,0
ffffffffc020056e:	4601                	li	a2,0
ffffffffc0200570:	4881                	li	a7,0
ffffffffc0200572:	00000073          	ecall
ffffffffc0200576:	8082                	ret

ffffffffc0200578 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200578:	8082                	ret

ffffffffc020057a <cons_putc>:
#include <sched.h>
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020057a:	100027f3          	csrr	a5,sstatus
ffffffffc020057e:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200580:	0ff57513          	zext.b	a0,a0
ffffffffc0200584:	e799                	bnez	a5,ffffffffc0200592 <cons_putc+0x18>
ffffffffc0200586:	4581                	li	a1,0
ffffffffc0200588:	4601                	li	a2,0
ffffffffc020058a:	4885                	li	a7,1
ffffffffc020058c:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200590:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200592:	1101                	addi	sp,sp,-32
ffffffffc0200594:	ec06                	sd	ra,24(sp)
ffffffffc0200596:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200598:	08a000ef          	jal	ra,ffffffffc0200622 <intr_disable>
ffffffffc020059c:	6522                	ld	a0,8(sp)
ffffffffc020059e:	4581                	li	a1,0
ffffffffc02005a0:	4601                	li	a2,0
ffffffffc02005a2:	4885                	li	a7,1
ffffffffc02005a4:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005a8:	60e2                	ld	ra,24(sp)
ffffffffc02005aa:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02005ac:	a885                	j	ffffffffc020061c <intr_enable>

ffffffffc02005ae <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02005ae:	100027f3          	csrr	a5,sstatus
ffffffffc02005b2:	8b89                	andi	a5,a5,2
ffffffffc02005b4:	eb89                	bnez	a5,ffffffffc02005c6 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005b6:	4501                	li	a0,0
ffffffffc02005b8:	4581                	li	a1,0
ffffffffc02005ba:	4601                	li	a2,0
ffffffffc02005bc:	4889                	li	a7,2
ffffffffc02005be:	00000073          	ecall
ffffffffc02005c2:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005c4:	8082                	ret
int cons_getc(void) {
ffffffffc02005c6:	1101                	addi	sp,sp,-32
ffffffffc02005c8:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005ca:	058000ef          	jal	ra,ffffffffc0200622 <intr_disable>
ffffffffc02005ce:	4501                	li	a0,0
ffffffffc02005d0:	4581                	li	a1,0
ffffffffc02005d2:	4601                	li	a2,0
ffffffffc02005d4:	4889                	li	a7,2
ffffffffc02005d6:	00000073          	ecall
ffffffffc02005da:	2501                	sext.w	a0,a0
ffffffffc02005dc:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005de:	03e000ef          	jal	ra,ffffffffc020061c <intr_enable>
}
ffffffffc02005e2:	60e2                	ld	ra,24(sp)
ffffffffc02005e4:	6522                	ld	a0,8(sp)
ffffffffc02005e6:	6105                	addi	sp,sp,32
ffffffffc02005e8:	8082                	ret

ffffffffc02005ea <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc02005ea:	8082                	ret

ffffffffc02005ec <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc02005ec:	00253513          	sltiu	a0,a0,2
ffffffffc02005f0:	8082                	ret

ffffffffc02005f2 <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc02005f2:	03800513          	li	a0,56
ffffffffc02005f6:	8082                	ret

ffffffffc02005f8 <ide_write_secs>:
    return 0;
}

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    int iobase = secno * SECTSIZE;
ffffffffc02005f8:	0095979b          	slliw	a5,a1,0x9
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02005fc:	000a7517          	auipc	a0,0xa7
ffffffffc0200600:	1dc50513          	addi	a0,a0,476 # ffffffffc02a77d8 <ide>
                   size_t nsecs) {
ffffffffc0200604:	1141                	addi	sp,sp,-16
ffffffffc0200606:	85b2                	mv	a1,a2
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200608:	953e                	add	a0,a0,a5
ffffffffc020060a:	00969613          	slli	a2,a3,0x9
                   size_t nsecs) {
ffffffffc020060e:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200610:	655050ef          	jal	ra,ffffffffc0206464 <memcpy>
    return 0;
}
ffffffffc0200614:	60a2                	ld	ra,8(sp)
ffffffffc0200616:	4501                	li	a0,0
ffffffffc0200618:	0141                	addi	sp,sp,16
ffffffffc020061a:	8082                	ret

ffffffffc020061c <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020061c:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200620:	8082                	ret

ffffffffc0200622 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200622:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200626:	8082                	ret

ffffffffc0200628 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200628:	8082                	ret

ffffffffc020062a <idt_init>:
void
idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020062a:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020062e:	00000797          	auipc	a5,0x0
ffffffffc0200632:	65a78793          	addi	a5,a5,1626 # ffffffffc0200c88 <__alltraps>
ffffffffc0200636:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020063a:	000407b7          	lui	a5,0x40
ffffffffc020063e:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200642:	8082                	ret

ffffffffc0200644 <print_regs>:
    cprintf("  tval 0x%08x\n", tf->tval);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs* gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200644:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs* gpr) {
ffffffffc0200646:	1141                	addi	sp,sp,-16
ffffffffc0200648:	e022                	sd	s0,0(sp)
ffffffffc020064a:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020064c:	00006517          	auipc	a0,0x6
ffffffffc0200650:	14450513          	addi	a0,a0,324 # ffffffffc0206790 <commands+0xa8>
void print_regs(struct pushregs* gpr) {
ffffffffc0200654:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200656:	b2bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020065a:	640c                	ld	a1,8(s0)
ffffffffc020065c:	00006517          	auipc	a0,0x6
ffffffffc0200660:	14c50513          	addi	a0,a0,332 # ffffffffc02067a8 <commands+0xc0>
ffffffffc0200664:	b1dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200668:	680c                	ld	a1,16(s0)
ffffffffc020066a:	00006517          	auipc	a0,0x6
ffffffffc020066e:	15650513          	addi	a0,a0,342 # ffffffffc02067c0 <commands+0xd8>
ffffffffc0200672:	b0fff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200676:	6c0c                	ld	a1,24(s0)
ffffffffc0200678:	00006517          	auipc	a0,0x6
ffffffffc020067c:	16050513          	addi	a0,a0,352 # ffffffffc02067d8 <commands+0xf0>
ffffffffc0200680:	b01ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200684:	700c                	ld	a1,32(s0)
ffffffffc0200686:	00006517          	auipc	a0,0x6
ffffffffc020068a:	16a50513          	addi	a0,a0,362 # ffffffffc02067f0 <commands+0x108>
ffffffffc020068e:	af3ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200692:	740c                	ld	a1,40(s0)
ffffffffc0200694:	00006517          	auipc	a0,0x6
ffffffffc0200698:	17450513          	addi	a0,a0,372 # ffffffffc0206808 <commands+0x120>
ffffffffc020069c:	ae5ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02006a0:	780c                	ld	a1,48(s0)
ffffffffc02006a2:	00006517          	auipc	a0,0x6
ffffffffc02006a6:	17e50513          	addi	a0,a0,382 # ffffffffc0206820 <commands+0x138>
ffffffffc02006aa:	ad7ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006ae:	7c0c                	ld	a1,56(s0)
ffffffffc02006b0:	00006517          	auipc	a0,0x6
ffffffffc02006b4:	18850513          	addi	a0,a0,392 # ffffffffc0206838 <commands+0x150>
ffffffffc02006b8:	ac9ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006bc:	602c                	ld	a1,64(s0)
ffffffffc02006be:	00006517          	auipc	a0,0x6
ffffffffc02006c2:	19250513          	addi	a0,a0,402 # ffffffffc0206850 <commands+0x168>
ffffffffc02006c6:	abbff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02006ca:	642c                	ld	a1,72(s0)
ffffffffc02006cc:	00006517          	auipc	a0,0x6
ffffffffc02006d0:	19c50513          	addi	a0,a0,412 # ffffffffc0206868 <commands+0x180>
ffffffffc02006d4:	aadff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02006d8:	682c                	ld	a1,80(s0)
ffffffffc02006da:	00006517          	auipc	a0,0x6
ffffffffc02006de:	1a650513          	addi	a0,a0,422 # ffffffffc0206880 <commands+0x198>
ffffffffc02006e2:	a9fff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02006e6:	6c2c                	ld	a1,88(s0)
ffffffffc02006e8:	00006517          	auipc	a0,0x6
ffffffffc02006ec:	1b050513          	addi	a0,a0,432 # ffffffffc0206898 <commands+0x1b0>
ffffffffc02006f0:	a91ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02006f4:	702c                	ld	a1,96(s0)
ffffffffc02006f6:	00006517          	auipc	a0,0x6
ffffffffc02006fa:	1ba50513          	addi	a0,a0,442 # ffffffffc02068b0 <commands+0x1c8>
ffffffffc02006fe:	a83ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200702:	742c                	ld	a1,104(s0)
ffffffffc0200704:	00006517          	auipc	a0,0x6
ffffffffc0200708:	1c450513          	addi	a0,a0,452 # ffffffffc02068c8 <commands+0x1e0>
ffffffffc020070c:	a75ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200710:	782c                	ld	a1,112(s0)
ffffffffc0200712:	00006517          	auipc	a0,0x6
ffffffffc0200716:	1ce50513          	addi	a0,a0,462 # ffffffffc02068e0 <commands+0x1f8>
ffffffffc020071a:	a67ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020071e:	7c2c                	ld	a1,120(s0)
ffffffffc0200720:	00006517          	auipc	a0,0x6
ffffffffc0200724:	1d850513          	addi	a0,a0,472 # ffffffffc02068f8 <commands+0x210>
ffffffffc0200728:	a59ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020072c:	604c                	ld	a1,128(s0)
ffffffffc020072e:	00006517          	auipc	a0,0x6
ffffffffc0200732:	1e250513          	addi	a0,a0,482 # ffffffffc0206910 <commands+0x228>
ffffffffc0200736:	a4bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020073a:	644c                	ld	a1,136(s0)
ffffffffc020073c:	00006517          	auipc	a0,0x6
ffffffffc0200740:	1ec50513          	addi	a0,a0,492 # ffffffffc0206928 <commands+0x240>
ffffffffc0200744:	a3dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200748:	684c                	ld	a1,144(s0)
ffffffffc020074a:	00006517          	auipc	a0,0x6
ffffffffc020074e:	1f650513          	addi	a0,a0,502 # ffffffffc0206940 <commands+0x258>
ffffffffc0200752:	a2fff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200756:	6c4c                	ld	a1,152(s0)
ffffffffc0200758:	00006517          	auipc	a0,0x6
ffffffffc020075c:	20050513          	addi	a0,a0,512 # ffffffffc0206958 <commands+0x270>
ffffffffc0200760:	a21ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200764:	704c                	ld	a1,160(s0)
ffffffffc0200766:	00006517          	auipc	a0,0x6
ffffffffc020076a:	20a50513          	addi	a0,a0,522 # ffffffffc0206970 <commands+0x288>
ffffffffc020076e:	a13ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200772:	744c                	ld	a1,168(s0)
ffffffffc0200774:	00006517          	auipc	a0,0x6
ffffffffc0200778:	21450513          	addi	a0,a0,532 # ffffffffc0206988 <commands+0x2a0>
ffffffffc020077c:	a05ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200780:	784c                	ld	a1,176(s0)
ffffffffc0200782:	00006517          	auipc	a0,0x6
ffffffffc0200786:	21e50513          	addi	a0,a0,542 # ffffffffc02069a0 <commands+0x2b8>
ffffffffc020078a:	9f7ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc020078e:	7c4c                	ld	a1,184(s0)
ffffffffc0200790:	00006517          	auipc	a0,0x6
ffffffffc0200794:	22850513          	addi	a0,a0,552 # ffffffffc02069b8 <commands+0x2d0>
ffffffffc0200798:	9e9ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc020079c:	606c                	ld	a1,192(s0)
ffffffffc020079e:	00006517          	auipc	a0,0x6
ffffffffc02007a2:	23250513          	addi	a0,a0,562 # ffffffffc02069d0 <commands+0x2e8>
ffffffffc02007a6:	9dbff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007aa:	646c                	ld	a1,200(s0)
ffffffffc02007ac:	00006517          	auipc	a0,0x6
ffffffffc02007b0:	23c50513          	addi	a0,a0,572 # ffffffffc02069e8 <commands+0x300>
ffffffffc02007b4:	9cdff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007b8:	686c                	ld	a1,208(s0)
ffffffffc02007ba:	00006517          	auipc	a0,0x6
ffffffffc02007be:	24650513          	addi	a0,a0,582 # ffffffffc0206a00 <commands+0x318>
ffffffffc02007c2:	9bfff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007c6:	6c6c                	ld	a1,216(s0)
ffffffffc02007c8:	00006517          	auipc	a0,0x6
ffffffffc02007cc:	25050513          	addi	a0,a0,592 # ffffffffc0206a18 <commands+0x330>
ffffffffc02007d0:	9b1ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02007d4:	706c                	ld	a1,224(s0)
ffffffffc02007d6:	00006517          	auipc	a0,0x6
ffffffffc02007da:	25a50513          	addi	a0,a0,602 # ffffffffc0206a30 <commands+0x348>
ffffffffc02007de:	9a3ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02007e2:	746c                	ld	a1,232(s0)
ffffffffc02007e4:	00006517          	auipc	a0,0x6
ffffffffc02007e8:	26450513          	addi	a0,a0,612 # ffffffffc0206a48 <commands+0x360>
ffffffffc02007ec:	995ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02007f0:	786c                	ld	a1,240(s0)
ffffffffc02007f2:	00006517          	auipc	a0,0x6
ffffffffc02007f6:	26e50513          	addi	a0,a0,622 # ffffffffc0206a60 <commands+0x378>
ffffffffc02007fa:	987ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02007fe:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200800:	6402                	ld	s0,0(sp)
ffffffffc0200802:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200804:	00006517          	auipc	a0,0x6
ffffffffc0200808:	27450513          	addi	a0,a0,628 # ffffffffc0206a78 <commands+0x390>
}
ffffffffc020080c:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020080e:	ba8d                	j	ffffffffc0200180 <cprintf>

ffffffffc0200810 <print_trapframe>:
print_trapframe(struct trapframe *tf) {
ffffffffc0200810:	1141                	addi	sp,sp,-16
ffffffffc0200812:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200814:	85aa                	mv	a1,a0
print_trapframe(struct trapframe *tf) {
ffffffffc0200816:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200818:	00006517          	auipc	a0,0x6
ffffffffc020081c:	27850513          	addi	a0,a0,632 # ffffffffc0206a90 <commands+0x3a8>
print_trapframe(struct trapframe *tf) {
ffffffffc0200820:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200822:	95fff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200826:	8522                	mv	a0,s0
ffffffffc0200828:	e1dff0ef          	jal	ra,ffffffffc0200644 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020082c:	10043583          	ld	a1,256(s0)
ffffffffc0200830:	00006517          	auipc	a0,0x6
ffffffffc0200834:	27850513          	addi	a0,a0,632 # ffffffffc0206aa8 <commands+0x3c0>
ffffffffc0200838:	949ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020083c:	10843583          	ld	a1,264(s0)
ffffffffc0200840:	00006517          	auipc	a0,0x6
ffffffffc0200844:	28050513          	addi	a0,a0,640 # ffffffffc0206ac0 <commands+0x3d8>
ffffffffc0200848:	939ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc020084c:	11043583          	ld	a1,272(s0)
ffffffffc0200850:	00006517          	auipc	a0,0x6
ffffffffc0200854:	28850513          	addi	a0,a0,648 # ffffffffc0206ad8 <commands+0x3f0>
ffffffffc0200858:	929ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020085c:	11843583          	ld	a1,280(s0)
}
ffffffffc0200860:	6402                	ld	s0,0(sp)
ffffffffc0200862:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200864:	00006517          	auipc	a0,0x6
ffffffffc0200868:	28450513          	addi	a0,a0,644 # ffffffffc0206ae8 <commands+0x400>
}
ffffffffc020086c:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020086e:	913ff06f          	j	ffffffffc0200180 <cprintf>

ffffffffc0200872 <pgfault_handler>:
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int
pgfault_handler(struct trapframe *tf) {
ffffffffc0200872:	1101                	addi	sp,sp,-32
ffffffffc0200874:	e426                	sd	s1,8(sp)
    extern struct mm_struct *check_mm_struct;
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc0200876:	000b2497          	auipc	s1,0xb2
ffffffffc020087a:	09248493          	addi	s1,s1,146 # ffffffffc02b2908 <check_mm_struct>
ffffffffc020087e:	609c                	ld	a5,0(s1)
pgfault_handler(struct trapframe *tf) {
ffffffffc0200880:	e822                	sd	s0,16(sp)
ffffffffc0200882:	ec06                	sd	ra,24(sp)
ffffffffc0200884:	842a                	mv	s0,a0
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc0200886:	cbad                	beqz	a5,ffffffffc02008f8 <pgfault_handler+0x86>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200888:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc020088c:	11053583          	ld	a1,272(a0)
ffffffffc0200890:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200894:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200898:	c7b1                	beqz	a5,ffffffffc02008e4 <pgfault_handler+0x72>
ffffffffc020089a:	11843703          	ld	a4,280(s0)
ffffffffc020089e:	47bd                	li	a5,15
ffffffffc02008a0:	05700693          	li	a3,87
ffffffffc02008a4:	00f70463          	beq	a4,a5,ffffffffc02008ac <pgfault_handler+0x3a>
ffffffffc02008a8:	05200693          	li	a3,82
ffffffffc02008ac:	00006517          	auipc	a0,0x6
ffffffffc02008b0:	25450513          	addi	a0,a0,596 # ffffffffc0206b00 <commands+0x418>
ffffffffc02008b4:	8cdff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            print_pgfault(tf);
        }
    struct mm_struct *mm;
    if (check_mm_struct != NULL) {
ffffffffc02008b8:	6088                	ld	a0,0(s1)
ffffffffc02008ba:	cd1d                	beqz	a0,ffffffffc02008f8 <pgfault_handler+0x86>
        assert(current == idleproc);
ffffffffc02008bc:	000b2717          	auipc	a4,0xb2
ffffffffc02008c0:	05c73703          	ld	a4,92(a4) # ffffffffc02b2918 <current>
ffffffffc02008c4:	000b2797          	auipc	a5,0xb2
ffffffffc02008c8:	05c7b783          	ld	a5,92(a5) # ffffffffc02b2920 <idleproc>
ffffffffc02008cc:	04f71663          	bne	a4,a5,ffffffffc0200918 <pgfault_handler+0xa6>
            print_pgfault(tf);
            panic("unhandled page fault.\n");
        }
        mm = current->mm;
    }
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc02008d0:	11043603          	ld	a2,272(s0)
ffffffffc02008d4:	11843583          	ld	a1,280(s0)
}
ffffffffc02008d8:	6442                	ld	s0,16(sp)
ffffffffc02008da:	60e2                	ld	ra,24(sp)
ffffffffc02008dc:	64a2                	ld	s1,8(sp)
ffffffffc02008de:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc02008e0:	07a0406f          	j	ffffffffc020495a <do_pgfault>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008e4:	11843703          	ld	a4,280(s0)
ffffffffc02008e8:	47bd                	li	a5,15
ffffffffc02008ea:	05500613          	li	a2,85
ffffffffc02008ee:	05700693          	li	a3,87
ffffffffc02008f2:	faf71be3          	bne	a4,a5,ffffffffc02008a8 <pgfault_handler+0x36>
ffffffffc02008f6:	bf5d                	j	ffffffffc02008ac <pgfault_handler+0x3a>
        if (current == NULL) {
ffffffffc02008f8:	000b2797          	auipc	a5,0xb2
ffffffffc02008fc:	0207b783          	ld	a5,32(a5) # ffffffffc02b2918 <current>
ffffffffc0200900:	cf85                	beqz	a5,ffffffffc0200938 <pgfault_handler+0xc6>
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200902:	11043603          	ld	a2,272(s0)
ffffffffc0200906:	11843583          	ld	a1,280(s0)
}
ffffffffc020090a:	6442                	ld	s0,16(sp)
ffffffffc020090c:	60e2                	ld	ra,24(sp)
ffffffffc020090e:	64a2                	ld	s1,8(sp)
        mm = current->mm;
ffffffffc0200910:	7788                	ld	a0,40(a5)
}
ffffffffc0200912:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200914:	0460406f          	j	ffffffffc020495a <do_pgfault>
        assert(current == idleproc);
ffffffffc0200918:	00006697          	auipc	a3,0x6
ffffffffc020091c:	20868693          	addi	a3,a3,520 # ffffffffc0206b20 <commands+0x438>
ffffffffc0200920:	00006617          	auipc	a2,0x6
ffffffffc0200924:	21860613          	addi	a2,a2,536 # ffffffffc0206b38 <commands+0x450>
ffffffffc0200928:	06b00593          	li	a1,107
ffffffffc020092c:	00006517          	auipc	a0,0x6
ffffffffc0200930:	22450513          	addi	a0,a0,548 # ffffffffc0206b50 <commands+0x468>
ffffffffc0200934:	b47ff0ef          	jal	ra,ffffffffc020047a <__panic>
            print_trapframe(tf);
ffffffffc0200938:	8522                	mv	a0,s0
ffffffffc020093a:	ed7ff0ef          	jal	ra,ffffffffc0200810 <print_trapframe>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020093e:	10043783          	ld	a5,256(s0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200942:	11043583          	ld	a1,272(s0)
ffffffffc0200946:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020094a:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc020094e:	e399                	bnez	a5,ffffffffc0200954 <pgfault_handler+0xe2>
ffffffffc0200950:	05500613          	li	a2,85
ffffffffc0200954:	11843703          	ld	a4,280(s0)
ffffffffc0200958:	47bd                	li	a5,15
ffffffffc020095a:	02f70663          	beq	a4,a5,ffffffffc0200986 <pgfault_handler+0x114>
ffffffffc020095e:	05200693          	li	a3,82
ffffffffc0200962:	00006517          	auipc	a0,0x6
ffffffffc0200966:	19e50513          	addi	a0,a0,414 # ffffffffc0206b00 <commands+0x418>
ffffffffc020096a:	817ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            panic("unhandled page fault.\n");
ffffffffc020096e:	00006617          	auipc	a2,0x6
ffffffffc0200972:	1fa60613          	addi	a2,a2,506 # ffffffffc0206b68 <commands+0x480>
ffffffffc0200976:	07200593          	li	a1,114
ffffffffc020097a:	00006517          	auipc	a0,0x6
ffffffffc020097e:	1d650513          	addi	a0,a0,470 # ffffffffc0206b50 <commands+0x468>
ffffffffc0200982:	af9ff0ef          	jal	ra,ffffffffc020047a <__panic>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200986:	05700693          	li	a3,87
ffffffffc020098a:	bfe1                	j	ffffffffc0200962 <pgfault_handler+0xf0>

ffffffffc020098c <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc020098c:	11853783          	ld	a5,280(a0)
ffffffffc0200990:	472d                	li	a4,11
ffffffffc0200992:	0786                	slli	a5,a5,0x1
ffffffffc0200994:	8385                	srli	a5,a5,0x1
ffffffffc0200996:	08f76363          	bltu	a4,a5,ffffffffc0200a1c <interrupt_handler+0x90>
ffffffffc020099a:	00006717          	auipc	a4,0x6
ffffffffc020099e:	28670713          	addi	a4,a4,646 # ffffffffc0206c20 <commands+0x538>
ffffffffc02009a2:	078a                	slli	a5,a5,0x2
ffffffffc02009a4:	97ba                	add	a5,a5,a4
ffffffffc02009a6:	439c                	lw	a5,0(a5)
ffffffffc02009a8:	97ba                	add	a5,a5,a4
ffffffffc02009aa:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02009ac:	00006517          	auipc	a0,0x6
ffffffffc02009b0:	23450513          	addi	a0,a0,564 # ffffffffc0206be0 <commands+0x4f8>
ffffffffc02009b4:	fccff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02009b8:	00006517          	auipc	a0,0x6
ffffffffc02009bc:	20850513          	addi	a0,a0,520 # ffffffffc0206bc0 <commands+0x4d8>
ffffffffc02009c0:	fc0ff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02009c4:	00006517          	auipc	a0,0x6
ffffffffc02009c8:	1bc50513          	addi	a0,a0,444 # ffffffffc0206b80 <commands+0x498>
ffffffffc02009cc:	fb4ff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02009d0:	00006517          	auipc	a0,0x6
ffffffffc02009d4:	1d050513          	addi	a0,a0,464 # ffffffffc0206ba0 <commands+0x4b8>
ffffffffc02009d8:	fa8ff06f          	j	ffffffffc0200180 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02009dc:	1141                	addi	sp,sp,-16
ffffffffc02009de:	e406                	sd	ra,8(sp)
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc02009e0:	b7fff0ef          	jal	ra,ffffffffc020055e <clock_set_next_event>
            if (++ticks % TICK_NUM == 0 && current) {
ffffffffc02009e4:	000b2697          	auipc	a3,0xb2
ffffffffc02009e8:	ec468693          	addi	a3,a3,-316 # ffffffffc02b28a8 <ticks>
ffffffffc02009ec:	629c                	ld	a5,0(a3)
ffffffffc02009ee:	06400713          	li	a4,100
ffffffffc02009f2:	0785                	addi	a5,a5,1
ffffffffc02009f4:	02e7f733          	remu	a4,a5,a4
ffffffffc02009f8:	e29c                	sd	a5,0(a3)
ffffffffc02009fa:	eb01                	bnez	a4,ffffffffc0200a0a <interrupt_handler+0x7e>
ffffffffc02009fc:	000b2797          	auipc	a5,0xb2
ffffffffc0200a00:	f1c7b783          	ld	a5,-228(a5) # ffffffffc02b2918 <current>
ffffffffc0200a04:	c399                	beqz	a5,ffffffffc0200a0a <interrupt_handler+0x7e>
                // print_ticks();
                current->need_resched = 1;
ffffffffc0200a06:	4705                	li	a4,1
ffffffffc0200a08:	ef98                	sd	a4,24(a5)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a0a:	60a2                	ld	ra,8(sp)
ffffffffc0200a0c:	0141                	addi	sp,sp,16
ffffffffc0200a0e:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200a10:	00006517          	auipc	a0,0x6
ffffffffc0200a14:	1f050513          	addi	a0,a0,496 # ffffffffc0206c00 <commands+0x518>
ffffffffc0200a18:	f68ff06f          	j	ffffffffc0200180 <cprintf>
            print_trapframe(tf);
ffffffffc0200a1c:	bbd5                	j	ffffffffc0200810 <print_trapframe>

ffffffffc0200a1e <exception_handler>:
void kernel_execve_ret(struct trapframe *tf,uintptr_t kstacktop);
void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200a1e:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200a22:	1101                	addi	sp,sp,-32
ffffffffc0200a24:	e822                	sd	s0,16(sp)
ffffffffc0200a26:	ec06                	sd	ra,24(sp)
ffffffffc0200a28:	e426                	sd	s1,8(sp)
ffffffffc0200a2a:	473d                	li	a4,15
ffffffffc0200a2c:	842a                	mv	s0,a0
ffffffffc0200a2e:	18f76563          	bltu	a4,a5,ffffffffc0200bb8 <exception_handler+0x19a>
ffffffffc0200a32:	00006717          	auipc	a4,0x6
ffffffffc0200a36:	3b670713          	addi	a4,a4,950 # ffffffffc0206de8 <commands+0x700>
ffffffffc0200a3a:	078a                	slli	a5,a5,0x2
ffffffffc0200a3c:	97ba                	add	a5,a5,a4
ffffffffc0200a3e:	439c                	lw	a5,0(a5)
ffffffffc0200a40:	97ba                	add	a5,a5,a4
ffffffffc0200a42:	8782                	jr	a5
            //cprintf("Environment call from U-mode\n");
            tf->epc += 4;
            syscall();
            break;
        case CAUSE_SUPERVISOR_ECALL:
            cprintf("Environment call from S-mode\n");
ffffffffc0200a44:	00006517          	auipc	a0,0x6
ffffffffc0200a48:	2fc50513          	addi	a0,a0,764 # ffffffffc0206d40 <commands+0x658>
ffffffffc0200a4c:	f34ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            tf->epc += 4;
ffffffffc0200a50:	10843783          	ld	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a54:	60e2                	ld	ra,24(sp)
ffffffffc0200a56:	64a2                	ld	s1,8(sp)
            tf->epc += 4;
ffffffffc0200a58:	0791                	addi	a5,a5,4
ffffffffc0200a5a:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200a5e:	6442                	ld	s0,16(sp)
ffffffffc0200a60:	6105                	addi	sp,sp,32
            syscall();
ffffffffc0200a62:	4f00506f          	j	ffffffffc0205f52 <syscall>
            cprintf("Environment call from H-mode\n");
ffffffffc0200a66:	00006517          	auipc	a0,0x6
ffffffffc0200a6a:	2fa50513          	addi	a0,a0,762 # ffffffffc0206d60 <commands+0x678>
}
ffffffffc0200a6e:	6442                	ld	s0,16(sp)
ffffffffc0200a70:	60e2                	ld	ra,24(sp)
ffffffffc0200a72:	64a2                	ld	s1,8(sp)
ffffffffc0200a74:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc0200a76:	f0aff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("Environment call from M-mode\n");
ffffffffc0200a7a:	00006517          	auipc	a0,0x6
ffffffffc0200a7e:	30650513          	addi	a0,a0,774 # ffffffffc0206d80 <commands+0x698>
ffffffffc0200a82:	b7f5                	j	ffffffffc0200a6e <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200a84:	00006517          	auipc	a0,0x6
ffffffffc0200a88:	31c50513          	addi	a0,a0,796 # ffffffffc0206da0 <commands+0x6b8>
ffffffffc0200a8c:	b7cd                	j	ffffffffc0200a6e <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200a8e:	00006517          	auipc	a0,0x6
ffffffffc0200a92:	32a50513          	addi	a0,a0,810 # ffffffffc0206db8 <commands+0x6d0>
ffffffffc0200a96:	eeaff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200a9a:	8522                	mv	a0,s0
ffffffffc0200a9c:	dd7ff0ef          	jal	ra,ffffffffc0200872 <pgfault_handler>
ffffffffc0200aa0:	84aa                	mv	s1,a0
ffffffffc0200aa2:	12051d63          	bnez	a0,ffffffffc0200bdc <exception_handler+0x1be>
}
ffffffffc0200aa6:	60e2                	ld	ra,24(sp)
ffffffffc0200aa8:	6442                	ld	s0,16(sp)
ffffffffc0200aaa:	64a2                	ld	s1,8(sp)
ffffffffc0200aac:	6105                	addi	sp,sp,32
ffffffffc0200aae:	8082                	ret
            cprintf("Store/AMO page fault\n");
ffffffffc0200ab0:	00006517          	auipc	a0,0x6
ffffffffc0200ab4:	32050513          	addi	a0,a0,800 # ffffffffc0206dd0 <commands+0x6e8>
ffffffffc0200ab8:	ec8ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200abc:	8522                	mv	a0,s0
ffffffffc0200abe:	db5ff0ef          	jal	ra,ffffffffc0200872 <pgfault_handler>
ffffffffc0200ac2:	84aa                	mv	s1,a0
ffffffffc0200ac4:	d16d                	beqz	a0,ffffffffc0200aa6 <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200ac6:	8522                	mv	a0,s0
ffffffffc0200ac8:	d49ff0ef          	jal	ra,ffffffffc0200810 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200acc:	86a6                	mv	a3,s1
ffffffffc0200ace:	00006617          	auipc	a2,0x6
ffffffffc0200ad2:	22260613          	addi	a2,a2,546 # ffffffffc0206cf0 <commands+0x608>
ffffffffc0200ad6:	0f800593          	li	a1,248
ffffffffc0200ada:	00006517          	auipc	a0,0x6
ffffffffc0200ade:	07650513          	addi	a0,a0,118 # ffffffffc0206b50 <commands+0x468>
ffffffffc0200ae2:	999ff0ef          	jal	ra,ffffffffc020047a <__panic>
            cprintf("Instruction address misaligned\n");
ffffffffc0200ae6:	00006517          	auipc	a0,0x6
ffffffffc0200aea:	16a50513          	addi	a0,a0,362 # ffffffffc0206c50 <commands+0x568>
ffffffffc0200aee:	b741                	j	ffffffffc0200a6e <exception_handler+0x50>
            cprintf("Instruction access fault\n");
ffffffffc0200af0:	00006517          	auipc	a0,0x6
ffffffffc0200af4:	18050513          	addi	a0,a0,384 # ffffffffc0206c70 <commands+0x588>
ffffffffc0200af8:	bf9d                	j	ffffffffc0200a6e <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc0200afa:	00006517          	auipc	a0,0x6
ffffffffc0200afe:	19650513          	addi	a0,a0,406 # ffffffffc0206c90 <commands+0x5a8>
ffffffffc0200b02:	b7b5                	j	ffffffffc0200a6e <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc0200b04:	00006517          	auipc	a0,0x6
ffffffffc0200b08:	1a450513          	addi	a0,a0,420 # ffffffffc0206ca8 <commands+0x5c0>
ffffffffc0200b0c:	e74ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if(tf->gpr.a7 == 10){
ffffffffc0200b10:	6458                	ld	a4,136(s0)
ffffffffc0200b12:	47a9                	li	a5,10
ffffffffc0200b14:	f8f719e3          	bne	a4,a5,ffffffffc0200aa6 <exception_handler+0x88>
                tf->epc += 4;
ffffffffc0200b18:	10843783          	ld	a5,264(s0)
ffffffffc0200b1c:	0791                	addi	a5,a5,4
ffffffffc0200b1e:	10f43423          	sd	a5,264(s0)
                syscall();
ffffffffc0200b22:	430050ef          	jal	ra,ffffffffc0205f52 <syscall>
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b26:	000b2797          	auipc	a5,0xb2
ffffffffc0200b2a:	df27b783          	ld	a5,-526(a5) # ffffffffc02b2918 <current>
ffffffffc0200b2e:	6b9c                	ld	a5,16(a5)
ffffffffc0200b30:	8522                	mv	a0,s0
}
ffffffffc0200b32:	6442                	ld	s0,16(sp)
ffffffffc0200b34:	60e2                	ld	ra,24(sp)
ffffffffc0200b36:	64a2                	ld	s1,8(sp)
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b38:	6589                	lui	a1,0x2
ffffffffc0200b3a:	95be                	add	a1,a1,a5
}
ffffffffc0200b3c:	6105                	addi	sp,sp,32
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b3e:	ac21                	j	ffffffffc0200d56 <kernel_execve_ret>
            cprintf("Load address misaligned\n");
ffffffffc0200b40:	00006517          	auipc	a0,0x6
ffffffffc0200b44:	17850513          	addi	a0,a0,376 # ffffffffc0206cb8 <commands+0x5d0>
ffffffffc0200b48:	b71d                	j	ffffffffc0200a6e <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc0200b4a:	00006517          	auipc	a0,0x6
ffffffffc0200b4e:	18e50513          	addi	a0,a0,398 # ffffffffc0206cd8 <commands+0x5f0>
ffffffffc0200b52:	e2eff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200b56:	8522                	mv	a0,s0
ffffffffc0200b58:	d1bff0ef          	jal	ra,ffffffffc0200872 <pgfault_handler>
ffffffffc0200b5c:	84aa                	mv	s1,a0
ffffffffc0200b5e:	d521                	beqz	a0,ffffffffc0200aa6 <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200b60:	8522                	mv	a0,s0
ffffffffc0200b62:	cafff0ef          	jal	ra,ffffffffc0200810 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200b66:	86a6                	mv	a3,s1
ffffffffc0200b68:	00006617          	auipc	a2,0x6
ffffffffc0200b6c:	18860613          	addi	a2,a2,392 # ffffffffc0206cf0 <commands+0x608>
ffffffffc0200b70:	0cd00593          	li	a1,205
ffffffffc0200b74:	00006517          	auipc	a0,0x6
ffffffffc0200b78:	fdc50513          	addi	a0,a0,-36 # ffffffffc0206b50 <commands+0x468>
ffffffffc0200b7c:	8ffff0ef          	jal	ra,ffffffffc020047a <__panic>
            cprintf("Store/AMO access fault\n");
ffffffffc0200b80:	00006517          	auipc	a0,0x6
ffffffffc0200b84:	1a850513          	addi	a0,a0,424 # ffffffffc0206d28 <commands+0x640>
ffffffffc0200b88:	df8ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200b8c:	8522                	mv	a0,s0
ffffffffc0200b8e:	ce5ff0ef          	jal	ra,ffffffffc0200872 <pgfault_handler>
ffffffffc0200b92:	84aa                	mv	s1,a0
ffffffffc0200b94:	f00509e3          	beqz	a0,ffffffffc0200aa6 <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200b98:	8522                	mv	a0,s0
ffffffffc0200b9a:	c77ff0ef          	jal	ra,ffffffffc0200810 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200b9e:	86a6                	mv	a3,s1
ffffffffc0200ba0:	00006617          	auipc	a2,0x6
ffffffffc0200ba4:	15060613          	addi	a2,a2,336 # ffffffffc0206cf0 <commands+0x608>
ffffffffc0200ba8:	0d700593          	li	a1,215
ffffffffc0200bac:	00006517          	auipc	a0,0x6
ffffffffc0200bb0:	fa450513          	addi	a0,a0,-92 # ffffffffc0206b50 <commands+0x468>
ffffffffc0200bb4:	8c7ff0ef          	jal	ra,ffffffffc020047a <__panic>
            print_trapframe(tf);
ffffffffc0200bb8:	8522                	mv	a0,s0
}
ffffffffc0200bba:	6442                	ld	s0,16(sp)
ffffffffc0200bbc:	60e2                	ld	ra,24(sp)
ffffffffc0200bbe:	64a2                	ld	s1,8(sp)
ffffffffc0200bc0:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200bc2:	b1b9                	j	ffffffffc0200810 <print_trapframe>
            panic("AMO address misaligned\n");
ffffffffc0200bc4:	00006617          	auipc	a2,0x6
ffffffffc0200bc8:	14c60613          	addi	a2,a2,332 # ffffffffc0206d10 <commands+0x628>
ffffffffc0200bcc:	0d100593          	li	a1,209
ffffffffc0200bd0:	00006517          	auipc	a0,0x6
ffffffffc0200bd4:	f8050513          	addi	a0,a0,-128 # ffffffffc0206b50 <commands+0x468>
ffffffffc0200bd8:	8a3ff0ef          	jal	ra,ffffffffc020047a <__panic>
                print_trapframe(tf);
ffffffffc0200bdc:	8522                	mv	a0,s0
ffffffffc0200bde:	c33ff0ef          	jal	ra,ffffffffc0200810 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200be2:	86a6                	mv	a3,s1
ffffffffc0200be4:	00006617          	auipc	a2,0x6
ffffffffc0200be8:	10c60613          	addi	a2,a2,268 # ffffffffc0206cf0 <commands+0x608>
ffffffffc0200bec:	0f100593          	li	a1,241
ffffffffc0200bf0:	00006517          	auipc	a0,0x6
ffffffffc0200bf4:	f6050513          	addi	a0,a0,-160 # ffffffffc0206b50 <commands+0x468>
ffffffffc0200bf8:	883ff0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0200bfc <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
ffffffffc0200bfc:	1101                	addi	sp,sp,-32
ffffffffc0200bfe:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
//    cputs("some trap");
    if (current == NULL) {
ffffffffc0200c00:	000b2417          	auipc	s0,0xb2
ffffffffc0200c04:	d1840413          	addi	s0,s0,-744 # ffffffffc02b2918 <current>
ffffffffc0200c08:	6018                	ld	a4,0(s0)
trap(struct trapframe *tf) {
ffffffffc0200c0a:	ec06                	sd	ra,24(sp)
ffffffffc0200c0c:	e426                	sd	s1,8(sp)
ffffffffc0200c0e:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c10:	11853683          	ld	a3,280(a0)
    if (current == NULL) {
ffffffffc0200c14:	cf1d                	beqz	a4,ffffffffc0200c52 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c16:	10053483          	ld	s1,256(a0)
        trap_dispatch(tf);
    } else {
        struct trapframe *otf = current->tf;
ffffffffc0200c1a:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200c1e:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c20:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c24:	0206c463          	bltz	a3,ffffffffc0200c4c <trap+0x50>
        exception_handler(tf);
ffffffffc0200c28:	df7ff0ef          	jal	ra,ffffffffc0200a1e <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200c2c:	601c                	ld	a5,0(s0)
ffffffffc0200c2e:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel) {
ffffffffc0200c32:	e499                	bnez	s1,ffffffffc0200c40 <trap+0x44>
            if (current->flags & PF_EXITING) {
ffffffffc0200c34:	0b07a703          	lw	a4,176(a5)
ffffffffc0200c38:	8b05                	andi	a4,a4,1
ffffffffc0200c3a:	e329                	bnez	a4,ffffffffc0200c7c <trap+0x80>
                do_exit(-E_KILLED);
            }
            if (current->need_resched) {
ffffffffc0200c3c:	6f9c                	ld	a5,24(a5)
ffffffffc0200c3e:	eb85                	bnez	a5,ffffffffc0200c6e <trap+0x72>
                schedule();
            }
        }
    }
}
ffffffffc0200c40:	60e2                	ld	ra,24(sp)
ffffffffc0200c42:	6442                	ld	s0,16(sp)
ffffffffc0200c44:	64a2                	ld	s1,8(sp)
ffffffffc0200c46:	6902                	ld	s2,0(sp)
ffffffffc0200c48:	6105                	addi	sp,sp,32
ffffffffc0200c4a:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200c4c:	d41ff0ef          	jal	ra,ffffffffc020098c <interrupt_handler>
ffffffffc0200c50:	bff1                	j	ffffffffc0200c2c <trap+0x30>
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c52:	0006c863          	bltz	a3,ffffffffc0200c62 <trap+0x66>
}
ffffffffc0200c56:	6442                	ld	s0,16(sp)
ffffffffc0200c58:	60e2                	ld	ra,24(sp)
ffffffffc0200c5a:	64a2                	ld	s1,8(sp)
ffffffffc0200c5c:	6902                	ld	s2,0(sp)
ffffffffc0200c5e:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200c60:	bb7d                	j	ffffffffc0200a1e <exception_handler>
}
ffffffffc0200c62:	6442                	ld	s0,16(sp)
ffffffffc0200c64:	60e2                	ld	ra,24(sp)
ffffffffc0200c66:	64a2                	ld	s1,8(sp)
ffffffffc0200c68:	6902                	ld	s2,0(sp)
ffffffffc0200c6a:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200c6c:	b305                	j	ffffffffc020098c <interrupt_handler>
}
ffffffffc0200c6e:	6442                	ld	s0,16(sp)
ffffffffc0200c70:	60e2                	ld	ra,24(sp)
ffffffffc0200c72:	64a2                	ld	s1,8(sp)
ffffffffc0200c74:	6902                	ld	s2,0(sp)
ffffffffc0200c76:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200c78:	1ee0506f          	j	ffffffffc0205e66 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200c7c:	555d                	li	a0,-9
ffffffffc0200c7e:	532040ef          	jal	ra,ffffffffc02051b0 <do_exit>
            if (current->need_resched) {
ffffffffc0200c82:	601c                	ld	a5,0(s0)
ffffffffc0200c84:	bf65                	j	ffffffffc0200c3c <trap+0x40>
	...

ffffffffc0200c88 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200c88:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200c8c:	00011463          	bnez	sp,ffffffffc0200c94 <__alltraps+0xc>
ffffffffc0200c90:	14002173          	csrr	sp,sscratch
ffffffffc0200c94:	712d                	addi	sp,sp,-288
ffffffffc0200c96:	e002                	sd	zero,0(sp)
ffffffffc0200c98:	e406                	sd	ra,8(sp)
ffffffffc0200c9a:	ec0e                	sd	gp,24(sp)
ffffffffc0200c9c:	f012                	sd	tp,32(sp)
ffffffffc0200c9e:	f416                	sd	t0,40(sp)
ffffffffc0200ca0:	f81a                	sd	t1,48(sp)
ffffffffc0200ca2:	fc1e                	sd	t2,56(sp)
ffffffffc0200ca4:	e0a2                	sd	s0,64(sp)
ffffffffc0200ca6:	e4a6                	sd	s1,72(sp)
ffffffffc0200ca8:	e8aa                	sd	a0,80(sp)
ffffffffc0200caa:	ecae                	sd	a1,88(sp)
ffffffffc0200cac:	f0b2                	sd	a2,96(sp)
ffffffffc0200cae:	f4b6                	sd	a3,104(sp)
ffffffffc0200cb0:	f8ba                	sd	a4,112(sp)
ffffffffc0200cb2:	fcbe                	sd	a5,120(sp)
ffffffffc0200cb4:	e142                	sd	a6,128(sp)
ffffffffc0200cb6:	e546                	sd	a7,136(sp)
ffffffffc0200cb8:	e94a                	sd	s2,144(sp)
ffffffffc0200cba:	ed4e                	sd	s3,152(sp)
ffffffffc0200cbc:	f152                	sd	s4,160(sp)
ffffffffc0200cbe:	f556                	sd	s5,168(sp)
ffffffffc0200cc0:	f95a                	sd	s6,176(sp)
ffffffffc0200cc2:	fd5e                	sd	s7,184(sp)
ffffffffc0200cc4:	e1e2                	sd	s8,192(sp)
ffffffffc0200cc6:	e5e6                	sd	s9,200(sp)
ffffffffc0200cc8:	e9ea                	sd	s10,208(sp)
ffffffffc0200cca:	edee                	sd	s11,216(sp)
ffffffffc0200ccc:	f1f2                	sd	t3,224(sp)
ffffffffc0200cce:	f5f6                	sd	t4,232(sp)
ffffffffc0200cd0:	f9fa                	sd	t5,240(sp)
ffffffffc0200cd2:	fdfe                	sd	t6,248(sp)
ffffffffc0200cd4:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200cd8:	100024f3          	csrr	s1,sstatus
ffffffffc0200cdc:	14102973          	csrr	s2,sepc
ffffffffc0200ce0:	143029f3          	csrr	s3,stval
ffffffffc0200ce4:	14202a73          	csrr	s4,scause
ffffffffc0200ce8:	e822                	sd	s0,16(sp)
ffffffffc0200cea:	e226                	sd	s1,256(sp)
ffffffffc0200cec:	e64a                	sd	s2,264(sp)
ffffffffc0200cee:	ea4e                	sd	s3,272(sp)
ffffffffc0200cf0:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200cf2:	850a                	mv	a0,sp
    jal trap
ffffffffc0200cf4:	f09ff0ef          	jal	ra,ffffffffc0200bfc <trap>

ffffffffc0200cf8 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200cf8:	6492                	ld	s1,256(sp)
ffffffffc0200cfa:	6932                	ld	s2,264(sp)
ffffffffc0200cfc:	1004f413          	andi	s0,s1,256
ffffffffc0200d00:	e401                	bnez	s0,ffffffffc0200d08 <__trapret+0x10>
ffffffffc0200d02:	1200                	addi	s0,sp,288
ffffffffc0200d04:	14041073          	csrw	sscratch,s0
ffffffffc0200d08:	10049073          	csrw	sstatus,s1
ffffffffc0200d0c:	14191073          	csrw	sepc,s2
ffffffffc0200d10:	60a2                	ld	ra,8(sp)
ffffffffc0200d12:	61e2                	ld	gp,24(sp)
ffffffffc0200d14:	7202                	ld	tp,32(sp)
ffffffffc0200d16:	72a2                	ld	t0,40(sp)
ffffffffc0200d18:	7342                	ld	t1,48(sp)
ffffffffc0200d1a:	73e2                	ld	t2,56(sp)
ffffffffc0200d1c:	6406                	ld	s0,64(sp)
ffffffffc0200d1e:	64a6                	ld	s1,72(sp)
ffffffffc0200d20:	6546                	ld	a0,80(sp)
ffffffffc0200d22:	65e6                	ld	a1,88(sp)
ffffffffc0200d24:	7606                	ld	a2,96(sp)
ffffffffc0200d26:	76a6                	ld	a3,104(sp)
ffffffffc0200d28:	7746                	ld	a4,112(sp)
ffffffffc0200d2a:	77e6                	ld	a5,120(sp)
ffffffffc0200d2c:	680a                	ld	a6,128(sp)
ffffffffc0200d2e:	68aa                	ld	a7,136(sp)
ffffffffc0200d30:	694a                	ld	s2,144(sp)
ffffffffc0200d32:	69ea                	ld	s3,152(sp)
ffffffffc0200d34:	7a0a                	ld	s4,160(sp)
ffffffffc0200d36:	7aaa                	ld	s5,168(sp)
ffffffffc0200d38:	7b4a                	ld	s6,176(sp)
ffffffffc0200d3a:	7bea                	ld	s7,184(sp)
ffffffffc0200d3c:	6c0e                	ld	s8,192(sp)
ffffffffc0200d3e:	6cae                	ld	s9,200(sp)
ffffffffc0200d40:	6d4e                	ld	s10,208(sp)
ffffffffc0200d42:	6dee                	ld	s11,216(sp)
ffffffffc0200d44:	7e0e                	ld	t3,224(sp)
ffffffffc0200d46:	7eae                	ld	t4,232(sp)
ffffffffc0200d48:	7f4e                	ld	t5,240(sp)
ffffffffc0200d4a:	7fee                	ld	t6,248(sp)
ffffffffc0200d4c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200d4e:	10200073          	sret

ffffffffc0200d52 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200d52:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200d54:	b755                	j	ffffffffc0200cf8 <__trapret>

ffffffffc0200d56 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200d56:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cd8>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200d5a:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200d5e:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200d62:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200d66:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200d6a:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200d6e:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200d72:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200d76:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200d7a:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200d7c:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200d7e:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200d80:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200d82:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200d84:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200d86:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200d88:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200d8a:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200d8c:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200d8e:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200d90:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200d92:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200d94:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200d96:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200d98:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200d9a:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200d9c:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200d9e:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200da0:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200da2:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200da4:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200da6:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200da8:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200daa:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200dac:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200dae:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200db0:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200db2:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200db4:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200db6:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200db8:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200dba:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200dbc:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200dbe:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200dc0:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200dc2:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200dc4:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200dc6:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200dc8:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200dca:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200dcc:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200dce:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200dd0:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200dd2:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200dd4:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200dd6:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200dd8:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200dda:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200ddc:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200dde:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200de0:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200de2:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200de4:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200de6:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200de8:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200dea:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200dec:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200dee:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200df0:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200df2:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200df4:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200df6:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200df8:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200dfa:	812e                	mv	sp,a1
ffffffffc0200dfc:	bdf5                	j	ffffffffc0200cf8 <__trapret>

ffffffffc0200dfe <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200dfe:	000ae797          	auipc	a5,0xae
ffffffffc0200e02:	9da78793          	addi	a5,a5,-1574 # ffffffffc02ae7d8 <free_area>
ffffffffc0200e06:	e79c                	sd	a5,8(a5)
ffffffffc0200e08:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200e0a:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200e0e:	8082                	ret

ffffffffc0200e10 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200e10:	000ae517          	auipc	a0,0xae
ffffffffc0200e14:	9d856503          	lwu	a0,-1576(a0) # ffffffffc02ae7e8 <free_area+0x10>
ffffffffc0200e18:	8082                	ret

ffffffffc0200e1a <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200e1a:	715d                	addi	sp,sp,-80
ffffffffc0200e1c:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200e1e:	000ae417          	auipc	s0,0xae
ffffffffc0200e22:	9ba40413          	addi	s0,s0,-1606 # ffffffffc02ae7d8 <free_area>
ffffffffc0200e26:	641c                	ld	a5,8(s0)
ffffffffc0200e28:	e486                	sd	ra,72(sp)
ffffffffc0200e2a:	fc26                	sd	s1,56(sp)
ffffffffc0200e2c:	f84a                	sd	s2,48(sp)
ffffffffc0200e2e:	f44e                	sd	s3,40(sp)
ffffffffc0200e30:	f052                	sd	s4,32(sp)
ffffffffc0200e32:	ec56                	sd	s5,24(sp)
ffffffffc0200e34:	e85a                	sd	s6,16(sp)
ffffffffc0200e36:	e45e                	sd	s7,8(sp)
ffffffffc0200e38:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e3a:	2a878d63          	beq	a5,s0,ffffffffc02010f4 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200e3e:	4481                	li	s1,0
ffffffffc0200e40:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200e42:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200e46:	8b09                	andi	a4,a4,2
ffffffffc0200e48:	2a070a63          	beqz	a4,ffffffffc02010fc <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc0200e4c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e50:	679c                	ld	a5,8(a5)
ffffffffc0200e52:	2905                	addiw	s2,s2,1
ffffffffc0200e54:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e56:	fe8796e3          	bne	a5,s0,ffffffffc0200e42 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200e5a:	89a6                	mv	s3,s1
ffffffffc0200e5c:	733000ef          	jal	ra,ffffffffc0201d8e <nr_free_pages>
ffffffffc0200e60:	6f351e63          	bne	a0,s3,ffffffffc020155c <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e64:	4505                	li	a0,1
ffffffffc0200e66:	657000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0200e6a:	8aaa                	mv	s5,a0
ffffffffc0200e6c:	42050863          	beqz	a0,ffffffffc020129c <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e70:	4505                	li	a0,1
ffffffffc0200e72:	64b000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0200e76:	89aa                	mv	s3,a0
ffffffffc0200e78:	70050263          	beqz	a0,ffffffffc020157c <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e7c:	4505                	li	a0,1
ffffffffc0200e7e:	63f000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0200e82:	8a2a                	mv	s4,a0
ffffffffc0200e84:	48050c63          	beqz	a0,ffffffffc020131c <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e88:	293a8a63          	beq	s5,s3,ffffffffc020111c <default_check+0x302>
ffffffffc0200e8c:	28aa8863          	beq	s5,a0,ffffffffc020111c <default_check+0x302>
ffffffffc0200e90:	28a98663          	beq	s3,a0,ffffffffc020111c <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200e94:	000aa783          	lw	a5,0(s5)
ffffffffc0200e98:	2a079263          	bnez	a5,ffffffffc020113c <default_check+0x322>
ffffffffc0200e9c:	0009a783          	lw	a5,0(s3)
ffffffffc0200ea0:	28079e63          	bnez	a5,ffffffffc020113c <default_check+0x322>
ffffffffc0200ea4:	411c                	lw	a5,0(a0)
ffffffffc0200ea6:	28079b63          	bnez	a5,ffffffffc020113c <default_check+0x322>
extern size_t npage;
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page) {
    return page - pages + nbase;
ffffffffc0200eaa:	000b2797          	auipc	a5,0xb2
ffffffffc0200eae:	a2e7b783          	ld	a5,-1490(a5) # ffffffffc02b28d8 <pages>
ffffffffc0200eb2:	40fa8733          	sub	a4,s5,a5
ffffffffc0200eb6:	00008617          	auipc	a2,0x8
ffffffffc0200eba:	c4a63603          	ld	a2,-950(a2) # ffffffffc0208b00 <nbase>
ffffffffc0200ebe:	8719                	srai	a4,a4,0x6
ffffffffc0200ec0:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200ec2:	000b2697          	auipc	a3,0xb2
ffffffffc0200ec6:	a0e6b683          	ld	a3,-1522(a3) # ffffffffc02b28d0 <npage>
ffffffffc0200eca:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ecc:	0732                	slli	a4,a4,0xc
ffffffffc0200ece:	28d77763          	bgeu	a4,a3,ffffffffc020115c <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200ed2:	40f98733          	sub	a4,s3,a5
ffffffffc0200ed6:	8719                	srai	a4,a4,0x6
ffffffffc0200ed8:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200eda:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200edc:	4cd77063          	bgeu	a4,a3,ffffffffc020139c <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200ee0:	40f507b3          	sub	a5,a0,a5
ffffffffc0200ee4:	8799                	srai	a5,a5,0x6
ffffffffc0200ee6:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ee8:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200eea:	30d7f963          	bgeu	a5,a3,ffffffffc02011fc <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200eee:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200ef0:	00043c03          	ld	s8,0(s0)
ffffffffc0200ef4:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200ef8:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200efc:	e400                	sd	s0,8(s0)
ffffffffc0200efe:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200f00:	000ae797          	auipc	a5,0xae
ffffffffc0200f04:	8e07a423          	sw	zero,-1816(a5) # ffffffffc02ae7e8 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200f08:	5b5000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0200f0c:	2c051863          	bnez	a0,ffffffffc02011dc <default_check+0x3c2>
    free_page(p0);
ffffffffc0200f10:	4585                	li	a1,1
ffffffffc0200f12:	8556                	mv	a0,s5
ffffffffc0200f14:	63b000ef          	jal	ra,ffffffffc0201d4e <free_pages>
    free_page(p1);
ffffffffc0200f18:	4585                	li	a1,1
ffffffffc0200f1a:	854e                	mv	a0,s3
ffffffffc0200f1c:	633000ef          	jal	ra,ffffffffc0201d4e <free_pages>
    free_page(p2);
ffffffffc0200f20:	4585                	li	a1,1
ffffffffc0200f22:	8552                	mv	a0,s4
ffffffffc0200f24:	62b000ef          	jal	ra,ffffffffc0201d4e <free_pages>
    assert(nr_free == 3);
ffffffffc0200f28:	4818                	lw	a4,16(s0)
ffffffffc0200f2a:	478d                	li	a5,3
ffffffffc0200f2c:	28f71863          	bne	a4,a5,ffffffffc02011bc <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f30:	4505                	li	a0,1
ffffffffc0200f32:	58b000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0200f36:	89aa                	mv	s3,a0
ffffffffc0200f38:	26050263          	beqz	a0,ffffffffc020119c <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f3c:	4505                	li	a0,1
ffffffffc0200f3e:	57f000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0200f42:	8aaa                	mv	s5,a0
ffffffffc0200f44:	3a050c63          	beqz	a0,ffffffffc02012fc <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f48:	4505                	li	a0,1
ffffffffc0200f4a:	573000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0200f4e:	8a2a                	mv	s4,a0
ffffffffc0200f50:	38050663          	beqz	a0,ffffffffc02012dc <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0200f54:	4505                	li	a0,1
ffffffffc0200f56:	567000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0200f5a:	36051163          	bnez	a0,ffffffffc02012bc <default_check+0x4a2>
    free_page(p0);
ffffffffc0200f5e:	4585                	li	a1,1
ffffffffc0200f60:	854e                	mv	a0,s3
ffffffffc0200f62:	5ed000ef          	jal	ra,ffffffffc0201d4e <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200f66:	641c                	ld	a5,8(s0)
ffffffffc0200f68:	20878a63          	beq	a5,s0,ffffffffc020117c <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0200f6c:	4505                	li	a0,1
ffffffffc0200f6e:	54f000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0200f72:	30a99563          	bne	s3,a0,ffffffffc020127c <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0200f76:	4505                	li	a0,1
ffffffffc0200f78:	545000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0200f7c:	2e051063          	bnez	a0,ffffffffc020125c <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0200f80:	481c                	lw	a5,16(s0)
ffffffffc0200f82:	2a079d63          	bnez	a5,ffffffffc020123c <default_check+0x422>
    free_page(p);
ffffffffc0200f86:	854e                	mv	a0,s3
ffffffffc0200f88:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200f8a:	01843023          	sd	s8,0(s0)
ffffffffc0200f8e:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200f92:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200f96:	5b9000ef          	jal	ra,ffffffffc0201d4e <free_pages>
    free_page(p1);
ffffffffc0200f9a:	4585                	li	a1,1
ffffffffc0200f9c:	8556                	mv	a0,s5
ffffffffc0200f9e:	5b1000ef          	jal	ra,ffffffffc0201d4e <free_pages>
    free_page(p2);
ffffffffc0200fa2:	4585                	li	a1,1
ffffffffc0200fa4:	8552                	mv	a0,s4
ffffffffc0200fa6:	5a9000ef          	jal	ra,ffffffffc0201d4e <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200faa:	4515                	li	a0,5
ffffffffc0200fac:	511000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0200fb0:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200fb2:	26050563          	beqz	a0,ffffffffc020121c <default_check+0x402>
ffffffffc0200fb6:	651c                	ld	a5,8(a0)
ffffffffc0200fb8:	8385                	srli	a5,a5,0x1
ffffffffc0200fba:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0200fbc:	54079063          	bnez	a5,ffffffffc02014fc <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200fc0:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200fc2:	00043b03          	ld	s6,0(s0)
ffffffffc0200fc6:	00843a83          	ld	s5,8(s0)
ffffffffc0200fca:	e000                	sd	s0,0(s0)
ffffffffc0200fcc:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200fce:	4ef000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0200fd2:	50051563          	bnez	a0,ffffffffc02014dc <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200fd6:	08098a13          	addi	s4,s3,128
ffffffffc0200fda:	8552                	mv	a0,s4
ffffffffc0200fdc:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200fde:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200fe2:	000ae797          	auipc	a5,0xae
ffffffffc0200fe6:	8007a323          	sw	zero,-2042(a5) # ffffffffc02ae7e8 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200fea:	565000ef          	jal	ra,ffffffffc0201d4e <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200fee:	4511                	li	a0,4
ffffffffc0200ff0:	4cd000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0200ff4:	4c051463          	bnez	a0,ffffffffc02014bc <default_check+0x6a2>
ffffffffc0200ff8:	0889b783          	ld	a5,136(s3)
ffffffffc0200ffc:	8385                	srli	a5,a5,0x1
ffffffffc0200ffe:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201000:	48078e63          	beqz	a5,ffffffffc020149c <default_check+0x682>
ffffffffc0201004:	0909a703          	lw	a4,144(s3)
ffffffffc0201008:	478d                	li	a5,3
ffffffffc020100a:	48f71963          	bne	a4,a5,ffffffffc020149c <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020100e:	450d                	li	a0,3
ffffffffc0201010:	4ad000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0201014:	8c2a                	mv	s8,a0
ffffffffc0201016:	46050363          	beqz	a0,ffffffffc020147c <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc020101a:	4505                	li	a0,1
ffffffffc020101c:	4a1000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0201020:	42051e63          	bnez	a0,ffffffffc020145c <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0201024:	418a1c63          	bne	s4,s8,ffffffffc020143c <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201028:	4585                	li	a1,1
ffffffffc020102a:	854e                	mv	a0,s3
ffffffffc020102c:	523000ef          	jal	ra,ffffffffc0201d4e <free_pages>
    free_pages(p1, 3);
ffffffffc0201030:	458d                	li	a1,3
ffffffffc0201032:	8552                	mv	a0,s4
ffffffffc0201034:	51b000ef          	jal	ra,ffffffffc0201d4e <free_pages>
ffffffffc0201038:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc020103c:	04098c13          	addi	s8,s3,64
ffffffffc0201040:	8385                	srli	a5,a5,0x1
ffffffffc0201042:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201044:	3c078c63          	beqz	a5,ffffffffc020141c <default_check+0x602>
ffffffffc0201048:	0109a703          	lw	a4,16(s3)
ffffffffc020104c:	4785                	li	a5,1
ffffffffc020104e:	3cf71763          	bne	a4,a5,ffffffffc020141c <default_check+0x602>
ffffffffc0201052:	008a3783          	ld	a5,8(s4)
ffffffffc0201056:	8385                	srli	a5,a5,0x1
ffffffffc0201058:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020105a:	3a078163          	beqz	a5,ffffffffc02013fc <default_check+0x5e2>
ffffffffc020105e:	010a2703          	lw	a4,16(s4)
ffffffffc0201062:	478d                	li	a5,3
ffffffffc0201064:	38f71c63          	bne	a4,a5,ffffffffc02013fc <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201068:	4505                	li	a0,1
ffffffffc020106a:	453000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc020106e:	36a99763          	bne	s3,a0,ffffffffc02013dc <default_check+0x5c2>
    free_page(p0);
ffffffffc0201072:	4585                	li	a1,1
ffffffffc0201074:	4db000ef          	jal	ra,ffffffffc0201d4e <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201078:	4509                	li	a0,2
ffffffffc020107a:	443000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc020107e:	32aa1f63          	bne	s4,a0,ffffffffc02013bc <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0201082:	4589                	li	a1,2
ffffffffc0201084:	4cb000ef          	jal	ra,ffffffffc0201d4e <free_pages>
    free_page(p2);
ffffffffc0201088:	4585                	li	a1,1
ffffffffc020108a:	8562                	mv	a0,s8
ffffffffc020108c:	4c3000ef          	jal	ra,ffffffffc0201d4e <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201090:	4515                	li	a0,5
ffffffffc0201092:	42b000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0201096:	89aa                	mv	s3,a0
ffffffffc0201098:	48050263          	beqz	a0,ffffffffc020151c <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc020109c:	4505                	li	a0,1
ffffffffc020109e:	41f000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc02010a2:	2c051d63          	bnez	a0,ffffffffc020137c <default_check+0x562>

    assert(nr_free == 0);
ffffffffc02010a6:	481c                	lw	a5,16(s0)
ffffffffc02010a8:	2a079a63          	bnez	a5,ffffffffc020135c <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02010ac:	4595                	li	a1,5
ffffffffc02010ae:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02010b0:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc02010b4:	01643023          	sd	s6,0(s0)
ffffffffc02010b8:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc02010bc:	493000ef          	jal	ra,ffffffffc0201d4e <free_pages>
    return listelm->next;
ffffffffc02010c0:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010c2:	00878963          	beq	a5,s0,ffffffffc02010d4 <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc02010c6:	ff87a703          	lw	a4,-8(a5)
ffffffffc02010ca:	679c                	ld	a5,8(a5)
ffffffffc02010cc:	397d                	addiw	s2,s2,-1
ffffffffc02010ce:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010d0:	fe879be3          	bne	a5,s0,ffffffffc02010c6 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02010d4:	26091463          	bnez	s2,ffffffffc020133c <default_check+0x522>
    assert(total == 0);
ffffffffc02010d8:	46049263          	bnez	s1,ffffffffc020153c <default_check+0x722>
}
ffffffffc02010dc:	60a6                	ld	ra,72(sp)
ffffffffc02010de:	6406                	ld	s0,64(sp)
ffffffffc02010e0:	74e2                	ld	s1,56(sp)
ffffffffc02010e2:	7942                	ld	s2,48(sp)
ffffffffc02010e4:	79a2                	ld	s3,40(sp)
ffffffffc02010e6:	7a02                	ld	s4,32(sp)
ffffffffc02010e8:	6ae2                	ld	s5,24(sp)
ffffffffc02010ea:	6b42                	ld	s6,16(sp)
ffffffffc02010ec:	6ba2                	ld	s7,8(sp)
ffffffffc02010ee:	6c02                	ld	s8,0(sp)
ffffffffc02010f0:	6161                	addi	sp,sp,80
ffffffffc02010f2:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010f4:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02010f6:	4481                	li	s1,0
ffffffffc02010f8:	4901                	li	s2,0
ffffffffc02010fa:	b38d                	j	ffffffffc0200e5c <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02010fc:	00006697          	auipc	a3,0x6
ffffffffc0201100:	d2c68693          	addi	a3,a3,-724 # ffffffffc0206e28 <commands+0x740>
ffffffffc0201104:	00006617          	auipc	a2,0x6
ffffffffc0201108:	a3460613          	addi	a2,a2,-1484 # ffffffffc0206b38 <commands+0x450>
ffffffffc020110c:	0f000593          	li	a1,240
ffffffffc0201110:	00006517          	auipc	a0,0x6
ffffffffc0201114:	d2850513          	addi	a0,a0,-728 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201118:	b62ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020111c:	00006697          	auipc	a3,0x6
ffffffffc0201120:	db468693          	addi	a3,a3,-588 # ffffffffc0206ed0 <commands+0x7e8>
ffffffffc0201124:	00006617          	auipc	a2,0x6
ffffffffc0201128:	a1460613          	addi	a2,a2,-1516 # ffffffffc0206b38 <commands+0x450>
ffffffffc020112c:	0bd00593          	li	a1,189
ffffffffc0201130:	00006517          	auipc	a0,0x6
ffffffffc0201134:	d0850513          	addi	a0,a0,-760 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201138:	b42ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020113c:	00006697          	auipc	a3,0x6
ffffffffc0201140:	dbc68693          	addi	a3,a3,-580 # ffffffffc0206ef8 <commands+0x810>
ffffffffc0201144:	00006617          	auipc	a2,0x6
ffffffffc0201148:	9f460613          	addi	a2,a2,-1548 # ffffffffc0206b38 <commands+0x450>
ffffffffc020114c:	0be00593          	li	a1,190
ffffffffc0201150:	00006517          	auipc	a0,0x6
ffffffffc0201154:	ce850513          	addi	a0,a0,-792 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201158:	b22ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020115c:	00006697          	auipc	a3,0x6
ffffffffc0201160:	ddc68693          	addi	a3,a3,-548 # ffffffffc0206f38 <commands+0x850>
ffffffffc0201164:	00006617          	auipc	a2,0x6
ffffffffc0201168:	9d460613          	addi	a2,a2,-1580 # ffffffffc0206b38 <commands+0x450>
ffffffffc020116c:	0c000593          	li	a1,192
ffffffffc0201170:	00006517          	auipc	a0,0x6
ffffffffc0201174:	cc850513          	addi	a0,a0,-824 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201178:	b02ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(!list_empty(&free_list));
ffffffffc020117c:	00006697          	auipc	a3,0x6
ffffffffc0201180:	e4468693          	addi	a3,a3,-444 # ffffffffc0206fc0 <commands+0x8d8>
ffffffffc0201184:	00006617          	auipc	a2,0x6
ffffffffc0201188:	9b460613          	addi	a2,a2,-1612 # ffffffffc0206b38 <commands+0x450>
ffffffffc020118c:	0d900593          	li	a1,217
ffffffffc0201190:	00006517          	auipc	a0,0x6
ffffffffc0201194:	ca850513          	addi	a0,a0,-856 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201198:	ae2ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020119c:	00006697          	auipc	a3,0x6
ffffffffc02011a0:	cd468693          	addi	a3,a3,-812 # ffffffffc0206e70 <commands+0x788>
ffffffffc02011a4:	00006617          	auipc	a2,0x6
ffffffffc02011a8:	99460613          	addi	a2,a2,-1644 # ffffffffc0206b38 <commands+0x450>
ffffffffc02011ac:	0d200593          	li	a1,210
ffffffffc02011b0:	00006517          	auipc	a0,0x6
ffffffffc02011b4:	c8850513          	addi	a0,a0,-888 # ffffffffc0206e38 <commands+0x750>
ffffffffc02011b8:	ac2ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_free == 3);
ffffffffc02011bc:	00006697          	auipc	a3,0x6
ffffffffc02011c0:	df468693          	addi	a3,a3,-524 # ffffffffc0206fb0 <commands+0x8c8>
ffffffffc02011c4:	00006617          	auipc	a2,0x6
ffffffffc02011c8:	97460613          	addi	a2,a2,-1676 # ffffffffc0206b38 <commands+0x450>
ffffffffc02011cc:	0d000593          	li	a1,208
ffffffffc02011d0:	00006517          	auipc	a0,0x6
ffffffffc02011d4:	c6850513          	addi	a0,a0,-920 # ffffffffc0206e38 <commands+0x750>
ffffffffc02011d8:	aa2ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011dc:	00006697          	auipc	a3,0x6
ffffffffc02011e0:	dbc68693          	addi	a3,a3,-580 # ffffffffc0206f98 <commands+0x8b0>
ffffffffc02011e4:	00006617          	auipc	a2,0x6
ffffffffc02011e8:	95460613          	addi	a2,a2,-1708 # ffffffffc0206b38 <commands+0x450>
ffffffffc02011ec:	0cb00593          	li	a1,203
ffffffffc02011f0:	00006517          	auipc	a0,0x6
ffffffffc02011f4:	c4850513          	addi	a0,a0,-952 # ffffffffc0206e38 <commands+0x750>
ffffffffc02011f8:	a82ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02011fc:	00006697          	auipc	a3,0x6
ffffffffc0201200:	d7c68693          	addi	a3,a3,-644 # ffffffffc0206f78 <commands+0x890>
ffffffffc0201204:	00006617          	auipc	a2,0x6
ffffffffc0201208:	93460613          	addi	a2,a2,-1740 # ffffffffc0206b38 <commands+0x450>
ffffffffc020120c:	0c200593          	li	a1,194
ffffffffc0201210:	00006517          	auipc	a0,0x6
ffffffffc0201214:	c2850513          	addi	a0,a0,-984 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201218:	a62ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(p0 != NULL);
ffffffffc020121c:	00006697          	auipc	a3,0x6
ffffffffc0201220:	dec68693          	addi	a3,a3,-532 # ffffffffc0207008 <commands+0x920>
ffffffffc0201224:	00006617          	auipc	a2,0x6
ffffffffc0201228:	91460613          	addi	a2,a2,-1772 # ffffffffc0206b38 <commands+0x450>
ffffffffc020122c:	0f800593          	li	a1,248
ffffffffc0201230:	00006517          	auipc	a0,0x6
ffffffffc0201234:	c0850513          	addi	a0,a0,-1016 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201238:	a42ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_free == 0);
ffffffffc020123c:	00006697          	auipc	a3,0x6
ffffffffc0201240:	dbc68693          	addi	a3,a3,-580 # ffffffffc0206ff8 <commands+0x910>
ffffffffc0201244:	00006617          	auipc	a2,0x6
ffffffffc0201248:	8f460613          	addi	a2,a2,-1804 # ffffffffc0206b38 <commands+0x450>
ffffffffc020124c:	0df00593          	li	a1,223
ffffffffc0201250:	00006517          	auipc	a0,0x6
ffffffffc0201254:	be850513          	addi	a0,a0,-1048 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201258:	a22ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_page() == NULL);
ffffffffc020125c:	00006697          	auipc	a3,0x6
ffffffffc0201260:	d3c68693          	addi	a3,a3,-708 # ffffffffc0206f98 <commands+0x8b0>
ffffffffc0201264:	00006617          	auipc	a2,0x6
ffffffffc0201268:	8d460613          	addi	a2,a2,-1836 # ffffffffc0206b38 <commands+0x450>
ffffffffc020126c:	0dd00593          	li	a1,221
ffffffffc0201270:	00006517          	auipc	a0,0x6
ffffffffc0201274:	bc850513          	addi	a0,a0,-1080 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201278:	a02ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020127c:	00006697          	auipc	a3,0x6
ffffffffc0201280:	d5c68693          	addi	a3,a3,-676 # ffffffffc0206fd8 <commands+0x8f0>
ffffffffc0201284:	00006617          	auipc	a2,0x6
ffffffffc0201288:	8b460613          	addi	a2,a2,-1868 # ffffffffc0206b38 <commands+0x450>
ffffffffc020128c:	0dc00593          	li	a1,220
ffffffffc0201290:	00006517          	auipc	a0,0x6
ffffffffc0201294:	ba850513          	addi	a0,a0,-1112 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201298:	9e2ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020129c:	00006697          	auipc	a3,0x6
ffffffffc02012a0:	bd468693          	addi	a3,a3,-1068 # ffffffffc0206e70 <commands+0x788>
ffffffffc02012a4:	00006617          	auipc	a2,0x6
ffffffffc02012a8:	89460613          	addi	a2,a2,-1900 # ffffffffc0206b38 <commands+0x450>
ffffffffc02012ac:	0b900593          	li	a1,185
ffffffffc02012b0:	00006517          	auipc	a0,0x6
ffffffffc02012b4:	b8850513          	addi	a0,a0,-1144 # ffffffffc0206e38 <commands+0x750>
ffffffffc02012b8:	9c2ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012bc:	00006697          	auipc	a3,0x6
ffffffffc02012c0:	cdc68693          	addi	a3,a3,-804 # ffffffffc0206f98 <commands+0x8b0>
ffffffffc02012c4:	00006617          	auipc	a2,0x6
ffffffffc02012c8:	87460613          	addi	a2,a2,-1932 # ffffffffc0206b38 <commands+0x450>
ffffffffc02012cc:	0d600593          	li	a1,214
ffffffffc02012d0:	00006517          	auipc	a0,0x6
ffffffffc02012d4:	b6850513          	addi	a0,a0,-1176 # ffffffffc0206e38 <commands+0x750>
ffffffffc02012d8:	9a2ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02012dc:	00006697          	auipc	a3,0x6
ffffffffc02012e0:	bd468693          	addi	a3,a3,-1068 # ffffffffc0206eb0 <commands+0x7c8>
ffffffffc02012e4:	00006617          	auipc	a2,0x6
ffffffffc02012e8:	85460613          	addi	a2,a2,-1964 # ffffffffc0206b38 <commands+0x450>
ffffffffc02012ec:	0d400593          	li	a1,212
ffffffffc02012f0:	00006517          	auipc	a0,0x6
ffffffffc02012f4:	b4850513          	addi	a0,a0,-1208 # ffffffffc0206e38 <commands+0x750>
ffffffffc02012f8:	982ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02012fc:	00006697          	auipc	a3,0x6
ffffffffc0201300:	b9468693          	addi	a3,a3,-1132 # ffffffffc0206e90 <commands+0x7a8>
ffffffffc0201304:	00006617          	auipc	a2,0x6
ffffffffc0201308:	83460613          	addi	a2,a2,-1996 # ffffffffc0206b38 <commands+0x450>
ffffffffc020130c:	0d300593          	li	a1,211
ffffffffc0201310:	00006517          	auipc	a0,0x6
ffffffffc0201314:	b2850513          	addi	a0,a0,-1240 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201318:	962ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020131c:	00006697          	auipc	a3,0x6
ffffffffc0201320:	b9468693          	addi	a3,a3,-1132 # ffffffffc0206eb0 <commands+0x7c8>
ffffffffc0201324:	00006617          	auipc	a2,0x6
ffffffffc0201328:	81460613          	addi	a2,a2,-2028 # ffffffffc0206b38 <commands+0x450>
ffffffffc020132c:	0bb00593          	li	a1,187
ffffffffc0201330:	00006517          	auipc	a0,0x6
ffffffffc0201334:	b0850513          	addi	a0,a0,-1272 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201338:	942ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(count == 0);
ffffffffc020133c:	00006697          	auipc	a3,0x6
ffffffffc0201340:	e1c68693          	addi	a3,a3,-484 # ffffffffc0207158 <commands+0xa70>
ffffffffc0201344:	00005617          	auipc	a2,0x5
ffffffffc0201348:	7f460613          	addi	a2,a2,2036 # ffffffffc0206b38 <commands+0x450>
ffffffffc020134c:	12500593          	li	a1,293
ffffffffc0201350:	00006517          	auipc	a0,0x6
ffffffffc0201354:	ae850513          	addi	a0,a0,-1304 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201358:	922ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_free == 0);
ffffffffc020135c:	00006697          	auipc	a3,0x6
ffffffffc0201360:	c9c68693          	addi	a3,a3,-868 # ffffffffc0206ff8 <commands+0x910>
ffffffffc0201364:	00005617          	auipc	a2,0x5
ffffffffc0201368:	7d460613          	addi	a2,a2,2004 # ffffffffc0206b38 <commands+0x450>
ffffffffc020136c:	11a00593          	li	a1,282
ffffffffc0201370:	00006517          	auipc	a0,0x6
ffffffffc0201374:	ac850513          	addi	a0,a0,-1336 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201378:	902ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_page() == NULL);
ffffffffc020137c:	00006697          	auipc	a3,0x6
ffffffffc0201380:	c1c68693          	addi	a3,a3,-996 # ffffffffc0206f98 <commands+0x8b0>
ffffffffc0201384:	00005617          	auipc	a2,0x5
ffffffffc0201388:	7b460613          	addi	a2,a2,1972 # ffffffffc0206b38 <commands+0x450>
ffffffffc020138c:	11800593          	li	a1,280
ffffffffc0201390:	00006517          	auipc	a0,0x6
ffffffffc0201394:	aa850513          	addi	a0,a0,-1368 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201398:	8e2ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020139c:	00006697          	auipc	a3,0x6
ffffffffc02013a0:	bbc68693          	addi	a3,a3,-1092 # ffffffffc0206f58 <commands+0x870>
ffffffffc02013a4:	00005617          	auipc	a2,0x5
ffffffffc02013a8:	79460613          	addi	a2,a2,1940 # ffffffffc0206b38 <commands+0x450>
ffffffffc02013ac:	0c100593          	li	a1,193
ffffffffc02013b0:	00006517          	auipc	a0,0x6
ffffffffc02013b4:	a8850513          	addi	a0,a0,-1400 # ffffffffc0206e38 <commands+0x750>
ffffffffc02013b8:	8c2ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02013bc:	00006697          	auipc	a3,0x6
ffffffffc02013c0:	d5c68693          	addi	a3,a3,-676 # ffffffffc0207118 <commands+0xa30>
ffffffffc02013c4:	00005617          	auipc	a2,0x5
ffffffffc02013c8:	77460613          	addi	a2,a2,1908 # ffffffffc0206b38 <commands+0x450>
ffffffffc02013cc:	11200593          	li	a1,274
ffffffffc02013d0:	00006517          	auipc	a0,0x6
ffffffffc02013d4:	a6850513          	addi	a0,a0,-1432 # ffffffffc0206e38 <commands+0x750>
ffffffffc02013d8:	8a2ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02013dc:	00006697          	auipc	a3,0x6
ffffffffc02013e0:	d1c68693          	addi	a3,a3,-740 # ffffffffc02070f8 <commands+0xa10>
ffffffffc02013e4:	00005617          	auipc	a2,0x5
ffffffffc02013e8:	75460613          	addi	a2,a2,1876 # ffffffffc0206b38 <commands+0x450>
ffffffffc02013ec:	11000593          	li	a1,272
ffffffffc02013f0:	00006517          	auipc	a0,0x6
ffffffffc02013f4:	a4850513          	addi	a0,a0,-1464 # ffffffffc0206e38 <commands+0x750>
ffffffffc02013f8:	882ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02013fc:	00006697          	auipc	a3,0x6
ffffffffc0201400:	cd468693          	addi	a3,a3,-812 # ffffffffc02070d0 <commands+0x9e8>
ffffffffc0201404:	00005617          	auipc	a2,0x5
ffffffffc0201408:	73460613          	addi	a2,a2,1844 # ffffffffc0206b38 <commands+0x450>
ffffffffc020140c:	10e00593          	li	a1,270
ffffffffc0201410:	00006517          	auipc	a0,0x6
ffffffffc0201414:	a2850513          	addi	a0,a0,-1496 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201418:	862ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020141c:	00006697          	auipc	a3,0x6
ffffffffc0201420:	c8c68693          	addi	a3,a3,-884 # ffffffffc02070a8 <commands+0x9c0>
ffffffffc0201424:	00005617          	auipc	a2,0x5
ffffffffc0201428:	71460613          	addi	a2,a2,1812 # ffffffffc0206b38 <commands+0x450>
ffffffffc020142c:	10d00593          	li	a1,269
ffffffffc0201430:	00006517          	auipc	a0,0x6
ffffffffc0201434:	a0850513          	addi	a0,a0,-1528 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201438:	842ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(p0 + 2 == p1);
ffffffffc020143c:	00006697          	auipc	a3,0x6
ffffffffc0201440:	c5c68693          	addi	a3,a3,-932 # ffffffffc0207098 <commands+0x9b0>
ffffffffc0201444:	00005617          	auipc	a2,0x5
ffffffffc0201448:	6f460613          	addi	a2,a2,1780 # ffffffffc0206b38 <commands+0x450>
ffffffffc020144c:	10800593          	li	a1,264
ffffffffc0201450:	00006517          	auipc	a0,0x6
ffffffffc0201454:	9e850513          	addi	a0,a0,-1560 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201458:	822ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_page() == NULL);
ffffffffc020145c:	00006697          	auipc	a3,0x6
ffffffffc0201460:	b3c68693          	addi	a3,a3,-1220 # ffffffffc0206f98 <commands+0x8b0>
ffffffffc0201464:	00005617          	auipc	a2,0x5
ffffffffc0201468:	6d460613          	addi	a2,a2,1748 # ffffffffc0206b38 <commands+0x450>
ffffffffc020146c:	10700593          	li	a1,263
ffffffffc0201470:	00006517          	auipc	a0,0x6
ffffffffc0201474:	9c850513          	addi	a0,a0,-1592 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201478:	802ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020147c:	00006697          	auipc	a3,0x6
ffffffffc0201480:	bfc68693          	addi	a3,a3,-1028 # ffffffffc0207078 <commands+0x990>
ffffffffc0201484:	00005617          	auipc	a2,0x5
ffffffffc0201488:	6b460613          	addi	a2,a2,1716 # ffffffffc0206b38 <commands+0x450>
ffffffffc020148c:	10600593          	li	a1,262
ffffffffc0201490:	00006517          	auipc	a0,0x6
ffffffffc0201494:	9a850513          	addi	a0,a0,-1624 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201498:	fe3fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020149c:	00006697          	auipc	a3,0x6
ffffffffc02014a0:	bac68693          	addi	a3,a3,-1108 # ffffffffc0207048 <commands+0x960>
ffffffffc02014a4:	00005617          	auipc	a2,0x5
ffffffffc02014a8:	69460613          	addi	a2,a2,1684 # ffffffffc0206b38 <commands+0x450>
ffffffffc02014ac:	10500593          	li	a1,261
ffffffffc02014b0:	00006517          	auipc	a0,0x6
ffffffffc02014b4:	98850513          	addi	a0,a0,-1656 # ffffffffc0206e38 <commands+0x750>
ffffffffc02014b8:	fc3fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02014bc:	00006697          	auipc	a3,0x6
ffffffffc02014c0:	b7468693          	addi	a3,a3,-1164 # ffffffffc0207030 <commands+0x948>
ffffffffc02014c4:	00005617          	auipc	a2,0x5
ffffffffc02014c8:	67460613          	addi	a2,a2,1652 # ffffffffc0206b38 <commands+0x450>
ffffffffc02014cc:	10400593          	li	a1,260
ffffffffc02014d0:	00006517          	auipc	a0,0x6
ffffffffc02014d4:	96850513          	addi	a0,a0,-1688 # ffffffffc0206e38 <commands+0x750>
ffffffffc02014d8:	fa3fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014dc:	00006697          	auipc	a3,0x6
ffffffffc02014e0:	abc68693          	addi	a3,a3,-1348 # ffffffffc0206f98 <commands+0x8b0>
ffffffffc02014e4:	00005617          	auipc	a2,0x5
ffffffffc02014e8:	65460613          	addi	a2,a2,1620 # ffffffffc0206b38 <commands+0x450>
ffffffffc02014ec:	0fe00593          	li	a1,254
ffffffffc02014f0:	00006517          	auipc	a0,0x6
ffffffffc02014f4:	94850513          	addi	a0,a0,-1720 # ffffffffc0206e38 <commands+0x750>
ffffffffc02014f8:	f83fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(!PageProperty(p0));
ffffffffc02014fc:	00006697          	auipc	a3,0x6
ffffffffc0201500:	b1c68693          	addi	a3,a3,-1252 # ffffffffc0207018 <commands+0x930>
ffffffffc0201504:	00005617          	auipc	a2,0x5
ffffffffc0201508:	63460613          	addi	a2,a2,1588 # ffffffffc0206b38 <commands+0x450>
ffffffffc020150c:	0f900593          	li	a1,249
ffffffffc0201510:	00006517          	auipc	a0,0x6
ffffffffc0201514:	92850513          	addi	a0,a0,-1752 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201518:	f63fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020151c:	00006697          	auipc	a3,0x6
ffffffffc0201520:	c1c68693          	addi	a3,a3,-996 # ffffffffc0207138 <commands+0xa50>
ffffffffc0201524:	00005617          	auipc	a2,0x5
ffffffffc0201528:	61460613          	addi	a2,a2,1556 # ffffffffc0206b38 <commands+0x450>
ffffffffc020152c:	11700593          	li	a1,279
ffffffffc0201530:	00006517          	auipc	a0,0x6
ffffffffc0201534:	90850513          	addi	a0,a0,-1784 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201538:	f43fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(total == 0);
ffffffffc020153c:	00006697          	auipc	a3,0x6
ffffffffc0201540:	c2c68693          	addi	a3,a3,-980 # ffffffffc0207168 <commands+0xa80>
ffffffffc0201544:	00005617          	auipc	a2,0x5
ffffffffc0201548:	5f460613          	addi	a2,a2,1524 # ffffffffc0206b38 <commands+0x450>
ffffffffc020154c:	12600593          	li	a1,294
ffffffffc0201550:	00006517          	auipc	a0,0x6
ffffffffc0201554:	8e850513          	addi	a0,a0,-1816 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201558:	f23fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(total == nr_free_pages());
ffffffffc020155c:	00006697          	auipc	a3,0x6
ffffffffc0201560:	8f468693          	addi	a3,a3,-1804 # ffffffffc0206e50 <commands+0x768>
ffffffffc0201564:	00005617          	auipc	a2,0x5
ffffffffc0201568:	5d460613          	addi	a2,a2,1492 # ffffffffc0206b38 <commands+0x450>
ffffffffc020156c:	0f300593          	li	a1,243
ffffffffc0201570:	00006517          	auipc	a0,0x6
ffffffffc0201574:	8c850513          	addi	a0,a0,-1848 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201578:	f03fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020157c:	00006697          	auipc	a3,0x6
ffffffffc0201580:	91468693          	addi	a3,a3,-1772 # ffffffffc0206e90 <commands+0x7a8>
ffffffffc0201584:	00005617          	auipc	a2,0x5
ffffffffc0201588:	5b460613          	addi	a2,a2,1460 # ffffffffc0206b38 <commands+0x450>
ffffffffc020158c:	0ba00593          	li	a1,186
ffffffffc0201590:	00006517          	auipc	a0,0x6
ffffffffc0201594:	8a850513          	addi	a0,a0,-1880 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201598:	ee3fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc020159c <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc020159c:	1141                	addi	sp,sp,-16
ffffffffc020159e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02015a0:	14058463          	beqz	a1,ffffffffc02016e8 <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc02015a4:	00659693          	slli	a3,a1,0x6
ffffffffc02015a8:	96aa                	add	a3,a3,a0
ffffffffc02015aa:	87aa                	mv	a5,a0
ffffffffc02015ac:	02d50263          	beq	a0,a3,ffffffffc02015d0 <default_free_pages+0x34>
ffffffffc02015b0:	6798                	ld	a4,8(a5)
ffffffffc02015b2:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02015b4:	10071a63          	bnez	a4,ffffffffc02016c8 <default_free_pages+0x12c>
ffffffffc02015b8:	6798                	ld	a4,8(a5)
ffffffffc02015ba:	8b09                	andi	a4,a4,2
ffffffffc02015bc:	10071663          	bnez	a4,ffffffffc02016c8 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc02015c0:	0007b423          	sd	zero,8(a5)
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) {
    page->ref = val;
ffffffffc02015c4:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02015c8:	04078793          	addi	a5,a5,64
ffffffffc02015cc:	fed792e3          	bne	a5,a3,ffffffffc02015b0 <default_free_pages+0x14>
    base->property = n;
ffffffffc02015d0:	2581                	sext.w	a1,a1
ffffffffc02015d2:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02015d4:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015d8:	4789                	li	a5,2
ffffffffc02015da:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02015de:	000ad697          	auipc	a3,0xad
ffffffffc02015e2:	1fa68693          	addi	a3,a3,506 # ffffffffc02ae7d8 <free_area>
ffffffffc02015e6:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02015e8:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02015ea:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02015ee:	9db9                	addw	a1,a1,a4
ffffffffc02015f0:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02015f2:	0ad78463          	beq	a5,a3,ffffffffc020169a <default_free_pages+0xfe>
            struct Page* page = le2page(le, page_link);
ffffffffc02015f6:	fe878713          	addi	a4,a5,-24
ffffffffc02015fa:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02015fe:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201600:	00e56a63          	bltu	a0,a4,ffffffffc0201614 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201604:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201606:	04d70c63          	beq	a4,a3,ffffffffc020165e <default_free_pages+0xc2>
    for (; p != base + n; p ++) {
ffffffffc020160a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020160c:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201610:	fee57ae3          	bgeu	a0,a4,ffffffffc0201604 <default_free_pages+0x68>
ffffffffc0201614:	c199                	beqz	a1,ffffffffc020161a <default_free_pages+0x7e>
ffffffffc0201616:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020161a:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc020161c:	e390                	sd	a2,0(a5)
ffffffffc020161e:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201620:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201622:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201624:	00d70d63          	beq	a4,a3,ffffffffc020163e <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc0201628:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc020162c:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc0201630:	02059813          	slli	a6,a1,0x20
ffffffffc0201634:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201638:	97b2                	add	a5,a5,a2
ffffffffc020163a:	02f50c63          	beq	a0,a5,ffffffffc0201672 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc020163e:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc0201640:	00d78c63          	beq	a5,a3,ffffffffc0201658 <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc0201644:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201646:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc020164a:	02061593          	slli	a1,a2,0x20
ffffffffc020164e:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0201652:	972a                	add	a4,a4,a0
ffffffffc0201654:	04e68a63          	beq	a3,a4,ffffffffc02016a8 <default_free_pages+0x10c>
}
ffffffffc0201658:	60a2                	ld	ra,8(sp)
ffffffffc020165a:	0141                	addi	sp,sp,16
ffffffffc020165c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020165e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201660:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201662:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201664:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201666:	02d70763          	beq	a4,a3,ffffffffc0201694 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc020166a:	8832                	mv	a6,a2
ffffffffc020166c:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020166e:	87ba                	mv	a5,a4
ffffffffc0201670:	bf71                	j	ffffffffc020160c <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201672:	491c                	lw	a5,16(a0)
ffffffffc0201674:	9dbd                	addw	a1,a1,a5
ffffffffc0201676:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020167a:	57f5                	li	a5,-3
ffffffffc020167c:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201680:	01853803          	ld	a6,24(a0)
ffffffffc0201684:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201686:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201688:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc020168c:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020168e:	0105b023          	sd	a6,0(a1)
ffffffffc0201692:	b77d                	j	ffffffffc0201640 <default_free_pages+0xa4>
ffffffffc0201694:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201696:	873e                	mv	a4,a5
ffffffffc0201698:	bf41                	j	ffffffffc0201628 <default_free_pages+0x8c>
}
ffffffffc020169a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020169c:	e390                	sd	a2,0(a5)
ffffffffc020169e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02016a0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016a2:	ed1c                	sd	a5,24(a0)
ffffffffc02016a4:	0141                	addi	sp,sp,16
ffffffffc02016a6:	8082                	ret
            base->property += p->property;
ffffffffc02016a8:	ff87a703          	lw	a4,-8(a5)
ffffffffc02016ac:	ff078693          	addi	a3,a5,-16
ffffffffc02016b0:	9e39                	addw	a2,a2,a4
ffffffffc02016b2:	c910                	sw	a2,16(a0)
ffffffffc02016b4:	5775                	li	a4,-3
ffffffffc02016b6:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02016ba:	6398                	ld	a4,0(a5)
ffffffffc02016bc:	679c                	ld	a5,8(a5)
}
ffffffffc02016be:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02016c0:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02016c2:	e398                	sd	a4,0(a5)
ffffffffc02016c4:	0141                	addi	sp,sp,16
ffffffffc02016c6:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02016c8:	00006697          	auipc	a3,0x6
ffffffffc02016cc:	ab868693          	addi	a3,a3,-1352 # ffffffffc0207180 <commands+0xa98>
ffffffffc02016d0:	00005617          	auipc	a2,0x5
ffffffffc02016d4:	46860613          	addi	a2,a2,1128 # ffffffffc0206b38 <commands+0x450>
ffffffffc02016d8:	08300593          	li	a1,131
ffffffffc02016dc:	00005517          	auipc	a0,0x5
ffffffffc02016e0:	75c50513          	addi	a0,a0,1884 # ffffffffc0206e38 <commands+0x750>
ffffffffc02016e4:	d97fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(n > 0);
ffffffffc02016e8:	00006697          	auipc	a3,0x6
ffffffffc02016ec:	a9068693          	addi	a3,a3,-1392 # ffffffffc0207178 <commands+0xa90>
ffffffffc02016f0:	00005617          	auipc	a2,0x5
ffffffffc02016f4:	44860613          	addi	a2,a2,1096 # ffffffffc0206b38 <commands+0x450>
ffffffffc02016f8:	08000593          	li	a1,128
ffffffffc02016fc:	00005517          	auipc	a0,0x5
ffffffffc0201700:	73c50513          	addi	a0,a0,1852 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201704:	d77fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0201708 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201708:	c941                	beqz	a0,ffffffffc0201798 <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc020170a:	000ad597          	auipc	a1,0xad
ffffffffc020170e:	0ce58593          	addi	a1,a1,206 # ffffffffc02ae7d8 <free_area>
ffffffffc0201712:	0105a803          	lw	a6,16(a1)
ffffffffc0201716:	872a                	mv	a4,a0
ffffffffc0201718:	02081793          	slli	a5,a6,0x20
ffffffffc020171c:	9381                	srli	a5,a5,0x20
ffffffffc020171e:	00a7ee63          	bltu	a5,a0,ffffffffc020173a <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201722:	87ae                	mv	a5,a1
ffffffffc0201724:	a801                	j	ffffffffc0201734 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0201726:	ff87a683          	lw	a3,-8(a5)
ffffffffc020172a:	02069613          	slli	a2,a3,0x20
ffffffffc020172e:	9201                	srli	a2,a2,0x20
ffffffffc0201730:	00e67763          	bgeu	a2,a4,ffffffffc020173e <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201734:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201736:	feb798e3          	bne	a5,a1,ffffffffc0201726 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020173a:	4501                	li	a0,0
}
ffffffffc020173c:	8082                	ret
    return listelm->prev;
ffffffffc020173e:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201742:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201746:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc020174a:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc020174e:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201752:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0201756:	02c77863          	bgeu	a4,a2,ffffffffc0201786 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc020175a:	071a                	slli	a4,a4,0x6
ffffffffc020175c:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc020175e:	41c686bb          	subw	a3,a3,t3
ffffffffc0201762:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201764:	00870613          	addi	a2,a4,8
ffffffffc0201768:	4689                	li	a3,2
ffffffffc020176a:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020176e:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201772:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201776:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc020177a:	e290                	sd	a2,0(a3)
ffffffffc020177c:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201780:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201782:	01173c23          	sd	a7,24(a4)
ffffffffc0201786:	41c8083b          	subw	a6,a6,t3
ffffffffc020178a:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020178e:	5775                	li	a4,-3
ffffffffc0201790:	17c1                	addi	a5,a5,-16
ffffffffc0201792:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201796:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201798:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020179a:	00006697          	auipc	a3,0x6
ffffffffc020179e:	9de68693          	addi	a3,a3,-1570 # ffffffffc0207178 <commands+0xa90>
ffffffffc02017a2:	00005617          	auipc	a2,0x5
ffffffffc02017a6:	39660613          	addi	a2,a2,918 # ffffffffc0206b38 <commands+0x450>
ffffffffc02017aa:	06200593          	li	a1,98
ffffffffc02017ae:	00005517          	auipc	a0,0x5
ffffffffc02017b2:	68a50513          	addi	a0,a0,1674 # ffffffffc0206e38 <commands+0x750>
default_alloc_pages(size_t n) {
ffffffffc02017b6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02017b8:	cc3fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02017bc <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02017bc:	1141                	addi	sp,sp,-16
ffffffffc02017be:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02017c0:	c5f1                	beqz	a1,ffffffffc020188c <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc02017c2:	00659693          	slli	a3,a1,0x6
ffffffffc02017c6:	96aa                	add	a3,a3,a0
ffffffffc02017c8:	87aa                	mv	a5,a0
ffffffffc02017ca:	00d50f63          	beq	a0,a3,ffffffffc02017e8 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02017ce:	6798                	ld	a4,8(a5)
ffffffffc02017d0:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc02017d2:	cf49                	beqz	a4,ffffffffc020186c <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc02017d4:	0007a823          	sw	zero,16(a5)
ffffffffc02017d8:	0007b423          	sd	zero,8(a5)
ffffffffc02017dc:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02017e0:	04078793          	addi	a5,a5,64
ffffffffc02017e4:	fed795e3          	bne	a5,a3,ffffffffc02017ce <default_init_memmap+0x12>
    base->property = n;
ffffffffc02017e8:	2581                	sext.w	a1,a1
ffffffffc02017ea:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017ec:	4789                	li	a5,2
ffffffffc02017ee:	00850713          	addi	a4,a0,8
ffffffffc02017f2:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02017f6:	000ad697          	auipc	a3,0xad
ffffffffc02017fa:	fe268693          	addi	a3,a3,-30 # ffffffffc02ae7d8 <free_area>
ffffffffc02017fe:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201800:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201802:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201806:	9db9                	addw	a1,a1,a4
ffffffffc0201808:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020180a:	04d78a63          	beq	a5,a3,ffffffffc020185e <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc020180e:	fe878713          	addi	a4,a5,-24
ffffffffc0201812:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201816:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201818:	00e56a63          	bltu	a0,a4,ffffffffc020182c <default_init_memmap+0x70>
    return listelm->next;
ffffffffc020181c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020181e:	02d70263          	beq	a4,a3,ffffffffc0201842 <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc0201822:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201824:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201828:	fee57ae3          	bgeu	a0,a4,ffffffffc020181c <default_init_memmap+0x60>
ffffffffc020182c:	c199                	beqz	a1,ffffffffc0201832 <default_init_memmap+0x76>
ffffffffc020182e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201832:	6398                	ld	a4,0(a5)
}
ffffffffc0201834:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201836:	e390                	sd	a2,0(a5)
ffffffffc0201838:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020183a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020183c:	ed18                	sd	a4,24(a0)
ffffffffc020183e:	0141                	addi	sp,sp,16
ffffffffc0201840:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201842:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201844:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201846:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201848:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020184a:	00d70663          	beq	a4,a3,ffffffffc0201856 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc020184e:	8832                	mv	a6,a2
ffffffffc0201850:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201852:	87ba                	mv	a5,a4
ffffffffc0201854:	bfc1                	j	ffffffffc0201824 <default_init_memmap+0x68>
}
ffffffffc0201856:	60a2                	ld	ra,8(sp)
ffffffffc0201858:	e290                	sd	a2,0(a3)
ffffffffc020185a:	0141                	addi	sp,sp,16
ffffffffc020185c:	8082                	ret
ffffffffc020185e:	60a2                	ld	ra,8(sp)
ffffffffc0201860:	e390                	sd	a2,0(a5)
ffffffffc0201862:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201864:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201866:	ed1c                	sd	a5,24(a0)
ffffffffc0201868:	0141                	addi	sp,sp,16
ffffffffc020186a:	8082                	ret
        assert(PageReserved(p));
ffffffffc020186c:	00006697          	auipc	a3,0x6
ffffffffc0201870:	93c68693          	addi	a3,a3,-1732 # ffffffffc02071a8 <commands+0xac0>
ffffffffc0201874:	00005617          	auipc	a2,0x5
ffffffffc0201878:	2c460613          	addi	a2,a2,708 # ffffffffc0206b38 <commands+0x450>
ffffffffc020187c:	04900593          	li	a1,73
ffffffffc0201880:	00005517          	auipc	a0,0x5
ffffffffc0201884:	5b850513          	addi	a0,a0,1464 # ffffffffc0206e38 <commands+0x750>
ffffffffc0201888:	bf3fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(n > 0);
ffffffffc020188c:	00006697          	auipc	a3,0x6
ffffffffc0201890:	8ec68693          	addi	a3,a3,-1812 # ffffffffc0207178 <commands+0xa90>
ffffffffc0201894:	00005617          	auipc	a2,0x5
ffffffffc0201898:	2a460613          	addi	a2,a2,676 # ffffffffc0206b38 <commands+0x450>
ffffffffc020189c:	04600593          	li	a1,70
ffffffffc02018a0:	00005517          	auipc	a0,0x5
ffffffffc02018a4:	59850513          	addi	a0,a0,1432 # ffffffffc0206e38 <commands+0x750>
ffffffffc02018a8:	bd3fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02018ac <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc02018ac:	c94d                	beqz	a0,ffffffffc020195e <slob_free+0xb2>
{
ffffffffc02018ae:	1141                	addi	sp,sp,-16
ffffffffc02018b0:	e022                	sd	s0,0(sp)
ffffffffc02018b2:	e406                	sd	ra,8(sp)
ffffffffc02018b4:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc02018b6:	e9c1                	bnez	a1,ffffffffc0201946 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018b8:	100027f3          	csrr	a5,sstatus
ffffffffc02018bc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02018be:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018c0:	ebd9                	bnez	a5,ffffffffc0201956 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02018c2:	000a6617          	auipc	a2,0xa6
ffffffffc02018c6:	b0660613          	addi	a2,a2,-1274 # ffffffffc02a73c8 <slobfree>
ffffffffc02018ca:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018cc:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02018ce:	679c                	ld	a5,8(a5)
ffffffffc02018d0:	02877a63          	bgeu	a4,s0,ffffffffc0201904 <slob_free+0x58>
ffffffffc02018d4:	00f46463          	bltu	s0,a5,ffffffffc02018dc <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018d8:	fef76ae3          	bltu	a4,a5,ffffffffc02018cc <slob_free+0x20>
			break;

	if (b + b->units == cur->next) {
ffffffffc02018dc:	400c                	lw	a1,0(s0)
ffffffffc02018de:	00459693          	slli	a3,a1,0x4
ffffffffc02018e2:	96a2                	add	a3,a3,s0
ffffffffc02018e4:	02d78a63          	beq	a5,a3,ffffffffc0201918 <slob_free+0x6c>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc02018e8:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc02018ea:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) {
ffffffffc02018ec:	00469793          	slli	a5,a3,0x4
ffffffffc02018f0:	97ba                	add	a5,a5,a4
ffffffffc02018f2:	02f40e63          	beq	s0,a5,ffffffffc020192e <slob_free+0x82>
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;
ffffffffc02018f6:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc02018f8:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc02018fa:	e129                	bnez	a0,ffffffffc020193c <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02018fc:	60a2                	ld	ra,8(sp)
ffffffffc02018fe:	6402                	ld	s0,0(sp)
ffffffffc0201900:	0141                	addi	sp,sp,16
ffffffffc0201902:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201904:	fcf764e3          	bltu	a4,a5,ffffffffc02018cc <slob_free+0x20>
ffffffffc0201908:	fcf472e3          	bgeu	s0,a5,ffffffffc02018cc <slob_free+0x20>
	if (b + b->units == cur->next) {
ffffffffc020190c:	400c                	lw	a1,0(s0)
ffffffffc020190e:	00459693          	slli	a3,a1,0x4
ffffffffc0201912:	96a2                	add	a3,a3,s0
ffffffffc0201914:	fcd79ae3          	bne	a5,a3,ffffffffc02018e8 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201918:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc020191a:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc020191c:	9db5                	addw	a1,a1,a3
ffffffffc020191e:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b) {
ffffffffc0201920:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201922:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) {
ffffffffc0201924:	00469793          	slli	a5,a3,0x4
ffffffffc0201928:	97ba                	add	a5,a5,a4
ffffffffc020192a:	fcf416e3          	bne	s0,a5,ffffffffc02018f6 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc020192e:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201930:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201932:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201934:	9ebd                	addw	a3,a3,a5
ffffffffc0201936:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201938:	e70c                	sd	a1,8(a4)
ffffffffc020193a:	d169                	beqz	a0,ffffffffc02018fc <slob_free+0x50>
}
ffffffffc020193c:	6402                	ld	s0,0(sp)
ffffffffc020193e:	60a2                	ld	ra,8(sp)
ffffffffc0201940:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201942:	cdbfe06f          	j	ffffffffc020061c <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201946:	25bd                	addiw	a1,a1,15
ffffffffc0201948:	8191                	srli	a1,a1,0x4
ffffffffc020194a:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020194c:	100027f3          	csrr	a5,sstatus
ffffffffc0201950:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201952:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201954:	d7bd                	beqz	a5,ffffffffc02018c2 <slob_free+0x16>
        intr_disable();
ffffffffc0201956:	ccdfe0ef          	jal	ra,ffffffffc0200622 <intr_disable>
        return 1;
ffffffffc020195a:	4505                	li	a0,1
ffffffffc020195c:	b79d                	j	ffffffffc02018c2 <slob_free+0x16>
ffffffffc020195e:	8082                	ret

ffffffffc0201960 <__slob_get_free_pages.constprop.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201960:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201962:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201964:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201968:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc020196a:	352000ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
  if(!page)
ffffffffc020196e:	c91d                	beqz	a0,ffffffffc02019a4 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201970:	000b1697          	auipc	a3,0xb1
ffffffffc0201974:	f686b683          	ld	a3,-152(a3) # ffffffffc02b28d8 <pages>
ffffffffc0201978:	8d15                	sub	a0,a0,a3
ffffffffc020197a:	8519                	srai	a0,a0,0x6
ffffffffc020197c:	00007697          	auipc	a3,0x7
ffffffffc0201980:	1846b683          	ld	a3,388(a3) # ffffffffc0208b00 <nbase>
ffffffffc0201984:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201986:	00c51793          	slli	a5,a0,0xc
ffffffffc020198a:	83b1                	srli	a5,a5,0xc
ffffffffc020198c:	000b1717          	auipc	a4,0xb1
ffffffffc0201990:	f4473703          	ld	a4,-188(a4) # ffffffffc02b28d0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201994:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201996:	00e7fa63          	bgeu	a5,a4,ffffffffc02019aa <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc020199a:	000b1697          	auipc	a3,0xb1
ffffffffc020199e:	f4e6b683          	ld	a3,-178(a3) # ffffffffc02b28e8 <va_pa_offset>
ffffffffc02019a2:	9536                	add	a0,a0,a3
}
ffffffffc02019a4:	60a2                	ld	ra,8(sp)
ffffffffc02019a6:	0141                	addi	sp,sp,16
ffffffffc02019a8:	8082                	ret
ffffffffc02019aa:	86aa                	mv	a3,a0
ffffffffc02019ac:	00006617          	auipc	a2,0x6
ffffffffc02019b0:	85c60613          	addi	a2,a2,-1956 # ffffffffc0207208 <default_pmm_manager+0x38>
ffffffffc02019b4:	06900593          	li	a1,105
ffffffffc02019b8:	00006517          	auipc	a0,0x6
ffffffffc02019bc:	87850513          	addi	a0,a0,-1928 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc02019c0:	abbfe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02019c4 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc02019c4:	1101                	addi	sp,sp,-32
ffffffffc02019c6:	ec06                	sd	ra,24(sp)
ffffffffc02019c8:	e822                	sd	s0,16(sp)
ffffffffc02019ca:	e426                	sd	s1,8(sp)
ffffffffc02019cc:	e04a                	sd	s2,0(sp)
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc02019ce:	01050713          	addi	a4,a0,16
ffffffffc02019d2:	6785                	lui	a5,0x1
ffffffffc02019d4:	0cf77363          	bgeu	a4,a5,ffffffffc0201a9a <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc02019d8:	00f50493          	addi	s1,a0,15
ffffffffc02019dc:	8091                	srli	s1,s1,0x4
ffffffffc02019de:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019e0:	10002673          	csrr	a2,sstatus
ffffffffc02019e4:	8a09                	andi	a2,a2,2
ffffffffc02019e6:	e25d                	bnez	a2,ffffffffc0201a8c <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc02019e8:	000a6917          	auipc	s2,0xa6
ffffffffc02019ec:	9e090913          	addi	s2,s2,-1568 # ffffffffc02a73c8 <slobfree>
ffffffffc02019f0:	00093683          	ld	a3,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc02019f4:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc02019f6:	4398                	lw	a4,0(a5)
ffffffffc02019f8:	08975e63          	bge	a4,s1,ffffffffc0201a94 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree) {
ffffffffc02019fc:	00f68b63          	beq	a3,a5,ffffffffc0201a12 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201a00:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201a02:	4018                	lw	a4,0(s0)
ffffffffc0201a04:	02975a63          	bge	a4,s1,ffffffffc0201a38 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree) {
ffffffffc0201a08:	00093683          	ld	a3,0(s2)
ffffffffc0201a0c:	87a2                	mv	a5,s0
ffffffffc0201a0e:	fef699e3          	bne	a3,a5,ffffffffc0201a00 <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc0201a12:	ee31                	bnez	a2,ffffffffc0201a6e <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201a14:	4501                	li	a0,0
ffffffffc0201a16:	f4bff0ef          	jal	ra,ffffffffc0201960 <__slob_get_free_pages.constprop.0>
ffffffffc0201a1a:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201a1c:	cd05                	beqz	a0,ffffffffc0201a54 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201a1e:	6585                	lui	a1,0x1
ffffffffc0201a20:	e8dff0ef          	jal	ra,ffffffffc02018ac <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a24:	10002673          	csrr	a2,sstatus
ffffffffc0201a28:	8a09                	andi	a2,a2,2
ffffffffc0201a2a:	ee05                	bnez	a2,ffffffffc0201a62 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201a2c:	00093783          	ld	a5,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201a30:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201a32:	4018                	lw	a4,0(s0)
ffffffffc0201a34:	fc974ae3          	blt	a4,s1,ffffffffc0201a08 <slob_alloc.constprop.0+0x44>
			if (cur->units == units) /* exact fit? */
ffffffffc0201a38:	04e48763          	beq	s1,a4,ffffffffc0201a86 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201a3c:	00449693          	slli	a3,s1,0x4
ffffffffc0201a40:	96a2                	add	a3,a3,s0
ffffffffc0201a42:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201a44:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201a46:	9f05                	subw	a4,a4,s1
ffffffffc0201a48:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201a4a:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201a4c:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201a4e:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc0201a52:	e20d                	bnez	a2,ffffffffc0201a74 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201a54:	60e2                	ld	ra,24(sp)
ffffffffc0201a56:	8522                	mv	a0,s0
ffffffffc0201a58:	6442                	ld	s0,16(sp)
ffffffffc0201a5a:	64a2                	ld	s1,8(sp)
ffffffffc0201a5c:	6902                	ld	s2,0(sp)
ffffffffc0201a5e:	6105                	addi	sp,sp,32
ffffffffc0201a60:	8082                	ret
        intr_disable();
ffffffffc0201a62:	bc1fe0ef          	jal	ra,ffffffffc0200622 <intr_disable>
			cur = slobfree;
ffffffffc0201a66:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201a6a:	4605                	li	a2,1
ffffffffc0201a6c:	b7d1                	j	ffffffffc0201a30 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201a6e:	baffe0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc0201a72:	b74d                	j	ffffffffc0201a14 <slob_alloc.constprop.0+0x50>
ffffffffc0201a74:	ba9fe0ef          	jal	ra,ffffffffc020061c <intr_enable>
}
ffffffffc0201a78:	60e2                	ld	ra,24(sp)
ffffffffc0201a7a:	8522                	mv	a0,s0
ffffffffc0201a7c:	6442                	ld	s0,16(sp)
ffffffffc0201a7e:	64a2                	ld	s1,8(sp)
ffffffffc0201a80:	6902                	ld	s2,0(sp)
ffffffffc0201a82:	6105                	addi	sp,sp,32
ffffffffc0201a84:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201a86:	6418                	ld	a4,8(s0)
ffffffffc0201a88:	e798                	sd	a4,8(a5)
ffffffffc0201a8a:	b7d1                	j	ffffffffc0201a4e <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201a8c:	b97fe0ef          	jal	ra,ffffffffc0200622 <intr_disable>
        return 1;
ffffffffc0201a90:	4605                	li	a2,1
ffffffffc0201a92:	bf99                	j	ffffffffc02019e8 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201a94:	843e                	mv	s0,a5
ffffffffc0201a96:	87b6                	mv	a5,a3
ffffffffc0201a98:	b745                	j	ffffffffc0201a38 <slob_alloc.constprop.0+0x74>
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201a9a:	00005697          	auipc	a3,0x5
ffffffffc0201a9e:	7a668693          	addi	a3,a3,1958 # ffffffffc0207240 <default_pmm_manager+0x70>
ffffffffc0201aa2:	00005617          	auipc	a2,0x5
ffffffffc0201aa6:	09660613          	addi	a2,a2,150 # ffffffffc0206b38 <commands+0x450>
ffffffffc0201aaa:	06400593          	li	a1,100
ffffffffc0201aae:	00005517          	auipc	a0,0x5
ffffffffc0201ab2:	7b250513          	addi	a0,a0,1970 # ffffffffc0207260 <default_pmm_manager+0x90>
ffffffffc0201ab6:	9c5fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0201aba <kmalloc_init>:
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
ffffffffc0201aba:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc0201abc:	00005517          	auipc	a0,0x5
ffffffffc0201ac0:	7bc50513          	addi	a0,a0,1980 # ffffffffc0207278 <default_pmm_manager+0xa8>
kmalloc_init(void) {
ffffffffc0201ac4:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc0201ac6:	ebafe0ef          	jal	ra,ffffffffc0200180 <cprintf>
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201aca:	60a2                	ld	ra,8(sp)
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201acc:	00005517          	auipc	a0,0x5
ffffffffc0201ad0:	7c450513          	addi	a0,a0,1988 # ffffffffc0207290 <default_pmm_manager+0xc0>
}
ffffffffc0201ad4:	0141                	addi	sp,sp,16
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201ad6:	eaafe06f          	j	ffffffffc0200180 <cprintf>

ffffffffc0201ada <kallocated>:
}

size_t
kallocated(void) {
   return slob_allocated();
}
ffffffffc0201ada:	4501                	li	a0,0
ffffffffc0201adc:	8082                	ret

ffffffffc0201ade <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201ade:	1101                	addi	sp,sp,-32
ffffffffc0201ae0:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201ae2:	6905                	lui	s2,0x1
{
ffffffffc0201ae4:	e822                	sd	s0,16(sp)
ffffffffc0201ae6:	ec06                	sd	ra,24(sp)
ffffffffc0201ae8:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201aea:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bc9>
{
ffffffffc0201aee:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201af0:	04a7f963          	bgeu	a5,a0,ffffffffc0201b42 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201af4:	4561                	li	a0,24
ffffffffc0201af6:	ecfff0ef          	jal	ra,ffffffffc02019c4 <slob_alloc.constprop.0>
ffffffffc0201afa:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201afc:	c929                	beqz	a0,ffffffffc0201b4e <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201afe:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201b02:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201b04:	00f95763          	bge	s2,a5,ffffffffc0201b12 <kmalloc+0x34>
ffffffffc0201b08:	6705                	lui	a4,0x1
ffffffffc0201b0a:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201b0c:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201b0e:	fef74ee3          	blt	a4,a5,ffffffffc0201b0a <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201b12:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201b14:	e4dff0ef          	jal	ra,ffffffffc0201960 <__slob_get_free_pages.constprop.0>
ffffffffc0201b18:	e488                	sd	a0,8(s1)
ffffffffc0201b1a:	842a                	mv	s0,a0
	if (bb->pages) {
ffffffffc0201b1c:	c525                	beqz	a0,ffffffffc0201b84 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b1e:	100027f3          	csrr	a5,sstatus
ffffffffc0201b22:	8b89                	andi	a5,a5,2
ffffffffc0201b24:	ef8d                	bnez	a5,ffffffffc0201b5e <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201b26:	000b1797          	auipc	a5,0xb1
ffffffffc0201b2a:	d9278793          	addi	a5,a5,-622 # ffffffffc02b28b8 <bigblocks>
ffffffffc0201b2e:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201b30:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201b32:	e898                	sd	a4,16(s1)
  return __kmalloc(size, 0);
}
ffffffffc0201b34:	60e2                	ld	ra,24(sp)
ffffffffc0201b36:	8522                	mv	a0,s0
ffffffffc0201b38:	6442                	ld	s0,16(sp)
ffffffffc0201b3a:	64a2                	ld	s1,8(sp)
ffffffffc0201b3c:	6902                	ld	s2,0(sp)
ffffffffc0201b3e:	6105                	addi	sp,sp,32
ffffffffc0201b40:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201b42:	0541                	addi	a0,a0,16
ffffffffc0201b44:	e81ff0ef          	jal	ra,ffffffffc02019c4 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201b48:	01050413          	addi	s0,a0,16
ffffffffc0201b4c:	f565                	bnez	a0,ffffffffc0201b34 <kmalloc+0x56>
ffffffffc0201b4e:	4401                	li	s0,0
}
ffffffffc0201b50:	60e2                	ld	ra,24(sp)
ffffffffc0201b52:	8522                	mv	a0,s0
ffffffffc0201b54:	6442                	ld	s0,16(sp)
ffffffffc0201b56:	64a2                	ld	s1,8(sp)
ffffffffc0201b58:	6902                	ld	s2,0(sp)
ffffffffc0201b5a:	6105                	addi	sp,sp,32
ffffffffc0201b5c:	8082                	ret
        intr_disable();
ffffffffc0201b5e:	ac5fe0ef          	jal	ra,ffffffffc0200622 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201b62:	000b1797          	auipc	a5,0xb1
ffffffffc0201b66:	d5678793          	addi	a5,a5,-682 # ffffffffc02b28b8 <bigblocks>
ffffffffc0201b6a:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201b6c:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201b6e:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201b70:	aadfe0ef          	jal	ra,ffffffffc020061c <intr_enable>
		return bb->pages;
ffffffffc0201b74:	6480                	ld	s0,8(s1)
}
ffffffffc0201b76:	60e2                	ld	ra,24(sp)
ffffffffc0201b78:	64a2                	ld	s1,8(sp)
ffffffffc0201b7a:	8522                	mv	a0,s0
ffffffffc0201b7c:	6442                	ld	s0,16(sp)
ffffffffc0201b7e:	6902                	ld	s2,0(sp)
ffffffffc0201b80:	6105                	addi	sp,sp,32
ffffffffc0201b82:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b84:	45e1                	li	a1,24
ffffffffc0201b86:	8526                	mv	a0,s1
ffffffffc0201b88:	d25ff0ef          	jal	ra,ffffffffc02018ac <slob_free>
  return __kmalloc(size, 0);
ffffffffc0201b8c:	b765                	j	ffffffffc0201b34 <kmalloc+0x56>

ffffffffc0201b8e <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201b8e:	c169                	beqz	a0,ffffffffc0201c50 <kfree+0xc2>
{
ffffffffc0201b90:	1101                	addi	sp,sp,-32
ffffffffc0201b92:	e822                	sd	s0,16(sp)
ffffffffc0201b94:	ec06                	sd	ra,24(sp)
ffffffffc0201b96:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc0201b98:	03451793          	slli	a5,a0,0x34
ffffffffc0201b9c:	842a                	mv	s0,a0
ffffffffc0201b9e:	e3d9                	bnez	a5,ffffffffc0201c24 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ba0:	100027f3          	csrr	a5,sstatus
ffffffffc0201ba4:	8b89                	andi	a5,a5,2
ffffffffc0201ba6:	e7d9                	bnez	a5,ffffffffc0201c34 <kfree+0xa6>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201ba8:	000b1797          	auipc	a5,0xb1
ffffffffc0201bac:	d107b783          	ld	a5,-752(a5) # ffffffffc02b28b8 <bigblocks>
    return 0;
ffffffffc0201bb0:	4601                	li	a2,0
ffffffffc0201bb2:	cbad                	beqz	a5,ffffffffc0201c24 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201bb4:	000b1697          	auipc	a3,0xb1
ffffffffc0201bb8:	d0468693          	addi	a3,a3,-764 # ffffffffc02b28b8 <bigblocks>
ffffffffc0201bbc:	a021                	j	ffffffffc0201bc4 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201bbe:	01048693          	addi	a3,s1,16
ffffffffc0201bc2:	c3a5                	beqz	a5,ffffffffc0201c22 <kfree+0x94>
			if (bb->pages == block) {
ffffffffc0201bc4:	6798                	ld	a4,8(a5)
ffffffffc0201bc6:	84be                	mv	s1,a5
				*last = bb->next;
ffffffffc0201bc8:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block) {
ffffffffc0201bca:	fe871ae3          	bne	a4,s0,ffffffffc0201bbe <kfree+0x30>
				*last = bb->next;
ffffffffc0201bce:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201bd0:	ee2d                	bnez	a2,ffffffffc0201c4a <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201bd2:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201bd6:	4098                	lw	a4,0(s1)
ffffffffc0201bd8:	08f46963          	bltu	s0,a5,ffffffffc0201c6a <kfree+0xdc>
ffffffffc0201bdc:	000b1697          	auipc	a3,0xb1
ffffffffc0201be0:	d0c6b683          	ld	a3,-756(a3) # ffffffffc02b28e8 <va_pa_offset>
ffffffffc0201be4:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage) {
ffffffffc0201be6:	8031                	srli	s0,s0,0xc
ffffffffc0201be8:	000b1797          	auipc	a5,0xb1
ffffffffc0201bec:	ce87b783          	ld	a5,-792(a5) # ffffffffc02b28d0 <npage>
ffffffffc0201bf0:	06f47163          	bgeu	s0,a5,ffffffffc0201c52 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201bf4:	00007517          	auipc	a0,0x7
ffffffffc0201bf8:	f0c53503          	ld	a0,-244(a0) # ffffffffc0208b00 <nbase>
ffffffffc0201bfc:	8c09                	sub	s0,s0,a0
ffffffffc0201bfe:	041a                	slli	s0,s0,0x6
  free_pages(kva2page(kva), 1 << order);
ffffffffc0201c00:	000b1517          	auipc	a0,0xb1
ffffffffc0201c04:	cd853503          	ld	a0,-808(a0) # ffffffffc02b28d8 <pages>
ffffffffc0201c08:	4585                	li	a1,1
ffffffffc0201c0a:	9522                	add	a0,a0,s0
ffffffffc0201c0c:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201c10:	13e000ef          	jal	ra,ffffffffc0201d4e <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201c14:	6442                	ld	s0,16(sp)
ffffffffc0201c16:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c18:	8526                	mv	a0,s1
}
ffffffffc0201c1a:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c1c:	45e1                	li	a1,24
}
ffffffffc0201c1e:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c20:	b171                	j	ffffffffc02018ac <slob_free>
ffffffffc0201c22:	e20d                	bnez	a2,ffffffffc0201c44 <kfree+0xb6>
ffffffffc0201c24:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201c28:	6442                	ld	s0,16(sp)
ffffffffc0201c2a:	60e2                	ld	ra,24(sp)
ffffffffc0201c2c:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c2e:	4581                	li	a1,0
}
ffffffffc0201c30:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c32:	b9ad                	j	ffffffffc02018ac <slob_free>
        intr_disable();
ffffffffc0201c34:	9effe0ef          	jal	ra,ffffffffc0200622 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201c38:	000b1797          	auipc	a5,0xb1
ffffffffc0201c3c:	c807b783          	ld	a5,-896(a5) # ffffffffc02b28b8 <bigblocks>
        return 1;
ffffffffc0201c40:	4605                	li	a2,1
ffffffffc0201c42:	fbad                	bnez	a5,ffffffffc0201bb4 <kfree+0x26>
        intr_enable();
ffffffffc0201c44:	9d9fe0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc0201c48:	bff1                	j	ffffffffc0201c24 <kfree+0x96>
ffffffffc0201c4a:	9d3fe0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc0201c4e:	b751                	j	ffffffffc0201bd2 <kfree+0x44>
ffffffffc0201c50:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201c52:	00005617          	auipc	a2,0x5
ffffffffc0201c56:	68660613          	addi	a2,a2,1670 # ffffffffc02072d8 <default_pmm_manager+0x108>
ffffffffc0201c5a:	06200593          	li	a1,98
ffffffffc0201c5e:	00005517          	auipc	a0,0x5
ffffffffc0201c62:	5d250513          	addi	a0,a0,1490 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc0201c66:	815fe0ef          	jal	ra,ffffffffc020047a <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201c6a:	86a2                	mv	a3,s0
ffffffffc0201c6c:	00005617          	auipc	a2,0x5
ffffffffc0201c70:	64460613          	addi	a2,a2,1604 # ffffffffc02072b0 <default_pmm_manager+0xe0>
ffffffffc0201c74:	06e00593          	li	a1,110
ffffffffc0201c78:	00005517          	auipc	a0,0x5
ffffffffc0201c7c:	5b850513          	addi	a0,a0,1464 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc0201c80:	ffafe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0201c84 <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc0201c84:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201c86:	00005617          	auipc	a2,0x5
ffffffffc0201c8a:	65260613          	addi	a2,a2,1618 # ffffffffc02072d8 <default_pmm_manager+0x108>
ffffffffc0201c8e:	06200593          	li	a1,98
ffffffffc0201c92:	00005517          	auipc	a0,0x5
ffffffffc0201c96:	59e50513          	addi	a0,a0,1438 # ffffffffc0207230 <default_pmm_manager+0x60>
pa2page(uintptr_t pa) {
ffffffffc0201c9a:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201c9c:	fdefe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0201ca0 <pte2page.part.0>:
pte2page(pte_t pte) {
ffffffffc0201ca0:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201ca2:	00005617          	auipc	a2,0x5
ffffffffc0201ca6:	65660613          	addi	a2,a2,1622 # ffffffffc02072f8 <default_pmm_manager+0x128>
ffffffffc0201caa:	07400593          	li	a1,116
ffffffffc0201cae:	00005517          	auipc	a0,0x5
ffffffffc0201cb2:	58250513          	addi	a0,a0,1410 # ffffffffc0207230 <default_pmm_manager+0x60>
pte2page(pte_t pte) {
ffffffffc0201cb6:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201cb8:	fc2fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0201cbc <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0201cbc:	7139                	addi	sp,sp,-64
ffffffffc0201cbe:	f426                	sd	s1,40(sp)
ffffffffc0201cc0:	f04a                	sd	s2,32(sp)
ffffffffc0201cc2:	ec4e                	sd	s3,24(sp)
ffffffffc0201cc4:	e852                	sd	s4,16(sp)
ffffffffc0201cc6:	e456                	sd	s5,8(sp)
ffffffffc0201cc8:	e05a                	sd	s6,0(sp)
ffffffffc0201cca:	fc06                	sd	ra,56(sp)
ffffffffc0201ccc:	f822                	sd	s0,48(sp)
ffffffffc0201cce:	84aa                	mv	s1,a0
ffffffffc0201cd0:	000b1917          	auipc	s2,0xb1
ffffffffc0201cd4:	c1090913          	addi	s2,s2,-1008 # ffffffffc02b28e0 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201cd8:	4a05                	li	s4,1
ffffffffc0201cda:	000b1a97          	auipc	s5,0xb1
ffffffffc0201cde:	c26a8a93          	addi	s5,s5,-986 # ffffffffc02b2900 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0201ce2:	0005099b          	sext.w	s3,a0
ffffffffc0201ce6:	000b1b17          	auipc	s6,0xb1
ffffffffc0201cea:	c22b0b13          	addi	s6,s6,-990 # ffffffffc02b2908 <check_mm_struct>
ffffffffc0201cee:	a01d                	j	ffffffffc0201d14 <alloc_pages+0x58>
            page = pmm_manager->alloc_pages(n);
ffffffffc0201cf0:	00093783          	ld	a5,0(s2)
ffffffffc0201cf4:	6f9c                	ld	a5,24(a5)
ffffffffc0201cf6:	9782                	jalr	a5
ffffffffc0201cf8:	842a                	mv	s0,a0
        swap_out(check_mm_struct, n, 0);
ffffffffc0201cfa:	4601                	li	a2,0
ffffffffc0201cfc:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201cfe:	ec0d                	bnez	s0,ffffffffc0201d38 <alloc_pages+0x7c>
ffffffffc0201d00:	029a6c63          	bltu	s4,s1,ffffffffc0201d38 <alloc_pages+0x7c>
ffffffffc0201d04:	000aa783          	lw	a5,0(s5)
ffffffffc0201d08:	2781                	sext.w	a5,a5
ffffffffc0201d0a:	c79d                	beqz	a5,ffffffffc0201d38 <alloc_pages+0x7c>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201d0c:	000b3503          	ld	a0,0(s6)
ffffffffc0201d10:	64d010ef          	jal	ra,ffffffffc0203b5c <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d14:	100027f3          	csrr	a5,sstatus
ffffffffc0201d18:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0201d1a:	8526                	mv	a0,s1
ffffffffc0201d1c:	dbf1                	beqz	a5,ffffffffc0201cf0 <alloc_pages+0x34>
        intr_disable();
ffffffffc0201d1e:	905fe0ef          	jal	ra,ffffffffc0200622 <intr_disable>
ffffffffc0201d22:	00093783          	ld	a5,0(s2)
ffffffffc0201d26:	8526                	mv	a0,s1
ffffffffc0201d28:	6f9c                	ld	a5,24(a5)
ffffffffc0201d2a:	9782                	jalr	a5
ffffffffc0201d2c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201d2e:	8effe0ef          	jal	ra,ffffffffc020061c <intr_enable>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201d32:	4601                	li	a2,0
ffffffffc0201d34:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201d36:	d469                	beqz	s0,ffffffffc0201d00 <alloc_pages+0x44>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0201d38:	70e2                	ld	ra,56(sp)
ffffffffc0201d3a:	8522                	mv	a0,s0
ffffffffc0201d3c:	7442                	ld	s0,48(sp)
ffffffffc0201d3e:	74a2                	ld	s1,40(sp)
ffffffffc0201d40:	7902                	ld	s2,32(sp)
ffffffffc0201d42:	69e2                	ld	s3,24(sp)
ffffffffc0201d44:	6a42                	ld	s4,16(sp)
ffffffffc0201d46:	6aa2                	ld	s5,8(sp)
ffffffffc0201d48:	6b02                	ld	s6,0(sp)
ffffffffc0201d4a:	6121                	addi	sp,sp,64
ffffffffc0201d4c:	8082                	ret

ffffffffc0201d4e <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d4e:	100027f3          	csrr	a5,sstatus
ffffffffc0201d52:	8b89                	andi	a5,a5,2
ffffffffc0201d54:	e799                	bnez	a5,ffffffffc0201d62 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201d56:	000b1797          	auipc	a5,0xb1
ffffffffc0201d5a:	b8a7b783          	ld	a5,-1142(a5) # ffffffffc02b28e0 <pmm_manager>
ffffffffc0201d5e:	739c                	ld	a5,32(a5)
ffffffffc0201d60:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201d62:	1101                	addi	sp,sp,-32
ffffffffc0201d64:	ec06                	sd	ra,24(sp)
ffffffffc0201d66:	e822                	sd	s0,16(sp)
ffffffffc0201d68:	e426                	sd	s1,8(sp)
ffffffffc0201d6a:	842a                	mv	s0,a0
ffffffffc0201d6c:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201d6e:	8b5fe0ef          	jal	ra,ffffffffc0200622 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201d72:	000b1797          	auipc	a5,0xb1
ffffffffc0201d76:	b6e7b783          	ld	a5,-1170(a5) # ffffffffc02b28e0 <pmm_manager>
ffffffffc0201d7a:	739c                	ld	a5,32(a5)
ffffffffc0201d7c:	85a6                	mv	a1,s1
ffffffffc0201d7e:	8522                	mv	a0,s0
ffffffffc0201d80:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201d82:	6442                	ld	s0,16(sp)
ffffffffc0201d84:	60e2                	ld	ra,24(sp)
ffffffffc0201d86:	64a2                	ld	s1,8(sp)
ffffffffc0201d88:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201d8a:	893fe06f          	j	ffffffffc020061c <intr_enable>

ffffffffc0201d8e <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d8e:	100027f3          	csrr	a5,sstatus
ffffffffc0201d92:	8b89                	andi	a5,a5,2
ffffffffc0201d94:	e799                	bnez	a5,ffffffffc0201da2 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201d96:	000b1797          	auipc	a5,0xb1
ffffffffc0201d9a:	b4a7b783          	ld	a5,-1206(a5) # ffffffffc02b28e0 <pmm_manager>
ffffffffc0201d9e:	779c                	ld	a5,40(a5)
ffffffffc0201da0:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201da2:	1141                	addi	sp,sp,-16
ffffffffc0201da4:	e406                	sd	ra,8(sp)
ffffffffc0201da6:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201da8:	87bfe0ef          	jal	ra,ffffffffc0200622 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201dac:	000b1797          	auipc	a5,0xb1
ffffffffc0201db0:	b347b783          	ld	a5,-1228(a5) # ffffffffc02b28e0 <pmm_manager>
ffffffffc0201db4:	779c                	ld	a5,40(a5)
ffffffffc0201db6:	9782                	jalr	a5
ffffffffc0201db8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201dba:	863fe0ef          	jal	ra,ffffffffc020061c <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201dbe:	60a2                	ld	ra,8(sp)
ffffffffc0201dc0:	8522                	mv	a0,s0
ffffffffc0201dc2:	6402                	ld	s0,0(sp)
ffffffffc0201dc4:	0141                	addi	sp,sp,16
ffffffffc0201dc6:	8082                	ret

ffffffffc0201dc8 <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201dc8:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201dcc:	1ff7f793          	andi	a5,a5,511
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201dd0:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201dd2:	078e                	slli	a5,a5,0x3
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201dd4:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201dd6:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201dda:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201ddc:	f04a                	sd	s2,32(sp)
ffffffffc0201dde:	ec4e                	sd	s3,24(sp)
ffffffffc0201de0:	e852                	sd	s4,16(sp)
ffffffffc0201de2:	fc06                	sd	ra,56(sp)
ffffffffc0201de4:	f822                	sd	s0,48(sp)
ffffffffc0201de6:	e456                	sd	s5,8(sp)
ffffffffc0201de8:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201dea:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201dee:	892e                	mv	s2,a1
ffffffffc0201df0:	89b2                	mv	s3,a2
ffffffffc0201df2:	000b1a17          	auipc	s4,0xb1
ffffffffc0201df6:	adea0a13          	addi	s4,s4,-1314 # ffffffffc02b28d0 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201dfa:	e7b5                	bnez	a5,ffffffffc0201e66 <get_pte+0x9e>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201dfc:	12060b63          	beqz	a2,ffffffffc0201f32 <get_pte+0x16a>
ffffffffc0201e00:	4505                	li	a0,1
ffffffffc0201e02:	ebbff0ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0201e06:	842a                	mv	s0,a0
ffffffffc0201e08:	12050563          	beqz	a0,ffffffffc0201f32 <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0201e0c:	000b1b17          	auipc	s6,0xb1
ffffffffc0201e10:	accb0b13          	addi	s6,s6,-1332 # ffffffffc02b28d8 <pages>
ffffffffc0201e14:	000b3503          	ld	a0,0(s6)
ffffffffc0201e18:	00080ab7          	lui	s5,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201e1c:	000b1a17          	auipc	s4,0xb1
ffffffffc0201e20:	ab4a0a13          	addi	s4,s4,-1356 # ffffffffc02b28d0 <npage>
ffffffffc0201e24:	40a40533          	sub	a0,s0,a0
ffffffffc0201e28:	8519                	srai	a0,a0,0x6
ffffffffc0201e2a:	9556                	add	a0,a0,s5
ffffffffc0201e2c:	000a3703          	ld	a4,0(s4)
ffffffffc0201e30:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201e34:	4685                	li	a3,1
ffffffffc0201e36:	c014                	sw	a3,0(s0)
ffffffffc0201e38:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e3a:	0532                	slli	a0,a0,0xc
ffffffffc0201e3c:	14e7f263          	bgeu	a5,a4,ffffffffc0201f80 <get_pte+0x1b8>
ffffffffc0201e40:	000b1797          	auipc	a5,0xb1
ffffffffc0201e44:	aa87b783          	ld	a5,-1368(a5) # ffffffffc02b28e8 <va_pa_offset>
ffffffffc0201e48:	6605                	lui	a2,0x1
ffffffffc0201e4a:	4581                	li	a1,0
ffffffffc0201e4c:	953e                	add	a0,a0,a5
ffffffffc0201e4e:	604040ef          	jal	ra,ffffffffc0206452 <memset>
    return page - pages + nbase;
ffffffffc0201e52:	000b3683          	ld	a3,0(s6)
ffffffffc0201e56:	40d406b3          	sub	a3,s0,a3
ffffffffc0201e5a:	8699                	srai	a3,a3,0x6
ffffffffc0201e5c:	96d6                	add	a3,a3,s5
  asm volatile("sfence.vma");
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e5e:	06aa                	slli	a3,a3,0xa
ffffffffc0201e60:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201e64:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201e66:	77fd                	lui	a5,0xfffff
ffffffffc0201e68:	068a                	slli	a3,a3,0x2
ffffffffc0201e6a:	000a3703          	ld	a4,0(s4)
ffffffffc0201e6e:	8efd                	and	a3,a3,a5
ffffffffc0201e70:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201e74:	0ce7f163          	bgeu	a5,a4,ffffffffc0201f36 <get_pte+0x16e>
ffffffffc0201e78:	000b1a97          	auipc	s5,0xb1
ffffffffc0201e7c:	a70a8a93          	addi	s5,s5,-1424 # ffffffffc02b28e8 <va_pa_offset>
ffffffffc0201e80:	000ab403          	ld	s0,0(s5)
ffffffffc0201e84:	01595793          	srli	a5,s2,0x15
ffffffffc0201e88:	1ff7f793          	andi	a5,a5,511
ffffffffc0201e8c:	96a2                	add	a3,a3,s0
ffffffffc0201e8e:	00379413          	slli	s0,a5,0x3
ffffffffc0201e92:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) {
ffffffffc0201e94:	6014                	ld	a3,0(s0)
ffffffffc0201e96:	0016f793          	andi	a5,a3,1
ffffffffc0201e9a:	e3ad                	bnez	a5,ffffffffc0201efc <get_pte+0x134>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201e9c:	08098b63          	beqz	s3,ffffffffc0201f32 <get_pte+0x16a>
ffffffffc0201ea0:	4505                	li	a0,1
ffffffffc0201ea2:	e1bff0ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0201ea6:	84aa                	mv	s1,a0
ffffffffc0201ea8:	c549                	beqz	a0,ffffffffc0201f32 <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0201eaa:	000b1b17          	auipc	s6,0xb1
ffffffffc0201eae:	a2eb0b13          	addi	s6,s6,-1490 # ffffffffc02b28d8 <pages>
ffffffffc0201eb2:	000b3503          	ld	a0,0(s6)
ffffffffc0201eb6:	000809b7          	lui	s3,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201eba:	000a3703          	ld	a4,0(s4)
ffffffffc0201ebe:	40a48533          	sub	a0,s1,a0
ffffffffc0201ec2:	8519                	srai	a0,a0,0x6
ffffffffc0201ec4:	954e                	add	a0,a0,s3
ffffffffc0201ec6:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201eca:	4685                	li	a3,1
ffffffffc0201ecc:	c094                	sw	a3,0(s1)
ffffffffc0201ece:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ed0:	0532                	slli	a0,a0,0xc
ffffffffc0201ed2:	08e7fa63          	bgeu	a5,a4,ffffffffc0201f66 <get_pte+0x19e>
ffffffffc0201ed6:	000ab783          	ld	a5,0(s5)
ffffffffc0201eda:	6605                	lui	a2,0x1
ffffffffc0201edc:	4581                	li	a1,0
ffffffffc0201ede:	953e                	add	a0,a0,a5
ffffffffc0201ee0:	572040ef          	jal	ra,ffffffffc0206452 <memset>
    return page - pages + nbase;
ffffffffc0201ee4:	000b3683          	ld	a3,0(s6)
ffffffffc0201ee8:	40d486b3          	sub	a3,s1,a3
ffffffffc0201eec:	8699                	srai	a3,a3,0x6
ffffffffc0201eee:	96ce                	add	a3,a3,s3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201ef0:	06aa                	slli	a3,a3,0xa
ffffffffc0201ef2:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201ef6:	e014                	sd	a3,0(s0)
        }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201ef8:	000a3703          	ld	a4,0(s4)
ffffffffc0201efc:	068a                	slli	a3,a3,0x2
ffffffffc0201efe:	757d                	lui	a0,0xfffff
ffffffffc0201f00:	8ee9                	and	a3,a3,a0
ffffffffc0201f02:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201f06:	04e7f463          	bgeu	a5,a4,ffffffffc0201f4e <get_pte+0x186>
ffffffffc0201f0a:	000ab503          	ld	a0,0(s5)
ffffffffc0201f0e:	00c95913          	srli	s2,s2,0xc
ffffffffc0201f12:	1ff97913          	andi	s2,s2,511
ffffffffc0201f16:	96aa                	add	a3,a3,a0
ffffffffc0201f18:	00391513          	slli	a0,s2,0x3
ffffffffc0201f1c:	9536                	add	a0,a0,a3
}
ffffffffc0201f1e:	70e2                	ld	ra,56(sp)
ffffffffc0201f20:	7442                	ld	s0,48(sp)
ffffffffc0201f22:	74a2                	ld	s1,40(sp)
ffffffffc0201f24:	7902                	ld	s2,32(sp)
ffffffffc0201f26:	69e2                	ld	s3,24(sp)
ffffffffc0201f28:	6a42                	ld	s4,16(sp)
ffffffffc0201f2a:	6aa2                	ld	s5,8(sp)
ffffffffc0201f2c:	6b02                	ld	s6,0(sp)
ffffffffc0201f2e:	6121                	addi	sp,sp,64
ffffffffc0201f30:	8082                	ret
            return NULL;
ffffffffc0201f32:	4501                	li	a0,0
ffffffffc0201f34:	b7ed                	j	ffffffffc0201f1e <get_pte+0x156>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f36:	00005617          	auipc	a2,0x5
ffffffffc0201f3a:	2d260613          	addi	a2,a2,722 # ffffffffc0207208 <default_pmm_manager+0x38>
ffffffffc0201f3e:	0e300593          	li	a1,227
ffffffffc0201f42:	00005517          	auipc	a0,0x5
ffffffffc0201f46:	3de50513          	addi	a0,a0,990 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0201f4a:	d30fe0ef          	jal	ra,ffffffffc020047a <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201f4e:	00005617          	auipc	a2,0x5
ffffffffc0201f52:	2ba60613          	addi	a2,a2,698 # ffffffffc0207208 <default_pmm_manager+0x38>
ffffffffc0201f56:	0ee00593          	li	a1,238
ffffffffc0201f5a:	00005517          	auipc	a0,0x5
ffffffffc0201f5e:	3c650513          	addi	a0,a0,966 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0201f62:	d18fe0ef          	jal	ra,ffffffffc020047a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f66:	86aa                	mv	a3,a0
ffffffffc0201f68:	00005617          	auipc	a2,0x5
ffffffffc0201f6c:	2a060613          	addi	a2,a2,672 # ffffffffc0207208 <default_pmm_manager+0x38>
ffffffffc0201f70:	0eb00593          	li	a1,235
ffffffffc0201f74:	00005517          	auipc	a0,0x5
ffffffffc0201f78:	3ac50513          	addi	a0,a0,940 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0201f7c:	cfefe0ef          	jal	ra,ffffffffc020047a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f80:	86aa                	mv	a3,a0
ffffffffc0201f82:	00005617          	auipc	a2,0x5
ffffffffc0201f86:	28660613          	addi	a2,a2,646 # ffffffffc0207208 <default_pmm_manager+0x38>
ffffffffc0201f8a:	0df00593          	li	a1,223
ffffffffc0201f8e:	00005517          	auipc	a0,0x5
ffffffffc0201f92:	39250513          	addi	a0,a0,914 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0201f96:	ce4fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0201f9a <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201f9a:	1141                	addi	sp,sp,-16
ffffffffc0201f9c:	e022                	sd	s0,0(sp)
ffffffffc0201f9e:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fa0:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201fa2:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fa4:	e25ff0ef          	jal	ra,ffffffffc0201dc8 <get_pte>
    if (ptep_store != NULL) {
ffffffffc0201fa8:	c011                	beqz	s0,ffffffffc0201fac <get_page+0x12>
        *ptep_store = ptep;
ffffffffc0201faa:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0201fac:	c511                	beqz	a0,ffffffffc0201fb8 <get_page+0x1e>
ffffffffc0201fae:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201fb0:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0201fb2:	0017f713          	andi	a4,a5,1
ffffffffc0201fb6:	e709                	bnez	a4,ffffffffc0201fc0 <get_page+0x26>
}
ffffffffc0201fb8:	60a2                	ld	ra,8(sp)
ffffffffc0201fba:	6402                	ld	s0,0(sp)
ffffffffc0201fbc:	0141                	addi	sp,sp,16
ffffffffc0201fbe:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201fc0:	078a                	slli	a5,a5,0x2
ffffffffc0201fc2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201fc4:	000b1717          	auipc	a4,0xb1
ffffffffc0201fc8:	90c73703          	ld	a4,-1780(a4) # ffffffffc02b28d0 <npage>
ffffffffc0201fcc:	00e7ff63          	bgeu	a5,a4,ffffffffc0201fea <get_page+0x50>
ffffffffc0201fd0:	60a2                	ld	ra,8(sp)
ffffffffc0201fd2:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0201fd4:	fff80537          	lui	a0,0xfff80
ffffffffc0201fd8:	97aa                	add	a5,a5,a0
ffffffffc0201fda:	079a                	slli	a5,a5,0x6
ffffffffc0201fdc:	000b1517          	auipc	a0,0xb1
ffffffffc0201fe0:	8fc53503          	ld	a0,-1796(a0) # ffffffffc02b28d8 <pages>
ffffffffc0201fe4:	953e                	add	a0,a0,a5
ffffffffc0201fe6:	0141                	addi	sp,sp,16
ffffffffc0201fe8:	8082                	ret
ffffffffc0201fea:	c9bff0ef          	jal	ra,ffffffffc0201c84 <pa2page.part.0>

ffffffffc0201fee <unmap_range>:
        *ptep = 0;                  //(5) clear second page table entry
        tlb_invalidate(pgdir, la);  //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0201fee:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0201ff0:	00c5e7b3          	or	a5,a1,a2
void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0201ff4:	f486                	sd	ra,104(sp)
ffffffffc0201ff6:	f0a2                	sd	s0,96(sp)
ffffffffc0201ff8:	eca6                	sd	s1,88(sp)
ffffffffc0201ffa:	e8ca                	sd	s2,80(sp)
ffffffffc0201ffc:	e4ce                	sd	s3,72(sp)
ffffffffc0201ffe:	e0d2                	sd	s4,64(sp)
ffffffffc0202000:	fc56                	sd	s5,56(sp)
ffffffffc0202002:	f85a                	sd	s6,48(sp)
ffffffffc0202004:	f45e                	sd	s7,40(sp)
ffffffffc0202006:	f062                	sd	s8,32(sp)
ffffffffc0202008:	ec66                	sd	s9,24(sp)
ffffffffc020200a:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020200c:	17d2                	slli	a5,a5,0x34
ffffffffc020200e:	e3ed                	bnez	a5,ffffffffc02020f0 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc0202010:	002007b7          	lui	a5,0x200
ffffffffc0202014:	842e                	mv	s0,a1
ffffffffc0202016:	0ef5ed63          	bltu	a1,a5,ffffffffc0202110 <unmap_range+0x122>
ffffffffc020201a:	8932                	mv	s2,a2
ffffffffc020201c:	0ec5fa63          	bgeu	a1,a2,ffffffffc0202110 <unmap_range+0x122>
ffffffffc0202020:	4785                	li	a5,1
ffffffffc0202022:	07fe                	slli	a5,a5,0x1f
ffffffffc0202024:	0ec7e663          	bltu	a5,a2,ffffffffc0202110 <unmap_range+0x122>
ffffffffc0202028:	89aa                	mv	s3,a0
            continue;
        }
        if (*ptep != 0) {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc020202a:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc020202c:	000b1c97          	auipc	s9,0xb1
ffffffffc0202030:	8a4c8c93          	addi	s9,s9,-1884 # ffffffffc02b28d0 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202034:	000b1c17          	auipc	s8,0xb1
ffffffffc0202038:	8a4c0c13          	addi	s8,s8,-1884 # ffffffffc02b28d8 <pages>
ffffffffc020203c:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc0202040:	000b1d17          	auipc	s10,0xb1
ffffffffc0202044:	8a0d0d13          	addi	s10,s10,-1888 # ffffffffc02b28e0 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202048:	00200b37          	lui	s6,0x200
ffffffffc020204c:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202050:	4601                	li	a2,0
ffffffffc0202052:	85a2                	mv	a1,s0
ffffffffc0202054:	854e                	mv	a0,s3
ffffffffc0202056:	d73ff0ef          	jal	ra,ffffffffc0201dc8 <get_pte>
ffffffffc020205a:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc020205c:	cd29                	beqz	a0,ffffffffc02020b6 <unmap_range+0xc8>
        if (*ptep != 0) {
ffffffffc020205e:	611c                	ld	a5,0(a0)
ffffffffc0202060:	e395                	bnez	a5,ffffffffc0202084 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0202062:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202064:	ff2466e3          	bltu	s0,s2,ffffffffc0202050 <unmap_range+0x62>
}
ffffffffc0202068:	70a6                	ld	ra,104(sp)
ffffffffc020206a:	7406                	ld	s0,96(sp)
ffffffffc020206c:	64e6                	ld	s1,88(sp)
ffffffffc020206e:	6946                	ld	s2,80(sp)
ffffffffc0202070:	69a6                	ld	s3,72(sp)
ffffffffc0202072:	6a06                	ld	s4,64(sp)
ffffffffc0202074:	7ae2                	ld	s5,56(sp)
ffffffffc0202076:	7b42                	ld	s6,48(sp)
ffffffffc0202078:	7ba2                	ld	s7,40(sp)
ffffffffc020207a:	7c02                	ld	s8,32(sp)
ffffffffc020207c:	6ce2                	ld	s9,24(sp)
ffffffffc020207e:	6d42                	ld	s10,16(sp)
ffffffffc0202080:	6165                	addi	sp,sp,112
ffffffffc0202082:	8082                	ret
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0202084:	0017f713          	andi	a4,a5,1
ffffffffc0202088:	df69                	beqz	a4,ffffffffc0202062 <unmap_range+0x74>
    if (PPN(pa) >= npage) {
ffffffffc020208a:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020208e:	078a                	slli	a5,a5,0x2
ffffffffc0202090:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202092:	08e7ff63          	bgeu	a5,a4,ffffffffc0202130 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0202096:	000c3503          	ld	a0,0(s8)
ffffffffc020209a:	97de                	add	a5,a5,s7
ffffffffc020209c:	079a                	slli	a5,a5,0x6
ffffffffc020209e:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02020a0:	411c                	lw	a5,0(a0)
ffffffffc02020a2:	fff7871b          	addiw	a4,a5,-1
ffffffffc02020a6:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02020a8:	cf11                	beqz	a4,ffffffffc02020c4 <unmap_range+0xd6>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc02020aa:	0004b023          	sd	zero,0(s1)
}

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020ae:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc02020b2:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02020b4:	bf45                	j	ffffffffc0202064 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02020b6:	945a                	add	s0,s0,s6
ffffffffc02020b8:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc02020bc:	d455                	beqz	s0,ffffffffc0202068 <unmap_range+0x7a>
ffffffffc02020be:	f92469e3          	bltu	s0,s2,ffffffffc0202050 <unmap_range+0x62>
ffffffffc02020c2:	b75d                	j	ffffffffc0202068 <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02020c4:	100027f3          	csrr	a5,sstatus
ffffffffc02020c8:	8b89                	andi	a5,a5,2
ffffffffc02020ca:	e799                	bnez	a5,ffffffffc02020d8 <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc02020cc:	000d3783          	ld	a5,0(s10)
ffffffffc02020d0:	4585                	li	a1,1
ffffffffc02020d2:	739c                	ld	a5,32(a5)
ffffffffc02020d4:	9782                	jalr	a5
    if (flag) {
ffffffffc02020d6:	bfd1                	j	ffffffffc02020aa <unmap_range+0xbc>
ffffffffc02020d8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02020da:	d48fe0ef          	jal	ra,ffffffffc0200622 <intr_disable>
ffffffffc02020de:	000d3783          	ld	a5,0(s10)
ffffffffc02020e2:	6522                	ld	a0,8(sp)
ffffffffc02020e4:	4585                	li	a1,1
ffffffffc02020e6:	739c                	ld	a5,32(a5)
ffffffffc02020e8:	9782                	jalr	a5
        intr_enable();
ffffffffc02020ea:	d32fe0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc02020ee:	bf75                	j	ffffffffc02020aa <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02020f0:	00005697          	auipc	a3,0x5
ffffffffc02020f4:	24068693          	addi	a3,a3,576 # ffffffffc0207330 <default_pmm_manager+0x160>
ffffffffc02020f8:	00005617          	auipc	a2,0x5
ffffffffc02020fc:	a4060613          	addi	a2,a2,-1472 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202100:	10f00593          	li	a1,271
ffffffffc0202104:	00005517          	auipc	a0,0x5
ffffffffc0202108:	21c50513          	addi	a0,a0,540 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc020210c:	b6efe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202110:	00005697          	auipc	a3,0x5
ffffffffc0202114:	25068693          	addi	a3,a3,592 # ffffffffc0207360 <default_pmm_manager+0x190>
ffffffffc0202118:	00005617          	auipc	a2,0x5
ffffffffc020211c:	a2060613          	addi	a2,a2,-1504 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202120:	11000593          	li	a1,272
ffffffffc0202124:	00005517          	auipc	a0,0x5
ffffffffc0202128:	1fc50513          	addi	a0,a0,508 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc020212c:	b4efe0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0202130:	b55ff0ef          	jal	ra,ffffffffc0201c84 <pa2page.part.0>

ffffffffc0202134 <exit_range>:
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0202134:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202136:	00c5e7b3          	or	a5,a1,a2
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc020213a:	fc86                	sd	ra,120(sp)
ffffffffc020213c:	f8a2                	sd	s0,112(sp)
ffffffffc020213e:	f4a6                	sd	s1,104(sp)
ffffffffc0202140:	f0ca                	sd	s2,96(sp)
ffffffffc0202142:	ecce                	sd	s3,88(sp)
ffffffffc0202144:	e8d2                	sd	s4,80(sp)
ffffffffc0202146:	e4d6                	sd	s5,72(sp)
ffffffffc0202148:	e0da                	sd	s6,64(sp)
ffffffffc020214a:	fc5e                	sd	s7,56(sp)
ffffffffc020214c:	f862                	sd	s8,48(sp)
ffffffffc020214e:	f466                	sd	s9,40(sp)
ffffffffc0202150:	f06a                	sd	s10,32(sp)
ffffffffc0202152:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202154:	17d2                	slli	a5,a5,0x34
ffffffffc0202156:	20079a63          	bnez	a5,ffffffffc020236a <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc020215a:	002007b7          	lui	a5,0x200
ffffffffc020215e:	24f5e463          	bltu	a1,a5,ffffffffc02023a6 <exit_range+0x272>
ffffffffc0202162:	8ab2                	mv	s5,a2
ffffffffc0202164:	24c5f163          	bgeu	a1,a2,ffffffffc02023a6 <exit_range+0x272>
ffffffffc0202168:	4785                	li	a5,1
ffffffffc020216a:	07fe                	slli	a5,a5,0x1f
ffffffffc020216c:	22c7ed63          	bltu	a5,a2,ffffffffc02023a6 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202170:	c00009b7          	lui	s3,0xc0000
ffffffffc0202174:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202178:	ffe00937          	lui	s2,0xffe00
ffffffffc020217c:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc0202180:	5cfd                	li	s9,-1
ffffffffc0202182:	8c2a                	mv	s8,a0
ffffffffc0202184:	0125f933          	and	s2,a1,s2
ffffffffc0202188:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage) {
ffffffffc020218a:	000b0d17          	auipc	s10,0xb0
ffffffffc020218e:	746d0d13          	addi	s10,s10,1862 # ffffffffc02b28d0 <npage>
    return KADDR(page2pa(page));
ffffffffc0202192:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202196:	000b0717          	auipc	a4,0xb0
ffffffffc020219a:	74270713          	addi	a4,a4,1858 # ffffffffc02b28d8 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc020219e:	000b0d97          	auipc	s11,0xb0
ffffffffc02021a2:	742d8d93          	addi	s11,s11,1858 # ffffffffc02b28e0 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02021a6:	c0000437          	lui	s0,0xc0000
ffffffffc02021aa:	944e                	add	s0,s0,s3
ffffffffc02021ac:	8079                	srli	s0,s0,0x1e
ffffffffc02021ae:	1ff47413          	andi	s0,s0,511
ffffffffc02021b2:	040e                	slli	s0,s0,0x3
ffffffffc02021b4:	9462                	add	s0,s0,s8
ffffffffc02021b6:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ed0>
        if (pde1&PTE_V){
ffffffffc02021ba:	001a7793          	andi	a5,s4,1
ffffffffc02021be:	eb99                	bnez	a5,ffffffffc02021d4 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc02021c0:	12098463          	beqz	s3,ffffffffc02022e8 <exit_range+0x1b4>
ffffffffc02021c4:	400007b7          	lui	a5,0x40000
ffffffffc02021c8:	97ce                	add	a5,a5,s3
ffffffffc02021ca:	894e                	mv	s2,s3
ffffffffc02021cc:	1159fe63          	bgeu	s3,s5,ffffffffc02022e8 <exit_range+0x1b4>
ffffffffc02021d0:	89be                	mv	s3,a5
ffffffffc02021d2:	bfd1                	j	ffffffffc02021a6 <exit_range+0x72>
    if (PPN(pa) >= npage) {
ffffffffc02021d4:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02021d8:	0a0a                	slli	s4,s4,0x2
ffffffffc02021da:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage) {
ffffffffc02021de:	1cfa7263          	bgeu	s4,a5,ffffffffc02023a2 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02021e2:	fff80637          	lui	a2,0xfff80
ffffffffc02021e6:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc02021e8:	000806b7          	lui	a3,0x80
ffffffffc02021ec:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02021ee:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02021f2:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02021f4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02021f6:	18f5fa63          	bgeu	a1,a5,ffffffffc020238a <exit_range+0x256>
ffffffffc02021fa:	000b0817          	auipc	a6,0xb0
ffffffffc02021fe:	6ee80813          	addi	a6,a6,1774 # ffffffffc02b28e8 <va_pa_offset>
ffffffffc0202202:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc0202206:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc0202208:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc020220c:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc020220e:	00080337          	lui	t1,0x80
ffffffffc0202212:	6885                	lui	a7,0x1
ffffffffc0202214:	a819                	j	ffffffffc020222a <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc0202216:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc0202218:	002007b7          	lui	a5,0x200
ffffffffc020221c:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc020221e:	08090c63          	beqz	s2,ffffffffc02022b6 <exit_range+0x182>
ffffffffc0202222:	09397a63          	bgeu	s2,s3,ffffffffc02022b6 <exit_range+0x182>
ffffffffc0202226:	0f597063          	bgeu	s2,s5,ffffffffc0202306 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc020222a:	01595493          	srli	s1,s2,0x15
ffffffffc020222e:	1ff4f493          	andi	s1,s1,511
ffffffffc0202232:	048e                	slli	s1,s1,0x3
ffffffffc0202234:	94da                	add	s1,s1,s6
ffffffffc0202236:	609c                	ld	a5,0(s1)
                if (pde0&PTE_V) {
ffffffffc0202238:	0017f693          	andi	a3,a5,1
ffffffffc020223c:	dee9                	beqz	a3,ffffffffc0202216 <exit_range+0xe2>
    if (PPN(pa) >= npage) {
ffffffffc020223e:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202242:	078a                	slli	a5,a5,0x2
ffffffffc0202244:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202246:	14b7fe63          	bgeu	a5,a1,ffffffffc02023a2 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020224a:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc020224c:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc0202250:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202254:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202258:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020225a:	12bef863          	bgeu	t4,a1,ffffffffc020238a <exit_range+0x256>
ffffffffc020225e:	00083783          	ld	a5,0(a6)
ffffffffc0202262:	96be                	add	a3,a3,a5
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc0202264:	011685b3          	add	a1,a3,a7
                        if (pt[i]&PTE_V){
ffffffffc0202268:	629c                	ld	a5,0(a3)
ffffffffc020226a:	8b85                	andi	a5,a5,1
ffffffffc020226c:	f7d5                	bnez	a5,ffffffffc0202218 <exit_range+0xe4>
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc020226e:	06a1                	addi	a3,a3,8
ffffffffc0202270:	fed59ce3          	bne	a1,a3,ffffffffc0202268 <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0202274:	631c                	ld	a5,0(a4)
ffffffffc0202276:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202278:	100027f3          	csrr	a5,sstatus
ffffffffc020227c:	8b89                	andi	a5,a5,2
ffffffffc020227e:	e7d9                	bnez	a5,ffffffffc020230c <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc0202280:	000db783          	ld	a5,0(s11)
ffffffffc0202284:	4585                	li	a1,1
ffffffffc0202286:	e032                	sd	a2,0(sp)
ffffffffc0202288:	739c                	ld	a5,32(a5)
ffffffffc020228a:	9782                	jalr	a5
    if (flag) {
ffffffffc020228c:	6602                	ld	a2,0(sp)
ffffffffc020228e:	000b0817          	auipc	a6,0xb0
ffffffffc0202292:	65a80813          	addi	a6,a6,1626 # ffffffffc02b28e8 <va_pa_offset>
ffffffffc0202296:	fff80e37          	lui	t3,0xfff80
ffffffffc020229a:	00080337          	lui	t1,0x80
ffffffffc020229e:	6885                	lui	a7,0x1
ffffffffc02022a0:	000b0717          	auipc	a4,0xb0
ffffffffc02022a4:	63870713          	addi	a4,a4,1592 # ffffffffc02b28d8 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02022a8:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc02022ac:	002007b7          	lui	a5,0x200
ffffffffc02022b0:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc02022b2:	f60918e3          	bnez	s2,ffffffffc0202222 <exit_range+0xee>
            if (free_pd0) {
ffffffffc02022b6:	f00b85e3          	beqz	s7,ffffffffc02021c0 <exit_range+0x8c>
    if (PPN(pa) >= npage) {
ffffffffc02022ba:	000d3783          	ld	a5,0(s10)
ffffffffc02022be:	0efa7263          	bgeu	s4,a5,ffffffffc02023a2 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02022c2:	6308                	ld	a0,0(a4)
ffffffffc02022c4:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02022c6:	100027f3          	csrr	a5,sstatus
ffffffffc02022ca:	8b89                	andi	a5,a5,2
ffffffffc02022cc:	efad                	bnez	a5,ffffffffc0202346 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc02022ce:	000db783          	ld	a5,0(s11)
ffffffffc02022d2:	4585                	li	a1,1
ffffffffc02022d4:	739c                	ld	a5,32(a5)
ffffffffc02022d6:	9782                	jalr	a5
ffffffffc02022d8:	000b0717          	auipc	a4,0xb0
ffffffffc02022dc:	60070713          	addi	a4,a4,1536 # ffffffffc02b28d8 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02022e0:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc02022e4:	ee0990e3          	bnez	s3,ffffffffc02021c4 <exit_range+0x90>
}
ffffffffc02022e8:	70e6                	ld	ra,120(sp)
ffffffffc02022ea:	7446                	ld	s0,112(sp)
ffffffffc02022ec:	74a6                	ld	s1,104(sp)
ffffffffc02022ee:	7906                	ld	s2,96(sp)
ffffffffc02022f0:	69e6                	ld	s3,88(sp)
ffffffffc02022f2:	6a46                	ld	s4,80(sp)
ffffffffc02022f4:	6aa6                	ld	s5,72(sp)
ffffffffc02022f6:	6b06                	ld	s6,64(sp)
ffffffffc02022f8:	7be2                	ld	s7,56(sp)
ffffffffc02022fa:	7c42                	ld	s8,48(sp)
ffffffffc02022fc:	7ca2                	ld	s9,40(sp)
ffffffffc02022fe:	7d02                	ld	s10,32(sp)
ffffffffc0202300:	6de2                	ld	s11,24(sp)
ffffffffc0202302:	6109                	addi	sp,sp,128
ffffffffc0202304:	8082                	ret
            if (free_pd0) {
ffffffffc0202306:	ea0b8fe3          	beqz	s7,ffffffffc02021c4 <exit_range+0x90>
ffffffffc020230a:	bf45                	j	ffffffffc02022ba <exit_range+0x186>
ffffffffc020230c:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc020230e:	e42a                	sd	a0,8(sp)
ffffffffc0202310:	b12fe0ef          	jal	ra,ffffffffc0200622 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202314:	000db783          	ld	a5,0(s11)
ffffffffc0202318:	6522                	ld	a0,8(sp)
ffffffffc020231a:	4585                	li	a1,1
ffffffffc020231c:	739c                	ld	a5,32(a5)
ffffffffc020231e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202320:	afcfe0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc0202324:	6602                	ld	a2,0(sp)
ffffffffc0202326:	000b0717          	auipc	a4,0xb0
ffffffffc020232a:	5b270713          	addi	a4,a4,1458 # ffffffffc02b28d8 <pages>
ffffffffc020232e:	6885                	lui	a7,0x1
ffffffffc0202330:	00080337          	lui	t1,0x80
ffffffffc0202334:	fff80e37          	lui	t3,0xfff80
ffffffffc0202338:	000b0817          	auipc	a6,0xb0
ffffffffc020233c:	5b080813          	addi	a6,a6,1456 # ffffffffc02b28e8 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202340:	0004b023          	sd	zero,0(s1)
ffffffffc0202344:	b7a5                	j	ffffffffc02022ac <exit_range+0x178>
ffffffffc0202346:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0202348:	adafe0ef          	jal	ra,ffffffffc0200622 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020234c:	000db783          	ld	a5,0(s11)
ffffffffc0202350:	6502                	ld	a0,0(sp)
ffffffffc0202352:	4585                	li	a1,1
ffffffffc0202354:	739c                	ld	a5,32(a5)
ffffffffc0202356:	9782                	jalr	a5
        intr_enable();
ffffffffc0202358:	ac4fe0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc020235c:	000b0717          	auipc	a4,0xb0
ffffffffc0202360:	57c70713          	addi	a4,a4,1404 # ffffffffc02b28d8 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202364:	00043023          	sd	zero,0(s0)
ffffffffc0202368:	bfb5                	j	ffffffffc02022e4 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020236a:	00005697          	auipc	a3,0x5
ffffffffc020236e:	fc668693          	addi	a3,a3,-58 # ffffffffc0207330 <default_pmm_manager+0x160>
ffffffffc0202372:	00004617          	auipc	a2,0x4
ffffffffc0202376:	7c660613          	addi	a2,a2,1990 # ffffffffc0206b38 <commands+0x450>
ffffffffc020237a:	12000593          	li	a1,288
ffffffffc020237e:	00005517          	auipc	a0,0x5
ffffffffc0202382:	fa250513          	addi	a0,a0,-94 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202386:	8f4fe0ef          	jal	ra,ffffffffc020047a <__panic>
    return KADDR(page2pa(page));
ffffffffc020238a:	00005617          	auipc	a2,0x5
ffffffffc020238e:	e7e60613          	addi	a2,a2,-386 # ffffffffc0207208 <default_pmm_manager+0x38>
ffffffffc0202392:	06900593          	li	a1,105
ffffffffc0202396:	00005517          	auipc	a0,0x5
ffffffffc020239a:	e9a50513          	addi	a0,a0,-358 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc020239e:	8dcfe0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc02023a2:	8e3ff0ef          	jal	ra,ffffffffc0201c84 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02023a6:	00005697          	auipc	a3,0x5
ffffffffc02023aa:	fba68693          	addi	a3,a3,-70 # ffffffffc0207360 <default_pmm_manager+0x190>
ffffffffc02023ae:	00004617          	auipc	a2,0x4
ffffffffc02023b2:	78a60613          	addi	a2,a2,1930 # ffffffffc0206b38 <commands+0x450>
ffffffffc02023b6:	12100593          	li	a1,289
ffffffffc02023ba:	00005517          	auipc	a0,0x5
ffffffffc02023be:	f6650513          	addi	a0,a0,-154 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc02023c2:	8b8fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02023c6 <page_remove>:
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc02023c6:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02023c8:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc02023ca:	ec26                	sd	s1,24(sp)
ffffffffc02023cc:	f406                	sd	ra,40(sp)
ffffffffc02023ce:	f022                	sd	s0,32(sp)
ffffffffc02023d0:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02023d2:	9f7ff0ef          	jal	ra,ffffffffc0201dc8 <get_pte>
    if (ptep != NULL) {
ffffffffc02023d6:	c511                	beqz	a0,ffffffffc02023e2 <page_remove+0x1c>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc02023d8:	611c                	ld	a5,0(a0)
ffffffffc02023da:	842a                	mv	s0,a0
ffffffffc02023dc:	0017f713          	andi	a4,a5,1
ffffffffc02023e0:	e711                	bnez	a4,ffffffffc02023ec <page_remove+0x26>
}
ffffffffc02023e2:	70a2                	ld	ra,40(sp)
ffffffffc02023e4:	7402                	ld	s0,32(sp)
ffffffffc02023e6:	64e2                	ld	s1,24(sp)
ffffffffc02023e8:	6145                	addi	sp,sp,48
ffffffffc02023ea:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02023ec:	078a                	slli	a5,a5,0x2
ffffffffc02023ee:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02023f0:	000b0717          	auipc	a4,0xb0
ffffffffc02023f4:	4e073703          	ld	a4,1248(a4) # ffffffffc02b28d0 <npage>
ffffffffc02023f8:	06e7f363          	bgeu	a5,a4,ffffffffc020245e <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc02023fc:	fff80537          	lui	a0,0xfff80
ffffffffc0202400:	97aa                	add	a5,a5,a0
ffffffffc0202402:	079a                	slli	a5,a5,0x6
ffffffffc0202404:	000b0517          	auipc	a0,0xb0
ffffffffc0202408:	4d453503          	ld	a0,1236(a0) # ffffffffc02b28d8 <pages>
ffffffffc020240c:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020240e:	411c                	lw	a5,0(a0)
ffffffffc0202410:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202414:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202416:	cb11                	beqz	a4,ffffffffc020242a <page_remove+0x64>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0202418:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020241c:	12048073          	sfence.vma	s1
}
ffffffffc0202420:	70a2                	ld	ra,40(sp)
ffffffffc0202422:	7402                	ld	s0,32(sp)
ffffffffc0202424:	64e2                	ld	s1,24(sp)
ffffffffc0202426:	6145                	addi	sp,sp,48
ffffffffc0202428:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020242a:	100027f3          	csrr	a5,sstatus
ffffffffc020242e:	8b89                	andi	a5,a5,2
ffffffffc0202430:	eb89                	bnez	a5,ffffffffc0202442 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202432:	000b0797          	auipc	a5,0xb0
ffffffffc0202436:	4ae7b783          	ld	a5,1198(a5) # ffffffffc02b28e0 <pmm_manager>
ffffffffc020243a:	739c                	ld	a5,32(a5)
ffffffffc020243c:	4585                	li	a1,1
ffffffffc020243e:	9782                	jalr	a5
    if (flag) {
ffffffffc0202440:	bfe1                	j	ffffffffc0202418 <page_remove+0x52>
        intr_disable();
ffffffffc0202442:	e42a                	sd	a0,8(sp)
ffffffffc0202444:	9defe0ef          	jal	ra,ffffffffc0200622 <intr_disable>
ffffffffc0202448:	000b0797          	auipc	a5,0xb0
ffffffffc020244c:	4987b783          	ld	a5,1176(a5) # ffffffffc02b28e0 <pmm_manager>
ffffffffc0202450:	739c                	ld	a5,32(a5)
ffffffffc0202452:	6522                	ld	a0,8(sp)
ffffffffc0202454:	4585                	li	a1,1
ffffffffc0202456:	9782                	jalr	a5
        intr_enable();
ffffffffc0202458:	9c4fe0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc020245c:	bf75                	j	ffffffffc0202418 <page_remove+0x52>
ffffffffc020245e:	827ff0ef          	jal	ra,ffffffffc0201c84 <pa2page.part.0>

ffffffffc0202462 <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202462:	7139                	addi	sp,sp,-64
ffffffffc0202464:	e852                	sd	s4,16(sp)
ffffffffc0202466:	8a32                	mv	s4,a2
ffffffffc0202468:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020246a:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc020246c:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020246e:	85d2                	mv	a1,s4
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202470:	f426                	sd	s1,40(sp)
ffffffffc0202472:	fc06                	sd	ra,56(sp)
ffffffffc0202474:	f04a                	sd	s2,32(sp)
ffffffffc0202476:	ec4e                	sd	s3,24(sp)
ffffffffc0202478:	e456                	sd	s5,8(sp)
ffffffffc020247a:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020247c:	94dff0ef          	jal	ra,ffffffffc0201dc8 <get_pte>
    if (ptep == NULL) {
ffffffffc0202480:	c961                	beqz	a0,ffffffffc0202550 <page_insert+0xee>
    page->ref += 1;
ffffffffc0202482:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) {
ffffffffc0202484:	611c                	ld	a5,0(a0)
ffffffffc0202486:	89aa                	mv	s3,a0
ffffffffc0202488:	0016871b          	addiw	a4,a3,1
ffffffffc020248c:	c018                	sw	a4,0(s0)
ffffffffc020248e:	0017f713          	andi	a4,a5,1
ffffffffc0202492:	ef05                	bnez	a4,ffffffffc02024ca <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202494:	000b0717          	auipc	a4,0xb0
ffffffffc0202498:	44473703          	ld	a4,1092(a4) # ffffffffc02b28d8 <pages>
ffffffffc020249c:	8c19                	sub	s0,s0,a4
ffffffffc020249e:	000807b7          	lui	a5,0x80
ffffffffc02024a2:	8419                	srai	s0,s0,0x6
ffffffffc02024a4:	943e                	add	s0,s0,a5
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02024a6:	042a                	slli	s0,s0,0xa
ffffffffc02024a8:	8cc1                	or	s1,s1,s0
ffffffffc02024aa:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02024ae:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ed0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02024b2:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02024b6:	4501                	li	a0,0
}
ffffffffc02024b8:	70e2                	ld	ra,56(sp)
ffffffffc02024ba:	7442                	ld	s0,48(sp)
ffffffffc02024bc:	74a2                	ld	s1,40(sp)
ffffffffc02024be:	7902                	ld	s2,32(sp)
ffffffffc02024c0:	69e2                	ld	s3,24(sp)
ffffffffc02024c2:	6a42                	ld	s4,16(sp)
ffffffffc02024c4:	6aa2                	ld	s5,8(sp)
ffffffffc02024c6:	6121                	addi	sp,sp,64
ffffffffc02024c8:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02024ca:	078a                	slli	a5,a5,0x2
ffffffffc02024cc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02024ce:	000b0717          	auipc	a4,0xb0
ffffffffc02024d2:	40273703          	ld	a4,1026(a4) # ffffffffc02b28d0 <npage>
ffffffffc02024d6:	06e7ff63          	bgeu	a5,a4,ffffffffc0202554 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02024da:	000b0a97          	auipc	s5,0xb0
ffffffffc02024de:	3fea8a93          	addi	s5,s5,1022 # ffffffffc02b28d8 <pages>
ffffffffc02024e2:	000ab703          	ld	a4,0(s5)
ffffffffc02024e6:	fff80937          	lui	s2,0xfff80
ffffffffc02024ea:	993e                	add	s2,s2,a5
ffffffffc02024ec:	091a                	slli	s2,s2,0x6
ffffffffc02024ee:	993a                	add	s2,s2,a4
        if (p == page) {
ffffffffc02024f0:	01240c63          	beq	s0,s2,ffffffffc0202508 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02024f4:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fccd6cc>
ffffffffc02024f8:	fff7869b          	addiw	a3,a5,-1
ffffffffc02024fc:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc0202500:	c691                	beqz	a3,ffffffffc020250c <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202502:	120a0073          	sfence.vma	s4
}
ffffffffc0202506:	bf59                	j	ffffffffc020249c <page_insert+0x3a>
ffffffffc0202508:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc020250a:	bf49                	j	ffffffffc020249c <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020250c:	100027f3          	csrr	a5,sstatus
ffffffffc0202510:	8b89                	andi	a5,a5,2
ffffffffc0202512:	ef91                	bnez	a5,ffffffffc020252e <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0202514:	000b0797          	auipc	a5,0xb0
ffffffffc0202518:	3cc7b783          	ld	a5,972(a5) # ffffffffc02b28e0 <pmm_manager>
ffffffffc020251c:	739c                	ld	a5,32(a5)
ffffffffc020251e:	4585                	li	a1,1
ffffffffc0202520:	854a                	mv	a0,s2
ffffffffc0202522:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202524:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202528:	120a0073          	sfence.vma	s4
ffffffffc020252c:	bf85                	j	ffffffffc020249c <page_insert+0x3a>
        intr_disable();
ffffffffc020252e:	8f4fe0ef          	jal	ra,ffffffffc0200622 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202532:	000b0797          	auipc	a5,0xb0
ffffffffc0202536:	3ae7b783          	ld	a5,942(a5) # ffffffffc02b28e0 <pmm_manager>
ffffffffc020253a:	739c                	ld	a5,32(a5)
ffffffffc020253c:	4585                	li	a1,1
ffffffffc020253e:	854a                	mv	a0,s2
ffffffffc0202540:	9782                	jalr	a5
        intr_enable();
ffffffffc0202542:	8dafe0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc0202546:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020254a:	120a0073          	sfence.vma	s4
ffffffffc020254e:	b7b9                	j	ffffffffc020249c <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0202550:	5571                	li	a0,-4
ffffffffc0202552:	b79d                	j	ffffffffc02024b8 <page_insert+0x56>
ffffffffc0202554:	f30ff0ef          	jal	ra,ffffffffc0201c84 <pa2page.part.0>

ffffffffc0202558 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202558:	00005797          	auipc	a5,0x5
ffffffffc020255c:	c7878793          	addi	a5,a5,-904 # ffffffffc02071d0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202560:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0202562:	711d                	addi	sp,sp,-96
ffffffffc0202564:	ec5e                	sd	s7,24(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202566:	00005517          	auipc	a0,0x5
ffffffffc020256a:	e1250513          	addi	a0,a0,-494 # ffffffffc0207378 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc020256e:	000b0b97          	auipc	s7,0xb0
ffffffffc0202572:	372b8b93          	addi	s7,s7,882 # ffffffffc02b28e0 <pmm_manager>
void pmm_init(void) {
ffffffffc0202576:	ec86                	sd	ra,88(sp)
ffffffffc0202578:	e4a6                	sd	s1,72(sp)
ffffffffc020257a:	fc4e                	sd	s3,56(sp)
ffffffffc020257c:	f05a                	sd	s6,32(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020257e:	00fbb023          	sd	a5,0(s7)
void pmm_init(void) {
ffffffffc0202582:	e8a2                	sd	s0,80(sp)
ffffffffc0202584:	e0ca                	sd	s2,64(sp)
ffffffffc0202586:	f852                	sd	s4,48(sp)
ffffffffc0202588:	f456                	sd	s5,40(sp)
ffffffffc020258a:	e862                	sd	s8,16(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020258c:	bf5fd0ef          	jal	ra,ffffffffc0200180 <cprintf>
    pmm_manager->init();
ffffffffc0202590:	000bb783          	ld	a5,0(s7)
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0202594:	000b0997          	auipc	s3,0xb0
ffffffffc0202598:	35498993          	addi	s3,s3,852 # ffffffffc02b28e8 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc020259c:	000b0497          	auipc	s1,0xb0
ffffffffc02025a0:	33448493          	addi	s1,s1,820 # ffffffffc02b28d0 <npage>
    pmm_manager->init();
ffffffffc02025a4:	679c                	ld	a5,8(a5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02025a6:	000b0b17          	auipc	s6,0xb0
ffffffffc02025aa:	332b0b13          	addi	s6,s6,818 # ffffffffc02b28d8 <pages>
    pmm_manager->init();
ffffffffc02025ae:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02025b0:	57f5                	li	a5,-3
ffffffffc02025b2:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc02025b4:	00005517          	auipc	a0,0x5
ffffffffc02025b8:	ddc50513          	addi	a0,a0,-548 # ffffffffc0207390 <default_pmm_manager+0x1c0>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02025bc:	00f9b023          	sd	a5,0(s3)
    cprintf("physcial memory map:\n");
ffffffffc02025c0:	bc1fd0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02025c4:	46c5                	li	a3,17
ffffffffc02025c6:	06ee                	slli	a3,a3,0x1b
ffffffffc02025c8:	40100613          	li	a2,1025
ffffffffc02025cc:	07e005b7          	lui	a1,0x7e00
ffffffffc02025d0:	16fd                	addi	a3,a3,-1
ffffffffc02025d2:	0656                	slli	a2,a2,0x15
ffffffffc02025d4:	00005517          	auipc	a0,0x5
ffffffffc02025d8:	dd450513          	addi	a0,a0,-556 # ffffffffc02073a8 <default_pmm_manager+0x1d8>
ffffffffc02025dc:	ba5fd0ef          	jal	ra,ffffffffc0200180 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02025e0:	777d                	lui	a4,0xfffff
ffffffffc02025e2:	000b1797          	auipc	a5,0xb1
ffffffffc02025e6:	35178793          	addi	a5,a5,849 # ffffffffc02b3933 <end+0xfff>
ffffffffc02025ea:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc02025ec:	00088737          	lui	a4,0x88
ffffffffc02025f0:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02025f2:	00fb3023          	sd	a5,0(s6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02025f6:	4701                	li	a4,0
ffffffffc02025f8:	4585                	li	a1,1
ffffffffc02025fa:	fff80837          	lui	a6,0xfff80
ffffffffc02025fe:	a019                	j	ffffffffc0202604 <pmm_init+0xac>
        SetPageReserved(pages + i);
ffffffffc0202600:	000b3783          	ld	a5,0(s6)
ffffffffc0202604:	00671693          	slli	a3,a4,0x6
ffffffffc0202608:	97b6                	add	a5,a5,a3
ffffffffc020260a:	07a1                	addi	a5,a5,8
ffffffffc020260c:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0202610:	6090                	ld	a2,0(s1)
ffffffffc0202612:	0705                	addi	a4,a4,1
ffffffffc0202614:	010607b3          	add	a5,a2,a6
ffffffffc0202618:	fef764e3          	bltu	a4,a5,ffffffffc0202600 <pmm_init+0xa8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020261c:	000b3503          	ld	a0,0(s6)
ffffffffc0202620:	079a                	slli	a5,a5,0x6
ffffffffc0202622:	c0200737          	lui	a4,0xc0200
ffffffffc0202626:	00f506b3          	add	a3,a0,a5
ffffffffc020262a:	60e6e563          	bltu	a3,a4,ffffffffc0202c34 <pmm_init+0x6dc>
ffffffffc020262e:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) {
ffffffffc0202632:	4745                	li	a4,17
ffffffffc0202634:	076e                	slli	a4,a4,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202636:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) {
ffffffffc0202638:	4ae6e563          	bltu	a3,a4,ffffffffc0202ae2 <pmm_init+0x58a>
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc020263c:	00005517          	auipc	a0,0x5
ffffffffc0202640:	d9450513          	addi	a0,a0,-620 # ffffffffc02073d0 <default_pmm_manager+0x200>
ffffffffc0202644:	b3dfd0ef          	jal	ra,ffffffffc0200180 <cprintf>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0202648:	000bb783          	ld	a5,0(s7)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc020264c:	000b0917          	auipc	s2,0xb0
ffffffffc0202650:	27c90913          	addi	s2,s2,636 # ffffffffc02b28c8 <boot_pgdir>
    pmm_manager->check();
ffffffffc0202654:	7b9c                	ld	a5,48(a5)
ffffffffc0202656:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202658:	00005517          	auipc	a0,0x5
ffffffffc020265c:	d9050513          	addi	a0,a0,-624 # ffffffffc02073e8 <default_pmm_manager+0x218>
ffffffffc0202660:	b21fd0ef          	jal	ra,ffffffffc0200180 <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0202664:	00009697          	auipc	a3,0x9
ffffffffc0202668:	99c68693          	addi	a3,a3,-1636 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc020266c:	00d93023          	sd	a3,0(s2)
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0202670:	c02007b7          	lui	a5,0xc0200
ffffffffc0202674:	5cf6ec63          	bltu	a3,a5,ffffffffc0202c4c <pmm_init+0x6f4>
ffffffffc0202678:	0009b783          	ld	a5,0(s3)
ffffffffc020267c:	8e9d                	sub	a3,a3,a5
ffffffffc020267e:	000b0797          	auipc	a5,0xb0
ffffffffc0202682:	24d7b123          	sd	a3,578(a5) # ffffffffc02b28c0 <boot_cr3>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202686:	100027f3          	csrr	a5,sstatus
ffffffffc020268a:	8b89                	andi	a5,a5,2
ffffffffc020268c:	48079263          	bnez	a5,ffffffffc0202b10 <pmm_init+0x5b8>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202690:	000bb783          	ld	a5,0(s7)
ffffffffc0202694:	779c                	ld	a5,40(a5)
ffffffffc0202696:	9782                	jalr	a5
ffffffffc0202698:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020269a:	6098                	ld	a4,0(s1)
ffffffffc020269c:	c80007b7          	lui	a5,0xc8000
ffffffffc02026a0:	83b1                	srli	a5,a5,0xc
ffffffffc02026a2:	5ee7e163          	bltu	a5,a4,ffffffffc0202c84 <pmm_init+0x72c>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02026a6:	00093503          	ld	a0,0(s2)
ffffffffc02026aa:	5a050d63          	beqz	a0,ffffffffc0202c64 <pmm_init+0x70c>
ffffffffc02026ae:	03451793          	slli	a5,a0,0x34
ffffffffc02026b2:	5a079963          	bnez	a5,ffffffffc0202c64 <pmm_init+0x70c>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02026b6:	4601                	li	a2,0
ffffffffc02026b8:	4581                	li	a1,0
ffffffffc02026ba:	8e1ff0ef          	jal	ra,ffffffffc0201f9a <get_page>
ffffffffc02026be:	62051563          	bnez	a0,ffffffffc0202ce8 <pmm_init+0x790>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc02026c2:	4505                	li	a0,1
ffffffffc02026c4:	df8ff0ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc02026c8:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc02026ca:	00093503          	ld	a0,0(s2)
ffffffffc02026ce:	4681                	li	a3,0
ffffffffc02026d0:	4601                	li	a2,0
ffffffffc02026d2:	85d2                	mv	a1,s4
ffffffffc02026d4:	d8fff0ef          	jal	ra,ffffffffc0202462 <page_insert>
ffffffffc02026d8:	5e051863          	bnez	a0,ffffffffc0202cc8 <pmm_init+0x770>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc02026dc:	00093503          	ld	a0,0(s2)
ffffffffc02026e0:	4601                	li	a2,0
ffffffffc02026e2:	4581                	li	a1,0
ffffffffc02026e4:	ee4ff0ef          	jal	ra,ffffffffc0201dc8 <get_pte>
ffffffffc02026e8:	5c050063          	beqz	a0,ffffffffc0202ca8 <pmm_init+0x750>
    assert(pte2page(*ptep) == p1);
ffffffffc02026ec:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02026ee:	0017f713          	andi	a4,a5,1
ffffffffc02026f2:	5a070963          	beqz	a4,ffffffffc0202ca4 <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc02026f6:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02026f8:	078a                	slli	a5,a5,0x2
ffffffffc02026fa:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02026fc:	52e7fa63          	bgeu	a5,a4,ffffffffc0202c30 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202700:	000b3683          	ld	a3,0(s6)
ffffffffc0202704:	fff80637          	lui	a2,0xfff80
ffffffffc0202708:	97b2                	add	a5,a5,a2
ffffffffc020270a:	079a                	slli	a5,a5,0x6
ffffffffc020270c:	97b6                	add	a5,a5,a3
ffffffffc020270e:	10fa16e3          	bne	s4,a5,ffffffffc020301a <pmm_init+0xac2>
    assert(page_ref(p1) == 1);
ffffffffc0202712:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc0202716:	4785                	li	a5,1
ffffffffc0202718:	12f69de3          	bne	a3,a5,ffffffffc0203052 <pmm_init+0xafa>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc020271c:	00093503          	ld	a0,0(s2)
ffffffffc0202720:	77fd                	lui	a5,0xfffff
ffffffffc0202722:	6114                	ld	a3,0(a0)
ffffffffc0202724:	068a                	slli	a3,a3,0x2
ffffffffc0202726:	8efd                	and	a3,a3,a5
ffffffffc0202728:	00c6d613          	srli	a2,a3,0xc
ffffffffc020272c:	10e677e3          	bgeu	a2,a4,ffffffffc020303a <pmm_init+0xae2>
ffffffffc0202730:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202734:	96e2                	add	a3,a3,s8
ffffffffc0202736:	0006ba83          	ld	s5,0(a3)
ffffffffc020273a:	0a8a                	slli	s5,s5,0x2
ffffffffc020273c:	00fafab3          	and	s5,s5,a5
ffffffffc0202740:	00cad793          	srli	a5,s5,0xc
ffffffffc0202744:	62e7f263          	bgeu	a5,a4,ffffffffc0202d68 <pmm_init+0x810>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202748:	4601                	li	a2,0
ffffffffc020274a:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020274c:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc020274e:	e7aff0ef          	jal	ra,ffffffffc0201dc8 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202752:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202754:	5f551a63          	bne	a0,s5,ffffffffc0202d48 <pmm_init+0x7f0>

    p2 = alloc_page();
ffffffffc0202758:	4505                	li	a0,1
ffffffffc020275a:	d62ff0ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc020275e:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202760:	00093503          	ld	a0,0(s2)
ffffffffc0202764:	46d1                	li	a3,20
ffffffffc0202766:	6605                	lui	a2,0x1
ffffffffc0202768:	85d6                	mv	a1,s5
ffffffffc020276a:	cf9ff0ef          	jal	ra,ffffffffc0202462 <page_insert>
ffffffffc020276e:	58051d63          	bnez	a0,ffffffffc0202d08 <pmm_init+0x7b0>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202772:	00093503          	ld	a0,0(s2)
ffffffffc0202776:	4601                	li	a2,0
ffffffffc0202778:	6585                	lui	a1,0x1
ffffffffc020277a:	e4eff0ef          	jal	ra,ffffffffc0201dc8 <get_pte>
ffffffffc020277e:	0e050ae3          	beqz	a0,ffffffffc0203072 <pmm_init+0xb1a>
    assert(*ptep & PTE_U);
ffffffffc0202782:	611c                	ld	a5,0(a0)
ffffffffc0202784:	0107f713          	andi	a4,a5,16
ffffffffc0202788:	6e070d63          	beqz	a4,ffffffffc0202e82 <pmm_init+0x92a>
    assert(*ptep & PTE_W);
ffffffffc020278c:	8b91                	andi	a5,a5,4
ffffffffc020278e:	6a078a63          	beqz	a5,ffffffffc0202e42 <pmm_init+0x8ea>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0202792:	00093503          	ld	a0,0(s2)
ffffffffc0202796:	611c                	ld	a5,0(a0)
ffffffffc0202798:	8bc1                	andi	a5,a5,16
ffffffffc020279a:	68078463          	beqz	a5,ffffffffc0202e22 <pmm_init+0x8ca>
    assert(page_ref(p2) == 1);
ffffffffc020279e:	000aa703          	lw	a4,0(s5)
ffffffffc02027a2:	4785                	li	a5,1
ffffffffc02027a4:	58f71263          	bne	a4,a5,ffffffffc0202d28 <pmm_init+0x7d0>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02027a8:	4681                	li	a3,0
ffffffffc02027aa:	6605                	lui	a2,0x1
ffffffffc02027ac:	85d2                	mv	a1,s4
ffffffffc02027ae:	cb5ff0ef          	jal	ra,ffffffffc0202462 <page_insert>
ffffffffc02027b2:	62051863          	bnez	a0,ffffffffc0202de2 <pmm_init+0x88a>
    assert(page_ref(p1) == 2);
ffffffffc02027b6:	000a2703          	lw	a4,0(s4)
ffffffffc02027ba:	4789                	li	a5,2
ffffffffc02027bc:	60f71363          	bne	a4,a5,ffffffffc0202dc2 <pmm_init+0x86a>
    assert(page_ref(p2) == 0);
ffffffffc02027c0:	000aa783          	lw	a5,0(s5)
ffffffffc02027c4:	5c079f63          	bnez	a5,ffffffffc0202da2 <pmm_init+0x84a>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02027c8:	00093503          	ld	a0,0(s2)
ffffffffc02027cc:	4601                	li	a2,0
ffffffffc02027ce:	6585                	lui	a1,0x1
ffffffffc02027d0:	df8ff0ef          	jal	ra,ffffffffc0201dc8 <get_pte>
ffffffffc02027d4:	5a050763          	beqz	a0,ffffffffc0202d82 <pmm_init+0x82a>
    assert(pte2page(*ptep) == p1);
ffffffffc02027d8:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02027da:	00177793          	andi	a5,a4,1
ffffffffc02027de:	4c078363          	beqz	a5,ffffffffc0202ca4 <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc02027e2:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02027e4:	00271793          	slli	a5,a4,0x2
ffffffffc02027e8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02027ea:	44d7f363          	bgeu	a5,a3,ffffffffc0202c30 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc02027ee:	000b3683          	ld	a3,0(s6)
ffffffffc02027f2:	fff80637          	lui	a2,0xfff80
ffffffffc02027f6:	97b2                	add	a5,a5,a2
ffffffffc02027f8:	079a                	slli	a5,a5,0x6
ffffffffc02027fa:	97b6                	add	a5,a5,a3
ffffffffc02027fc:	6efa1363          	bne	s4,a5,ffffffffc0202ee2 <pmm_init+0x98a>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202800:	8b41                	andi	a4,a4,16
ffffffffc0202802:	6c071063          	bnez	a4,ffffffffc0202ec2 <pmm_init+0x96a>

    page_remove(boot_pgdir, 0x0);
ffffffffc0202806:	00093503          	ld	a0,0(s2)
ffffffffc020280a:	4581                	li	a1,0
ffffffffc020280c:	bbbff0ef          	jal	ra,ffffffffc02023c6 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202810:	000a2703          	lw	a4,0(s4)
ffffffffc0202814:	4785                	li	a5,1
ffffffffc0202816:	68f71663          	bne	a4,a5,ffffffffc0202ea2 <pmm_init+0x94a>
    assert(page_ref(p2) == 0);
ffffffffc020281a:	000aa783          	lw	a5,0(s5)
ffffffffc020281e:	74079e63          	bnez	a5,ffffffffc0202f7a <pmm_init+0xa22>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0202822:	00093503          	ld	a0,0(s2)
ffffffffc0202826:	6585                	lui	a1,0x1
ffffffffc0202828:	b9fff0ef          	jal	ra,ffffffffc02023c6 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc020282c:	000a2783          	lw	a5,0(s4)
ffffffffc0202830:	72079563          	bnez	a5,ffffffffc0202f5a <pmm_init+0xa02>
    assert(page_ref(p2) == 0);
ffffffffc0202834:	000aa783          	lw	a5,0(s5)
ffffffffc0202838:	70079163          	bnez	a5,ffffffffc0202f3a <pmm_init+0x9e2>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc020283c:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0202840:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202842:	000a3683          	ld	a3,0(s4)
ffffffffc0202846:	068a                	slli	a3,a3,0x2
ffffffffc0202848:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc020284a:	3ee6f363          	bgeu	a3,a4,ffffffffc0202c30 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc020284e:	fff807b7          	lui	a5,0xfff80
ffffffffc0202852:	000b3503          	ld	a0,0(s6)
ffffffffc0202856:	96be                	add	a3,a3,a5
ffffffffc0202858:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc020285a:	00d507b3          	add	a5,a0,a3
ffffffffc020285e:	4390                	lw	a2,0(a5)
ffffffffc0202860:	4785                	li	a5,1
ffffffffc0202862:	6af61c63          	bne	a2,a5,ffffffffc0202f1a <pmm_init+0x9c2>
    return page - pages + nbase;
ffffffffc0202866:	8699                	srai	a3,a3,0x6
ffffffffc0202868:	000805b7          	lui	a1,0x80
ffffffffc020286c:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc020286e:	00c69613          	slli	a2,a3,0xc
ffffffffc0202872:	8231                	srli	a2,a2,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202874:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202876:	68e67663          	bgeu	a2,a4,ffffffffc0202f02 <pmm_init+0x9aa>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc020287a:	0009b603          	ld	a2,0(s3)
ffffffffc020287e:	96b2                	add	a3,a3,a2
    return pa2page(PDE_ADDR(pde));
ffffffffc0202880:	629c                	ld	a5,0(a3)
ffffffffc0202882:	078a                	slli	a5,a5,0x2
ffffffffc0202884:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202886:	3ae7f563          	bgeu	a5,a4,ffffffffc0202c30 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc020288a:	8f8d                	sub	a5,a5,a1
ffffffffc020288c:	079a                	slli	a5,a5,0x6
ffffffffc020288e:	953e                	add	a0,a0,a5
ffffffffc0202890:	100027f3          	csrr	a5,sstatus
ffffffffc0202894:	8b89                	andi	a5,a5,2
ffffffffc0202896:	2c079763          	bnez	a5,ffffffffc0202b64 <pmm_init+0x60c>
        pmm_manager->free_pages(base, n);
ffffffffc020289a:	000bb783          	ld	a5,0(s7)
ffffffffc020289e:	4585                	li	a1,1
ffffffffc02028a0:	739c                	ld	a5,32(a5)
ffffffffc02028a2:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02028a4:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc02028a8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02028aa:	078a                	slli	a5,a5,0x2
ffffffffc02028ac:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02028ae:	38e7f163          	bgeu	a5,a4,ffffffffc0202c30 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc02028b2:	000b3503          	ld	a0,0(s6)
ffffffffc02028b6:	fff80737          	lui	a4,0xfff80
ffffffffc02028ba:	97ba                	add	a5,a5,a4
ffffffffc02028bc:	079a                	slli	a5,a5,0x6
ffffffffc02028be:	953e                	add	a0,a0,a5
ffffffffc02028c0:	100027f3          	csrr	a5,sstatus
ffffffffc02028c4:	8b89                	andi	a5,a5,2
ffffffffc02028c6:	28079363          	bnez	a5,ffffffffc0202b4c <pmm_init+0x5f4>
ffffffffc02028ca:	000bb783          	ld	a5,0(s7)
ffffffffc02028ce:	4585                	li	a1,1
ffffffffc02028d0:	739c                	ld	a5,32(a5)
ffffffffc02028d2:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc02028d4:	00093783          	ld	a5,0(s2)
ffffffffc02028d8:	0007b023          	sd	zero,0(a5) # fffffffffff80000 <end+0x3fccd6cc>
  asm volatile("sfence.vma");
ffffffffc02028dc:	12000073          	sfence.vma
ffffffffc02028e0:	100027f3          	csrr	a5,sstatus
ffffffffc02028e4:	8b89                	andi	a5,a5,2
ffffffffc02028e6:	24079963          	bnez	a5,ffffffffc0202b38 <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc02028ea:	000bb783          	ld	a5,0(s7)
ffffffffc02028ee:	779c                	ld	a5,40(a5)
ffffffffc02028f0:	9782                	jalr	a5
ffffffffc02028f2:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc02028f4:	71441363          	bne	s0,s4,ffffffffc0202ffa <pmm_init+0xaa2>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc02028f8:	00005517          	auipc	a0,0x5
ffffffffc02028fc:	dd850513          	addi	a0,a0,-552 # ffffffffc02076d0 <default_pmm_manager+0x500>
ffffffffc0202900:	881fd0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc0202904:	100027f3          	csrr	a5,sstatus
ffffffffc0202908:	8b89                	andi	a5,a5,2
ffffffffc020290a:	20079d63          	bnez	a5,ffffffffc0202b24 <pmm_init+0x5cc>
        ret = pmm_manager->nr_free_pages();
ffffffffc020290e:	000bb783          	ld	a5,0(s7)
ffffffffc0202912:	779c                	ld	a5,40(a5)
ffffffffc0202914:	9782                	jalr	a5
ffffffffc0202916:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0202918:	6098                	ld	a4,0(s1)
ffffffffc020291a:	c0200437          	lui	s0,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020291e:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0202920:	00c71793          	slli	a5,a4,0xc
ffffffffc0202924:	6a05                	lui	s4,0x1
ffffffffc0202926:	02f47c63          	bgeu	s0,a5,ffffffffc020295e <pmm_init+0x406>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020292a:	00c45793          	srli	a5,s0,0xc
ffffffffc020292e:	00093503          	ld	a0,0(s2)
ffffffffc0202932:	2ee7f263          	bgeu	a5,a4,ffffffffc0202c16 <pmm_init+0x6be>
ffffffffc0202936:	0009b583          	ld	a1,0(s3)
ffffffffc020293a:	4601                	li	a2,0
ffffffffc020293c:	95a2                	add	a1,a1,s0
ffffffffc020293e:	c8aff0ef          	jal	ra,ffffffffc0201dc8 <get_pte>
ffffffffc0202942:	2a050a63          	beqz	a0,ffffffffc0202bf6 <pmm_init+0x69e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202946:	611c                	ld	a5,0(a0)
ffffffffc0202948:	078a                	slli	a5,a5,0x2
ffffffffc020294a:	0157f7b3          	and	a5,a5,s5
ffffffffc020294e:	28879463          	bne	a5,s0,ffffffffc0202bd6 <pmm_init+0x67e>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0202952:	6098                	ld	a4,0(s1)
ffffffffc0202954:	9452                	add	s0,s0,s4
ffffffffc0202956:	00c71793          	slli	a5,a4,0xc
ffffffffc020295a:	fcf468e3          	bltu	s0,a5,ffffffffc020292a <pmm_init+0x3d2>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc020295e:	00093783          	ld	a5,0(s2)
ffffffffc0202962:	639c                	ld	a5,0(a5)
ffffffffc0202964:	66079b63          	bnez	a5,ffffffffc0202fda <pmm_init+0xa82>

    struct Page *p;
    p = alloc_page();
ffffffffc0202968:	4505                	li	a0,1
ffffffffc020296a:	b52ff0ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc020296e:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202970:	00093503          	ld	a0,0(s2)
ffffffffc0202974:	4699                	li	a3,6
ffffffffc0202976:	10000613          	li	a2,256
ffffffffc020297a:	85d6                	mv	a1,s5
ffffffffc020297c:	ae7ff0ef          	jal	ra,ffffffffc0202462 <page_insert>
ffffffffc0202980:	62051d63          	bnez	a0,ffffffffc0202fba <pmm_init+0xa62>
    assert(page_ref(p) == 1);
ffffffffc0202984:	000aa703          	lw	a4,0(s5) # fffffffffffff000 <end+0x3fd4c6cc>
ffffffffc0202988:	4785                	li	a5,1
ffffffffc020298a:	60f71863          	bne	a4,a5,ffffffffc0202f9a <pmm_init+0xa42>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020298e:	00093503          	ld	a0,0(s2)
ffffffffc0202992:	6405                	lui	s0,0x1
ffffffffc0202994:	4699                	li	a3,6
ffffffffc0202996:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8ab8>
ffffffffc020299a:	85d6                	mv	a1,s5
ffffffffc020299c:	ac7ff0ef          	jal	ra,ffffffffc0202462 <page_insert>
ffffffffc02029a0:	46051163          	bnez	a0,ffffffffc0202e02 <pmm_init+0x8aa>
    assert(page_ref(p) == 2);
ffffffffc02029a4:	000aa703          	lw	a4,0(s5)
ffffffffc02029a8:	4789                	li	a5,2
ffffffffc02029aa:	72f71463          	bne	a4,a5,ffffffffc02030d2 <pmm_init+0xb7a>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02029ae:	00005597          	auipc	a1,0x5
ffffffffc02029b2:	e5a58593          	addi	a1,a1,-422 # ffffffffc0207808 <default_pmm_manager+0x638>
ffffffffc02029b6:	10000513          	li	a0,256
ffffffffc02029ba:	253030ef          	jal	ra,ffffffffc020640c <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02029be:	10040593          	addi	a1,s0,256
ffffffffc02029c2:	10000513          	li	a0,256
ffffffffc02029c6:	259030ef          	jal	ra,ffffffffc020641e <strcmp>
ffffffffc02029ca:	6e051463          	bnez	a0,ffffffffc02030b2 <pmm_init+0xb5a>
    return page - pages + nbase;
ffffffffc02029ce:	000b3683          	ld	a3,0(s6)
ffffffffc02029d2:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc02029d6:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc02029d8:	40da86b3          	sub	a3,s5,a3
ffffffffc02029dc:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02029de:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc02029e0:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02029e2:	8031                	srli	s0,s0,0xc
ffffffffc02029e4:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc02029e8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02029ea:	50f77c63          	bgeu	a4,a5,ffffffffc0202f02 <pmm_init+0x9aa>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02029ee:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc02029f2:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02029f6:	96be                	add	a3,a3,a5
ffffffffc02029f8:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc02029fc:	1db030ef          	jal	ra,ffffffffc02063d6 <strlen>
ffffffffc0202a00:	68051963          	bnez	a0,ffffffffc0203092 <pmm_init+0xb3a>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0202a04:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0202a08:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a0a:	000a3683          	ld	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc0202a0e:	068a                	slli	a3,a3,0x2
ffffffffc0202a10:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202a12:	20f6ff63          	bgeu	a3,a5,ffffffffc0202c30 <pmm_init+0x6d8>
    return KADDR(page2pa(page));
ffffffffc0202a16:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a18:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202a1a:	4ef47463          	bgeu	s0,a5,ffffffffc0202f02 <pmm_init+0x9aa>
ffffffffc0202a1e:	0009b403          	ld	s0,0(s3)
ffffffffc0202a22:	9436                	add	s0,s0,a3
ffffffffc0202a24:	100027f3          	csrr	a5,sstatus
ffffffffc0202a28:	8b89                	andi	a5,a5,2
ffffffffc0202a2a:	18079b63          	bnez	a5,ffffffffc0202bc0 <pmm_init+0x668>
        pmm_manager->free_pages(base, n);
ffffffffc0202a2e:	000bb783          	ld	a5,0(s7)
ffffffffc0202a32:	4585                	li	a1,1
ffffffffc0202a34:	8556                	mv	a0,s5
ffffffffc0202a36:	739c                	ld	a5,32(a5)
ffffffffc0202a38:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a3a:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0202a3c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a3e:	078a                	slli	a5,a5,0x2
ffffffffc0202a40:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202a42:	1ee7f763          	bgeu	a5,a4,ffffffffc0202c30 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a46:	000b3503          	ld	a0,0(s6)
ffffffffc0202a4a:	fff80737          	lui	a4,0xfff80
ffffffffc0202a4e:	97ba                	add	a5,a5,a4
ffffffffc0202a50:	079a                	slli	a5,a5,0x6
ffffffffc0202a52:	953e                	add	a0,a0,a5
ffffffffc0202a54:	100027f3          	csrr	a5,sstatus
ffffffffc0202a58:	8b89                	andi	a5,a5,2
ffffffffc0202a5a:	14079763          	bnez	a5,ffffffffc0202ba8 <pmm_init+0x650>
ffffffffc0202a5e:	000bb783          	ld	a5,0(s7)
ffffffffc0202a62:	4585                	li	a1,1
ffffffffc0202a64:	739c                	ld	a5,32(a5)
ffffffffc0202a66:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a68:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc0202a6c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a6e:	078a                	slli	a5,a5,0x2
ffffffffc0202a70:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202a72:	1ae7ff63          	bgeu	a5,a4,ffffffffc0202c30 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a76:	000b3503          	ld	a0,0(s6)
ffffffffc0202a7a:	fff80737          	lui	a4,0xfff80
ffffffffc0202a7e:	97ba                	add	a5,a5,a4
ffffffffc0202a80:	079a                	slli	a5,a5,0x6
ffffffffc0202a82:	953e                	add	a0,a0,a5
ffffffffc0202a84:	100027f3          	csrr	a5,sstatus
ffffffffc0202a88:	8b89                	andi	a5,a5,2
ffffffffc0202a8a:	10079363          	bnez	a5,ffffffffc0202b90 <pmm_init+0x638>
ffffffffc0202a8e:	000bb783          	ld	a5,0(s7)
ffffffffc0202a92:	4585                	li	a1,1
ffffffffc0202a94:	739c                	ld	a5,32(a5)
ffffffffc0202a96:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0202a98:	00093783          	ld	a5,0(s2)
ffffffffc0202a9c:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc0202aa0:	12000073          	sfence.vma
ffffffffc0202aa4:	100027f3          	csrr	a5,sstatus
ffffffffc0202aa8:	8b89                	andi	a5,a5,2
ffffffffc0202aaa:	0c079963          	bnez	a5,ffffffffc0202b7c <pmm_init+0x624>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202aae:	000bb783          	ld	a5,0(s7)
ffffffffc0202ab2:	779c                	ld	a5,40(a5)
ffffffffc0202ab4:	9782                	jalr	a5
ffffffffc0202ab6:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0202ab8:	3a8c1563          	bne	s8,s0,ffffffffc0202e62 <pmm_init+0x90a>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202abc:	00005517          	auipc	a0,0x5
ffffffffc0202ac0:	dc450513          	addi	a0,a0,-572 # ffffffffc0207880 <default_pmm_manager+0x6b0>
ffffffffc0202ac4:	ebcfd0ef          	jal	ra,ffffffffc0200180 <cprintf>
}
ffffffffc0202ac8:	6446                	ld	s0,80(sp)
ffffffffc0202aca:	60e6                	ld	ra,88(sp)
ffffffffc0202acc:	64a6                	ld	s1,72(sp)
ffffffffc0202ace:	6906                	ld	s2,64(sp)
ffffffffc0202ad0:	79e2                	ld	s3,56(sp)
ffffffffc0202ad2:	7a42                	ld	s4,48(sp)
ffffffffc0202ad4:	7aa2                	ld	s5,40(sp)
ffffffffc0202ad6:	7b02                	ld	s6,32(sp)
ffffffffc0202ad8:	6be2                	ld	s7,24(sp)
ffffffffc0202ada:	6c42                	ld	s8,16(sp)
ffffffffc0202adc:	6125                	addi	sp,sp,96
    kmalloc_init();
ffffffffc0202ade:	fddfe06f          	j	ffffffffc0201aba <kmalloc_init>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202ae2:	6785                	lui	a5,0x1
ffffffffc0202ae4:	17fd                	addi	a5,a5,-1
ffffffffc0202ae6:	96be                	add	a3,a3,a5
ffffffffc0202ae8:	77fd                	lui	a5,0xfffff
ffffffffc0202aea:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage) {
ffffffffc0202aec:	00c7d693          	srli	a3,a5,0xc
ffffffffc0202af0:	14c6f063          	bgeu	a3,a2,ffffffffc0202c30 <pmm_init+0x6d8>
    pmm_manager->init_memmap(base, n);
ffffffffc0202af4:	000bb603          	ld	a2,0(s7)
    return &pages[PPN(pa) - nbase];
ffffffffc0202af8:	96c2                	add	a3,a3,a6
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202afa:	40f707b3          	sub	a5,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202afe:	6a10                	ld	a2,16(a2)
ffffffffc0202b00:	069a                	slli	a3,a3,0x6
ffffffffc0202b02:	00c7d593          	srli	a1,a5,0xc
ffffffffc0202b06:	9536                	add	a0,a0,a3
ffffffffc0202b08:	9602                	jalr	a2
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0202b0a:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202b0e:	b63d                	j	ffffffffc020263c <pmm_init+0xe4>
        intr_disable();
ffffffffc0202b10:	b13fd0ef          	jal	ra,ffffffffc0200622 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b14:	000bb783          	ld	a5,0(s7)
ffffffffc0202b18:	779c                	ld	a5,40(a5)
ffffffffc0202b1a:	9782                	jalr	a5
ffffffffc0202b1c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202b1e:	afffd0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc0202b22:	bea5                	j	ffffffffc020269a <pmm_init+0x142>
        intr_disable();
ffffffffc0202b24:	afffd0ef          	jal	ra,ffffffffc0200622 <intr_disable>
ffffffffc0202b28:	000bb783          	ld	a5,0(s7)
ffffffffc0202b2c:	779c                	ld	a5,40(a5)
ffffffffc0202b2e:	9782                	jalr	a5
ffffffffc0202b30:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202b32:	aebfd0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc0202b36:	b3cd                	j	ffffffffc0202918 <pmm_init+0x3c0>
        intr_disable();
ffffffffc0202b38:	aebfd0ef          	jal	ra,ffffffffc0200622 <intr_disable>
ffffffffc0202b3c:	000bb783          	ld	a5,0(s7)
ffffffffc0202b40:	779c                	ld	a5,40(a5)
ffffffffc0202b42:	9782                	jalr	a5
ffffffffc0202b44:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202b46:	ad7fd0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc0202b4a:	b36d                	j	ffffffffc02028f4 <pmm_init+0x39c>
ffffffffc0202b4c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202b4e:	ad5fd0ef          	jal	ra,ffffffffc0200622 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202b52:	000bb783          	ld	a5,0(s7)
ffffffffc0202b56:	6522                	ld	a0,8(sp)
ffffffffc0202b58:	4585                	li	a1,1
ffffffffc0202b5a:	739c                	ld	a5,32(a5)
ffffffffc0202b5c:	9782                	jalr	a5
        intr_enable();
ffffffffc0202b5e:	abffd0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc0202b62:	bb8d                	j	ffffffffc02028d4 <pmm_init+0x37c>
ffffffffc0202b64:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202b66:	abdfd0ef          	jal	ra,ffffffffc0200622 <intr_disable>
ffffffffc0202b6a:	000bb783          	ld	a5,0(s7)
ffffffffc0202b6e:	6522                	ld	a0,8(sp)
ffffffffc0202b70:	4585                	li	a1,1
ffffffffc0202b72:	739c                	ld	a5,32(a5)
ffffffffc0202b74:	9782                	jalr	a5
        intr_enable();
ffffffffc0202b76:	aa7fd0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc0202b7a:	b32d                	j	ffffffffc02028a4 <pmm_init+0x34c>
        intr_disable();
ffffffffc0202b7c:	aa7fd0ef          	jal	ra,ffffffffc0200622 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b80:	000bb783          	ld	a5,0(s7)
ffffffffc0202b84:	779c                	ld	a5,40(a5)
ffffffffc0202b86:	9782                	jalr	a5
ffffffffc0202b88:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202b8a:	a93fd0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc0202b8e:	b72d                	j	ffffffffc0202ab8 <pmm_init+0x560>
ffffffffc0202b90:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202b92:	a91fd0ef          	jal	ra,ffffffffc0200622 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202b96:	000bb783          	ld	a5,0(s7)
ffffffffc0202b9a:	6522                	ld	a0,8(sp)
ffffffffc0202b9c:	4585                	li	a1,1
ffffffffc0202b9e:	739c                	ld	a5,32(a5)
ffffffffc0202ba0:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ba2:	a7bfd0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc0202ba6:	bdcd                	j	ffffffffc0202a98 <pmm_init+0x540>
ffffffffc0202ba8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202baa:	a79fd0ef          	jal	ra,ffffffffc0200622 <intr_disable>
ffffffffc0202bae:	000bb783          	ld	a5,0(s7)
ffffffffc0202bb2:	6522                	ld	a0,8(sp)
ffffffffc0202bb4:	4585                	li	a1,1
ffffffffc0202bb6:	739c                	ld	a5,32(a5)
ffffffffc0202bb8:	9782                	jalr	a5
        intr_enable();
ffffffffc0202bba:	a63fd0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc0202bbe:	b56d                	j	ffffffffc0202a68 <pmm_init+0x510>
        intr_disable();
ffffffffc0202bc0:	a63fd0ef          	jal	ra,ffffffffc0200622 <intr_disable>
ffffffffc0202bc4:	000bb783          	ld	a5,0(s7)
ffffffffc0202bc8:	4585                	li	a1,1
ffffffffc0202bca:	8556                	mv	a0,s5
ffffffffc0202bcc:	739c                	ld	a5,32(a5)
ffffffffc0202bce:	9782                	jalr	a5
        intr_enable();
ffffffffc0202bd0:	a4dfd0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc0202bd4:	b59d                	j	ffffffffc0202a3a <pmm_init+0x4e2>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202bd6:	00005697          	auipc	a3,0x5
ffffffffc0202bda:	b5a68693          	addi	a3,a3,-1190 # ffffffffc0207730 <default_pmm_manager+0x560>
ffffffffc0202bde:	00004617          	auipc	a2,0x4
ffffffffc0202be2:	f5a60613          	addi	a2,a2,-166 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202be6:	22800593          	li	a1,552
ffffffffc0202bea:	00004517          	auipc	a0,0x4
ffffffffc0202bee:	73650513          	addi	a0,a0,1846 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202bf2:	889fd0ef          	jal	ra,ffffffffc020047a <__panic>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202bf6:	00005697          	auipc	a3,0x5
ffffffffc0202bfa:	afa68693          	addi	a3,a3,-1286 # ffffffffc02076f0 <default_pmm_manager+0x520>
ffffffffc0202bfe:	00004617          	auipc	a2,0x4
ffffffffc0202c02:	f3a60613          	addi	a2,a2,-198 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202c06:	22700593          	li	a1,551
ffffffffc0202c0a:	00004517          	auipc	a0,0x4
ffffffffc0202c0e:	71650513          	addi	a0,a0,1814 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202c12:	869fd0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0202c16:	86a2                	mv	a3,s0
ffffffffc0202c18:	00004617          	auipc	a2,0x4
ffffffffc0202c1c:	5f060613          	addi	a2,a2,1520 # ffffffffc0207208 <default_pmm_manager+0x38>
ffffffffc0202c20:	22700593          	li	a1,551
ffffffffc0202c24:	00004517          	auipc	a0,0x4
ffffffffc0202c28:	6fc50513          	addi	a0,a0,1788 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202c2c:	84ffd0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0202c30:	854ff0ef          	jal	ra,ffffffffc0201c84 <pa2page.part.0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202c34:	00004617          	auipc	a2,0x4
ffffffffc0202c38:	67c60613          	addi	a2,a2,1660 # ffffffffc02072b0 <default_pmm_manager+0xe0>
ffffffffc0202c3c:	07f00593          	li	a1,127
ffffffffc0202c40:	00004517          	auipc	a0,0x4
ffffffffc0202c44:	6e050513          	addi	a0,a0,1760 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202c48:	833fd0ef          	jal	ra,ffffffffc020047a <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0202c4c:	00004617          	auipc	a2,0x4
ffffffffc0202c50:	66460613          	addi	a2,a2,1636 # ffffffffc02072b0 <default_pmm_manager+0xe0>
ffffffffc0202c54:	0c100593          	li	a1,193
ffffffffc0202c58:	00004517          	auipc	a0,0x4
ffffffffc0202c5c:	6c850513          	addi	a0,a0,1736 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202c60:	81bfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0202c64:	00004697          	auipc	a3,0x4
ffffffffc0202c68:	7c468693          	addi	a3,a3,1988 # ffffffffc0207428 <default_pmm_manager+0x258>
ffffffffc0202c6c:	00004617          	auipc	a2,0x4
ffffffffc0202c70:	ecc60613          	addi	a2,a2,-308 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202c74:	1eb00593          	li	a1,491
ffffffffc0202c78:	00004517          	auipc	a0,0x4
ffffffffc0202c7c:	6a850513          	addi	a0,a0,1704 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202c80:	ffafd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202c84:	00004697          	auipc	a3,0x4
ffffffffc0202c88:	78468693          	addi	a3,a3,1924 # ffffffffc0207408 <default_pmm_manager+0x238>
ffffffffc0202c8c:	00004617          	auipc	a2,0x4
ffffffffc0202c90:	eac60613          	addi	a2,a2,-340 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202c94:	1ea00593          	li	a1,490
ffffffffc0202c98:	00004517          	auipc	a0,0x4
ffffffffc0202c9c:	68850513          	addi	a0,a0,1672 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202ca0:	fdafd0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0202ca4:	ffdfe0ef          	jal	ra,ffffffffc0201ca0 <pte2page.part.0>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0202ca8:	00005697          	auipc	a3,0x5
ffffffffc0202cac:	81068693          	addi	a3,a3,-2032 # ffffffffc02074b8 <default_pmm_manager+0x2e8>
ffffffffc0202cb0:	00004617          	auipc	a2,0x4
ffffffffc0202cb4:	e8860613          	addi	a2,a2,-376 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202cb8:	1f300593          	li	a1,499
ffffffffc0202cbc:	00004517          	auipc	a0,0x4
ffffffffc0202cc0:	66450513          	addi	a0,a0,1636 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202cc4:	fb6fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0202cc8:	00004697          	auipc	a3,0x4
ffffffffc0202ccc:	7c068693          	addi	a3,a3,1984 # ffffffffc0207488 <default_pmm_manager+0x2b8>
ffffffffc0202cd0:	00004617          	auipc	a2,0x4
ffffffffc0202cd4:	e6860613          	addi	a2,a2,-408 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202cd8:	1f000593          	li	a1,496
ffffffffc0202cdc:	00004517          	auipc	a0,0x4
ffffffffc0202ce0:	64450513          	addi	a0,a0,1604 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202ce4:	f96fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0202ce8:	00004697          	auipc	a3,0x4
ffffffffc0202cec:	77868693          	addi	a3,a3,1912 # ffffffffc0207460 <default_pmm_manager+0x290>
ffffffffc0202cf0:	00004617          	auipc	a2,0x4
ffffffffc0202cf4:	e4860613          	addi	a2,a2,-440 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202cf8:	1ec00593          	li	a1,492
ffffffffc0202cfc:	00004517          	auipc	a0,0x4
ffffffffc0202d00:	62450513          	addi	a0,a0,1572 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202d04:	f76fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202d08:	00005697          	auipc	a3,0x5
ffffffffc0202d0c:	83868693          	addi	a3,a3,-1992 # ffffffffc0207540 <default_pmm_manager+0x370>
ffffffffc0202d10:	00004617          	auipc	a2,0x4
ffffffffc0202d14:	e2860613          	addi	a2,a2,-472 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202d18:	1fc00593          	li	a1,508
ffffffffc0202d1c:	00004517          	auipc	a0,0x4
ffffffffc0202d20:	60450513          	addi	a0,a0,1540 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202d24:	f56fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202d28:	00005697          	auipc	a3,0x5
ffffffffc0202d2c:	8b868693          	addi	a3,a3,-1864 # ffffffffc02075e0 <default_pmm_manager+0x410>
ffffffffc0202d30:	00004617          	auipc	a2,0x4
ffffffffc0202d34:	e0860613          	addi	a2,a2,-504 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202d38:	20100593          	li	a1,513
ffffffffc0202d3c:	00004517          	auipc	a0,0x4
ffffffffc0202d40:	5e450513          	addi	a0,a0,1508 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202d44:	f36fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202d48:	00004697          	auipc	a3,0x4
ffffffffc0202d4c:	7d068693          	addi	a3,a3,2000 # ffffffffc0207518 <default_pmm_manager+0x348>
ffffffffc0202d50:	00004617          	auipc	a2,0x4
ffffffffc0202d54:	de860613          	addi	a2,a2,-536 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202d58:	1f900593          	li	a1,505
ffffffffc0202d5c:	00004517          	auipc	a0,0x4
ffffffffc0202d60:	5c450513          	addi	a0,a0,1476 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202d64:	f16fd0ef          	jal	ra,ffffffffc020047a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202d68:	86d6                	mv	a3,s5
ffffffffc0202d6a:	00004617          	auipc	a2,0x4
ffffffffc0202d6e:	49e60613          	addi	a2,a2,1182 # ffffffffc0207208 <default_pmm_manager+0x38>
ffffffffc0202d72:	1f800593          	li	a1,504
ffffffffc0202d76:	00004517          	auipc	a0,0x4
ffffffffc0202d7a:	5aa50513          	addi	a0,a0,1450 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202d7e:	efcfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202d82:	00004697          	auipc	a3,0x4
ffffffffc0202d86:	7f668693          	addi	a3,a3,2038 # ffffffffc0207578 <default_pmm_manager+0x3a8>
ffffffffc0202d8a:	00004617          	auipc	a2,0x4
ffffffffc0202d8e:	dae60613          	addi	a2,a2,-594 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202d92:	20600593          	li	a1,518
ffffffffc0202d96:	00004517          	auipc	a0,0x4
ffffffffc0202d9a:	58a50513          	addi	a0,a0,1418 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202d9e:	edcfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202da2:	00005697          	auipc	a3,0x5
ffffffffc0202da6:	89e68693          	addi	a3,a3,-1890 # ffffffffc0207640 <default_pmm_manager+0x470>
ffffffffc0202daa:	00004617          	auipc	a2,0x4
ffffffffc0202dae:	d8e60613          	addi	a2,a2,-626 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202db2:	20500593          	li	a1,517
ffffffffc0202db6:	00004517          	auipc	a0,0x4
ffffffffc0202dba:	56a50513          	addi	a0,a0,1386 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202dbe:	ebcfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202dc2:	00005697          	auipc	a3,0x5
ffffffffc0202dc6:	86668693          	addi	a3,a3,-1946 # ffffffffc0207628 <default_pmm_manager+0x458>
ffffffffc0202dca:	00004617          	auipc	a2,0x4
ffffffffc0202dce:	d6e60613          	addi	a2,a2,-658 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202dd2:	20400593          	li	a1,516
ffffffffc0202dd6:	00004517          	auipc	a0,0x4
ffffffffc0202dda:	54a50513          	addi	a0,a0,1354 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202dde:	e9cfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0202de2:	00005697          	auipc	a3,0x5
ffffffffc0202de6:	81668693          	addi	a3,a3,-2026 # ffffffffc02075f8 <default_pmm_manager+0x428>
ffffffffc0202dea:	00004617          	auipc	a2,0x4
ffffffffc0202dee:	d4e60613          	addi	a2,a2,-690 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202df2:	20300593          	li	a1,515
ffffffffc0202df6:	00004517          	auipc	a0,0x4
ffffffffc0202dfa:	52a50513          	addi	a0,a0,1322 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202dfe:	e7cfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202e02:	00005697          	auipc	a3,0x5
ffffffffc0202e06:	9ae68693          	addi	a3,a3,-1618 # ffffffffc02077b0 <default_pmm_manager+0x5e0>
ffffffffc0202e0a:	00004617          	auipc	a2,0x4
ffffffffc0202e0e:	d2e60613          	addi	a2,a2,-722 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202e12:	23200593          	li	a1,562
ffffffffc0202e16:	00004517          	auipc	a0,0x4
ffffffffc0202e1a:	50a50513          	addi	a0,a0,1290 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202e1e:	e5cfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0202e22:	00004697          	auipc	a3,0x4
ffffffffc0202e26:	7a668693          	addi	a3,a3,1958 # ffffffffc02075c8 <default_pmm_manager+0x3f8>
ffffffffc0202e2a:	00004617          	auipc	a2,0x4
ffffffffc0202e2e:	d0e60613          	addi	a2,a2,-754 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202e32:	20000593          	li	a1,512
ffffffffc0202e36:	00004517          	auipc	a0,0x4
ffffffffc0202e3a:	4ea50513          	addi	a0,a0,1258 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202e3e:	e3cfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202e42:	00004697          	auipc	a3,0x4
ffffffffc0202e46:	77668693          	addi	a3,a3,1910 # ffffffffc02075b8 <default_pmm_manager+0x3e8>
ffffffffc0202e4a:	00004617          	auipc	a2,0x4
ffffffffc0202e4e:	cee60613          	addi	a2,a2,-786 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202e52:	1ff00593          	li	a1,511
ffffffffc0202e56:	00004517          	auipc	a0,0x4
ffffffffc0202e5a:	4ca50513          	addi	a0,a0,1226 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202e5e:	e1cfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0202e62:	00005697          	auipc	a3,0x5
ffffffffc0202e66:	84e68693          	addi	a3,a3,-1970 # ffffffffc02076b0 <default_pmm_manager+0x4e0>
ffffffffc0202e6a:	00004617          	auipc	a2,0x4
ffffffffc0202e6e:	cce60613          	addi	a2,a2,-818 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202e72:	24300593          	li	a1,579
ffffffffc0202e76:	00004517          	auipc	a0,0x4
ffffffffc0202e7a:	4aa50513          	addi	a0,a0,1194 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202e7e:	dfcfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202e82:	00004697          	auipc	a3,0x4
ffffffffc0202e86:	72668693          	addi	a3,a3,1830 # ffffffffc02075a8 <default_pmm_manager+0x3d8>
ffffffffc0202e8a:	00004617          	auipc	a2,0x4
ffffffffc0202e8e:	cae60613          	addi	a2,a2,-850 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202e92:	1fe00593          	li	a1,510
ffffffffc0202e96:	00004517          	auipc	a0,0x4
ffffffffc0202e9a:	48a50513          	addi	a0,a0,1162 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202e9e:	ddcfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202ea2:	00004697          	auipc	a3,0x4
ffffffffc0202ea6:	65e68693          	addi	a3,a3,1630 # ffffffffc0207500 <default_pmm_manager+0x330>
ffffffffc0202eaa:	00004617          	auipc	a2,0x4
ffffffffc0202eae:	c8e60613          	addi	a2,a2,-882 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202eb2:	20b00593          	li	a1,523
ffffffffc0202eb6:	00004517          	auipc	a0,0x4
ffffffffc0202eba:	46a50513          	addi	a0,a0,1130 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202ebe:	dbcfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202ec2:	00004697          	auipc	a3,0x4
ffffffffc0202ec6:	79668693          	addi	a3,a3,1942 # ffffffffc0207658 <default_pmm_manager+0x488>
ffffffffc0202eca:	00004617          	auipc	a2,0x4
ffffffffc0202ece:	c6e60613          	addi	a2,a2,-914 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202ed2:	20800593          	li	a1,520
ffffffffc0202ed6:	00004517          	auipc	a0,0x4
ffffffffc0202eda:	44a50513          	addi	a0,a0,1098 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202ede:	d9cfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202ee2:	00004697          	auipc	a3,0x4
ffffffffc0202ee6:	60668693          	addi	a3,a3,1542 # ffffffffc02074e8 <default_pmm_manager+0x318>
ffffffffc0202eea:	00004617          	auipc	a2,0x4
ffffffffc0202eee:	c4e60613          	addi	a2,a2,-946 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202ef2:	20700593          	li	a1,519
ffffffffc0202ef6:	00004517          	auipc	a0,0x4
ffffffffc0202efa:	42a50513          	addi	a0,a0,1066 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202efe:	d7cfd0ef          	jal	ra,ffffffffc020047a <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f02:	00004617          	auipc	a2,0x4
ffffffffc0202f06:	30660613          	addi	a2,a2,774 # ffffffffc0207208 <default_pmm_manager+0x38>
ffffffffc0202f0a:	06900593          	li	a1,105
ffffffffc0202f0e:	00004517          	auipc	a0,0x4
ffffffffc0202f12:	32250513          	addi	a0,a0,802 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc0202f16:	d64fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0202f1a:	00004697          	auipc	a3,0x4
ffffffffc0202f1e:	76e68693          	addi	a3,a3,1902 # ffffffffc0207688 <default_pmm_manager+0x4b8>
ffffffffc0202f22:	00004617          	auipc	a2,0x4
ffffffffc0202f26:	c1660613          	addi	a2,a2,-1002 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202f2a:	21200593          	li	a1,530
ffffffffc0202f2e:	00004517          	auipc	a0,0x4
ffffffffc0202f32:	3f250513          	addi	a0,a0,1010 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202f36:	d44fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f3a:	00004697          	auipc	a3,0x4
ffffffffc0202f3e:	70668693          	addi	a3,a3,1798 # ffffffffc0207640 <default_pmm_manager+0x470>
ffffffffc0202f42:	00004617          	auipc	a2,0x4
ffffffffc0202f46:	bf660613          	addi	a2,a2,-1034 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202f4a:	21000593          	li	a1,528
ffffffffc0202f4e:	00004517          	auipc	a0,0x4
ffffffffc0202f52:	3d250513          	addi	a0,a0,978 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202f56:	d24fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202f5a:	00004697          	auipc	a3,0x4
ffffffffc0202f5e:	71668693          	addi	a3,a3,1814 # ffffffffc0207670 <default_pmm_manager+0x4a0>
ffffffffc0202f62:	00004617          	auipc	a2,0x4
ffffffffc0202f66:	bd660613          	addi	a2,a2,-1066 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202f6a:	20f00593          	li	a1,527
ffffffffc0202f6e:	00004517          	auipc	a0,0x4
ffffffffc0202f72:	3b250513          	addi	a0,a0,946 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202f76:	d04fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f7a:	00004697          	auipc	a3,0x4
ffffffffc0202f7e:	6c668693          	addi	a3,a3,1734 # ffffffffc0207640 <default_pmm_manager+0x470>
ffffffffc0202f82:	00004617          	auipc	a2,0x4
ffffffffc0202f86:	bb660613          	addi	a2,a2,-1098 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202f8a:	20c00593          	li	a1,524
ffffffffc0202f8e:	00004517          	auipc	a0,0x4
ffffffffc0202f92:	39250513          	addi	a0,a0,914 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202f96:	ce4fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202f9a:	00004697          	auipc	a3,0x4
ffffffffc0202f9e:	7fe68693          	addi	a3,a3,2046 # ffffffffc0207798 <default_pmm_manager+0x5c8>
ffffffffc0202fa2:	00004617          	auipc	a2,0x4
ffffffffc0202fa6:	b9660613          	addi	a2,a2,-1130 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202faa:	23100593          	li	a1,561
ffffffffc0202fae:	00004517          	auipc	a0,0x4
ffffffffc0202fb2:	37250513          	addi	a0,a0,882 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202fb6:	cc4fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202fba:	00004697          	auipc	a3,0x4
ffffffffc0202fbe:	7a668693          	addi	a3,a3,1958 # ffffffffc0207760 <default_pmm_manager+0x590>
ffffffffc0202fc2:	00004617          	auipc	a2,0x4
ffffffffc0202fc6:	b7660613          	addi	a2,a2,-1162 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202fca:	23000593          	li	a1,560
ffffffffc0202fce:	00004517          	auipc	a0,0x4
ffffffffc0202fd2:	35250513          	addi	a0,a0,850 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202fd6:	ca4fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0202fda:	00004697          	auipc	a3,0x4
ffffffffc0202fde:	76e68693          	addi	a3,a3,1902 # ffffffffc0207748 <default_pmm_manager+0x578>
ffffffffc0202fe2:	00004617          	auipc	a2,0x4
ffffffffc0202fe6:	b5660613          	addi	a2,a2,-1194 # ffffffffc0206b38 <commands+0x450>
ffffffffc0202fea:	22c00593          	li	a1,556
ffffffffc0202fee:	00004517          	auipc	a0,0x4
ffffffffc0202ff2:	33250513          	addi	a0,a0,818 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0202ff6:	c84fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0202ffa:	00004697          	auipc	a3,0x4
ffffffffc0202ffe:	6b668693          	addi	a3,a3,1718 # ffffffffc02076b0 <default_pmm_manager+0x4e0>
ffffffffc0203002:	00004617          	auipc	a2,0x4
ffffffffc0203006:	b3660613          	addi	a2,a2,-1226 # ffffffffc0206b38 <commands+0x450>
ffffffffc020300a:	21a00593          	li	a1,538
ffffffffc020300e:	00004517          	auipc	a0,0x4
ffffffffc0203012:	31250513          	addi	a0,a0,786 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0203016:	c64fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020301a:	00004697          	auipc	a3,0x4
ffffffffc020301e:	4ce68693          	addi	a3,a3,1230 # ffffffffc02074e8 <default_pmm_manager+0x318>
ffffffffc0203022:	00004617          	auipc	a2,0x4
ffffffffc0203026:	b1660613          	addi	a2,a2,-1258 # ffffffffc0206b38 <commands+0x450>
ffffffffc020302a:	1f400593          	li	a1,500
ffffffffc020302e:	00004517          	auipc	a0,0x4
ffffffffc0203032:	2f250513          	addi	a0,a0,754 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc0203036:	c44fd0ef          	jal	ra,ffffffffc020047a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc020303a:	00004617          	auipc	a2,0x4
ffffffffc020303e:	1ce60613          	addi	a2,a2,462 # ffffffffc0207208 <default_pmm_manager+0x38>
ffffffffc0203042:	1f700593          	li	a1,503
ffffffffc0203046:	00004517          	auipc	a0,0x4
ffffffffc020304a:	2da50513          	addi	a0,a0,730 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc020304e:	c2cfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203052:	00004697          	auipc	a3,0x4
ffffffffc0203056:	4ae68693          	addi	a3,a3,1198 # ffffffffc0207500 <default_pmm_manager+0x330>
ffffffffc020305a:	00004617          	auipc	a2,0x4
ffffffffc020305e:	ade60613          	addi	a2,a2,-1314 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203062:	1f500593          	li	a1,501
ffffffffc0203066:	00004517          	auipc	a0,0x4
ffffffffc020306a:	2ba50513          	addi	a0,a0,698 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc020306e:	c0cfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0203072:	00004697          	auipc	a3,0x4
ffffffffc0203076:	50668693          	addi	a3,a3,1286 # ffffffffc0207578 <default_pmm_manager+0x3a8>
ffffffffc020307a:	00004617          	auipc	a2,0x4
ffffffffc020307e:	abe60613          	addi	a2,a2,-1346 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203082:	1fd00593          	li	a1,509
ffffffffc0203086:	00004517          	auipc	a0,0x4
ffffffffc020308a:	29a50513          	addi	a0,a0,666 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc020308e:	becfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203092:	00004697          	auipc	a3,0x4
ffffffffc0203096:	7c668693          	addi	a3,a3,1990 # ffffffffc0207858 <default_pmm_manager+0x688>
ffffffffc020309a:	00004617          	auipc	a2,0x4
ffffffffc020309e:	a9e60613          	addi	a2,a2,-1378 # ffffffffc0206b38 <commands+0x450>
ffffffffc02030a2:	23a00593          	li	a1,570
ffffffffc02030a6:	00004517          	auipc	a0,0x4
ffffffffc02030aa:	27a50513          	addi	a0,a0,634 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc02030ae:	bccfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02030b2:	00004697          	auipc	a3,0x4
ffffffffc02030b6:	76e68693          	addi	a3,a3,1902 # ffffffffc0207820 <default_pmm_manager+0x650>
ffffffffc02030ba:	00004617          	auipc	a2,0x4
ffffffffc02030be:	a7e60613          	addi	a2,a2,-1410 # ffffffffc0206b38 <commands+0x450>
ffffffffc02030c2:	23700593          	li	a1,567
ffffffffc02030c6:	00004517          	auipc	a0,0x4
ffffffffc02030ca:	25a50513          	addi	a0,a0,602 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc02030ce:	bacfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p) == 2);
ffffffffc02030d2:	00004697          	auipc	a3,0x4
ffffffffc02030d6:	71e68693          	addi	a3,a3,1822 # ffffffffc02077f0 <default_pmm_manager+0x620>
ffffffffc02030da:	00004617          	auipc	a2,0x4
ffffffffc02030de:	a5e60613          	addi	a2,a2,-1442 # ffffffffc0206b38 <commands+0x450>
ffffffffc02030e2:	23300593          	li	a1,563
ffffffffc02030e6:	00004517          	auipc	a0,0x4
ffffffffc02030ea:	23a50513          	addi	a0,a0,570 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc02030ee:	b8cfd0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02030f2 <copy_range>:
               bool share) {
ffffffffc02030f2:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02030f4:	00d667b3          	or	a5,a2,a3
               bool share) {
ffffffffc02030f8:	f486                	sd	ra,104(sp)
ffffffffc02030fa:	f0a2                	sd	s0,96(sp)
ffffffffc02030fc:	eca6                	sd	s1,88(sp)
ffffffffc02030fe:	e8ca                	sd	s2,80(sp)
ffffffffc0203100:	e4ce                	sd	s3,72(sp)
ffffffffc0203102:	e0d2                	sd	s4,64(sp)
ffffffffc0203104:	fc56                	sd	s5,56(sp)
ffffffffc0203106:	f85a                	sd	s6,48(sp)
ffffffffc0203108:	f45e                	sd	s7,40(sp)
ffffffffc020310a:	f062                	sd	s8,32(sp)
ffffffffc020310c:	ec66                	sd	s9,24(sp)
ffffffffc020310e:	e86a                	sd	s10,16(sp)
ffffffffc0203110:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203112:	17d2                	slli	a5,a5,0x34
ffffffffc0203114:	1e079763          	bnez	a5,ffffffffc0203302 <copy_range+0x210>
    assert(USER_ACCESS(start, end));
ffffffffc0203118:	002007b7          	lui	a5,0x200
ffffffffc020311c:	8432                	mv	s0,a2
ffffffffc020311e:	16f66a63          	bltu	a2,a5,ffffffffc0203292 <copy_range+0x1a0>
ffffffffc0203122:	8936                	mv	s2,a3
ffffffffc0203124:	16d67763          	bgeu	a2,a3,ffffffffc0203292 <copy_range+0x1a0>
ffffffffc0203128:	4785                	li	a5,1
ffffffffc020312a:	07fe                	slli	a5,a5,0x1f
ffffffffc020312c:	16d7e363          	bltu	a5,a3,ffffffffc0203292 <copy_range+0x1a0>
ffffffffc0203130:	5b7d                	li	s6,-1
ffffffffc0203132:	8aaa                	mv	s5,a0
ffffffffc0203134:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc0203136:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc0203138:	000afc97          	auipc	s9,0xaf
ffffffffc020313c:	798c8c93          	addi	s9,s9,1944 # ffffffffc02b28d0 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203140:	000afc17          	auipc	s8,0xaf
ffffffffc0203144:	798c0c13          	addi	s8,s8,1944 # ffffffffc02b28d8 <pages>
    return page - pages + nbase;
ffffffffc0203148:	00080bb7          	lui	s7,0x80
    return KADDR(page2pa(page));
ffffffffc020314c:	00cb5b13          	srli	s6,s6,0xc
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203150:	4601                	li	a2,0
ffffffffc0203152:	85a2                	mv	a1,s0
ffffffffc0203154:	854e                	mv	a0,s3
ffffffffc0203156:	c73fe0ef          	jal	ra,ffffffffc0201dc8 <get_pte>
ffffffffc020315a:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc020315c:	c175                	beqz	a0,ffffffffc0203240 <copy_range+0x14e>
        if (*ptep & PTE_V) {
ffffffffc020315e:	611c                	ld	a5,0(a0)
ffffffffc0203160:	8b85                	andi	a5,a5,1
ffffffffc0203162:	e785                	bnez	a5,ffffffffc020318a <copy_range+0x98>
        start += PGSIZE;
ffffffffc0203164:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0203166:	ff2465e3          	bltu	s0,s2,ffffffffc0203150 <copy_range+0x5e>
    return 0;
ffffffffc020316a:	4501                	li	a0,0
}
ffffffffc020316c:	70a6                	ld	ra,104(sp)
ffffffffc020316e:	7406                	ld	s0,96(sp)
ffffffffc0203170:	64e6                	ld	s1,88(sp)
ffffffffc0203172:	6946                	ld	s2,80(sp)
ffffffffc0203174:	69a6                	ld	s3,72(sp)
ffffffffc0203176:	6a06                	ld	s4,64(sp)
ffffffffc0203178:	7ae2                	ld	s5,56(sp)
ffffffffc020317a:	7b42                	ld	s6,48(sp)
ffffffffc020317c:	7ba2                	ld	s7,40(sp)
ffffffffc020317e:	7c02                	ld	s8,32(sp)
ffffffffc0203180:	6ce2                	ld	s9,24(sp)
ffffffffc0203182:	6d42                	ld	s10,16(sp)
ffffffffc0203184:	6da2                	ld	s11,8(sp)
ffffffffc0203186:	6165                	addi	sp,sp,112
ffffffffc0203188:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL) {
ffffffffc020318a:	4605                	li	a2,1
ffffffffc020318c:	85a2                	mv	a1,s0
ffffffffc020318e:	8556                	mv	a0,s5
ffffffffc0203190:	c39fe0ef          	jal	ra,ffffffffc0201dc8 <get_pte>
ffffffffc0203194:	c161                	beqz	a0,ffffffffc0203254 <copy_range+0x162>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203196:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V)) {
ffffffffc0203198:	0017f713          	andi	a4,a5,1
ffffffffc020319c:	01f7f493          	andi	s1,a5,31
ffffffffc02031a0:	14070563          	beqz	a4,ffffffffc02032ea <copy_range+0x1f8>
    if (PPN(pa) >= npage) {
ffffffffc02031a4:	000cb683          	ld	a3,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc02031a8:	078a                	slli	a5,a5,0x2
ffffffffc02031aa:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02031ae:	12d77263          	bgeu	a4,a3,ffffffffc02032d2 <copy_range+0x1e0>
    return &pages[PPN(pa) - nbase];
ffffffffc02031b2:	000c3783          	ld	a5,0(s8)
ffffffffc02031b6:	fff806b7          	lui	a3,0xfff80
ffffffffc02031ba:	9736                	add	a4,a4,a3
ffffffffc02031bc:	071a                	slli	a4,a4,0x6
            struct Page *npage = alloc_page();
ffffffffc02031be:	4505                	li	a0,1
ffffffffc02031c0:	00e78db3          	add	s11,a5,a4
ffffffffc02031c4:	af9fe0ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc02031c8:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc02031ca:	0a0d8463          	beqz	s11,ffffffffc0203272 <copy_range+0x180>
            assert(npage != NULL);
ffffffffc02031ce:	c175                	beqz	a0,ffffffffc02032b2 <copy_range+0x1c0>
    return page - pages + nbase;
ffffffffc02031d0:	000c3703          	ld	a4,0(s8)
    return KADDR(page2pa(page));
ffffffffc02031d4:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc02031d8:	40ed86b3          	sub	a3,s11,a4
ffffffffc02031dc:	8699                	srai	a3,a3,0x6
ffffffffc02031de:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc02031e0:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02031e4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02031e6:	06c7fa63          	bgeu	a5,a2,ffffffffc020325a <copy_range+0x168>
    return page - pages + nbase;
ffffffffc02031ea:	40e507b3          	sub	a5,a0,a4
    return KADDR(page2pa(page));
ffffffffc02031ee:	000af717          	auipc	a4,0xaf
ffffffffc02031f2:	6fa70713          	addi	a4,a4,1786 # ffffffffc02b28e8 <va_pa_offset>
ffffffffc02031f6:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc02031f8:	8799                	srai	a5,a5,0x6
ffffffffc02031fa:	97de                	add	a5,a5,s7
    return KADDR(page2pa(page));
ffffffffc02031fc:	0167f733          	and	a4,a5,s6
ffffffffc0203200:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203204:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203206:	04c77963          	bgeu	a4,a2,ffffffffc0203258 <copy_range+0x166>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc020320a:	6605                	lui	a2,0x1
ffffffffc020320c:	953e                	add	a0,a0,a5
ffffffffc020320e:	256030ef          	jal	ra,ffffffffc0206464 <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc0203212:	86a6                	mv	a3,s1
ffffffffc0203214:	8622                	mv	a2,s0
ffffffffc0203216:	85ea                	mv	a1,s10
ffffffffc0203218:	8556                	mv	a0,s5
ffffffffc020321a:	a48ff0ef          	jal	ra,ffffffffc0202462 <page_insert>
            assert(ret == 0);
ffffffffc020321e:	d139                	beqz	a0,ffffffffc0203164 <copy_range+0x72>
ffffffffc0203220:	00004697          	auipc	a3,0x4
ffffffffc0203224:	6a068693          	addi	a3,a3,1696 # ffffffffc02078c0 <default_pmm_manager+0x6f0>
ffffffffc0203228:	00004617          	auipc	a2,0x4
ffffffffc020322c:	91060613          	addi	a2,a2,-1776 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203230:	18c00593          	li	a1,396
ffffffffc0203234:	00004517          	auipc	a0,0x4
ffffffffc0203238:	0ec50513          	addi	a0,a0,236 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc020323c:	a3efd0ef          	jal	ra,ffffffffc020047a <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203240:	00200637          	lui	a2,0x200
ffffffffc0203244:	9432                	add	s0,s0,a2
ffffffffc0203246:	ffe00637          	lui	a2,0xffe00
ffffffffc020324a:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc020324c:	dc19                	beqz	s0,ffffffffc020316a <copy_range+0x78>
ffffffffc020324e:	f12461e3          	bltu	s0,s2,ffffffffc0203150 <copy_range+0x5e>
ffffffffc0203252:	bf21                	j	ffffffffc020316a <copy_range+0x78>
                return -E_NO_MEM;
ffffffffc0203254:	5571                	li	a0,-4
ffffffffc0203256:	bf19                	j	ffffffffc020316c <copy_range+0x7a>
ffffffffc0203258:	86be                	mv	a3,a5
ffffffffc020325a:	00004617          	auipc	a2,0x4
ffffffffc020325e:	fae60613          	addi	a2,a2,-82 # ffffffffc0207208 <default_pmm_manager+0x38>
ffffffffc0203262:	06900593          	li	a1,105
ffffffffc0203266:	00004517          	auipc	a0,0x4
ffffffffc020326a:	fca50513          	addi	a0,a0,-54 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc020326e:	a0cfd0ef          	jal	ra,ffffffffc020047a <__panic>
            assert(page != NULL);
ffffffffc0203272:	00004697          	auipc	a3,0x4
ffffffffc0203276:	62e68693          	addi	a3,a3,1582 # ffffffffc02078a0 <default_pmm_manager+0x6d0>
ffffffffc020327a:	00004617          	auipc	a2,0x4
ffffffffc020327e:	8be60613          	addi	a2,a2,-1858 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203282:	17200593          	li	a1,370
ffffffffc0203286:	00004517          	auipc	a0,0x4
ffffffffc020328a:	09a50513          	addi	a0,a0,154 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc020328e:	9ecfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203292:	00004697          	auipc	a3,0x4
ffffffffc0203296:	0ce68693          	addi	a3,a3,206 # ffffffffc0207360 <default_pmm_manager+0x190>
ffffffffc020329a:	00004617          	auipc	a2,0x4
ffffffffc020329e:	89e60613          	addi	a2,a2,-1890 # ffffffffc0206b38 <commands+0x450>
ffffffffc02032a2:	15e00593          	li	a1,350
ffffffffc02032a6:	00004517          	auipc	a0,0x4
ffffffffc02032aa:	07a50513          	addi	a0,a0,122 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc02032ae:	9ccfd0ef          	jal	ra,ffffffffc020047a <__panic>
            assert(npage != NULL);
ffffffffc02032b2:	00004697          	auipc	a3,0x4
ffffffffc02032b6:	5fe68693          	addi	a3,a3,1534 # ffffffffc02078b0 <default_pmm_manager+0x6e0>
ffffffffc02032ba:	00004617          	auipc	a2,0x4
ffffffffc02032be:	87e60613          	addi	a2,a2,-1922 # ffffffffc0206b38 <commands+0x450>
ffffffffc02032c2:	17300593          	li	a1,371
ffffffffc02032c6:	00004517          	auipc	a0,0x4
ffffffffc02032ca:	05a50513          	addi	a0,a0,90 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc02032ce:	9acfd0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02032d2:	00004617          	auipc	a2,0x4
ffffffffc02032d6:	00660613          	addi	a2,a2,6 # ffffffffc02072d8 <default_pmm_manager+0x108>
ffffffffc02032da:	06200593          	li	a1,98
ffffffffc02032de:	00004517          	auipc	a0,0x4
ffffffffc02032e2:	f5250513          	addi	a0,a0,-174 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc02032e6:	994fd0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02032ea:	00004617          	auipc	a2,0x4
ffffffffc02032ee:	00e60613          	addi	a2,a2,14 # ffffffffc02072f8 <default_pmm_manager+0x128>
ffffffffc02032f2:	07400593          	li	a1,116
ffffffffc02032f6:	00004517          	auipc	a0,0x4
ffffffffc02032fa:	f3a50513          	addi	a0,a0,-198 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc02032fe:	97cfd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203302:	00004697          	auipc	a3,0x4
ffffffffc0203306:	02e68693          	addi	a3,a3,46 # ffffffffc0207330 <default_pmm_manager+0x160>
ffffffffc020330a:	00004617          	auipc	a2,0x4
ffffffffc020330e:	82e60613          	addi	a2,a2,-2002 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203312:	15d00593          	li	a1,349
ffffffffc0203316:	00004517          	auipc	a0,0x4
ffffffffc020331a:	00a50513          	addi	a0,a0,10 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc020331e:	95cfd0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203322 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203322:	12058073          	sfence.vma	a1
}
ffffffffc0203326:	8082                	ret

ffffffffc0203328 <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0203328:	7179                	addi	sp,sp,-48
ffffffffc020332a:	e84a                	sd	s2,16(sp)
ffffffffc020332c:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc020332e:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0203330:	f022                	sd	s0,32(sp)
ffffffffc0203332:	ec26                	sd	s1,24(sp)
ffffffffc0203334:	e44e                	sd	s3,8(sp)
ffffffffc0203336:	f406                	sd	ra,40(sp)
ffffffffc0203338:	84ae                	mv	s1,a1
ffffffffc020333a:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc020333c:	981fe0ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0203340:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0203342:	cd05                	beqz	a0,ffffffffc020337a <pgdir_alloc_page+0x52>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0203344:	85aa                	mv	a1,a0
ffffffffc0203346:	86ce                	mv	a3,s3
ffffffffc0203348:	8626                	mv	a2,s1
ffffffffc020334a:	854a                	mv	a0,s2
ffffffffc020334c:	916ff0ef          	jal	ra,ffffffffc0202462 <page_insert>
ffffffffc0203350:	ed0d                	bnez	a0,ffffffffc020338a <pgdir_alloc_page+0x62>
        if (swap_init_ok) {
ffffffffc0203352:	000af797          	auipc	a5,0xaf
ffffffffc0203356:	5ae7a783          	lw	a5,1454(a5) # ffffffffc02b2900 <swap_init_ok>
ffffffffc020335a:	c385                	beqz	a5,ffffffffc020337a <pgdir_alloc_page+0x52>
            if (check_mm_struct != NULL) {
ffffffffc020335c:	000af517          	auipc	a0,0xaf
ffffffffc0203360:	5ac53503          	ld	a0,1452(a0) # ffffffffc02b2908 <check_mm_struct>
ffffffffc0203364:	c919                	beqz	a0,ffffffffc020337a <pgdir_alloc_page+0x52>
                swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0203366:	4681                	li	a3,0
ffffffffc0203368:	8622                	mv	a2,s0
ffffffffc020336a:	85a6                	mv	a1,s1
ffffffffc020336c:	7e4000ef          	jal	ra,ffffffffc0203b50 <swap_map_swappable>
                assert(page_ref(page) == 1);
ffffffffc0203370:	4018                	lw	a4,0(s0)
                page->pra_vaddr = la;
ffffffffc0203372:	fc04                	sd	s1,56(s0)
                assert(page_ref(page) == 1);
ffffffffc0203374:	4785                	li	a5,1
ffffffffc0203376:	04f71663          	bne	a4,a5,ffffffffc02033c2 <pgdir_alloc_page+0x9a>
}
ffffffffc020337a:	70a2                	ld	ra,40(sp)
ffffffffc020337c:	8522                	mv	a0,s0
ffffffffc020337e:	7402                	ld	s0,32(sp)
ffffffffc0203380:	64e2                	ld	s1,24(sp)
ffffffffc0203382:	6942                	ld	s2,16(sp)
ffffffffc0203384:	69a2                	ld	s3,8(sp)
ffffffffc0203386:	6145                	addi	sp,sp,48
ffffffffc0203388:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020338a:	100027f3          	csrr	a5,sstatus
ffffffffc020338e:	8b89                	andi	a5,a5,2
ffffffffc0203390:	eb99                	bnez	a5,ffffffffc02033a6 <pgdir_alloc_page+0x7e>
        pmm_manager->free_pages(base, n);
ffffffffc0203392:	000af797          	auipc	a5,0xaf
ffffffffc0203396:	54e7b783          	ld	a5,1358(a5) # ffffffffc02b28e0 <pmm_manager>
ffffffffc020339a:	739c                	ld	a5,32(a5)
ffffffffc020339c:	8522                	mv	a0,s0
ffffffffc020339e:	4585                	li	a1,1
ffffffffc02033a0:	9782                	jalr	a5
            return NULL;
ffffffffc02033a2:	4401                	li	s0,0
ffffffffc02033a4:	bfd9                	j	ffffffffc020337a <pgdir_alloc_page+0x52>
        intr_disable();
ffffffffc02033a6:	a7cfd0ef          	jal	ra,ffffffffc0200622 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02033aa:	000af797          	auipc	a5,0xaf
ffffffffc02033ae:	5367b783          	ld	a5,1334(a5) # ffffffffc02b28e0 <pmm_manager>
ffffffffc02033b2:	739c                	ld	a5,32(a5)
ffffffffc02033b4:	8522                	mv	a0,s0
ffffffffc02033b6:	4585                	li	a1,1
ffffffffc02033b8:	9782                	jalr	a5
            return NULL;
ffffffffc02033ba:	4401                	li	s0,0
        intr_enable();
ffffffffc02033bc:	a60fd0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc02033c0:	bf6d                	j	ffffffffc020337a <pgdir_alloc_page+0x52>
                assert(page_ref(page) == 1);
ffffffffc02033c2:	00004697          	auipc	a3,0x4
ffffffffc02033c6:	50e68693          	addi	a3,a3,1294 # ffffffffc02078d0 <default_pmm_manager+0x700>
ffffffffc02033ca:	00003617          	auipc	a2,0x3
ffffffffc02033ce:	76e60613          	addi	a2,a2,1902 # ffffffffc0206b38 <commands+0x450>
ffffffffc02033d2:	1cb00593          	li	a1,459
ffffffffc02033d6:	00004517          	auipc	a0,0x4
ffffffffc02033da:	f4a50513          	addi	a0,a0,-182 # ffffffffc0207320 <default_pmm_manager+0x150>
ffffffffc02033de:	89cfd0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02033e2 <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc02033e2:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc02033e4:	00004617          	auipc	a2,0x4
ffffffffc02033e8:	ef460613          	addi	a2,a2,-268 # ffffffffc02072d8 <default_pmm_manager+0x108>
ffffffffc02033ec:	06200593          	li	a1,98
ffffffffc02033f0:	00004517          	auipc	a0,0x4
ffffffffc02033f4:	e4050513          	addi	a0,a0,-448 # ffffffffc0207230 <default_pmm_manager+0x60>
pa2page(uintptr_t pa) {
ffffffffc02033f8:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc02033fa:	880fd0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02033fe <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc02033fe:	7135                	addi	sp,sp,-160
ffffffffc0203400:	ed06                	sd	ra,152(sp)
ffffffffc0203402:	e922                	sd	s0,144(sp)
ffffffffc0203404:	e526                	sd	s1,136(sp)
ffffffffc0203406:	e14a                	sd	s2,128(sp)
ffffffffc0203408:	fcce                	sd	s3,120(sp)
ffffffffc020340a:	f8d2                	sd	s4,112(sp)
ffffffffc020340c:	f4d6                	sd	s5,104(sp)
ffffffffc020340e:	f0da                	sd	s6,96(sp)
ffffffffc0203410:	ecde                	sd	s7,88(sp)
ffffffffc0203412:	e8e2                	sd	s8,80(sp)
ffffffffc0203414:	e4e6                	sd	s9,72(sp)
ffffffffc0203416:	e0ea                	sd	s10,64(sp)
ffffffffc0203418:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc020341a:	690010ef          	jal	ra,ffffffffc0204aaa <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc020341e:	000af697          	auipc	a3,0xaf
ffffffffc0203422:	4d26b683          	ld	a3,1234(a3) # ffffffffc02b28f0 <max_swap_offset>
ffffffffc0203426:	010007b7          	lui	a5,0x1000
ffffffffc020342a:	ff968713          	addi	a4,a3,-7
ffffffffc020342e:	17e1                	addi	a5,a5,-8
ffffffffc0203430:	42e7e663          	bltu	a5,a4,ffffffffc020385c <swap_init+0x45e>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }
     

     sm = &swap_manager_fifo;
ffffffffc0203434:	000a4797          	auipc	a5,0xa4
ffffffffc0203438:	f5478793          	addi	a5,a5,-172 # ffffffffc02a7388 <swap_manager_fifo>
     int r = sm->init();
ffffffffc020343c:	6798                	ld	a4,8(a5)
     sm = &swap_manager_fifo;
ffffffffc020343e:	000afb97          	auipc	s7,0xaf
ffffffffc0203442:	4bab8b93          	addi	s7,s7,1210 # ffffffffc02b28f8 <sm>
ffffffffc0203446:	00fbb023          	sd	a5,0(s7)
     int r = sm->init();
ffffffffc020344a:	9702                	jalr	a4
ffffffffc020344c:	892a                	mv	s2,a0
     
     if (r == 0)
ffffffffc020344e:	c10d                	beqz	a0,ffffffffc0203470 <swap_init+0x72>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc0203450:	60ea                	ld	ra,152(sp)
ffffffffc0203452:	644a                	ld	s0,144(sp)
ffffffffc0203454:	64aa                	ld	s1,136(sp)
ffffffffc0203456:	79e6                	ld	s3,120(sp)
ffffffffc0203458:	7a46                	ld	s4,112(sp)
ffffffffc020345a:	7aa6                	ld	s5,104(sp)
ffffffffc020345c:	7b06                	ld	s6,96(sp)
ffffffffc020345e:	6be6                	ld	s7,88(sp)
ffffffffc0203460:	6c46                	ld	s8,80(sp)
ffffffffc0203462:	6ca6                	ld	s9,72(sp)
ffffffffc0203464:	6d06                	ld	s10,64(sp)
ffffffffc0203466:	7de2                	ld	s11,56(sp)
ffffffffc0203468:	854a                	mv	a0,s2
ffffffffc020346a:	690a                	ld	s2,128(sp)
ffffffffc020346c:	610d                	addi	sp,sp,160
ffffffffc020346e:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0203470:	000bb783          	ld	a5,0(s7)
ffffffffc0203474:	00004517          	auipc	a0,0x4
ffffffffc0203478:	4a450513          	addi	a0,a0,1188 # ffffffffc0207918 <default_pmm_manager+0x748>
    return listelm->next;
ffffffffc020347c:	000ab417          	auipc	s0,0xab
ffffffffc0203480:	35c40413          	addi	s0,s0,860 # ffffffffc02ae7d8 <free_area>
ffffffffc0203484:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc0203486:	4785                	li	a5,1
ffffffffc0203488:	000af717          	auipc	a4,0xaf
ffffffffc020348c:	46f72c23          	sw	a5,1144(a4) # ffffffffc02b2900 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0203490:	cf1fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc0203494:	641c                	ld	a5,8(s0)

static void
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
ffffffffc0203496:	4d01                	li	s10,0
ffffffffc0203498:	4d81                	li	s11,0
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc020349a:	34878163          	beq	a5,s0,ffffffffc02037dc <swap_init+0x3de>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020349e:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02034a2:	8b09                	andi	a4,a4,2
ffffffffc02034a4:	32070e63          	beqz	a4,ffffffffc02037e0 <swap_init+0x3e2>
        count ++, total += p->property;
ffffffffc02034a8:	ff87a703          	lw	a4,-8(a5)
ffffffffc02034ac:	679c                	ld	a5,8(a5)
ffffffffc02034ae:	2d85                	addiw	s11,s11,1
ffffffffc02034b0:	01a70d3b          	addw	s10,a4,s10
     while ((le = list_next(le)) != &free_list) {
ffffffffc02034b4:	fe8795e3          	bne	a5,s0,ffffffffc020349e <swap_init+0xa0>
     }
     assert(total == nr_free_pages());
ffffffffc02034b8:	84ea                	mv	s1,s10
ffffffffc02034ba:	8d5fe0ef          	jal	ra,ffffffffc0201d8e <nr_free_pages>
ffffffffc02034be:	42951763          	bne	a0,s1,ffffffffc02038ec <swap_init+0x4ee>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc02034c2:	866a                	mv	a2,s10
ffffffffc02034c4:	85ee                	mv	a1,s11
ffffffffc02034c6:	00004517          	auipc	a0,0x4
ffffffffc02034ca:	46a50513          	addi	a0,a0,1130 # ffffffffc0207930 <default_pmm_manager+0x760>
ffffffffc02034ce:	cb3fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc02034d2:	3b1000ef          	jal	ra,ffffffffc0204082 <mm_create>
ffffffffc02034d6:	8aaa                	mv	s5,a0
     assert(mm != NULL);
ffffffffc02034d8:	46050a63          	beqz	a0,ffffffffc020394c <swap_init+0x54e>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc02034dc:	000af797          	auipc	a5,0xaf
ffffffffc02034e0:	42c78793          	addi	a5,a5,1068 # ffffffffc02b2908 <check_mm_struct>
ffffffffc02034e4:	6398                	ld	a4,0(a5)
ffffffffc02034e6:	3e071363          	bnez	a4,ffffffffc02038cc <swap_init+0x4ce>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02034ea:	000af717          	auipc	a4,0xaf
ffffffffc02034ee:	3de70713          	addi	a4,a4,990 # ffffffffc02b28c8 <boot_pgdir>
ffffffffc02034f2:	00073b03          	ld	s6,0(a4)
     check_mm_struct = mm;
ffffffffc02034f6:	e388                	sd	a0,0(a5)
     assert(pgdir[0] == 0);
ffffffffc02034f8:	000b3783          	ld	a5,0(s6)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02034fc:	01653c23          	sd	s6,24(a0)
     assert(pgdir[0] == 0);
ffffffffc0203500:	42079663          	bnez	a5,ffffffffc020392c <swap_init+0x52e>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0203504:	6599                	lui	a1,0x6
ffffffffc0203506:	460d                	li	a2,3
ffffffffc0203508:	6505                	lui	a0,0x1
ffffffffc020350a:	3c1000ef          	jal	ra,ffffffffc02040ca <vma_create>
ffffffffc020350e:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0203510:	52050a63          	beqz	a0,ffffffffc0203a44 <swap_init+0x646>

     insert_vma_struct(mm, vma);
ffffffffc0203514:	8556                	mv	a0,s5
ffffffffc0203516:	423000ef          	jal	ra,ffffffffc0204138 <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc020351a:	00004517          	auipc	a0,0x4
ffffffffc020351e:	48650513          	addi	a0,a0,1158 # ffffffffc02079a0 <default_pmm_manager+0x7d0>
ffffffffc0203522:	c5ffc0ef          	jal	ra,ffffffffc0200180 <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc0203526:	018ab503          	ld	a0,24(s5)
ffffffffc020352a:	4605                	li	a2,1
ffffffffc020352c:	6585                	lui	a1,0x1
ffffffffc020352e:	89bfe0ef          	jal	ra,ffffffffc0201dc8 <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc0203532:	4c050963          	beqz	a0,ffffffffc0203a04 <swap_init+0x606>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0203536:	00004517          	auipc	a0,0x4
ffffffffc020353a:	4ba50513          	addi	a0,a0,1210 # ffffffffc02079f0 <default_pmm_manager+0x820>
ffffffffc020353e:	000ab497          	auipc	s1,0xab
ffffffffc0203542:	2d248493          	addi	s1,s1,722 # ffffffffc02ae810 <check_rp>
ffffffffc0203546:	c3bfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020354a:	000ab997          	auipc	s3,0xab
ffffffffc020354e:	2e698993          	addi	s3,s3,742 # ffffffffc02ae830 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0203552:	8a26                	mv	s4,s1
          check_rp[i] = alloc_page();
ffffffffc0203554:	4505                	li	a0,1
ffffffffc0203556:	f66fe0ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc020355a:	00aa3023          	sd	a0,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
          assert(check_rp[i] != NULL );
ffffffffc020355e:	2c050f63          	beqz	a0,ffffffffc020383c <swap_init+0x43e>
ffffffffc0203562:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0203564:	8b89                	andi	a5,a5,2
ffffffffc0203566:	34079363          	bnez	a5,ffffffffc02038ac <swap_init+0x4ae>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020356a:	0a21                	addi	s4,s4,8
ffffffffc020356c:	ff3a14e3          	bne	s4,s3,ffffffffc0203554 <swap_init+0x156>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0203570:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc0203572:	000aba17          	auipc	s4,0xab
ffffffffc0203576:	29ea0a13          	addi	s4,s4,670 # ffffffffc02ae810 <check_rp>
    elm->prev = elm->next = elm;
ffffffffc020357a:	e000                	sd	s0,0(s0)
     list_entry_t free_list_store = free_list;
ffffffffc020357c:	ec3e                	sd	a5,24(sp)
ffffffffc020357e:	641c                	ld	a5,8(s0)
ffffffffc0203580:	e400                	sd	s0,8(s0)
ffffffffc0203582:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc0203584:	481c                	lw	a5,16(s0)
ffffffffc0203586:	f43e                	sd	a5,40(sp)
     nr_free = 0;
ffffffffc0203588:	000ab797          	auipc	a5,0xab
ffffffffc020358c:	2607a023          	sw	zero,608(a5) # ffffffffc02ae7e8 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0203590:	000a3503          	ld	a0,0(s4)
ffffffffc0203594:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203596:	0a21                	addi	s4,s4,8
        free_pages(check_rp[i],1);
ffffffffc0203598:	fb6fe0ef          	jal	ra,ffffffffc0201d4e <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020359c:	ff3a1ae3          	bne	s4,s3,ffffffffc0203590 <swap_init+0x192>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc02035a0:	01042a03          	lw	s4,16(s0)
ffffffffc02035a4:	4791                	li	a5,4
ffffffffc02035a6:	42fa1f63          	bne	s4,a5,ffffffffc02039e4 <swap_init+0x5e6>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc02035aa:	00004517          	auipc	a0,0x4
ffffffffc02035ae:	4ce50513          	addi	a0,a0,1230 # ffffffffc0207a78 <default_pmm_manager+0x8a8>
ffffffffc02035b2:	bcffc0ef          	jal	ra,ffffffffc0200180 <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc02035b6:	6705                	lui	a4,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc02035b8:	000af797          	auipc	a5,0xaf
ffffffffc02035bc:	3407ac23          	sw	zero,856(a5) # ffffffffc02b2910 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc02035c0:	4629                	li	a2,10
ffffffffc02035c2:	00c70023          	sb	a2,0(a4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
     assert(pgfault_num==1);
ffffffffc02035c6:	000af697          	auipc	a3,0xaf
ffffffffc02035ca:	34a6a683          	lw	a3,842(a3) # ffffffffc02b2910 <pgfault_num>
ffffffffc02035ce:	4585                	li	a1,1
ffffffffc02035d0:	000af797          	auipc	a5,0xaf
ffffffffc02035d4:	34078793          	addi	a5,a5,832 # ffffffffc02b2910 <pgfault_num>
ffffffffc02035d8:	54b69663          	bne	a3,a1,ffffffffc0203b24 <swap_init+0x726>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc02035dc:	00c70823          	sb	a2,16(a4)
     assert(pgfault_num==1);
ffffffffc02035e0:	4398                	lw	a4,0(a5)
ffffffffc02035e2:	2701                	sext.w	a4,a4
ffffffffc02035e4:	3ed71063          	bne	a4,a3,ffffffffc02039c4 <swap_init+0x5c6>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc02035e8:	6689                	lui	a3,0x2
ffffffffc02035ea:	462d                	li	a2,11
ffffffffc02035ec:	00c68023          	sb	a2,0(a3) # 2000 <_binary_obj___user_faultread_out_size-0x7bb8>
     assert(pgfault_num==2);
ffffffffc02035f0:	4398                	lw	a4,0(a5)
ffffffffc02035f2:	4589                	li	a1,2
ffffffffc02035f4:	2701                	sext.w	a4,a4
ffffffffc02035f6:	4ab71763          	bne	a4,a1,ffffffffc0203aa4 <swap_init+0x6a6>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc02035fa:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc02035fe:	4394                	lw	a3,0(a5)
ffffffffc0203600:	2681                	sext.w	a3,a3
ffffffffc0203602:	4ce69163          	bne	a3,a4,ffffffffc0203ac4 <swap_init+0x6c6>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203606:	668d                	lui	a3,0x3
ffffffffc0203608:	4631                	li	a2,12
ffffffffc020360a:	00c68023          	sb	a2,0(a3) # 3000 <_binary_obj___user_faultread_out_size-0x6bb8>
     assert(pgfault_num==3);
ffffffffc020360e:	4398                	lw	a4,0(a5)
ffffffffc0203610:	458d                	li	a1,3
ffffffffc0203612:	2701                	sext.w	a4,a4
ffffffffc0203614:	4cb71863          	bne	a4,a1,ffffffffc0203ae4 <swap_init+0x6e6>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc0203618:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc020361c:	4394                	lw	a3,0(a5)
ffffffffc020361e:	2681                	sext.w	a3,a3
ffffffffc0203620:	4ee69263          	bne	a3,a4,ffffffffc0203b04 <swap_init+0x706>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203624:	6691                	lui	a3,0x4
ffffffffc0203626:	4635                	li	a2,13
ffffffffc0203628:	00c68023          	sb	a2,0(a3) # 4000 <_binary_obj___user_faultread_out_size-0x5bb8>
     assert(pgfault_num==4);
ffffffffc020362c:	4398                	lw	a4,0(a5)
ffffffffc020362e:	2701                	sext.w	a4,a4
ffffffffc0203630:	43471a63          	bne	a4,s4,ffffffffc0203a64 <swap_init+0x666>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0203634:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc0203638:	439c                	lw	a5,0(a5)
ffffffffc020363a:	2781                	sext.w	a5,a5
ffffffffc020363c:	44e79463          	bne	a5,a4,ffffffffc0203a84 <swap_init+0x686>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0203640:	481c                	lw	a5,16(s0)
ffffffffc0203642:	2c079563          	bnez	a5,ffffffffc020390c <swap_init+0x50e>
ffffffffc0203646:	000ab797          	auipc	a5,0xab
ffffffffc020364a:	1ea78793          	addi	a5,a5,490 # ffffffffc02ae830 <swap_in_seq_no>
ffffffffc020364e:	000ab717          	auipc	a4,0xab
ffffffffc0203652:	20a70713          	addi	a4,a4,522 # ffffffffc02ae858 <swap_out_seq_no>
ffffffffc0203656:	000ab617          	auipc	a2,0xab
ffffffffc020365a:	20260613          	addi	a2,a2,514 # ffffffffc02ae858 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc020365e:	56fd                	li	a3,-1
ffffffffc0203660:	c394                	sw	a3,0(a5)
ffffffffc0203662:	c314                	sw	a3,0(a4)
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0203664:	0791                	addi	a5,a5,4
ffffffffc0203666:	0711                	addi	a4,a4,4
ffffffffc0203668:	fec79ce3          	bne	a5,a2,ffffffffc0203660 <swap_init+0x262>
ffffffffc020366c:	000ab717          	auipc	a4,0xab
ffffffffc0203670:	18470713          	addi	a4,a4,388 # ffffffffc02ae7f0 <check_ptep>
ffffffffc0203674:	000ab697          	auipc	a3,0xab
ffffffffc0203678:	19c68693          	addi	a3,a3,412 # ffffffffc02ae810 <check_rp>
ffffffffc020367c:	6585                	lui	a1,0x1
    if (PPN(pa) >= npage) {
ffffffffc020367e:	000afc17          	auipc	s8,0xaf
ffffffffc0203682:	252c0c13          	addi	s8,s8,594 # ffffffffc02b28d0 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203686:	000afc97          	auipc	s9,0xaf
ffffffffc020368a:	252c8c93          	addi	s9,s9,594 # ffffffffc02b28d8 <pages>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc020368e:	00073023          	sd	zero,0(a4)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0203692:	4601                	li	a2,0
ffffffffc0203694:	855a                	mv	a0,s6
ffffffffc0203696:	e836                	sd	a3,16(sp)
ffffffffc0203698:	e42e                	sd	a1,8(sp)
         check_ptep[i]=0;
ffffffffc020369a:	e03a                	sd	a4,0(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc020369c:	f2cfe0ef          	jal	ra,ffffffffc0201dc8 <get_pte>
ffffffffc02036a0:	6702                	ld	a4,0(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc02036a2:	65a2                	ld	a1,8(sp)
ffffffffc02036a4:	66c2                	ld	a3,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc02036a6:	e308                	sd	a0,0(a4)
         assert(check_ptep[i] != NULL);
ffffffffc02036a8:	1c050663          	beqz	a0,ffffffffc0203874 <swap_init+0x476>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc02036ac:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02036ae:	0017f613          	andi	a2,a5,1
ffffffffc02036b2:	1e060163          	beqz	a2,ffffffffc0203894 <swap_init+0x496>
    if (PPN(pa) >= npage) {
ffffffffc02036b6:	000c3603          	ld	a2,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc02036ba:	078a                	slli	a5,a5,0x2
ffffffffc02036bc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02036be:	14c7f363          	bgeu	a5,a2,ffffffffc0203804 <swap_init+0x406>
    return &pages[PPN(pa) - nbase];
ffffffffc02036c2:	00005617          	auipc	a2,0x5
ffffffffc02036c6:	43e60613          	addi	a2,a2,1086 # ffffffffc0208b00 <nbase>
ffffffffc02036ca:	00063a03          	ld	s4,0(a2)
ffffffffc02036ce:	000cb603          	ld	a2,0(s9)
ffffffffc02036d2:	6288                	ld	a0,0(a3)
ffffffffc02036d4:	414787b3          	sub	a5,a5,s4
ffffffffc02036d8:	079a                	slli	a5,a5,0x6
ffffffffc02036da:	97b2                	add	a5,a5,a2
ffffffffc02036dc:	14f51063          	bne	a0,a5,ffffffffc020381c <swap_init+0x41e>
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02036e0:	6785                	lui	a5,0x1
ffffffffc02036e2:	95be                	add	a1,a1,a5
ffffffffc02036e4:	6795                	lui	a5,0x5
ffffffffc02036e6:	0721                	addi	a4,a4,8
ffffffffc02036e8:	06a1                	addi	a3,a3,8
ffffffffc02036ea:	faf592e3          	bne	a1,a5,ffffffffc020368e <swap_init+0x290>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc02036ee:	00004517          	auipc	a0,0x4
ffffffffc02036f2:	43250513          	addi	a0,a0,1074 # ffffffffc0207b20 <default_pmm_manager+0x950>
ffffffffc02036f6:	a8bfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    int ret = sm->check_swap();
ffffffffc02036fa:	000bb783          	ld	a5,0(s7)
ffffffffc02036fe:	7f9c                	ld	a5,56(a5)
ffffffffc0203700:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc0203702:	32051163          	bnez	a0,ffffffffc0203a24 <swap_init+0x626>

     nr_free = nr_free_store;
ffffffffc0203706:	77a2                	ld	a5,40(sp)
ffffffffc0203708:	c81c                	sw	a5,16(s0)
     free_list = free_list_store;
ffffffffc020370a:	67e2                	ld	a5,24(sp)
ffffffffc020370c:	e01c                	sd	a5,0(s0)
ffffffffc020370e:	7782                	ld	a5,32(sp)
ffffffffc0203710:	e41c                	sd	a5,8(s0)

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc0203712:	6088                	ld	a0,0(s1)
ffffffffc0203714:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203716:	04a1                	addi	s1,s1,8
         free_pages(check_rp[i],1);
ffffffffc0203718:	e36fe0ef          	jal	ra,ffffffffc0201d4e <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020371c:	ff349be3          	bne	s1,s3,ffffffffc0203712 <swap_init+0x314>
     } 

     //free_page(pte2page(*temp_ptep));

     mm->pgdir = NULL;
ffffffffc0203720:	000abc23          	sd	zero,24(s5)
     mm_destroy(mm);
ffffffffc0203724:	8556                	mv	a0,s5
ffffffffc0203726:	2e3000ef          	jal	ra,ffffffffc0204208 <mm_destroy>
     check_mm_struct = NULL;

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc020372a:	000af797          	auipc	a5,0xaf
ffffffffc020372e:	19e78793          	addi	a5,a5,414 # ffffffffc02b28c8 <boot_pgdir>
ffffffffc0203732:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0203734:	000c3703          	ld	a4,0(s8)
     check_mm_struct = NULL;
ffffffffc0203738:	000af697          	auipc	a3,0xaf
ffffffffc020373c:	1c06b823          	sd	zero,464(a3) # ffffffffc02b2908 <check_mm_struct>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203740:	639c                	ld	a5,0(a5)
ffffffffc0203742:	078a                	slli	a5,a5,0x2
ffffffffc0203744:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203746:	0ae7fd63          	bgeu	a5,a4,ffffffffc0203800 <swap_init+0x402>
    return &pages[PPN(pa) - nbase];
ffffffffc020374a:	414786b3          	sub	a3,a5,s4
ffffffffc020374e:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc0203750:	8699                	srai	a3,a3,0x6
ffffffffc0203752:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc0203754:	00c69793          	slli	a5,a3,0xc
ffffffffc0203758:	83b1                	srli	a5,a5,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc020375a:	000cb503          	ld	a0,0(s9)
    return page2ppn(page) << PGSHIFT;
ffffffffc020375e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203760:	22e7f663          	bgeu	a5,a4,ffffffffc020398c <swap_init+0x58e>
     free_page(pde2page(pd0[0]));
ffffffffc0203764:	000af797          	auipc	a5,0xaf
ffffffffc0203768:	1847b783          	ld	a5,388(a5) # ffffffffc02b28e8 <va_pa_offset>
ffffffffc020376c:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020376e:	629c                	ld	a5,0(a3)
ffffffffc0203770:	078a                	slli	a5,a5,0x2
ffffffffc0203772:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203774:	08e7f663          	bgeu	a5,a4,ffffffffc0203800 <swap_init+0x402>
    return &pages[PPN(pa) - nbase];
ffffffffc0203778:	414787b3          	sub	a5,a5,s4
ffffffffc020377c:	079a                	slli	a5,a5,0x6
ffffffffc020377e:	953e                	add	a0,a0,a5
ffffffffc0203780:	4585                	li	a1,1
ffffffffc0203782:	dccfe0ef          	jal	ra,ffffffffc0201d4e <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203786:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc020378a:	000c3703          	ld	a4,0(s8)
    return pa2page(PDE_ADDR(pde));
ffffffffc020378e:	078a                	slli	a5,a5,0x2
ffffffffc0203790:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203792:	06e7f763          	bgeu	a5,a4,ffffffffc0203800 <swap_init+0x402>
    return &pages[PPN(pa) - nbase];
ffffffffc0203796:	000cb503          	ld	a0,0(s9)
ffffffffc020379a:	414787b3          	sub	a5,a5,s4
ffffffffc020379e:	079a                	slli	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc02037a0:	4585                	li	a1,1
ffffffffc02037a2:	953e                	add	a0,a0,a5
ffffffffc02037a4:	daafe0ef          	jal	ra,ffffffffc0201d4e <free_pages>
     pgdir[0] = 0;
ffffffffc02037a8:	000b3023          	sd	zero,0(s6)
  asm volatile("sfence.vma");
ffffffffc02037ac:	12000073          	sfence.vma
    return listelm->next;
ffffffffc02037b0:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc02037b2:	00878a63          	beq	a5,s0,ffffffffc02037c6 <swap_init+0x3c8>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc02037b6:	ff87a703          	lw	a4,-8(a5)
ffffffffc02037ba:	679c                	ld	a5,8(a5)
ffffffffc02037bc:	3dfd                	addiw	s11,s11,-1
ffffffffc02037be:	40ed0d3b          	subw	s10,s10,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc02037c2:	fe879ae3          	bne	a5,s0,ffffffffc02037b6 <swap_init+0x3b8>
     }
     assert(count==0);
ffffffffc02037c6:	1c0d9f63          	bnez	s11,ffffffffc02039a4 <swap_init+0x5a6>
     assert(total==0);
ffffffffc02037ca:	1a0d1163          	bnez	s10,ffffffffc020396c <swap_init+0x56e>

     cprintf("check_swap() succeeded!\n");
ffffffffc02037ce:	00004517          	auipc	a0,0x4
ffffffffc02037d2:	3a250513          	addi	a0,a0,930 # ffffffffc0207b70 <default_pmm_manager+0x9a0>
ffffffffc02037d6:	9abfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
}
ffffffffc02037da:	b99d                	j	ffffffffc0203450 <swap_init+0x52>
     while ((le = list_next(le)) != &free_list) {
ffffffffc02037dc:	4481                	li	s1,0
ffffffffc02037de:	b9f1                	j	ffffffffc02034ba <swap_init+0xbc>
        assert(PageProperty(p));
ffffffffc02037e0:	00003697          	auipc	a3,0x3
ffffffffc02037e4:	64868693          	addi	a3,a3,1608 # ffffffffc0206e28 <commands+0x740>
ffffffffc02037e8:	00003617          	auipc	a2,0x3
ffffffffc02037ec:	35060613          	addi	a2,a2,848 # ffffffffc0206b38 <commands+0x450>
ffffffffc02037f0:	0bc00593          	li	a1,188
ffffffffc02037f4:	00004517          	auipc	a0,0x4
ffffffffc02037f8:	11450513          	addi	a0,a0,276 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc02037fc:	c7ffc0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0203800:	be3ff0ef          	jal	ra,ffffffffc02033e2 <pa2page.part.0>
        panic("pa2page called with invalid pa");
ffffffffc0203804:	00004617          	auipc	a2,0x4
ffffffffc0203808:	ad460613          	addi	a2,a2,-1324 # ffffffffc02072d8 <default_pmm_manager+0x108>
ffffffffc020380c:	06200593          	li	a1,98
ffffffffc0203810:	00004517          	auipc	a0,0x4
ffffffffc0203814:	a2050513          	addi	a0,a0,-1504 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc0203818:	c63fc0ef          	jal	ra,ffffffffc020047a <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc020381c:	00004697          	auipc	a3,0x4
ffffffffc0203820:	2dc68693          	addi	a3,a3,732 # ffffffffc0207af8 <default_pmm_manager+0x928>
ffffffffc0203824:	00003617          	auipc	a2,0x3
ffffffffc0203828:	31460613          	addi	a2,a2,788 # ffffffffc0206b38 <commands+0x450>
ffffffffc020382c:	0fc00593          	li	a1,252
ffffffffc0203830:	00004517          	auipc	a0,0x4
ffffffffc0203834:	0d850513          	addi	a0,a0,216 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203838:	c43fc0ef          	jal	ra,ffffffffc020047a <__panic>
          assert(check_rp[i] != NULL );
ffffffffc020383c:	00004697          	auipc	a3,0x4
ffffffffc0203840:	1dc68693          	addi	a3,a3,476 # ffffffffc0207a18 <default_pmm_manager+0x848>
ffffffffc0203844:	00003617          	auipc	a2,0x3
ffffffffc0203848:	2f460613          	addi	a2,a2,756 # ffffffffc0206b38 <commands+0x450>
ffffffffc020384c:	0dc00593          	li	a1,220
ffffffffc0203850:	00004517          	auipc	a0,0x4
ffffffffc0203854:	0b850513          	addi	a0,a0,184 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203858:	c23fc0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc020385c:	00004617          	auipc	a2,0x4
ffffffffc0203860:	08c60613          	addi	a2,a2,140 # ffffffffc02078e8 <default_pmm_manager+0x718>
ffffffffc0203864:	02800593          	li	a1,40
ffffffffc0203868:	00004517          	auipc	a0,0x4
ffffffffc020386c:	0a050513          	addi	a0,a0,160 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203870:	c0bfc0ef          	jal	ra,ffffffffc020047a <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc0203874:	00004697          	auipc	a3,0x4
ffffffffc0203878:	26c68693          	addi	a3,a3,620 # ffffffffc0207ae0 <default_pmm_manager+0x910>
ffffffffc020387c:	00003617          	auipc	a2,0x3
ffffffffc0203880:	2bc60613          	addi	a2,a2,700 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203884:	0fb00593          	li	a1,251
ffffffffc0203888:	00004517          	auipc	a0,0x4
ffffffffc020388c:	08050513          	addi	a0,a0,128 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203890:	bebfc0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0203894:	00004617          	auipc	a2,0x4
ffffffffc0203898:	a6460613          	addi	a2,a2,-1436 # ffffffffc02072f8 <default_pmm_manager+0x128>
ffffffffc020389c:	07400593          	li	a1,116
ffffffffc02038a0:	00004517          	auipc	a0,0x4
ffffffffc02038a4:	99050513          	addi	a0,a0,-1648 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc02038a8:	bd3fc0ef          	jal	ra,ffffffffc020047a <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc02038ac:	00004697          	auipc	a3,0x4
ffffffffc02038b0:	18468693          	addi	a3,a3,388 # ffffffffc0207a30 <default_pmm_manager+0x860>
ffffffffc02038b4:	00003617          	auipc	a2,0x3
ffffffffc02038b8:	28460613          	addi	a2,a2,644 # ffffffffc0206b38 <commands+0x450>
ffffffffc02038bc:	0dd00593          	li	a1,221
ffffffffc02038c0:	00004517          	auipc	a0,0x4
ffffffffc02038c4:	04850513          	addi	a0,a0,72 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc02038c8:	bb3fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(check_mm_struct == NULL);
ffffffffc02038cc:	00004697          	auipc	a3,0x4
ffffffffc02038d0:	09c68693          	addi	a3,a3,156 # ffffffffc0207968 <default_pmm_manager+0x798>
ffffffffc02038d4:	00003617          	auipc	a2,0x3
ffffffffc02038d8:	26460613          	addi	a2,a2,612 # ffffffffc0206b38 <commands+0x450>
ffffffffc02038dc:	0c700593          	li	a1,199
ffffffffc02038e0:	00004517          	auipc	a0,0x4
ffffffffc02038e4:	02850513          	addi	a0,a0,40 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc02038e8:	b93fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(total == nr_free_pages());
ffffffffc02038ec:	00003697          	auipc	a3,0x3
ffffffffc02038f0:	56468693          	addi	a3,a3,1380 # ffffffffc0206e50 <commands+0x768>
ffffffffc02038f4:	00003617          	auipc	a2,0x3
ffffffffc02038f8:	24460613          	addi	a2,a2,580 # ffffffffc0206b38 <commands+0x450>
ffffffffc02038fc:	0bf00593          	li	a1,191
ffffffffc0203900:	00004517          	auipc	a0,0x4
ffffffffc0203904:	00850513          	addi	a0,a0,8 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203908:	b73fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert( nr_free == 0);         
ffffffffc020390c:	00003697          	auipc	a3,0x3
ffffffffc0203910:	6ec68693          	addi	a3,a3,1772 # ffffffffc0206ff8 <commands+0x910>
ffffffffc0203914:	00003617          	auipc	a2,0x3
ffffffffc0203918:	22460613          	addi	a2,a2,548 # ffffffffc0206b38 <commands+0x450>
ffffffffc020391c:	0f300593          	li	a1,243
ffffffffc0203920:	00004517          	auipc	a0,0x4
ffffffffc0203924:	fe850513          	addi	a0,a0,-24 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203928:	b53fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgdir[0] == 0);
ffffffffc020392c:	00004697          	auipc	a3,0x4
ffffffffc0203930:	05468693          	addi	a3,a3,84 # ffffffffc0207980 <default_pmm_manager+0x7b0>
ffffffffc0203934:	00003617          	auipc	a2,0x3
ffffffffc0203938:	20460613          	addi	a2,a2,516 # ffffffffc0206b38 <commands+0x450>
ffffffffc020393c:	0cc00593          	li	a1,204
ffffffffc0203940:	00004517          	auipc	a0,0x4
ffffffffc0203944:	fc850513          	addi	a0,a0,-56 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203948:	b33fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(mm != NULL);
ffffffffc020394c:	00004697          	auipc	a3,0x4
ffffffffc0203950:	00c68693          	addi	a3,a3,12 # ffffffffc0207958 <default_pmm_manager+0x788>
ffffffffc0203954:	00003617          	auipc	a2,0x3
ffffffffc0203958:	1e460613          	addi	a2,a2,484 # ffffffffc0206b38 <commands+0x450>
ffffffffc020395c:	0c400593          	li	a1,196
ffffffffc0203960:	00004517          	auipc	a0,0x4
ffffffffc0203964:	fa850513          	addi	a0,a0,-88 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203968:	b13fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(total==0);
ffffffffc020396c:	00004697          	auipc	a3,0x4
ffffffffc0203970:	1f468693          	addi	a3,a3,500 # ffffffffc0207b60 <default_pmm_manager+0x990>
ffffffffc0203974:	00003617          	auipc	a2,0x3
ffffffffc0203978:	1c460613          	addi	a2,a2,452 # ffffffffc0206b38 <commands+0x450>
ffffffffc020397c:	11e00593          	li	a1,286
ffffffffc0203980:	00004517          	auipc	a0,0x4
ffffffffc0203984:	f8850513          	addi	a0,a0,-120 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203988:	af3fc0ef          	jal	ra,ffffffffc020047a <__panic>
    return KADDR(page2pa(page));
ffffffffc020398c:	00004617          	auipc	a2,0x4
ffffffffc0203990:	87c60613          	addi	a2,a2,-1924 # ffffffffc0207208 <default_pmm_manager+0x38>
ffffffffc0203994:	06900593          	li	a1,105
ffffffffc0203998:	00004517          	auipc	a0,0x4
ffffffffc020399c:	89850513          	addi	a0,a0,-1896 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc02039a0:	adbfc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(count==0);
ffffffffc02039a4:	00004697          	auipc	a3,0x4
ffffffffc02039a8:	1ac68693          	addi	a3,a3,428 # ffffffffc0207b50 <default_pmm_manager+0x980>
ffffffffc02039ac:	00003617          	auipc	a2,0x3
ffffffffc02039b0:	18c60613          	addi	a2,a2,396 # ffffffffc0206b38 <commands+0x450>
ffffffffc02039b4:	11d00593          	li	a1,285
ffffffffc02039b8:	00004517          	auipc	a0,0x4
ffffffffc02039bc:	f5050513          	addi	a0,a0,-176 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc02039c0:	abbfc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==1);
ffffffffc02039c4:	00004697          	auipc	a3,0x4
ffffffffc02039c8:	0dc68693          	addi	a3,a3,220 # ffffffffc0207aa0 <default_pmm_manager+0x8d0>
ffffffffc02039cc:	00003617          	auipc	a2,0x3
ffffffffc02039d0:	16c60613          	addi	a2,a2,364 # ffffffffc0206b38 <commands+0x450>
ffffffffc02039d4:	09500593          	li	a1,149
ffffffffc02039d8:	00004517          	auipc	a0,0x4
ffffffffc02039dc:	f3050513          	addi	a0,a0,-208 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc02039e0:	a9bfc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc02039e4:	00004697          	auipc	a3,0x4
ffffffffc02039e8:	06c68693          	addi	a3,a3,108 # ffffffffc0207a50 <default_pmm_manager+0x880>
ffffffffc02039ec:	00003617          	auipc	a2,0x3
ffffffffc02039f0:	14c60613          	addi	a2,a2,332 # ffffffffc0206b38 <commands+0x450>
ffffffffc02039f4:	0ea00593          	li	a1,234
ffffffffc02039f8:	00004517          	auipc	a0,0x4
ffffffffc02039fc:	f1050513          	addi	a0,a0,-240 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203a00:	a7bfc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(temp_ptep!= NULL);
ffffffffc0203a04:	00004697          	auipc	a3,0x4
ffffffffc0203a08:	fd468693          	addi	a3,a3,-44 # ffffffffc02079d8 <default_pmm_manager+0x808>
ffffffffc0203a0c:	00003617          	auipc	a2,0x3
ffffffffc0203a10:	12c60613          	addi	a2,a2,300 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203a14:	0d700593          	li	a1,215
ffffffffc0203a18:	00004517          	auipc	a0,0x4
ffffffffc0203a1c:	ef050513          	addi	a0,a0,-272 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203a20:	a5bfc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(ret==0);
ffffffffc0203a24:	00004697          	auipc	a3,0x4
ffffffffc0203a28:	12468693          	addi	a3,a3,292 # ffffffffc0207b48 <default_pmm_manager+0x978>
ffffffffc0203a2c:	00003617          	auipc	a2,0x3
ffffffffc0203a30:	10c60613          	addi	a2,a2,268 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203a34:	10200593          	li	a1,258
ffffffffc0203a38:	00004517          	auipc	a0,0x4
ffffffffc0203a3c:	ed050513          	addi	a0,a0,-304 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203a40:	a3bfc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(vma != NULL);
ffffffffc0203a44:	00004697          	auipc	a3,0x4
ffffffffc0203a48:	f4c68693          	addi	a3,a3,-180 # ffffffffc0207990 <default_pmm_manager+0x7c0>
ffffffffc0203a4c:	00003617          	auipc	a2,0x3
ffffffffc0203a50:	0ec60613          	addi	a2,a2,236 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203a54:	0cf00593          	li	a1,207
ffffffffc0203a58:	00004517          	auipc	a0,0x4
ffffffffc0203a5c:	eb050513          	addi	a0,a0,-336 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203a60:	a1bfc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==4);
ffffffffc0203a64:	00004697          	auipc	a3,0x4
ffffffffc0203a68:	06c68693          	addi	a3,a3,108 # ffffffffc0207ad0 <default_pmm_manager+0x900>
ffffffffc0203a6c:	00003617          	auipc	a2,0x3
ffffffffc0203a70:	0cc60613          	addi	a2,a2,204 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203a74:	09f00593          	li	a1,159
ffffffffc0203a78:	00004517          	auipc	a0,0x4
ffffffffc0203a7c:	e9050513          	addi	a0,a0,-368 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203a80:	9fbfc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==4);
ffffffffc0203a84:	00004697          	auipc	a3,0x4
ffffffffc0203a88:	04c68693          	addi	a3,a3,76 # ffffffffc0207ad0 <default_pmm_manager+0x900>
ffffffffc0203a8c:	00003617          	auipc	a2,0x3
ffffffffc0203a90:	0ac60613          	addi	a2,a2,172 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203a94:	0a100593          	li	a1,161
ffffffffc0203a98:	00004517          	auipc	a0,0x4
ffffffffc0203a9c:	e7050513          	addi	a0,a0,-400 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203aa0:	9dbfc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==2);
ffffffffc0203aa4:	00004697          	auipc	a3,0x4
ffffffffc0203aa8:	00c68693          	addi	a3,a3,12 # ffffffffc0207ab0 <default_pmm_manager+0x8e0>
ffffffffc0203aac:	00003617          	auipc	a2,0x3
ffffffffc0203ab0:	08c60613          	addi	a2,a2,140 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203ab4:	09700593          	li	a1,151
ffffffffc0203ab8:	00004517          	auipc	a0,0x4
ffffffffc0203abc:	e5050513          	addi	a0,a0,-432 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203ac0:	9bbfc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==2);
ffffffffc0203ac4:	00004697          	auipc	a3,0x4
ffffffffc0203ac8:	fec68693          	addi	a3,a3,-20 # ffffffffc0207ab0 <default_pmm_manager+0x8e0>
ffffffffc0203acc:	00003617          	auipc	a2,0x3
ffffffffc0203ad0:	06c60613          	addi	a2,a2,108 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203ad4:	09900593          	li	a1,153
ffffffffc0203ad8:	00004517          	auipc	a0,0x4
ffffffffc0203adc:	e3050513          	addi	a0,a0,-464 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203ae0:	99bfc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==3);
ffffffffc0203ae4:	00004697          	auipc	a3,0x4
ffffffffc0203ae8:	fdc68693          	addi	a3,a3,-36 # ffffffffc0207ac0 <default_pmm_manager+0x8f0>
ffffffffc0203aec:	00003617          	auipc	a2,0x3
ffffffffc0203af0:	04c60613          	addi	a2,a2,76 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203af4:	09b00593          	li	a1,155
ffffffffc0203af8:	00004517          	auipc	a0,0x4
ffffffffc0203afc:	e1050513          	addi	a0,a0,-496 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203b00:	97bfc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==3);
ffffffffc0203b04:	00004697          	auipc	a3,0x4
ffffffffc0203b08:	fbc68693          	addi	a3,a3,-68 # ffffffffc0207ac0 <default_pmm_manager+0x8f0>
ffffffffc0203b0c:	00003617          	auipc	a2,0x3
ffffffffc0203b10:	02c60613          	addi	a2,a2,44 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203b14:	09d00593          	li	a1,157
ffffffffc0203b18:	00004517          	auipc	a0,0x4
ffffffffc0203b1c:	df050513          	addi	a0,a0,-528 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203b20:	95bfc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==1);
ffffffffc0203b24:	00004697          	auipc	a3,0x4
ffffffffc0203b28:	f7c68693          	addi	a3,a3,-132 # ffffffffc0207aa0 <default_pmm_manager+0x8d0>
ffffffffc0203b2c:	00003617          	auipc	a2,0x3
ffffffffc0203b30:	00c60613          	addi	a2,a2,12 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203b34:	09300593          	li	a1,147
ffffffffc0203b38:	00004517          	auipc	a0,0x4
ffffffffc0203b3c:	dd050513          	addi	a0,a0,-560 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203b40:	93bfc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203b44 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0203b44:	000af797          	auipc	a5,0xaf
ffffffffc0203b48:	db47b783          	ld	a5,-588(a5) # ffffffffc02b28f8 <sm>
ffffffffc0203b4c:	6b9c                	ld	a5,16(a5)
ffffffffc0203b4e:	8782                	jr	a5

ffffffffc0203b50 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0203b50:	000af797          	auipc	a5,0xaf
ffffffffc0203b54:	da87b783          	ld	a5,-600(a5) # ffffffffc02b28f8 <sm>
ffffffffc0203b58:	739c                	ld	a5,32(a5)
ffffffffc0203b5a:	8782                	jr	a5

ffffffffc0203b5c <swap_out>:
{
ffffffffc0203b5c:	711d                	addi	sp,sp,-96
ffffffffc0203b5e:	ec86                	sd	ra,88(sp)
ffffffffc0203b60:	e8a2                	sd	s0,80(sp)
ffffffffc0203b62:	e4a6                	sd	s1,72(sp)
ffffffffc0203b64:	e0ca                	sd	s2,64(sp)
ffffffffc0203b66:	fc4e                	sd	s3,56(sp)
ffffffffc0203b68:	f852                	sd	s4,48(sp)
ffffffffc0203b6a:	f456                	sd	s5,40(sp)
ffffffffc0203b6c:	f05a                	sd	s6,32(sp)
ffffffffc0203b6e:	ec5e                	sd	s7,24(sp)
ffffffffc0203b70:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc0203b72:	cde9                	beqz	a1,ffffffffc0203c4c <swap_out+0xf0>
ffffffffc0203b74:	8a2e                	mv	s4,a1
ffffffffc0203b76:	892a                	mv	s2,a0
ffffffffc0203b78:	8ab2                	mv	s5,a2
ffffffffc0203b7a:	4401                	li	s0,0
ffffffffc0203b7c:	000af997          	auipc	s3,0xaf
ffffffffc0203b80:	d7c98993          	addi	s3,s3,-644 # ffffffffc02b28f8 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203b84:	00004b17          	auipc	s6,0x4
ffffffffc0203b88:	06cb0b13          	addi	s6,s6,108 # ffffffffc0207bf0 <default_pmm_manager+0xa20>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203b8c:	00004b97          	auipc	s7,0x4
ffffffffc0203b90:	04cb8b93          	addi	s7,s7,76 # ffffffffc0207bd8 <default_pmm_manager+0xa08>
ffffffffc0203b94:	a825                	j	ffffffffc0203bcc <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203b96:	67a2                	ld	a5,8(sp)
ffffffffc0203b98:	8626                	mv	a2,s1
ffffffffc0203b9a:	85a2                	mv	a1,s0
ffffffffc0203b9c:	7f94                	ld	a3,56(a5)
ffffffffc0203b9e:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0203ba0:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203ba2:	82b1                	srli	a3,a3,0xc
ffffffffc0203ba4:	0685                	addi	a3,a3,1
ffffffffc0203ba6:	ddafc0ef          	jal	ra,ffffffffc0200180 <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203baa:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc0203bac:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203bae:	7d1c                	ld	a5,56(a0)
ffffffffc0203bb0:	83b1                	srli	a5,a5,0xc
ffffffffc0203bb2:	0785                	addi	a5,a5,1
ffffffffc0203bb4:	07a2                	slli	a5,a5,0x8
ffffffffc0203bb6:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc0203bba:	994fe0ef          	jal	ra,ffffffffc0201d4e <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc0203bbe:	01893503          	ld	a0,24(s2)
ffffffffc0203bc2:	85a6                	mv	a1,s1
ffffffffc0203bc4:	f5eff0ef          	jal	ra,ffffffffc0203322 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0203bc8:	048a0d63          	beq	s4,s0,ffffffffc0203c22 <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc0203bcc:	0009b783          	ld	a5,0(s3)
ffffffffc0203bd0:	8656                	mv	a2,s5
ffffffffc0203bd2:	002c                	addi	a1,sp,8
ffffffffc0203bd4:	7b9c                	ld	a5,48(a5)
ffffffffc0203bd6:	854a                	mv	a0,s2
ffffffffc0203bd8:	9782                	jalr	a5
          if (r != 0) {
ffffffffc0203bda:	e12d                	bnez	a0,ffffffffc0203c3c <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc0203bdc:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203bde:	01893503          	ld	a0,24(s2)
ffffffffc0203be2:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc0203be4:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203be6:	85a6                	mv	a1,s1
ffffffffc0203be8:	9e0fe0ef          	jal	ra,ffffffffc0201dc8 <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203bec:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203bee:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc0203bf0:	8b85                	andi	a5,a5,1
ffffffffc0203bf2:	cfb9                	beqz	a5,ffffffffc0203c50 <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc0203bf4:	65a2                	ld	a1,8(sp)
ffffffffc0203bf6:	7d9c                	ld	a5,56(a1)
ffffffffc0203bf8:	83b1                	srli	a5,a5,0xc
ffffffffc0203bfa:	0785                	addi	a5,a5,1
ffffffffc0203bfc:	00879513          	slli	a0,a5,0x8
ffffffffc0203c00:	6e3000ef          	jal	ra,ffffffffc0204ae2 <swapfs_write>
ffffffffc0203c04:	d949                	beqz	a0,ffffffffc0203b96 <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203c06:	855e                	mv	a0,s7
ffffffffc0203c08:	d78fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203c0c:	0009b783          	ld	a5,0(s3)
ffffffffc0203c10:	6622                	ld	a2,8(sp)
ffffffffc0203c12:	4681                	li	a3,0
ffffffffc0203c14:	739c                	ld	a5,32(a5)
ffffffffc0203c16:	85a6                	mv	a1,s1
ffffffffc0203c18:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc0203c1a:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203c1c:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc0203c1e:	fa8a17e3          	bne	s4,s0,ffffffffc0203bcc <swap_out+0x70>
}
ffffffffc0203c22:	60e6                	ld	ra,88(sp)
ffffffffc0203c24:	8522                	mv	a0,s0
ffffffffc0203c26:	6446                	ld	s0,80(sp)
ffffffffc0203c28:	64a6                	ld	s1,72(sp)
ffffffffc0203c2a:	6906                	ld	s2,64(sp)
ffffffffc0203c2c:	79e2                	ld	s3,56(sp)
ffffffffc0203c2e:	7a42                	ld	s4,48(sp)
ffffffffc0203c30:	7aa2                	ld	s5,40(sp)
ffffffffc0203c32:	7b02                	ld	s6,32(sp)
ffffffffc0203c34:	6be2                	ld	s7,24(sp)
ffffffffc0203c36:	6c42                	ld	s8,16(sp)
ffffffffc0203c38:	6125                	addi	sp,sp,96
ffffffffc0203c3a:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0203c3c:	85a2                	mv	a1,s0
ffffffffc0203c3e:	00004517          	auipc	a0,0x4
ffffffffc0203c42:	f5250513          	addi	a0,a0,-174 # ffffffffc0207b90 <default_pmm_manager+0x9c0>
ffffffffc0203c46:	d3afc0ef          	jal	ra,ffffffffc0200180 <cprintf>
                  break;
ffffffffc0203c4a:	bfe1                	j	ffffffffc0203c22 <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc0203c4c:	4401                	li	s0,0
ffffffffc0203c4e:	bfd1                	j	ffffffffc0203c22 <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203c50:	00004697          	auipc	a3,0x4
ffffffffc0203c54:	f7068693          	addi	a3,a3,-144 # ffffffffc0207bc0 <default_pmm_manager+0x9f0>
ffffffffc0203c58:	00003617          	auipc	a2,0x3
ffffffffc0203c5c:	ee060613          	addi	a2,a2,-288 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203c60:	06800593          	li	a1,104
ffffffffc0203c64:	00004517          	auipc	a0,0x4
ffffffffc0203c68:	ca450513          	addi	a0,a0,-860 # ffffffffc0207908 <default_pmm_manager+0x738>
ffffffffc0203c6c:	80ffc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203c70 <_fifo_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc0203c70:	000ab797          	auipc	a5,0xab
ffffffffc0203c74:	c1078793          	addi	a5,a5,-1008 # ffffffffc02ae880 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
ffffffffc0203c78:	f51c                	sd	a5,40(a0)
ffffffffc0203c7a:	e79c                	sd	a5,8(a5)
ffffffffc0203c7c:	e39c                	sd	a5,0(a5)
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc0203c7e:	4501                	li	a0,0
ffffffffc0203c80:	8082                	ret

ffffffffc0203c82 <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0203c82:	4501                	li	a0,0
ffffffffc0203c84:	8082                	ret

ffffffffc0203c86 <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0203c86:	4501                	li	a0,0
ffffffffc0203c88:	8082                	ret

ffffffffc0203c8a <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc0203c8a:	4501                	li	a0,0
ffffffffc0203c8c:	8082                	ret

ffffffffc0203c8e <_fifo_check_swap>:
_fifo_check_swap(void) {
ffffffffc0203c8e:	711d                	addi	sp,sp,-96
ffffffffc0203c90:	fc4e                	sd	s3,56(sp)
ffffffffc0203c92:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203c94:	00004517          	auipc	a0,0x4
ffffffffc0203c98:	f9c50513          	addi	a0,a0,-100 # ffffffffc0207c30 <default_pmm_manager+0xa60>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203c9c:	698d                	lui	s3,0x3
ffffffffc0203c9e:	4a31                	li	s4,12
_fifo_check_swap(void) {
ffffffffc0203ca0:	e0ca                	sd	s2,64(sp)
ffffffffc0203ca2:	ec86                	sd	ra,88(sp)
ffffffffc0203ca4:	e8a2                	sd	s0,80(sp)
ffffffffc0203ca6:	e4a6                	sd	s1,72(sp)
ffffffffc0203ca8:	f456                	sd	s5,40(sp)
ffffffffc0203caa:	f05a                	sd	s6,32(sp)
ffffffffc0203cac:	ec5e                	sd	s7,24(sp)
ffffffffc0203cae:	e862                	sd	s8,16(sp)
ffffffffc0203cb0:	e466                	sd	s9,8(sp)
ffffffffc0203cb2:	e06a                	sd	s10,0(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203cb4:	cccfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203cb8:	01498023          	sb	s4,0(s3) # 3000 <_binary_obj___user_faultread_out_size-0x6bb8>
    assert(pgfault_num==4);
ffffffffc0203cbc:	000af917          	auipc	s2,0xaf
ffffffffc0203cc0:	c5492903          	lw	s2,-940(s2) # ffffffffc02b2910 <pgfault_num>
ffffffffc0203cc4:	4791                	li	a5,4
ffffffffc0203cc6:	14f91e63          	bne	s2,a5,ffffffffc0203e22 <_fifo_check_swap+0x194>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203cca:	00004517          	auipc	a0,0x4
ffffffffc0203cce:	fa650513          	addi	a0,a0,-90 # ffffffffc0207c70 <default_pmm_manager+0xaa0>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203cd2:	6a85                	lui	s5,0x1
ffffffffc0203cd4:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203cd6:	caafc0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc0203cda:	000af417          	auipc	s0,0xaf
ffffffffc0203cde:	c3640413          	addi	s0,s0,-970 # ffffffffc02b2910 <pgfault_num>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203ce2:	016a8023          	sb	s6,0(s5) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
    assert(pgfault_num==4);
ffffffffc0203ce6:	4004                	lw	s1,0(s0)
ffffffffc0203ce8:	2481                	sext.w	s1,s1
ffffffffc0203cea:	2b249c63          	bne	s1,s2,ffffffffc0203fa2 <_fifo_check_swap+0x314>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203cee:	00004517          	auipc	a0,0x4
ffffffffc0203cf2:	faa50513          	addi	a0,a0,-86 # ffffffffc0207c98 <default_pmm_manager+0xac8>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203cf6:	6b91                	lui	s7,0x4
ffffffffc0203cf8:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203cfa:	c86fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203cfe:	018b8023          	sb	s8,0(s7) # 4000 <_binary_obj___user_faultread_out_size-0x5bb8>
    assert(pgfault_num==4);
ffffffffc0203d02:	00042903          	lw	s2,0(s0)
ffffffffc0203d06:	2901                	sext.w	s2,s2
ffffffffc0203d08:	26991d63          	bne	s2,s1,ffffffffc0203f82 <_fifo_check_swap+0x2f4>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203d0c:	00004517          	auipc	a0,0x4
ffffffffc0203d10:	fb450513          	addi	a0,a0,-76 # ffffffffc0207cc0 <default_pmm_manager+0xaf0>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203d14:	6c89                	lui	s9,0x2
ffffffffc0203d16:	4d2d                	li	s10,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203d18:	c68fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203d1c:	01ac8023          	sb	s10,0(s9) # 2000 <_binary_obj___user_faultread_out_size-0x7bb8>
    assert(pgfault_num==4);
ffffffffc0203d20:	401c                	lw	a5,0(s0)
ffffffffc0203d22:	2781                	sext.w	a5,a5
ffffffffc0203d24:	23279f63          	bne	a5,s2,ffffffffc0203f62 <_fifo_check_swap+0x2d4>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203d28:	00004517          	auipc	a0,0x4
ffffffffc0203d2c:	fc050513          	addi	a0,a0,-64 # ffffffffc0207ce8 <default_pmm_manager+0xb18>
ffffffffc0203d30:	c50fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203d34:	6795                	lui	a5,0x5
ffffffffc0203d36:	4739                	li	a4,14
ffffffffc0203d38:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4bb8>
    assert(pgfault_num==5);
ffffffffc0203d3c:	4004                	lw	s1,0(s0)
ffffffffc0203d3e:	4795                	li	a5,5
ffffffffc0203d40:	2481                	sext.w	s1,s1
ffffffffc0203d42:	20f49063          	bne	s1,a5,ffffffffc0203f42 <_fifo_check_swap+0x2b4>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203d46:	00004517          	auipc	a0,0x4
ffffffffc0203d4a:	f7a50513          	addi	a0,a0,-134 # ffffffffc0207cc0 <default_pmm_manager+0xaf0>
ffffffffc0203d4e:	c32fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203d52:	01ac8023          	sb	s10,0(s9)
    assert(pgfault_num==5);
ffffffffc0203d56:	401c                	lw	a5,0(s0)
ffffffffc0203d58:	2781                	sext.w	a5,a5
ffffffffc0203d5a:	1c979463          	bne	a5,s1,ffffffffc0203f22 <_fifo_check_swap+0x294>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203d5e:	00004517          	auipc	a0,0x4
ffffffffc0203d62:	f1250513          	addi	a0,a0,-238 # ffffffffc0207c70 <default_pmm_manager+0xaa0>
ffffffffc0203d66:	c1afc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203d6a:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num==6);
ffffffffc0203d6e:	401c                	lw	a5,0(s0)
ffffffffc0203d70:	4719                	li	a4,6
ffffffffc0203d72:	2781                	sext.w	a5,a5
ffffffffc0203d74:	18e79763          	bne	a5,a4,ffffffffc0203f02 <_fifo_check_swap+0x274>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203d78:	00004517          	auipc	a0,0x4
ffffffffc0203d7c:	f4850513          	addi	a0,a0,-184 # ffffffffc0207cc0 <default_pmm_manager+0xaf0>
ffffffffc0203d80:	c00fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203d84:	01ac8023          	sb	s10,0(s9)
    assert(pgfault_num==7);
ffffffffc0203d88:	401c                	lw	a5,0(s0)
ffffffffc0203d8a:	471d                	li	a4,7
ffffffffc0203d8c:	2781                	sext.w	a5,a5
ffffffffc0203d8e:	14e79a63          	bne	a5,a4,ffffffffc0203ee2 <_fifo_check_swap+0x254>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203d92:	00004517          	auipc	a0,0x4
ffffffffc0203d96:	e9e50513          	addi	a0,a0,-354 # ffffffffc0207c30 <default_pmm_manager+0xa60>
ffffffffc0203d9a:	be6fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203d9e:	01498023          	sb	s4,0(s3)
    assert(pgfault_num==8);
ffffffffc0203da2:	401c                	lw	a5,0(s0)
ffffffffc0203da4:	4721                	li	a4,8
ffffffffc0203da6:	2781                	sext.w	a5,a5
ffffffffc0203da8:	10e79d63          	bne	a5,a4,ffffffffc0203ec2 <_fifo_check_swap+0x234>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203dac:	00004517          	auipc	a0,0x4
ffffffffc0203db0:	eec50513          	addi	a0,a0,-276 # ffffffffc0207c98 <default_pmm_manager+0xac8>
ffffffffc0203db4:	bccfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203db8:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num==9);
ffffffffc0203dbc:	401c                	lw	a5,0(s0)
ffffffffc0203dbe:	4725                	li	a4,9
ffffffffc0203dc0:	2781                	sext.w	a5,a5
ffffffffc0203dc2:	0ee79063          	bne	a5,a4,ffffffffc0203ea2 <_fifo_check_swap+0x214>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203dc6:	00004517          	auipc	a0,0x4
ffffffffc0203dca:	f2250513          	addi	a0,a0,-222 # ffffffffc0207ce8 <default_pmm_manager+0xb18>
ffffffffc0203dce:	bb2fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203dd2:	6795                	lui	a5,0x5
ffffffffc0203dd4:	4739                	li	a4,14
ffffffffc0203dd6:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4bb8>
    assert(pgfault_num==10);
ffffffffc0203dda:	4004                	lw	s1,0(s0)
ffffffffc0203ddc:	47a9                	li	a5,10
ffffffffc0203dde:	2481                	sext.w	s1,s1
ffffffffc0203de0:	0af49163          	bne	s1,a5,ffffffffc0203e82 <_fifo_check_swap+0x1f4>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203de4:	00004517          	auipc	a0,0x4
ffffffffc0203de8:	e8c50513          	addi	a0,a0,-372 # ffffffffc0207c70 <default_pmm_manager+0xaa0>
ffffffffc0203dec:	b94fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203df0:	6785                	lui	a5,0x1
ffffffffc0203df2:	0007c783          	lbu	a5,0(a5) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc0203df6:	06979663          	bne	a5,s1,ffffffffc0203e62 <_fifo_check_swap+0x1d4>
    assert(pgfault_num==11);
ffffffffc0203dfa:	401c                	lw	a5,0(s0)
ffffffffc0203dfc:	472d                	li	a4,11
ffffffffc0203dfe:	2781                	sext.w	a5,a5
ffffffffc0203e00:	04e79163          	bne	a5,a4,ffffffffc0203e42 <_fifo_check_swap+0x1b4>
}
ffffffffc0203e04:	60e6                	ld	ra,88(sp)
ffffffffc0203e06:	6446                	ld	s0,80(sp)
ffffffffc0203e08:	64a6                	ld	s1,72(sp)
ffffffffc0203e0a:	6906                	ld	s2,64(sp)
ffffffffc0203e0c:	79e2                	ld	s3,56(sp)
ffffffffc0203e0e:	7a42                	ld	s4,48(sp)
ffffffffc0203e10:	7aa2                	ld	s5,40(sp)
ffffffffc0203e12:	7b02                	ld	s6,32(sp)
ffffffffc0203e14:	6be2                	ld	s7,24(sp)
ffffffffc0203e16:	6c42                	ld	s8,16(sp)
ffffffffc0203e18:	6ca2                	ld	s9,8(sp)
ffffffffc0203e1a:	6d02                	ld	s10,0(sp)
ffffffffc0203e1c:	4501                	li	a0,0
ffffffffc0203e1e:	6125                	addi	sp,sp,96
ffffffffc0203e20:	8082                	ret
    assert(pgfault_num==4);
ffffffffc0203e22:	00004697          	auipc	a3,0x4
ffffffffc0203e26:	cae68693          	addi	a3,a3,-850 # ffffffffc0207ad0 <default_pmm_manager+0x900>
ffffffffc0203e2a:	00003617          	auipc	a2,0x3
ffffffffc0203e2e:	d0e60613          	addi	a2,a2,-754 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203e32:	05100593          	li	a1,81
ffffffffc0203e36:	00004517          	auipc	a0,0x4
ffffffffc0203e3a:	e2250513          	addi	a0,a0,-478 # ffffffffc0207c58 <default_pmm_manager+0xa88>
ffffffffc0203e3e:	e3cfc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==11);
ffffffffc0203e42:	00004697          	auipc	a3,0x4
ffffffffc0203e46:	f5668693          	addi	a3,a3,-170 # ffffffffc0207d98 <default_pmm_manager+0xbc8>
ffffffffc0203e4a:	00003617          	auipc	a2,0x3
ffffffffc0203e4e:	cee60613          	addi	a2,a2,-786 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203e52:	07300593          	li	a1,115
ffffffffc0203e56:	00004517          	auipc	a0,0x4
ffffffffc0203e5a:	e0250513          	addi	a0,a0,-510 # ffffffffc0207c58 <default_pmm_manager+0xa88>
ffffffffc0203e5e:	e1cfc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203e62:	00004697          	auipc	a3,0x4
ffffffffc0203e66:	f0e68693          	addi	a3,a3,-242 # ffffffffc0207d70 <default_pmm_manager+0xba0>
ffffffffc0203e6a:	00003617          	auipc	a2,0x3
ffffffffc0203e6e:	cce60613          	addi	a2,a2,-818 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203e72:	07100593          	li	a1,113
ffffffffc0203e76:	00004517          	auipc	a0,0x4
ffffffffc0203e7a:	de250513          	addi	a0,a0,-542 # ffffffffc0207c58 <default_pmm_manager+0xa88>
ffffffffc0203e7e:	dfcfc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==10);
ffffffffc0203e82:	00004697          	auipc	a3,0x4
ffffffffc0203e86:	ede68693          	addi	a3,a3,-290 # ffffffffc0207d60 <default_pmm_manager+0xb90>
ffffffffc0203e8a:	00003617          	auipc	a2,0x3
ffffffffc0203e8e:	cae60613          	addi	a2,a2,-850 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203e92:	06f00593          	li	a1,111
ffffffffc0203e96:	00004517          	auipc	a0,0x4
ffffffffc0203e9a:	dc250513          	addi	a0,a0,-574 # ffffffffc0207c58 <default_pmm_manager+0xa88>
ffffffffc0203e9e:	ddcfc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==9);
ffffffffc0203ea2:	00004697          	auipc	a3,0x4
ffffffffc0203ea6:	eae68693          	addi	a3,a3,-338 # ffffffffc0207d50 <default_pmm_manager+0xb80>
ffffffffc0203eaa:	00003617          	auipc	a2,0x3
ffffffffc0203eae:	c8e60613          	addi	a2,a2,-882 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203eb2:	06c00593          	li	a1,108
ffffffffc0203eb6:	00004517          	auipc	a0,0x4
ffffffffc0203eba:	da250513          	addi	a0,a0,-606 # ffffffffc0207c58 <default_pmm_manager+0xa88>
ffffffffc0203ebe:	dbcfc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==8);
ffffffffc0203ec2:	00004697          	auipc	a3,0x4
ffffffffc0203ec6:	e7e68693          	addi	a3,a3,-386 # ffffffffc0207d40 <default_pmm_manager+0xb70>
ffffffffc0203eca:	00003617          	auipc	a2,0x3
ffffffffc0203ece:	c6e60613          	addi	a2,a2,-914 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203ed2:	06900593          	li	a1,105
ffffffffc0203ed6:	00004517          	auipc	a0,0x4
ffffffffc0203eda:	d8250513          	addi	a0,a0,-638 # ffffffffc0207c58 <default_pmm_manager+0xa88>
ffffffffc0203ede:	d9cfc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==7);
ffffffffc0203ee2:	00004697          	auipc	a3,0x4
ffffffffc0203ee6:	e4e68693          	addi	a3,a3,-434 # ffffffffc0207d30 <default_pmm_manager+0xb60>
ffffffffc0203eea:	00003617          	auipc	a2,0x3
ffffffffc0203eee:	c4e60613          	addi	a2,a2,-946 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203ef2:	06600593          	li	a1,102
ffffffffc0203ef6:	00004517          	auipc	a0,0x4
ffffffffc0203efa:	d6250513          	addi	a0,a0,-670 # ffffffffc0207c58 <default_pmm_manager+0xa88>
ffffffffc0203efe:	d7cfc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==6);
ffffffffc0203f02:	00004697          	auipc	a3,0x4
ffffffffc0203f06:	e1e68693          	addi	a3,a3,-482 # ffffffffc0207d20 <default_pmm_manager+0xb50>
ffffffffc0203f0a:	00003617          	auipc	a2,0x3
ffffffffc0203f0e:	c2e60613          	addi	a2,a2,-978 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203f12:	06300593          	li	a1,99
ffffffffc0203f16:	00004517          	auipc	a0,0x4
ffffffffc0203f1a:	d4250513          	addi	a0,a0,-702 # ffffffffc0207c58 <default_pmm_manager+0xa88>
ffffffffc0203f1e:	d5cfc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==5);
ffffffffc0203f22:	00004697          	auipc	a3,0x4
ffffffffc0203f26:	dee68693          	addi	a3,a3,-530 # ffffffffc0207d10 <default_pmm_manager+0xb40>
ffffffffc0203f2a:	00003617          	auipc	a2,0x3
ffffffffc0203f2e:	c0e60613          	addi	a2,a2,-1010 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203f32:	06000593          	li	a1,96
ffffffffc0203f36:	00004517          	auipc	a0,0x4
ffffffffc0203f3a:	d2250513          	addi	a0,a0,-734 # ffffffffc0207c58 <default_pmm_manager+0xa88>
ffffffffc0203f3e:	d3cfc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==5);
ffffffffc0203f42:	00004697          	auipc	a3,0x4
ffffffffc0203f46:	dce68693          	addi	a3,a3,-562 # ffffffffc0207d10 <default_pmm_manager+0xb40>
ffffffffc0203f4a:	00003617          	auipc	a2,0x3
ffffffffc0203f4e:	bee60613          	addi	a2,a2,-1042 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203f52:	05d00593          	li	a1,93
ffffffffc0203f56:	00004517          	auipc	a0,0x4
ffffffffc0203f5a:	d0250513          	addi	a0,a0,-766 # ffffffffc0207c58 <default_pmm_manager+0xa88>
ffffffffc0203f5e:	d1cfc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==4);
ffffffffc0203f62:	00004697          	auipc	a3,0x4
ffffffffc0203f66:	b6e68693          	addi	a3,a3,-1170 # ffffffffc0207ad0 <default_pmm_manager+0x900>
ffffffffc0203f6a:	00003617          	auipc	a2,0x3
ffffffffc0203f6e:	bce60613          	addi	a2,a2,-1074 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203f72:	05a00593          	li	a1,90
ffffffffc0203f76:	00004517          	auipc	a0,0x4
ffffffffc0203f7a:	ce250513          	addi	a0,a0,-798 # ffffffffc0207c58 <default_pmm_manager+0xa88>
ffffffffc0203f7e:	cfcfc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==4);
ffffffffc0203f82:	00004697          	auipc	a3,0x4
ffffffffc0203f86:	b4e68693          	addi	a3,a3,-1202 # ffffffffc0207ad0 <default_pmm_manager+0x900>
ffffffffc0203f8a:	00003617          	auipc	a2,0x3
ffffffffc0203f8e:	bae60613          	addi	a2,a2,-1106 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203f92:	05700593          	li	a1,87
ffffffffc0203f96:	00004517          	auipc	a0,0x4
ffffffffc0203f9a:	cc250513          	addi	a0,a0,-830 # ffffffffc0207c58 <default_pmm_manager+0xa88>
ffffffffc0203f9e:	cdcfc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==4);
ffffffffc0203fa2:	00004697          	auipc	a3,0x4
ffffffffc0203fa6:	b2e68693          	addi	a3,a3,-1234 # ffffffffc0207ad0 <default_pmm_manager+0x900>
ffffffffc0203faa:	00003617          	auipc	a2,0x3
ffffffffc0203fae:	b8e60613          	addi	a2,a2,-1138 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203fb2:	05400593          	li	a1,84
ffffffffc0203fb6:	00004517          	auipc	a0,0x4
ffffffffc0203fba:	ca250513          	addi	a0,a0,-862 # ffffffffc0207c58 <default_pmm_manager+0xa88>
ffffffffc0203fbe:	cbcfc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203fc2 <_fifo_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc0203fc2:	751c                	ld	a5,40(a0)
{
ffffffffc0203fc4:	1141                	addi	sp,sp,-16
ffffffffc0203fc6:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc0203fc8:	cf91                	beqz	a5,ffffffffc0203fe4 <_fifo_swap_out_victim+0x22>
     assert(in_tick==0);
ffffffffc0203fca:	ee0d                	bnez	a2,ffffffffc0204004 <_fifo_swap_out_victim+0x42>
    return listelm->next;
ffffffffc0203fcc:	679c                	ld	a5,8(a5)
}
ffffffffc0203fce:	60a2                	ld	ra,8(sp)
ffffffffc0203fd0:	4501                	li	a0,0
    __list_del(listelm->prev, listelm->next);
ffffffffc0203fd2:	6394                	ld	a3,0(a5)
ffffffffc0203fd4:	6798                	ld	a4,8(a5)
    *ptr_page = le2page(entry, pra_page_link);
ffffffffc0203fd6:	fd878793          	addi	a5,a5,-40
    prev->next = next;
ffffffffc0203fda:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0203fdc:	e314                	sd	a3,0(a4)
ffffffffc0203fde:	e19c                	sd	a5,0(a1)
}
ffffffffc0203fe0:	0141                	addi	sp,sp,16
ffffffffc0203fe2:	8082                	ret
         assert(head != NULL);
ffffffffc0203fe4:	00004697          	auipc	a3,0x4
ffffffffc0203fe8:	dc468693          	addi	a3,a3,-572 # ffffffffc0207da8 <default_pmm_manager+0xbd8>
ffffffffc0203fec:	00003617          	auipc	a2,0x3
ffffffffc0203ff0:	b4c60613          	addi	a2,a2,-1204 # ffffffffc0206b38 <commands+0x450>
ffffffffc0203ff4:	04100593          	li	a1,65
ffffffffc0203ff8:	00004517          	auipc	a0,0x4
ffffffffc0203ffc:	c6050513          	addi	a0,a0,-928 # ffffffffc0207c58 <default_pmm_manager+0xa88>
ffffffffc0204000:	c7afc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(in_tick==0);
ffffffffc0204004:	00004697          	auipc	a3,0x4
ffffffffc0204008:	db468693          	addi	a3,a3,-588 # ffffffffc0207db8 <default_pmm_manager+0xbe8>
ffffffffc020400c:	00003617          	auipc	a2,0x3
ffffffffc0204010:	b2c60613          	addi	a2,a2,-1236 # ffffffffc0206b38 <commands+0x450>
ffffffffc0204014:	04200593          	li	a1,66
ffffffffc0204018:	00004517          	auipc	a0,0x4
ffffffffc020401c:	c4050513          	addi	a0,a0,-960 # ffffffffc0207c58 <default_pmm_manager+0xa88>
ffffffffc0204020:	c5afc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204024 <_fifo_map_swappable>:
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc0204024:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc0204026:	cb91                	beqz	a5,ffffffffc020403a <_fifo_map_swappable+0x16>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0204028:	6394                	ld	a3,0(a5)
ffffffffc020402a:	02860713          	addi	a4,a2,40
    prev->next = next->prev = elm;
ffffffffc020402e:	e398                	sd	a4,0(a5)
ffffffffc0204030:	e698                	sd	a4,8(a3)
}
ffffffffc0204032:	4501                	li	a0,0
    elm->next = next;
ffffffffc0204034:	fa1c                	sd	a5,48(a2)
    elm->prev = prev;
ffffffffc0204036:	f614                	sd	a3,40(a2)
ffffffffc0204038:	8082                	ret
{
ffffffffc020403a:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc020403c:	00004697          	auipc	a3,0x4
ffffffffc0204040:	d8c68693          	addi	a3,a3,-628 # ffffffffc0207dc8 <default_pmm_manager+0xbf8>
ffffffffc0204044:	00003617          	auipc	a2,0x3
ffffffffc0204048:	af460613          	addi	a2,a2,-1292 # ffffffffc0206b38 <commands+0x450>
ffffffffc020404c:	03200593          	li	a1,50
ffffffffc0204050:	00004517          	auipc	a0,0x4
ffffffffc0204054:	c0850513          	addi	a0,a0,-1016 # ffffffffc0207c58 <default_pmm_manager+0xa88>
{
ffffffffc0204058:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc020405a:	c20fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc020405e <check_vma_overlap.part.0>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc020405e:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0204060:	00004697          	auipc	a3,0x4
ffffffffc0204064:	da068693          	addi	a3,a3,-608 # ffffffffc0207e00 <default_pmm_manager+0xc30>
ffffffffc0204068:	00003617          	auipc	a2,0x3
ffffffffc020406c:	ad060613          	addi	a2,a2,-1328 # ffffffffc0206b38 <commands+0x450>
ffffffffc0204070:	06d00593          	li	a1,109
ffffffffc0204074:	00004517          	auipc	a0,0x4
ffffffffc0204078:	dac50513          	addi	a0,a0,-596 # ffffffffc0207e20 <default_pmm_manager+0xc50>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc020407c:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc020407e:	bfcfc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204082 <mm_create>:
mm_create(void) {
ffffffffc0204082:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0204084:	04000513          	li	a0,64
mm_create(void) {
ffffffffc0204088:	e022                	sd	s0,0(sp)
ffffffffc020408a:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020408c:	a53fd0ef          	jal	ra,ffffffffc0201ade <kmalloc>
ffffffffc0204090:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0204092:	c505                	beqz	a0,ffffffffc02040ba <mm_create+0x38>
    elm->prev = elm->next = elm;
ffffffffc0204094:	e408                	sd	a0,8(s0)
ffffffffc0204096:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc0204098:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020409c:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02040a0:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02040a4:	000af797          	auipc	a5,0xaf
ffffffffc02040a8:	85c7a783          	lw	a5,-1956(a5) # ffffffffc02b2900 <swap_init_ok>
ffffffffc02040ac:	ef81                	bnez	a5,ffffffffc02040c4 <mm_create+0x42>
        else mm->sm_priv = NULL;
ffffffffc02040ae:	02053423          	sd	zero,40(a0)
    return mm->mm_count;
}

static inline void
set_mm_count(struct mm_struct *mm, int val) {
    mm->mm_count = val;
ffffffffc02040b2:	02042823          	sw	zero,48(s0)

typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock) {
    *lock = 0;
ffffffffc02040b6:	02043c23          	sd	zero,56(s0)
}
ffffffffc02040ba:	60a2                	ld	ra,8(sp)
ffffffffc02040bc:	8522                	mv	a0,s0
ffffffffc02040be:	6402                	ld	s0,0(sp)
ffffffffc02040c0:	0141                	addi	sp,sp,16
ffffffffc02040c2:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02040c4:	a81ff0ef          	jal	ra,ffffffffc0203b44 <swap_init_mm>
ffffffffc02040c8:	b7ed                	j	ffffffffc02040b2 <mm_create+0x30>

ffffffffc02040ca <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc02040ca:	1101                	addi	sp,sp,-32
ffffffffc02040cc:	e04a                	sd	s2,0(sp)
ffffffffc02040ce:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02040d0:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc02040d4:	e822                	sd	s0,16(sp)
ffffffffc02040d6:	e426                	sd	s1,8(sp)
ffffffffc02040d8:	ec06                	sd	ra,24(sp)
ffffffffc02040da:	84ae                	mv	s1,a1
ffffffffc02040dc:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02040de:	a01fd0ef          	jal	ra,ffffffffc0201ade <kmalloc>
    if (vma != NULL) {
ffffffffc02040e2:	c509                	beqz	a0,ffffffffc02040ec <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc02040e4:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc02040e8:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02040ea:	cd00                	sw	s0,24(a0)
}
ffffffffc02040ec:	60e2                	ld	ra,24(sp)
ffffffffc02040ee:	6442                	ld	s0,16(sp)
ffffffffc02040f0:	64a2                	ld	s1,8(sp)
ffffffffc02040f2:	6902                	ld	s2,0(sp)
ffffffffc02040f4:	6105                	addi	sp,sp,32
ffffffffc02040f6:	8082                	ret

ffffffffc02040f8 <find_vma>:
find_vma(struct mm_struct *mm, uintptr_t addr) {
ffffffffc02040f8:	86aa                	mv	a3,a0
    if (mm != NULL) {
ffffffffc02040fa:	c505                	beqz	a0,ffffffffc0204122 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02040fc:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc02040fe:	c501                	beqz	a0,ffffffffc0204106 <find_vma+0xe>
ffffffffc0204100:	651c                	ld	a5,8(a0)
ffffffffc0204102:	02f5f263          	bgeu	a1,a5,ffffffffc0204126 <find_vma+0x2e>
    return listelm->next;
ffffffffc0204106:	669c                	ld	a5,8(a3)
                while ((le = list_next(le)) != list) {
ffffffffc0204108:	00f68d63          	beq	a3,a5,ffffffffc0204122 <find_vma+0x2a>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc020410c:	fe87b703          	ld	a4,-24(a5)
ffffffffc0204110:	00e5e663          	bltu	a1,a4,ffffffffc020411c <find_vma+0x24>
ffffffffc0204114:	ff07b703          	ld	a4,-16(a5)
ffffffffc0204118:	00e5ec63          	bltu	a1,a4,ffffffffc0204130 <find_vma+0x38>
ffffffffc020411c:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc020411e:	fef697e3          	bne	a3,a5,ffffffffc020410c <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0204122:	4501                	li	a0,0
}
ffffffffc0204124:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0204126:	691c                	ld	a5,16(a0)
ffffffffc0204128:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0204106 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc020412c:	ea88                	sd	a0,16(a3)
ffffffffc020412e:	8082                	ret
                    vma = le2vma(le, list_link);
ffffffffc0204130:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0204134:	ea88                	sd	a0,16(a3)
ffffffffc0204136:	8082                	ret

ffffffffc0204138 <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc0204138:	6590                	ld	a2,8(a1)
ffffffffc020413a:	0105b803          	ld	a6,16(a1) # 1010 <_binary_obj___user_faultread_out_size-0x8ba8>
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc020413e:	1141                	addi	sp,sp,-16
ffffffffc0204140:	e406                	sd	ra,8(sp)
ffffffffc0204142:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0204144:	01066763          	bltu	a2,a6,ffffffffc0204152 <insert_vma_struct+0x1a>
ffffffffc0204148:	a085                	j	ffffffffc02041a8 <insert_vma_struct+0x70>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc020414a:	fe87b703          	ld	a4,-24(a5)
ffffffffc020414e:	04e66863          	bltu	a2,a4,ffffffffc020419e <insert_vma_struct+0x66>
ffffffffc0204152:	86be                	mv	a3,a5
ffffffffc0204154:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0204156:	fef51ae3          	bne	a0,a5,ffffffffc020414a <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc020415a:	02a68463          	beq	a3,a0,ffffffffc0204182 <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc020415e:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0204162:	fe86b883          	ld	a7,-24(a3)
ffffffffc0204166:	08e8f163          	bgeu	a7,a4,ffffffffc02041e8 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020416a:	04e66f63          	bltu	a2,a4,ffffffffc02041c8 <insert_vma_struct+0x90>
    }
    if (le_next != list) {
ffffffffc020416e:	00f50a63          	beq	a0,a5,ffffffffc0204182 <insert_vma_struct+0x4a>
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0204172:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0204176:	05076963          	bltu	a4,a6,ffffffffc02041c8 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc020417a:	ff07b603          	ld	a2,-16(a5)
ffffffffc020417e:	02c77363          	bgeu	a4,a2,ffffffffc02041a4 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc0204182:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0204184:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0204186:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc020418a:	e390                	sd	a2,0(a5)
ffffffffc020418c:	e690                	sd	a2,8(a3)
}
ffffffffc020418e:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0204190:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0204192:	f194                	sd	a3,32(a1)
    mm->map_count ++;
ffffffffc0204194:	0017079b          	addiw	a5,a4,1
ffffffffc0204198:	d11c                	sw	a5,32(a0)
}
ffffffffc020419a:	0141                	addi	sp,sp,16
ffffffffc020419c:	8082                	ret
    if (le_prev != list) {
ffffffffc020419e:	fca690e3          	bne	a3,a0,ffffffffc020415e <insert_vma_struct+0x26>
ffffffffc02041a2:	bfd1                	j	ffffffffc0204176 <insert_vma_struct+0x3e>
ffffffffc02041a4:	ebbff0ef          	jal	ra,ffffffffc020405e <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02041a8:	00004697          	auipc	a3,0x4
ffffffffc02041ac:	c8868693          	addi	a3,a3,-888 # ffffffffc0207e30 <default_pmm_manager+0xc60>
ffffffffc02041b0:	00003617          	auipc	a2,0x3
ffffffffc02041b4:	98860613          	addi	a2,a2,-1656 # ffffffffc0206b38 <commands+0x450>
ffffffffc02041b8:	07400593          	li	a1,116
ffffffffc02041bc:	00004517          	auipc	a0,0x4
ffffffffc02041c0:	c6450513          	addi	a0,a0,-924 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc02041c4:	ab6fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02041c8:	00004697          	auipc	a3,0x4
ffffffffc02041cc:	ca868693          	addi	a3,a3,-856 # ffffffffc0207e70 <default_pmm_manager+0xca0>
ffffffffc02041d0:	00003617          	auipc	a2,0x3
ffffffffc02041d4:	96860613          	addi	a2,a2,-1688 # ffffffffc0206b38 <commands+0x450>
ffffffffc02041d8:	06c00593          	li	a1,108
ffffffffc02041dc:	00004517          	auipc	a0,0x4
ffffffffc02041e0:	c4450513          	addi	a0,a0,-956 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc02041e4:	a96fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02041e8:	00004697          	auipc	a3,0x4
ffffffffc02041ec:	c6868693          	addi	a3,a3,-920 # ffffffffc0207e50 <default_pmm_manager+0xc80>
ffffffffc02041f0:	00003617          	auipc	a2,0x3
ffffffffc02041f4:	94860613          	addi	a2,a2,-1720 # ffffffffc0206b38 <commands+0x450>
ffffffffc02041f8:	06b00593          	li	a1,107
ffffffffc02041fc:	00004517          	auipc	a0,0x4
ffffffffc0204200:	c2450513          	addi	a0,a0,-988 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc0204204:	a76fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204208 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
    assert(mm_count(mm) == 0);
ffffffffc0204208:	591c                	lw	a5,48(a0)
mm_destroy(struct mm_struct *mm) {
ffffffffc020420a:	1141                	addi	sp,sp,-16
ffffffffc020420c:	e406                	sd	ra,8(sp)
ffffffffc020420e:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0204210:	e78d                	bnez	a5,ffffffffc020423a <mm_destroy+0x32>
ffffffffc0204212:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0204214:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc0204216:	00a40c63          	beq	s0,a0,ffffffffc020422e <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc020421a:	6118                	ld	a4,0(a0)
ffffffffc020421c:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc020421e:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0204220:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0204222:	e398                	sd	a4,0(a5)
ffffffffc0204224:	96bfd0ef          	jal	ra,ffffffffc0201b8e <kfree>
    return listelm->next;
ffffffffc0204228:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc020422a:	fea418e3          	bne	s0,a0,ffffffffc020421a <mm_destroy+0x12>
    }
    kfree(mm); //kfree mm
ffffffffc020422e:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc0204230:	6402                	ld	s0,0(sp)
ffffffffc0204232:	60a2                	ld	ra,8(sp)
ffffffffc0204234:	0141                	addi	sp,sp,16
    kfree(mm); //kfree mm
ffffffffc0204236:	959fd06f          	j	ffffffffc0201b8e <kfree>
    assert(mm_count(mm) == 0);
ffffffffc020423a:	00004697          	auipc	a3,0x4
ffffffffc020423e:	c5668693          	addi	a3,a3,-938 # ffffffffc0207e90 <default_pmm_manager+0xcc0>
ffffffffc0204242:	00003617          	auipc	a2,0x3
ffffffffc0204246:	8f660613          	addi	a2,a2,-1802 # ffffffffc0206b38 <commands+0x450>
ffffffffc020424a:	09400593          	li	a1,148
ffffffffc020424e:	00004517          	auipc	a0,0x4
ffffffffc0204252:	bd250513          	addi	a0,a0,-1070 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc0204256:	a24fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc020425a <mm_map>:

int
mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
       struct vma_struct **vma_store) {
ffffffffc020425a:	7139                	addi	sp,sp,-64
ffffffffc020425c:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020425e:	6405                	lui	s0,0x1
ffffffffc0204260:	147d                	addi	s0,s0,-1
ffffffffc0204262:	77fd                	lui	a5,0xfffff
ffffffffc0204264:	9622                	add	a2,a2,s0
ffffffffc0204266:	962e                	add	a2,a2,a1
       struct vma_struct **vma_store) {
ffffffffc0204268:	f426                	sd	s1,40(sp)
ffffffffc020426a:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020426c:	00f5f4b3          	and	s1,a1,a5
       struct vma_struct **vma_store) {
ffffffffc0204270:	f04a                	sd	s2,32(sp)
ffffffffc0204272:	ec4e                	sd	s3,24(sp)
ffffffffc0204274:	e852                	sd	s4,16(sp)
ffffffffc0204276:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end)) {
ffffffffc0204278:	002005b7          	lui	a1,0x200
ffffffffc020427c:	00f67433          	and	s0,a2,a5
ffffffffc0204280:	06b4e363          	bltu	s1,a1,ffffffffc02042e6 <mm_map+0x8c>
ffffffffc0204284:	0684f163          	bgeu	s1,s0,ffffffffc02042e6 <mm_map+0x8c>
ffffffffc0204288:	4785                	li	a5,1
ffffffffc020428a:	07fe                	slli	a5,a5,0x1f
ffffffffc020428c:	0487ed63          	bltu	a5,s0,ffffffffc02042e6 <mm_map+0x8c>
ffffffffc0204290:	89aa                	mv	s3,a0
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0204292:	cd21                	beqz	a0,ffffffffc02042ea <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start) {
ffffffffc0204294:	85a6                	mv	a1,s1
ffffffffc0204296:	8ab6                	mv	s5,a3
ffffffffc0204298:	8a3a                	mv	s4,a4
ffffffffc020429a:	e5fff0ef          	jal	ra,ffffffffc02040f8 <find_vma>
ffffffffc020429e:	c501                	beqz	a0,ffffffffc02042a6 <mm_map+0x4c>
ffffffffc02042a0:	651c                	ld	a5,8(a0)
ffffffffc02042a2:	0487e263          	bltu	a5,s0,ffffffffc02042e6 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02042a6:	03000513          	li	a0,48
ffffffffc02042aa:	835fd0ef          	jal	ra,ffffffffc0201ade <kmalloc>
ffffffffc02042ae:	892a                	mv	s2,a0
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc02042b0:	5571                	li	a0,-4
    if (vma != NULL) {
ffffffffc02042b2:	02090163          	beqz	s2,ffffffffc02042d4 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL) {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc02042b6:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc02042b8:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc02042bc:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc02042c0:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc02042c4:	85ca                	mv	a1,s2
ffffffffc02042c6:	e73ff0ef          	jal	ra,ffffffffc0204138 <insert_vma_struct>
    if (vma_store != NULL) {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc02042ca:	4501                	li	a0,0
    if (vma_store != NULL) {
ffffffffc02042cc:	000a0463          	beqz	s4,ffffffffc02042d4 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc02042d0:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc02042d4:	70e2                	ld	ra,56(sp)
ffffffffc02042d6:	7442                	ld	s0,48(sp)
ffffffffc02042d8:	74a2                	ld	s1,40(sp)
ffffffffc02042da:	7902                	ld	s2,32(sp)
ffffffffc02042dc:	69e2                	ld	s3,24(sp)
ffffffffc02042de:	6a42                	ld	s4,16(sp)
ffffffffc02042e0:	6aa2                	ld	s5,8(sp)
ffffffffc02042e2:	6121                	addi	sp,sp,64
ffffffffc02042e4:	8082                	ret
        return -E_INVAL;
ffffffffc02042e6:	5575                	li	a0,-3
ffffffffc02042e8:	b7f5                	j	ffffffffc02042d4 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02042ea:	00003697          	auipc	a3,0x3
ffffffffc02042ee:	66e68693          	addi	a3,a3,1646 # ffffffffc0207958 <default_pmm_manager+0x788>
ffffffffc02042f2:	00003617          	auipc	a2,0x3
ffffffffc02042f6:	84660613          	addi	a2,a2,-1978 # ffffffffc0206b38 <commands+0x450>
ffffffffc02042fa:	0a700593          	li	a1,167
ffffffffc02042fe:	00004517          	auipc	a0,0x4
ffffffffc0204302:	b2250513          	addi	a0,a0,-1246 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc0204306:	974fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc020430a <dup_mmap>:

int
dup_mmap(struct mm_struct *to, struct mm_struct *from) {
ffffffffc020430a:	7139                	addi	sp,sp,-64
ffffffffc020430c:	fc06                	sd	ra,56(sp)
ffffffffc020430e:	f822                	sd	s0,48(sp)
ffffffffc0204310:	f426                	sd	s1,40(sp)
ffffffffc0204312:	f04a                	sd	s2,32(sp)
ffffffffc0204314:	ec4e                	sd	s3,24(sp)
ffffffffc0204316:	e852                	sd	s4,16(sp)
ffffffffc0204318:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc020431a:	c52d                	beqz	a0,ffffffffc0204384 <dup_mmap+0x7a>
ffffffffc020431c:	892a                	mv	s2,a0
ffffffffc020431e:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0204320:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0204322:	e595                	bnez	a1,ffffffffc020434e <dup_mmap+0x44>
ffffffffc0204324:	a085                	j	ffffffffc0204384 <dup_mmap+0x7a>
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL) {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0204326:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0204328:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ed8>
        vma->vm_end = vm_end;
ffffffffc020432c:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0204330:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0204334:	e05ff0ef          	jal	ra,ffffffffc0204138 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0) {
ffffffffc0204338:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bc8>
ffffffffc020433c:	fe843603          	ld	a2,-24(s0)
ffffffffc0204340:	6c8c                	ld	a1,24(s1)
ffffffffc0204342:	01893503          	ld	a0,24(s2)
ffffffffc0204346:	4701                	li	a4,0
ffffffffc0204348:	dabfe0ef          	jal	ra,ffffffffc02030f2 <copy_range>
ffffffffc020434c:	e105                	bnez	a0,ffffffffc020436c <dup_mmap+0x62>
    return listelm->prev;
ffffffffc020434e:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list) {
ffffffffc0204350:	02848863          	beq	s1,s0,ffffffffc0204380 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204354:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0204358:	fe843a83          	ld	s5,-24(s0)
ffffffffc020435c:	ff043a03          	ld	s4,-16(s0)
ffffffffc0204360:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204364:	f7afd0ef          	jal	ra,ffffffffc0201ade <kmalloc>
ffffffffc0204368:	85aa                	mv	a1,a0
    if (vma != NULL) {
ffffffffc020436a:	fd55                	bnez	a0,ffffffffc0204326 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc020436c:	5571                	li	a0,-4
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc020436e:	70e2                	ld	ra,56(sp)
ffffffffc0204370:	7442                	ld	s0,48(sp)
ffffffffc0204372:	74a2                	ld	s1,40(sp)
ffffffffc0204374:	7902                	ld	s2,32(sp)
ffffffffc0204376:	69e2                	ld	s3,24(sp)
ffffffffc0204378:	6a42                	ld	s4,16(sp)
ffffffffc020437a:	6aa2                	ld	s5,8(sp)
ffffffffc020437c:	6121                	addi	sp,sp,64
ffffffffc020437e:	8082                	ret
    return 0;
ffffffffc0204380:	4501                	li	a0,0
ffffffffc0204382:	b7f5                	j	ffffffffc020436e <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0204384:	00004697          	auipc	a3,0x4
ffffffffc0204388:	b2468693          	addi	a3,a3,-1244 # ffffffffc0207ea8 <default_pmm_manager+0xcd8>
ffffffffc020438c:	00002617          	auipc	a2,0x2
ffffffffc0204390:	7ac60613          	addi	a2,a2,1964 # ffffffffc0206b38 <commands+0x450>
ffffffffc0204394:	0c000593          	li	a1,192
ffffffffc0204398:	00004517          	auipc	a0,0x4
ffffffffc020439c:	a8850513          	addi	a0,a0,-1400 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc02043a0:	8dafc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02043a4 <exit_mmap>:

void
exit_mmap(struct mm_struct *mm) {
ffffffffc02043a4:	1101                	addi	sp,sp,-32
ffffffffc02043a6:	ec06                	sd	ra,24(sp)
ffffffffc02043a8:	e822                	sd	s0,16(sp)
ffffffffc02043aa:	e426                	sd	s1,8(sp)
ffffffffc02043ac:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02043ae:	c531                	beqz	a0,ffffffffc02043fa <exit_mmap+0x56>
ffffffffc02043b0:	591c                	lw	a5,48(a0)
ffffffffc02043b2:	84aa                	mv	s1,a0
ffffffffc02043b4:	e3b9                	bnez	a5,ffffffffc02043fa <exit_mmap+0x56>
    return listelm->next;
ffffffffc02043b6:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc02043b8:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list) {
ffffffffc02043bc:	02850663          	beq	a0,s0,ffffffffc02043e8 <exit_mmap+0x44>
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02043c0:	ff043603          	ld	a2,-16(s0)
ffffffffc02043c4:	fe843583          	ld	a1,-24(s0)
ffffffffc02043c8:	854a                	mv	a0,s2
ffffffffc02043ca:	c25fd0ef          	jal	ra,ffffffffc0201fee <unmap_range>
ffffffffc02043ce:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc02043d0:	fe8498e3          	bne	s1,s0,ffffffffc02043c0 <exit_mmap+0x1c>
ffffffffc02043d4:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list) {
ffffffffc02043d6:	00848c63          	beq	s1,s0,ffffffffc02043ee <exit_mmap+0x4a>
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02043da:	ff043603          	ld	a2,-16(s0)
ffffffffc02043de:	fe843583          	ld	a1,-24(s0)
ffffffffc02043e2:	854a                	mv	a0,s2
ffffffffc02043e4:	d51fd0ef          	jal	ra,ffffffffc0202134 <exit_range>
ffffffffc02043e8:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc02043ea:	fe8498e3          	bne	s1,s0,ffffffffc02043da <exit_mmap+0x36>
    }
}
ffffffffc02043ee:	60e2                	ld	ra,24(sp)
ffffffffc02043f0:	6442                	ld	s0,16(sp)
ffffffffc02043f2:	64a2                	ld	s1,8(sp)
ffffffffc02043f4:	6902                	ld	s2,0(sp)
ffffffffc02043f6:	6105                	addi	sp,sp,32
ffffffffc02043f8:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02043fa:	00004697          	auipc	a3,0x4
ffffffffc02043fe:	ace68693          	addi	a3,a3,-1330 # ffffffffc0207ec8 <default_pmm_manager+0xcf8>
ffffffffc0204402:	00002617          	auipc	a2,0x2
ffffffffc0204406:	73660613          	addi	a2,a2,1846 # ffffffffc0206b38 <commands+0x450>
ffffffffc020440a:	0d600593          	li	a1,214
ffffffffc020440e:	00004517          	auipc	a0,0x4
ffffffffc0204412:	a1250513          	addi	a0,a0,-1518 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc0204416:	864fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc020441a <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc020441a:	7139                	addi	sp,sp,-64
ffffffffc020441c:	f822                	sd	s0,48(sp)
ffffffffc020441e:	f426                	sd	s1,40(sp)
ffffffffc0204420:	fc06                	sd	ra,56(sp)
ffffffffc0204422:	f04a                	sd	s2,32(sp)
ffffffffc0204424:	ec4e                	sd	s3,24(sp)
ffffffffc0204426:	e852                	sd	s4,16(sp)
ffffffffc0204428:	e456                	sd	s5,8(sp)

static void
check_vma_struct(void) {
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
ffffffffc020442a:	c59ff0ef          	jal	ra,ffffffffc0204082 <mm_create>
    assert(mm != NULL);
ffffffffc020442e:	84aa                	mv	s1,a0
ffffffffc0204430:	03200413          	li	s0,50
ffffffffc0204434:	e919                	bnez	a0,ffffffffc020444a <vmm_init+0x30>
ffffffffc0204436:	a991                	j	ffffffffc020488a <vmm_init+0x470>
        vma->vm_start = vm_start;
ffffffffc0204438:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc020443a:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020443c:	00052c23          	sw	zero,24(a0)

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
ffffffffc0204440:	146d                	addi	s0,s0,-5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0204442:	8526                	mv	a0,s1
ffffffffc0204444:	cf5ff0ef          	jal	ra,ffffffffc0204138 <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc0204448:	c80d                	beqz	s0,ffffffffc020447a <vmm_init+0x60>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020444a:	03000513          	li	a0,48
ffffffffc020444e:	e90fd0ef          	jal	ra,ffffffffc0201ade <kmalloc>
ffffffffc0204452:	85aa                	mv	a1,a0
ffffffffc0204454:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc0204458:	f165                	bnez	a0,ffffffffc0204438 <vmm_init+0x1e>
        assert(vma != NULL);
ffffffffc020445a:	00003697          	auipc	a3,0x3
ffffffffc020445e:	53668693          	addi	a3,a3,1334 # ffffffffc0207990 <default_pmm_manager+0x7c0>
ffffffffc0204462:	00002617          	auipc	a2,0x2
ffffffffc0204466:	6d660613          	addi	a2,a2,1750 # ffffffffc0206b38 <commands+0x450>
ffffffffc020446a:	11300593          	li	a1,275
ffffffffc020446e:	00004517          	auipc	a0,0x4
ffffffffc0204472:	9b250513          	addi	a0,a0,-1614 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc0204476:	804fc0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc020447a:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc020447e:	1f900913          	li	s2,505
ffffffffc0204482:	a819                	j	ffffffffc0204498 <vmm_init+0x7e>
        vma->vm_start = vm_start;
ffffffffc0204484:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0204486:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0204488:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc020448c:	0415                	addi	s0,s0,5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc020448e:	8526                	mv	a0,s1
ffffffffc0204490:	ca9ff0ef          	jal	ra,ffffffffc0204138 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0204494:	03240a63          	beq	s0,s2,ffffffffc02044c8 <vmm_init+0xae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204498:	03000513          	li	a0,48
ffffffffc020449c:	e42fd0ef          	jal	ra,ffffffffc0201ade <kmalloc>
ffffffffc02044a0:	85aa                	mv	a1,a0
ffffffffc02044a2:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc02044a6:	fd79                	bnez	a0,ffffffffc0204484 <vmm_init+0x6a>
        assert(vma != NULL);
ffffffffc02044a8:	00003697          	auipc	a3,0x3
ffffffffc02044ac:	4e868693          	addi	a3,a3,1256 # ffffffffc0207990 <default_pmm_manager+0x7c0>
ffffffffc02044b0:	00002617          	auipc	a2,0x2
ffffffffc02044b4:	68860613          	addi	a2,a2,1672 # ffffffffc0206b38 <commands+0x450>
ffffffffc02044b8:	11900593          	li	a1,281
ffffffffc02044bc:	00004517          	auipc	a0,0x4
ffffffffc02044c0:	96450513          	addi	a0,a0,-1692 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc02044c4:	fb7fb0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc02044c8:	649c                	ld	a5,8(s1)
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
        assert(le != &(mm->mmap_list));
ffffffffc02044ca:	471d                	li	a4,7
    for (i = 1; i <= step2; i ++) {
ffffffffc02044cc:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc02044d0:	2cf48d63          	beq	s1,a5,ffffffffc02047aa <vmm_init+0x390>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02044d4:	fe87b683          	ld	a3,-24(a5) # ffffffffffffefe8 <end+0x3fd4c6b4>
ffffffffc02044d8:	ffe70613          	addi	a2,a4,-2
ffffffffc02044dc:	24d61763          	bne	a2,a3,ffffffffc020472a <vmm_init+0x310>
ffffffffc02044e0:	ff07b683          	ld	a3,-16(a5)
ffffffffc02044e4:	24e69363          	bne	a3,a4,ffffffffc020472a <vmm_init+0x310>
    for (i = 1; i <= step2; i ++) {
ffffffffc02044e8:	0715                	addi	a4,a4,5
ffffffffc02044ea:	679c                	ld	a5,8(a5)
ffffffffc02044ec:	feb712e3          	bne	a4,a1,ffffffffc02044d0 <vmm_init+0xb6>
ffffffffc02044f0:	4a1d                	li	s4,7
ffffffffc02044f2:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc02044f4:	1f900a93          	li	s5,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc02044f8:	85a2                	mv	a1,s0
ffffffffc02044fa:	8526                	mv	a0,s1
ffffffffc02044fc:	bfdff0ef          	jal	ra,ffffffffc02040f8 <find_vma>
ffffffffc0204500:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0204502:	30050463          	beqz	a0,ffffffffc020480a <vmm_init+0x3f0>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0204506:	00140593          	addi	a1,s0,1
ffffffffc020450a:	8526                	mv	a0,s1
ffffffffc020450c:	bedff0ef          	jal	ra,ffffffffc02040f8 <find_vma>
ffffffffc0204510:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0204512:	2c050c63          	beqz	a0,ffffffffc02047ea <vmm_init+0x3d0>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0204516:	85d2                	mv	a1,s4
ffffffffc0204518:	8526                	mv	a0,s1
ffffffffc020451a:	bdfff0ef          	jal	ra,ffffffffc02040f8 <find_vma>
        assert(vma3 == NULL);
ffffffffc020451e:	2a051663          	bnez	a0,ffffffffc02047ca <vmm_init+0x3b0>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc0204522:	00340593          	addi	a1,s0,3
ffffffffc0204526:	8526                	mv	a0,s1
ffffffffc0204528:	bd1ff0ef          	jal	ra,ffffffffc02040f8 <find_vma>
        assert(vma4 == NULL);
ffffffffc020452c:	30051f63          	bnez	a0,ffffffffc020484a <vmm_init+0x430>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc0204530:	00440593          	addi	a1,s0,4
ffffffffc0204534:	8526                	mv	a0,s1
ffffffffc0204536:	bc3ff0ef          	jal	ra,ffffffffc02040f8 <find_vma>
        assert(vma5 == NULL);
ffffffffc020453a:	2e051863          	bnez	a0,ffffffffc020482a <vmm_init+0x410>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc020453e:	00893783          	ld	a5,8(s2)
ffffffffc0204542:	20879463          	bne	a5,s0,ffffffffc020474a <vmm_init+0x330>
ffffffffc0204546:	01093783          	ld	a5,16(s2)
ffffffffc020454a:	20fa1063          	bne	s4,a5,ffffffffc020474a <vmm_init+0x330>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc020454e:	0089b783          	ld	a5,8(s3)
ffffffffc0204552:	20879c63          	bne	a5,s0,ffffffffc020476a <vmm_init+0x350>
ffffffffc0204556:	0109b783          	ld	a5,16(s3)
ffffffffc020455a:	20fa1863          	bne	s4,a5,ffffffffc020476a <vmm_init+0x350>
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc020455e:	0415                	addi	s0,s0,5
ffffffffc0204560:	0a15                	addi	s4,s4,5
ffffffffc0204562:	f9541be3          	bne	s0,s5,ffffffffc02044f8 <vmm_init+0xde>
ffffffffc0204566:	4411                	li	s0,4
    }

    for (i =4; i>=0; i--) {
ffffffffc0204568:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc020456a:	85a2                	mv	a1,s0
ffffffffc020456c:	8526                	mv	a0,s1
ffffffffc020456e:	b8bff0ef          	jal	ra,ffffffffc02040f8 <find_vma>
ffffffffc0204572:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL ) {
ffffffffc0204576:	c90d                	beqz	a0,ffffffffc02045a8 <vmm_init+0x18e>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0204578:	6914                	ld	a3,16(a0)
ffffffffc020457a:	6510                	ld	a2,8(a0)
ffffffffc020457c:	00004517          	auipc	a0,0x4
ffffffffc0204580:	a6c50513          	addi	a0,a0,-1428 # ffffffffc0207fe8 <default_pmm_manager+0xe18>
ffffffffc0204584:	bfdfb0ef          	jal	ra,ffffffffc0200180 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0204588:	00004697          	auipc	a3,0x4
ffffffffc020458c:	a8868693          	addi	a3,a3,-1400 # ffffffffc0208010 <default_pmm_manager+0xe40>
ffffffffc0204590:	00002617          	auipc	a2,0x2
ffffffffc0204594:	5a860613          	addi	a2,a2,1448 # ffffffffc0206b38 <commands+0x450>
ffffffffc0204598:	13b00593          	li	a1,315
ffffffffc020459c:	00004517          	auipc	a0,0x4
ffffffffc02045a0:	88450513          	addi	a0,a0,-1916 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc02045a4:	ed7fb0ef          	jal	ra,ffffffffc020047a <__panic>
    for (i =4; i>=0; i--) {
ffffffffc02045a8:	147d                	addi	s0,s0,-1
ffffffffc02045aa:	fd2410e3          	bne	s0,s2,ffffffffc020456a <vmm_init+0x150>
    }

    mm_destroy(mm);
ffffffffc02045ae:	8526                	mv	a0,s1
ffffffffc02045b0:	c59ff0ef          	jal	ra,ffffffffc0204208 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc02045b4:	00004517          	auipc	a0,0x4
ffffffffc02045b8:	a7450513          	addi	a0,a0,-1420 # ffffffffc0208028 <default_pmm_manager+0xe58>
ffffffffc02045bc:	bc5fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02045c0:	fcefd0ef          	jal	ra,ffffffffc0201d8e <nr_free_pages>
ffffffffc02045c4:	892a                	mv	s2,a0

    check_mm_struct = mm_create();
ffffffffc02045c6:	abdff0ef          	jal	ra,ffffffffc0204082 <mm_create>
ffffffffc02045ca:	000ae797          	auipc	a5,0xae
ffffffffc02045ce:	32a7bf23          	sd	a0,830(a5) # ffffffffc02b2908 <check_mm_struct>
ffffffffc02045d2:	842a                	mv	s0,a0
    assert(check_mm_struct != NULL);
ffffffffc02045d4:	28050b63          	beqz	a0,ffffffffc020486a <vmm_init+0x450>

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02045d8:	000ae497          	auipc	s1,0xae
ffffffffc02045dc:	2f04b483          	ld	s1,752(s1) # ffffffffc02b28c8 <boot_pgdir>
    assert(pgdir[0] == 0);
ffffffffc02045e0:	609c                	ld	a5,0(s1)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02045e2:	ed04                	sd	s1,24(a0)
    assert(pgdir[0] == 0);
ffffffffc02045e4:	2e079f63          	bnez	a5,ffffffffc02048e2 <vmm_init+0x4c8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02045e8:	03000513          	li	a0,48
ffffffffc02045ec:	cf2fd0ef          	jal	ra,ffffffffc0201ade <kmalloc>
ffffffffc02045f0:	89aa                	mv	s3,a0
    if (vma != NULL) {
ffffffffc02045f2:	18050c63          	beqz	a0,ffffffffc020478a <vmm_init+0x370>
        vma->vm_end = vm_end;
ffffffffc02045f6:	002007b7          	lui	a5,0x200
ffffffffc02045fa:	00f9b823          	sd	a5,16(s3)
        vma->vm_flags = vm_flags;
ffffffffc02045fe:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0204600:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc0204602:	00f9ac23          	sw	a5,24(s3)
    insert_vma_struct(mm, vma);
ffffffffc0204606:	8522                	mv	a0,s0
        vma->vm_start = vm_start;
ffffffffc0204608:	0009b423          	sd	zero,8(s3)
    insert_vma_struct(mm, vma);
ffffffffc020460c:	b2dff0ef          	jal	ra,ffffffffc0204138 <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0204610:	10000593          	li	a1,256
ffffffffc0204614:	8522                	mv	a0,s0
ffffffffc0204616:	ae3ff0ef          	jal	ra,ffffffffc02040f8 <find_vma>
ffffffffc020461a:	10000793          	li	a5,256

    int i, sum = 0;

    for (i = 0; i < 100; i ++) {
ffffffffc020461e:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0204622:	2ea99063          	bne	s3,a0,ffffffffc0204902 <vmm_init+0x4e8>
        *(char *)(addr + i) = i;
ffffffffc0204626:	00f78023          	sb	a5,0(a5) # 200000 <_binary_obj___user_exit_out_size+0x1f4ed0>
    for (i = 0; i < 100; i ++) {
ffffffffc020462a:	0785                	addi	a5,a5,1
ffffffffc020462c:	fee79de3          	bne	a5,a4,ffffffffc0204626 <vmm_init+0x20c>
        sum += i;
ffffffffc0204630:	6705                	lui	a4,0x1
ffffffffc0204632:	10000793          	li	a5,256
ffffffffc0204636:	35670713          	addi	a4,a4,854 # 1356 <_binary_obj___user_faultread_out_size-0x8862>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc020463a:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc020463e:	0007c683          	lbu	a3,0(a5)
    for (i = 0; i < 100; i ++) {
ffffffffc0204642:	0785                	addi	a5,a5,1
        sum -= *(char *)(addr + i);
ffffffffc0204644:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc0204646:	fec79ce3          	bne	a5,a2,ffffffffc020463e <vmm_init+0x224>
    }

    assert(sum == 0);
ffffffffc020464a:	2e071863          	bnez	a4,ffffffffc020493a <vmm_init+0x520>
    return pa2page(PDE_ADDR(pde));
ffffffffc020464e:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc0204650:	000aea97          	auipc	s5,0xae
ffffffffc0204654:	280a8a93          	addi	s5,s5,640 # ffffffffc02b28d0 <npage>
ffffffffc0204658:	000ab603          	ld	a2,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020465c:	078a                	slli	a5,a5,0x2
ffffffffc020465e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0204660:	2cc7f163          	bgeu	a5,a2,ffffffffc0204922 <vmm_init+0x508>
    return &pages[PPN(pa) - nbase];
ffffffffc0204664:	00004a17          	auipc	s4,0x4
ffffffffc0204668:	49ca3a03          	ld	s4,1180(s4) # ffffffffc0208b00 <nbase>
ffffffffc020466c:	414787b3          	sub	a5,a5,s4
ffffffffc0204670:	079a                	slli	a5,a5,0x6
    return page - pages + nbase;
ffffffffc0204672:	8799                	srai	a5,a5,0x6
ffffffffc0204674:	97d2                	add	a5,a5,s4
    return KADDR(page2pa(page));
ffffffffc0204676:	00c79713          	slli	a4,a5,0xc
ffffffffc020467a:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020467c:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0204680:	24c77563          	bgeu	a4,a2,ffffffffc02048ca <vmm_init+0x4b0>
ffffffffc0204684:	000ae997          	auipc	s3,0xae
ffffffffc0204688:	2649b983          	ld	s3,612(s3) # ffffffffc02b28e8 <va_pa_offset>

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc020468c:	4581                	li	a1,0
ffffffffc020468e:	8526                	mv	a0,s1
ffffffffc0204690:	99b6                	add	s3,s3,a3
ffffffffc0204692:	d35fd0ef          	jal	ra,ffffffffc02023c6 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc0204696:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc020469a:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020469e:	078a                	slli	a5,a5,0x2
ffffffffc02046a0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02046a2:	28e7f063          	bgeu	a5,a4,ffffffffc0204922 <vmm_init+0x508>
    return &pages[PPN(pa) - nbase];
ffffffffc02046a6:	000ae997          	auipc	s3,0xae
ffffffffc02046aa:	23298993          	addi	s3,s3,562 # ffffffffc02b28d8 <pages>
ffffffffc02046ae:	0009b503          	ld	a0,0(s3)
ffffffffc02046b2:	414787b3          	sub	a5,a5,s4
ffffffffc02046b6:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc02046b8:	953e                	add	a0,a0,a5
ffffffffc02046ba:	4585                	li	a1,1
ffffffffc02046bc:	e92fd0ef          	jal	ra,ffffffffc0201d4e <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc02046c0:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc02046c2:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02046c6:	078a                	slli	a5,a5,0x2
ffffffffc02046c8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02046ca:	24e7fc63          	bgeu	a5,a4,ffffffffc0204922 <vmm_init+0x508>
    return &pages[PPN(pa) - nbase];
ffffffffc02046ce:	0009b503          	ld	a0,0(s3)
ffffffffc02046d2:	414787b3          	sub	a5,a5,s4
ffffffffc02046d6:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc02046d8:	4585                	li	a1,1
ffffffffc02046da:	953e                	add	a0,a0,a5
ffffffffc02046dc:	e72fd0ef          	jal	ra,ffffffffc0201d4e <free_pages>
    pgdir[0] = 0;
ffffffffc02046e0:	0004b023          	sd	zero,0(s1)
  asm volatile("sfence.vma");
ffffffffc02046e4:	12000073          	sfence.vma
    flush_tlb();

    mm->pgdir = NULL;
    mm_destroy(mm);
ffffffffc02046e8:	8522                	mv	a0,s0
    mm->pgdir = NULL;
ffffffffc02046ea:	00043c23          	sd	zero,24(s0)
    mm_destroy(mm);
ffffffffc02046ee:	b1bff0ef          	jal	ra,ffffffffc0204208 <mm_destroy>
    check_mm_struct = NULL;
ffffffffc02046f2:	000ae797          	auipc	a5,0xae
ffffffffc02046f6:	2007bb23          	sd	zero,534(a5) # ffffffffc02b2908 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02046fa:	e94fd0ef          	jal	ra,ffffffffc0201d8e <nr_free_pages>
ffffffffc02046fe:	1aa91663          	bne	s2,a0,ffffffffc02048aa <vmm_init+0x490>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0204702:	00004517          	auipc	a0,0x4
ffffffffc0204706:	9b650513          	addi	a0,a0,-1610 # ffffffffc02080b8 <default_pmm_manager+0xee8>
ffffffffc020470a:	a77fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
}
ffffffffc020470e:	7442                	ld	s0,48(sp)
ffffffffc0204710:	70e2                	ld	ra,56(sp)
ffffffffc0204712:	74a2                	ld	s1,40(sp)
ffffffffc0204714:	7902                	ld	s2,32(sp)
ffffffffc0204716:	69e2                	ld	s3,24(sp)
ffffffffc0204718:	6a42                	ld	s4,16(sp)
ffffffffc020471a:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc020471c:	00004517          	auipc	a0,0x4
ffffffffc0204720:	9bc50513          	addi	a0,a0,-1604 # ffffffffc02080d8 <default_pmm_manager+0xf08>
}
ffffffffc0204724:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0204726:	a5bfb06f          	j	ffffffffc0200180 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc020472a:	00003697          	auipc	a3,0x3
ffffffffc020472e:	7d668693          	addi	a3,a3,2006 # ffffffffc0207f00 <default_pmm_manager+0xd30>
ffffffffc0204732:	00002617          	auipc	a2,0x2
ffffffffc0204736:	40660613          	addi	a2,a2,1030 # ffffffffc0206b38 <commands+0x450>
ffffffffc020473a:	12200593          	li	a1,290
ffffffffc020473e:	00003517          	auipc	a0,0x3
ffffffffc0204742:	6e250513          	addi	a0,a0,1762 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc0204746:	d35fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc020474a:	00004697          	auipc	a3,0x4
ffffffffc020474e:	83e68693          	addi	a3,a3,-1986 # ffffffffc0207f88 <default_pmm_manager+0xdb8>
ffffffffc0204752:	00002617          	auipc	a2,0x2
ffffffffc0204756:	3e660613          	addi	a2,a2,998 # ffffffffc0206b38 <commands+0x450>
ffffffffc020475a:	13200593          	li	a1,306
ffffffffc020475e:	00003517          	auipc	a0,0x3
ffffffffc0204762:	6c250513          	addi	a0,a0,1730 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc0204766:	d15fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc020476a:	00004697          	auipc	a3,0x4
ffffffffc020476e:	84e68693          	addi	a3,a3,-1970 # ffffffffc0207fb8 <default_pmm_manager+0xde8>
ffffffffc0204772:	00002617          	auipc	a2,0x2
ffffffffc0204776:	3c660613          	addi	a2,a2,966 # ffffffffc0206b38 <commands+0x450>
ffffffffc020477a:	13300593          	li	a1,307
ffffffffc020477e:	00003517          	auipc	a0,0x3
ffffffffc0204782:	6a250513          	addi	a0,a0,1698 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc0204786:	cf5fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(vma != NULL);
ffffffffc020478a:	00003697          	auipc	a3,0x3
ffffffffc020478e:	20668693          	addi	a3,a3,518 # ffffffffc0207990 <default_pmm_manager+0x7c0>
ffffffffc0204792:	00002617          	auipc	a2,0x2
ffffffffc0204796:	3a660613          	addi	a2,a2,934 # ffffffffc0206b38 <commands+0x450>
ffffffffc020479a:	15200593          	li	a1,338
ffffffffc020479e:	00003517          	auipc	a0,0x3
ffffffffc02047a2:	68250513          	addi	a0,a0,1666 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc02047a6:	cd5fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc02047aa:	00003697          	auipc	a3,0x3
ffffffffc02047ae:	73e68693          	addi	a3,a3,1854 # ffffffffc0207ee8 <default_pmm_manager+0xd18>
ffffffffc02047b2:	00002617          	auipc	a2,0x2
ffffffffc02047b6:	38660613          	addi	a2,a2,902 # ffffffffc0206b38 <commands+0x450>
ffffffffc02047ba:	12000593          	li	a1,288
ffffffffc02047be:	00003517          	auipc	a0,0x3
ffffffffc02047c2:	66250513          	addi	a0,a0,1634 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc02047c6:	cb5fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma3 == NULL);
ffffffffc02047ca:	00003697          	auipc	a3,0x3
ffffffffc02047ce:	78e68693          	addi	a3,a3,1934 # ffffffffc0207f58 <default_pmm_manager+0xd88>
ffffffffc02047d2:	00002617          	auipc	a2,0x2
ffffffffc02047d6:	36660613          	addi	a2,a2,870 # ffffffffc0206b38 <commands+0x450>
ffffffffc02047da:	12c00593          	li	a1,300
ffffffffc02047de:	00003517          	auipc	a0,0x3
ffffffffc02047e2:	64250513          	addi	a0,a0,1602 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc02047e6:	c95fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma2 != NULL);
ffffffffc02047ea:	00003697          	auipc	a3,0x3
ffffffffc02047ee:	75e68693          	addi	a3,a3,1886 # ffffffffc0207f48 <default_pmm_manager+0xd78>
ffffffffc02047f2:	00002617          	auipc	a2,0x2
ffffffffc02047f6:	34660613          	addi	a2,a2,838 # ffffffffc0206b38 <commands+0x450>
ffffffffc02047fa:	12a00593          	li	a1,298
ffffffffc02047fe:	00003517          	auipc	a0,0x3
ffffffffc0204802:	62250513          	addi	a0,a0,1570 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc0204806:	c75fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma1 != NULL);
ffffffffc020480a:	00003697          	auipc	a3,0x3
ffffffffc020480e:	72e68693          	addi	a3,a3,1838 # ffffffffc0207f38 <default_pmm_manager+0xd68>
ffffffffc0204812:	00002617          	auipc	a2,0x2
ffffffffc0204816:	32660613          	addi	a2,a2,806 # ffffffffc0206b38 <commands+0x450>
ffffffffc020481a:	12800593          	li	a1,296
ffffffffc020481e:	00003517          	auipc	a0,0x3
ffffffffc0204822:	60250513          	addi	a0,a0,1538 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc0204826:	c55fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma5 == NULL);
ffffffffc020482a:	00003697          	auipc	a3,0x3
ffffffffc020482e:	74e68693          	addi	a3,a3,1870 # ffffffffc0207f78 <default_pmm_manager+0xda8>
ffffffffc0204832:	00002617          	auipc	a2,0x2
ffffffffc0204836:	30660613          	addi	a2,a2,774 # ffffffffc0206b38 <commands+0x450>
ffffffffc020483a:	13000593          	li	a1,304
ffffffffc020483e:	00003517          	auipc	a0,0x3
ffffffffc0204842:	5e250513          	addi	a0,a0,1506 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc0204846:	c35fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma4 == NULL);
ffffffffc020484a:	00003697          	auipc	a3,0x3
ffffffffc020484e:	71e68693          	addi	a3,a3,1822 # ffffffffc0207f68 <default_pmm_manager+0xd98>
ffffffffc0204852:	00002617          	auipc	a2,0x2
ffffffffc0204856:	2e660613          	addi	a2,a2,742 # ffffffffc0206b38 <commands+0x450>
ffffffffc020485a:	12e00593          	li	a1,302
ffffffffc020485e:	00003517          	auipc	a0,0x3
ffffffffc0204862:	5c250513          	addi	a0,a0,1474 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc0204866:	c15fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(check_mm_struct != NULL);
ffffffffc020486a:	00003697          	auipc	a3,0x3
ffffffffc020486e:	7de68693          	addi	a3,a3,2014 # ffffffffc0208048 <default_pmm_manager+0xe78>
ffffffffc0204872:	00002617          	auipc	a2,0x2
ffffffffc0204876:	2c660613          	addi	a2,a2,710 # ffffffffc0206b38 <commands+0x450>
ffffffffc020487a:	14b00593          	li	a1,331
ffffffffc020487e:	00003517          	auipc	a0,0x3
ffffffffc0204882:	5a250513          	addi	a0,a0,1442 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc0204886:	bf5fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(mm != NULL);
ffffffffc020488a:	00003697          	auipc	a3,0x3
ffffffffc020488e:	0ce68693          	addi	a3,a3,206 # ffffffffc0207958 <default_pmm_manager+0x788>
ffffffffc0204892:	00002617          	auipc	a2,0x2
ffffffffc0204896:	2a660613          	addi	a2,a2,678 # ffffffffc0206b38 <commands+0x450>
ffffffffc020489a:	10c00593          	li	a1,268
ffffffffc020489e:	00003517          	auipc	a0,0x3
ffffffffc02048a2:	58250513          	addi	a0,a0,1410 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc02048a6:	bd5fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02048aa:	00003697          	auipc	a3,0x3
ffffffffc02048ae:	7e668693          	addi	a3,a3,2022 # ffffffffc0208090 <default_pmm_manager+0xec0>
ffffffffc02048b2:	00002617          	auipc	a2,0x2
ffffffffc02048b6:	28660613          	addi	a2,a2,646 # ffffffffc0206b38 <commands+0x450>
ffffffffc02048ba:	17000593          	li	a1,368
ffffffffc02048be:	00003517          	auipc	a0,0x3
ffffffffc02048c2:	56250513          	addi	a0,a0,1378 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc02048c6:	bb5fb0ef          	jal	ra,ffffffffc020047a <__panic>
    return KADDR(page2pa(page));
ffffffffc02048ca:	00003617          	auipc	a2,0x3
ffffffffc02048ce:	93e60613          	addi	a2,a2,-1730 # ffffffffc0207208 <default_pmm_manager+0x38>
ffffffffc02048d2:	06900593          	li	a1,105
ffffffffc02048d6:	00003517          	auipc	a0,0x3
ffffffffc02048da:	95a50513          	addi	a0,a0,-1702 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc02048de:	b9dfb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgdir[0] == 0);
ffffffffc02048e2:	00003697          	auipc	a3,0x3
ffffffffc02048e6:	09e68693          	addi	a3,a3,158 # ffffffffc0207980 <default_pmm_manager+0x7b0>
ffffffffc02048ea:	00002617          	auipc	a2,0x2
ffffffffc02048ee:	24e60613          	addi	a2,a2,590 # ffffffffc0206b38 <commands+0x450>
ffffffffc02048f2:	14f00593          	li	a1,335
ffffffffc02048f6:	00003517          	auipc	a0,0x3
ffffffffc02048fa:	52a50513          	addi	a0,a0,1322 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc02048fe:	b7dfb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0204902:	00003697          	auipc	a3,0x3
ffffffffc0204906:	75e68693          	addi	a3,a3,1886 # ffffffffc0208060 <default_pmm_manager+0xe90>
ffffffffc020490a:	00002617          	auipc	a2,0x2
ffffffffc020490e:	22e60613          	addi	a2,a2,558 # ffffffffc0206b38 <commands+0x450>
ffffffffc0204912:	15700593          	li	a1,343
ffffffffc0204916:	00003517          	auipc	a0,0x3
ffffffffc020491a:	50a50513          	addi	a0,a0,1290 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc020491e:	b5dfb0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204922:	00003617          	auipc	a2,0x3
ffffffffc0204926:	9b660613          	addi	a2,a2,-1610 # ffffffffc02072d8 <default_pmm_manager+0x108>
ffffffffc020492a:	06200593          	li	a1,98
ffffffffc020492e:	00003517          	auipc	a0,0x3
ffffffffc0204932:	90250513          	addi	a0,a0,-1790 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc0204936:	b45fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(sum == 0);
ffffffffc020493a:	00003697          	auipc	a3,0x3
ffffffffc020493e:	74668693          	addi	a3,a3,1862 # ffffffffc0208080 <default_pmm_manager+0xeb0>
ffffffffc0204942:	00002617          	auipc	a2,0x2
ffffffffc0204946:	1f660613          	addi	a2,a2,502 # ffffffffc0206b38 <commands+0x450>
ffffffffc020494a:	16300593          	li	a1,355
ffffffffc020494e:	00003517          	auipc	a0,0x3
ffffffffc0204952:	4d250513          	addi	a0,a0,1234 # ffffffffc0207e20 <default_pmm_manager+0xc50>
ffffffffc0204956:	b25fb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc020495a <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc020495a:	1101                	addi	sp,sp,-32
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc020495c:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc020495e:	e822                	sd	s0,16(sp)
ffffffffc0204960:	e426                	sd	s1,8(sp)
ffffffffc0204962:	ec06                	sd	ra,24(sp)
ffffffffc0204964:	e04a                	sd	s2,0(sp)
ffffffffc0204966:	8432                	mv	s0,a2
ffffffffc0204968:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc020496a:	f8eff0ef          	jal	ra,ffffffffc02040f8 <find_vma>

    pgfault_num++;
ffffffffc020496e:	000ae797          	auipc	a5,0xae
ffffffffc0204972:	fa27a783          	lw	a5,-94(a5) # ffffffffc02b2910 <pgfault_num>
ffffffffc0204976:	2785                	addiw	a5,a5,1
ffffffffc0204978:	000ae717          	auipc	a4,0xae
ffffffffc020497c:	f8f72c23          	sw	a5,-104(a4) # ffffffffc02b2910 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc0204980:	c931                	beqz	a0,ffffffffc02049d4 <do_pgfault+0x7a>
ffffffffc0204982:	651c                	ld	a5,8(a0)
ffffffffc0204984:	04f46863          	bltu	s0,a5,ffffffffc02049d4 <do_pgfault+0x7a>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0204988:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc020498a:	4941                	li	s2,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc020498c:	8b89                	andi	a5,a5,2
ffffffffc020498e:	e39d                	bnez	a5,ffffffffc02049b4 <do_pgfault+0x5a>
        perm |= READ_WRITE;
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0204990:	75fd                	lui	a1,0xfffff

    pte_t *ptep=NULL;
  
    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0204992:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0204994:	8c6d                	and	s0,s0,a1
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0204996:	4605                	li	a2,1
ffffffffc0204998:	85a2                	mv	a1,s0
ffffffffc020499a:	c2efd0ef          	jal	ra,ffffffffc0201dc8 <get_pte>
ffffffffc020499e:	cd21                	beqz	a0,ffffffffc02049f6 <do_pgfault+0x9c>
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
ffffffffc02049a0:	610c                	ld	a1,0(a0)
ffffffffc02049a2:	c999                	beqz	a1,ffffffffc02049b8 <do_pgfault+0x5e>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc02049a4:	000ae797          	auipc	a5,0xae
ffffffffc02049a8:	f5c7a783          	lw	a5,-164(a5) # ffffffffc02b2900 <swap_init_ok>
ffffffffc02049ac:	cf8d                	beqz	a5,ffffffffc02049e6 <do_pgfault+0x8c>
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
            page->pra_vaddr = addr;
ffffffffc02049ae:	02003c23          	sd	zero,56(zero) # 38 <_binary_obj___user_faultread_out_size-0x9b80>
ffffffffc02049b2:	9002                	ebreak
        perm |= READ_WRITE;
ffffffffc02049b4:	495d                	li	s2,23
ffffffffc02049b6:	bfe9                	j	ffffffffc0204990 <do_pgfault+0x36>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc02049b8:	6c88                	ld	a0,24(s1)
ffffffffc02049ba:	864a                	mv	a2,s2
ffffffffc02049bc:	85a2                	mv	a1,s0
ffffffffc02049be:	96bfe0ef          	jal	ra,ffffffffc0203328 <pgdir_alloc_page>
ffffffffc02049c2:	87aa                	mv	a5,a0
        } else {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }
   ret = 0;
ffffffffc02049c4:	4501                	li	a0,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc02049c6:	c3a1                	beqz	a5,ffffffffc0204a06 <do_pgfault+0xac>
failed:
    return ret;
}
ffffffffc02049c8:	60e2                	ld	ra,24(sp)
ffffffffc02049ca:	6442                	ld	s0,16(sp)
ffffffffc02049cc:	64a2                	ld	s1,8(sp)
ffffffffc02049ce:	6902                	ld	s2,0(sp)
ffffffffc02049d0:	6105                	addi	sp,sp,32
ffffffffc02049d2:	8082                	ret
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc02049d4:	85a2                	mv	a1,s0
ffffffffc02049d6:	00003517          	auipc	a0,0x3
ffffffffc02049da:	71a50513          	addi	a0,a0,1818 # ffffffffc02080f0 <default_pmm_manager+0xf20>
ffffffffc02049de:	fa2fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
    int ret = -E_INVAL;
ffffffffc02049e2:	5575                	li	a0,-3
        goto failed;
ffffffffc02049e4:	b7d5                	j	ffffffffc02049c8 <do_pgfault+0x6e>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc02049e6:	00003517          	auipc	a0,0x3
ffffffffc02049ea:	78250513          	addi	a0,a0,1922 # ffffffffc0208168 <default_pmm_manager+0xf98>
ffffffffc02049ee:	f92fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
    ret = -E_NO_MEM;
ffffffffc02049f2:	5571                	li	a0,-4
            goto failed;
ffffffffc02049f4:	bfd1                	j	ffffffffc02049c8 <do_pgfault+0x6e>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc02049f6:	00003517          	auipc	a0,0x3
ffffffffc02049fa:	72a50513          	addi	a0,a0,1834 # ffffffffc0208120 <default_pmm_manager+0xf50>
ffffffffc02049fe:	f82fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204a02:	5571                	li	a0,-4
        goto failed;
ffffffffc0204a04:	b7d1                	j	ffffffffc02049c8 <do_pgfault+0x6e>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0204a06:	00003517          	auipc	a0,0x3
ffffffffc0204a0a:	73a50513          	addi	a0,a0,1850 # ffffffffc0208140 <default_pmm_manager+0xf70>
ffffffffc0204a0e:	f72fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204a12:	5571                	li	a0,-4
            goto failed;
ffffffffc0204a14:	bf55                	j	ffffffffc02049c8 <do_pgfault+0x6e>

ffffffffc0204a16 <user_mem_check>:

bool
user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write) {
ffffffffc0204a16:	7179                	addi	sp,sp,-48
ffffffffc0204a18:	f022                	sd	s0,32(sp)
ffffffffc0204a1a:	f406                	sd	ra,40(sp)
ffffffffc0204a1c:	ec26                	sd	s1,24(sp)
ffffffffc0204a1e:	e84a                	sd	s2,16(sp)
ffffffffc0204a20:	e44e                	sd	s3,8(sp)
ffffffffc0204a22:	e052                	sd	s4,0(sp)
ffffffffc0204a24:	842e                	mv	s0,a1
    if (mm != NULL) {
ffffffffc0204a26:	c135                	beqz	a0,ffffffffc0204a8a <user_mem_check+0x74>
        if (!USER_ACCESS(addr, addr + len)) {
ffffffffc0204a28:	002007b7          	lui	a5,0x200
ffffffffc0204a2c:	04f5e663          	bltu	a1,a5,ffffffffc0204a78 <user_mem_check+0x62>
ffffffffc0204a30:	00c584b3          	add	s1,a1,a2
ffffffffc0204a34:	0495f263          	bgeu	a1,s1,ffffffffc0204a78 <user_mem_check+0x62>
ffffffffc0204a38:	4785                	li	a5,1
ffffffffc0204a3a:	07fe                	slli	a5,a5,0x1f
ffffffffc0204a3c:	0297ee63          	bltu	a5,s1,ffffffffc0204a78 <user_mem_check+0x62>
ffffffffc0204a40:	892a                	mv	s2,a0
ffffffffc0204a42:	89b6                	mv	s3,a3
            }
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK)) {
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204a44:	6a05                	lui	s4,0x1
ffffffffc0204a46:	a821                	j	ffffffffc0204a5e <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204a48:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204a4c:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc0204a4e:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204a50:	c685                	beqz	a3,ffffffffc0204a78 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc0204a52:	c399                	beqz	a5,ffffffffc0204a58 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204a54:	02e46263          	bltu	s0,a4,ffffffffc0204a78 <user_mem_check+0x62>
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0204a58:	6900                	ld	s0,16(a0)
        while (start < end) {
ffffffffc0204a5a:	04947663          	bgeu	s0,s1,ffffffffc0204aa6 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start) {
ffffffffc0204a5e:	85a2                	mv	a1,s0
ffffffffc0204a60:	854a                	mv	a0,s2
ffffffffc0204a62:	e96ff0ef          	jal	ra,ffffffffc02040f8 <find_vma>
ffffffffc0204a66:	c909                	beqz	a0,ffffffffc0204a78 <user_mem_check+0x62>
ffffffffc0204a68:	6518                	ld	a4,8(a0)
ffffffffc0204a6a:	00e46763          	bltu	s0,a4,ffffffffc0204a78 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204a6e:	4d1c                	lw	a5,24(a0)
ffffffffc0204a70:	fc099ce3          	bnez	s3,ffffffffc0204a48 <user_mem_check+0x32>
ffffffffc0204a74:	8b85                	andi	a5,a5,1
ffffffffc0204a76:	f3ed                	bnez	a5,ffffffffc0204a58 <user_mem_check+0x42>
            return 0;
ffffffffc0204a78:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0204a7a:	70a2                	ld	ra,40(sp)
ffffffffc0204a7c:	7402                	ld	s0,32(sp)
ffffffffc0204a7e:	64e2                	ld	s1,24(sp)
ffffffffc0204a80:	6942                	ld	s2,16(sp)
ffffffffc0204a82:	69a2                	ld	s3,8(sp)
ffffffffc0204a84:	6a02                	ld	s4,0(sp)
ffffffffc0204a86:	6145                	addi	sp,sp,48
ffffffffc0204a88:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0204a8a:	c02007b7          	lui	a5,0xc0200
ffffffffc0204a8e:	4501                	li	a0,0
ffffffffc0204a90:	fef5e5e3          	bltu	a1,a5,ffffffffc0204a7a <user_mem_check+0x64>
ffffffffc0204a94:	962e                	add	a2,a2,a1
ffffffffc0204a96:	fec5f2e3          	bgeu	a1,a2,ffffffffc0204a7a <user_mem_check+0x64>
ffffffffc0204a9a:	c8000537          	lui	a0,0xc8000
ffffffffc0204a9e:	0505                	addi	a0,a0,1
ffffffffc0204aa0:	00a63533          	sltu	a0,a2,a0
ffffffffc0204aa4:	bfd9                	j	ffffffffc0204a7a <user_mem_check+0x64>
        return 1;
ffffffffc0204aa6:	4505                	li	a0,1
ffffffffc0204aa8:	bfc9                	j	ffffffffc0204a7a <user_mem_check+0x64>

ffffffffc0204aaa <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0204aaa:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204aac:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0204aae:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204ab0:	b3dfb0ef          	jal	ra,ffffffffc02005ec <ide_device_valid>
ffffffffc0204ab4:	cd01                	beqz	a0,ffffffffc0204acc <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204ab6:	4505                	li	a0,1
ffffffffc0204ab8:	b3bfb0ef          	jal	ra,ffffffffc02005f2 <ide_device_size>
}
ffffffffc0204abc:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204abe:	810d                	srli	a0,a0,0x3
ffffffffc0204ac0:	000ae797          	auipc	a5,0xae
ffffffffc0204ac4:	e2a7b823          	sd	a0,-464(a5) # ffffffffc02b28f0 <max_swap_offset>
}
ffffffffc0204ac8:	0141                	addi	sp,sp,16
ffffffffc0204aca:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0204acc:	00003617          	auipc	a2,0x3
ffffffffc0204ad0:	6c460613          	addi	a2,a2,1732 # ffffffffc0208190 <default_pmm_manager+0xfc0>
ffffffffc0204ad4:	45b5                	li	a1,13
ffffffffc0204ad6:	00003517          	auipc	a0,0x3
ffffffffc0204ada:	6da50513          	addi	a0,a0,1754 # ffffffffc02081b0 <default_pmm_manager+0xfe0>
ffffffffc0204ade:	99dfb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204ae2 <swapfs_write>:
swapfs_read(swap_entry_t entry, struct Page *page) {
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
}

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0204ae2:	1141                	addi	sp,sp,-16
ffffffffc0204ae4:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204ae6:	00855793          	srli	a5,a0,0x8
ffffffffc0204aea:	cbb1                	beqz	a5,ffffffffc0204b3e <swapfs_write+0x5c>
ffffffffc0204aec:	000ae717          	auipc	a4,0xae
ffffffffc0204af0:	e0473703          	ld	a4,-508(a4) # ffffffffc02b28f0 <max_swap_offset>
ffffffffc0204af4:	04e7f563          	bgeu	a5,a4,ffffffffc0204b3e <swapfs_write+0x5c>
    return page - pages + nbase;
ffffffffc0204af8:	000ae617          	auipc	a2,0xae
ffffffffc0204afc:	de063603          	ld	a2,-544(a2) # ffffffffc02b28d8 <pages>
ffffffffc0204b00:	8d91                	sub	a1,a1,a2
ffffffffc0204b02:	4065d613          	srai	a2,a1,0x6
ffffffffc0204b06:	00004717          	auipc	a4,0x4
ffffffffc0204b0a:	ffa73703          	ld	a4,-6(a4) # ffffffffc0208b00 <nbase>
ffffffffc0204b0e:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc0204b10:	00c61713          	slli	a4,a2,0xc
ffffffffc0204b14:	8331                	srli	a4,a4,0xc
ffffffffc0204b16:	000ae697          	auipc	a3,0xae
ffffffffc0204b1a:	dba6b683          	ld	a3,-582(a3) # ffffffffc02b28d0 <npage>
ffffffffc0204b1e:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b22:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204b24:	02d77963          	bgeu	a4,a3,ffffffffc0204b56 <swapfs_write+0x74>
}
ffffffffc0204b28:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204b2a:	000ae797          	auipc	a5,0xae
ffffffffc0204b2e:	dbe7b783          	ld	a5,-578(a5) # ffffffffc02b28e8 <va_pa_offset>
ffffffffc0204b32:	46a1                	li	a3,8
ffffffffc0204b34:	963e                	add	a2,a2,a5
ffffffffc0204b36:	4505                	li	a0,1
}
ffffffffc0204b38:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204b3a:	abffb06f          	j	ffffffffc02005f8 <ide_write_secs>
ffffffffc0204b3e:	86aa                	mv	a3,a0
ffffffffc0204b40:	00003617          	auipc	a2,0x3
ffffffffc0204b44:	68860613          	addi	a2,a2,1672 # ffffffffc02081c8 <default_pmm_manager+0xff8>
ffffffffc0204b48:	45e5                	li	a1,25
ffffffffc0204b4a:	00003517          	auipc	a0,0x3
ffffffffc0204b4e:	66650513          	addi	a0,a0,1638 # ffffffffc02081b0 <default_pmm_manager+0xfe0>
ffffffffc0204b52:	929fb0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0204b56:	86b2                	mv	a3,a2
ffffffffc0204b58:	06900593          	li	a1,105
ffffffffc0204b5c:	00002617          	auipc	a2,0x2
ffffffffc0204b60:	6ac60613          	addi	a2,a2,1708 # ffffffffc0207208 <default_pmm_manager+0x38>
ffffffffc0204b64:	00002517          	auipc	a0,0x2
ffffffffc0204b68:	6cc50513          	addi	a0,a0,1740 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc0204b6c:	90ffb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204b70 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204b70:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204b72:	9402                	jalr	s0

	jal do_exit
ffffffffc0204b74:	63c000ef          	jal	ra,ffffffffc02051b0 <do_exit>

ffffffffc0204b78 <alloc_proc>:
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
ffffffffc0204b78:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204b7a:	10800513          	li	a0,264
alloc_proc(void) {
ffffffffc0204b7e:	e022                	sd	s0,0(sp)
ffffffffc0204b80:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204b82:	f5dfc0ef          	jal	ra,ffffffffc0201ade <kmalloc>
ffffffffc0204b86:	842a                	mv	s0,a0
    if (proc != NULL) {
ffffffffc0204b88:	cd21                	beqz	a0,ffffffffc0204be0 <alloc_proc+0x68>
     *       struct trapframe *tf;                       // Trap frame for current interrupt
     *       uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
     *       uint32_t flags;                             // Process flag
     *       char name[PROC_NAME_LEN + 1];               // Process name
     */
    proc->state = PROC_UNINIT;
ffffffffc0204b8a:	57fd                	li	a5,-1
ffffffffc0204b8c:	1782                	slli	a5,a5,0x20
ffffffffc0204b8e:	e11c                	sd	a5,0(a0)
    proc->runs = 0;
    proc->kstack = 0;
    proc->need_resched = 0;
    proc->parent = NULL;
    proc->mm = NULL;
    memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0204b90:	07000613          	li	a2,112
ffffffffc0204b94:	4581                	li	a1,0
    proc->runs = 0;
ffffffffc0204b96:	00052423          	sw	zero,8(a0)
    proc->kstack = 0;
ffffffffc0204b9a:	00053823          	sd	zero,16(a0)
    proc->need_resched = 0;
ffffffffc0204b9e:	00053c23          	sd	zero,24(a0)
    proc->parent = NULL;
ffffffffc0204ba2:	02053023          	sd	zero,32(a0)
    proc->mm = NULL;
ffffffffc0204ba6:	02053423          	sd	zero,40(a0)
    memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0204baa:	03050513          	addi	a0,a0,48
ffffffffc0204bae:	0a5010ef          	jal	ra,ffffffffc0206452 <memset>
    proc->tf = NULL;
    proc->cr3 = boot_cr3;
ffffffffc0204bb2:	000ae797          	auipc	a5,0xae
ffffffffc0204bb6:	d0e7b783          	ld	a5,-754(a5) # ffffffffc02b28c0 <boot_cr3>
    proc->tf = NULL;
ffffffffc0204bba:	0a043023          	sd	zero,160(s0)
    proc->cr3 = boot_cr3;
ffffffffc0204bbe:	f45c                	sd	a5,168(s0)
    proc->flags = 0;
ffffffffc0204bc0:	0a042823          	sw	zero,176(s0)
    memset(proc->name, 0, PROC_NAME_LEN);
ffffffffc0204bc4:	463d                	li	a2,15
ffffffffc0204bc6:	4581                	li	a1,0
ffffffffc0204bc8:	0b440513          	addi	a0,s0,180
ffffffffc0204bcc:	087010ef          	jal	ra,ffffffffc0206452 <memset>
     /*
     * below fields(add in LAB5) in proc_struct need to be initialized  
     *       uint32_t wait_state;                        // waiting state
     *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
     */
    proc->wait_state = 0;  // 进程等待状态初始化为0
ffffffffc0204bd0:	0e042623          	sw	zero,236(s0)
    proc->cptr = proc->yptr = proc->optr = NULL;  // 进程间指针初始化为NULL
ffffffffc0204bd4:	10043023          	sd	zero,256(s0)
ffffffffc0204bd8:	0e043c23          	sd	zero,248(s0)
ffffffffc0204bdc:	0e043823          	sd	zero,240(s0)
    }
    return proc;
}
ffffffffc0204be0:	60a2                	ld	ra,8(sp)
ffffffffc0204be2:	8522                	mv	a0,s0
ffffffffc0204be4:	6402                	ld	s0,0(sp)
ffffffffc0204be6:	0141                	addi	sp,sp,16
ffffffffc0204be8:	8082                	ret

ffffffffc0204bea <forkret>:
// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
ffffffffc0204bea:	000ae797          	auipc	a5,0xae
ffffffffc0204bee:	d2e7b783          	ld	a5,-722(a5) # ffffffffc02b2918 <current>
ffffffffc0204bf2:	73c8                	ld	a0,160(a5)
ffffffffc0204bf4:	95efc06f          	j	ffffffffc0200d52 <forkrets>

ffffffffc0204bf8 <user_main>:

// user_main - kernel thread used to exec a user program
static int
user_main(void *arg) {
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204bf8:	000ae797          	auipc	a5,0xae
ffffffffc0204bfc:	d207b783          	ld	a5,-736(a5) # ffffffffc02b2918 <current>
ffffffffc0204c00:	43cc                	lw	a1,4(a5)
user_main(void *arg) {
ffffffffc0204c02:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204c04:	00003617          	auipc	a2,0x3
ffffffffc0204c08:	5e460613          	addi	a2,a2,1508 # ffffffffc02081e8 <default_pmm_manager+0x1018>
ffffffffc0204c0c:	00003517          	auipc	a0,0x3
ffffffffc0204c10:	5e450513          	addi	a0,a0,1508 # ffffffffc02081f0 <default_pmm_manager+0x1020>
user_main(void *arg) {
ffffffffc0204c14:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204c16:	d6afb0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc0204c1a:	3fe05797          	auipc	a5,0x3fe05
ffffffffc0204c1e:	19678793          	addi	a5,a5,406 # 9db0 <_binary_obj___user_pgdir_out_size>
ffffffffc0204c22:	e43e                	sd	a5,8(sp)
ffffffffc0204c24:	00003517          	auipc	a0,0x3
ffffffffc0204c28:	5c450513          	addi	a0,a0,1476 # ffffffffc02081e8 <default_pmm_manager+0x1018>
ffffffffc0204c2c:	00065797          	auipc	a5,0x65
ffffffffc0204c30:	8cc78793          	addi	a5,a5,-1844 # ffffffffc02694f8 <_binary_obj___user_pgdir_out_start>
ffffffffc0204c34:	f03e                	sd	a5,32(sp)
ffffffffc0204c36:	f42a                	sd	a0,40(sp)
    int64_t ret=0, len = strlen(name);
ffffffffc0204c38:	e802                	sd	zero,16(sp)
ffffffffc0204c3a:	79c010ef          	jal	ra,ffffffffc02063d6 <strlen>
ffffffffc0204c3e:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204c40:	4511                	li	a0,4
ffffffffc0204c42:	55a2                	lw	a1,40(sp)
ffffffffc0204c44:	4662                	lw	a2,24(sp)
ffffffffc0204c46:	5682                	lw	a3,32(sp)
ffffffffc0204c48:	4722                	lw	a4,8(sp)
ffffffffc0204c4a:	48a9                	li	a7,10
ffffffffc0204c4c:	9002                	ebreak
ffffffffc0204c4e:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204c50:	65c2                	ld	a1,16(sp)
ffffffffc0204c52:	00003517          	auipc	a0,0x3
ffffffffc0204c56:	5c650513          	addi	a0,a0,1478 # ffffffffc0208218 <default_pmm_manager+0x1048>
ffffffffc0204c5a:	d26fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0204c5e:	00003617          	auipc	a2,0x3
ffffffffc0204c62:	5ca60613          	addi	a2,a2,1482 # ffffffffc0208228 <default_pmm_manager+0x1058>
ffffffffc0204c66:	35700593          	li	a1,855
ffffffffc0204c6a:	00003517          	auipc	a0,0x3
ffffffffc0204c6e:	5de50513          	addi	a0,a0,1502 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc0204c72:	809fb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204c76 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0204c76:	6d14                	ld	a3,24(a0)
put_pgdir(struct mm_struct *mm) {
ffffffffc0204c78:	1141                	addi	sp,sp,-16
ffffffffc0204c7a:	e406                	sd	ra,8(sp)
ffffffffc0204c7c:	c02007b7          	lui	a5,0xc0200
ffffffffc0204c80:	02f6ee63          	bltu	a3,a5,ffffffffc0204cbc <put_pgdir+0x46>
ffffffffc0204c84:	000ae517          	auipc	a0,0xae
ffffffffc0204c88:	c6453503          	ld	a0,-924(a0) # ffffffffc02b28e8 <va_pa_offset>
ffffffffc0204c8c:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage) {
ffffffffc0204c8e:	82b1                	srli	a3,a3,0xc
ffffffffc0204c90:	000ae797          	auipc	a5,0xae
ffffffffc0204c94:	c407b783          	ld	a5,-960(a5) # ffffffffc02b28d0 <npage>
ffffffffc0204c98:	02f6fe63          	bgeu	a3,a5,ffffffffc0204cd4 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0204c9c:	00004517          	auipc	a0,0x4
ffffffffc0204ca0:	e6453503          	ld	a0,-412(a0) # ffffffffc0208b00 <nbase>
}
ffffffffc0204ca4:	60a2                	ld	ra,8(sp)
ffffffffc0204ca6:	8e89                	sub	a3,a3,a0
ffffffffc0204ca8:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0204caa:	000ae517          	auipc	a0,0xae
ffffffffc0204cae:	c2e53503          	ld	a0,-978(a0) # ffffffffc02b28d8 <pages>
ffffffffc0204cb2:	4585                	li	a1,1
ffffffffc0204cb4:	9536                	add	a0,a0,a3
}
ffffffffc0204cb6:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0204cb8:	896fd06f          	j	ffffffffc0201d4e <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0204cbc:	00002617          	auipc	a2,0x2
ffffffffc0204cc0:	5f460613          	addi	a2,a2,1524 # ffffffffc02072b0 <default_pmm_manager+0xe0>
ffffffffc0204cc4:	06e00593          	li	a1,110
ffffffffc0204cc8:	00002517          	auipc	a0,0x2
ffffffffc0204ccc:	56850513          	addi	a0,a0,1384 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc0204cd0:	faafb0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204cd4:	00002617          	auipc	a2,0x2
ffffffffc0204cd8:	60460613          	addi	a2,a2,1540 # ffffffffc02072d8 <default_pmm_manager+0x108>
ffffffffc0204cdc:	06200593          	li	a1,98
ffffffffc0204ce0:	00002517          	auipc	a0,0x2
ffffffffc0204ce4:	55050513          	addi	a0,a0,1360 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc0204ce8:	f92fb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204cec <proc_run>:
proc_run(struct proc_struct *proc) {
ffffffffc0204cec:	7179                	addi	sp,sp,-48
ffffffffc0204cee:	ec4a                	sd	s2,24(sp)
    if (proc != current) {
ffffffffc0204cf0:	000ae917          	auipc	s2,0xae
ffffffffc0204cf4:	c2890913          	addi	s2,s2,-984 # ffffffffc02b2918 <current>
proc_run(struct proc_struct *proc) {
ffffffffc0204cf8:	f026                	sd	s1,32(sp)
    if (proc != current) {
ffffffffc0204cfa:	00093483          	ld	s1,0(s2)
proc_run(struct proc_struct *proc) {
ffffffffc0204cfe:	f406                	sd	ra,40(sp)
ffffffffc0204d00:	e84e                	sd	s3,16(sp)
    if (proc != current) {
ffffffffc0204d02:	02a48863          	beq	s1,a0,ffffffffc0204d32 <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204d06:	100027f3          	csrr	a5,sstatus
ffffffffc0204d0a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204d0c:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204d0e:	ef9d                	bnez	a5,ffffffffc0204d4c <proc_run+0x60>

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned long cr3) {
    write_csr(satp, 0x8000000000000000 | (cr3 >> RISCV_PGSHIFT));
ffffffffc0204d10:	755c                	ld	a5,168(a0)
ffffffffc0204d12:	577d                	li	a4,-1
ffffffffc0204d14:	177e                	slli	a4,a4,0x3f
ffffffffc0204d16:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc0204d18:	00a93023          	sd	a0,0(s2)
ffffffffc0204d1c:	8fd9                	or	a5,a5,a4
ffffffffc0204d1e:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(proc->context)); // prev.ra <- 返回值，转移到forkret
ffffffffc0204d22:	03050593          	addi	a1,a0,48
ffffffffc0204d26:	03048513          	addi	a0,s1,48
ffffffffc0204d2a:	052010ef          	jal	ra,ffffffffc0205d7c <switch_to>
    if (flag) {
ffffffffc0204d2e:	00099863          	bnez	s3,ffffffffc0204d3e <proc_run+0x52>
}
ffffffffc0204d32:	70a2                	ld	ra,40(sp)
ffffffffc0204d34:	7482                	ld	s1,32(sp)
ffffffffc0204d36:	6962                	ld	s2,24(sp)
ffffffffc0204d38:	69c2                	ld	s3,16(sp)
ffffffffc0204d3a:	6145                	addi	sp,sp,48
ffffffffc0204d3c:	8082                	ret
ffffffffc0204d3e:	70a2                	ld	ra,40(sp)
ffffffffc0204d40:	7482                	ld	s1,32(sp)
ffffffffc0204d42:	6962                	ld	s2,24(sp)
ffffffffc0204d44:	69c2                	ld	s3,16(sp)
ffffffffc0204d46:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0204d48:	8d5fb06f          	j	ffffffffc020061c <intr_enable>
ffffffffc0204d4c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0204d4e:	8d5fb0ef          	jal	ra,ffffffffc0200622 <intr_disable>
        return 1;
ffffffffc0204d52:	6522                	ld	a0,8(sp)
ffffffffc0204d54:	4985                	li	s3,1
ffffffffc0204d56:	bf6d                	j	ffffffffc0204d10 <proc_run+0x24>

ffffffffc0204d58 <do_fork>:
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0204d58:	7119                	addi	sp,sp,-128
ffffffffc0204d5a:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0204d5c:	000ae917          	auipc	s2,0xae
ffffffffc0204d60:	bd490913          	addi	s2,s2,-1068 # ffffffffc02b2930 <nr_process>
ffffffffc0204d64:	00092703          	lw	a4,0(s2)
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0204d68:	fc86                	sd	ra,120(sp)
ffffffffc0204d6a:	f8a2                	sd	s0,112(sp)
ffffffffc0204d6c:	f4a6                	sd	s1,104(sp)
ffffffffc0204d6e:	ecce                	sd	s3,88(sp)
ffffffffc0204d70:	e8d2                	sd	s4,80(sp)
ffffffffc0204d72:	e4d6                	sd	s5,72(sp)
ffffffffc0204d74:	e0da                	sd	s6,64(sp)
ffffffffc0204d76:	fc5e                	sd	s7,56(sp)
ffffffffc0204d78:	f862                	sd	s8,48(sp)
ffffffffc0204d7a:	f466                	sd	s9,40(sp)
ffffffffc0204d7c:	f06a                	sd	s10,32(sp)
ffffffffc0204d7e:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0204d80:	6785                	lui	a5,0x1
ffffffffc0204d82:	32f75b63          	bge	a4,a5,ffffffffc02050b8 <do_fork+0x360>
ffffffffc0204d86:	8a2a                	mv	s4,a0
ffffffffc0204d88:	89ae                	mv	s3,a1
ffffffffc0204d8a:	8432                	mv	s0,a2
    if((proc = alloc_proc()) == NULL){
ffffffffc0204d8c:	dedff0ef          	jal	ra,ffffffffc0204b78 <alloc_proc>
ffffffffc0204d90:	84aa                	mv	s1,a0
ffffffffc0204d92:	32050863          	beqz	a0,ffffffffc02050c2 <do_fork+0x36a>
    proc->parent = current;
ffffffffc0204d96:	000aec17          	auipc	s8,0xae
ffffffffc0204d9a:	b82c0c13          	addi	s8,s8,-1150 # ffffffffc02b2918 <current>
ffffffffc0204d9e:	000c3783          	ld	a5,0(s8)
    assert(current->wait_state == 0);
ffffffffc0204da2:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8acc>
    proc->parent = current;
ffffffffc0204da6:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc0204da8:	36071463          	bnez	a4,ffffffffc0205110 <do_fork+0x3b8>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204dac:	4509                	li	a0,2
ffffffffc0204dae:	f0ffc0ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
    if (page != NULL) {
ffffffffc0204db2:	2e050163          	beqz	a0,ffffffffc0205094 <do_fork+0x33c>
    return page - pages + nbase;
ffffffffc0204db6:	000aea97          	auipc	s5,0xae
ffffffffc0204dba:	b22a8a93          	addi	s5,s5,-1246 # ffffffffc02b28d8 <pages>
ffffffffc0204dbe:	000ab683          	ld	a3,0(s5)
ffffffffc0204dc2:	00004b17          	auipc	s6,0x4
ffffffffc0204dc6:	d3eb0b13          	addi	s6,s6,-706 # ffffffffc0208b00 <nbase>
ffffffffc0204dca:	000b3783          	ld	a5,0(s6)
ffffffffc0204dce:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0204dd2:	000aeb97          	auipc	s7,0xae
ffffffffc0204dd6:	afeb8b93          	addi	s7,s7,-1282 # ffffffffc02b28d0 <npage>
    return page - pages + nbase;
ffffffffc0204dda:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204ddc:	5dfd                	li	s11,-1
ffffffffc0204dde:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204de2:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204de4:	00cddd93          	srli	s11,s11,0xc
ffffffffc0204de8:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204dec:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204dee:	2ce67c63          	bgeu	a2,a4,ffffffffc02050c6 <do_fork+0x36e>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0204df2:	000c3603          	ld	a2,0(s8)
ffffffffc0204df6:	000aec17          	auipc	s8,0xae
ffffffffc0204dfa:	af2c0c13          	addi	s8,s8,-1294 # ffffffffc02b28e8 <va_pa_offset>
ffffffffc0204dfe:	000c3703          	ld	a4,0(s8)
ffffffffc0204e02:	02863d03          	ld	s10,40(a2)
ffffffffc0204e06:	e43e                	sd	a5,8(sp)
ffffffffc0204e08:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0204e0a:	e894                	sd	a3,16(s1)
    if (oldmm == NULL) {
ffffffffc0204e0c:	020d0863          	beqz	s10,ffffffffc0204e3c <do_fork+0xe4>
    if (clone_flags & CLONE_VM) {
ffffffffc0204e10:	100a7a13          	andi	s4,s4,256
ffffffffc0204e14:	1c0a0163          	beqz	s4,ffffffffc0204fd6 <do_fork+0x27e>
}

static inline int
mm_count_inc(struct mm_struct *mm) {
    mm->mm_count += 1;
ffffffffc0204e18:	030d2703          	lw	a4,48(s10)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0204e1c:	018d3783          	ld	a5,24(s10)
ffffffffc0204e20:	c02006b7          	lui	a3,0xc0200
ffffffffc0204e24:	2705                	addiw	a4,a4,1
ffffffffc0204e26:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc0204e2a:	03a4b423          	sd	s10,40(s1)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0204e2e:	2ad7e863          	bltu	a5,a3,ffffffffc02050de <do_fork+0x386>
ffffffffc0204e32:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204e36:	6894                	ld	a3,16(s1)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0204e38:	8f99                	sub	a5,a5,a4
ffffffffc0204e3a:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204e3c:	6789                	lui	a5,0x2
ffffffffc0204e3e:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cd8>
ffffffffc0204e42:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0204e44:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204e46:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc0204e48:	87b6                	mv	a5,a3
ffffffffc0204e4a:	12040893          	addi	a7,s0,288
ffffffffc0204e4e:	00063803          	ld	a6,0(a2)
ffffffffc0204e52:	6608                	ld	a0,8(a2)
ffffffffc0204e54:	6a0c                	ld	a1,16(a2)
ffffffffc0204e56:	6e18                	ld	a4,24(a2)
ffffffffc0204e58:	0107b023          	sd	a6,0(a5)
ffffffffc0204e5c:	e788                	sd	a0,8(a5)
ffffffffc0204e5e:	eb8c                	sd	a1,16(a5)
ffffffffc0204e60:	ef98                	sd	a4,24(a5)
ffffffffc0204e62:	02060613          	addi	a2,a2,32
ffffffffc0204e66:	02078793          	addi	a5,a5,32
ffffffffc0204e6a:	ff1612e3          	bne	a2,a7,ffffffffc0204e4e <do_fork+0xf6>
    proc->tf->gpr.a0 = 0;
ffffffffc0204e6e:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x1e>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204e72:	12098f63          	beqz	s3,ffffffffc0204fb0 <do_fork+0x258>
ffffffffc0204e76:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204e7a:	00000797          	auipc	a5,0x0
ffffffffc0204e7e:	d7078793          	addi	a5,a5,-656 # ffffffffc0204bea <forkret>
ffffffffc0204e82:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204e84:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204e86:	100027f3          	csrr	a5,sstatus
ffffffffc0204e8a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204e8c:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204e8e:	14079063          	bnez	a5,ffffffffc0204fce <do_fork+0x276>
    if (++ last_pid >= MAX_PID) {
ffffffffc0204e92:	000a2817          	auipc	a6,0xa2
ffffffffc0204e96:	53e80813          	addi	a6,a6,1342 # ffffffffc02a73d0 <last_pid.1>
ffffffffc0204e9a:	00082783          	lw	a5,0(a6)
ffffffffc0204e9e:	6709                	lui	a4,0x2
ffffffffc0204ea0:	0017851b          	addiw	a0,a5,1
ffffffffc0204ea4:	00a82023          	sw	a0,0(a6)
ffffffffc0204ea8:	08e55d63          	bge	a0,a4,ffffffffc0204f42 <do_fork+0x1ea>
    if (last_pid >= next_safe) {
ffffffffc0204eac:	000a2317          	auipc	t1,0xa2
ffffffffc0204eb0:	52830313          	addi	t1,t1,1320 # ffffffffc02a73d4 <next_safe.0>
ffffffffc0204eb4:	00032783          	lw	a5,0(t1)
ffffffffc0204eb8:	000ae417          	auipc	s0,0xae
ffffffffc0204ebc:	9d840413          	addi	s0,s0,-1576 # ffffffffc02b2890 <proc_list>
ffffffffc0204ec0:	08f55963          	bge	a0,a5,ffffffffc0204f52 <do_fork+0x1fa>
        proc->pid = get_pid();
ffffffffc0204ec4:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204ec6:	45a9                	li	a1,10
ffffffffc0204ec8:	2501                	sext.w	a0,a0
ffffffffc0204eca:	108010ef          	jal	ra,ffffffffc0205fd2 <hash32>
ffffffffc0204ece:	02051793          	slli	a5,a0,0x20
ffffffffc0204ed2:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204ed6:	000aa797          	auipc	a5,0xaa
ffffffffc0204eda:	9ba78793          	addi	a5,a5,-1606 # ffffffffc02ae890 <hash_list>
ffffffffc0204ede:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204ee0:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc0204ee2:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204ee4:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc0204ee8:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0204eea:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc0204eec:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc0204eee:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204ef0:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc0204ef4:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc0204ef6:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc0204ef8:	e21c                	sd	a5,0(a2)
ffffffffc0204efa:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc0204efc:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc0204efe:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc0204f00:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc0204f04:	10e4b023          	sd	a4,256(s1)
ffffffffc0204f08:	c311                	beqz	a4,ffffffffc0204f0c <do_fork+0x1b4>
        proc->optr->yptr = proc;
ffffffffc0204f0a:	ff64                	sd	s1,248(a4)
    nr_process ++;
ffffffffc0204f0c:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc0204f10:	fae4                	sd	s1,240(a3)
    nr_process ++;
ffffffffc0204f12:	2785                	addiw	a5,a5,1
ffffffffc0204f14:	00f92023          	sw	a5,0(s2)
    if (flag) {
ffffffffc0204f18:	18099363          	bnez	s3,ffffffffc020509e <do_fork+0x346>
    wakeup_proc(proc);  // 设置为RUNNABLE!!
ffffffffc0204f1c:	8526                	mv	a0,s1
ffffffffc0204f1e:	6c9000ef          	jal	ra,ffffffffc0205de6 <wakeup_proc>
    return proc->pid;
ffffffffc0204f22:	40c8                	lw	a0,4(s1)
}
ffffffffc0204f24:	70e6                	ld	ra,120(sp)
ffffffffc0204f26:	7446                	ld	s0,112(sp)
ffffffffc0204f28:	74a6                	ld	s1,104(sp)
ffffffffc0204f2a:	7906                	ld	s2,96(sp)
ffffffffc0204f2c:	69e6                	ld	s3,88(sp)
ffffffffc0204f2e:	6a46                	ld	s4,80(sp)
ffffffffc0204f30:	6aa6                	ld	s5,72(sp)
ffffffffc0204f32:	6b06                	ld	s6,64(sp)
ffffffffc0204f34:	7be2                	ld	s7,56(sp)
ffffffffc0204f36:	7c42                	ld	s8,48(sp)
ffffffffc0204f38:	7ca2                	ld	s9,40(sp)
ffffffffc0204f3a:	7d02                	ld	s10,32(sp)
ffffffffc0204f3c:	6de2                	ld	s11,24(sp)
ffffffffc0204f3e:	6109                	addi	sp,sp,128
ffffffffc0204f40:	8082                	ret
        last_pid = 1;
ffffffffc0204f42:	4785                	li	a5,1
ffffffffc0204f44:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc0204f48:	4505                	li	a0,1
ffffffffc0204f4a:	000a2317          	auipc	t1,0xa2
ffffffffc0204f4e:	48a30313          	addi	t1,t1,1162 # ffffffffc02a73d4 <next_safe.0>
    return listelm->next;
ffffffffc0204f52:	000ae417          	auipc	s0,0xae
ffffffffc0204f56:	93e40413          	addi	s0,s0,-1730 # ffffffffc02b2890 <proc_list>
ffffffffc0204f5a:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc0204f5e:	6789                	lui	a5,0x2
ffffffffc0204f60:	00f32023          	sw	a5,0(t1)
ffffffffc0204f64:	86aa                	mv	a3,a0
ffffffffc0204f66:	4581                	li	a1,0
        while ((le = list_next(le)) != list) {
ffffffffc0204f68:	6e89                	lui	t4,0x2
ffffffffc0204f6a:	148e0263          	beq	t3,s0,ffffffffc02050ae <do_fork+0x356>
ffffffffc0204f6e:	88ae                	mv	a7,a1
ffffffffc0204f70:	87f2                	mv	a5,t3
ffffffffc0204f72:	6609                	lui	a2,0x2
ffffffffc0204f74:	a811                	j	ffffffffc0204f88 <do_fork+0x230>
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc0204f76:	00e6d663          	bge	a3,a4,ffffffffc0204f82 <do_fork+0x22a>
ffffffffc0204f7a:	00c75463          	bge	a4,a2,ffffffffc0204f82 <do_fork+0x22a>
ffffffffc0204f7e:	863a                	mv	a2,a4
ffffffffc0204f80:	4885                	li	a7,1
ffffffffc0204f82:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0204f84:	00878d63          	beq	a5,s0,ffffffffc0204f9e <do_fork+0x246>
            if (proc->pid == last_pid) {
ffffffffc0204f88:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c7c>
ffffffffc0204f8c:	fed715e3          	bne	a4,a3,ffffffffc0204f76 <do_fork+0x21e>
                if (++ last_pid >= next_safe) {
ffffffffc0204f90:	2685                	addiw	a3,a3,1
ffffffffc0204f92:	10c6d963          	bge	a3,a2,ffffffffc02050a4 <do_fork+0x34c>
ffffffffc0204f96:	679c                	ld	a5,8(a5)
ffffffffc0204f98:	4585                	li	a1,1
        while ((le = list_next(le)) != list) {
ffffffffc0204f9a:	fe8797e3          	bne	a5,s0,ffffffffc0204f88 <do_fork+0x230>
ffffffffc0204f9e:	c581                	beqz	a1,ffffffffc0204fa6 <do_fork+0x24e>
ffffffffc0204fa0:	00d82023          	sw	a3,0(a6)
ffffffffc0204fa4:	8536                	mv	a0,a3
ffffffffc0204fa6:	f0088fe3          	beqz	a7,ffffffffc0204ec4 <do_fork+0x16c>
ffffffffc0204faa:	00c32023          	sw	a2,0(t1)
ffffffffc0204fae:	bf19                	j	ffffffffc0204ec4 <do_fork+0x16c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204fb0:	89b6                	mv	s3,a3
ffffffffc0204fb2:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204fb6:	00000797          	auipc	a5,0x0
ffffffffc0204fba:	c3478793          	addi	a5,a5,-972 # ffffffffc0204bea <forkret>
ffffffffc0204fbe:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204fc0:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204fc2:	100027f3          	csrr	a5,sstatus
ffffffffc0204fc6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204fc8:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204fca:	ec0784e3          	beqz	a5,ffffffffc0204e92 <do_fork+0x13a>
        intr_disable();
ffffffffc0204fce:	e54fb0ef          	jal	ra,ffffffffc0200622 <intr_disable>
        return 1;
ffffffffc0204fd2:	4985                	li	s3,1
ffffffffc0204fd4:	bd7d                	j	ffffffffc0204e92 <do_fork+0x13a>
    if ((mm = mm_create()) == NULL) {
ffffffffc0204fd6:	8acff0ef          	jal	ra,ffffffffc0204082 <mm_create>
ffffffffc0204fda:	8caa                	mv	s9,a0
ffffffffc0204fdc:	c541                	beqz	a0,ffffffffc0205064 <do_fork+0x30c>
    if ((page = alloc_page()) == NULL) {
ffffffffc0204fde:	4505                	li	a0,1
ffffffffc0204fe0:	cddfc0ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc0204fe4:	cd2d                	beqz	a0,ffffffffc020505e <do_fork+0x306>
    return page - pages + nbase;
ffffffffc0204fe6:	000ab683          	ld	a3,0(s5)
ffffffffc0204fea:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc0204fec:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204ff0:	40d506b3          	sub	a3,a0,a3
ffffffffc0204ff4:	8699                	srai	a3,a3,0x6
ffffffffc0204ff6:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204ff8:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ffc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204ffe:	0cedf463          	bgeu	s11,a4,ffffffffc02050c6 <do_fork+0x36e>
ffffffffc0205002:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc0205006:	6605                	lui	a2,0x1
ffffffffc0205008:	000ae597          	auipc	a1,0xae
ffffffffc020500c:	8c05b583          	ld	a1,-1856(a1) # ffffffffc02b28c8 <boot_pgdir>
ffffffffc0205010:	9a36                	add	s4,s4,a3
ffffffffc0205012:	8552                	mv	a0,s4
ffffffffc0205014:	450010ef          	jal	ra,ffffffffc0206464 <memcpy>
}

static inline void
lock_mm(struct mm_struct *mm) {
    if (mm != NULL) {
        lock(&(mm->mm_lock));
ffffffffc0205018:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc020501c:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0205020:	4785                	li	a5,1
ffffffffc0205022:	40fdb7af          	amoor.d	a5,a5,(s11)
    return !test_and_set_bit(0, lock);
}

static inline void
lock(lock_t *lock) {
    while (!try_lock(lock)) {
ffffffffc0205026:	8b85                	andi	a5,a5,1
ffffffffc0205028:	4a05                	li	s4,1
ffffffffc020502a:	c799                	beqz	a5,ffffffffc0205038 <do_fork+0x2e0>
        schedule();
ffffffffc020502c:	63b000ef          	jal	ra,ffffffffc0205e66 <schedule>
ffffffffc0205030:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock)) {
ffffffffc0205034:	8b85                	andi	a5,a5,1
ffffffffc0205036:	fbfd                	bnez	a5,ffffffffc020502c <do_fork+0x2d4>
        ret = dup_mmap(mm, oldmm);
ffffffffc0205038:	85ea                	mv	a1,s10
ffffffffc020503a:	8566                	mv	a0,s9
ffffffffc020503c:	aceff0ef          	jal	ra,ffffffffc020430a <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0205040:	57f9                	li	a5,-2
ffffffffc0205042:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc0205046:	8b85                	andi	a5,a5,1
    }
}

static inline void
unlock(lock_t *lock) {
    if (!test_and_clear_bit(0, lock)) {
ffffffffc0205048:	10078063          	beqz	a5,ffffffffc0205148 <do_fork+0x3f0>
good_mm:
ffffffffc020504c:	8d66                	mv	s10,s9
    if (ret != 0) {
ffffffffc020504e:	dc0505e3          	beqz	a0,ffffffffc0204e18 <do_fork+0xc0>
    exit_mmap(mm);
ffffffffc0205052:	8566                	mv	a0,s9
ffffffffc0205054:	b50ff0ef          	jal	ra,ffffffffc02043a4 <exit_mmap>
    put_pgdir(mm);
ffffffffc0205058:	8566                	mv	a0,s9
ffffffffc020505a:	c1dff0ef          	jal	ra,ffffffffc0204c76 <put_pgdir>
    mm_destroy(mm);
ffffffffc020505e:	8566                	mv	a0,s9
ffffffffc0205060:	9a8ff0ef          	jal	ra,ffffffffc0204208 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0205064:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc0205066:	c02007b7          	lui	a5,0xc0200
ffffffffc020506a:	0cf6e363          	bltu	a3,a5,ffffffffc0205130 <do_fork+0x3d8>
ffffffffc020506e:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage) {
ffffffffc0205072:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc0205076:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc020507a:	83b1                	srli	a5,a5,0xc
ffffffffc020507c:	06e7fe63          	bgeu	a5,a4,ffffffffc02050f8 <do_fork+0x3a0>
    return &pages[PPN(pa) - nbase];
ffffffffc0205080:	000b3703          	ld	a4,0(s6)
ffffffffc0205084:	000ab503          	ld	a0,0(s5)
ffffffffc0205088:	4589                	li	a1,2
ffffffffc020508a:	8f99                	sub	a5,a5,a4
ffffffffc020508c:	079a                	slli	a5,a5,0x6
ffffffffc020508e:	953e                	add	a0,a0,a5
ffffffffc0205090:	cbffc0ef          	jal	ra,ffffffffc0201d4e <free_pages>
    kfree(proc);
ffffffffc0205094:	8526                	mv	a0,s1
ffffffffc0205096:	af9fc0ef          	jal	ra,ffffffffc0201b8e <kfree>
    ret = -E_NO_MEM;
ffffffffc020509a:	5571                	li	a0,-4
    goto fork_out;
ffffffffc020509c:	b561                	j	ffffffffc0204f24 <do_fork+0x1cc>
        intr_enable();
ffffffffc020509e:	d7efb0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc02050a2:	bdad                	j	ffffffffc0204f1c <do_fork+0x1c4>
                    if (last_pid >= MAX_PID) {
ffffffffc02050a4:	01d6c363          	blt	a3,t4,ffffffffc02050aa <do_fork+0x352>
                        last_pid = 1;
ffffffffc02050a8:	4685                	li	a3,1
                    goto repeat;
ffffffffc02050aa:	4585                	li	a1,1
ffffffffc02050ac:	bd7d                	j	ffffffffc0204f6a <do_fork+0x212>
ffffffffc02050ae:	c599                	beqz	a1,ffffffffc02050bc <do_fork+0x364>
ffffffffc02050b0:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc02050b4:	8536                	mv	a0,a3
ffffffffc02050b6:	b539                	j	ffffffffc0204ec4 <do_fork+0x16c>
    int ret = -E_NO_FREE_PROC;
ffffffffc02050b8:	556d                	li	a0,-5
ffffffffc02050ba:	b5ad                	j	ffffffffc0204f24 <do_fork+0x1cc>
    return last_pid;
ffffffffc02050bc:	00082503          	lw	a0,0(a6)
ffffffffc02050c0:	b511                	j	ffffffffc0204ec4 <do_fork+0x16c>
    ret = -E_NO_MEM;
ffffffffc02050c2:	5571                	li	a0,-4
ffffffffc02050c4:	b585                	j	ffffffffc0204f24 <do_fork+0x1cc>
    return KADDR(page2pa(page));
ffffffffc02050c6:	00002617          	auipc	a2,0x2
ffffffffc02050ca:	14260613          	addi	a2,a2,322 # ffffffffc0207208 <default_pmm_manager+0x38>
ffffffffc02050ce:	06900593          	li	a1,105
ffffffffc02050d2:	00002517          	auipc	a0,0x2
ffffffffc02050d6:	15e50513          	addi	a0,a0,350 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc02050da:	ba0fb0ef          	jal	ra,ffffffffc020047a <__panic>
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc02050de:	86be                	mv	a3,a5
ffffffffc02050e0:	00002617          	auipc	a2,0x2
ffffffffc02050e4:	1d060613          	addi	a2,a2,464 # ffffffffc02072b0 <default_pmm_manager+0xe0>
ffffffffc02050e8:	16700593          	li	a1,359
ffffffffc02050ec:	00003517          	auipc	a0,0x3
ffffffffc02050f0:	15c50513          	addi	a0,a0,348 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc02050f4:	b86fb0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02050f8:	00002617          	auipc	a2,0x2
ffffffffc02050fc:	1e060613          	addi	a2,a2,480 # ffffffffc02072d8 <default_pmm_manager+0x108>
ffffffffc0205100:	06200593          	li	a1,98
ffffffffc0205104:	00002517          	auipc	a0,0x2
ffffffffc0205108:	12c50513          	addi	a0,a0,300 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc020510c:	b6efb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(current->wait_state == 0);
ffffffffc0205110:	00003697          	auipc	a3,0x3
ffffffffc0205114:	15068693          	addi	a3,a3,336 # ffffffffc0208260 <default_pmm_manager+0x1090>
ffffffffc0205118:	00002617          	auipc	a2,0x2
ffffffffc020511c:	a2060613          	addi	a2,a2,-1504 # ffffffffc0206b38 <commands+0x450>
ffffffffc0205120:	1a800593          	li	a1,424
ffffffffc0205124:	00003517          	auipc	a0,0x3
ffffffffc0205128:	12450513          	addi	a0,a0,292 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc020512c:	b4efb0ef          	jal	ra,ffffffffc020047a <__panic>
    return pa2page(PADDR(kva));
ffffffffc0205130:	00002617          	auipc	a2,0x2
ffffffffc0205134:	18060613          	addi	a2,a2,384 # ffffffffc02072b0 <default_pmm_manager+0xe0>
ffffffffc0205138:	06e00593          	li	a1,110
ffffffffc020513c:	00002517          	auipc	a0,0x2
ffffffffc0205140:	0f450513          	addi	a0,a0,244 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc0205144:	b36fb0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("Unlock failed.\n");
ffffffffc0205148:	00003617          	auipc	a2,0x3
ffffffffc020514c:	13860613          	addi	a2,a2,312 # ffffffffc0208280 <default_pmm_manager+0x10b0>
ffffffffc0205150:	03100593          	li	a1,49
ffffffffc0205154:	00003517          	auipc	a0,0x3
ffffffffc0205158:	13c50513          	addi	a0,a0,316 # ffffffffc0208290 <default_pmm_manager+0x10c0>
ffffffffc020515c:	b1efb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0205160 <kernel_thread>:
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc0205160:	7129                	addi	sp,sp,-320
ffffffffc0205162:	fa22                	sd	s0,304(sp)
ffffffffc0205164:	f626                	sd	s1,296(sp)
ffffffffc0205166:	f24a                	sd	s2,288(sp)
ffffffffc0205168:	84ae                	mv	s1,a1
ffffffffc020516a:	892a                	mv	s2,a0
ffffffffc020516c:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020516e:	4581                	li	a1,0
ffffffffc0205170:	12000613          	li	a2,288
ffffffffc0205174:	850a                	mv	a0,sp
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc0205176:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0205178:	2da010ef          	jal	ra,ffffffffc0206452 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc020517c:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020517e:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0205180:	100027f3          	csrr	a5,sstatus
ffffffffc0205184:	edd7f793          	andi	a5,a5,-291
ffffffffc0205188:	1207e793          	ori	a5,a5,288
ffffffffc020518c:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020518e:	860a                	mv	a2,sp
ffffffffc0205190:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0205194:	00000797          	auipc	a5,0x0
ffffffffc0205198:	9dc78793          	addi	a5,a5,-1572 # ffffffffc0204b70 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020519c:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020519e:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02051a0:	bb9ff0ef          	jal	ra,ffffffffc0204d58 <do_fork>
}
ffffffffc02051a4:	70f2                	ld	ra,312(sp)
ffffffffc02051a6:	7452                	ld	s0,304(sp)
ffffffffc02051a8:	74b2                	ld	s1,296(sp)
ffffffffc02051aa:	7912                	ld	s2,288(sp)
ffffffffc02051ac:	6131                	addi	sp,sp,320
ffffffffc02051ae:	8082                	ret

ffffffffc02051b0 <do_exit>:
do_exit(int error_code) {
ffffffffc02051b0:	7179                	addi	sp,sp,-48
ffffffffc02051b2:	f022                	sd	s0,32(sp)
    if (current == idleproc) {
ffffffffc02051b4:	000ad417          	auipc	s0,0xad
ffffffffc02051b8:	76440413          	addi	s0,s0,1892 # ffffffffc02b2918 <current>
ffffffffc02051bc:	601c                	ld	a5,0(s0)
do_exit(int error_code) {
ffffffffc02051be:	f406                	sd	ra,40(sp)
ffffffffc02051c0:	ec26                	sd	s1,24(sp)
ffffffffc02051c2:	e84a                	sd	s2,16(sp)
ffffffffc02051c4:	e44e                	sd	s3,8(sp)
ffffffffc02051c6:	e052                	sd	s4,0(sp)
    if (current == idleproc) {
ffffffffc02051c8:	000ad717          	auipc	a4,0xad
ffffffffc02051cc:	75873703          	ld	a4,1880(a4) # ffffffffc02b2920 <idleproc>
ffffffffc02051d0:	0ce78c63          	beq	a5,a4,ffffffffc02052a8 <do_exit+0xf8>
    if (current == initproc) {
ffffffffc02051d4:	000ad497          	auipc	s1,0xad
ffffffffc02051d8:	75448493          	addi	s1,s1,1876 # ffffffffc02b2928 <initproc>
ffffffffc02051dc:	6098                	ld	a4,0(s1)
ffffffffc02051de:	0ee78b63          	beq	a5,a4,ffffffffc02052d4 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc02051e2:	0287b983          	ld	s3,40(a5)
ffffffffc02051e6:	892a                	mv	s2,a0
    if (mm != NULL) {
ffffffffc02051e8:	02098663          	beqz	s3,ffffffffc0205214 <do_exit+0x64>
ffffffffc02051ec:	000ad797          	auipc	a5,0xad
ffffffffc02051f0:	6d47b783          	ld	a5,1748(a5) # ffffffffc02b28c0 <boot_cr3>
ffffffffc02051f4:	577d                	li	a4,-1
ffffffffc02051f6:	177e                	slli	a4,a4,0x3f
ffffffffc02051f8:	83b1                	srli	a5,a5,0xc
ffffffffc02051fa:	8fd9                	or	a5,a5,a4
ffffffffc02051fc:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0205200:	0309a783          	lw	a5,48(s3)
ffffffffc0205204:	fff7871b          	addiw	a4,a5,-1
ffffffffc0205208:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0) {
ffffffffc020520c:	cb55                	beqz	a4,ffffffffc02052c0 <do_exit+0x110>
        current->mm = NULL;
ffffffffc020520e:	601c                	ld	a5,0(s0)
ffffffffc0205210:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0205214:	601c                	ld	a5,0(s0)
ffffffffc0205216:	470d                	li	a4,3
ffffffffc0205218:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc020521a:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020521e:	100027f3          	csrr	a5,sstatus
ffffffffc0205222:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205224:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205226:	e3f9                	bnez	a5,ffffffffc02052ec <do_exit+0x13c>
        proc = current->parent;
ffffffffc0205228:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD) {
ffffffffc020522a:	800007b7          	lui	a5,0x80000
ffffffffc020522e:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0205230:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD) {
ffffffffc0205232:	0ec52703          	lw	a4,236(a0)
ffffffffc0205236:	0af70f63          	beq	a4,a5,ffffffffc02052f4 <do_exit+0x144>
        while (current->cptr != NULL) {
ffffffffc020523a:	6018                	ld	a4,0(s0)
ffffffffc020523c:	7b7c                	ld	a5,240(a4)
ffffffffc020523e:	c3a1                	beqz	a5,ffffffffc020527e <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD) {
ffffffffc0205240:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE) {
ffffffffc0205244:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD) {
ffffffffc0205246:	0985                	addi	s3,s3,1
ffffffffc0205248:	a021                	j	ffffffffc0205250 <do_exit+0xa0>
        while (current->cptr != NULL) {
ffffffffc020524a:	6018                	ld	a4,0(s0)
ffffffffc020524c:	7b7c                	ld	a5,240(a4)
ffffffffc020524e:	cb85                	beqz	a5,ffffffffc020527e <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc0205250:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fd0>
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc0205254:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0205256:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc0205258:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc020525a:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc020525e:	10e7b023          	sd	a4,256(a5)
ffffffffc0205262:	c311                	beqz	a4,ffffffffc0205266 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0205264:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc0205266:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0205268:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc020526a:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc020526c:	fd271fe3          	bne	a4,s2,ffffffffc020524a <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD) {
ffffffffc0205270:	0ec52783          	lw	a5,236(a0)
ffffffffc0205274:	fd379be3          	bne	a5,s3,ffffffffc020524a <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc0205278:	36f000ef          	jal	ra,ffffffffc0205de6 <wakeup_proc>
ffffffffc020527c:	b7f9                	j	ffffffffc020524a <do_exit+0x9a>
    if (flag) {
ffffffffc020527e:	020a1263          	bnez	s4,ffffffffc02052a2 <do_exit+0xf2>
    schedule();
ffffffffc0205282:	3e5000ef          	jal	ra,ffffffffc0205e66 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0205286:	601c                	ld	a5,0(s0)
ffffffffc0205288:	00003617          	auipc	a2,0x3
ffffffffc020528c:	04060613          	addi	a2,a2,64 # ffffffffc02082c8 <default_pmm_manager+0x10f8>
ffffffffc0205290:	20e00593          	li	a1,526
ffffffffc0205294:	43d4                	lw	a3,4(a5)
ffffffffc0205296:	00003517          	auipc	a0,0x3
ffffffffc020529a:	fb250513          	addi	a0,a0,-78 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc020529e:	9dcfb0ef          	jal	ra,ffffffffc020047a <__panic>
        intr_enable();
ffffffffc02052a2:	b7afb0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc02052a6:	bff1                	j	ffffffffc0205282 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc02052a8:	00003617          	auipc	a2,0x3
ffffffffc02052ac:	00060613          	mv	a2,a2
ffffffffc02052b0:	1e200593          	li	a1,482
ffffffffc02052b4:	00003517          	auipc	a0,0x3
ffffffffc02052b8:	f9450513          	addi	a0,a0,-108 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc02052bc:	9befb0ef          	jal	ra,ffffffffc020047a <__panic>
            exit_mmap(mm);
ffffffffc02052c0:	854e                	mv	a0,s3
ffffffffc02052c2:	8e2ff0ef          	jal	ra,ffffffffc02043a4 <exit_mmap>
            put_pgdir(mm);
ffffffffc02052c6:	854e                	mv	a0,s3
ffffffffc02052c8:	9afff0ef          	jal	ra,ffffffffc0204c76 <put_pgdir>
            mm_destroy(mm);
ffffffffc02052cc:	854e                	mv	a0,s3
ffffffffc02052ce:	f3bfe0ef          	jal	ra,ffffffffc0204208 <mm_destroy>
ffffffffc02052d2:	bf35                	j	ffffffffc020520e <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc02052d4:	00003617          	auipc	a2,0x3
ffffffffc02052d8:	fe460613          	addi	a2,a2,-28 # ffffffffc02082b8 <default_pmm_manager+0x10e8>
ffffffffc02052dc:	1e500593          	li	a1,485
ffffffffc02052e0:	00003517          	auipc	a0,0x3
ffffffffc02052e4:	f6850513          	addi	a0,a0,-152 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc02052e8:	992fb0ef          	jal	ra,ffffffffc020047a <__panic>
        intr_disable();
ffffffffc02052ec:	b36fb0ef          	jal	ra,ffffffffc0200622 <intr_disable>
        return 1;
ffffffffc02052f0:	4a05                	li	s4,1
ffffffffc02052f2:	bf1d                	j	ffffffffc0205228 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc02052f4:	2f3000ef          	jal	ra,ffffffffc0205de6 <wakeup_proc>
ffffffffc02052f8:	b789                	j	ffffffffc020523a <do_exit+0x8a>

ffffffffc02052fa <do_wait.part.0>:
do_wait(int pid, int *code_store) {
ffffffffc02052fa:	715d                	addi	sp,sp,-80
ffffffffc02052fc:	f84a                	sd	s2,48(sp)
ffffffffc02052fe:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc0205300:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205304:	6989                	lui	s3,0x2
do_wait(int pid, int *code_store) {
ffffffffc0205306:	fc26                	sd	s1,56(sp)
ffffffffc0205308:	f052                	sd	s4,32(sp)
ffffffffc020530a:	ec56                	sd	s5,24(sp)
ffffffffc020530c:	e85a                	sd	s6,16(sp)
ffffffffc020530e:	e45e                	sd	s7,8(sp)
ffffffffc0205310:	e486                	sd	ra,72(sp)
ffffffffc0205312:	e0a2                	sd	s0,64(sp)
ffffffffc0205314:	84aa                	mv	s1,a0
ffffffffc0205316:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc0205318:	000adb97          	auipc	s7,0xad
ffffffffc020531c:	600b8b93          	addi	s7,s7,1536 # ffffffffc02b2918 <current>
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205320:	00050b1b          	sext.w	s6,a0
ffffffffc0205324:	fff50a9b          	addiw	s5,a0,-1
ffffffffc0205328:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc020532a:	0905                	addi	s2,s2,1
    if (pid != 0) {
ffffffffc020532c:	ccbd                	beqz	s1,ffffffffc02053aa <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID) {
ffffffffc020532e:	0359e863          	bltu	s3,s5,ffffffffc020535e <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205332:	45a9                	li	a1,10
ffffffffc0205334:	855a                	mv	a0,s6
ffffffffc0205336:	49d000ef          	jal	ra,ffffffffc0205fd2 <hash32>
ffffffffc020533a:	02051793          	slli	a5,a0,0x20
ffffffffc020533e:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0205342:	000a9797          	auipc	a5,0xa9
ffffffffc0205346:	54e78793          	addi	a5,a5,1358 # ffffffffc02ae890 <hash_list>
ffffffffc020534a:	953e                	add	a0,a0,a5
ffffffffc020534c:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list) {
ffffffffc020534e:	a029                	j	ffffffffc0205358 <do_wait.part.0+0x5e>
            if (proc->pid == pid) {
ffffffffc0205350:	f2c42783          	lw	a5,-212(s0)
ffffffffc0205354:	02978163          	beq	a5,s1,ffffffffc0205376 <do_wait.part.0+0x7c>
ffffffffc0205358:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list) {
ffffffffc020535a:	fe851be3          	bne	a0,s0,ffffffffc0205350 <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc020535e:	5579                	li	a0,-2
}
ffffffffc0205360:	60a6                	ld	ra,72(sp)
ffffffffc0205362:	6406                	ld	s0,64(sp)
ffffffffc0205364:	74e2                	ld	s1,56(sp)
ffffffffc0205366:	7942                	ld	s2,48(sp)
ffffffffc0205368:	79a2                	ld	s3,40(sp)
ffffffffc020536a:	7a02                	ld	s4,32(sp)
ffffffffc020536c:	6ae2                	ld	s5,24(sp)
ffffffffc020536e:	6b42                	ld	s6,16(sp)
ffffffffc0205370:	6ba2                	ld	s7,8(sp)
ffffffffc0205372:	6161                	addi	sp,sp,80
ffffffffc0205374:	8082                	ret
        if (proc != NULL && proc->parent == current) {
ffffffffc0205376:	000bb683          	ld	a3,0(s7)
ffffffffc020537a:	f4843783          	ld	a5,-184(s0)
ffffffffc020537e:	fed790e3          	bne	a5,a3,ffffffffc020535e <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc0205382:	f2842703          	lw	a4,-216(s0)
ffffffffc0205386:	478d                	li	a5,3
ffffffffc0205388:	0ef70b63          	beq	a4,a5,ffffffffc020547e <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc020538c:	4785                	li	a5,1
ffffffffc020538e:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc0205390:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc0205394:	2d3000ef          	jal	ra,ffffffffc0205e66 <schedule>
        if (current->flags & PF_EXITING) {
ffffffffc0205398:	000bb783          	ld	a5,0(s7)
ffffffffc020539c:	0b07a783          	lw	a5,176(a5)
ffffffffc02053a0:	8b85                	andi	a5,a5,1
ffffffffc02053a2:	d7c9                	beqz	a5,ffffffffc020532c <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc02053a4:	555d                	li	a0,-9
ffffffffc02053a6:	e0bff0ef          	jal	ra,ffffffffc02051b0 <do_exit>
        proc = current->cptr;
ffffffffc02053aa:	000bb683          	ld	a3,0(s7)
ffffffffc02053ae:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr) {
ffffffffc02053b0:	d45d                	beqz	s0,ffffffffc020535e <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02053b2:	470d                	li	a4,3
ffffffffc02053b4:	a021                	j	ffffffffc02053bc <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr) {
ffffffffc02053b6:	10043403          	ld	s0,256(s0)
ffffffffc02053ba:	d869                	beqz	s0,ffffffffc020538c <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02053bc:	401c                	lw	a5,0(s0)
ffffffffc02053be:	fee79ce3          	bne	a5,a4,ffffffffc02053b6 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc) {
ffffffffc02053c2:	000ad797          	auipc	a5,0xad
ffffffffc02053c6:	55e7b783          	ld	a5,1374(a5) # ffffffffc02b2920 <idleproc>
ffffffffc02053ca:	0c878963          	beq	a5,s0,ffffffffc020549c <do_wait.part.0+0x1a2>
ffffffffc02053ce:	000ad797          	auipc	a5,0xad
ffffffffc02053d2:	55a7b783          	ld	a5,1370(a5) # ffffffffc02b2928 <initproc>
ffffffffc02053d6:	0cf40363          	beq	s0,a5,ffffffffc020549c <do_wait.part.0+0x1a2>
    if (code_store != NULL) {
ffffffffc02053da:	000a0663          	beqz	s4,ffffffffc02053e6 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc02053de:	0e842783          	lw	a5,232(s0)
ffffffffc02053e2:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02053e6:	100027f3          	csrr	a5,sstatus
ffffffffc02053ea:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02053ec:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02053ee:	e7c1                	bnez	a5,ffffffffc0205476 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02053f0:	6c70                	ld	a2,216(s0)
ffffffffc02053f2:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL) {
ffffffffc02053f4:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc02053f8:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc02053fa:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02053fc:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02053fe:	6470                	ld	a2,200(s0)
ffffffffc0205400:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0205402:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0205404:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL) {
ffffffffc0205406:	c319                	beqz	a4,ffffffffc020540c <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc0205408:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL) {
ffffffffc020540a:	7c7c                	ld	a5,248(s0)
ffffffffc020540c:	c3b5                	beqz	a5,ffffffffc0205470 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc020540e:	10e7b023          	sd	a4,256(a5)
    nr_process --;
ffffffffc0205412:	000ad717          	auipc	a4,0xad
ffffffffc0205416:	51e70713          	addi	a4,a4,1310 # ffffffffc02b2930 <nr_process>
ffffffffc020541a:	431c                	lw	a5,0(a4)
ffffffffc020541c:	37fd                	addiw	a5,a5,-1
ffffffffc020541e:	c31c                	sw	a5,0(a4)
    if (flag) {
ffffffffc0205420:	e5a9                	bnez	a1,ffffffffc020546a <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0205422:	6814                	ld	a3,16(s0)
ffffffffc0205424:	c02007b7          	lui	a5,0xc0200
ffffffffc0205428:	04f6ee63          	bltu	a3,a5,ffffffffc0205484 <do_wait.part.0+0x18a>
ffffffffc020542c:	000ad797          	auipc	a5,0xad
ffffffffc0205430:	4bc7b783          	ld	a5,1212(a5) # ffffffffc02b28e8 <va_pa_offset>
ffffffffc0205434:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc0205436:	82b1                	srli	a3,a3,0xc
ffffffffc0205438:	000ad797          	auipc	a5,0xad
ffffffffc020543c:	4987b783          	ld	a5,1176(a5) # ffffffffc02b28d0 <npage>
ffffffffc0205440:	06f6fa63          	bgeu	a3,a5,ffffffffc02054b4 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0205444:	00003517          	auipc	a0,0x3
ffffffffc0205448:	6bc53503          	ld	a0,1724(a0) # ffffffffc0208b00 <nbase>
ffffffffc020544c:	8e89                	sub	a3,a3,a0
ffffffffc020544e:	069a                	slli	a3,a3,0x6
ffffffffc0205450:	000ad517          	auipc	a0,0xad
ffffffffc0205454:	48853503          	ld	a0,1160(a0) # ffffffffc02b28d8 <pages>
ffffffffc0205458:	9536                	add	a0,a0,a3
ffffffffc020545a:	4589                	li	a1,2
ffffffffc020545c:	8f3fc0ef          	jal	ra,ffffffffc0201d4e <free_pages>
    kfree(proc);
ffffffffc0205460:	8522                	mv	a0,s0
ffffffffc0205462:	f2cfc0ef          	jal	ra,ffffffffc0201b8e <kfree>
    return 0;
ffffffffc0205466:	4501                	li	a0,0
ffffffffc0205468:	bde5                	j	ffffffffc0205360 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc020546a:	9b2fb0ef          	jal	ra,ffffffffc020061c <intr_enable>
ffffffffc020546e:	bf55                	j	ffffffffc0205422 <do_wait.part.0+0x128>
       proc->parent->cptr = proc->optr;
ffffffffc0205470:	701c                	ld	a5,32(s0)
ffffffffc0205472:	fbf8                	sd	a4,240(a5)
ffffffffc0205474:	bf79                	j	ffffffffc0205412 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0205476:	9acfb0ef          	jal	ra,ffffffffc0200622 <intr_disable>
        return 1;
ffffffffc020547a:	4585                	li	a1,1
ffffffffc020547c:	bf95                	j	ffffffffc02053f0 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020547e:	f2840413          	addi	s0,s0,-216
ffffffffc0205482:	b781                	j	ffffffffc02053c2 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0205484:	00002617          	auipc	a2,0x2
ffffffffc0205488:	e2c60613          	addi	a2,a2,-468 # ffffffffc02072b0 <default_pmm_manager+0xe0>
ffffffffc020548c:	06e00593          	li	a1,110
ffffffffc0205490:	00002517          	auipc	a0,0x2
ffffffffc0205494:	da050513          	addi	a0,a0,-608 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc0205498:	fe3fa0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc020549c:	00003617          	auipc	a2,0x3
ffffffffc02054a0:	e4c60613          	addi	a2,a2,-436 # ffffffffc02082e8 <default_pmm_manager+0x1118>
ffffffffc02054a4:	30500593          	li	a1,773
ffffffffc02054a8:	00003517          	auipc	a0,0x3
ffffffffc02054ac:	da050513          	addi	a0,a0,-608 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc02054b0:	fcbfa0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02054b4:	00002617          	auipc	a2,0x2
ffffffffc02054b8:	e2460613          	addi	a2,a2,-476 # ffffffffc02072d8 <default_pmm_manager+0x108>
ffffffffc02054bc:	06200593          	li	a1,98
ffffffffc02054c0:	00002517          	auipc	a0,0x2
ffffffffc02054c4:	d7050513          	addi	a0,a0,-656 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc02054c8:	fb3fa0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02054cc <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg) {
ffffffffc02054cc:	1141                	addi	sp,sp,-16
ffffffffc02054ce:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02054d0:	8bffc0ef          	jal	ra,ffffffffc0201d8e <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02054d4:	e06fc0ef          	jal	ra,ffffffffc0201ada <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02054d8:	4601                	li	a2,0
ffffffffc02054da:	4581                	li	a1,0
ffffffffc02054dc:	fffff517          	auipc	a0,0xfffff
ffffffffc02054e0:	71c50513          	addi	a0,a0,1820 # ffffffffc0204bf8 <user_main>
ffffffffc02054e4:	c7dff0ef          	jal	ra,ffffffffc0205160 <kernel_thread>
    if (pid <= 0) {
ffffffffc02054e8:	00a04563          	bgtz	a0,ffffffffc02054f2 <init_main+0x26>
ffffffffc02054ec:	a071                	j	ffffffffc0205578 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0) {
        schedule();
ffffffffc02054ee:	179000ef          	jal	ra,ffffffffc0205e66 <schedule>
    if (code_store != NULL) {
ffffffffc02054f2:	4581                	li	a1,0
ffffffffc02054f4:	4501                	li	a0,0
ffffffffc02054f6:	e05ff0ef          	jal	ra,ffffffffc02052fa <do_wait.part.0>
    while (do_wait(0, NULL) == 0) {
ffffffffc02054fa:	d975                	beqz	a0,ffffffffc02054ee <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02054fc:	00003517          	auipc	a0,0x3
ffffffffc0205500:	e2c50513          	addi	a0,a0,-468 # ffffffffc0208328 <default_pmm_manager+0x1158>
ffffffffc0205504:	c7dfa0ef          	jal	ra,ffffffffc0200180 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0205508:	000ad797          	auipc	a5,0xad
ffffffffc020550c:	4207b783          	ld	a5,1056(a5) # ffffffffc02b2928 <initproc>
ffffffffc0205510:	7bf8                	ld	a4,240(a5)
ffffffffc0205512:	e339                	bnez	a4,ffffffffc0205558 <init_main+0x8c>
ffffffffc0205514:	7ff8                	ld	a4,248(a5)
ffffffffc0205516:	e329                	bnez	a4,ffffffffc0205558 <init_main+0x8c>
ffffffffc0205518:	1007b703          	ld	a4,256(a5)
ffffffffc020551c:	ef15                	bnez	a4,ffffffffc0205558 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc020551e:	000ad697          	auipc	a3,0xad
ffffffffc0205522:	4126a683          	lw	a3,1042(a3) # ffffffffc02b2930 <nr_process>
ffffffffc0205526:	4709                	li	a4,2
ffffffffc0205528:	0ae69463          	bne	a3,a4,ffffffffc02055d0 <init_main+0x104>
    return listelm->next;
ffffffffc020552c:	000ad697          	auipc	a3,0xad
ffffffffc0205530:	36468693          	addi	a3,a3,868 # ffffffffc02b2890 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0205534:	6698                	ld	a4,8(a3)
ffffffffc0205536:	0c878793          	addi	a5,a5,200
ffffffffc020553a:	06f71b63          	bne	a4,a5,ffffffffc02055b0 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020553e:	629c                	ld	a5,0(a3)
ffffffffc0205540:	04f71863          	bne	a4,a5,ffffffffc0205590 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0205544:	00003517          	auipc	a0,0x3
ffffffffc0205548:	ecc50513          	addi	a0,a0,-308 # ffffffffc0208410 <default_pmm_manager+0x1240>
ffffffffc020554c:	c35fa0ef          	jal	ra,ffffffffc0200180 <cprintf>
    return 0;
}
ffffffffc0205550:	60a2                	ld	ra,8(sp)
ffffffffc0205552:	4501                	li	a0,0
ffffffffc0205554:	0141                	addi	sp,sp,16
ffffffffc0205556:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0205558:	00003697          	auipc	a3,0x3
ffffffffc020555c:	df868693          	addi	a3,a3,-520 # ffffffffc0208350 <default_pmm_manager+0x1180>
ffffffffc0205560:	00001617          	auipc	a2,0x1
ffffffffc0205564:	5d860613          	addi	a2,a2,1496 # ffffffffc0206b38 <commands+0x450>
ffffffffc0205568:	36a00593          	li	a1,874
ffffffffc020556c:	00003517          	auipc	a0,0x3
ffffffffc0205570:	cdc50513          	addi	a0,a0,-804 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc0205574:	f07fa0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("create user_main failed.\n");
ffffffffc0205578:	00003617          	auipc	a2,0x3
ffffffffc020557c:	d9060613          	addi	a2,a2,-624 # ffffffffc0208308 <default_pmm_manager+0x1138>
ffffffffc0205580:	36200593          	li	a1,866
ffffffffc0205584:	00003517          	auipc	a0,0x3
ffffffffc0205588:	cc450513          	addi	a0,a0,-828 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc020558c:	eeffa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0205590:	00003697          	auipc	a3,0x3
ffffffffc0205594:	e5068693          	addi	a3,a3,-432 # ffffffffc02083e0 <default_pmm_manager+0x1210>
ffffffffc0205598:	00001617          	auipc	a2,0x1
ffffffffc020559c:	5a060613          	addi	a2,a2,1440 # ffffffffc0206b38 <commands+0x450>
ffffffffc02055a0:	36d00593          	li	a1,877
ffffffffc02055a4:	00003517          	auipc	a0,0x3
ffffffffc02055a8:	ca450513          	addi	a0,a0,-860 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc02055ac:	ecffa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02055b0:	00003697          	auipc	a3,0x3
ffffffffc02055b4:	e0068693          	addi	a3,a3,-512 # ffffffffc02083b0 <default_pmm_manager+0x11e0>
ffffffffc02055b8:	00001617          	auipc	a2,0x1
ffffffffc02055bc:	58060613          	addi	a2,a2,1408 # ffffffffc0206b38 <commands+0x450>
ffffffffc02055c0:	36c00593          	li	a1,876
ffffffffc02055c4:	00003517          	auipc	a0,0x3
ffffffffc02055c8:	c8450513          	addi	a0,a0,-892 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc02055cc:	eaffa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_process == 2);
ffffffffc02055d0:	00003697          	auipc	a3,0x3
ffffffffc02055d4:	dd068693          	addi	a3,a3,-560 # ffffffffc02083a0 <default_pmm_manager+0x11d0>
ffffffffc02055d8:	00001617          	auipc	a2,0x1
ffffffffc02055dc:	56060613          	addi	a2,a2,1376 # ffffffffc0206b38 <commands+0x450>
ffffffffc02055e0:	36b00593          	li	a1,875
ffffffffc02055e4:	00003517          	auipc	a0,0x3
ffffffffc02055e8:	c6450513          	addi	a0,a0,-924 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc02055ec:	e8ffa0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02055f0 <do_execve>:
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc02055f0:	7171                	addi	sp,sp,-176
ffffffffc02055f2:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02055f4:	000add97          	auipc	s11,0xad
ffffffffc02055f8:	324d8d93          	addi	s11,s11,804 # ffffffffc02b2918 <current>
ffffffffc02055fc:	000db783          	ld	a5,0(s11)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205600:	e54e                	sd	s3,136(sp)
ffffffffc0205602:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0205604:	0287b983          	ld	s3,40(a5)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205608:	e94a                	sd	s2,144(sp)
ffffffffc020560a:	f4de                	sd	s7,104(sp)
ffffffffc020560c:	892a                	mv	s2,a0
ffffffffc020560e:	8bb2                	mv	s7,a2
ffffffffc0205610:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc0205612:	862e                	mv	a2,a1
ffffffffc0205614:	4681                	li	a3,0
ffffffffc0205616:	85aa                	mv	a1,a0
ffffffffc0205618:	854e                	mv	a0,s3
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc020561a:	f506                	sd	ra,168(sp)
ffffffffc020561c:	f122                	sd	s0,160(sp)
ffffffffc020561e:	e152                	sd	s4,128(sp)
ffffffffc0205620:	fcd6                	sd	s5,120(sp)
ffffffffc0205622:	f8da                	sd	s6,112(sp)
ffffffffc0205624:	f0e2                	sd	s8,96(sp)
ffffffffc0205626:	ece6                	sd	s9,88(sp)
ffffffffc0205628:	e8ea                	sd	s10,80(sp)
ffffffffc020562a:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc020562c:	beaff0ef          	jal	ra,ffffffffc0204a16 <user_mem_check>
ffffffffc0205630:	40050863          	beqz	a0,ffffffffc0205a40 <do_execve+0x450>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0205634:	4641                	li	a2,16
ffffffffc0205636:	4581                	li	a1,0
ffffffffc0205638:	1808                	addi	a0,sp,48
ffffffffc020563a:	619000ef          	jal	ra,ffffffffc0206452 <memset>
    memcpy(local_name, name, len);
ffffffffc020563e:	47bd                	li	a5,15
ffffffffc0205640:	8626                	mv	a2,s1
ffffffffc0205642:	1e97e063          	bltu	a5,s1,ffffffffc0205822 <do_execve+0x232>
ffffffffc0205646:	85ca                	mv	a1,s2
ffffffffc0205648:	1808                	addi	a0,sp,48
ffffffffc020564a:	61b000ef          	jal	ra,ffffffffc0206464 <memcpy>
    if (mm != NULL) {
ffffffffc020564e:	1e098163          	beqz	s3,ffffffffc0205830 <do_execve+0x240>
        cputs("mm != NULL");
ffffffffc0205652:	00002517          	auipc	a0,0x2
ffffffffc0205656:	30650513          	addi	a0,a0,774 # ffffffffc0207958 <default_pmm_manager+0x788>
ffffffffc020565a:	b5ffa0ef          	jal	ra,ffffffffc02001b8 <cputs>
ffffffffc020565e:	000ad797          	auipc	a5,0xad
ffffffffc0205662:	2627b783          	ld	a5,610(a5) # ffffffffc02b28c0 <boot_cr3>
ffffffffc0205666:	577d                	li	a4,-1
ffffffffc0205668:	177e                	slli	a4,a4,0x3f
ffffffffc020566a:	83b1                	srli	a5,a5,0xc
ffffffffc020566c:	8fd9                	or	a5,a5,a4
ffffffffc020566e:	18079073          	csrw	satp,a5
ffffffffc0205672:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7b88>
ffffffffc0205676:	fff7871b          	addiw	a4,a5,-1
ffffffffc020567a:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0) {
ffffffffc020567e:	2c070263          	beqz	a4,ffffffffc0205942 <do_execve+0x352>
        current->mm = NULL;
ffffffffc0205682:	000db783          	ld	a5,0(s11)
ffffffffc0205686:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL) {
ffffffffc020568a:	9f9fe0ef          	jal	ra,ffffffffc0204082 <mm_create>
ffffffffc020568e:	84aa                	mv	s1,a0
ffffffffc0205690:	1c050b63          	beqz	a0,ffffffffc0205866 <do_execve+0x276>
    if ((page = alloc_page()) == NULL) {
ffffffffc0205694:	4505                	li	a0,1
ffffffffc0205696:	e26fc0ef          	jal	ra,ffffffffc0201cbc <alloc_pages>
ffffffffc020569a:	3a050763          	beqz	a0,ffffffffc0205a48 <do_execve+0x458>
    return page - pages + nbase;
ffffffffc020569e:	000adc97          	auipc	s9,0xad
ffffffffc02056a2:	23ac8c93          	addi	s9,s9,570 # ffffffffc02b28d8 <pages>
ffffffffc02056a6:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc02056aa:	000adc17          	auipc	s8,0xad
ffffffffc02056ae:	226c0c13          	addi	s8,s8,550 # ffffffffc02b28d0 <npage>
    return page - pages + nbase;
ffffffffc02056b2:	00003717          	auipc	a4,0x3
ffffffffc02056b6:	44e73703          	ld	a4,1102(a4) # ffffffffc0208b00 <nbase>
ffffffffc02056ba:	40d506b3          	sub	a3,a0,a3
ffffffffc02056be:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02056c0:	5afd                	li	s5,-1
ffffffffc02056c2:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc02056c6:	96ba                	add	a3,a3,a4
ffffffffc02056c8:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc02056ca:	00cad713          	srli	a4,s5,0xc
ffffffffc02056ce:	ec3a                	sd	a4,24(sp)
ffffffffc02056d0:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02056d2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02056d4:	36f77e63          	bgeu	a4,a5,ffffffffc0205a50 <do_execve+0x460>
ffffffffc02056d8:	000adb17          	auipc	s6,0xad
ffffffffc02056dc:	210b0b13          	addi	s6,s6,528 # ffffffffc02b28e8 <va_pa_offset>
ffffffffc02056e0:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc02056e4:	6605                	lui	a2,0x1
ffffffffc02056e6:	000ad597          	auipc	a1,0xad
ffffffffc02056ea:	1e25b583          	ld	a1,482(a1) # ffffffffc02b28c8 <boot_pgdir>
ffffffffc02056ee:	9936                	add	s2,s2,a3
ffffffffc02056f0:	854a                	mv	a0,s2
ffffffffc02056f2:	573000ef          	jal	ra,ffffffffc0206464 <memcpy>
    if (elf->e_magic != ELF_MAGIC) {
ffffffffc02056f6:	7782                	ld	a5,32(sp)
ffffffffc02056f8:	4398                	lw	a4,0(a5)
ffffffffc02056fa:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc02056fe:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC) {
ffffffffc0205702:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b944f>
ffffffffc0205706:	14f71663          	bne	a4,a5,ffffffffc0205852 <do_execve+0x262>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020570a:	7682                	ld	a3,32(sp)
ffffffffc020570c:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0205710:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0205714:	00371793          	slli	a5,a4,0x3
ffffffffc0205718:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc020571a:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020571c:	078e                	slli	a5,a5,0x3
ffffffffc020571e:	97ce                	add	a5,a5,s3
ffffffffc0205720:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph ++) {
ffffffffc0205722:	00f9fc63          	bgeu	s3,a5,ffffffffc020573a <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD) {
ffffffffc0205726:	0009a783          	lw	a5,0(s3)
ffffffffc020572a:	4705                	li	a4,1
ffffffffc020572c:	12e78f63          	beq	a5,a4,ffffffffc020586a <do_execve+0x27a>
    for (; ph < ph_end; ph ++) {
ffffffffc0205730:	77a2                	ld	a5,40(sp)
ffffffffc0205732:	03898993          	addi	s3,s3,56
ffffffffc0205736:	fef9e8e3          	bltu	s3,a5,ffffffffc0205726 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) {
ffffffffc020573a:	4701                	li	a4,0
ffffffffc020573c:	46ad                	li	a3,11
ffffffffc020573e:	00100637          	lui	a2,0x100
ffffffffc0205742:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0205746:	8526                	mv	a0,s1
ffffffffc0205748:	b13fe0ef          	jal	ra,ffffffffc020425a <mm_map>
ffffffffc020574c:	892a                	mv	s2,a0
ffffffffc020574e:	1e051063          	bnez	a0,ffffffffc020592e <do_execve+0x33e>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
ffffffffc0205752:	6c88                	ld	a0,24(s1)
ffffffffc0205754:	467d                	li	a2,31
ffffffffc0205756:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc020575a:	bcffd0ef          	jal	ra,ffffffffc0203328 <pgdir_alloc_page>
ffffffffc020575e:	38050163          	beqz	a0,ffffffffc0205ae0 <do_execve+0x4f0>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
ffffffffc0205762:	6c88                	ld	a0,24(s1)
ffffffffc0205764:	467d                	li	a2,31
ffffffffc0205766:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc020576a:	bbffd0ef          	jal	ra,ffffffffc0203328 <pgdir_alloc_page>
ffffffffc020576e:	34050963          	beqz	a0,ffffffffc0205ac0 <do_execve+0x4d0>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
ffffffffc0205772:	6c88                	ld	a0,24(s1)
ffffffffc0205774:	467d                	li	a2,31
ffffffffc0205776:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc020577a:	baffd0ef          	jal	ra,ffffffffc0203328 <pgdir_alloc_page>
ffffffffc020577e:	32050163          	beqz	a0,ffffffffc0205aa0 <do_execve+0x4b0>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
ffffffffc0205782:	6c88                	ld	a0,24(s1)
ffffffffc0205784:	467d                	li	a2,31
ffffffffc0205786:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc020578a:	b9ffd0ef          	jal	ra,ffffffffc0203328 <pgdir_alloc_page>
ffffffffc020578e:	2e050963          	beqz	a0,ffffffffc0205a80 <do_execve+0x490>
    mm->mm_count += 1;
ffffffffc0205792:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0205794:	000db603          	ld	a2,0(s11)
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205798:	6c94                	ld	a3,24(s1)
ffffffffc020579a:	2785                	addiw	a5,a5,1
ffffffffc020579c:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc020579e:	f604                	sd	s1,40(a2)
    current->cr3 = PADDR(mm->pgdir);
ffffffffc02057a0:	c02007b7          	lui	a5,0xc0200
ffffffffc02057a4:	2cf6e263          	bltu	a3,a5,ffffffffc0205a68 <do_execve+0x478>
ffffffffc02057a8:	000b3783          	ld	a5,0(s6)
ffffffffc02057ac:	577d                	li	a4,-1
ffffffffc02057ae:	177e                	slli	a4,a4,0x3f
ffffffffc02057b0:	8e9d                	sub	a3,a3,a5
ffffffffc02057b2:	00c6d793          	srli	a5,a3,0xc
ffffffffc02057b6:	f654                	sd	a3,168(a2)
ffffffffc02057b8:	8fd9                	or	a5,a5,a4
ffffffffc02057ba:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc02057be:	7244                	ld	s1,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02057c0:	4581                	li	a1,0
ffffffffc02057c2:	12000613          	li	a2,288
ffffffffc02057c6:	8526                	mv	a0,s1
ffffffffc02057c8:	48b000ef          	jal	ra,ffffffffc0206452 <memset>
    tf->epc = elf->e_entry;  // 用户程序入口
ffffffffc02057cc:	7782                	ld	a5,32(sp)
ffffffffc02057ce:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;  // 用户栈顶
ffffffffc02057d0:	4785                	li	a5,1
ffffffffc02057d2:	07fe                	slli	a5,a5,0x1f
ffffffffc02057d4:	e89c                	sd	a5,16(s1)
    tf->epc = elf->e_entry;  // 用户程序入口
ffffffffc02057d6:	10e4b423          	sd	a4,264(s1)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP & ~SSTATUS_SPIE);  // 用户态
ffffffffc02057da:	100027f3          	csrr	a5,sstatus
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02057de:	000db403          	ld	s0,0(s11)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP & ~SSTATUS_SPIE);  // 用户态
ffffffffc02057e2:	edf7f793          	andi	a5,a5,-289
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02057e6:	4641                	li	a2,16
ffffffffc02057e8:	0b440413          	addi	s0,s0,180
ffffffffc02057ec:	4581                	li	a1,0
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP & ~SSTATUS_SPIE);  // 用户态
ffffffffc02057ee:	10f4b023          	sd	a5,256(s1)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02057f2:	8522                	mv	a0,s0
ffffffffc02057f4:	45f000ef          	jal	ra,ffffffffc0206452 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02057f8:	463d                	li	a2,15
ffffffffc02057fa:	180c                	addi	a1,sp,48
ffffffffc02057fc:	8522                	mv	a0,s0
ffffffffc02057fe:	467000ef          	jal	ra,ffffffffc0206464 <memcpy>
}
ffffffffc0205802:	70aa                	ld	ra,168(sp)
ffffffffc0205804:	740a                	ld	s0,160(sp)
ffffffffc0205806:	64ea                	ld	s1,152(sp)
ffffffffc0205808:	69aa                	ld	s3,136(sp)
ffffffffc020580a:	6a0a                	ld	s4,128(sp)
ffffffffc020580c:	7ae6                	ld	s5,120(sp)
ffffffffc020580e:	7b46                	ld	s6,112(sp)
ffffffffc0205810:	7ba6                	ld	s7,104(sp)
ffffffffc0205812:	7c06                	ld	s8,96(sp)
ffffffffc0205814:	6ce6                	ld	s9,88(sp)
ffffffffc0205816:	6d46                	ld	s10,80(sp)
ffffffffc0205818:	6da6                	ld	s11,72(sp)
ffffffffc020581a:	854a                	mv	a0,s2
ffffffffc020581c:	694a                	ld	s2,144(sp)
ffffffffc020581e:	614d                	addi	sp,sp,176
ffffffffc0205820:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0205822:	463d                	li	a2,15
ffffffffc0205824:	85ca                	mv	a1,s2
ffffffffc0205826:	1808                	addi	a0,sp,48
ffffffffc0205828:	43d000ef          	jal	ra,ffffffffc0206464 <memcpy>
    if (mm != NULL) {
ffffffffc020582c:	e20993e3          	bnez	s3,ffffffffc0205652 <do_execve+0x62>
    if (current->mm != NULL) {
ffffffffc0205830:	000db783          	ld	a5,0(s11)
ffffffffc0205834:	779c                	ld	a5,40(a5)
ffffffffc0205836:	e4078ae3          	beqz	a5,ffffffffc020568a <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc020583a:	00003617          	auipc	a2,0x3
ffffffffc020583e:	bf660613          	addi	a2,a2,-1034 # ffffffffc0208430 <default_pmm_manager+0x1260>
ffffffffc0205842:	21800593          	li	a1,536
ffffffffc0205846:	00003517          	auipc	a0,0x3
ffffffffc020584a:	a0250513          	addi	a0,a0,-1534 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc020584e:	c2dfa0ef          	jal	ra,ffffffffc020047a <__panic>
    put_pgdir(mm);
ffffffffc0205852:	8526                	mv	a0,s1
ffffffffc0205854:	c22ff0ef          	jal	ra,ffffffffc0204c76 <put_pgdir>
    mm_destroy(mm);
ffffffffc0205858:	8526                	mv	a0,s1
ffffffffc020585a:	9affe0ef          	jal	ra,ffffffffc0204208 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc020585e:	5961                	li	s2,-8
    do_exit(ret);
ffffffffc0205860:	854a                	mv	a0,s2
ffffffffc0205862:	94fff0ef          	jal	ra,ffffffffc02051b0 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0205866:	5971                	li	s2,-4
ffffffffc0205868:	bfe5                	j	ffffffffc0205860 <do_execve+0x270>
        if (ph->p_filesz > ph->p_memsz) {
ffffffffc020586a:	0289b603          	ld	a2,40(s3)
ffffffffc020586e:	0209b783          	ld	a5,32(s3)
ffffffffc0205872:	1cf66d63          	bltu	a2,a5,ffffffffc0205a4c <do_execve+0x45c>
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
ffffffffc0205876:	0049a783          	lw	a5,4(s3)
ffffffffc020587a:	0017f693          	andi	a3,a5,1
ffffffffc020587e:	c291                	beqz	a3,ffffffffc0205882 <do_execve+0x292>
ffffffffc0205880:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205882:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205886:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205888:	e779                	bnez	a4,ffffffffc0205956 <do_execve+0x366>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc020588a:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc020588c:	c781                	beqz	a5,ffffffffc0205894 <do_execve+0x2a4>
ffffffffc020588e:	0016e693          	ori	a3,a3,1
        if (vm_flags & VM_READ) perm |= PTE_R;
ffffffffc0205892:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc0205894:	0026f793          	andi	a5,a3,2
ffffffffc0205898:	e3f1                	bnez	a5,ffffffffc020595c <do_execve+0x36c>
        if (vm_flags & VM_EXEC) perm |= PTE_X;
ffffffffc020589a:	0046f793          	andi	a5,a3,4
ffffffffc020589e:	c399                	beqz	a5,ffffffffc02058a4 <do_execve+0x2b4>
ffffffffc02058a0:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) {
ffffffffc02058a4:	0109b583          	ld	a1,16(s3)
ffffffffc02058a8:	4701                	li	a4,0
ffffffffc02058aa:	8526                	mv	a0,s1
ffffffffc02058ac:	9affe0ef          	jal	ra,ffffffffc020425a <mm_map>
ffffffffc02058b0:	892a                	mv	s2,a0
ffffffffc02058b2:	ed35                	bnez	a0,ffffffffc020592e <do_execve+0x33e>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc02058b4:	0109bb83          	ld	s7,16(s3)
ffffffffc02058b8:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc02058ba:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc02058be:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc02058c2:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc02058c6:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc02058c8:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc02058ca:	993e                	add	s2,s2,a5
        while (start < end) {
ffffffffc02058cc:	054be963          	bltu	s7,s4,ffffffffc020591e <do_execve+0x32e>
ffffffffc02058d0:	aa95                	j	ffffffffc0205a44 <do_execve+0x454>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc02058d2:	6785                	lui	a5,0x1
ffffffffc02058d4:	415b8533          	sub	a0,s7,s5
ffffffffc02058d8:	9abe                	add	s5,s5,a5
ffffffffc02058da:	417a8633          	sub	a2,s5,s7
            if (end < la) {
ffffffffc02058de:	015a7463          	bgeu	s4,s5,ffffffffc02058e6 <do_execve+0x2f6>
                size -= la - end;
ffffffffc02058e2:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc02058e6:	000cb683          	ld	a3,0(s9)
ffffffffc02058ea:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc02058ec:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc02058f0:	40d406b3          	sub	a3,s0,a3
ffffffffc02058f4:	8699                	srai	a3,a3,0x6
ffffffffc02058f6:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02058f8:	67e2                	ld	a5,24(sp)
ffffffffc02058fa:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc02058fe:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205900:	14b87863          	bgeu	a6,a1,ffffffffc0205a50 <do_execve+0x460>
ffffffffc0205904:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205908:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc020590a:	9bb2                	add	s7,s7,a2
ffffffffc020590c:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc020590e:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0205910:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205912:	353000ef          	jal	ra,ffffffffc0206464 <memcpy>
            start += size, from += size;
ffffffffc0205916:	6622                	ld	a2,8(sp)
ffffffffc0205918:	9932                	add	s2,s2,a2
        while (start < end) {
ffffffffc020591a:	054bf363          	bgeu	s7,s4,ffffffffc0205960 <do_execve+0x370>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc020591e:	6c88                	ld	a0,24(s1)
ffffffffc0205920:	866a                	mv	a2,s10
ffffffffc0205922:	85d6                	mv	a1,s5
ffffffffc0205924:	a05fd0ef          	jal	ra,ffffffffc0203328 <pgdir_alloc_page>
ffffffffc0205928:	842a                	mv	s0,a0
ffffffffc020592a:	f545                	bnez	a0,ffffffffc02058d2 <do_execve+0x2e2>
        ret = -E_NO_MEM;
ffffffffc020592c:	5971                	li	s2,-4
    exit_mmap(mm);
ffffffffc020592e:	8526                	mv	a0,s1
ffffffffc0205930:	a75fe0ef          	jal	ra,ffffffffc02043a4 <exit_mmap>
    put_pgdir(mm);
ffffffffc0205934:	8526                	mv	a0,s1
ffffffffc0205936:	b40ff0ef          	jal	ra,ffffffffc0204c76 <put_pgdir>
    mm_destroy(mm);
ffffffffc020593a:	8526                	mv	a0,s1
ffffffffc020593c:	8cdfe0ef          	jal	ra,ffffffffc0204208 <mm_destroy>
    return ret;
ffffffffc0205940:	b705                	j	ffffffffc0205860 <do_execve+0x270>
            exit_mmap(mm);
ffffffffc0205942:	854e                	mv	a0,s3
ffffffffc0205944:	a61fe0ef          	jal	ra,ffffffffc02043a4 <exit_mmap>
            put_pgdir(mm);
ffffffffc0205948:	854e                	mv	a0,s3
ffffffffc020594a:	b2cff0ef          	jal	ra,ffffffffc0204c76 <put_pgdir>
            mm_destroy(mm);
ffffffffc020594e:	854e                	mv	a0,s3
ffffffffc0205950:	8b9fe0ef          	jal	ra,ffffffffc0204208 <mm_destroy>
ffffffffc0205954:	b33d                	j	ffffffffc0205682 <do_execve+0x92>
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205956:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc020595a:	fb95                	bnez	a5,ffffffffc020588e <do_execve+0x29e>
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc020595c:	4d5d                	li	s10,23
ffffffffc020595e:	bf35                	j	ffffffffc020589a <do_execve+0x2aa>
        end = ph->p_va + ph->p_memsz;
ffffffffc0205960:	0109b683          	ld	a3,16(s3)
ffffffffc0205964:	0289b903          	ld	s2,40(s3)
ffffffffc0205968:	9936                	add	s2,s2,a3
        if (start < la) {
ffffffffc020596a:	075bfd63          	bgeu	s7,s5,ffffffffc02059e4 <do_execve+0x3f4>
            if (start == end) {
ffffffffc020596e:	dd7901e3          	beq	s2,s7,ffffffffc0205730 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205972:	6785                	lui	a5,0x1
ffffffffc0205974:	00fb8533          	add	a0,s7,a5
ffffffffc0205978:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc020597c:	41790a33          	sub	s4,s2,s7
            if (end < la) {
ffffffffc0205980:	0b597d63          	bgeu	s2,s5,ffffffffc0205a3a <do_execve+0x44a>
    return page - pages + nbase;
ffffffffc0205984:	000cb683          	ld	a3,0(s9)
ffffffffc0205988:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc020598a:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc020598e:	40d406b3          	sub	a3,s0,a3
ffffffffc0205992:	8699                	srai	a3,a3,0x6
ffffffffc0205994:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205996:	67e2                	ld	a5,24(sp)
ffffffffc0205998:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc020599c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020599e:	0ac5f963          	bgeu	a1,a2,ffffffffc0205a50 <do_execve+0x460>
ffffffffc02059a2:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc02059a6:	8652                	mv	a2,s4
ffffffffc02059a8:	4581                	li	a1,0
ffffffffc02059aa:	96c2                	add	a3,a3,a6
ffffffffc02059ac:	9536                	add	a0,a0,a3
ffffffffc02059ae:	2a5000ef          	jal	ra,ffffffffc0206452 <memset>
            start += size;
ffffffffc02059b2:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc02059b6:	03597463          	bgeu	s2,s5,ffffffffc02059de <do_execve+0x3ee>
ffffffffc02059ba:	d6e90be3          	beq	s2,a4,ffffffffc0205730 <do_execve+0x140>
ffffffffc02059be:	00003697          	auipc	a3,0x3
ffffffffc02059c2:	a9a68693          	addi	a3,a3,-1382 # ffffffffc0208458 <default_pmm_manager+0x1288>
ffffffffc02059c6:	00001617          	auipc	a2,0x1
ffffffffc02059ca:	17260613          	addi	a2,a2,370 # ffffffffc0206b38 <commands+0x450>
ffffffffc02059ce:	26d00593          	li	a1,621
ffffffffc02059d2:	00003517          	auipc	a0,0x3
ffffffffc02059d6:	87650513          	addi	a0,a0,-1930 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc02059da:	aa1fa0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc02059de:	ff5710e3          	bne	a4,s5,ffffffffc02059be <do_execve+0x3ce>
ffffffffc02059e2:	8bd6                	mv	s7,s5
        while (start < end) {
ffffffffc02059e4:	d52bf6e3          	bgeu	s7,s2,ffffffffc0205730 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc02059e8:	6c88                	ld	a0,24(s1)
ffffffffc02059ea:	866a                	mv	a2,s10
ffffffffc02059ec:	85d6                	mv	a1,s5
ffffffffc02059ee:	93bfd0ef          	jal	ra,ffffffffc0203328 <pgdir_alloc_page>
ffffffffc02059f2:	842a                	mv	s0,a0
ffffffffc02059f4:	dd05                	beqz	a0,ffffffffc020592c <do_execve+0x33c>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc02059f6:	6785                	lui	a5,0x1
ffffffffc02059f8:	415b8533          	sub	a0,s7,s5
ffffffffc02059fc:	9abe                	add	s5,s5,a5
ffffffffc02059fe:	417a8633          	sub	a2,s5,s7
            if (end < la) {
ffffffffc0205a02:	01597463          	bgeu	s2,s5,ffffffffc0205a0a <do_execve+0x41a>
                size -= la - end;
ffffffffc0205a06:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0205a0a:	000cb683          	ld	a3,0(s9)
ffffffffc0205a0e:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205a10:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0205a14:	40d406b3          	sub	a3,s0,a3
ffffffffc0205a18:	8699                	srai	a3,a3,0x6
ffffffffc0205a1a:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205a1c:	67e2                	ld	a5,24(sp)
ffffffffc0205a1e:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205a22:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205a24:	02b87663          	bgeu	a6,a1,ffffffffc0205a50 <do_execve+0x460>
ffffffffc0205a28:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205a2c:	4581                	li	a1,0
            start += size;
ffffffffc0205a2e:	9bb2                	add	s7,s7,a2
ffffffffc0205a30:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0205a32:	9536                	add	a0,a0,a3
ffffffffc0205a34:	21f000ef          	jal	ra,ffffffffc0206452 <memset>
ffffffffc0205a38:	b775                	j	ffffffffc02059e4 <do_execve+0x3f4>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205a3a:	417a8a33          	sub	s4,s5,s7
ffffffffc0205a3e:	b799                	j	ffffffffc0205984 <do_execve+0x394>
        return -E_INVAL;
ffffffffc0205a40:	5975                	li	s2,-3
ffffffffc0205a42:	b3c1                	j	ffffffffc0205802 <do_execve+0x212>
        while (start < end) {
ffffffffc0205a44:	86de                	mv	a3,s7
ffffffffc0205a46:	bf39                	j	ffffffffc0205964 <do_execve+0x374>
    int ret = -E_NO_MEM;
ffffffffc0205a48:	5971                	li	s2,-4
ffffffffc0205a4a:	bdc5                	j	ffffffffc020593a <do_execve+0x34a>
            ret = -E_INVAL_ELF;
ffffffffc0205a4c:	5961                	li	s2,-8
ffffffffc0205a4e:	b5c5                	j	ffffffffc020592e <do_execve+0x33e>
ffffffffc0205a50:	00001617          	auipc	a2,0x1
ffffffffc0205a54:	7b860613          	addi	a2,a2,1976 # ffffffffc0207208 <default_pmm_manager+0x38>
ffffffffc0205a58:	06900593          	li	a1,105
ffffffffc0205a5c:	00001517          	auipc	a0,0x1
ffffffffc0205a60:	7d450513          	addi	a0,a0,2004 # ffffffffc0207230 <default_pmm_manager+0x60>
ffffffffc0205a64:	a17fa0ef          	jal	ra,ffffffffc020047a <__panic>
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205a68:	00002617          	auipc	a2,0x2
ffffffffc0205a6c:	84860613          	addi	a2,a2,-1976 # ffffffffc02072b0 <default_pmm_manager+0xe0>
ffffffffc0205a70:	28800593          	li	a1,648
ffffffffc0205a74:	00002517          	auipc	a0,0x2
ffffffffc0205a78:	7d450513          	addi	a0,a0,2004 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc0205a7c:	9fffa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
ffffffffc0205a80:	00003697          	auipc	a3,0x3
ffffffffc0205a84:	af068693          	addi	a3,a3,-1296 # ffffffffc0208570 <default_pmm_manager+0x13a0>
ffffffffc0205a88:	00001617          	auipc	a2,0x1
ffffffffc0205a8c:	0b060613          	addi	a2,a2,176 # ffffffffc0206b38 <commands+0x450>
ffffffffc0205a90:	28300593          	li	a1,643
ffffffffc0205a94:	00002517          	auipc	a0,0x2
ffffffffc0205a98:	7b450513          	addi	a0,a0,1972 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc0205a9c:	9dffa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
ffffffffc0205aa0:	00003697          	auipc	a3,0x3
ffffffffc0205aa4:	a8868693          	addi	a3,a3,-1400 # ffffffffc0208528 <default_pmm_manager+0x1358>
ffffffffc0205aa8:	00001617          	auipc	a2,0x1
ffffffffc0205aac:	09060613          	addi	a2,a2,144 # ffffffffc0206b38 <commands+0x450>
ffffffffc0205ab0:	28200593          	li	a1,642
ffffffffc0205ab4:	00002517          	auipc	a0,0x2
ffffffffc0205ab8:	79450513          	addi	a0,a0,1940 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc0205abc:	9bffa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
ffffffffc0205ac0:	00003697          	auipc	a3,0x3
ffffffffc0205ac4:	a2068693          	addi	a3,a3,-1504 # ffffffffc02084e0 <default_pmm_manager+0x1310>
ffffffffc0205ac8:	00001617          	auipc	a2,0x1
ffffffffc0205acc:	07060613          	addi	a2,a2,112 # ffffffffc0206b38 <commands+0x450>
ffffffffc0205ad0:	28100593          	li	a1,641
ffffffffc0205ad4:	00002517          	auipc	a0,0x2
ffffffffc0205ad8:	77450513          	addi	a0,a0,1908 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc0205adc:	99ffa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
ffffffffc0205ae0:	00003697          	auipc	a3,0x3
ffffffffc0205ae4:	9b868693          	addi	a3,a3,-1608 # ffffffffc0208498 <default_pmm_manager+0x12c8>
ffffffffc0205ae8:	00001617          	auipc	a2,0x1
ffffffffc0205aec:	05060613          	addi	a2,a2,80 # ffffffffc0206b38 <commands+0x450>
ffffffffc0205af0:	28000593          	li	a1,640
ffffffffc0205af4:	00002517          	auipc	a0,0x2
ffffffffc0205af8:	75450513          	addi	a0,a0,1876 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc0205afc:	97ffa0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0205b00 <do_yield>:
    current->need_resched = 1;
ffffffffc0205b00:	000ad797          	auipc	a5,0xad
ffffffffc0205b04:	e187b783          	ld	a5,-488(a5) # ffffffffc02b2918 <current>
ffffffffc0205b08:	4705                	li	a4,1
ffffffffc0205b0a:	ef98                	sd	a4,24(a5)
}
ffffffffc0205b0c:	4501                	li	a0,0
ffffffffc0205b0e:	8082                	ret

ffffffffc0205b10 <do_wait>:
do_wait(int pid, int *code_store) {
ffffffffc0205b10:	1101                	addi	sp,sp,-32
ffffffffc0205b12:	e822                	sd	s0,16(sp)
ffffffffc0205b14:	e426                	sd	s1,8(sp)
ffffffffc0205b16:	ec06                	sd	ra,24(sp)
ffffffffc0205b18:	842e                	mv	s0,a1
ffffffffc0205b1a:	84aa                	mv	s1,a0
    if (code_store != NULL) {
ffffffffc0205b1c:	c999                	beqz	a1,ffffffffc0205b32 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0205b1e:	000ad797          	auipc	a5,0xad
ffffffffc0205b22:	dfa7b783          	ld	a5,-518(a5) # ffffffffc02b2918 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1)) {
ffffffffc0205b26:	7788                	ld	a0,40(a5)
ffffffffc0205b28:	4685                	li	a3,1
ffffffffc0205b2a:	4611                	li	a2,4
ffffffffc0205b2c:	eebfe0ef          	jal	ra,ffffffffc0204a16 <user_mem_check>
ffffffffc0205b30:	c909                	beqz	a0,ffffffffc0205b42 <do_wait+0x32>
ffffffffc0205b32:	85a2                	mv	a1,s0
}
ffffffffc0205b34:	6442                	ld	s0,16(sp)
ffffffffc0205b36:	60e2                	ld	ra,24(sp)
ffffffffc0205b38:	8526                	mv	a0,s1
ffffffffc0205b3a:	64a2                	ld	s1,8(sp)
ffffffffc0205b3c:	6105                	addi	sp,sp,32
ffffffffc0205b3e:	fbcff06f          	j	ffffffffc02052fa <do_wait.part.0>
ffffffffc0205b42:	60e2                	ld	ra,24(sp)
ffffffffc0205b44:	6442                	ld	s0,16(sp)
ffffffffc0205b46:	64a2                	ld	s1,8(sp)
ffffffffc0205b48:	5575                	li	a0,-3
ffffffffc0205b4a:	6105                	addi	sp,sp,32
ffffffffc0205b4c:	8082                	ret

ffffffffc0205b4e <do_kill>:
do_kill(int pid) {
ffffffffc0205b4e:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205b50:	6789                	lui	a5,0x2
do_kill(int pid) {
ffffffffc0205b52:	e406                	sd	ra,8(sp)
ffffffffc0205b54:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205b56:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205b5a:	17f9                	addi	a5,a5,-2
ffffffffc0205b5c:	02e7e963          	bltu	a5,a4,ffffffffc0205b8e <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205b60:	842a                	mv	s0,a0
ffffffffc0205b62:	45a9                	li	a1,10
ffffffffc0205b64:	2501                	sext.w	a0,a0
ffffffffc0205b66:	46c000ef          	jal	ra,ffffffffc0205fd2 <hash32>
ffffffffc0205b6a:	02051793          	slli	a5,a0,0x20
ffffffffc0205b6e:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0205b72:	000a9797          	auipc	a5,0xa9
ffffffffc0205b76:	d1e78793          	addi	a5,a5,-738 # ffffffffc02ae890 <hash_list>
ffffffffc0205b7a:	953e                	add	a0,a0,a5
ffffffffc0205b7c:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list) {
ffffffffc0205b7e:	a029                	j	ffffffffc0205b88 <do_kill+0x3a>
            if (proc->pid == pid) {
ffffffffc0205b80:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0205b84:	00870b63          	beq	a4,s0,ffffffffc0205b9a <do_kill+0x4c>
ffffffffc0205b88:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0205b8a:	fef51be3          	bne	a0,a5,ffffffffc0205b80 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0205b8e:	5475                	li	s0,-3
}
ffffffffc0205b90:	60a2                	ld	ra,8(sp)
ffffffffc0205b92:	8522                	mv	a0,s0
ffffffffc0205b94:	6402                	ld	s0,0(sp)
ffffffffc0205b96:	0141                	addi	sp,sp,16
ffffffffc0205b98:	8082                	ret
        if (!(proc->flags & PF_EXITING)) {
ffffffffc0205b9a:	fd87a703          	lw	a4,-40(a5)
ffffffffc0205b9e:	00177693          	andi	a3,a4,1
ffffffffc0205ba2:	e295                	bnez	a3,ffffffffc0205bc6 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205ba4:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0205ba6:	00176713          	ori	a4,a4,1
ffffffffc0205baa:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0205bae:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205bb0:	fe06d0e3          	bgez	a3,ffffffffc0205b90 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0205bb4:	f2878513          	addi	a0,a5,-216
ffffffffc0205bb8:	22e000ef          	jal	ra,ffffffffc0205de6 <wakeup_proc>
}
ffffffffc0205bbc:	60a2                	ld	ra,8(sp)
ffffffffc0205bbe:	8522                	mv	a0,s0
ffffffffc0205bc0:	6402                	ld	s0,0(sp)
ffffffffc0205bc2:	0141                	addi	sp,sp,16
ffffffffc0205bc4:	8082                	ret
        return -E_KILLED;
ffffffffc0205bc6:	545d                	li	s0,-9
ffffffffc0205bc8:	b7e1                	j	ffffffffc0205b90 <do_kill+0x42>

ffffffffc0205bca <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
void
proc_init(void) {
ffffffffc0205bca:	1101                	addi	sp,sp,-32
ffffffffc0205bcc:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0205bce:	000ad797          	auipc	a5,0xad
ffffffffc0205bd2:	cc278793          	addi	a5,a5,-830 # ffffffffc02b2890 <proc_list>
ffffffffc0205bd6:	ec06                	sd	ra,24(sp)
ffffffffc0205bd8:	e822                	sd	s0,16(sp)
ffffffffc0205bda:	e04a                	sd	s2,0(sp)
ffffffffc0205bdc:	000a9497          	auipc	s1,0xa9
ffffffffc0205be0:	cb448493          	addi	s1,s1,-844 # ffffffffc02ae890 <hash_list>
ffffffffc0205be4:	e79c                	sd	a5,8(a5)
ffffffffc0205be6:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
ffffffffc0205be8:	000ad717          	auipc	a4,0xad
ffffffffc0205bec:	ca870713          	addi	a4,a4,-856 # ffffffffc02b2890 <proc_list>
ffffffffc0205bf0:	87a6                	mv	a5,s1
ffffffffc0205bf2:	e79c                	sd	a5,8(a5)
ffffffffc0205bf4:	e39c                	sd	a5,0(a5)
ffffffffc0205bf6:	07c1                	addi	a5,a5,16
ffffffffc0205bf8:	fef71de3          	bne	a4,a5,ffffffffc0205bf2 <proc_init+0x28>
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL) {
ffffffffc0205bfc:	f7dfe0ef          	jal	ra,ffffffffc0204b78 <alloc_proc>
ffffffffc0205c00:	000ad917          	auipc	s2,0xad
ffffffffc0205c04:	d2090913          	addi	s2,s2,-736 # ffffffffc02b2920 <idleproc>
ffffffffc0205c08:	00a93023          	sd	a0,0(s2)
ffffffffc0205c0c:	0e050f63          	beqz	a0,ffffffffc0205d0a <proc_init+0x140>
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0205c10:	4789                	li	a5,2
ffffffffc0205c12:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205c14:	00003797          	auipc	a5,0x3
ffffffffc0205c18:	3ec78793          	addi	a5,a5,1004 # ffffffffc0209000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205c1c:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205c20:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0205c22:	4785                	li	a5,1
ffffffffc0205c24:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205c26:	4641                	li	a2,16
ffffffffc0205c28:	4581                	li	a1,0
ffffffffc0205c2a:	8522                	mv	a0,s0
ffffffffc0205c2c:	027000ef          	jal	ra,ffffffffc0206452 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205c30:	463d                	li	a2,15
ffffffffc0205c32:	00003597          	auipc	a1,0x3
ffffffffc0205c36:	99e58593          	addi	a1,a1,-1634 # ffffffffc02085d0 <default_pmm_manager+0x1400>
ffffffffc0205c3a:	8522                	mv	a0,s0
ffffffffc0205c3c:	029000ef          	jal	ra,ffffffffc0206464 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process ++;
ffffffffc0205c40:	000ad717          	auipc	a4,0xad
ffffffffc0205c44:	cf070713          	addi	a4,a4,-784 # ffffffffc02b2930 <nr_process>
ffffffffc0205c48:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0205c4a:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205c4e:	4601                	li	a2,0
    nr_process ++;
ffffffffc0205c50:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205c52:	4581                	li	a1,0
ffffffffc0205c54:	00000517          	auipc	a0,0x0
ffffffffc0205c58:	87850513          	addi	a0,a0,-1928 # ffffffffc02054cc <init_main>
    nr_process ++;
ffffffffc0205c5c:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0205c5e:	000ad797          	auipc	a5,0xad
ffffffffc0205c62:	cad7bd23          	sd	a3,-838(a5) # ffffffffc02b2918 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205c66:	cfaff0ef          	jal	ra,ffffffffc0205160 <kernel_thread>
ffffffffc0205c6a:	842a                	mv	s0,a0
    if (pid <= 0) {
ffffffffc0205c6c:	08a05363          	blez	a0,ffffffffc0205cf2 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205c70:	6789                	lui	a5,0x2
ffffffffc0205c72:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205c76:	17f9                	addi	a5,a5,-2
ffffffffc0205c78:	2501                	sext.w	a0,a0
ffffffffc0205c7a:	02e7e363          	bltu	a5,a4,ffffffffc0205ca0 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205c7e:	45a9                	li	a1,10
ffffffffc0205c80:	352000ef          	jal	ra,ffffffffc0205fd2 <hash32>
ffffffffc0205c84:	02051793          	slli	a5,a0,0x20
ffffffffc0205c88:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0205c8c:	96a6                	add	a3,a3,s1
ffffffffc0205c8e:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list) {
ffffffffc0205c90:	a029                	j	ffffffffc0205c9a <proc_init+0xd0>
            if (proc->pid == pid) {
ffffffffc0205c92:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c8c>
ffffffffc0205c96:	04870b63          	beq	a4,s0,ffffffffc0205cec <proc_init+0x122>
    return listelm->next;
ffffffffc0205c9a:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0205c9c:	fef69be3          	bne	a3,a5,ffffffffc0205c92 <proc_init+0xc8>
    return NULL;
ffffffffc0205ca0:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205ca2:	0b478493          	addi	s1,a5,180
ffffffffc0205ca6:	4641                	li	a2,16
ffffffffc0205ca8:	4581                	li	a1,0
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0205caa:	000ad417          	auipc	s0,0xad
ffffffffc0205cae:	c7e40413          	addi	s0,s0,-898 # ffffffffc02b2928 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205cb2:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0205cb4:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205cb6:	79c000ef          	jal	ra,ffffffffc0206452 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205cba:	463d                	li	a2,15
ffffffffc0205cbc:	00003597          	auipc	a1,0x3
ffffffffc0205cc0:	93c58593          	addi	a1,a1,-1732 # ffffffffc02085f8 <default_pmm_manager+0x1428>
ffffffffc0205cc4:	8526                	mv	a0,s1
ffffffffc0205cc6:	79e000ef          	jal	ra,ffffffffc0206464 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205cca:	00093783          	ld	a5,0(s2)
ffffffffc0205cce:	cbb5                	beqz	a5,ffffffffc0205d42 <proc_init+0x178>
ffffffffc0205cd0:	43dc                	lw	a5,4(a5)
ffffffffc0205cd2:	eba5                	bnez	a5,ffffffffc0205d42 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205cd4:	601c                	ld	a5,0(s0)
ffffffffc0205cd6:	c7b1                	beqz	a5,ffffffffc0205d22 <proc_init+0x158>
ffffffffc0205cd8:	43d8                	lw	a4,4(a5)
ffffffffc0205cda:	4785                	li	a5,1
ffffffffc0205cdc:	04f71363          	bne	a4,a5,ffffffffc0205d22 <proc_init+0x158>
}
ffffffffc0205ce0:	60e2                	ld	ra,24(sp)
ffffffffc0205ce2:	6442                	ld	s0,16(sp)
ffffffffc0205ce4:	64a2                	ld	s1,8(sp)
ffffffffc0205ce6:	6902                	ld	s2,0(sp)
ffffffffc0205ce8:	6105                	addi	sp,sp,32
ffffffffc0205cea:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205cec:	f2878793          	addi	a5,a5,-216
ffffffffc0205cf0:	bf4d                	j	ffffffffc0205ca2 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0205cf2:	00003617          	auipc	a2,0x3
ffffffffc0205cf6:	8e660613          	addi	a2,a2,-1818 # ffffffffc02085d8 <default_pmm_manager+0x1408>
ffffffffc0205cfa:	38d00593          	li	a1,909
ffffffffc0205cfe:	00002517          	auipc	a0,0x2
ffffffffc0205d02:	54a50513          	addi	a0,a0,1354 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc0205d06:	f74fa0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205d0a:	00003617          	auipc	a2,0x3
ffffffffc0205d0e:	8ae60613          	addi	a2,a2,-1874 # ffffffffc02085b8 <default_pmm_manager+0x13e8>
ffffffffc0205d12:	37f00593          	li	a1,895
ffffffffc0205d16:	00002517          	auipc	a0,0x2
ffffffffc0205d1a:	53250513          	addi	a0,a0,1330 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc0205d1e:	f5cfa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205d22:	00003697          	auipc	a3,0x3
ffffffffc0205d26:	90668693          	addi	a3,a3,-1786 # ffffffffc0208628 <default_pmm_manager+0x1458>
ffffffffc0205d2a:	00001617          	auipc	a2,0x1
ffffffffc0205d2e:	e0e60613          	addi	a2,a2,-498 # ffffffffc0206b38 <commands+0x450>
ffffffffc0205d32:	39400593          	li	a1,916
ffffffffc0205d36:	00002517          	auipc	a0,0x2
ffffffffc0205d3a:	51250513          	addi	a0,a0,1298 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc0205d3e:	f3cfa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205d42:	00003697          	auipc	a3,0x3
ffffffffc0205d46:	8be68693          	addi	a3,a3,-1858 # ffffffffc0208600 <default_pmm_manager+0x1430>
ffffffffc0205d4a:	00001617          	auipc	a2,0x1
ffffffffc0205d4e:	dee60613          	addi	a2,a2,-530 # ffffffffc0206b38 <commands+0x450>
ffffffffc0205d52:	39300593          	li	a1,915
ffffffffc0205d56:	00002517          	auipc	a0,0x2
ffffffffc0205d5a:	4f250513          	addi	a0,a0,1266 # ffffffffc0208248 <default_pmm_manager+0x1078>
ffffffffc0205d5e:	f1cfa0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0205d62 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
ffffffffc0205d62:	1141                	addi	sp,sp,-16
ffffffffc0205d64:	e022                	sd	s0,0(sp)
ffffffffc0205d66:	e406                	sd	ra,8(sp)
ffffffffc0205d68:	000ad417          	auipc	s0,0xad
ffffffffc0205d6c:	bb040413          	addi	s0,s0,-1104 # ffffffffc02b2918 <current>
    while (1) {
        if (current->need_resched) {
ffffffffc0205d70:	6018                	ld	a4,0(s0)
ffffffffc0205d72:	6f1c                	ld	a5,24(a4)
ffffffffc0205d74:	dffd                	beqz	a5,ffffffffc0205d72 <cpu_idle+0x10>
            schedule();
ffffffffc0205d76:	0f0000ef          	jal	ra,ffffffffc0205e66 <schedule>
ffffffffc0205d7a:	bfdd                	j	ffffffffc0205d70 <cpu_idle+0xe>

ffffffffc0205d7c <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205d7c:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205d80:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0205d84:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0205d86:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0205d88:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205d8c:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205d90:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0205d94:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0205d98:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205d9c:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205da0:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0205da4:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0205da8:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205dac:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205db0:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0205db4:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0205db8:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205dba:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205dbc:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205dc0:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0205dc4:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0205dc8:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205dcc:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205dd0:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0205dd4:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0205dd8:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205ddc:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205de0:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0205de4:	8082                	ret

ffffffffc0205de6 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205de6:	4118                	lw	a4,0(a0)
wakeup_proc(struct proc_struct *proc) {
ffffffffc0205de8:	1101                	addi	sp,sp,-32
ffffffffc0205dea:	ec06                	sd	ra,24(sp)
ffffffffc0205dec:	e822                	sd	s0,16(sp)
ffffffffc0205dee:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205df0:	478d                	li	a5,3
ffffffffc0205df2:	04f70b63          	beq	a4,a5,ffffffffc0205e48 <wakeup_proc+0x62>
ffffffffc0205df6:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205df8:	100027f3          	csrr	a5,sstatus
ffffffffc0205dfc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205dfe:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205e00:	ef9d                	bnez	a5,ffffffffc0205e3e <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE) {
ffffffffc0205e02:	4789                	li	a5,2
ffffffffc0205e04:	02f70163          	beq	a4,a5,ffffffffc0205e26 <wakeup_proc+0x40>
            proc->state = PROC_RUNNABLE;
ffffffffc0205e08:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0205e0a:	0e042623          	sw	zero,236(s0)
    if (flag) {
ffffffffc0205e0e:	e491                	bnez	s1,ffffffffc0205e1a <wakeup_proc+0x34>
        else {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205e10:	60e2                	ld	ra,24(sp)
ffffffffc0205e12:	6442                	ld	s0,16(sp)
ffffffffc0205e14:	64a2                	ld	s1,8(sp)
ffffffffc0205e16:	6105                	addi	sp,sp,32
ffffffffc0205e18:	8082                	ret
ffffffffc0205e1a:	6442                	ld	s0,16(sp)
ffffffffc0205e1c:	60e2                	ld	ra,24(sp)
ffffffffc0205e1e:	64a2                	ld	s1,8(sp)
ffffffffc0205e20:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205e22:	ffafa06f          	j	ffffffffc020061c <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205e26:	00003617          	auipc	a2,0x3
ffffffffc0205e2a:	86260613          	addi	a2,a2,-1950 # ffffffffc0208688 <default_pmm_manager+0x14b8>
ffffffffc0205e2e:	45c9                	li	a1,18
ffffffffc0205e30:	00003517          	auipc	a0,0x3
ffffffffc0205e34:	84050513          	addi	a0,a0,-1984 # ffffffffc0208670 <default_pmm_manager+0x14a0>
ffffffffc0205e38:	eaafa0ef          	jal	ra,ffffffffc02004e2 <__warn>
ffffffffc0205e3c:	bfc9                	j	ffffffffc0205e0e <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205e3e:	fe4fa0ef          	jal	ra,ffffffffc0200622 <intr_disable>
        if (proc->state != PROC_RUNNABLE) {
ffffffffc0205e42:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc0205e44:	4485                	li	s1,1
ffffffffc0205e46:	bf75                	j	ffffffffc0205e02 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205e48:	00003697          	auipc	a3,0x3
ffffffffc0205e4c:	80868693          	addi	a3,a3,-2040 # ffffffffc0208650 <default_pmm_manager+0x1480>
ffffffffc0205e50:	00001617          	auipc	a2,0x1
ffffffffc0205e54:	ce860613          	addi	a2,a2,-792 # ffffffffc0206b38 <commands+0x450>
ffffffffc0205e58:	45a5                	li	a1,9
ffffffffc0205e5a:	00003517          	auipc	a0,0x3
ffffffffc0205e5e:	81650513          	addi	a0,a0,-2026 # ffffffffc0208670 <default_pmm_manager+0x14a0>
ffffffffc0205e62:	e18fa0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0205e66 <schedule>:

void
schedule(void) {
ffffffffc0205e66:	1141                	addi	sp,sp,-16
ffffffffc0205e68:	e406                	sd	ra,8(sp)
ffffffffc0205e6a:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205e6c:	100027f3          	csrr	a5,sstatus
ffffffffc0205e70:	8b89                	andi	a5,a5,2
ffffffffc0205e72:	4401                	li	s0,0
ffffffffc0205e74:	efbd                	bnez	a5,ffffffffc0205ef2 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205e76:	000ad897          	auipc	a7,0xad
ffffffffc0205e7a:	aa28b883          	ld	a7,-1374(a7) # ffffffffc02b2918 <current>
ffffffffc0205e7e:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205e82:	000ad517          	auipc	a0,0xad
ffffffffc0205e86:	a9e53503          	ld	a0,-1378(a0) # ffffffffc02b2920 <idleproc>
ffffffffc0205e8a:	04a88e63          	beq	a7,a0,ffffffffc0205ee6 <schedule+0x80>
ffffffffc0205e8e:	0c888693          	addi	a3,a7,200
ffffffffc0205e92:	000ad617          	auipc	a2,0xad
ffffffffc0205e96:	9fe60613          	addi	a2,a2,-1538 # ffffffffc02b2890 <proc_list>
        le = last;
ffffffffc0205e9a:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0205e9c:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc0205e9e:	4809                	li	a6,2
ffffffffc0205ea0:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0205ea2:	00c78863          	beq	a5,a2,ffffffffc0205eb2 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0205ea6:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0205eaa:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc0205eae:	03070163          	beq	a4,a6,ffffffffc0205ed0 <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc0205eb2:	fef697e3          	bne	a3,a5,ffffffffc0205ea0 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0205eb6:	ed89                	bnez	a1,ffffffffc0205ed0 <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc0205eb8:	451c                	lw	a5,8(a0)
ffffffffc0205eba:	2785                	addiw	a5,a5,1
ffffffffc0205ebc:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc0205ebe:	00a88463          	beq	a7,a0,ffffffffc0205ec6 <schedule+0x60>
            proc_run(next);
ffffffffc0205ec2:	e2bfe0ef          	jal	ra,ffffffffc0204cec <proc_run>
    if (flag) {
ffffffffc0205ec6:	e819                	bnez	s0,ffffffffc0205edc <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205ec8:	60a2                	ld	ra,8(sp)
ffffffffc0205eca:	6402                	ld	s0,0(sp)
ffffffffc0205ecc:	0141                	addi	sp,sp,16
ffffffffc0205ece:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0205ed0:	4198                	lw	a4,0(a1)
ffffffffc0205ed2:	4789                	li	a5,2
ffffffffc0205ed4:	fef712e3          	bne	a4,a5,ffffffffc0205eb8 <schedule+0x52>
ffffffffc0205ed8:	852e                	mv	a0,a1
ffffffffc0205eda:	bff9                	j	ffffffffc0205eb8 <schedule+0x52>
}
ffffffffc0205edc:	6402                	ld	s0,0(sp)
ffffffffc0205ede:	60a2                	ld	ra,8(sp)
ffffffffc0205ee0:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0205ee2:	f3afa06f          	j	ffffffffc020061c <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205ee6:	000ad617          	auipc	a2,0xad
ffffffffc0205eea:	9aa60613          	addi	a2,a2,-1622 # ffffffffc02b2890 <proc_list>
ffffffffc0205eee:	86b2                	mv	a3,a2
ffffffffc0205ef0:	b76d                	j	ffffffffc0205e9a <schedule+0x34>
        intr_disable();
ffffffffc0205ef2:	f30fa0ef          	jal	ra,ffffffffc0200622 <intr_disable>
        return 1;
ffffffffc0205ef6:	4405                	li	s0,1
ffffffffc0205ef8:	bfbd                	j	ffffffffc0205e76 <schedule+0x10>

ffffffffc0205efa <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205efa:	000ad797          	auipc	a5,0xad
ffffffffc0205efe:	a1e7b783          	ld	a5,-1506(a5) # ffffffffc02b2918 <current>
}
ffffffffc0205f02:	43c8                	lw	a0,4(a5)
ffffffffc0205f04:	8082                	ret

ffffffffc0205f06 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205f06:	4501                	li	a0,0
ffffffffc0205f08:	8082                	ret

ffffffffc0205f0a <sys_putc>:
    cputchar(c);
ffffffffc0205f0a:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205f0c:	1141                	addi	sp,sp,-16
ffffffffc0205f0e:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205f10:	aa6fa0ef          	jal	ra,ffffffffc02001b6 <cputchar>
}
ffffffffc0205f14:	60a2                	ld	ra,8(sp)
ffffffffc0205f16:	4501                	li	a0,0
ffffffffc0205f18:	0141                	addi	sp,sp,16
ffffffffc0205f1a:	8082                	ret

ffffffffc0205f1c <sys_kill>:
    return do_kill(pid);
ffffffffc0205f1c:	4108                	lw	a0,0(a0)
ffffffffc0205f1e:	c31ff06f          	j	ffffffffc0205b4e <do_kill>

ffffffffc0205f22 <sys_yield>:
    return do_yield();
ffffffffc0205f22:	bdfff06f          	j	ffffffffc0205b00 <do_yield>

ffffffffc0205f26 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205f26:	6d14                	ld	a3,24(a0)
ffffffffc0205f28:	6910                	ld	a2,16(a0)
ffffffffc0205f2a:	650c                	ld	a1,8(a0)
ffffffffc0205f2c:	6108                	ld	a0,0(a0)
ffffffffc0205f2e:	ec2ff06f          	j	ffffffffc02055f0 <do_execve>

ffffffffc0205f32 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205f32:	650c                	ld	a1,8(a0)
ffffffffc0205f34:	4108                	lw	a0,0(a0)
ffffffffc0205f36:	bdbff06f          	j	ffffffffc0205b10 <do_wait>

ffffffffc0205f3a <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205f3a:	000ad797          	auipc	a5,0xad
ffffffffc0205f3e:	9de7b783          	ld	a5,-1570(a5) # ffffffffc02b2918 <current>
ffffffffc0205f42:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205f44:	4501                	li	a0,0
ffffffffc0205f46:	6a0c                	ld	a1,16(a2)
ffffffffc0205f48:	e11fe06f          	j	ffffffffc0204d58 <do_fork>

ffffffffc0205f4c <sys_exit>:
    return do_exit(error_code);
ffffffffc0205f4c:	4108                	lw	a0,0(a0)
ffffffffc0205f4e:	a62ff06f          	j	ffffffffc02051b0 <do_exit>

ffffffffc0205f52 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc0205f52:	715d                	addi	sp,sp,-80
ffffffffc0205f54:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205f56:	000ad497          	auipc	s1,0xad
ffffffffc0205f5a:	9c248493          	addi	s1,s1,-1598 # ffffffffc02b2918 <current>
ffffffffc0205f5e:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc0205f60:	e0a2                	sd	s0,64(sp)
ffffffffc0205f62:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205f64:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc0205f66:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205f68:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc0205f6a:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205f6e:	0327ee63          	bltu	a5,s2,ffffffffc0205faa <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc0205f72:	00391713          	slli	a4,s2,0x3
ffffffffc0205f76:	00002797          	auipc	a5,0x2
ffffffffc0205f7a:	77a78793          	addi	a5,a5,1914 # ffffffffc02086f0 <syscalls>
ffffffffc0205f7e:	97ba                	add	a5,a5,a4
ffffffffc0205f80:	639c                	ld	a5,0(a5)
ffffffffc0205f82:	c785                	beqz	a5,ffffffffc0205faa <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc0205f84:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc0205f86:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0205f88:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0205f8a:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0205f8c:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0205f8e:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0205f90:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc0205f92:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0205f94:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc0205f96:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205f98:	0028                	addi	a0,sp,8
ffffffffc0205f9a:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0205f9c:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205f9e:	e828                	sd	a0,80(s0)
}
ffffffffc0205fa0:	6406                	ld	s0,64(sp)
ffffffffc0205fa2:	74e2                	ld	s1,56(sp)
ffffffffc0205fa4:	7942                	ld	s2,48(sp)
ffffffffc0205fa6:	6161                	addi	sp,sp,80
ffffffffc0205fa8:	8082                	ret
    print_trapframe(tf);
ffffffffc0205faa:	8522                	mv	a0,s0
ffffffffc0205fac:	865fa0ef          	jal	ra,ffffffffc0200810 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205fb0:	609c                	ld	a5,0(s1)
ffffffffc0205fb2:	86ca                	mv	a3,s2
ffffffffc0205fb4:	00002617          	auipc	a2,0x2
ffffffffc0205fb8:	6f460613          	addi	a2,a2,1780 # ffffffffc02086a8 <default_pmm_manager+0x14d8>
ffffffffc0205fbc:	43d8                	lw	a4,4(a5)
ffffffffc0205fbe:	06200593          	li	a1,98
ffffffffc0205fc2:	0b478793          	addi	a5,a5,180
ffffffffc0205fc6:	00002517          	auipc	a0,0x2
ffffffffc0205fca:	71250513          	addi	a0,a0,1810 # ffffffffc02086d8 <default_pmm_manager+0x1508>
ffffffffc0205fce:	cacfa0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0205fd2 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205fd2:	9e3707b7          	lui	a5,0x9e370
ffffffffc0205fd6:	2785                	addiw	a5,a5,1
ffffffffc0205fd8:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205fdc:	02000793          	li	a5,32
ffffffffc0205fe0:	9f8d                	subw	a5,a5,a1
}
ffffffffc0205fe2:	00f5553b          	srlw	a0,a0,a5
ffffffffc0205fe6:	8082                	ret

ffffffffc0205fe8 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205fe8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205fec:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0205fee:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205ff2:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0205ff4:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205ff8:	f022                	sd	s0,32(sp)
ffffffffc0205ffa:	ec26                	sd	s1,24(sp)
ffffffffc0205ffc:	e84a                	sd	s2,16(sp)
ffffffffc0205ffe:	f406                	sd	ra,40(sp)
ffffffffc0206000:	e44e                	sd	s3,8(sp)
ffffffffc0206002:	84aa                	mv	s1,a0
ffffffffc0206004:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0206006:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020600a:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020600c:	03067e63          	bgeu	a2,a6,ffffffffc0206048 <printnum+0x60>
ffffffffc0206010:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0206012:	00805763          	blez	s0,ffffffffc0206020 <printnum+0x38>
ffffffffc0206016:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0206018:	85ca                	mv	a1,s2
ffffffffc020601a:	854e                	mv	a0,s3
ffffffffc020601c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020601e:	fc65                	bnez	s0,ffffffffc0206016 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206020:	1a02                	slli	s4,s4,0x20
ffffffffc0206022:	00002797          	auipc	a5,0x2
ffffffffc0206026:	7ce78793          	addi	a5,a5,1998 # ffffffffc02087f0 <syscalls+0x100>
ffffffffc020602a:	020a5a13          	srli	s4,s4,0x20
ffffffffc020602e:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0206030:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206032:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0206036:	70a2                	ld	ra,40(sp)
ffffffffc0206038:	69a2                	ld	s3,8(sp)
ffffffffc020603a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020603c:	85ca                	mv	a1,s2
ffffffffc020603e:	87a6                	mv	a5,s1
}
ffffffffc0206040:	6942                	ld	s2,16(sp)
ffffffffc0206042:	64e2                	ld	s1,24(sp)
ffffffffc0206044:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206046:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0206048:	03065633          	divu	a2,a2,a6
ffffffffc020604c:	8722                	mv	a4,s0
ffffffffc020604e:	f9bff0ef          	jal	ra,ffffffffc0205fe8 <printnum>
ffffffffc0206052:	b7f9                	j	ffffffffc0206020 <printnum+0x38>

ffffffffc0206054 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0206054:	7119                	addi	sp,sp,-128
ffffffffc0206056:	f4a6                	sd	s1,104(sp)
ffffffffc0206058:	f0ca                	sd	s2,96(sp)
ffffffffc020605a:	ecce                	sd	s3,88(sp)
ffffffffc020605c:	e8d2                	sd	s4,80(sp)
ffffffffc020605e:	e4d6                	sd	s5,72(sp)
ffffffffc0206060:	e0da                	sd	s6,64(sp)
ffffffffc0206062:	fc5e                	sd	s7,56(sp)
ffffffffc0206064:	f06a                	sd	s10,32(sp)
ffffffffc0206066:	fc86                	sd	ra,120(sp)
ffffffffc0206068:	f8a2                	sd	s0,112(sp)
ffffffffc020606a:	f862                	sd	s8,48(sp)
ffffffffc020606c:	f466                	sd	s9,40(sp)
ffffffffc020606e:	ec6e                	sd	s11,24(sp)
ffffffffc0206070:	892a                	mv	s2,a0
ffffffffc0206072:	84ae                	mv	s1,a1
ffffffffc0206074:	8d32                	mv	s10,a2
ffffffffc0206076:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206078:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020607c:	5b7d                	li	s6,-1
ffffffffc020607e:	00002a97          	auipc	s5,0x2
ffffffffc0206082:	79ea8a93          	addi	s5,s5,1950 # ffffffffc020881c <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0206086:	00003b97          	auipc	s7,0x3
ffffffffc020608a:	9b2b8b93          	addi	s7,s7,-1614 # ffffffffc0208a38 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020608e:	000d4503          	lbu	a0,0(s10)
ffffffffc0206092:	001d0413          	addi	s0,s10,1
ffffffffc0206096:	01350a63          	beq	a0,s3,ffffffffc02060aa <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020609a:	c121                	beqz	a0,ffffffffc02060da <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020609c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020609e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02060a0:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02060a2:	fff44503          	lbu	a0,-1(s0)
ffffffffc02060a6:	ff351ae3          	bne	a0,s3,ffffffffc020609a <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02060aa:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02060ae:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02060b2:	4c81                	li	s9,0
ffffffffc02060b4:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02060b6:	5c7d                	li	s8,-1
ffffffffc02060b8:	5dfd                	li	s11,-1
ffffffffc02060ba:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02060be:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02060c0:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02060c4:	0ff5f593          	zext.b	a1,a1
ffffffffc02060c8:	00140d13          	addi	s10,s0,1
ffffffffc02060cc:	04b56263          	bltu	a0,a1,ffffffffc0206110 <vprintfmt+0xbc>
ffffffffc02060d0:	058a                	slli	a1,a1,0x2
ffffffffc02060d2:	95d6                	add	a1,a1,s5
ffffffffc02060d4:	4194                	lw	a3,0(a1)
ffffffffc02060d6:	96d6                	add	a3,a3,s5
ffffffffc02060d8:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02060da:	70e6                	ld	ra,120(sp)
ffffffffc02060dc:	7446                	ld	s0,112(sp)
ffffffffc02060de:	74a6                	ld	s1,104(sp)
ffffffffc02060e0:	7906                	ld	s2,96(sp)
ffffffffc02060e2:	69e6                	ld	s3,88(sp)
ffffffffc02060e4:	6a46                	ld	s4,80(sp)
ffffffffc02060e6:	6aa6                	ld	s5,72(sp)
ffffffffc02060e8:	6b06                	ld	s6,64(sp)
ffffffffc02060ea:	7be2                	ld	s7,56(sp)
ffffffffc02060ec:	7c42                	ld	s8,48(sp)
ffffffffc02060ee:	7ca2                	ld	s9,40(sp)
ffffffffc02060f0:	7d02                	ld	s10,32(sp)
ffffffffc02060f2:	6de2                	ld	s11,24(sp)
ffffffffc02060f4:	6109                	addi	sp,sp,128
ffffffffc02060f6:	8082                	ret
            padc = '0';
ffffffffc02060f8:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02060fa:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02060fe:	846a                	mv	s0,s10
ffffffffc0206100:	00140d13          	addi	s10,s0,1
ffffffffc0206104:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0206108:	0ff5f593          	zext.b	a1,a1
ffffffffc020610c:	fcb572e3          	bgeu	a0,a1,ffffffffc02060d0 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0206110:	85a6                	mv	a1,s1
ffffffffc0206112:	02500513          	li	a0,37
ffffffffc0206116:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0206118:	fff44783          	lbu	a5,-1(s0)
ffffffffc020611c:	8d22                	mv	s10,s0
ffffffffc020611e:	f73788e3          	beq	a5,s3,ffffffffc020608e <vprintfmt+0x3a>
ffffffffc0206122:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0206126:	1d7d                	addi	s10,s10,-1
ffffffffc0206128:	ff379de3          	bne	a5,s3,ffffffffc0206122 <vprintfmt+0xce>
ffffffffc020612c:	b78d                	j	ffffffffc020608e <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020612e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0206132:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206136:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0206138:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020613c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0206140:	02d86463          	bltu	a6,a3,ffffffffc0206168 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0206144:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0206148:	002c169b          	slliw	a3,s8,0x2
ffffffffc020614c:	0186873b          	addw	a4,a3,s8
ffffffffc0206150:	0017171b          	slliw	a4,a4,0x1
ffffffffc0206154:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0206156:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020615a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020615c:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0206160:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0206164:	fed870e3          	bgeu	a6,a3,ffffffffc0206144 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0206168:	f40ddce3          	bgez	s11,ffffffffc02060c0 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc020616c:	8de2                	mv	s11,s8
ffffffffc020616e:	5c7d                	li	s8,-1
ffffffffc0206170:	bf81                	j	ffffffffc02060c0 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0206172:	fffdc693          	not	a3,s11
ffffffffc0206176:	96fd                	srai	a3,a3,0x3f
ffffffffc0206178:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020617c:	00144603          	lbu	a2,1(s0)
ffffffffc0206180:	2d81                	sext.w	s11,s11
ffffffffc0206182:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0206184:	bf35                	j	ffffffffc02060c0 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0206186:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020618a:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020618e:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206190:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0206192:	bfd9                	j	ffffffffc0206168 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0206194:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0206196:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020619a:	01174463          	blt	a4,a7,ffffffffc02061a2 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020619e:	1a088e63          	beqz	a7,ffffffffc020635a <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02061a2:	000a3603          	ld	a2,0(s4)
ffffffffc02061a6:	46c1                	li	a3,16
ffffffffc02061a8:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02061aa:	2781                	sext.w	a5,a5
ffffffffc02061ac:	876e                	mv	a4,s11
ffffffffc02061ae:	85a6                	mv	a1,s1
ffffffffc02061b0:	854a                	mv	a0,s2
ffffffffc02061b2:	e37ff0ef          	jal	ra,ffffffffc0205fe8 <printnum>
            break;
ffffffffc02061b6:	bde1                	j	ffffffffc020608e <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02061b8:	000a2503          	lw	a0,0(s4)
ffffffffc02061bc:	85a6                	mv	a1,s1
ffffffffc02061be:	0a21                	addi	s4,s4,8
ffffffffc02061c0:	9902                	jalr	s2
            break;
ffffffffc02061c2:	b5f1                	j	ffffffffc020608e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02061c4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02061c6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02061ca:	01174463          	blt	a4,a7,ffffffffc02061d2 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02061ce:	18088163          	beqz	a7,ffffffffc0206350 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02061d2:	000a3603          	ld	a2,0(s4)
ffffffffc02061d6:	46a9                	li	a3,10
ffffffffc02061d8:	8a2e                	mv	s4,a1
ffffffffc02061da:	bfc1                	j	ffffffffc02061aa <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02061dc:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02061e0:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02061e2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02061e4:	bdf1                	j	ffffffffc02060c0 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02061e6:	85a6                	mv	a1,s1
ffffffffc02061e8:	02500513          	li	a0,37
ffffffffc02061ec:	9902                	jalr	s2
            break;
ffffffffc02061ee:	b545                	j	ffffffffc020608e <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02061f0:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02061f4:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02061f6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02061f8:	b5e1                	j	ffffffffc02060c0 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02061fa:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02061fc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0206200:	01174463          	blt	a4,a7,ffffffffc0206208 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0206204:	14088163          	beqz	a7,ffffffffc0206346 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0206208:	000a3603          	ld	a2,0(s4)
ffffffffc020620c:	46a1                	li	a3,8
ffffffffc020620e:	8a2e                	mv	s4,a1
ffffffffc0206210:	bf69                	j	ffffffffc02061aa <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0206212:	03000513          	li	a0,48
ffffffffc0206216:	85a6                	mv	a1,s1
ffffffffc0206218:	e03e                	sd	a5,0(sp)
ffffffffc020621a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020621c:	85a6                	mv	a1,s1
ffffffffc020621e:	07800513          	li	a0,120
ffffffffc0206222:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0206224:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0206226:	6782                	ld	a5,0(sp)
ffffffffc0206228:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020622a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020622e:	bfb5                	j	ffffffffc02061aa <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0206230:	000a3403          	ld	s0,0(s4)
ffffffffc0206234:	008a0713          	addi	a4,s4,8
ffffffffc0206238:	e03a                	sd	a4,0(sp)
ffffffffc020623a:	14040263          	beqz	s0,ffffffffc020637e <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020623e:	0fb05763          	blez	s11,ffffffffc020632c <vprintfmt+0x2d8>
ffffffffc0206242:	02d00693          	li	a3,45
ffffffffc0206246:	0cd79163          	bne	a5,a3,ffffffffc0206308 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020624a:	00044783          	lbu	a5,0(s0)
ffffffffc020624e:	0007851b          	sext.w	a0,a5
ffffffffc0206252:	cf85                	beqz	a5,ffffffffc020628a <vprintfmt+0x236>
ffffffffc0206254:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206258:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020625c:	000c4563          	bltz	s8,ffffffffc0206266 <vprintfmt+0x212>
ffffffffc0206260:	3c7d                	addiw	s8,s8,-1
ffffffffc0206262:	036c0263          	beq	s8,s6,ffffffffc0206286 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0206266:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206268:	0e0c8e63          	beqz	s9,ffffffffc0206364 <vprintfmt+0x310>
ffffffffc020626c:	3781                	addiw	a5,a5,-32
ffffffffc020626e:	0ef47b63          	bgeu	s0,a5,ffffffffc0206364 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0206272:	03f00513          	li	a0,63
ffffffffc0206276:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206278:	000a4783          	lbu	a5,0(s4)
ffffffffc020627c:	3dfd                	addiw	s11,s11,-1
ffffffffc020627e:	0a05                	addi	s4,s4,1
ffffffffc0206280:	0007851b          	sext.w	a0,a5
ffffffffc0206284:	ffe1                	bnez	a5,ffffffffc020625c <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0206286:	01b05963          	blez	s11,ffffffffc0206298 <vprintfmt+0x244>
ffffffffc020628a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020628c:	85a6                	mv	a1,s1
ffffffffc020628e:	02000513          	li	a0,32
ffffffffc0206292:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0206294:	fe0d9be3          	bnez	s11,ffffffffc020628a <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0206298:	6a02                	ld	s4,0(sp)
ffffffffc020629a:	bbd5                	j	ffffffffc020608e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020629c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020629e:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02062a2:	01174463          	blt	a4,a7,ffffffffc02062aa <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02062a6:	08088d63          	beqz	a7,ffffffffc0206340 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02062aa:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02062ae:	0a044d63          	bltz	s0,ffffffffc0206368 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02062b2:	8622                	mv	a2,s0
ffffffffc02062b4:	8a66                	mv	s4,s9
ffffffffc02062b6:	46a9                	li	a3,10
ffffffffc02062b8:	bdcd                	j	ffffffffc02061aa <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02062ba:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02062be:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc02062c0:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02062c2:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02062c6:	8fb5                	xor	a5,a5,a3
ffffffffc02062c8:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02062cc:	02d74163          	blt	a4,a3,ffffffffc02062ee <vprintfmt+0x29a>
ffffffffc02062d0:	00369793          	slli	a5,a3,0x3
ffffffffc02062d4:	97de                	add	a5,a5,s7
ffffffffc02062d6:	639c                	ld	a5,0(a5)
ffffffffc02062d8:	cb99                	beqz	a5,ffffffffc02062ee <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02062da:	86be                	mv	a3,a5
ffffffffc02062dc:	00000617          	auipc	a2,0x0
ffffffffc02062e0:	1cc60613          	addi	a2,a2,460 # ffffffffc02064a8 <etext+0x2c>
ffffffffc02062e4:	85a6                	mv	a1,s1
ffffffffc02062e6:	854a                	mv	a0,s2
ffffffffc02062e8:	0ce000ef          	jal	ra,ffffffffc02063b6 <printfmt>
ffffffffc02062ec:	b34d                	j	ffffffffc020608e <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02062ee:	00002617          	auipc	a2,0x2
ffffffffc02062f2:	52260613          	addi	a2,a2,1314 # ffffffffc0208810 <syscalls+0x120>
ffffffffc02062f6:	85a6                	mv	a1,s1
ffffffffc02062f8:	854a                	mv	a0,s2
ffffffffc02062fa:	0bc000ef          	jal	ra,ffffffffc02063b6 <printfmt>
ffffffffc02062fe:	bb41                	j	ffffffffc020608e <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0206300:	00002417          	auipc	s0,0x2
ffffffffc0206304:	50840413          	addi	s0,s0,1288 # ffffffffc0208808 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206308:	85e2                	mv	a1,s8
ffffffffc020630a:	8522                	mv	a0,s0
ffffffffc020630c:	e43e                	sd	a5,8(sp)
ffffffffc020630e:	0e2000ef          	jal	ra,ffffffffc02063f0 <strnlen>
ffffffffc0206312:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0206316:	01b05b63          	blez	s11,ffffffffc020632c <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc020631a:	67a2                	ld	a5,8(sp)
ffffffffc020631c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206320:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0206322:	85a6                	mv	a1,s1
ffffffffc0206324:	8552                	mv	a0,s4
ffffffffc0206326:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206328:	fe0d9ce3          	bnez	s11,ffffffffc0206320 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020632c:	00044783          	lbu	a5,0(s0)
ffffffffc0206330:	00140a13          	addi	s4,s0,1
ffffffffc0206334:	0007851b          	sext.w	a0,a5
ffffffffc0206338:	d3a5                	beqz	a5,ffffffffc0206298 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020633a:	05e00413          	li	s0,94
ffffffffc020633e:	bf39                	j	ffffffffc020625c <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0206340:	000a2403          	lw	s0,0(s4)
ffffffffc0206344:	b7ad                	j	ffffffffc02062ae <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0206346:	000a6603          	lwu	a2,0(s4)
ffffffffc020634a:	46a1                	li	a3,8
ffffffffc020634c:	8a2e                	mv	s4,a1
ffffffffc020634e:	bdb1                	j	ffffffffc02061aa <vprintfmt+0x156>
ffffffffc0206350:	000a6603          	lwu	a2,0(s4)
ffffffffc0206354:	46a9                	li	a3,10
ffffffffc0206356:	8a2e                	mv	s4,a1
ffffffffc0206358:	bd89                	j	ffffffffc02061aa <vprintfmt+0x156>
ffffffffc020635a:	000a6603          	lwu	a2,0(s4)
ffffffffc020635e:	46c1                	li	a3,16
ffffffffc0206360:	8a2e                	mv	s4,a1
ffffffffc0206362:	b5a1                	j	ffffffffc02061aa <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0206364:	9902                	jalr	s2
ffffffffc0206366:	bf09                	j	ffffffffc0206278 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0206368:	85a6                	mv	a1,s1
ffffffffc020636a:	02d00513          	li	a0,45
ffffffffc020636e:	e03e                	sd	a5,0(sp)
ffffffffc0206370:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0206372:	6782                	ld	a5,0(sp)
ffffffffc0206374:	8a66                	mv	s4,s9
ffffffffc0206376:	40800633          	neg	a2,s0
ffffffffc020637a:	46a9                	li	a3,10
ffffffffc020637c:	b53d                	j	ffffffffc02061aa <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc020637e:	03b05163          	blez	s11,ffffffffc02063a0 <vprintfmt+0x34c>
ffffffffc0206382:	02d00693          	li	a3,45
ffffffffc0206386:	f6d79de3          	bne	a5,a3,ffffffffc0206300 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc020638a:	00002417          	auipc	s0,0x2
ffffffffc020638e:	47e40413          	addi	s0,s0,1150 # ffffffffc0208808 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206392:	02800793          	li	a5,40
ffffffffc0206396:	02800513          	li	a0,40
ffffffffc020639a:	00140a13          	addi	s4,s0,1
ffffffffc020639e:	bd6d                	j	ffffffffc0206258 <vprintfmt+0x204>
ffffffffc02063a0:	00002a17          	auipc	s4,0x2
ffffffffc02063a4:	469a0a13          	addi	s4,s4,1129 # ffffffffc0208809 <syscalls+0x119>
ffffffffc02063a8:	02800513          	li	a0,40
ffffffffc02063ac:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02063b0:	05e00413          	li	s0,94
ffffffffc02063b4:	b565                	j	ffffffffc020625c <vprintfmt+0x208>

ffffffffc02063b6 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02063b6:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02063b8:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02063bc:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02063be:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02063c0:	ec06                	sd	ra,24(sp)
ffffffffc02063c2:	f83a                	sd	a4,48(sp)
ffffffffc02063c4:	fc3e                	sd	a5,56(sp)
ffffffffc02063c6:	e0c2                	sd	a6,64(sp)
ffffffffc02063c8:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02063ca:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02063cc:	c89ff0ef          	jal	ra,ffffffffc0206054 <vprintfmt>
}
ffffffffc02063d0:	60e2                	ld	ra,24(sp)
ffffffffc02063d2:	6161                	addi	sp,sp,80
ffffffffc02063d4:	8082                	ret

ffffffffc02063d6 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02063d6:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02063da:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02063dc:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02063de:	cb81                	beqz	a5,ffffffffc02063ee <strlen+0x18>
        cnt ++;
ffffffffc02063e0:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02063e2:	00a707b3          	add	a5,a4,a0
ffffffffc02063e6:	0007c783          	lbu	a5,0(a5)
ffffffffc02063ea:	fbfd                	bnez	a5,ffffffffc02063e0 <strlen+0xa>
ffffffffc02063ec:	8082                	ret
    }
    return cnt;
}
ffffffffc02063ee:	8082                	ret

ffffffffc02063f0 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02063f0:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02063f2:	e589                	bnez	a1,ffffffffc02063fc <strnlen+0xc>
ffffffffc02063f4:	a811                	j	ffffffffc0206408 <strnlen+0x18>
        cnt ++;
ffffffffc02063f6:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02063f8:	00f58863          	beq	a1,a5,ffffffffc0206408 <strnlen+0x18>
ffffffffc02063fc:	00f50733          	add	a4,a0,a5
ffffffffc0206400:	00074703          	lbu	a4,0(a4)
ffffffffc0206404:	fb6d                	bnez	a4,ffffffffc02063f6 <strnlen+0x6>
ffffffffc0206406:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0206408:	852e                	mv	a0,a1
ffffffffc020640a:	8082                	ret

ffffffffc020640c <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc020640c:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc020640e:	0005c703          	lbu	a4,0(a1)
ffffffffc0206412:	0785                	addi	a5,a5,1
ffffffffc0206414:	0585                	addi	a1,a1,1
ffffffffc0206416:	fee78fa3          	sb	a4,-1(a5)
ffffffffc020641a:	fb75                	bnez	a4,ffffffffc020640e <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc020641c:	8082                	ret

ffffffffc020641e <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020641e:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0206422:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0206426:	cb89                	beqz	a5,ffffffffc0206438 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0206428:	0505                	addi	a0,a0,1
ffffffffc020642a:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020642c:	fee789e3          	beq	a5,a4,ffffffffc020641e <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0206430:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0206434:	9d19                	subw	a0,a0,a4
ffffffffc0206436:	8082                	ret
ffffffffc0206438:	4501                	li	a0,0
ffffffffc020643a:	bfed                	j	ffffffffc0206434 <strcmp+0x16>

ffffffffc020643c <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020643c:	00054783          	lbu	a5,0(a0)
ffffffffc0206440:	c799                	beqz	a5,ffffffffc020644e <strchr+0x12>
        if (*s == c) {
ffffffffc0206442:	00f58763          	beq	a1,a5,ffffffffc0206450 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0206446:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc020644a:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020644c:	fbfd                	bnez	a5,ffffffffc0206442 <strchr+0x6>
    }
    return NULL;
ffffffffc020644e:	4501                	li	a0,0
}
ffffffffc0206450:	8082                	ret

ffffffffc0206452 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0206452:	ca01                	beqz	a2,ffffffffc0206462 <memset+0x10>
ffffffffc0206454:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0206456:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0206458:	0785                	addi	a5,a5,1
ffffffffc020645a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020645e:	fec79de3          	bne	a5,a2,ffffffffc0206458 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0206462:	8082                	ret

ffffffffc0206464 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0206464:	ca19                	beqz	a2,ffffffffc020647a <memcpy+0x16>
ffffffffc0206466:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0206468:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc020646a:	0005c703          	lbu	a4,0(a1)
ffffffffc020646e:	0585                	addi	a1,a1,1
ffffffffc0206470:	0785                	addi	a5,a5,1
ffffffffc0206472:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0206476:	fec59ae3          	bne	a1,a2,ffffffffc020646a <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc020647a:	8082                	ret
