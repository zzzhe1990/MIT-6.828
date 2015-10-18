
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 80 18 10 f0       	push   $0xf0101880
f0100050:	e8 81 08 00 00       	call   f01008d6 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 d3 06 00 00       	call   f010074e <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 9c 18 10 f0       	push   $0xf010189c
f0100087:	e8 4a 08 00 00       	call   f01008d6 <cprintf>
f010008c:	83 c4 10             	add    $0x10,%esp
}
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 84 29 11 f0       	mov    $0xf0112984,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 10 13 00 00       	call   f01013c1 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8c 04 00 00       	call   f0100542 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 b7 18 10 f0       	push   $0xf01018b7
f01000c3:	e8 0e 08 00 00       	call   f01008d6 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 77 06 00 00       	call   f0100758 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 80 29 11 f0 00 	cmpl   $0x0,0xf0112980
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 80 29 11 f0    	mov    %esi,0xf0112980

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 d2 18 10 f0       	push   $0xf01018d2
f0100110:	e8 c1 07 00 00       	call   f01008d6 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 91 07 00 00       	call   f01008b0 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 0e 19 10 f0 	movl   $0xf010190e,(%esp)
f0100126:	e8 ab 07 00 00       	call   f01008d6 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 20 06 00 00       	call   f0100758 <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 ea 18 10 f0       	push   $0xf01018ea
f0100152:	e8 7f 07 00 00       	call   f01008d6 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 4d 07 00 00       	call   f01008b0 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 0e 19 10 f0 	movl   $0xf010190e,(%esp)
f010016a:	e8 67 07 00 00       	call   f01008d6 <cprintf>
	va_end(ap);
f010016f:	83 c4 10             	add    $0x10,%esp
}
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 08                	je     f010018c <serial_proc_data+0x15>
f0100184:	b2 f8                	mov    $0xf8,%dl
f0100186:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100187:	0f b6 c0             	movzbl %al,%eax
f010018a:	eb 05                	jmp    f0100191 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100193:	55                   	push   %ebp
f0100194:	89 e5                	mov    %esp,%ebp
f0100196:	53                   	push   %ebx
f0100197:	83 ec 04             	sub    $0x4,%esp
f010019a:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019c:	eb 2a                	jmp    f01001c8 <cons_intr+0x35>
		if (c == 0)
f010019e:	85 d2                	test   %edx,%edx
f01001a0:	74 26                	je     f01001c8 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a2:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f01001a7:	8d 48 01             	lea    0x1(%eax),%ecx
f01001aa:	89 0d 44 25 11 f0    	mov    %ecx,0xf0112544
f01001b0:	88 90 40 23 11 f0    	mov    %dl,-0xfeedcc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001b6:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001bc:	75 0a                	jne    f01001c8 <cons_intr+0x35>
			cons.wpos = 0;
f01001be:	c7 05 44 25 11 f0 00 	movl   $0x0,0xf0112544
f01001c5:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001c8:	ff d3                	call   *%ebx
f01001ca:	89 c2                	mov    %eax,%edx
f01001cc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001cf:	75 cd                	jne    f010019e <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d1:	83 c4 04             	add    $0x4,%esp
f01001d4:	5b                   	pop    %ebx
f01001d5:	5d                   	pop    %ebp
f01001d6:	c3                   	ret    

f01001d7 <kbd_proc_data>:
f01001d7:	ba 64 00 00 00       	mov    $0x64,%edx
f01001dc:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001dd:	a8 01                	test   $0x1,%al
f01001df:	0f 84 f0 00 00 00    	je     f01002d5 <kbd_proc_data+0xfe>
f01001e5:	b2 60                	mov    $0x60,%dl
f01001e7:	ec                   	in     (%dx),%al
f01001e8:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001ea:	3c e0                	cmp    $0xe0,%al
f01001ec:	75 0d                	jne    f01001fb <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001ee:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f01001f5:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001fa:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001fb:	55                   	push   %ebp
f01001fc:	89 e5                	mov    %esp,%ebp
f01001fe:	53                   	push   %ebx
f01001ff:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100202:	84 c0                	test   %al,%al
f0100204:	79 36                	jns    f010023c <kbd_proc_data+0x65>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100206:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010020c:	89 cb                	mov    %ecx,%ebx
f010020e:	83 e3 40             	and    $0x40,%ebx
f0100211:	83 e0 7f             	and    $0x7f,%eax
f0100214:	85 db                	test   %ebx,%ebx
f0100216:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100219:	0f b6 d2             	movzbl %dl,%edx
f010021c:	0f b6 82 80 1a 10 f0 	movzbl -0xfefe580(%edx),%eax
f0100223:	83 c8 40             	or     $0x40,%eax
f0100226:	0f b6 c0             	movzbl %al,%eax
f0100229:	f7 d0                	not    %eax
f010022b:	21 c8                	and    %ecx,%eax
f010022d:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f0100232:	b8 00 00 00 00       	mov    $0x0,%eax
f0100237:	e9 a1 00 00 00       	jmp    f01002dd <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f010023c:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100242:	f6 c1 40             	test   $0x40,%cl
f0100245:	74 0e                	je     f0100255 <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100247:	83 c8 80             	or     $0xffffff80,%eax
f010024a:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010024c:	83 e1 bf             	and    $0xffffffbf,%ecx
f010024f:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100255:	0f b6 c2             	movzbl %dl,%eax
f0100258:	0f b6 90 80 1a 10 f0 	movzbl -0xfefe580(%eax),%edx
f010025f:	0b 15 00 23 11 f0    	or     0xf0112300,%edx
	shift ^= togglecode[data];
f0100265:	0f b6 88 80 19 10 f0 	movzbl -0xfefe680(%eax),%ecx
f010026c:	31 ca                	xor    %ecx,%edx
f010026e:	89 15 00 23 11 f0    	mov    %edx,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100274:	89 d1                	mov    %edx,%ecx
f0100276:	83 e1 03             	and    $0x3,%ecx
f0100279:	8b 0c 8d 40 19 10 f0 	mov    -0xfefe6c0(,%ecx,4),%ecx
f0100280:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f0100284:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100287:	f6 c2 08             	test   $0x8,%dl
f010028a:	74 1b                	je     f01002a7 <kbd_proc_data+0xd0>
		if ('a' <= c && c <= 'z')
f010028c:	89 d8                	mov    %ebx,%eax
f010028e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100291:	83 f9 19             	cmp    $0x19,%ecx
f0100294:	77 05                	ja     f010029b <kbd_proc_data+0xc4>
			c += 'A' - 'a';
f0100296:	83 eb 20             	sub    $0x20,%ebx
f0100299:	eb 0c                	jmp    f01002a7 <kbd_proc_data+0xd0>
		else if ('A' <= c && c <= 'Z')
f010029b:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f010029e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002a1:	83 f8 19             	cmp    $0x19,%eax
f01002a4:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002a7:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002ad:	75 2c                	jne    f01002db <kbd_proc_data+0x104>
f01002af:	f7 d2                	not    %edx
f01002b1:	f6 c2 06             	test   $0x6,%dl
f01002b4:	75 25                	jne    f01002db <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01002b6:	83 ec 0c             	sub    $0xc,%esp
f01002b9:	68 04 19 10 f0       	push   $0xf0101904
f01002be:	e8 13 06 00 00       	call   f01008d6 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c3:	ba 92 00 00 00       	mov    $0x92,%edx
f01002c8:	b8 03 00 00 00       	mov    $0x3,%eax
f01002cd:	ee                   	out    %al,(%dx)
f01002ce:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d1:	89 d8                	mov    %ebx,%eax
f01002d3:	eb 08                	jmp    f01002dd <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002da:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002db:	89 d8                	mov    %ebx,%eax
}
f01002dd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002e0:	c9                   	leave  
f01002e1:	c3                   	ret    

f01002e2 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002e2:	55                   	push   %ebp
f01002e3:	89 e5                	mov    %esp,%ebp
f01002e5:	57                   	push   %edi
f01002e6:	56                   	push   %esi
f01002e7:	53                   	push   %ebx
f01002e8:	83 ec 1c             	sub    $0x1c,%esp
f01002eb:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ed:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f2:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002f7:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fc:	eb 09                	jmp    f0100307 <cons_putc+0x25>
f01002fe:	89 ca                	mov    %ecx,%edx
f0100300:	ec                   	in     (%dx),%al
f0100301:	ec                   	in     (%dx),%al
f0100302:	ec                   	in     (%dx),%al
f0100303:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100304:	83 c3 01             	add    $0x1,%ebx
f0100307:	89 f2                	mov    %esi,%edx
f0100309:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010030a:	a8 20                	test   $0x20,%al
f010030c:	75 08                	jne    f0100316 <cons_putc+0x34>
f010030e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100314:	7e e8                	jle    f01002fe <cons_putc+0x1c>
f0100316:	89 f8                	mov    %edi,%eax
f0100318:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100320:	89 f8                	mov    %edi,%eax
f0100322:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100323:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100328:	be 79 03 00 00       	mov    $0x379,%esi
f010032d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100332:	eb 09                	jmp    f010033d <cons_putc+0x5b>
f0100334:	89 ca                	mov    %ecx,%edx
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	ec                   	in     (%dx),%al
f0100339:	ec                   	in     (%dx),%al
f010033a:	83 c3 01             	add    $0x1,%ebx
f010033d:	89 f2                	mov    %esi,%edx
f010033f:	ec                   	in     (%dx),%al
f0100340:	84 c0                	test   %al,%al
f0100342:	78 08                	js     f010034c <cons_putc+0x6a>
f0100344:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010034a:	7e e8                	jle    f0100334 <cons_putc+0x52>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100351:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100355:	ee                   	out    %al,(%dx)
f0100356:	b2 7a                	mov    $0x7a,%dl
f0100358:	b8 0d 00 00 00       	mov    $0xd,%eax
f010035d:	ee                   	out    %al,(%dx)
f010035e:	b8 08 00 00 00       	mov    $0x8,%eax
f0100363:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100364:	89 fa                	mov    %edi,%edx
f0100366:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010036c:	89 f8                	mov    %edi,%eax
f010036e:	80 cc 07             	or     $0x7,%ah
f0100371:	85 d2                	test   %edx,%edx
f0100373:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100376:	89 f8                	mov    %edi,%eax
f0100378:	0f b6 c0             	movzbl %al,%eax
f010037b:	83 f8 09             	cmp    $0x9,%eax
f010037e:	74 74                	je     f01003f4 <cons_putc+0x112>
f0100380:	83 f8 09             	cmp    $0x9,%eax
f0100383:	7f 0a                	jg     f010038f <cons_putc+0xad>
f0100385:	83 f8 08             	cmp    $0x8,%eax
f0100388:	74 14                	je     f010039e <cons_putc+0xbc>
f010038a:	e9 99 00 00 00       	jmp    f0100428 <cons_putc+0x146>
f010038f:	83 f8 0a             	cmp    $0xa,%eax
f0100392:	74 3a                	je     f01003ce <cons_putc+0xec>
f0100394:	83 f8 0d             	cmp    $0xd,%eax
f0100397:	74 3d                	je     f01003d6 <cons_putc+0xf4>
f0100399:	e9 8a 00 00 00       	jmp    f0100428 <cons_putc+0x146>
	case '\b':
		if (crt_pos > 0) {
f010039e:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f01003a5:	66 85 c0             	test   %ax,%ax
f01003a8:	0f 84 e6 00 00 00    	je     f0100494 <cons_putc+0x1b2>
			crt_pos--;
f01003ae:	83 e8 01             	sub    $0x1,%eax
f01003b1:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003b7:	0f b7 c0             	movzwl %ax,%eax
f01003ba:	66 81 e7 00 ff       	and    $0xff00,%di
f01003bf:	83 cf 20             	or     $0x20,%edi
f01003c2:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f01003c8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003cc:	eb 78                	jmp    f0100446 <cons_putc+0x164>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003ce:	66 83 05 48 25 11 f0 	addw   $0x50,0xf0112548
f01003d5:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003d6:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f01003dd:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e3:	c1 e8 16             	shr    $0x16,%eax
f01003e6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003e9:	c1 e0 04             	shl    $0x4,%eax
f01003ec:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
f01003f2:	eb 52                	jmp    f0100446 <cons_putc+0x164>
		break;
	case '\t':
		cons_putc(' ');
f01003f4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f9:	e8 e4 fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f01003fe:	b8 20 00 00 00       	mov    $0x20,%eax
f0100403:	e8 da fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f0100408:	b8 20 00 00 00       	mov    $0x20,%eax
f010040d:	e8 d0 fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f0100412:	b8 20 00 00 00       	mov    $0x20,%eax
f0100417:	e8 c6 fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f010041c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100421:	e8 bc fe ff ff       	call   f01002e2 <cons_putc>
f0100426:	eb 1e                	jmp    f0100446 <cons_putc+0x164>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100428:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f010042f:	8d 50 01             	lea    0x1(%eax),%edx
f0100432:	66 89 15 48 25 11 f0 	mov    %dx,0xf0112548
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f0100442:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100446:	66 81 3d 48 25 11 f0 	cmpw   $0x7cf,0xf0112548
f010044d:	cf 07 
f010044f:	76 43                	jbe    f0100494 <cons_putc+0x1b2>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100451:	a1 4c 25 11 f0       	mov    0xf011254c,%eax
f0100456:	83 ec 04             	sub    $0x4,%esp
f0100459:	68 00 0f 00 00       	push   $0xf00
f010045e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100464:	52                   	push   %edx
f0100465:	50                   	push   %eax
f0100466:	e8 a3 0f 00 00       	call   f010140e <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010046b:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f0100471:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100477:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010047d:	83 c4 10             	add    $0x10,%esp
f0100480:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100485:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100488:	39 d0                	cmp    %edx,%eax
f010048a:	75 f4                	jne    f0100480 <cons_putc+0x19e>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010048c:	66 83 2d 48 25 11 f0 	subw   $0x50,0xf0112548
f0100493:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100494:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f010049a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010049f:	89 ca                	mov    %ecx,%edx
f01004a1:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a2:	0f b7 1d 48 25 11 f0 	movzwl 0xf0112548,%ebx
f01004a9:	8d 71 01             	lea    0x1(%ecx),%esi
f01004ac:	89 d8                	mov    %ebx,%eax
f01004ae:	66 c1 e8 08          	shr    $0x8,%ax
f01004b2:	89 f2                	mov    %esi,%edx
f01004b4:	ee                   	out    %al,(%dx)
f01004b5:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004ba:	89 ca                	mov    %ecx,%edx
f01004bc:	ee                   	out    %al,(%dx)
f01004bd:	89 d8                	mov    %ebx,%eax
f01004bf:	89 f2                	mov    %esi,%edx
f01004c1:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004c2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004c5:	5b                   	pop    %ebx
f01004c6:	5e                   	pop    %esi
f01004c7:	5f                   	pop    %edi
f01004c8:	5d                   	pop    %ebp
f01004c9:	c3                   	ret    

f01004ca <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004ca:	80 3d 54 25 11 f0 00 	cmpb   $0x0,0xf0112554
f01004d1:	74 11                	je     f01004e4 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004d3:	55                   	push   %ebp
f01004d4:	89 e5                	mov    %esp,%ebp
f01004d6:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004d9:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004de:	e8 b0 fc ff ff       	call   f0100193 <cons_intr>
}
f01004e3:	c9                   	leave  
f01004e4:	f3 c3                	repz ret 

f01004e6 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004e6:	55                   	push   %ebp
f01004e7:	89 e5                	mov    %esp,%ebp
f01004e9:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ec:	b8 d7 01 10 f0       	mov    $0xf01001d7,%eax
f01004f1:	e8 9d fc ff ff       	call   f0100193 <cons_intr>
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004fe:	e8 c7 ff ff ff       	call   f01004ca <serial_intr>
	kbd_intr();
f0100503:	e8 de ff ff ff       	call   f01004e6 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100508:	a1 40 25 11 f0       	mov    0xf0112540,%eax
f010050d:	3b 05 44 25 11 f0    	cmp    0xf0112544,%eax
f0100513:	74 26                	je     f010053b <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100515:	8d 50 01             	lea    0x1(%eax),%edx
f0100518:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
f010051e:	0f b6 88 40 23 11 f0 	movzbl -0xfeedcc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100525:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100527:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010052d:	75 11                	jne    f0100540 <cons_getc+0x48>
			cons.rpos = 0;
f010052f:	c7 05 40 25 11 f0 00 	movl   $0x0,0xf0112540
f0100536:	00 00 00 
f0100539:	eb 05                	jmp    f0100540 <cons_getc+0x48>
		return c;
	}
	return 0;
f010053b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100540:	c9                   	leave  
f0100541:	c3                   	ret    

f0100542 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100542:	55                   	push   %ebp
f0100543:	89 e5                	mov    %esp,%ebp
f0100545:	57                   	push   %edi
f0100546:	56                   	push   %esi
f0100547:	53                   	push   %ebx
f0100548:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010054b:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100552:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100559:	5a a5 
	if (*cp != 0xA55A) {
f010055b:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100562:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100566:	74 11                	je     f0100579 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100568:	c7 05 50 25 11 f0 b4 	movl   $0x3b4,0xf0112550
f010056f:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100572:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100577:	eb 16                	jmp    f010058f <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100579:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100580:	c7 05 50 25 11 f0 d4 	movl   $0x3d4,0xf0112550
f0100587:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010058a:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010058f:	8b 3d 50 25 11 f0    	mov    0xf0112550,%edi
f0100595:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059a:	89 fa                	mov    %edi,%edx
f010059c:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010059d:	8d 4f 01             	lea    0x1(%edi),%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a0:	89 ca                	mov    %ecx,%edx
f01005a2:	ec                   	in     (%dx),%al
f01005a3:	0f b6 c0             	movzbl %al,%eax
f01005a6:	c1 e0 08             	shl    $0x8,%eax
f01005a9:	89 c3                	mov    %eax,%ebx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ab:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b0:	89 fa                	mov    %edi,%edx
f01005b2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b3:	89 ca                	mov    %ecx,%edx
f01005b5:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005b6:	89 35 4c 25 11 f0    	mov    %esi,0xf011254c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005bc:	0f b6 c8             	movzbl %al,%ecx
f01005bf:	89 d8                	mov    %ebx,%eax
f01005c1:	09 c8                	or     %ecx,%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005c3:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c9:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d3:	89 da                	mov    %ebx,%edx
f01005d5:	ee                   	out    %al,(%dx)
f01005d6:	b2 fb                	mov    $0xfb,%dl
f01005d8:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005dd:	ee                   	out    %al,(%dx)
f01005de:	be f8 03 00 00       	mov    $0x3f8,%esi
f01005e3:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005e8:	89 f2                	mov    %esi,%edx
f01005ea:	ee                   	out    %al,(%dx)
f01005eb:	b2 f9                	mov    $0xf9,%dl
f01005ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f2:	ee                   	out    %al,(%dx)
f01005f3:	b2 fb                	mov    $0xfb,%dl
f01005f5:	b8 03 00 00 00       	mov    $0x3,%eax
f01005fa:	ee                   	out    %al,(%dx)
f01005fb:	b2 fc                	mov    $0xfc,%dl
f01005fd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100602:	ee                   	out    %al,(%dx)
f0100603:	b2 f9                	mov    $0xf9,%dl
f0100605:	b8 01 00 00 00       	mov    $0x1,%eax
f010060a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010060b:	b2 fd                	mov    $0xfd,%dl
f010060d:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010060e:	3c ff                	cmp    $0xff,%al
f0100610:	0f 95 c1             	setne  %cl
f0100613:	88 0d 54 25 11 f0    	mov    %cl,0xf0112554
f0100619:	89 da                	mov    %ebx,%edx
f010061b:	ec                   	in     (%dx),%al
f010061c:	89 f2                	mov    %esi,%edx
f010061e:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010061f:	84 c9                	test   %cl,%cl
f0100621:	75 10                	jne    f0100633 <cons_init+0xf1>
		cprintf("Serial port does not exist!\n");
f0100623:	83 ec 0c             	sub    $0xc,%esp
f0100626:	68 10 19 10 f0       	push   $0xf0101910
f010062b:	e8 a6 02 00 00       	call   f01008d6 <cprintf>
f0100630:	83 c4 10             	add    $0x10,%esp
}
f0100633:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100636:	5b                   	pop    %ebx
f0100637:	5e                   	pop    %esi
f0100638:	5f                   	pop    %edi
f0100639:	5d                   	pop    %ebp
f010063a:	c3                   	ret    

f010063b <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010063b:	55                   	push   %ebp
f010063c:	89 e5                	mov    %esp,%ebp
f010063e:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100641:	8b 45 08             	mov    0x8(%ebp),%eax
f0100644:	e8 99 fc ff ff       	call   f01002e2 <cons_putc>
}
f0100649:	c9                   	leave  
f010064a:	c3                   	ret    

f010064b <getchar>:

int
getchar(void)
{
f010064b:	55                   	push   %ebp
f010064c:	89 e5                	mov    %esp,%ebp
f010064e:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100651:	e8 a2 fe ff ff       	call   f01004f8 <cons_getc>
f0100656:	85 c0                	test   %eax,%eax
f0100658:	74 f7                	je     f0100651 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010065a:	c9                   	leave  
f010065b:	c3                   	ret    

f010065c <iscons>:

int
iscons(int fdnum)
{
f010065c:	55                   	push   %ebp
f010065d:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010065f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100664:	5d                   	pop    %ebp
f0100665:	c3                   	ret    

f0100666 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100666:	55                   	push   %ebp
f0100667:	89 e5                	mov    %esp,%ebp
f0100669:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010066c:	68 80 1b 10 f0       	push   $0xf0101b80
f0100671:	68 9e 1b 10 f0       	push   $0xf0101b9e
f0100676:	68 a3 1b 10 f0       	push   $0xf0101ba3
f010067b:	e8 56 02 00 00       	call   f01008d6 <cprintf>
f0100680:	83 c4 0c             	add    $0xc,%esp
f0100683:	68 0c 1c 10 f0       	push   $0xf0101c0c
f0100688:	68 ac 1b 10 f0       	push   $0xf0101bac
f010068d:	68 a3 1b 10 f0       	push   $0xf0101ba3
f0100692:	e8 3f 02 00 00       	call   f01008d6 <cprintf>
	return 0;
}
f0100697:	b8 00 00 00 00       	mov    $0x0,%eax
f010069c:	c9                   	leave  
f010069d:	c3                   	ret    

f010069e <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010069e:	55                   	push   %ebp
f010069f:	89 e5                	mov    %esp,%ebp
f01006a1:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006a4:	68 b5 1b 10 f0       	push   $0xf0101bb5
f01006a9:	e8 28 02 00 00       	call   f01008d6 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006ae:	83 c4 08             	add    $0x8,%esp
f01006b1:	68 0c 00 10 00       	push   $0x10000c
f01006b6:	68 34 1c 10 f0       	push   $0xf0101c34
f01006bb:	e8 16 02 00 00       	call   f01008d6 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006c0:	83 c4 0c             	add    $0xc,%esp
f01006c3:	68 0c 00 10 00       	push   $0x10000c
f01006c8:	68 0c 00 10 f0       	push   $0xf010000c
f01006cd:	68 5c 1c 10 f0       	push   $0xf0101c5c
f01006d2:	e8 ff 01 00 00       	call   f01008d6 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d7:	83 c4 0c             	add    $0xc,%esp
f01006da:	68 75 18 10 00       	push   $0x101875
f01006df:	68 75 18 10 f0       	push   $0xf0101875
f01006e4:	68 80 1c 10 f0       	push   $0xf0101c80
f01006e9:	e8 e8 01 00 00       	call   f01008d6 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ee:	83 c4 0c             	add    $0xc,%esp
f01006f1:	68 00 23 11 00       	push   $0x112300
f01006f6:	68 00 23 11 f0       	push   $0xf0112300
f01006fb:	68 a4 1c 10 f0       	push   $0xf0101ca4
f0100700:	e8 d1 01 00 00       	call   f01008d6 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100705:	83 c4 0c             	add    $0xc,%esp
f0100708:	68 84 29 11 00       	push   $0x112984
f010070d:	68 84 29 11 f0       	push   $0xf0112984
f0100712:	68 c8 1c 10 f0       	push   $0xf0101cc8
f0100717:	e8 ba 01 00 00       	call   f01008d6 <cprintf>
f010071c:	b8 83 2d 11 f0       	mov    $0xf0112d83,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100721:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100726:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100729:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010072e:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100734:	85 c0                	test   %eax,%eax
f0100736:	0f 48 c2             	cmovs  %edx,%eax
f0100739:	c1 f8 0a             	sar    $0xa,%eax
f010073c:	50                   	push   %eax
f010073d:	68 ec 1c 10 f0       	push   $0xf0101cec
f0100742:	e8 8f 01 00 00       	call   f01008d6 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100747:	b8 00 00 00 00       	mov    $0x0,%eax
f010074c:	c9                   	leave  
f010074d:	c3                   	ret    

f010074e <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010074e:	55                   	push   %ebp
f010074f:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100751:	b8 00 00 00 00       	mov    $0x0,%eax
f0100756:	5d                   	pop    %ebp
f0100757:	c3                   	ret    

f0100758 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100758:	55                   	push   %ebp
f0100759:	89 e5                	mov    %esp,%ebp
f010075b:	57                   	push   %edi
f010075c:	56                   	push   %esi
f010075d:	53                   	push   %ebx
f010075e:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100761:	68 18 1d 10 f0       	push   $0xf0101d18
f0100766:	e8 6b 01 00 00       	call   f01008d6 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010076b:	c7 04 24 3c 1d 10 f0 	movl   $0xf0101d3c,(%esp)
f0100772:	e8 5f 01 00 00       	call   f01008d6 <cprintf>
f0100777:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010077a:	83 ec 0c             	sub    $0xc,%esp
f010077d:	68 ce 1b 10 f0       	push   $0xf0101bce
f0100782:	e8 e3 09 00 00       	call   f010116a <readline>
f0100787:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100789:	83 c4 10             	add    $0x10,%esp
f010078c:	85 c0                	test   %eax,%eax
f010078e:	74 ea                	je     f010077a <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100790:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100797:	be 00 00 00 00       	mov    $0x0,%esi
f010079c:	eb 0a                	jmp    f01007a8 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010079e:	c6 03 00             	movb   $0x0,(%ebx)
f01007a1:	89 f7                	mov    %esi,%edi
f01007a3:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007a6:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007a8:	0f b6 03             	movzbl (%ebx),%eax
f01007ab:	84 c0                	test   %al,%al
f01007ad:	74 63                	je     f0100812 <monitor+0xba>
f01007af:	83 ec 08             	sub    $0x8,%esp
f01007b2:	0f be c0             	movsbl %al,%eax
f01007b5:	50                   	push   %eax
f01007b6:	68 d2 1b 10 f0       	push   $0xf0101bd2
f01007bb:	e8 c4 0b 00 00       	call   f0101384 <strchr>
f01007c0:	83 c4 10             	add    $0x10,%esp
f01007c3:	85 c0                	test   %eax,%eax
f01007c5:	75 d7                	jne    f010079e <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f01007c7:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007ca:	74 46                	je     f0100812 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007cc:	83 fe 0f             	cmp    $0xf,%esi
f01007cf:	75 14                	jne    f01007e5 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007d1:	83 ec 08             	sub    $0x8,%esp
f01007d4:	6a 10                	push   $0x10
f01007d6:	68 d7 1b 10 f0       	push   $0xf0101bd7
f01007db:	e8 f6 00 00 00       	call   f01008d6 <cprintf>
f01007e0:	83 c4 10             	add    $0x10,%esp
f01007e3:	eb 95                	jmp    f010077a <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01007e5:	8d 7e 01             	lea    0x1(%esi),%edi
f01007e8:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01007ec:	eb 03                	jmp    f01007f1 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01007ee:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01007f1:	0f b6 03             	movzbl (%ebx),%eax
f01007f4:	84 c0                	test   %al,%al
f01007f6:	74 ae                	je     f01007a6 <monitor+0x4e>
f01007f8:	83 ec 08             	sub    $0x8,%esp
f01007fb:	0f be c0             	movsbl %al,%eax
f01007fe:	50                   	push   %eax
f01007ff:	68 d2 1b 10 f0       	push   $0xf0101bd2
f0100804:	e8 7b 0b 00 00       	call   f0101384 <strchr>
f0100809:	83 c4 10             	add    $0x10,%esp
f010080c:	85 c0                	test   %eax,%eax
f010080e:	74 de                	je     f01007ee <monitor+0x96>
f0100810:	eb 94                	jmp    f01007a6 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100812:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100819:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010081a:	85 f6                	test   %esi,%esi
f010081c:	0f 84 58 ff ff ff    	je     f010077a <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100822:	83 ec 08             	sub    $0x8,%esp
f0100825:	68 9e 1b 10 f0       	push   $0xf0101b9e
f010082a:	ff 75 a8             	pushl  -0x58(%ebp)
f010082d:	e8 f4 0a 00 00       	call   f0101326 <strcmp>
f0100832:	83 c4 10             	add    $0x10,%esp
f0100835:	85 c0                	test   %eax,%eax
f0100837:	74 1b                	je     f0100854 <monitor+0xfc>
f0100839:	83 ec 08             	sub    $0x8,%esp
f010083c:	68 ac 1b 10 f0       	push   $0xf0101bac
f0100841:	ff 75 a8             	pushl  -0x58(%ebp)
f0100844:	e8 dd 0a 00 00       	call   f0101326 <strcmp>
f0100849:	83 c4 10             	add    $0x10,%esp
f010084c:	85 c0                	test   %eax,%eax
f010084e:	75 2d                	jne    f010087d <monitor+0x125>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100850:	b0 01                	mov    $0x1,%al
f0100852:	eb 05                	jmp    f0100859 <monitor+0x101>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100854:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100859:	83 ec 04             	sub    $0x4,%esp
f010085c:	8d 14 00             	lea    (%eax,%eax,1),%edx
f010085f:	01 d0                	add    %edx,%eax
f0100861:	ff 75 08             	pushl  0x8(%ebp)
f0100864:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100867:	51                   	push   %ecx
f0100868:	56                   	push   %esi
f0100869:	ff 14 85 6c 1d 10 f0 	call   *-0xfefe294(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100870:	83 c4 10             	add    $0x10,%esp
f0100873:	85 c0                	test   %eax,%eax
f0100875:	0f 89 ff fe ff ff    	jns    f010077a <monitor+0x22>
f010087b:	eb 18                	jmp    f0100895 <monitor+0x13d>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010087d:	83 ec 08             	sub    $0x8,%esp
f0100880:	ff 75 a8             	pushl  -0x58(%ebp)
f0100883:	68 f4 1b 10 f0       	push   $0xf0101bf4
f0100888:	e8 49 00 00 00       	call   f01008d6 <cprintf>
f010088d:	83 c4 10             	add    $0x10,%esp
f0100890:	e9 e5 fe ff ff       	jmp    f010077a <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100895:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100898:	5b                   	pop    %ebx
f0100899:	5e                   	pop    %esi
f010089a:	5f                   	pop    %edi
f010089b:	5d                   	pop    %ebp
f010089c:	c3                   	ret    

f010089d <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010089d:	55                   	push   %ebp
f010089e:	89 e5                	mov    %esp,%ebp
f01008a0:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01008a3:	ff 75 08             	pushl  0x8(%ebp)
f01008a6:	e8 90 fd ff ff       	call   f010063b <cputchar>
f01008ab:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f01008ae:	c9                   	leave  
f01008af:	c3                   	ret    

f01008b0 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008b0:	55                   	push   %ebp
f01008b1:	89 e5                	mov    %esp,%ebp
f01008b3:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01008b6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01008bd:	ff 75 0c             	pushl  0xc(%ebp)
f01008c0:	ff 75 08             	pushl  0x8(%ebp)
f01008c3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01008c6:	50                   	push   %eax
f01008c7:	68 9d 08 10 f0       	push   $0xf010089d
f01008cc:	e8 d6 03 00 00       	call   f0100ca7 <vprintfmt>
	return cnt;
}
f01008d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01008d4:	c9                   	leave  
f01008d5:	c3                   	ret    

f01008d6 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01008d6:	55                   	push   %ebp
f01008d7:	89 e5                	mov    %esp,%ebp
f01008d9:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01008dc:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01008df:	50                   	push   %eax
f01008e0:	ff 75 08             	pushl  0x8(%ebp)
f01008e3:	e8 c8 ff ff ff       	call   f01008b0 <vcprintf>
	va_end(ap);

	return cnt;
}
f01008e8:	c9                   	leave  
f01008e9:	c3                   	ret    

f01008ea <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01008ea:	55                   	push   %ebp
f01008eb:	89 e5                	mov    %esp,%ebp
f01008ed:	57                   	push   %edi
f01008ee:	56                   	push   %esi
f01008ef:	53                   	push   %ebx
f01008f0:	83 ec 14             	sub    $0x14,%esp
f01008f3:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01008f6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01008f9:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01008fc:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01008ff:	8b 1a                	mov    (%edx),%ebx
f0100901:	8b 01                	mov    (%ecx),%eax
f0100903:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100906:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010090d:	e9 88 00 00 00       	jmp    f010099a <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0100912:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100915:	01 d8                	add    %ebx,%eax
f0100917:	89 c6                	mov    %eax,%esi
f0100919:	c1 ee 1f             	shr    $0x1f,%esi
f010091c:	01 c6                	add    %eax,%esi
f010091e:	d1 fe                	sar    %esi
f0100920:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100923:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100926:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0100929:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010092b:	eb 03                	jmp    f0100930 <stab_binsearch+0x46>
			m--;
f010092d:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100930:	39 c3                	cmp    %eax,%ebx
f0100932:	7f 1f                	jg     f0100953 <stab_binsearch+0x69>
f0100934:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100938:	83 ea 0c             	sub    $0xc,%edx
f010093b:	39 f9                	cmp    %edi,%ecx
f010093d:	75 ee                	jne    f010092d <stab_binsearch+0x43>
f010093f:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100942:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100945:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100948:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010094c:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010094f:	76 18                	jbe    f0100969 <stab_binsearch+0x7f>
f0100951:	eb 05                	jmp    f0100958 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100953:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100956:	eb 42                	jmp    f010099a <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100958:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010095b:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010095d:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100960:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100967:	eb 31                	jmp    f010099a <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100969:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010096c:	73 17                	jae    f0100985 <stab_binsearch+0x9b>
			*region_right = m - 1;
f010096e:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100971:	83 e8 01             	sub    $0x1,%eax
f0100974:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100977:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010097a:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010097c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100983:	eb 15                	jmp    f010099a <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100985:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100988:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f010098b:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f010098d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100991:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100993:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010099a:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010099d:	0f 8e 6f ff ff ff    	jle    f0100912 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01009a3:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01009a7:	75 0f                	jne    f01009b8 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f01009a9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009ac:	8b 00                	mov    (%eax),%eax
f01009ae:	83 e8 01             	sub    $0x1,%eax
f01009b1:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01009b4:	89 06                	mov    %eax,(%esi)
f01009b6:	eb 2c                	jmp    f01009e4 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009b8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009bb:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01009bd:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01009c0:	8b 0e                	mov    (%esi),%ecx
f01009c2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01009c5:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01009c8:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009cb:	eb 03                	jmp    f01009d0 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01009cd:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009d0:	39 c8                	cmp    %ecx,%eax
f01009d2:	7e 0b                	jle    f01009df <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f01009d4:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01009d8:	83 ea 0c             	sub    $0xc,%edx
f01009db:	39 fb                	cmp    %edi,%ebx
f01009dd:	75 ee                	jne    f01009cd <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f01009df:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01009e2:	89 06                	mov    %eax,(%esi)
	}
}
f01009e4:	83 c4 14             	add    $0x14,%esp
f01009e7:	5b                   	pop    %ebx
f01009e8:	5e                   	pop    %esi
f01009e9:	5f                   	pop    %edi
f01009ea:	5d                   	pop    %ebp
f01009eb:	c3                   	ret    

f01009ec <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01009ec:	55                   	push   %ebp
f01009ed:	89 e5                	mov    %esp,%ebp
f01009ef:	57                   	push   %edi
f01009f0:	56                   	push   %esi
f01009f1:	53                   	push   %ebx
f01009f2:	83 ec 1c             	sub    $0x1c,%esp
f01009f5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01009f8:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01009fb:	c7 06 7c 1d 10 f0    	movl   $0xf0101d7c,(%esi)
	info->eip_line = 0;
f0100a01:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100a08:	c7 46 08 7c 1d 10 f0 	movl   $0xf0101d7c,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100a0f:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100a16:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100a19:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a20:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100a26:	76 11                	jbe    f0100a39 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a28:	b8 bf 70 10 f0       	mov    $0xf01070bf,%eax
f0100a2d:	3d 35 58 10 f0       	cmp    $0xf0105835,%eax
f0100a32:	77 19                	ja     f0100a4d <debuginfo_eip+0x61>
f0100a34:	e9 4c 01 00 00       	jmp    f0100b85 <debuginfo_eip+0x199>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a39:	83 ec 04             	sub    $0x4,%esp
f0100a3c:	68 86 1d 10 f0       	push   $0xf0101d86
f0100a41:	6a 7f                	push   $0x7f
f0100a43:	68 93 1d 10 f0       	push   $0xf0101d93
f0100a48:	e8 99 f6 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a4d:	80 3d be 70 10 f0 00 	cmpb   $0x0,0xf01070be
f0100a54:	0f 85 32 01 00 00    	jne    f0100b8c <debuginfo_eip+0x1a0>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a5a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100a61:	b8 34 58 10 f0       	mov    $0xf0105834,%eax
f0100a66:	2d d0 1f 10 f0       	sub    $0xf0101fd0,%eax
f0100a6b:	c1 f8 02             	sar    $0x2,%eax
f0100a6e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100a74:	83 e8 01             	sub    $0x1,%eax
f0100a77:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100a7a:	83 ec 08             	sub    $0x8,%esp
f0100a7d:	57                   	push   %edi
f0100a7e:	6a 64                	push   $0x64
f0100a80:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100a83:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100a86:	b8 d0 1f 10 f0       	mov    $0xf0101fd0,%eax
f0100a8b:	e8 5a fe ff ff       	call   f01008ea <stab_binsearch>
	if (lfile == 0)
f0100a90:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a93:	83 c4 10             	add    $0x10,%esp
f0100a96:	85 c0                	test   %eax,%eax
f0100a98:	0f 84 f5 00 00 00    	je     f0100b93 <debuginfo_eip+0x1a7>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100a9e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100aa1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100aa4:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100aa7:	83 ec 08             	sub    $0x8,%esp
f0100aaa:	57                   	push   %edi
f0100aab:	6a 24                	push   $0x24
f0100aad:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100ab0:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ab3:	b8 d0 1f 10 f0       	mov    $0xf0101fd0,%eax
f0100ab8:	e8 2d fe ff ff       	call   f01008ea <stab_binsearch>

	if (lfun <= rfun) {
f0100abd:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100ac0:	83 c4 10             	add    $0x10,%esp
f0100ac3:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100ac6:	7f 31                	jg     f0100af9 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100ac8:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100acb:	c1 e0 02             	shl    $0x2,%eax
f0100ace:	8d 90 d0 1f 10 f0    	lea    -0xfefe030(%eax),%edx
f0100ad4:	8b 88 d0 1f 10 f0    	mov    -0xfefe030(%eax),%ecx
f0100ada:	b8 bf 70 10 f0       	mov    $0xf01070bf,%eax
f0100adf:	2d 35 58 10 f0       	sub    $0xf0105835,%eax
f0100ae4:	39 c1                	cmp    %eax,%ecx
f0100ae6:	73 09                	jae    f0100af1 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100ae8:	81 c1 35 58 10 f0    	add    $0xf0105835,%ecx
f0100aee:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100af1:	8b 42 08             	mov    0x8(%edx),%eax
f0100af4:	89 46 10             	mov    %eax,0x10(%esi)
f0100af7:	eb 06                	jmp    f0100aff <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100af9:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100afc:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100aff:	83 ec 08             	sub    $0x8,%esp
f0100b02:	6a 3a                	push   $0x3a
f0100b04:	ff 76 08             	pushl  0x8(%esi)
f0100b07:	e8 99 08 00 00       	call   f01013a5 <strfind>
f0100b0c:	2b 46 08             	sub    0x8(%esi),%eax
f0100b0f:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b12:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b15:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b18:	8d 04 85 d0 1f 10 f0 	lea    -0xfefe030(,%eax,4),%eax
f0100b1f:	83 c4 10             	add    $0x10,%esp
f0100b22:	eb 06                	jmp    f0100b2a <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b24:	83 eb 01             	sub    $0x1,%ebx
f0100b27:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b2a:	39 fb                	cmp    %edi,%ebx
f0100b2c:	7c 1e                	jl     f0100b4c <debuginfo_eip+0x160>
	       && stabs[lline].n_type != N_SOL
f0100b2e:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100b32:	80 fa 84             	cmp    $0x84,%dl
f0100b35:	74 6a                	je     f0100ba1 <debuginfo_eip+0x1b5>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b37:	80 fa 64             	cmp    $0x64,%dl
f0100b3a:	75 e8                	jne    f0100b24 <debuginfo_eip+0x138>
f0100b3c:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100b40:	74 e2                	je     f0100b24 <debuginfo_eip+0x138>
f0100b42:	eb 5d                	jmp    f0100ba1 <debuginfo_eip+0x1b5>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100b44:	81 c2 35 58 10 f0    	add    $0xf0105835,%edx
f0100b4a:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b4c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100b4f:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b52:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b57:	39 cb                	cmp    %ecx,%ebx
f0100b59:	7d 60                	jge    f0100bbb <debuginfo_eip+0x1cf>
		for (lline = lfun + 1;
f0100b5b:	8d 53 01             	lea    0x1(%ebx),%edx
f0100b5e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b61:	8d 04 85 d0 1f 10 f0 	lea    -0xfefe030(,%eax,4),%eax
f0100b68:	eb 07                	jmp    f0100b71 <debuginfo_eip+0x185>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100b6a:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100b6e:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100b71:	39 ca                	cmp    %ecx,%edx
f0100b73:	74 25                	je     f0100b9a <debuginfo_eip+0x1ae>
f0100b75:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100b78:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100b7c:	74 ec                	je     f0100b6a <debuginfo_eip+0x17e>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b7e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b83:	eb 36                	jmp    f0100bbb <debuginfo_eip+0x1cf>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100b85:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b8a:	eb 2f                	jmp    f0100bbb <debuginfo_eip+0x1cf>
f0100b8c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b91:	eb 28                	jmp    f0100bbb <debuginfo_eip+0x1cf>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100b93:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b98:	eb 21                	jmp    f0100bbb <debuginfo_eip+0x1cf>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b9a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b9f:	eb 1a                	jmp    f0100bbb <debuginfo_eip+0x1cf>
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100ba1:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100ba4:	8b 14 85 d0 1f 10 f0 	mov    -0xfefe030(,%eax,4),%edx
f0100bab:	b8 bf 70 10 f0       	mov    $0xf01070bf,%eax
f0100bb0:	2d 35 58 10 f0       	sub    $0xf0105835,%eax
f0100bb5:	39 c2                	cmp    %eax,%edx
f0100bb7:	72 8b                	jb     f0100b44 <debuginfo_eip+0x158>
f0100bb9:	eb 91                	jmp    f0100b4c <debuginfo_eip+0x160>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f0100bbb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100bbe:	5b                   	pop    %ebx
f0100bbf:	5e                   	pop    %esi
f0100bc0:	5f                   	pop    %edi
f0100bc1:	5d                   	pop    %ebp
f0100bc2:	c3                   	ret    

f0100bc3 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100bc3:	55                   	push   %ebp
f0100bc4:	89 e5                	mov    %esp,%ebp
f0100bc6:	57                   	push   %edi
f0100bc7:	56                   	push   %esi
f0100bc8:	53                   	push   %ebx
f0100bc9:	83 ec 1c             	sub    $0x1c,%esp
f0100bcc:	89 c7                	mov    %eax,%edi
f0100bce:	89 d6                	mov    %edx,%esi
f0100bd0:	8b 45 08             	mov    0x8(%ebp),%eax
f0100bd3:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100bd6:	89 d1                	mov    %edx,%ecx
f0100bd8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100bdb:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100bde:	8b 45 10             	mov    0x10(%ebp),%eax
f0100be1:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100be4:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100be7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100bee:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f0100bf1:	72 05                	jb     f0100bf8 <printnum+0x35>
f0100bf3:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100bf6:	77 3e                	ja     f0100c36 <printnum+0x73>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100bf8:	83 ec 0c             	sub    $0xc,%esp
f0100bfb:	ff 75 18             	pushl  0x18(%ebp)
f0100bfe:	83 eb 01             	sub    $0x1,%ebx
f0100c01:	53                   	push   %ebx
f0100c02:	50                   	push   %eax
f0100c03:	83 ec 08             	sub    $0x8,%esp
f0100c06:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c09:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c0c:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c0f:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c12:	e8 b9 09 00 00       	call   f01015d0 <__udivdi3>
f0100c17:	83 c4 18             	add    $0x18,%esp
f0100c1a:	52                   	push   %edx
f0100c1b:	50                   	push   %eax
f0100c1c:	89 f2                	mov    %esi,%edx
f0100c1e:	89 f8                	mov    %edi,%eax
f0100c20:	e8 9e ff ff ff       	call   f0100bc3 <printnum>
f0100c25:	83 c4 20             	add    $0x20,%esp
f0100c28:	eb 13                	jmp    f0100c3d <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100c2a:	83 ec 08             	sub    $0x8,%esp
f0100c2d:	56                   	push   %esi
f0100c2e:	ff 75 18             	pushl  0x18(%ebp)
f0100c31:	ff d7                	call   *%edi
f0100c33:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c36:	83 eb 01             	sub    $0x1,%ebx
f0100c39:	85 db                	test   %ebx,%ebx
f0100c3b:	7f ed                	jg     f0100c2a <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100c3d:	83 ec 08             	sub    $0x8,%esp
f0100c40:	56                   	push   %esi
f0100c41:	83 ec 04             	sub    $0x4,%esp
f0100c44:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c47:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c4a:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c4d:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c50:	e8 ab 0a 00 00       	call   f0101700 <__umoddi3>
f0100c55:	83 c4 14             	add    $0x14,%esp
f0100c58:	0f be 80 a1 1d 10 f0 	movsbl -0xfefe25f(%eax),%eax
f0100c5f:	50                   	push   %eax
f0100c60:	ff d7                	call   *%edi
f0100c62:	83 c4 10             	add    $0x10,%esp
}
f0100c65:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c68:	5b                   	pop    %ebx
f0100c69:	5e                   	pop    %esi
f0100c6a:	5f                   	pop    %edi
f0100c6b:	5d                   	pop    %ebp
f0100c6c:	c3                   	ret    

f0100c6d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100c6d:	55                   	push   %ebp
f0100c6e:	89 e5                	mov    %esp,%ebp
f0100c70:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100c73:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100c77:	8b 10                	mov    (%eax),%edx
f0100c79:	3b 50 04             	cmp    0x4(%eax),%edx
f0100c7c:	73 0a                	jae    f0100c88 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100c7e:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100c81:	89 08                	mov    %ecx,(%eax)
f0100c83:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c86:	88 02                	mov    %al,(%edx)
}
f0100c88:	5d                   	pop    %ebp
f0100c89:	c3                   	ret    

f0100c8a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100c8a:	55                   	push   %ebp
f0100c8b:	89 e5                	mov    %esp,%ebp
f0100c8d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100c90:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100c93:	50                   	push   %eax
f0100c94:	ff 75 10             	pushl  0x10(%ebp)
f0100c97:	ff 75 0c             	pushl  0xc(%ebp)
f0100c9a:	ff 75 08             	pushl  0x8(%ebp)
f0100c9d:	e8 05 00 00 00       	call   f0100ca7 <vprintfmt>
	va_end(ap);
f0100ca2:	83 c4 10             	add    $0x10,%esp
}
f0100ca5:	c9                   	leave  
f0100ca6:	c3                   	ret    

f0100ca7 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100ca7:	55                   	push   %ebp
f0100ca8:	89 e5                	mov    %esp,%ebp
f0100caa:	57                   	push   %edi
f0100cab:	56                   	push   %esi
f0100cac:	53                   	push   %ebx
f0100cad:	83 ec 2c             	sub    $0x2c,%esp
f0100cb0:	8b 75 08             	mov    0x8(%ebp),%esi
f0100cb3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100cb6:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100cb9:	eb 12                	jmp    f0100ccd <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100cbb:	85 c0                	test   %eax,%eax
f0100cbd:	0f 84 37 04 00 00    	je     f01010fa <vprintfmt+0x453>
				return;
			putch(ch, putdat);
f0100cc3:	83 ec 08             	sub    $0x8,%esp
f0100cc6:	53                   	push   %ebx
f0100cc7:	50                   	push   %eax
f0100cc8:	ff d6                	call   *%esi
f0100cca:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ccd:	83 c7 01             	add    $0x1,%edi
f0100cd0:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100cd4:	83 f8 25             	cmp    $0x25,%eax
f0100cd7:	75 e2                	jne    f0100cbb <vprintfmt+0x14>
f0100cd9:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100cdd:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100ce4:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100ceb:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100cf2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100cf7:	eb 07                	jmp    f0100d00 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100cf9:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100cfc:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d00:	8d 47 01             	lea    0x1(%edi),%eax
f0100d03:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d06:	0f b6 07             	movzbl (%edi),%eax
f0100d09:	0f b6 d0             	movzbl %al,%edx
f0100d0c:	83 e8 23             	sub    $0x23,%eax
f0100d0f:	3c 55                	cmp    $0x55,%al
f0100d11:	0f 87 c8 03 00 00    	ja     f01010df <vprintfmt+0x438>
f0100d17:	0f b6 c0             	movzbl %al,%eax
f0100d1a:	ff 24 85 40 1e 10 f0 	jmp    *-0xfefe1c0(,%eax,4)
f0100d21:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100d24:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100d28:	eb d6                	jmp    f0100d00 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d2a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d2d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d32:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100d35:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100d38:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100d3c:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100d3f:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100d42:	83 f9 09             	cmp    $0x9,%ecx
f0100d45:	77 3f                	ja     f0100d86 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100d47:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100d4a:	eb e9                	jmp    f0100d35 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100d4c:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d4f:	8b 00                	mov    (%eax),%eax
f0100d51:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100d54:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d57:	8d 40 04             	lea    0x4(%eax),%eax
f0100d5a:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d5d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100d60:	eb 2a                	jmp    f0100d8c <vprintfmt+0xe5>
f0100d62:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d65:	85 c0                	test   %eax,%eax
f0100d67:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d6c:	0f 49 d0             	cmovns %eax,%edx
f0100d6f:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d72:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d75:	eb 89                	jmp    f0100d00 <vprintfmt+0x59>
f0100d77:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100d7a:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100d81:	e9 7a ff ff ff       	jmp    f0100d00 <vprintfmt+0x59>
f0100d86:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d89:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100d8c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100d90:	0f 89 6a ff ff ff    	jns    f0100d00 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100d96:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100d99:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d9c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100da3:	e9 58 ff ff ff       	jmp    f0100d00 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100da8:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100dae:	e9 4d ff ff ff       	jmp    f0100d00 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100db3:	8b 45 14             	mov    0x14(%ebp),%eax
f0100db6:	8d 78 04             	lea    0x4(%eax),%edi
f0100db9:	83 ec 08             	sub    $0x8,%esp
f0100dbc:	53                   	push   %ebx
f0100dbd:	ff 30                	pushl  (%eax)
f0100dbf:	ff d6                	call   *%esi
			break;
f0100dc1:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100dc4:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dc7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100dca:	e9 fe fe ff ff       	jmp    f0100ccd <vprintfmt+0x26>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dcf:	8b 45 14             	mov    0x14(%ebp),%eax
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100dd2:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100dd6:	8b 00                	mov    (%eax),%eax
f0100dd8:	99                   	cltd   
f0100dd9:	31 d0                	xor    %edx,%eax
f0100ddb:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100ddd:	83 f8 07             	cmp    $0x7,%eax
f0100de0:	7f 0b                	jg     f0100ded <vprintfmt+0x146>
f0100de2:	8b 14 85 a0 1f 10 f0 	mov    -0xfefe060(,%eax,4),%edx
f0100de9:	85 d2                	test   %edx,%edx
f0100deb:	75 18                	jne    f0100e05 <vprintfmt+0x15e>
				printfmt(putch, putdat, "error %d", err);
f0100ded:	50                   	push   %eax
f0100dee:	68 b9 1d 10 f0       	push   $0xf0101db9
f0100df3:	53                   	push   %ebx
f0100df4:	56                   	push   %esi
f0100df5:	e8 90 fe ff ff       	call   f0100c8a <printfmt>
f0100dfa:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dfd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100e00:	e9 c8 fe ff ff       	jmp    f0100ccd <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100e05:	52                   	push   %edx
f0100e06:	68 c2 1d 10 f0       	push   $0xf0101dc2
f0100e0b:	53                   	push   %ebx
f0100e0c:	56                   	push   %esi
f0100e0d:	e8 78 fe ff ff       	call   f0100c8a <printfmt>
f0100e12:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e15:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e18:	e9 b0 fe ff ff       	jmp    f0100ccd <vprintfmt+0x26>
f0100e1d:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e20:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100e23:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100e26:	89 4d cc             	mov    %ecx,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100e29:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100e2d:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100e2f:	85 ff                	test   %edi,%edi
f0100e31:	b8 b2 1d 10 f0       	mov    $0xf0101db2,%eax
f0100e36:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100e39:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100e3d:	0f 84 90 00 00 00    	je     f0100ed3 <vprintfmt+0x22c>
f0100e43:	85 c9                	test   %ecx,%ecx
f0100e45:	0f 8e 96 00 00 00    	jle    f0100ee1 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e4b:	83 ec 08             	sub    $0x8,%esp
f0100e4e:	52                   	push   %edx
f0100e4f:	57                   	push   %edi
f0100e50:	e8 06 04 00 00       	call   f010125b <strnlen>
f0100e55:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100e58:	29 c1                	sub    %eax,%ecx
f0100e5a:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100e5d:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100e60:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100e64:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e67:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100e6a:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e6c:	eb 0f                	jmp    f0100e7d <vprintfmt+0x1d6>
					putch(padc, putdat);
f0100e6e:	83 ec 08             	sub    $0x8,%esp
f0100e71:	53                   	push   %ebx
f0100e72:	ff 75 e0             	pushl  -0x20(%ebp)
f0100e75:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e77:	83 ef 01             	sub    $0x1,%edi
f0100e7a:	83 c4 10             	add    $0x10,%esp
f0100e7d:	85 ff                	test   %edi,%edi
f0100e7f:	7f ed                	jg     f0100e6e <vprintfmt+0x1c7>
f0100e81:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100e84:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100e87:	85 c9                	test   %ecx,%ecx
f0100e89:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e8e:	0f 49 c1             	cmovns %ecx,%eax
f0100e91:	29 c1                	sub    %eax,%ecx
f0100e93:	89 75 08             	mov    %esi,0x8(%ebp)
f0100e96:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100e99:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100e9c:	89 cb                	mov    %ecx,%ebx
f0100e9e:	eb 4d                	jmp    f0100eed <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100ea0:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100ea4:	74 1b                	je     f0100ec1 <vprintfmt+0x21a>
f0100ea6:	0f be c0             	movsbl %al,%eax
f0100ea9:	83 e8 20             	sub    $0x20,%eax
f0100eac:	83 f8 5e             	cmp    $0x5e,%eax
f0100eaf:	76 10                	jbe    f0100ec1 <vprintfmt+0x21a>
					putch('?', putdat);
f0100eb1:	83 ec 08             	sub    $0x8,%esp
f0100eb4:	ff 75 0c             	pushl  0xc(%ebp)
f0100eb7:	6a 3f                	push   $0x3f
f0100eb9:	ff 55 08             	call   *0x8(%ebp)
f0100ebc:	83 c4 10             	add    $0x10,%esp
f0100ebf:	eb 0d                	jmp    f0100ece <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0100ec1:	83 ec 08             	sub    $0x8,%esp
f0100ec4:	ff 75 0c             	pushl  0xc(%ebp)
f0100ec7:	52                   	push   %edx
f0100ec8:	ff 55 08             	call   *0x8(%ebp)
f0100ecb:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100ece:	83 eb 01             	sub    $0x1,%ebx
f0100ed1:	eb 1a                	jmp    f0100eed <vprintfmt+0x246>
f0100ed3:	89 75 08             	mov    %esi,0x8(%ebp)
f0100ed6:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100ed9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100edc:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100edf:	eb 0c                	jmp    f0100eed <vprintfmt+0x246>
f0100ee1:	89 75 08             	mov    %esi,0x8(%ebp)
f0100ee4:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100ee7:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100eea:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100eed:	83 c7 01             	add    $0x1,%edi
f0100ef0:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100ef4:	0f be d0             	movsbl %al,%edx
f0100ef7:	85 d2                	test   %edx,%edx
f0100ef9:	74 23                	je     f0100f1e <vprintfmt+0x277>
f0100efb:	85 f6                	test   %esi,%esi
f0100efd:	78 a1                	js     f0100ea0 <vprintfmt+0x1f9>
f0100eff:	83 ee 01             	sub    $0x1,%esi
f0100f02:	79 9c                	jns    f0100ea0 <vprintfmt+0x1f9>
f0100f04:	89 df                	mov    %ebx,%edi
f0100f06:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f09:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f0c:	eb 18                	jmp    f0100f26 <vprintfmt+0x27f>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100f0e:	83 ec 08             	sub    $0x8,%esp
f0100f11:	53                   	push   %ebx
f0100f12:	6a 20                	push   $0x20
f0100f14:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100f16:	83 ef 01             	sub    $0x1,%edi
f0100f19:	83 c4 10             	add    $0x10,%esp
f0100f1c:	eb 08                	jmp    f0100f26 <vprintfmt+0x27f>
f0100f1e:	89 df                	mov    %ebx,%edi
f0100f20:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f23:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f26:	85 ff                	test   %edi,%edi
f0100f28:	7f e4                	jg     f0100f0e <vprintfmt+0x267>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f2a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f2d:	e9 9b fd ff ff       	jmp    f0100ccd <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100f32:	83 f9 01             	cmp    $0x1,%ecx
f0100f35:	7e 19                	jle    f0100f50 <vprintfmt+0x2a9>
		return va_arg(*ap, long long);
f0100f37:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f3a:	8b 50 04             	mov    0x4(%eax),%edx
f0100f3d:	8b 00                	mov    (%eax),%eax
f0100f3f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f42:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100f45:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f48:	8d 40 08             	lea    0x8(%eax),%eax
f0100f4b:	89 45 14             	mov    %eax,0x14(%ebp)
f0100f4e:	eb 38                	jmp    f0100f88 <vprintfmt+0x2e1>
	else if (lflag)
f0100f50:	85 c9                	test   %ecx,%ecx
f0100f52:	74 1b                	je     f0100f6f <vprintfmt+0x2c8>
		return va_arg(*ap, long);
f0100f54:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f57:	8b 00                	mov    (%eax),%eax
f0100f59:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f5c:	89 c1                	mov    %eax,%ecx
f0100f5e:	c1 f9 1f             	sar    $0x1f,%ecx
f0100f61:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100f64:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f67:	8d 40 04             	lea    0x4(%eax),%eax
f0100f6a:	89 45 14             	mov    %eax,0x14(%ebp)
f0100f6d:	eb 19                	jmp    f0100f88 <vprintfmt+0x2e1>
	else
		return va_arg(*ap, int);
f0100f6f:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f72:	8b 00                	mov    (%eax),%eax
f0100f74:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f77:	89 c1                	mov    %eax,%ecx
f0100f79:	c1 f9 1f             	sar    $0x1f,%ecx
f0100f7c:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100f7f:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f82:	8d 40 04             	lea    0x4(%eax),%eax
f0100f85:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0100f88:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100f8b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0100f8e:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0100f93:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100f97:	0f 89 0e 01 00 00    	jns    f01010ab <vprintfmt+0x404>
				putch('-', putdat);
f0100f9d:	83 ec 08             	sub    $0x8,%esp
f0100fa0:	53                   	push   %ebx
f0100fa1:	6a 2d                	push   $0x2d
f0100fa3:	ff d6                	call   *%esi
				num = -(long long) num;
f0100fa5:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100fa8:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100fab:	f7 da                	neg    %edx
f0100fad:	83 d1 00             	adc    $0x0,%ecx
f0100fb0:	f7 d9                	neg    %ecx
f0100fb2:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0100fb5:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100fba:	e9 ec 00 00 00       	jmp    f01010ab <vprintfmt+0x404>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100fbf:	83 f9 01             	cmp    $0x1,%ecx
f0100fc2:	7e 18                	jle    f0100fdc <vprintfmt+0x335>
		return va_arg(*ap, unsigned long long);
f0100fc4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fc7:	8b 10                	mov    (%eax),%edx
f0100fc9:	8b 48 04             	mov    0x4(%eax),%ecx
f0100fcc:	8d 40 08             	lea    0x8(%eax),%eax
f0100fcf:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0100fd2:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100fd7:	e9 cf 00 00 00       	jmp    f01010ab <vprintfmt+0x404>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0100fdc:	85 c9                	test   %ecx,%ecx
f0100fde:	74 1a                	je     f0100ffa <vprintfmt+0x353>
		return va_arg(*ap, unsigned long);
f0100fe0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fe3:	8b 10                	mov    (%eax),%edx
f0100fe5:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100fea:	8d 40 04             	lea    0x4(%eax),%eax
f0100fed:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0100ff0:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100ff5:	e9 b1 00 00 00       	jmp    f01010ab <vprintfmt+0x404>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0100ffa:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ffd:	8b 10                	mov    (%eax),%edx
f0100fff:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101004:	8d 40 04             	lea    0x4(%eax),%eax
f0101007:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010100a:	b8 0a 00 00 00       	mov    $0xa,%eax
f010100f:	e9 97 00 00 00       	jmp    f01010ab <vprintfmt+0x404>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0101014:	83 ec 08             	sub    $0x8,%esp
f0101017:	53                   	push   %ebx
f0101018:	6a 58                	push   $0x58
f010101a:	ff d6                	call   *%esi
			putch('X', putdat);
f010101c:	83 c4 08             	add    $0x8,%esp
f010101f:	53                   	push   %ebx
f0101020:	6a 58                	push   $0x58
f0101022:	ff d6                	call   *%esi
			putch('X', putdat);
f0101024:	83 c4 08             	add    $0x8,%esp
f0101027:	53                   	push   %ebx
f0101028:	6a 58                	push   $0x58
f010102a:	ff d6                	call   *%esi
			break;
f010102c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010102f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0101032:	e9 96 fc ff ff       	jmp    f0100ccd <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0101037:	83 ec 08             	sub    $0x8,%esp
f010103a:	53                   	push   %ebx
f010103b:	6a 30                	push   $0x30
f010103d:	ff d6                	call   *%esi
			putch('x', putdat);
f010103f:	83 c4 08             	add    $0x8,%esp
f0101042:	53                   	push   %ebx
f0101043:	6a 78                	push   $0x78
f0101045:	ff d6                	call   *%esi
			num = (unsigned long long)
f0101047:	8b 45 14             	mov    0x14(%ebp),%eax
f010104a:	8b 10                	mov    (%eax),%edx
f010104c:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101051:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101054:	8d 40 04             	lea    0x4(%eax),%eax
f0101057:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010105a:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f010105f:	eb 4a                	jmp    f01010ab <vprintfmt+0x404>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101061:	83 f9 01             	cmp    $0x1,%ecx
f0101064:	7e 15                	jle    f010107b <vprintfmt+0x3d4>
		return va_arg(*ap, unsigned long long);
f0101066:	8b 45 14             	mov    0x14(%ebp),%eax
f0101069:	8b 10                	mov    (%eax),%edx
f010106b:	8b 48 04             	mov    0x4(%eax),%ecx
f010106e:	8d 40 08             	lea    0x8(%eax),%eax
f0101071:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101074:	b8 10 00 00 00       	mov    $0x10,%eax
f0101079:	eb 30                	jmp    f01010ab <vprintfmt+0x404>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f010107b:	85 c9                	test   %ecx,%ecx
f010107d:	74 17                	je     f0101096 <vprintfmt+0x3ef>
		return va_arg(*ap, unsigned long);
f010107f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101082:	8b 10                	mov    (%eax),%edx
f0101084:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101089:	8d 40 04             	lea    0x4(%eax),%eax
f010108c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010108f:	b8 10 00 00 00       	mov    $0x10,%eax
f0101094:	eb 15                	jmp    f01010ab <vprintfmt+0x404>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0101096:	8b 45 14             	mov    0x14(%ebp),%eax
f0101099:	8b 10                	mov    (%eax),%edx
f010109b:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010a0:	8d 40 04             	lea    0x4(%eax),%eax
f01010a3:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01010a6:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01010ab:	83 ec 0c             	sub    $0xc,%esp
f01010ae:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01010b2:	57                   	push   %edi
f01010b3:	ff 75 e0             	pushl  -0x20(%ebp)
f01010b6:	50                   	push   %eax
f01010b7:	51                   	push   %ecx
f01010b8:	52                   	push   %edx
f01010b9:	89 da                	mov    %ebx,%edx
f01010bb:	89 f0                	mov    %esi,%eax
f01010bd:	e8 01 fb ff ff       	call   f0100bc3 <printnum>
			break;
f01010c2:	83 c4 20             	add    $0x20,%esp
f01010c5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01010c8:	e9 00 fc ff ff       	jmp    f0100ccd <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01010cd:	83 ec 08             	sub    $0x8,%esp
f01010d0:	53                   	push   %ebx
f01010d1:	52                   	push   %edx
f01010d2:	ff d6                	call   *%esi
			break;
f01010d4:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010d7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01010da:	e9 ee fb ff ff       	jmp    f0100ccd <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01010df:	83 ec 08             	sub    $0x8,%esp
f01010e2:	53                   	push   %ebx
f01010e3:	6a 25                	push   $0x25
f01010e5:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01010e7:	83 c4 10             	add    $0x10,%esp
f01010ea:	eb 03                	jmp    f01010ef <vprintfmt+0x448>
f01010ec:	83 ef 01             	sub    $0x1,%edi
f01010ef:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01010f3:	75 f7                	jne    f01010ec <vprintfmt+0x445>
f01010f5:	e9 d3 fb ff ff       	jmp    f0100ccd <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01010fa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010fd:	5b                   	pop    %ebx
f01010fe:	5e                   	pop    %esi
f01010ff:	5f                   	pop    %edi
f0101100:	5d                   	pop    %ebp
f0101101:	c3                   	ret    

f0101102 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101102:	55                   	push   %ebp
f0101103:	89 e5                	mov    %esp,%ebp
f0101105:	83 ec 18             	sub    $0x18,%esp
f0101108:	8b 45 08             	mov    0x8(%ebp),%eax
f010110b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010110e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101111:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101115:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101118:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010111f:	85 c0                	test   %eax,%eax
f0101121:	74 26                	je     f0101149 <vsnprintf+0x47>
f0101123:	85 d2                	test   %edx,%edx
f0101125:	7e 22                	jle    f0101149 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101127:	ff 75 14             	pushl  0x14(%ebp)
f010112a:	ff 75 10             	pushl  0x10(%ebp)
f010112d:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101130:	50                   	push   %eax
f0101131:	68 6d 0c 10 f0       	push   $0xf0100c6d
f0101136:	e8 6c fb ff ff       	call   f0100ca7 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010113b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010113e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101141:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101144:	83 c4 10             	add    $0x10,%esp
f0101147:	eb 05                	jmp    f010114e <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101149:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010114e:	c9                   	leave  
f010114f:	c3                   	ret    

f0101150 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101150:	55                   	push   %ebp
f0101151:	89 e5                	mov    %esp,%ebp
f0101153:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101156:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101159:	50                   	push   %eax
f010115a:	ff 75 10             	pushl  0x10(%ebp)
f010115d:	ff 75 0c             	pushl  0xc(%ebp)
f0101160:	ff 75 08             	pushl  0x8(%ebp)
f0101163:	e8 9a ff ff ff       	call   f0101102 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101168:	c9                   	leave  
f0101169:	c3                   	ret    

f010116a <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010116a:	55                   	push   %ebp
f010116b:	89 e5                	mov    %esp,%ebp
f010116d:	57                   	push   %edi
f010116e:	56                   	push   %esi
f010116f:	53                   	push   %ebx
f0101170:	83 ec 0c             	sub    $0xc,%esp
f0101173:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101176:	85 c0                	test   %eax,%eax
f0101178:	74 11                	je     f010118b <readline+0x21>
		cprintf("%s", prompt);
f010117a:	83 ec 08             	sub    $0x8,%esp
f010117d:	50                   	push   %eax
f010117e:	68 c2 1d 10 f0       	push   $0xf0101dc2
f0101183:	e8 4e f7 ff ff       	call   f01008d6 <cprintf>
f0101188:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010118b:	83 ec 0c             	sub    $0xc,%esp
f010118e:	6a 00                	push   $0x0
f0101190:	e8 c7 f4 ff ff       	call   f010065c <iscons>
f0101195:	89 c7                	mov    %eax,%edi
f0101197:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010119a:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010119f:	e8 a7 f4 ff ff       	call   f010064b <getchar>
f01011a4:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01011a6:	85 c0                	test   %eax,%eax
f01011a8:	79 18                	jns    f01011c2 <readline+0x58>
			cprintf("read error: %e\n", c);
f01011aa:	83 ec 08             	sub    $0x8,%esp
f01011ad:	50                   	push   %eax
f01011ae:	68 c0 1f 10 f0       	push   $0xf0101fc0
f01011b3:	e8 1e f7 ff ff       	call   f01008d6 <cprintf>
			return NULL;
f01011b8:	83 c4 10             	add    $0x10,%esp
f01011bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01011c0:	eb 79                	jmp    f010123b <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01011c2:	83 f8 7f             	cmp    $0x7f,%eax
f01011c5:	0f 94 c2             	sete   %dl
f01011c8:	83 f8 08             	cmp    $0x8,%eax
f01011cb:	0f 94 c0             	sete   %al
f01011ce:	08 c2                	or     %al,%dl
f01011d0:	74 1a                	je     f01011ec <readline+0x82>
f01011d2:	85 f6                	test   %esi,%esi
f01011d4:	7e 16                	jle    f01011ec <readline+0x82>
			if (echoing)
f01011d6:	85 ff                	test   %edi,%edi
f01011d8:	74 0d                	je     f01011e7 <readline+0x7d>
				cputchar('\b');
f01011da:	83 ec 0c             	sub    $0xc,%esp
f01011dd:	6a 08                	push   $0x8
f01011df:	e8 57 f4 ff ff       	call   f010063b <cputchar>
f01011e4:	83 c4 10             	add    $0x10,%esp
			i--;
f01011e7:	83 ee 01             	sub    $0x1,%esi
f01011ea:	eb b3                	jmp    f010119f <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01011ec:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01011f2:	7f 20                	jg     f0101214 <readline+0xaa>
f01011f4:	83 fb 1f             	cmp    $0x1f,%ebx
f01011f7:	7e 1b                	jle    f0101214 <readline+0xaa>
			if (echoing)
f01011f9:	85 ff                	test   %edi,%edi
f01011fb:	74 0c                	je     f0101209 <readline+0x9f>
				cputchar(c);
f01011fd:	83 ec 0c             	sub    $0xc,%esp
f0101200:	53                   	push   %ebx
f0101201:	e8 35 f4 ff ff       	call   f010063b <cputchar>
f0101206:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101209:	88 9e 80 25 11 f0    	mov    %bl,-0xfeeda80(%esi)
f010120f:	8d 76 01             	lea    0x1(%esi),%esi
f0101212:	eb 8b                	jmp    f010119f <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101214:	83 fb 0d             	cmp    $0xd,%ebx
f0101217:	74 05                	je     f010121e <readline+0xb4>
f0101219:	83 fb 0a             	cmp    $0xa,%ebx
f010121c:	75 81                	jne    f010119f <readline+0x35>
			if (echoing)
f010121e:	85 ff                	test   %edi,%edi
f0101220:	74 0d                	je     f010122f <readline+0xc5>
				cputchar('\n');
f0101222:	83 ec 0c             	sub    $0xc,%esp
f0101225:	6a 0a                	push   $0xa
f0101227:	e8 0f f4 ff ff       	call   f010063b <cputchar>
f010122c:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010122f:	c6 86 80 25 11 f0 00 	movb   $0x0,-0xfeeda80(%esi)
			return buf;
f0101236:	b8 80 25 11 f0       	mov    $0xf0112580,%eax
		}
	}
}
f010123b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010123e:	5b                   	pop    %ebx
f010123f:	5e                   	pop    %esi
f0101240:	5f                   	pop    %edi
f0101241:	5d                   	pop    %ebp
f0101242:	c3                   	ret    

f0101243 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101243:	55                   	push   %ebp
f0101244:	89 e5                	mov    %esp,%ebp
f0101246:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101249:	b8 00 00 00 00       	mov    $0x0,%eax
f010124e:	eb 03                	jmp    f0101253 <strlen+0x10>
		n++;
f0101250:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101253:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101257:	75 f7                	jne    f0101250 <strlen+0xd>
		n++;
	return n;
}
f0101259:	5d                   	pop    %ebp
f010125a:	c3                   	ret    

f010125b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010125b:	55                   	push   %ebp
f010125c:	89 e5                	mov    %esp,%ebp
f010125e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101261:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101264:	ba 00 00 00 00       	mov    $0x0,%edx
f0101269:	eb 03                	jmp    f010126e <strnlen+0x13>
		n++;
f010126b:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010126e:	39 c2                	cmp    %eax,%edx
f0101270:	74 08                	je     f010127a <strnlen+0x1f>
f0101272:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101276:	75 f3                	jne    f010126b <strnlen+0x10>
f0101278:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010127a:	5d                   	pop    %ebp
f010127b:	c3                   	ret    

f010127c <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010127c:	55                   	push   %ebp
f010127d:	89 e5                	mov    %esp,%ebp
f010127f:	53                   	push   %ebx
f0101280:	8b 45 08             	mov    0x8(%ebp),%eax
f0101283:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101286:	89 c2                	mov    %eax,%edx
f0101288:	83 c2 01             	add    $0x1,%edx
f010128b:	83 c1 01             	add    $0x1,%ecx
f010128e:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101292:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101295:	84 db                	test   %bl,%bl
f0101297:	75 ef                	jne    f0101288 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101299:	5b                   	pop    %ebx
f010129a:	5d                   	pop    %ebp
f010129b:	c3                   	ret    

f010129c <strcat>:

char *
strcat(char *dst, const char *src)
{
f010129c:	55                   	push   %ebp
f010129d:	89 e5                	mov    %esp,%ebp
f010129f:	53                   	push   %ebx
f01012a0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01012a3:	53                   	push   %ebx
f01012a4:	e8 9a ff ff ff       	call   f0101243 <strlen>
f01012a9:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01012ac:	ff 75 0c             	pushl  0xc(%ebp)
f01012af:	01 d8                	add    %ebx,%eax
f01012b1:	50                   	push   %eax
f01012b2:	e8 c5 ff ff ff       	call   f010127c <strcpy>
	return dst;
}
f01012b7:	89 d8                	mov    %ebx,%eax
f01012b9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01012bc:	c9                   	leave  
f01012bd:	c3                   	ret    

f01012be <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01012be:	55                   	push   %ebp
f01012bf:	89 e5                	mov    %esp,%ebp
f01012c1:	56                   	push   %esi
f01012c2:	53                   	push   %ebx
f01012c3:	8b 75 08             	mov    0x8(%ebp),%esi
f01012c6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01012c9:	89 f3                	mov    %esi,%ebx
f01012cb:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01012ce:	89 f2                	mov    %esi,%edx
f01012d0:	eb 0f                	jmp    f01012e1 <strncpy+0x23>
		*dst++ = *src;
f01012d2:	83 c2 01             	add    $0x1,%edx
f01012d5:	0f b6 01             	movzbl (%ecx),%eax
f01012d8:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01012db:	80 39 01             	cmpb   $0x1,(%ecx)
f01012de:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01012e1:	39 da                	cmp    %ebx,%edx
f01012e3:	75 ed                	jne    f01012d2 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01012e5:	89 f0                	mov    %esi,%eax
f01012e7:	5b                   	pop    %ebx
f01012e8:	5e                   	pop    %esi
f01012e9:	5d                   	pop    %ebp
f01012ea:	c3                   	ret    

f01012eb <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01012eb:	55                   	push   %ebp
f01012ec:	89 e5                	mov    %esp,%ebp
f01012ee:	56                   	push   %esi
f01012ef:	53                   	push   %ebx
f01012f0:	8b 75 08             	mov    0x8(%ebp),%esi
f01012f3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01012f6:	8b 55 10             	mov    0x10(%ebp),%edx
f01012f9:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01012fb:	85 d2                	test   %edx,%edx
f01012fd:	74 21                	je     f0101320 <strlcpy+0x35>
f01012ff:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101303:	89 f2                	mov    %esi,%edx
f0101305:	eb 09                	jmp    f0101310 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101307:	83 c2 01             	add    $0x1,%edx
f010130a:	83 c1 01             	add    $0x1,%ecx
f010130d:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101310:	39 c2                	cmp    %eax,%edx
f0101312:	74 09                	je     f010131d <strlcpy+0x32>
f0101314:	0f b6 19             	movzbl (%ecx),%ebx
f0101317:	84 db                	test   %bl,%bl
f0101319:	75 ec                	jne    f0101307 <strlcpy+0x1c>
f010131b:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010131d:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101320:	29 f0                	sub    %esi,%eax
}
f0101322:	5b                   	pop    %ebx
f0101323:	5e                   	pop    %esi
f0101324:	5d                   	pop    %ebp
f0101325:	c3                   	ret    

f0101326 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101326:	55                   	push   %ebp
f0101327:	89 e5                	mov    %esp,%ebp
f0101329:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010132c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010132f:	eb 06                	jmp    f0101337 <strcmp+0x11>
		p++, q++;
f0101331:	83 c1 01             	add    $0x1,%ecx
f0101334:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101337:	0f b6 01             	movzbl (%ecx),%eax
f010133a:	84 c0                	test   %al,%al
f010133c:	74 04                	je     f0101342 <strcmp+0x1c>
f010133e:	3a 02                	cmp    (%edx),%al
f0101340:	74 ef                	je     f0101331 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101342:	0f b6 c0             	movzbl %al,%eax
f0101345:	0f b6 12             	movzbl (%edx),%edx
f0101348:	29 d0                	sub    %edx,%eax
}
f010134a:	5d                   	pop    %ebp
f010134b:	c3                   	ret    

f010134c <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010134c:	55                   	push   %ebp
f010134d:	89 e5                	mov    %esp,%ebp
f010134f:	53                   	push   %ebx
f0101350:	8b 45 08             	mov    0x8(%ebp),%eax
f0101353:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101356:	89 c3                	mov    %eax,%ebx
f0101358:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010135b:	eb 06                	jmp    f0101363 <strncmp+0x17>
		n--, p++, q++;
f010135d:	83 c0 01             	add    $0x1,%eax
f0101360:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101363:	39 d8                	cmp    %ebx,%eax
f0101365:	74 15                	je     f010137c <strncmp+0x30>
f0101367:	0f b6 08             	movzbl (%eax),%ecx
f010136a:	84 c9                	test   %cl,%cl
f010136c:	74 04                	je     f0101372 <strncmp+0x26>
f010136e:	3a 0a                	cmp    (%edx),%cl
f0101370:	74 eb                	je     f010135d <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101372:	0f b6 00             	movzbl (%eax),%eax
f0101375:	0f b6 12             	movzbl (%edx),%edx
f0101378:	29 d0                	sub    %edx,%eax
f010137a:	eb 05                	jmp    f0101381 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010137c:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101381:	5b                   	pop    %ebx
f0101382:	5d                   	pop    %ebp
f0101383:	c3                   	ret    

f0101384 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101384:	55                   	push   %ebp
f0101385:	89 e5                	mov    %esp,%ebp
f0101387:	8b 45 08             	mov    0x8(%ebp),%eax
f010138a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010138e:	eb 07                	jmp    f0101397 <strchr+0x13>
		if (*s == c)
f0101390:	38 ca                	cmp    %cl,%dl
f0101392:	74 0f                	je     f01013a3 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101394:	83 c0 01             	add    $0x1,%eax
f0101397:	0f b6 10             	movzbl (%eax),%edx
f010139a:	84 d2                	test   %dl,%dl
f010139c:	75 f2                	jne    f0101390 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010139e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01013a3:	5d                   	pop    %ebp
f01013a4:	c3                   	ret    

f01013a5 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01013a5:	55                   	push   %ebp
f01013a6:	89 e5                	mov    %esp,%ebp
f01013a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01013ab:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01013af:	eb 03                	jmp    f01013b4 <strfind+0xf>
f01013b1:	83 c0 01             	add    $0x1,%eax
f01013b4:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01013b7:	84 d2                	test   %dl,%dl
f01013b9:	74 04                	je     f01013bf <strfind+0x1a>
f01013bb:	38 ca                	cmp    %cl,%dl
f01013bd:	75 f2                	jne    f01013b1 <strfind+0xc>
			break;
	return (char *) s;
}
f01013bf:	5d                   	pop    %ebp
f01013c0:	c3                   	ret    

f01013c1 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01013c1:	55                   	push   %ebp
f01013c2:	89 e5                	mov    %esp,%ebp
f01013c4:	57                   	push   %edi
f01013c5:	56                   	push   %esi
f01013c6:	53                   	push   %ebx
f01013c7:	8b 7d 08             	mov    0x8(%ebp),%edi
f01013ca:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01013cd:	85 c9                	test   %ecx,%ecx
f01013cf:	74 36                	je     f0101407 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01013d1:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01013d7:	75 28                	jne    f0101401 <memset+0x40>
f01013d9:	f6 c1 03             	test   $0x3,%cl
f01013dc:	75 23                	jne    f0101401 <memset+0x40>
		c &= 0xFF;
f01013de:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01013e2:	89 d3                	mov    %edx,%ebx
f01013e4:	c1 e3 08             	shl    $0x8,%ebx
f01013e7:	89 d6                	mov    %edx,%esi
f01013e9:	c1 e6 18             	shl    $0x18,%esi
f01013ec:	89 d0                	mov    %edx,%eax
f01013ee:	c1 e0 10             	shl    $0x10,%eax
f01013f1:	09 f0                	or     %esi,%eax
f01013f3:	09 c2                	or     %eax,%edx
f01013f5:	89 d0                	mov    %edx,%eax
f01013f7:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01013f9:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01013fc:	fc                   	cld    
f01013fd:	f3 ab                	rep stos %eax,%es:(%edi)
f01013ff:	eb 06                	jmp    f0101407 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101401:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101404:	fc                   	cld    
f0101405:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101407:	89 f8                	mov    %edi,%eax
f0101409:	5b                   	pop    %ebx
f010140a:	5e                   	pop    %esi
f010140b:	5f                   	pop    %edi
f010140c:	5d                   	pop    %ebp
f010140d:	c3                   	ret    

f010140e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010140e:	55                   	push   %ebp
f010140f:	89 e5                	mov    %esp,%ebp
f0101411:	57                   	push   %edi
f0101412:	56                   	push   %esi
f0101413:	8b 45 08             	mov    0x8(%ebp),%eax
f0101416:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101419:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010141c:	39 c6                	cmp    %eax,%esi
f010141e:	73 35                	jae    f0101455 <memmove+0x47>
f0101420:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101423:	39 d0                	cmp    %edx,%eax
f0101425:	73 2e                	jae    f0101455 <memmove+0x47>
		s += n;
		d += n;
f0101427:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f010142a:	89 d6                	mov    %edx,%esi
f010142c:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010142e:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101434:	75 13                	jne    f0101449 <memmove+0x3b>
f0101436:	f6 c1 03             	test   $0x3,%cl
f0101439:	75 0e                	jne    f0101449 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010143b:	83 ef 04             	sub    $0x4,%edi
f010143e:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101441:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101444:	fd                   	std    
f0101445:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101447:	eb 09                	jmp    f0101452 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101449:	83 ef 01             	sub    $0x1,%edi
f010144c:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010144f:	fd                   	std    
f0101450:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101452:	fc                   	cld    
f0101453:	eb 1d                	jmp    f0101472 <memmove+0x64>
f0101455:	89 f2                	mov    %esi,%edx
f0101457:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101459:	f6 c2 03             	test   $0x3,%dl
f010145c:	75 0f                	jne    f010146d <memmove+0x5f>
f010145e:	f6 c1 03             	test   $0x3,%cl
f0101461:	75 0a                	jne    f010146d <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101463:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101466:	89 c7                	mov    %eax,%edi
f0101468:	fc                   	cld    
f0101469:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010146b:	eb 05                	jmp    f0101472 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010146d:	89 c7                	mov    %eax,%edi
f010146f:	fc                   	cld    
f0101470:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101472:	5e                   	pop    %esi
f0101473:	5f                   	pop    %edi
f0101474:	5d                   	pop    %ebp
f0101475:	c3                   	ret    

f0101476 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101476:	55                   	push   %ebp
f0101477:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101479:	ff 75 10             	pushl  0x10(%ebp)
f010147c:	ff 75 0c             	pushl  0xc(%ebp)
f010147f:	ff 75 08             	pushl  0x8(%ebp)
f0101482:	e8 87 ff ff ff       	call   f010140e <memmove>
}
f0101487:	c9                   	leave  
f0101488:	c3                   	ret    

f0101489 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101489:	55                   	push   %ebp
f010148a:	89 e5                	mov    %esp,%ebp
f010148c:	56                   	push   %esi
f010148d:	53                   	push   %ebx
f010148e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101491:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101494:	89 c6                	mov    %eax,%esi
f0101496:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101499:	eb 1a                	jmp    f01014b5 <memcmp+0x2c>
		if (*s1 != *s2)
f010149b:	0f b6 08             	movzbl (%eax),%ecx
f010149e:	0f b6 1a             	movzbl (%edx),%ebx
f01014a1:	38 d9                	cmp    %bl,%cl
f01014a3:	74 0a                	je     f01014af <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01014a5:	0f b6 c1             	movzbl %cl,%eax
f01014a8:	0f b6 db             	movzbl %bl,%ebx
f01014ab:	29 d8                	sub    %ebx,%eax
f01014ad:	eb 0f                	jmp    f01014be <memcmp+0x35>
		s1++, s2++;
f01014af:	83 c0 01             	add    $0x1,%eax
f01014b2:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01014b5:	39 f0                	cmp    %esi,%eax
f01014b7:	75 e2                	jne    f010149b <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01014b9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014be:	5b                   	pop    %ebx
f01014bf:	5e                   	pop    %esi
f01014c0:	5d                   	pop    %ebp
f01014c1:	c3                   	ret    

f01014c2 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01014c2:	55                   	push   %ebp
f01014c3:	89 e5                	mov    %esp,%ebp
f01014c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01014c8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01014cb:	89 c2                	mov    %eax,%edx
f01014cd:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01014d0:	eb 07                	jmp    f01014d9 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01014d2:	38 08                	cmp    %cl,(%eax)
f01014d4:	74 07                	je     f01014dd <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01014d6:	83 c0 01             	add    $0x1,%eax
f01014d9:	39 d0                	cmp    %edx,%eax
f01014db:	72 f5                	jb     f01014d2 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01014dd:	5d                   	pop    %ebp
f01014de:	c3                   	ret    

f01014df <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01014df:	55                   	push   %ebp
f01014e0:	89 e5                	mov    %esp,%ebp
f01014e2:	57                   	push   %edi
f01014e3:	56                   	push   %esi
f01014e4:	53                   	push   %ebx
f01014e5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014e8:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01014eb:	eb 03                	jmp    f01014f0 <strtol+0x11>
		s++;
f01014ed:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01014f0:	0f b6 01             	movzbl (%ecx),%eax
f01014f3:	3c 09                	cmp    $0x9,%al
f01014f5:	74 f6                	je     f01014ed <strtol+0xe>
f01014f7:	3c 20                	cmp    $0x20,%al
f01014f9:	74 f2                	je     f01014ed <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01014fb:	3c 2b                	cmp    $0x2b,%al
f01014fd:	75 0a                	jne    f0101509 <strtol+0x2a>
		s++;
f01014ff:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101502:	bf 00 00 00 00       	mov    $0x0,%edi
f0101507:	eb 10                	jmp    f0101519 <strtol+0x3a>
f0101509:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010150e:	3c 2d                	cmp    $0x2d,%al
f0101510:	75 07                	jne    f0101519 <strtol+0x3a>
		s++, neg = 1;
f0101512:	8d 49 01             	lea    0x1(%ecx),%ecx
f0101515:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101519:	85 db                	test   %ebx,%ebx
f010151b:	0f 94 c0             	sete   %al
f010151e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101524:	75 19                	jne    f010153f <strtol+0x60>
f0101526:	80 39 30             	cmpb   $0x30,(%ecx)
f0101529:	75 14                	jne    f010153f <strtol+0x60>
f010152b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010152f:	0f 85 82 00 00 00    	jne    f01015b7 <strtol+0xd8>
		s += 2, base = 16;
f0101535:	83 c1 02             	add    $0x2,%ecx
f0101538:	bb 10 00 00 00       	mov    $0x10,%ebx
f010153d:	eb 16                	jmp    f0101555 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f010153f:	84 c0                	test   %al,%al
f0101541:	74 12                	je     f0101555 <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101543:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101548:	80 39 30             	cmpb   $0x30,(%ecx)
f010154b:	75 08                	jne    f0101555 <strtol+0x76>
		s++, base = 8;
f010154d:	83 c1 01             	add    $0x1,%ecx
f0101550:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0101555:	b8 00 00 00 00       	mov    $0x0,%eax
f010155a:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010155d:	0f b6 11             	movzbl (%ecx),%edx
f0101560:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101563:	89 f3                	mov    %esi,%ebx
f0101565:	80 fb 09             	cmp    $0x9,%bl
f0101568:	77 08                	ja     f0101572 <strtol+0x93>
			dig = *s - '0';
f010156a:	0f be d2             	movsbl %dl,%edx
f010156d:	83 ea 30             	sub    $0x30,%edx
f0101570:	eb 22                	jmp    f0101594 <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f0101572:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101575:	89 f3                	mov    %esi,%ebx
f0101577:	80 fb 19             	cmp    $0x19,%bl
f010157a:	77 08                	ja     f0101584 <strtol+0xa5>
			dig = *s - 'a' + 10;
f010157c:	0f be d2             	movsbl %dl,%edx
f010157f:	83 ea 57             	sub    $0x57,%edx
f0101582:	eb 10                	jmp    f0101594 <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f0101584:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101587:	89 f3                	mov    %esi,%ebx
f0101589:	80 fb 19             	cmp    $0x19,%bl
f010158c:	77 16                	ja     f01015a4 <strtol+0xc5>
			dig = *s - 'A' + 10;
f010158e:	0f be d2             	movsbl %dl,%edx
f0101591:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0101594:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101597:	7d 0f                	jge    f01015a8 <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f0101599:	83 c1 01             	add    $0x1,%ecx
f010159c:	0f af 45 10          	imul   0x10(%ebp),%eax
f01015a0:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01015a2:	eb b9                	jmp    f010155d <strtol+0x7e>
f01015a4:	89 c2                	mov    %eax,%edx
f01015a6:	eb 02                	jmp    f01015aa <strtol+0xcb>
f01015a8:	89 c2                	mov    %eax,%edx

	if (endptr)
f01015aa:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01015ae:	74 0d                	je     f01015bd <strtol+0xde>
		*endptr = (char *) s;
f01015b0:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015b3:	89 0e                	mov    %ecx,(%esi)
f01015b5:	eb 06                	jmp    f01015bd <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01015b7:	84 c0                	test   %al,%al
f01015b9:	75 92                	jne    f010154d <strtol+0x6e>
f01015bb:	eb 98                	jmp    f0101555 <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01015bd:	f7 da                	neg    %edx
f01015bf:	85 ff                	test   %edi,%edi
f01015c1:	0f 45 c2             	cmovne %edx,%eax
}
f01015c4:	5b                   	pop    %ebx
f01015c5:	5e                   	pop    %esi
f01015c6:	5f                   	pop    %edi
f01015c7:	5d                   	pop    %ebp
f01015c8:	c3                   	ret    
f01015c9:	66 90                	xchg   %ax,%ax
f01015cb:	66 90                	xchg   %ax,%ax
f01015cd:	66 90                	xchg   %ax,%ax
f01015cf:	90                   	nop

f01015d0 <__udivdi3>:
f01015d0:	55                   	push   %ebp
f01015d1:	57                   	push   %edi
f01015d2:	56                   	push   %esi
f01015d3:	83 ec 10             	sub    $0x10,%esp
f01015d6:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f01015da:	8b 7c 24 20          	mov    0x20(%esp),%edi
f01015de:	8b 74 24 24          	mov    0x24(%esp),%esi
f01015e2:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01015e6:	85 d2                	test   %edx,%edx
f01015e8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01015ec:	89 34 24             	mov    %esi,(%esp)
f01015ef:	89 c8                	mov    %ecx,%eax
f01015f1:	75 35                	jne    f0101628 <__udivdi3+0x58>
f01015f3:	39 f1                	cmp    %esi,%ecx
f01015f5:	0f 87 bd 00 00 00    	ja     f01016b8 <__udivdi3+0xe8>
f01015fb:	85 c9                	test   %ecx,%ecx
f01015fd:	89 cd                	mov    %ecx,%ebp
f01015ff:	75 0b                	jne    f010160c <__udivdi3+0x3c>
f0101601:	b8 01 00 00 00       	mov    $0x1,%eax
f0101606:	31 d2                	xor    %edx,%edx
f0101608:	f7 f1                	div    %ecx
f010160a:	89 c5                	mov    %eax,%ebp
f010160c:	89 f0                	mov    %esi,%eax
f010160e:	31 d2                	xor    %edx,%edx
f0101610:	f7 f5                	div    %ebp
f0101612:	89 c6                	mov    %eax,%esi
f0101614:	89 f8                	mov    %edi,%eax
f0101616:	f7 f5                	div    %ebp
f0101618:	89 f2                	mov    %esi,%edx
f010161a:	83 c4 10             	add    $0x10,%esp
f010161d:	5e                   	pop    %esi
f010161e:	5f                   	pop    %edi
f010161f:	5d                   	pop    %ebp
f0101620:	c3                   	ret    
f0101621:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101628:	3b 14 24             	cmp    (%esp),%edx
f010162b:	77 7b                	ja     f01016a8 <__udivdi3+0xd8>
f010162d:	0f bd f2             	bsr    %edx,%esi
f0101630:	83 f6 1f             	xor    $0x1f,%esi
f0101633:	0f 84 97 00 00 00    	je     f01016d0 <__udivdi3+0x100>
f0101639:	bd 20 00 00 00       	mov    $0x20,%ebp
f010163e:	89 d7                	mov    %edx,%edi
f0101640:	89 f1                	mov    %esi,%ecx
f0101642:	29 f5                	sub    %esi,%ebp
f0101644:	d3 e7                	shl    %cl,%edi
f0101646:	89 c2                	mov    %eax,%edx
f0101648:	89 e9                	mov    %ebp,%ecx
f010164a:	d3 ea                	shr    %cl,%edx
f010164c:	89 f1                	mov    %esi,%ecx
f010164e:	09 fa                	or     %edi,%edx
f0101650:	8b 3c 24             	mov    (%esp),%edi
f0101653:	d3 e0                	shl    %cl,%eax
f0101655:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101659:	89 e9                	mov    %ebp,%ecx
f010165b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010165f:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101663:	89 fa                	mov    %edi,%edx
f0101665:	d3 ea                	shr    %cl,%edx
f0101667:	89 f1                	mov    %esi,%ecx
f0101669:	d3 e7                	shl    %cl,%edi
f010166b:	89 e9                	mov    %ebp,%ecx
f010166d:	d3 e8                	shr    %cl,%eax
f010166f:	09 c7                	or     %eax,%edi
f0101671:	89 f8                	mov    %edi,%eax
f0101673:	f7 74 24 08          	divl   0x8(%esp)
f0101677:	89 d5                	mov    %edx,%ebp
f0101679:	89 c7                	mov    %eax,%edi
f010167b:	f7 64 24 0c          	mull   0xc(%esp)
f010167f:	39 d5                	cmp    %edx,%ebp
f0101681:	89 14 24             	mov    %edx,(%esp)
f0101684:	72 11                	jb     f0101697 <__udivdi3+0xc7>
f0101686:	8b 54 24 04          	mov    0x4(%esp),%edx
f010168a:	89 f1                	mov    %esi,%ecx
f010168c:	d3 e2                	shl    %cl,%edx
f010168e:	39 c2                	cmp    %eax,%edx
f0101690:	73 5e                	jae    f01016f0 <__udivdi3+0x120>
f0101692:	3b 2c 24             	cmp    (%esp),%ebp
f0101695:	75 59                	jne    f01016f0 <__udivdi3+0x120>
f0101697:	8d 47 ff             	lea    -0x1(%edi),%eax
f010169a:	31 f6                	xor    %esi,%esi
f010169c:	89 f2                	mov    %esi,%edx
f010169e:	83 c4 10             	add    $0x10,%esp
f01016a1:	5e                   	pop    %esi
f01016a2:	5f                   	pop    %edi
f01016a3:	5d                   	pop    %ebp
f01016a4:	c3                   	ret    
f01016a5:	8d 76 00             	lea    0x0(%esi),%esi
f01016a8:	31 f6                	xor    %esi,%esi
f01016aa:	31 c0                	xor    %eax,%eax
f01016ac:	89 f2                	mov    %esi,%edx
f01016ae:	83 c4 10             	add    $0x10,%esp
f01016b1:	5e                   	pop    %esi
f01016b2:	5f                   	pop    %edi
f01016b3:	5d                   	pop    %ebp
f01016b4:	c3                   	ret    
f01016b5:	8d 76 00             	lea    0x0(%esi),%esi
f01016b8:	89 f2                	mov    %esi,%edx
f01016ba:	31 f6                	xor    %esi,%esi
f01016bc:	89 f8                	mov    %edi,%eax
f01016be:	f7 f1                	div    %ecx
f01016c0:	89 f2                	mov    %esi,%edx
f01016c2:	83 c4 10             	add    $0x10,%esp
f01016c5:	5e                   	pop    %esi
f01016c6:	5f                   	pop    %edi
f01016c7:	5d                   	pop    %ebp
f01016c8:	c3                   	ret    
f01016c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016d0:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f01016d4:	76 0b                	jbe    f01016e1 <__udivdi3+0x111>
f01016d6:	31 c0                	xor    %eax,%eax
f01016d8:	3b 14 24             	cmp    (%esp),%edx
f01016db:	0f 83 37 ff ff ff    	jae    f0101618 <__udivdi3+0x48>
f01016e1:	b8 01 00 00 00       	mov    $0x1,%eax
f01016e6:	e9 2d ff ff ff       	jmp    f0101618 <__udivdi3+0x48>
f01016eb:	90                   	nop
f01016ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01016f0:	89 f8                	mov    %edi,%eax
f01016f2:	31 f6                	xor    %esi,%esi
f01016f4:	e9 1f ff ff ff       	jmp    f0101618 <__udivdi3+0x48>
f01016f9:	66 90                	xchg   %ax,%ax
f01016fb:	66 90                	xchg   %ax,%ax
f01016fd:	66 90                	xchg   %ax,%ax
f01016ff:	90                   	nop

f0101700 <__umoddi3>:
f0101700:	55                   	push   %ebp
f0101701:	57                   	push   %edi
f0101702:	56                   	push   %esi
f0101703:	83 ec 20             	sub    $0x20,%esp
f0101706:	8b 44 24 34          	mov    0x34(%esp),%eax
f010170a:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010170e:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101712:	89 c6                	mov    %eax,%esi
f0101714:	89 44 24 10          	mov    %eax,0x10(%esp)
f0101718:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010171c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0101720:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101724:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0101728:	89 74 24 18          	mov    %esi,0x18(%esp)
f010172c:	85 c0                	test   %eax,%eax
f010172e:	89 c2                	mov    %eax,%edx
f0101730:	75 1e                	jne    f0101750 <__umoddi3+0x50>
f0101732:	39 f7                	cmp    %esi,%edi
f0101734:	76 52                	jbe    f0101788 <__umoddi3+0x88>
f0101736:	89 c8                	mov    %ecx,%eax
f0101738:	89 f2                	mov    %esi,%edx
f010173a:	f7 f7                	div    %edi
f010173c:	89 d0                	mov    %edx,%eax
f010173e:	31 d2                	xor    %edx,%edx
f0101740:	83 c4 20             	add    $0x20,%esp
f0101743:	5e                   	pop    %esi
f0101744:	5f                   	pop    %edi
f0101745:	5d                   	pop    %ebp
f0101746:	c3                   	ret    
f0101747:	89 f6                	mov    %esi,%esi
f0101749:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101750:	39 f0                	cmp    %esi,%eax
f0101752:	77 5c                	ja     f01017b0 <__umoddi3+0xb0>
f0101754:	0f bd e8             	bsr    %eax,%ebp
f0101757:	83 f5 1f             	xor    $0x1f,%ebp
f010175a:	75 64                	jne    f01017c0 <__umoddi3+0xc0>
f010175c:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0101760:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0101764:	0f 86 f6 00 00 00    	jbe    f0101860 <__umoddi3+0x160>
f010176a:	3b 44 24 18          	cmp    0x18(%esp),%eax
f010176e:	0f 82 ec 00 00 00    	jb     f0101860 <__umoddi3+0x160>
f0101774:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101778:	8b 54 24 18          	mov    0x18(%esp),%edx
f010177c:	83 c4 20             	add    $0x20,%esp
f010177f:	5e                   	pop    %esi
f0101780:	5f                   	pop    %edi
f0101781:	5d                   	pop    %ebp
f0101782:	c3                   	ret    
f0101783:	90                   	nop
f0101784:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101788:	85 ff                	test   %edi,%edi
f010178a:	89 fd                	mov    %edi,%ebp
f010178c:	75 0b                	jne    f0101799 <__umoddi3+0x99>
f010178e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101793:	31 d2                	xor    %edx,%edx
f0101795:	f7 f7                	div    %edi
f0101797:	89 c5                	mov    %eax,%ebp
f0101799:	8b 44 24 10          	mov    0x10(%esp),%eax
f010179d:	31 d2                	xor    %edx,%edx
f010179f:	f7 f5                	div    %ebp
f01017a1:	89 c8                	mov    %ecx,%eax
f01017a3:	f7 f5                	div    %ebp
f01017a5:	eb 95                	jmp    f010173c <__umoddi3+0x3c>
f01017a7:	89 f6                	mov    %esi,%esi
f01017a9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01017b0:	89 c8                	mov    %ecx,%eax
f01017b2:	89 f2                	mov    %esi,%edx
f01017b4:	83 c4 20             	add    $0x20,%esp
f01017b7:	5e                   	pop    %esi
f01017b8:	5f                   	pop    %edi
f01017b9:	5d                   	pop    %ebp
f01017ba:	c3                   	ret    
f01017bb:	90                   	nop
f01017bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017c0:	b8 20 00 00 00       	mov    $0x20,%eax
f01017c5:	89 e9                	mov    %ebp,%ecx
f01017c7:	29 e8                	sub    %ebp,%eax
f01017c9:	d3 e2                	shl    %cl,%edx
f01017cb:	89 c7                	mov    %eax,%edi
f01017cd:	89 44 24 18          	mov    %eax,0x18(%esp)
f01017d1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01017d5:	89 f9                	mov    %edi,%ecx
f01017d7:	d3 e8                	shr    %cl,%eax
f01017d9:	89 c1                	mov    %eax,%ecx
f01017db:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01017df:	09 d1                	or     %edx,%ecx
f01017e1:	89 fa                	mov    %edi,%edx
f01017e3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01017e7:	89 e9                	mov    %ebp,%ecx
f01017e9:	d3 e0                	shl    %cl,%eax
f01017eb:	89 f9                	mov    %edi,%ecx
f01017ed:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01017f1:	89 f0                	mov    %esi,%eax
f01017f3:	d3 e8                	shr    %cl,%eax
f01017f5:	89 e9                	mov    %ebp,%ecx
f01017f7:	89 c7                	mov    %eax,%edi
f01017f9:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f01017fd:	d3 e6                	shl    %cl,%esi
f01017ff:	89 d1                	mov    %edx,%ecx
f0101801:	89 fa                	mov    %edi,%edx
f0101803:	d3 e8                	shr    %cl,%eax
f0101805:	89 e9                	mov    %ebp,%ecx
f0101807:	09 f0                	or     %esi,%eax
f0101809:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f010180d:	f7 74 24 10          	divl   0x10(%esp)
f0101811:	d3 e6                	shl    %cl,%esi
f0101813:	89 d1                	mov    %edx,%ecx
f0101815:	f7 64 24 0c          	mull   0xc(%esp)
f0101819:	39 d1                	cmp    %edx,%ecx
f010181b:	89 74 24 14          	mov    %esi,0x14(%esp)
f010181f:	89 d7                	mov    %edx,%edi
f0101821:	89 c6                	mov    %eax,%esi
f0101823:	72 0a                	jb     f010182f <__umoddi3+0x12f>
f0101825:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0101829:	73 10                	jae    f010183b <__umoddi3+0x13b>
f010182b:	39 d1                	cmp    %edx,%ecx
f010182d:	75 0c                	jne    f010183b <__umoddi3+0x13b>
f010182f:	89 d7                	mov    %edx,%edi
f0101831:	89 c6                	mov    %eax,%esi
f0101833:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0101837:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f010183b:	89 ca                	mov    %ecx,%edx
f010183d:	89 e9                	mov    %ebp,%ecx
f010183f:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101843:	29 f0                	sub    %esi,%eax
f0101845:	19 fa                	sbb    %edi,%edx
f0101847:	d3 e8                	shr    %cl,%eax
f0101849:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f010184e:	89 d7                	mov    %edx,%edi
f0101850:	d3 e7                	shl    %cl,%edi
f0101852:	89 e9                	mov    %ebp,%ecx
f0101854:	09 f8                	or     %edi,%eax
f0101856:	d3 ea                	shr    %cl,%edx
f0101858:	83 c4 20             	add    $0x20,%esp
f010185b:	5e                   	pop    %esi
f010185c:	5f                   	pop    %edi
f010185d:	5d                   	pop    %ebp
f010185e:	c3                   	ret    
f010185f:	90                   	nop
f0101860:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101864:	29 f9                	sub    %edi,%ecx
f0101866:	19 c6                	sbb    %eax,%esi
f0101868:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010186c:	89 74 24 18          	mov    %esi,0x18(%esp)
f0101870:	e9 ff fe ff ff       	jmp    f0101774 <__umoddi3+0x74>
