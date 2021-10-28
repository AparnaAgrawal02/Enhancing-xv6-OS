
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a8013103          	ld	sp,-1408(sp) # 80008a80 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	fec78793          	addi	a5,a5,-20 # 80006050 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	53e080e7          	jalr	1342(ra) # 8000266a <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	056080e7          	jalr	86(ra) # 8000222a <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	404080e7          	jalr	1028(ra) # 80002614 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	3ce080e7          	jalr	974(ra) # 800026c0 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f80080e7          	jalr	-128(ra) # 800023c6 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	6a078793          	addi	a5,a5,1696 # 80021b18 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	b26080e7          	jalr	-1242(ra) # 800023c6 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	8fe080e7          	jalr	-1794(ra) # 8000222a <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{ 
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	acc080e7          	jalr	-1332(ra) # 800029a0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	1b4080e7          	jalr	436(ra) # 80006090 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	0a0080e7          	jalr	160(ra) # 80001f84 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	a2c080e7          	jalr	-1492(ra) # 80002978 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	a4c080e7          	jalr	-1460(ra) # 800029a0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	11e080e7          	jalr	286(ra) # 8000607a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	12c080e7          	jalr	300(ra) # 80006090 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	30e080e7          	jalr	782(ra) # 8000327a <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	99e080e7          	jalr	-1634(ra) # 80003912 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	948080e7          	jalr	-1720(ra) # 800048c4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	22e080e7          	jalr	558(ra) # 800061b2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d20080e7          	jalr	-736(ra) # 80001cac <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	062a0a13          	addi	s4,s4,98 # 800178d0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if (pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a8:	18848493          	addi	s1,s1,392
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	db848493          	addi	s1,s1,-584 # 800116d0 <proc>
  {
    initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
    p->kstack = KSTACK((int)(p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000193a:	00016997          	auipc	s3,0x16
    8000193e:	f9698993          	addi	s3,s3,-106 # 800178d0 <tickslock>
    initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	878d                	srai	a5,a5,0x3
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	f0bc                	sd	a5,96(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001968:	18848493          	addi	s1,s1,392
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	93050513          	addi	a0,a0,-1744 # 800112d0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8d870713          	addi	a4,a4,-1832 # 800112a0 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first)
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	0307a783          	lw	a5,48(a5) # 80008a30 <first.1721>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	fae080e7          	jalr	-82(ra) # 800029b8 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	0007ab23          	sw	zero,22(a5) # 80008a30 <first.1721>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	e6e080e7          	jalr	-402(ra) # 80003892 <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
{
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3a:	00010917          	auipc	s2,0x10
    80001a3e:	86690913          	addi	s2,s2,-1946 # 800112a0 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	fe878793          	addi	a5,a5,-24 # 80008a34 <nextpid>
    80001a54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a56:	0014871b          	addiw	a4,s1,1
    80001a5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <proc_pagetable>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
    80001a80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	8b8080e7          	jalr	-1864(ra) # 8000133a <uvmcreate>
    80001a8a:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a8c:	c121                	beqz	a0,80001acc <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8e:	4729                	li	a4,10
    80001a90:	00005697          	auipc	a3,0x5
    80001a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	040005b7          	lui	a1,0x4000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b2                	slli	a1,a1,0xc
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	60e080e7          	jalr	1550(ra) # 800010b0 <mappages>
    80001aaa:	02054863          	bltz	a0,80001ada <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aae:	4719                	li	a4,6
    80001ab0:	07893683          	ld	a3,120(s2)
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f0080e7          	jalr	1520(ra) # 800010b0 <mappages>
    80001ac8:	02054163          	bltz	a0,80001aea <proc_pagetable+0x76>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret
    uvmfree(pagetable, 0);
    80001ada:	4581                	li	a1,0
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	a58080e7          	jalr	-1448(ra) # 80001536 <uvmfree>
    return 0;
    80001ae6:	4481                	li	s1,0
    80001ae8:	b7d5                	j	80001acc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aea:	4681                	li	a3,0
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	77e080e7          	jalr	1918(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b00:	4581                	li	a1,0
    80001b02:	8526                	mv	a0,s1
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	a32080e7          	jalr	-1486(ra) # 80001536 <uvmfree>
    return 0;
    80001b0c:	4481                	li	s1,0
    80001b0e:	bf7d                	j	80001acc <proc_pagetable+0x58>

0000000080001b10 <proc_freepagetable>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
    80001b1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	74a080e7          	jalr	1866(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b6                	slli	a1,a1,0xd
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	734080e7          	jalr	1844(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4a:	85ca                	mv	a1,s2
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	9e8080e7          	jalr	-1560(ra) # 80001536 <uvmfree>
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <freeproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    80001b6c:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6e:	7d28                	ld	a0,120(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0604bc23          	sd	zero,120(s1)
  if (p->pagetable)
    80001b7e:	78a8                	ld	a0,112(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	74ac                	ld	a1,104(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80001b90:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80001b9c:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80001ba0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bac:	0004ac23          	sw	zero,24(s1)
}
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <allocproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	e04a                	sd	s2,0(sp)
    80001bc4:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc6:	00010497          	auipc	s1,0x10
    80001bca:	b0a48493          	addi	s1,s1,-1270 # 800116d0 <proc>
    80001bce:	00016917          	auipc	s2,0x16
    80001bd2:	d0290913          	addi	s2,s2,-766 # 800178d0 <tickslock>
    acquire(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	00c080e7          	jalr	12(ra) # 80000be4 <acquire>
    if (p->state == UNUSED)
    80001be0:	4c9c                	lw	a5,24(s1)
    80001be2:	cf81                	beqz	a5,80001bfa <allocproc+0x40>
      release(&p->lock);
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bee:	18848493          	addi	s1,s1,392
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a89d                	j	80001c6e <allocproc+0xb4>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e34080e7          	jalr	-460(ra) # 80001a2e <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	eec080e7          	jalr	-276(ra) # 80000af4 <kalloc>
    80001c10:	892a                	mv	s2,a0
    80001c12:	fca8                	sd	a0,120(s1)
    80001c14:	c525                	beqz	a0,80001c7c <allocproc+0xc2>
  p->pagetable = proc_pagetable(p);
    80001c16:	8526                	mv	a0,s1
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	e5c080e7          	jalr	-420(ra) # 80001a74 <proc_pagetable>
    80001c20:	892a                	mv	s2,a0
    80001c22:	f8a8                	sd	a0,112(s1)
  if (p->pagetable == 0)
    80001c24:	c925                	beqz	a0,80001c94 <allocproc+0xda>
  memset(&p->context, 0, sizeof(p->context));
    80001c26:	07000613          	li	a2,112
    80001c2a:	4581                	li	a1,0
    80001c2c:	08048513          	addi	a0,s1,128
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	0b0080e7          	jalr	176(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c38:	00000797          	auipc	a5,0x0
    80001c3c:	db078793          	addi	a5,a5,-592 # 800019e8 <forkret>
    80001c40:	e0dc                	sd	a5,128(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c42:	70bc                	ld	a5,96(s1)
    80001c44:	6705                	lui	a4,0x1
    80001c46:	97ba                	add	a5,a5,a4
    80001c48:	e4dc                	sd	a5,136(s1)
  p->rtime = 0;
    80001c4a:	0204ae23          	sw	zero,60(s1)
  p->ctime = ticks;
    80001c4e:	00007797          	auipc	a5,0x7
    80001c52:	3e27a783          	lw	a5,994(a5) # 80009030 <ticks>
    80001c56:	dc9c                	sw	a5,56(s1)
  p->etime = 0;
    80001c58:	0404a023          	sw	zero,64(s1)
  p->stime = 0;
    80001c5c:	0404a423          	sw	zero,72(s1)
  p->startsleep= 0;
    80001c60:	0404a623          	sw	zero,76(s1)
  p->sp = 60;
    80001c64:	03c00793          	li	a5,60
    80001c68:	c0fc                	sw	a5,68(s1)
  p->scheduleNum = 0;
    80001c6a:	0404a823          	sw	zero,80(s1)
}
    80001c6e:	8526                	mv	a0,s1
    80001c70:	60e2                	ld	ra,24(sp)
    80001c72:	6442                	ld	s0,16(sp)
    80001c74:	64a2                	ld	s1,8(sp)
    80001c76:	6902                	ld	s2,0(sp)
    80001c78:	6105                	addi	sp,sp,32
    80001c7a:	8082                	ret
    freeproc(p);
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	00000097          	auipc	ra,0x0
    80001c82:	ee4080e7          	jalr	-284(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	010080e7          	jalr	16(ra) # 80000c98 <release>
    return 0;
    80001c90:	84ca                	mv	s1,s2
    80001c92:	bff1                	j	80001c6e <allocproc+0xb4>
    freeproc(p);
    80001c94:	8526                	mv	a0,s1
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	ecc080e7          	jalr	-308(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	ff8080e7          	jalr	-8(ra) # 80000c98 <release>
    return 0;
    80001ca8:	84ca                	mv	s1,s2
    80001caa:	b7d1                	j	80001c6e <allocproc+0xb4>

0000000080001cac <userinit>:
{
    80001cac:	1101                	addi	sp,sp,-32
    80001cae:	ec06                	sd	ra,24(sp)
    80001cb0:	e822                	sd	s0,16(sp)
    80001cb2:	e426                	sd	s1,8(sp)
    80001cb4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	f04080e7          	jalr	-252(ra) # 80001bba <allocproc>
    80001cbe:	84aa                	mv	s1,a0
  initproc = p;
    80001cc0:	00007797          	auipc	a5,0x7
    80001cc4:	36a7b423          	sd	a0,872(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cc8:	03400613          	li	a2,52
    80001ccc:	00007597          	auipc	a1,0x7
    80001cd0:	d7458593          	addi	a1,a1,-652 # 80008a40 <initcode>
    80001cd4:	7928                	ld	a0,112(a0)
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	692080e7          	jalr	1682(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cde:	6785                	lui	a5,0x1
    80001ce0:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;     // user program counter
    80001ce2:	7cb8                	ld	a4,120(s1)
    80001ce4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001ce8:	7cb8                	ld	a4,120(s1)
    80001cea:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cec:	4641                	li	a2,16
    80001cee:	00006597          	auipc	a1,0x6
    80001cf2:	51258593          	addi	a1,a1,1298 # 80008200 <digits+0x1c0>
    80001cf6:	17848513          	addi	a0,s1,376
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	138080e7          	jalr	312(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d02:	00006517          	auipc	a0,0x6
    80001d06:	50e50513          	addi	a0,a0,1294 # 80008210 <digits+0x1d0>
    80001d0a:	00002097          	auipc	ra,0x2
    80001d0e:	5b6080e7          	jalr	1462(ra) # 800042c0 <namei>
    80001d12:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80001d16:	478d                	li	a5,3
    80001d18:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d1a:	8526                	mv	a0,s1
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	f7c080e7          	jalr	-132(ra) # 80000c98 <release>
}
    80001d24:	60e2                	ld	ra,24(sp)
    80001d26:	6442                	ld	s0,16(sp)
    80001d28:	64a2                	ld	s1,8(sp)
    80001d2a:	6105                	addi	sp,sp,32
    80001d2c:	8082                	ret

0000000080001d2e <growproc>:
{
    80001d2e:	1101                	addi	sp,sp,-32
    80001d30:	ec06                	sd	ra,24(sp)
    80001d32:	e822                	sd	s0,16(sp)
    80001d34:	e426                	sd	s1,8(sp)
    80001d36:	e04a                	sd	s2,0(sp)
    80001d38:	1000                	addi	s0,sp,32
    80001d3a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d3c:	00000097          	auipc	ra,0x0
    80001d40:	c74080e7          	jalr	-908(ra) # 800019b0 <myproc>
    80001d44:	892a                	mv	s2,a0
  sz = p->sz;
    80001d46:	752c                	ld	a1,104(a0)
    80001d48:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001d4c:	00904f63          	bgtz	s1,80001d6a <growproc+0x3c>
  else if (n < 0)
    80001d50:	0204cc63          	bltz	s1,80001d88 <growproc+0x5a>
  p->sz = sz;
    80001d54:	1602                	slli	a2,a2,0x20
    80001d56:	9201                	srli	a2,a2,0x20
    80001d58:	06c93423          	sd	a2,104(s2)
  return 0;
    80001d5c:	4501                	li	a0,0
}
    80001d5e:	60e2                	ld	ra,24(sp)
    80001d60:	6442                	ld	s0,16(sp)
    80001d62:	64a2                	ld	s1,8(sp)
    80001d64:	6902                	ld	s2,0(sp)
    80001d66:	6105                	addi	sp,sp,32
    80001d68:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001d6a:	9e25                	addw	a2,a2,s1
    80001d6c:	1602                	slli	a2,a2,0x20
    80001d6e:	9201                	srli	a2,a2,0x20
    80001d70:	1582                	slli	a1,a1,0x20
    80001d72:	9181                	srli	a1,a1,0x20
    80001d74:	7928                	ld	a0,112(a0)
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	6ac080e7          	jalr	1708(ra) # 80001422 <uvmalloc>
    80001d7e:	0005061b          	sext.w	a2,a0
    80001d82:	fa69                	bnez	a2,80001d54 <growproc+0x26>
      return -1;
    80001d84:	557d                	li	a0,-1
    80001d86:	bfe1                	j	80001d5e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d88:	9e25                	addw	a2,a2,s1
    80001d8a:	1602                	slli	a2,a2,0x20
    80001d8c:	9201                	srli	a2,a2,0x20
    80001d8e:	1582                	slli	a1,a1,0x20
    80001d90:	9181                	srli	a1,a1,0x20
    80001d92:	7928                	ld	a0,112(a0)
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	646080e7          	jalr	1606(ra) # 800013da <uvmdealloc>
    80001d9c:	0005061b          	sext.w	a2,a0
    80001da0:	bf55                	j	80001d54 <growproc+0x26>

0000000080001da2 <fork>:
{
    80001da2:	7179                	addi	sp,sp,-48
    80001da4:	f406                	sd	ra,40(sp)
    80001da6:	f022                	sd	s0,32(sp)
    80001da8:	ec26                	sd	s1,24(sp)
    80001daa:	e84a                	sd	s2,16(sp)
    80001dac:	e44e                	sd	s3,8(sp)
    80001dae:	e052                	sd	s4,0(sp)
    80001db0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001db2:	00000097          	auipc	ra,0x0
    80001db6:	bfe080e7          	jalr	-1026(ra) # 800019b0 <myproc>
    80001dba:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001dbc:	00000097          	auipc	ra,0x0
    80001dc0:	dfe080e7          	jalr	-514(ra) # 80001bba <allocproc>
    80001dc4:	10050f63          	beqz	a0,80001ee2 <fork+0x140>
    80001dc8:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dca:	06893603          	ld	a2,104(s2)
    80001dce:	792c                	ld	a1,112(a0)
    80001dd0:	07093503          	ld	a0,112(s2)
    80001dd4:	fffff097          	auipc	ra,0xfffff
    80001dd8:	79a080e7          	jalr	1946(ra) # 8000156e <uvmcopy>
    80001ddc:	04054a63          	bltz	a0,80001e30 <fork+0x8e>
  np->sz = p->sz;
    80001de0:	06893783          	ld	a5,104(s2)
    80001de4:	06f9b423          	sd	a5,104(s3)
  np->trace_mask = p->trace_mask;
    80001de8:	03492783          	lw	a5,52(s2)
    80001dec:	02f9aa23          	sw	a5,52(s3)
  *(np->trapframe) = *(p->trapframe);
    80001df0:	07893683          	ld	a3,120(s2)
    80001df4:	87b6                	mv	a5,a3
    80001df6:	0789b703          	ld	a4,120(s3)
    80001dfa:	12068693          	addi	a3,a3,288
    80001dfe:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e02:	6788                	ld	a0,8(a5)
    80001e04:	6b8c                	ld	a1,16(a5)
    80001e06:	6f90                	ld	a2,24(a5)
    80001e08:	01073023          	sd	a6,0(a4)
    80001e0c:	e708                	sd	a0,8(a4)
    80001e0e:	eb0c                	sd	a1,16(a4)
    80001e10:	ef10                	sd	a2,24(a4)
    80001e12:	02078793          	addi	a5,a5,32
    80001e16:	02070713          	addi	a4,a4,32
    80001e1a:	fed792e3          	bne	a5,a3,80001dfe <fork+0x5c>
  np->trapframe->a0 = 0;
    80001e1e:	0789b783          	ld	a5,120(s3)
    80001e22:	0607b823          	sd	zero,112(a5)
    80001e26:	0f000493          	li	s1,240
  for (i = 0; i < NOFILE; i++)
    80001e2a:	17000a13          	li	s4,368
    80001e2e:	a03d                	j	80001e5c <fork+0xba>
    freeproc(np);
    80001e30:	854e                	mv	a0,s3
    80001e32:	00000097          	auipc	ra,0x0
    80001e36:	d30080e7          	jalr	-720(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e3a:	854e                	mv	a0,s3
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	e5c080e7          	jalr	-420(ra) # 80000c98 <release>
    return -1;
    80001e44:	5a7d                	li	s4,-1
    80001e46:	a069                	j	80001ed0 <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e48:	00003097          	auipc	ra,0x3
    80001e4c:	b0e080e7          	jalr	-1266(ra) # 80004956 <filedup>
    80001e50:	009987b3          	add	a5,s3,s1
    80001e54:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001e56:	04a1                	addi	s1,s1,8
    80001e58:	01448763          	beq	s1,s4,80001e66 <fork+0xc4>
    if (p->ofile[i])
    80001e5c:	009907b3          	add	a5,s2,s1
    80001e60:	6388                	ld	a0,0(a5)
    80001e62:	f17d                	bnez	a0,80001e48 <fork+0xa6>
    80001e64:	bfcd                	j	80001e56 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001e66:	17093503          	ld	a0,368(s2)
    80001e6a:	00002097          	auipc	ra,0x2
    80001e6e:	c62080e7          	jalr	-926(ra) # 80003acc <idup>
    80001e72:	16a9b823          	sd	a0,368(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e76:	4641                	li	a2,16
    80001e78:	17890593          	addi	a1,s2,376
    80001e7c:	17898513          	addi	a0,s3,376
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	fb2080e7          	jalr	-78(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e88:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e8c:	854e                	mv	a0,s3
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	e0a080e7          	jalr	-502(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e96:	0000f497          	auipc	s1,0xf
    80001e9a:	42248493          	addi	s1,s1,1058 # 800112b8 <wait_lock>
    80001e9e:	8526                	mv	a0,s1
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	d44080e7          	jalr	-700(ra) # 80000be4 <acquire>
  np->parent = p;
    80001ea8:	0529bc23          	sd	s2,88(s3)
  release(&wait_lock);
    80001eac:	8526                	mv	a0,s1
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	dea080e7          	jalr	-534(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001eb6:	854e                	mv	a0,s3
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	d2c080e7          	jalr	-724(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ec0:	478d                	li	a5,3
    80001ec2:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ec6:	854e                	mv	a0,s3
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	dd0080e7          	jalr	-560(ra) # 80000c98 <release>
}
    80001ed0:	8552                	mv	a0,s4
    80001ed2:	70a2                	ld	ra,40(sp)
    80001ed4:	7402                	ld	s0,32(sp)
    80001ed6:	64e2                	ld	s1,24(sp)
    80001ed8:	6942                	ld	s2,16(sp)
    80001eda:	69a2                	ld	s3,8(sp)
    80001edc:	6a02                	ld	s4,0(sp)
    80001ede:	6145                	addi	sp,sp,48
    80001ee0:	8082                	ret
    return -1;
    80001ee2:	5a7d                	li	s4,-1
    80001ee4:	b7f5                	j	80001ed0 <fork+0x12e>

0000000080001ee6 <set_priority>:
{ int prev = -1;
    80001ee6:	7139                	addi	sp,sp,-64
    80001ee8:	fc06                	sd	ra,56(sp)
    80001eea:	f822                	sd	s0,48(sp)
    80001eec:	f426                	sd	s1,40(sp)
    80001eee:	f04a                	sd	s2,32(sp)
    80001ef0:	ec4e                	sd	s3,24(sp)
    80001ef2:	e852                	sd	s4,16(sp)
    80001ef4:	e456                	sd	s5,8(sp)
    80001ef6:	e05a                	sd	s6,0(sp)
    80001ef8:	0080                	addi	s0,sp,64
    80001efa:	8a2a                	mv	s4,a0
    80001efc:	892e                	mv	s2,a1
  for (p = proc; p < &proc[NPROC]; p++)
    80001efe:	0000f497          	auipc	s1,0xf
    80001f02:	7d248493          	addi	s1,s1,2002 # 800116d0 <proc>
{ int prev = -1;
    80001f06:	5afd                	li	s5,-1
      printf("%d",p->sp);
    80001f08:	00006b17          	auipc	s6,0x6
    80001f0c:	310b0b13          	addi	s6,s6,784 # 80008218 <digits+0x1d8>
  for (p = proc; p < &proc[NPROC]; p++)
    80001f10:	00016997          	auipc	s3,0x16
    80001f14:	9c098993          	addi	s3,s3,-1600 # 800178d0 <tickslock>
    80001f18:	a80d                	j	80001f4a <set_priority+0x64>
    { prev= p->sp;
    80001f1a:	0444aa83          	lw	s5,68(s1)
      acquire(&p->lock);
    80001f1e:	8526                	mv	a0,s1
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	cc4080e7          	jalr	-828(ra) # 80000be4 <acquire>
      printf("%d",p->sp);
    80001f28:	40ec                	lw	a1,68(s1)
    80001f2a:	855a                	mv	a0,s6
    80001f2c:	ffffe097          	auipc	ra,0xffffe
    80001f30:	65c080e7          	jalr	1628(ra) # 80000588 <printf>
      p->sp = sp;
    80001f34:	0544a223          	sw	s4,68(s1)
      release(&p->lock);
    80001f38:	8526                	mv	a0,s1
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	d5e080e7          	jalr	-674(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001f42:	18848493          	addi	s1,s1,392
    80001f46:	01348663          	beq	s1,s3,80001f52 <set_priority+0x6c>
    if (p->pid == pid)
    80001f4a:	589c                	lw	a5,48(s1)
    80001f4c:	ff279be3          	bne	a5,s2,80001f42 <set_priority+0x5c>
    80001f50:	b7e9                	j	80001f1a <set_priority+0x34>
}
    80001f52:	8556                	mv	a0,s5
    80001f54:	70e2                	ld	ra,56(sp)
    80001f56:	7442                	ld	s0,48(sp)
    80001f58:	74a2                	ld	s1,40(sp)
    80001f5a:	7902                	ld	s2,32(sp)
    80001f5c:	69e2                	ld	s3,24(sp)
    80001f5e:	6a42                	ld	s4,16(sp)
    80001f60:	6aa2                	ld	s5,8(sp)
    80001f62:	6b02                	ld	s6,0(sp)
    80001f64:	6121                	addi	sp,sp,64
    80001f66:	8082                	ret

0000000080001f68 <calculate_niceness>:
{
    80001f68:	1141                	addi	sp,sp,-16
    80001f6a:	e422                	sd	s0,8(sp)
    80001f6c:	0800                	addi	s0,sp,16
  if (p->rtime != 0)
    80001f6e:	5d5c                	lw	a5,60(a0)
    80001f70:	cb81                	beqz	a5,80001f80 <calculate_niceness+0x18>
    niceness = p->stime / (p->stime + p->rtime);
    80001f72:	4528                	lw	a0,72(a0)
    80001f74:	9fa9                	addw	a5,a5,a0
    80001f76:	02f5553b          	divuw	a0,a0,a5
}
    80001f7a:	6422                	ld	s0,8(sp)
    80001f7c:	0141                	addi	sp,sp,16
    80001f7e:	8082                	ret
  int niceness = 5;
    80001f80:	4515                	li	a0,5
    80001f82:	bfe5                	j	80001f7a <calculate_niceness+0x12>

0000000080001f84 <scheduler>:
{
    80001f84:	7119                	addi	sp,sp,-128
    80001f86:	fc86                	sd	ra,120(sp)
    80001f88:	f8a2                	sd	s0,112(sp)
    80001f8a:	f4a6                	sd	s1,104(sp)
    80001f8c:	f0ca                	sd	s2,96(sp)
    80001f8e:	ecce                	sd	s3,88(sp)
    80001f90:	e8d2                	sd	s4,80(sp)
    80001f92:	e4d6                	sd	s5,72(sp)
    80001f94:	e0da                	sd	s6,64(sp)
    80001f96:	fc5e                	sd	s7,56(sp)
    80001f98:	f862                	sd	s8,48(sp)
    80001f9a:	f466                	sd	s9,40(sp)
    80001f9c:	f06a                	sd	s10,32(sp)
    80001f9e:	ec6e                	sd	s11,24(sp)
    80001fa0:	0100                	addi	s0,sp,128
  printf("PBS");
    80001fa2:	00006517          	auipc	a0,0x6
    80001fa6:	27e50513          	addi	a0,a0,638 # 80008220 <digits+0x1e0>
    80001faa:	ffffe097          	auipc	ra,0xffffe
    80001fae:	5de080e7          	jalr	1502(ra) # 80000588 <printf>
    80001fb2:	8792                	mv	a5,tp
  int id = r_tp();
    80001fb4:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fb6:	00779693          	slli	a3,a5,0x7
    80001fba:	0000f717          	auipc	a4,0xf
    80001fbe:	2e670713          	addi	a4,a4,742 # 800112a0 <pid_lock>
    80001fc2:	9736                	add	a4,a4,a3
    80001fc4:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001fc8:	0000f717          	auipc	a4,0xf
    80001fcc:	31070713          	addi	a4,a4,784 # 800112d8 <cpus+0x8>
    80001fd0:	9736                	add	a4,a4,a3
    80001fd2:	f8e43423          	sd	a4,-120(s0)
  int highestDpriority = 0;
    80001fd6:	4a81                	li	s5,0
      { if(p->sp == 80){
    80001fd8:	05000b93          	li	s7,80
        printf("[%d]\n",p->sp);
    80001fdc:	00006d17          	auipc	s10,0x6
    80001fe0:	24cd0d13          	addi	s10,s10,588 # 80008228 <digits+0x1e8>
    for (p = proc; p < &proc[NPROC]; p++)
    80001fe4:	00016997          	auipc	s3,0x16
    80001fe8:	8ec98993          	addi	s3,s3,-1812 # 800178d0 <tickslock>
      { if(p->sp == 80){
    80001fec:	8cde                	mv	s9,s7
    80001fee:	06400c13          	li	s8,100
        c->proc = p;
    80001ff2:	0000fd97          	auipc	s11,0xf
    80001ff6:	2aed8d93          	addi	s11,s11,686 # 800112a0 <pid_lock>
    80001ffa:	9db6                	add	s11,s11,a3
    80001ffc:	a0f9                	j	800020ca <scheduler+0x146>
        printf("[%d]\n",p->sp);
    80001ffe:	85e6                	mv	a1,s9
    80002000:	856a                	mv	a0,s10
    80002002:	ffffe097          	auipc	ra,0xffffe
    80002006:	586080e7          	jalr	1414(ra) # 80000588 <printf>
    8000200a:	a839                	j	80002028 <scheduler+0xa4>
          highestDpriority = dp;
    8000200c:	8aaa                	mv	s5,a0
    8000200e:	8a26                	mv	s4,s1
    80002010:	a011                	j	80002014 <scheduler+0x90>
    80002012:	8a26                	mv	s4,s1
    for (p = proc; p < &proc[NPROC]; p++)
    80002014:	18848493          	addi	s1,s1,392
    80002018:	07348363          	beq	s1,s3,8000207e <scheduler+0xfa>
      if (p->state == RUNNABLE)
    8000201c:	4c9c                	lw	a5,24(s1)
    8000201e:	ff279be3          	bne	a5,s2,80002014 <scheduler+0x90>
      { if(p->sp == 80){
    80002022:	40fc                	lw	a5,68(s1)
    80002024:	fd778de3          	beq	a5,s7,80001ffe <scheduler+0x7a>
        niceness = calculate_niceness(p);
    80002028:	8526                	mv	a0,s1
    8000202a:	00000097          	auipc	ra,0x0
    8000202e:	f3e080e7          	jalr	-194(ra) # 80001f68 <calculate_niceness>
        dp = max(0, min(p->sp - niceness + 5, 100));
    80002032:	40fc                	lw	a5,68(s1)
    80002034:	2795                	addiw	a5,a5,5
    80002036:	40a7853b          	subw	a0,a5,a0
    8000203a:	0005079b          	sext.w	a5,a0
    8000203e:	00fb5363          	bge	s6,a5,80002044 <scheduler+0xc0>
    80002042:	8562                	mv	a0,s8
    80002044:	0005079b          	sext.w	a5,a0
    80002048:	fff7c793          	not	a5,a5
    8000204c:	97fd                	srai	a5,a5,0x3f
    8000204e:	8d7d                	and	a0,a0,a5
    80002050:	2501                	sext.w	a0,a0
        if (!pbs_process)
    80002052:	fa0a0de3          	beqz	s4,8000200c <scheduler+0x88>
        else if (highestDpriority > dp)
    80002056:	fb554ee3          	blt	a0,s5,80002012 <scheduler+0x8e>
        else if (highestDpriority == dp)
    8000205a:	fb551de3          	bne	a0,s5,80002014 <scheduler+0x90>
          if (p->scheduleNum < pbs_process->scheduleNum)
    8000205e:	48b8                	lw	a4,80(s1)
    80002060:	050a2783          	lw	a5,80(s4)
    80002064:	00f74b63          	blt	a4,a5,8000207a <scheduler+0xf6>
          else if (p->scheduleNum == pbs_process->scheduleNum && p->ctime < pbs_process->ctime)
    80002068:	faf716e3          	bne	a4,a5,80002014 <scheduler+0x90>
    8000206c:	5c98                	lw	a4,56(s1)
    8000206e:	038a2783          	lw	a5,56(s4)
    80002072:	faf771e3          	bgeu	a4,a5,80002014 <scheduler+0x90>
    80002076:	8a26                	mv	s4,s1
    80002078:	bf71                	j	80002014 <scheduler+0x90>
    8000207a:	8a26                	mv	s4,s1
    8000207c:	bf61                	j	80002014 <scheduler+0x90>
    if (pbs_process)
    8000207e:	040a0663          	beqz	s4,800020ca <scheduler+0x146>
      acquire(&p->lock);
    80002082:	84d2                	mv	s1,s4
    80002084:	8552                	mv	a0,s4
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	b5e080e7          	jalr	-1186(ra) # 80000be4 <acquire>
      if (p->state == RUNNABLE)
    8000208e:	018a2703          	lw	a4,24(s4)
    80002092:	478d                	li	a5,3
    80002094:	02f71663          	bne	a4,a5,800020c0 <scheduler+0x13c>
        p->state = RUNNING;
    80002098:	4791                	li	a5,4
    8000209a:	00fa2c23          	sw	a5,24(s4)
        p->scheduleNum += 1;
    8000209e:	050a2783          	lw	a5,80(s4)
    800020a2:	2785                	addiw	a5,a5,1
    800020a4:	04fa2823          	sw	a5,80(s4)
        c->proc = p;
    800020a8:	034db823          	sd	s4,48(s11)
        swtch(&c->context, &p->context);
    800020ac:	080a0593          	addi	a1,s4,128
    800020b0:	f8843503          	ld	a0,-120(s0)
    800020b4:	00001097          	auipc	ra,0x1
    800020b8:	85a080e7          	jalr	-1958(ra) # 8000290e <swtch>
        c->proc = 0;
    800020bc:	020db823          	sd	zero,48(s11)
      release(&p->lock);
    800020c0:	8526                	mv	a0,s1
    800020c2:	fffff097          	auipc	ra,0xfffff
    800020c6:	bd6080e7          	jalr	-1066(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020ca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020ce:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020d2:	10079073          	csrw	sstatus,a5
    pbs_process = 0;
    800020d6:	4a01                	li	s4,0
    for (p = proc; p < &proc[NPROC]; p++)
    800020d8:	0000f497          	auipc	s1,0xf
    800020dc:	5f848493          	addi	s1,s1,1528 # 800116d0 <proc>
      if (p->state == RUNNABLE)
    800020e0:	490d                	li	s2,3
    800020e2:	06400b13          	li	s6,100
    800020e6:	bf1d                	j	8000201c <scheduler+0x98>

00000000800020e8 <max>:
{
    800020e8:	1141                	addi	sp,sp,-16
    800020ea:	e422                	sd	s0,8(sp)
    800020ec:	0800                	addi	s0,sp,16
  if (a >= b)
    800020ee:	87aa                	mv	a5,a0
    800020f0:	00b55363          	bge	a0,a1,800020f6 <max+0xe>
    800020f4:	87ae                	mv	a5,a1
}
    800020f6:	0007851b          	sext.w	a0,a5
    800020fa:	6422                	ld	s0,8(sp)
    800020fc:	0141                	addi	sp,sp,16
    800020fe:	8082                	ret

0000000080002100 <min>:
{
    80002100:	1141                	addi	sp,sp,-16
    80002102:	e422                	sd	s0,8(sp)
    80002104:	0800                	addi	s0,sp,16
  if (a <= b)
    80002106:	87aa                	mv	a5,a0
    80002108:	00a5d363          	bge	a1,a0,8000210e <min+0xe>
    8000210c:	87ae                	mv	a5,a1
}
    8000210e:	0007851b          	sext.w	a0,a5
    80002112:	6422                	ld	s0,8(sp)
    80002114:	0141                	addi	sp,sp,16
    80002116:	8082                	ret

0000000080002118 <sched>:
{
    80002118:	7179                	addi	sp,sp,-48
    8000211a:	f406                	sd	ra,40(sp)
    8000211c:	f022                	sd	s0,32(sp)
    8000211e:	ec26                	sd	s1,24(sp)
    80002120:	e84a                	sd	s2,16(sp)
    80002122:	e44e                	sd	s3,8(sp)
    80002124:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002126:	00000097          	auipc	ra,0x0
    8000212a:	88a080e7          	jalr	-1910(ra) # 800019b0 <myproc>
    8000212e:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	a3a080e7          	jalr	-1478(ra) # 80000b6a <holding>
    80002138:	c93d                	beqz	a0,800021ae <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000213a:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    8000213c:	2781                	sext.w	a5,a5
    8000213e:	079e                	slli	a5,a5,0x7
    80002140:	0000f717          	auipc	a4,0xf
    80002144:	16070713          	addi	a4,a4,352 # 800112a0 <pid_lock>
    80002148:	97ba                	add	a5,a5,a4
    8000214a:	0a87a703          	lw	a4,168(a5)
    8000214e:	4785                	li	a5,1
    80002150:	06f71763          	bne	a4,a5,800021be <sched+0xa6>
  if (p->state == RUNNING)
    80002154:	4c98                	lw	a4,24(s1)
    80002156:	4791                	li	a5,4
    80002158:	06f70b63          	beq	a4,a5,800021ce <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000215c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002160:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002162:	efb5                	bnez	a5,800021de <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002164:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002166:	0000f917          	auipc	s2,0xf
    8000216a:	13a90913          	addi	s2,s2,314 # 800112a0 <pid_lock>
    8000216e:	2781                	sext.w	a5,a5
    80002170:	079e                	slli	a5,a5,0x7
    80002172:	97ca                	add	a5,a5,s2
    80002174:	0ac7a983          	lw	s3,172(a5)
    80002178:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000217a:	2781                	sext.w	a5,a5
    8000217c:	079e                	slli	a5,a5,0x7
    8000217e:	0000f597          	auipc	a1,0xf
    80002182:	15a58593          	addi	a1,a1,346 # 800112d8 <cpus+0x8>
    80002186:	95be                	add	a1,a1,a5
    80002188:	08048513          	addi	a0,s1,128
    8000218c:	00000097          	auipc	ra,0x0
    80002190:	782080e7          	jalr	1922(ra) # 8000290e <swtch>
    80002194:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002196:	2781                	sext.w	a5,a5
    80002198:	079e                	slli	a5,a5,0x7
    8000219a:	97ca                	add	a5,a5,s2
    8000219c:	0b37a623          	sw	s3,172(a5)
}
    800021a0:	70a2                	ld	ra,40(sp)
    800021a2:	7402                	ld	s0,32(sp)
    800021a4:	64e2                	ld	s1,24(sp)
    800021a6:	6942                	ld	s2,16(sp)
    800021a8:	69a2                	ld	s3,8(sp)
    800021aa:	6145                	addi	sp,sp,48
    800021ac:	8082                	ret
    panic("sched p->lock");
    800021ae:	00006517          	auipc	a0,0x6
    800021b2:	08250513          	addi	a0,a0,130 # 80008230 <digits+0x1f0>
    800021b6:	ffffe097          	auipc	ra,0xffffe
    800021ba:	388080e7          	jalr	904(ra) # 8000053e <panic>
    panic("sched locks");
    800021be:	00006517          	auipc	a0,0x6
    800021c2:	08250513          	addi	a0,a0,130 # 80008240 <digits+0x200>
    800021c6:	ffffe097          	auipc	ra,0xffffe
    800021ca:	378080e7          	jalr	888(ra) # 8000053e <panic>
    panic("sched running");
    800021ce:	00006517          	auipc	a0,0x6
    800021d2:	08250513          	addi	a0,a0,130 # 80008250 <digits+0x210>
    800021d6:	ffffe097          	auipc	ra,0xffffe
    800021da:	368080e7          	jalr	872(ra) # 8000053e <panic>
    panic("sched interruptible");
    800021de:	00006517          	auipc	a0,0x6
    800021e2:	08250513          	addi	a0,a0,130 # 80008260 <digits+0x220>
    800021e6:	ffffe097          	auipc	ra,0xffffe
    800021ea:	358080e7          	jalr	856(ra) # 8000053e <panic>

00000000800021ee <yield>:
{
    800021ee:	1101                	addi	sp,sp,-32
    800021f0:	ec06                	sd	ra,24(sp)
    800021f2:	e822                	sd	s0,16(sp)
    800021f4:	e426                	sd	s1,8(sp)
    800021f6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	7b8080e7          	jalr	1976(ra) # 800019b0 <myproc>
    80002200:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	9e2080e7          	jalr	-1566(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000220a:	478d                	li	a5,3
    8000220c:	cc9c                	sw	a5,24(s1)
  sched();
    8000220e:	00000097          	auipc	ra,0x0
    80002212:	f0a080e7          	jalr	-246(ra) # 80002118 <sched>
  release(&p->lock);
    80002216:	8526                	mv	a0,s1
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	a80080e7          	jalr	-1408(ra) # 80000c98 <release>
}
    80002220:	60e2                	ld	ra,24(sp)
    80002222:	6442                	ld	s0,16(sp)
    80002224:	64a2                	ld	s1,8(sp)
    80002226:	6105                	addi	sp,sp,32
    80002228:	8082                	ret

000000008000222a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000222a:	7179                	addi	sp,sp,-48
    8000222c:	f406                	sd	ra,40(sp)
    8000222e:	f022                	sd	s0,32(sp)
    80002230:	ec26                	sd	s1,24(sp)
    80002232:	e84a                	sd	s2,16(sp)
    80002234:	e44e                	sd	s3,8(sp)
    80002236:	1800                	addi	s0,sp,48
    80002238:	89aa                	mv	s3,a0
    8000223a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	774080e7          	jalr	1908(ra) # 800019b0 <myproc>
    80002244:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	99e080e7          	jalr	-1634(ra) # 80000be4 <acquire>
  release(lk);
    8000224e:	854a                	mv	a0,s2
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	a48080e7          	jalr	-1464(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002258:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000225c:	4789                	li	a5,2
    8000225e:	cc9c                	sw	a5,24(s1)
  proc->startsleep = ticks;
    80002260:	00007797          	auipc	a5,0x7
    80002264:	dd07a783          	lw	a5,-560(a5) # 80009030 <ticks>
    80002268:	0000f717          	auipc	a4,0xf
    8000226c:	4af72a23          	sw	a5,1204(a4) # 8001171c <proc+0x4c>
  sched();
    80002270:	00000097          	auipc	ra,0x0
    80002274:	ea8080e7          	jalr	-344(ra) # 80002118 <sched>

  // Tidy up.
  p->chan = 0;
    80002278:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000227c:	8526                	mv	a0,s1
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	a1a080e7          	jalr	-1510(ra) # 80000c98 <release>
  acquire(lk);
    80002286:	854a                	mv	a0,s2
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	95c080e7          	jalr	-1700(ra) # 80000be4 <acquire>
}
    80002290:	70a2                	ld	ra,40(sp)
    80002292:	7402                	ld	s0,32(sp)
    80002294:	64e2                	ld	s1,24(sp)
    80002296:	6942                	ld	s2,16(sp)
    80002298:	69a2                	ld	s3,8(sp)
    8000229a:	6145                	addi	sp,sp,48
    8000229c:	8082                	ret

000000008000229e <wait>:
{
    8000229e:	715d                	addi	sp,sp,-80
    800022a0:	e486                	sd	ra,72(sp)
    800022a2:	e0a2                	sd	s0,64(sp)
    800022a4:	fc26                	sd	s1,56(sp)
    800022a6:	f84a                	sd	s2,48(sp)
    800022a8:	f44e                	sd	s3,40(sp)
    800022aa:	f052                	sd	s4,32(sp)
    800022ac:	ec56                	sd	s5,24(sp)
    800022ae:	e85a                	sd	s6,16(sp)
    800022b0:	e45e                	sd	s7,8(sp)
    800022b2:	e062                	sd	s8,0(sp)
    800022b4:	0880                	addi	s0,sp,80
    800022b6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	6f8080e7          	jalr	1784(ra) # 800019b0 <myproc>
    800022c0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800022c2:	0000f517          	auipc	a0,0xf
    800022c6:	ff650513          	addi	a0,a0,-10 # 800112b8 <wait_lock>
    800022ca:	fffff097          	auipc	ra,0xfffff
    800022ce:	91a080e7          	jalr	-1766(ra) # 80000be4 <acquire>
    havekids = 0;
    800022d2:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    800022d4:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    800022d6:	00015997          	auipc	s3,0x15
    800022da:	5fa98993          	addi	s3,s3,1530 # 800178d0 <tickslock>
        havekids = 1;
    800022de:	4a85                	li	s5,1
    sleep(p, &wait_lock); //DOC: wait-sleep
    800022e0:	0000fc17          	auipc	s8,0xf
    800022e4:	fd8c0c13          	addi	s8,s8,-40 # 800112b8 <wait_lock>
    havekids = 0;
    800022e8:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    800022ea:	0000f497          	auipc	s1,0xf
    800022ee:	3e648493          	addi	s1,s1,998 # 800116d0 <proc>
    800022f2:	a0bd                	j	80002360 <wait+0xc2>
          pid = np->pid;
    800022f4:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022f8:	000b0e63          	beqz	s6,80002314 <wait+0x76>
    800022fc:	4691                	li	a3,4
    800022fe:	02c48613          	addi	a2,s1,44
    80002302:	85da                	mv	a1,s6
    80002304:	07093503          	ld	a0,112(s2)
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	36a080e7          	jalr	874(ra) # 80001672 <copyout>
    80002310:	02054563          	bltz	a0,8000233a <wait+0x9c>
          freeproc(np);
    80002314:	8526                	mv	a0,s1
    80002316:	00000097          	auipc	ra,0x0
    8000231a:	84c080e7          	jalr	-1972(ra) # 80001b62 <freeproc>
          release(&np->lock);
    8000231e:	8526                	mv	a0,s1
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	978080e7          	jalr	-1672(ra) # 80000c98 <release>
          release(&wait_lock);
    80002328:	0000f517          	auipc	a0,0xf
    8000232c:	f9050513          	addi	a0,a0,-112 # 800112b8 <wait_lock>
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	968080e7          	jalr	-1688(ra) # 80000c98 <release>
          return pid;
    80002338:	a09d                	j	8000239e <wait+0x100>
            release(&np->lock);
    8000233a:	8526                	mv	a0,s1
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	95c080e7          	jalr	-1700(ra) # 80000c98 <release>
            release(&wait_lock);
    80002344:	0000f517          	auipc	a0,0xf
    80002348:	f7450513          	addi	a0,a0,-140 # 800112b8 <wait_lock>
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	94c080e7          	jalr	-1716(ra) # 80000c98 <release>
            return -1;
    80002354:	59fd                	li	s3,-1
    80002356:	a0a1                	j	8000239e <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    80002358:	18848493          	addi	s1,s1,392
    8000235c:	03348463          	beq	s1,s3,80002384 <wait+0xe6>
      if (np->parent == p)
    80002360:	6cbc                	ld	a5,88(s1)
    80002362:	ff279be3          	bne	a5,s2,80002358 <wait+0xba>
        acquire(&np->lock);
    80002366:	8526                	mv	a0,s1
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	87c080e7          	jalr	-1924(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    80002370:	4c9c                	lw	a5,24(s1)
    80002372:	f94781e3          	beq	a5,s4,800022f4 <wait+0x56>
        release(&np->lock);
    80002376:	8526                	mv	a0,s1
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	920080e7          	jalr	-1760(ra) # 80000c98 <release>
        havekids = 1;
    80002380:	8756                	mv	a4,s5
    80002382:	bfd9                	j	80002358 <wait+0xba>
    if (!havekids || p->killed)
    80002384:	c701                	beqz	a4,8000238c <wait+0xee>
    80002386:	02892783          	lw	a5,40(s2)
    8000238a:	c79d                	beqz	a5,800023b8 <wait+0x11a>
      release(&wait_lock);
    8000238c:	0000f517          	auipc	a0,0xf
    80002390:	f2c50513          	addi	a0,a0,-212 # 800112b8 <wait_lock>
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	904080e7          	jalr	-1788(ra) # 80000c98 <release>
      return -1;
    8000239c:	59fd                	li	s3,-1
}
    8000239e:	854e                	mv	a0,s3
    800023a0:	60a6                	ld	ra,72(sp)
    800023a2:	6406                	ld	s0,64(sp)
    800023a4:	74e2                	ld	s1,56(sp)
    800023a6:	7942                	ld	s2,48(sp)
    800023a8:	79a2                	ld	s3,40(sp)
    800023aa:	7a02                	ld	s4,32(sp)
    800023ac:	6ae2                	ld	s5,24(sp)
    800023ae:	6b42                	ld	s6,16(sp)
    800023b0:	6ba2                	ld	s7,8(sp)
    800023b2:	6c02                	ld	s8,0(sp)
    800023b4:	6161                	addi	sp,sp,80
    800023b6:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    800023b8:	85e2                	mv	a1,s8
    800023ba:	854a                	mv	a0,s2
    800023bc:	00000097          	auipc	ra,0x0
    800023c0:	e6e080e7          	jalr	-402(ra) # 8000222a <sleep>
    havekids = 0;
    800023c4:	b715                	j	800022e8 <wait+0x4a>

00000000800023c6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800023c6:	715d                	addi	sp,sp,-80
    800023c8:	e486                	sd	ra,72(sp)
    800023ca:	e0a2                	sd	s0,64(sp)
    800023cc:	fc26                	sd	s1,56(sp)
    800023ce:	f84a                	sd	s2,48(sp)
    800023d0:	f44e                	sd	s3,40(sp)
    800023d2:	f052                	sd	s4,32(sp)
    800023d4:	ec56                	sd	s5,24(sp)
    800023d6:	e85a                	sd	s6,16(sp)
    800023d8:	e45e                	sd	s7,8(sp)
    800023da:	0880                	addi	s0,sp,80
    800023dc:	8aaa                	mv	s5,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800023de:	0000f497          	auipc	s1,0xf
    800023e2:	2f248493          	addi	s1,s1,754 # 800116d0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800023e6:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800023e8:	4b8d                	li	s7,3
        proc->stime+= ticks-proc->startsleep;
    800023ea:	8a26                	mv	s4,s1
    800023ec:	00007b17          	auipc	s6,0x7
    800023f0:	c44b0b13          	addi	s6,s6,-956 # 80009030 <ticks>
  for (p = proc; p < &proc[NPROC]; p++)
    800023f4:	00015917          	auipc	s2,0x15
    800023f8:	4dc90913          	addi	s2,s2,1244 # 800178d0 <tickslock>
    800023fc:	a805                	j	8000242c <wakeup+0x66>
        p->state = RUNNABLE;
    800023fe:	0174ac23          	sw	s7,24(s1)
        proc->stime+= ticks-proc->startsleep;
    80002402:	048a2783          	lw	a5,72(s4)
    80002406:	000b2703          	lw	a4,0(s6)
    8000240a:	9fb9                	addw	a5,a5,a4
    8000240c:	04ca2703          	lw	a4,76(s4)
    80002410:	9f99                	subw	a5,a5,a4
    80002412:	04fa2423          	sw	a5,72(s4)
        proc->startsleep =0;
    80002416:	040a2623          	sw	zero,76(s4)
        //printf("Aaaaaaaaaaa,%d",proc->stime);
      }
      release(&p->lock);
    8000241a:	8526                	mv	a0,s1
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	87c080e7          	jalr	-1924(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002424:	18848493          	addi	s1,s1,392
    80002428:	03248463          	beq	s1,s2,80002450 <wakeup+0x8a>
    if (p != myproc())
    8000242c:	fffff097          	auipc	ra,0xfffff
    80002430:	584080e7          	jalr	1412(ra) # 800019b0 <myproc>
    80002434:	fea488e3          	beq	s1,a0,80002424 <wakeup+0x5e>
      acquire(&p->lock);
    80002438:	8526                	mv	a0,s1
    8000243a:	ffffe097          	auipc	ra,0xffffe
    8000243e:	7aa080e7          	jalr	1962(ra) # 80000be4 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002442:	4c9c                	lw	a5,24(s1)
    80002444:	fd379be3          	bne	a5,s3,8000241a <wakeup+0x54>
    80002448:	709c                	ld	a5,32(s1)
    8000244a:	fd5798e3          	bne	a5,s5,8000241a <wakeup+0x54>
    8000244e:	bf45                	j	800023fe <wakeup+0x38>
    }
  }
}
    80002450:	60a6                	ld	ra,72(sp)
    80002452:	6406                	ld	s0,64(sp)
    80002454:	74e2                	ld	s1,56(sp)
    80002456:	7942                	ld	s2,48(sp)
    80002458:	79a2                	ld	s3,40(sp)
    8000245a:	7a02                	ld	s4,32(sp)
    8000245c:	6ae2                	ld	s5,24(sp)
    8000245e:	6b42                	ld	s6,16(sp)
    80002460:	6ba2                	ld	s7,8(sp)
    80002462:	6161                	addi	sp,sp,80
    80002464:	8082                	ret

0000000080002466 <reparent>:
{
    80002466:	7179                	addi	sp,sp,-48
    80002468:	f406                	sd	ra,40(sp)
    8000246a:	f022                	sd	s0,32(sp)
    8000246c:	ec26                	sd	s1,24(sp)
    8000246e:	e84a                	sd	s2,16(sp)
    80002470:	e44e                	sd	s3,8(sp)
    80002472:	e052                	sd	s4,0(sp)
    80002474:	1800                	addi	s0,sp,48
    80002476:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002478:	0000f497          	auipc	s1,0xf
    8000247c:	25848493          	addi	s1,s1,600 # 800116d0 <proc>
      pp->parent = initproc;
    80002480:	00007a17          	auipc	s4,0x7
    80002484:	ba8a0a13          	addi	s4,s4,-1112 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002488:	00015997          	auipc	s3,0x15
    8000248c:	44898993          	addi	s3,s3,1096 # 800178d0 <tickslock>
    80002490:	a029                	j	8000249a <reparent+0x34>
    80002492:	18848493          	addi	s1,s1,392
    80002496:	01348d63          	beq	s1,s3,800024b0 <reparent+0x4a>
    if (pp->parent == p)
    8000249a:	6cbc                	ld	a5,88(s1)
    8000249c:	ff279be3          	bne	a5,s2,80002492 <reparent+0x2c>
      pp->parent = initproc;
    800024a0:	000a3503          	ld	a0,0(s4)
    800024a4:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    800024a6:	00000097          	auipc	ra,0x0
    800024aa:	f20080e7          	jalr	-224(ra) # 800023c6 <wakeup>
    800024ae:	b7d5                	j	80002492 <reparent+0x2c>
}
    800024b0:	70a2                	ld	ra,40(sp)
    800024b2:	7402                	ld	s0,32(sp)
    800024b4:	64e2                	ld	s1,24(sp)
    800024b6:	6942                	ld	s2,16(sp)
    800024b8:	69a2                	ld	s3,8(sp)
    800024ba:	6a02                	ld	s4,0(sp)
    800024bc:	6145                	addi	sp,sp,48
    800024be:	8082                	ret

00000000800024c0 <exit>:
{
    800024c0:	7179                	addi	sp,sp,-48
    800024c2:	f406                	sd	ra,40(sp)
    800024c4:	f022                	sd	s0,32(sp)
    800024c6:	ec26                	sd	s1,24(sp)
    800024c8:	e84a                	sd	s2,16(sp)
    800024ca:	e44e                	sd	s3,8(sp)
    800024cc:	e052                	sd	s4,0(sp)
    800024ce:	1800                	addi	s0,sp,48
    800024d0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	4de080e7          	jalr	1246(ra) # 800019b0 <myproc>
    800024da:	89aa                	mv	s3,a0
  if (p == initproc)
    800024dc:	00007797          	auipc	a5,0x7
    800024e0:	b4c7b783          	ld	a5,-1204(a5) # 80009028 <initproc>
    800024e4:	0f050493          	addi	s1,a0,240
    800024e8:	17050913          	addi	s2,a0,368
    800024ec:	02a79363          	bne	a5,a0,80002512 <exit+0x52>
    panic("init exiting");
    800024f0:	00006517          	auipc	a0,0x6
    800024f4:	d8850513          	addi	a0,a0,-632 # 80008278 <digits+0x238>
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	046080e7          	jalr	70(ra) # 8000053e <panic>
      fileclose(f);
    80002500:	00002097          	auipc	ra,0x2
    80002504:	4a8080e7          	jalr	1192(ra) # 800049a8 <fileclose>
      p->ofile[fd] = 0;
    80002508:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000250c:	04a1                	addi	s1,s1,8
    8000250e:	01248563          	beq	s1,s2,80002518 <exit+0x58>
    if (p->ofile[fd])
    80002512:	6088                	ld	a0,0(s1)
    80002514:	f575                	bnez	a0,80002500 <exit+0x40>
    80002516:	bfdd                	j	8000250c <exit+0x4c>
  begin_op();
    80002518:	00002097          	auipc	ra,0x2
    8000251c:	fc4080e7          	jalr	-60(ra) # 800044dc <begin_op>
  iput(p->cwd);
    80002520:	1709b503          	ld	a0,368(s3)
    80002524:	00001097          	auipc	ra,0x1
    80002528:	7a0080e7          	jalr	1952(ra) # 80003cc4 <iput>
  end_op();
    8000252c:	00002097          	auipc	ra,0x2
    80002530:	030080e7          	jalr	48(ra) # 8000455c <end_op>
  p->cwd = 0;
    80002534:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    80002538:	0000f497          	auipc	s1,0xf
    8000253c:	d8048493          	addi	s1,s1,-640 # 800112b8 <wait_lock>
    80002540:	8526                	mv	a0,s1
    80002542:	ffffe097          	auipc	ra,0xffffe
    80002546:	6a2080e7          	jalr	1698(ra) # 80000be4 <acquire>
  reparent(p);
    8000254a:	854e                	mv	a0,s3
    8000254c:	00000097          	auipc	ra,0x0
    80002550:	f1a080e7          	jalr	-230(ra) # 80002466 <reparent>
  wakeup(p->parent);
    80002554:	0589b503          	ld	a0,88(s3)
    80002558:	00000097          	auipc	ra,0x0
    8000255c:	e6e080e7          	jalr	-402(ra) # 800023c6 <wakeup>
  acquire(&p->lock);
    80002560:	854e                	mv	a0,s3
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	682080e7          	jalr	1666(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000256a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000256e:	4795                	li	a5,5
    80002570:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002574:	00007797          	auipc	a5,0x7
    80002578:	abc7a783          	lw	a5,-1348(a5) # 80009030 <ticks>
    8000257c:	04f9a023          	sw	a5,64(s3)
  release(&wait_lock);
    80002580:	8526                	mv	a0,s1
    80002582:	ffffe097          	auipc	ra,0xffffe
    80002586:	716080e7          	jalr	1814(ra) # 80000c98 <release>
  sched();
    8000258a:	00000097          	auipc	ra,0x0
    8000258e:	b8e080e7          	jalr	-1138(ra) # 80002118 <sched>
  panic("zombie exit");
    80002592:	00006517          	auipc	a0,0x6
    80002596:	cf650513          	addi	a0,a0,-778 # 80008288 <digits+0x248>
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	fa4080e7          	jalr	-92(ra) # 8000053e <panic>

00000000800025a2 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025a2:	7179                	addi	sp,sp,-48
    800025a4:	f406                	sd	ra,40(sp)
    800025a6:	f022                	sd	s0,32(sp)
    800025a8:	ec26                	sd	s1,24(sp)
    800025aa:	e84a                	sd	s2,16(sp)
    800025ac:	e44e                	sd	s3,8(sp)
    800025ae:	1800                	addi	s0,sp,48
    800025b0:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800025b2:	0000f497          	auipc	s1,0xf
    800025b6:	11e48493          	addi	s1,s1,286 # 800116d0 <proc>
    800025ba:	00015997          	auipc	s3,0x15
    800025be:	31698993          	addi	s3,s3,790 # 800178d0 <tickslock>
  {
    acquire(&p->lock);
    800025c2:	8526                	mv	a0,s1
    800025c4:	ffffe097          	auipc	ra,0xffffe
    800025c8:	620080e7          	jalr	1568(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    800025cc:	589c                	lw	a5,48(s1)
    800025ce:	01278d63          	beq	a5,s2,800025e8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025d2:	8526                	mv	a0,s1
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	6c4080e7          	jalr	1732(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800025dc:	18848493          	addi	s1,s1,392
    800025e0:	ff3491e3          	bne	s1,s3,800025c2 <kill+0x20>
  }
  return -1;
    800025e4:	557d                	li	a0,-1
    800025e6:	a829                	j	80002600 <kill+0x5e>
      p->killed = 1;
    800025e8:	4785                	li	a5,1
    800025ea:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800025ec:	4c98                	lw	a4,24(s1)
    800025ee:	4789                	li	a5,2
    800025f0:	00f70f63          	beq	a4,a5,8000260e <kill+0x6c>
      release(&p->lock);
    800025f4:	8526                	mv	a0,s1
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	6a2080e7          	jalr	1698(ra) # 80000c98 <release>
      return 0;
    800025fe:	4501                	li	a0,0
}
    80002600:	70a2                	ld	ra,40(sp)
    80002602:	7402                	ld	s0,32(sp)
    80002604:	64e2                	ld	s1,24(sp)
    80002606:	6942                	ld	s2,16(sp)
    80002608:	69a2                	ld	s3,8(sp)
    8000260a:	6145                	addi	sp,sp,48
    8000260c:	8082                	ret
        p->state = RUNNABLE;
    8000260e:	478d                	li	a5,3
    80002610:	cc9c                	sw	a5,24(s1)
    80002612:	b7cd                	j	800025f4 <kill+0x52>

0000000080002614 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002614:	7179                	addi	sp,sp,-48
    80002616:	f406                	sd	ra,40(sp)
    80002618:	f022                	sd	s0,32(sp)
    8000261a:	ec26                	sd	s1,24(sp)
    8000261c:	e84a                	sd	s2,16(sp)
    8000261e:	e44e                	sd	s3,8(sp)
    80002620:	e052                	sd	s4,0(sp)
    80002622:	1800                	addi	s0,sp,48
    80002624:	84aa                	mv	s1,a0
    80002626:	892e                	mv	s2,a1
    80002628:	89b2                	mv	s3,a2
    8000262a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000262c:	fffff097          	auipc	ra,0xfffff
    80002630:	384080e7          	jalr	900(ra) # 800019b0 <myproc>
  if (user_dst)
    80002634:	c08d                	beqz	s1,80002656 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002636:	86d2                	mv	a3,s4
    80002638:	864e                	mv	a2,s3
    8000263a:	85ca                	mv	a1,s2
    8000263c:	7928                	ld	a0,112(a0)
    8000263e:	fffff097          	auipc	ra,0xfffff
    80002642:	034080e7          	jalr	52(ra) # 80001672 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002646:	70a2                	ld	ra,40(sp)
    80002648:	7402                	ld	s0,32(sp)
    8000264a:	64e2                	ld	s1,24(sp)
    8000264c:	6942                	ld	s2,16(sp)
    8000264e:	69a2                	ld	s3,8(sp)
    80002650:	6a02                	ld	s4,0(sp)
    80002652:	6145                	addi	sp,sp,48
    80002654:	8082                	ret
    memmove((char *)dst, src, len);
    80002656:	000a061b          	sext.w	a2,s4
    8000265a:	85ce                	mv	a1,s3
    8000265c:	854a                	mv	a0,s2
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	6e2080e7          	jalr	1762(ra) # 80000d40 <memmove>
    return 0;
    80002666:	8526                	mv	a0,s1
    80002668:	bff9                	j	80002646 <either_copyout+0x32>

000000008000266a <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000266a:	7179                	addi	sp,sp,-48
    8000266c:	f406                	sd	ra,40(sp)
    8000266e:	f022                	sd	s0,32(sp)
    80002670:	ec26                	sd	s1,24(sp)
    80002672:	e84a                	sd	s2,16(sp)
    80002674:	e44e                	sd	s3,8(sp)
    80002676:	e052                	sd	s4,0(sp)
    80002678:	1800                	addi	s0,sp,48
    8000267a:	892a                	mv	s2,a0
    8000267c:	84ae                	mv	s1,a1
    8000267e:	89b2                	mv	s3,a2
    80002680:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002682:	fffff097          	auipc	ra,0xfffff
    80002686:	32e080e7          	jalr	814(ra) # 800019b0 <myproc>
  if (user_src)
    8000268a:	c08d                	beqz	s1,800026ac <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000268c:	86d2                	mv	a3,s4
    8000268e:	864e                	mv	a2,s3
    80002690:	85ca                	mv	a1,s2
    80002692:	7928                	ld	a0,112(a0)
    80002694:	fffff097          	auipc	ra,0xfffff
    80002698:	06a080e7          	jalr	106(ra) # 800016fe <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000269c:	70a2                	ld	ra,40(sp)
    8000269e:	7402                	ld	s0,32(sp)
    800026a0:	64e2                	ld	s1,24(sp)
    800026a2:	6942                	ld	s2,16(sp)
    800026a4:	69a2                	ld	s3,8(sp)
    800026a6:	6a02                	ld	s4,0(sp)
    800026a8:	6145                	addi	sp,sp,48
    800026aa:	8082                	ret
    memmove(dst, (char *)src, len);
    800026ac:	000a061b          	sext.w	a2,s4
    800026b0:	85ce                	mv	a1,s3
    800026b2:	854a                	mv	a0,s2
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	68c080e7          	jalr	1676(ra) # 80000d40 <memmove>
    return 0;
    800026bc:	8526                	mv	a0,s1
    800026be:	bff9                	j	8000269c <either_copyin+0x32>

00000000800026c0 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800026c0:	715d                	addi	sp,sp,-80
    800026c2:	e486                	sd	ra,72(sp)
    800026c4:	e0a2                	sd	s0,64(sp)
    800026c6:	fc26                	sd	s1,56(sp)
    800026c8:	f84a                	sd	s2,48(sp)
    800026ca:	f44e                	sd	s3,40(sp)
    800026cc:	f052                	sd	s4,32(sp)
    800026ce:	ec56                	sd	s5,24(sp)
    800026d0:	e85a                	sd	s6,16(sp)
    800026d2:	e45e                	sd	s7,8(sp)
    800026d4:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800026d6:	00006517          	auipc	a0,0x6
    800026da:	9f250513          	addi	a0,a0,-1550 # 800080c8 <digits+0x88>
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	eaa080e7          	jalr	-342(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800026e6:	0000f497          	auipc	s1,0xf
    800026ea:	16248493          	addi	s1,s1,354 # 80011848 <proc+0x178>
    800026ee:	00015917          	auipc	s2,0x15
    800026f2:	35a90913          	addi	s2,s2,858 # 80017a48 <bcache+0x160>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026f6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026f8:	00006997          	auipc	s3,0x6
    800026fc:	ba098993          	addi	s3,s3,-1120 # 80008298 <digits+0x258>
    printf("%d %s %s", p->pid, state, p->name);
    80002700:	00006a97          	auipc	s5,0x6
    80002704:	ba0a8a93          	addi	s5,s5,-1120 # 800082a0 <digits+0x260>
    printf("\n");
    80002708:	00006a17          	auipc	s4,0x6
    8000270c:	9c0a0a13          	addi	s4,s4,-1600 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002710:	00006b97          	auipc	s7,0x6
    80002714:	bc8b8b93          	addi	s7,s7,-1080 # 800082d8 <states.1758>
    80002718:	a00d                	j	8000273a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000271a:	eb86a583          	lw	a1,-328(a3)
    8000271e:	8556                	mv	a0,s5
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	e68080e7          	jalr	-408(ra) # 80000588 <printf>
    printf("\n");
    80002728:	8552                	mv	a0,s4
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	e5e080e7          	jalr	-418(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002732:	18848493          	addi	s1,s1,392
    80002736:	03248163          	beq	s1,s2,80002758 <procdump+0x98>
    if (p->state == UNUSED)
    8000273a:	86a6                	mv	a3,s1
    8000273c:	ea04a783          	lw	a5,-352(s1)
    80002740:	dbed                	beqz	a5,80002732 <procdump+0x72>
      state = "???";
    80002742:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002744:	fcfb6be3          	bltu	s6,a5,8000271a <procdump+0x5a>
    80002748:	1782                	slli	a5,a5,0x20
    8000274a:	9381                	srli	a5,a5,0x20
    8000274c:	078e                	slli	a5,a5,0x3
    8000274e:	97de                	add	a5,a5,s7
    80002750:	6390                	ld	a2,0(a5)
    80002752:	f661                	bnez	a2,8000271a <procdump+0x5a>
      state = "???";
    80002754:	864e                	mv	a2,s3
    80002756:	b7d1                	j	8000271a <procdump+0x5a>
  }
}
    80002758:	60a6                	ld	ra,72(sp)
    8000275a:	6406                	ld	s0,64(sp)
    8000275c:	74e2                	ld	s1,56(sp)
    8000275e:	7942                	ld	s2,48(sp)
    80002760:	79a2                	ld	s3,40(sp)
    80002762:	7a02                	ld	s4,32(sp)
    80002764:	6ae2                	ld	s5,24(sp)
    80002766:	6b42                	ld	s6,16(sp)
    80002768:	6ba2                	ld	s7,8(sp)
    8000276a:	6161                	addi	sp,sp,80
    8000276c:	8082                	ret

000000008000276e <update_time>:

void update_time()
{
    8000276e:	7179                	addi	sp,sp,-48
    80002770:	f406                	sd	ra,40(sp)
    80002772:	f022                	sd	s0,32(sp)
    80002774:	ec26                	sd	s1,24(sp)
    80002776:	e84a                	sd	s2,16(sp)
    80002778:	e44e                	sd	s3,8(sp)
    8000277a:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    8000277c:	0000f497          	auipc	s1,0xf
    80002780:	f5448493          	addi	s1,s1,-172 # 800116d0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002784:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002786:	00015917          	auipc	s2,0x15
    8000278a:	14a90913          	addi	s2,s2,330 # 800178d0 <tickslock>
    8000278e:	a811                	j	800027a2 <update_time+0x34>
    {
      p->rtime++;
      //printf("%d\n", p->rtime);
    }
    release(&p->lock);
    80002790:	8526                	mv	a0,s1
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	506080e7          	jalr	1286(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000279a:	18848493          	addi	s1,s1,392
    8000279e:	01248e63          	beq	s1,s2,800027ba <update_time+0x4c>
    acquire(&p->lock);
    800027a2:	8526                	mv	a0,s1
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	440080e7          	jalr	1088(ra) # 80000be4 <acquire>
    if (p->state == RUNNING)
    800027ac:	4c9c                	lw	a5,24(s1)
    800027ae:	ff3791e3          	bne	a5,s3,80002790 <update_time+0x22>
      p->rtime++;
    800027b2:	5cdc                	lw	a5,60(s1)
    800027b4:	2785                	addiw	a5,a5,1
    800027b6:	dcdc                	sw	a5,60(s1)
    800027b8:	bfe1                	j	80002790 <update_time+0x22>
  }
}
    800027ba:	70a2                	ld	ra,40(sp)
    800027bc:	7402                	ld	s0,32(sp)
    800027be:	64e2                	ld	s1,24(sp)
    800027c0:	6942                	ld	s2,16(sp)
    800027c2:	69a2                	ld	s3,8(sp)
    800027c4:	6145                	addi	sp,sp,48
    800027c6:	8082                	ret

00000000800027c8 <waitx>:

int
waitx(uint64 addr, uint* rtime, uint* wtime)
{
    800027c8:	711d                	addi	sp,sp,-96
    800027ca:	ec86                	sd	ra,88(sp)
    800027cc:	e8a2                	sd	s0,80(sp)
    800027ce:	e4a6                	sd	s1,72(sp)
    800027d0:	e0ca                	sd	s2,64(sp)
    800027d2:	fc4e                	sd	s3,56(sp)
    800027d4:	f852                	sd	s4,48(sp)
    800027d6:	f456                	sd	s5,40(sp)
    800027d8:	f05a                	sd	s6,32(sp)
    800027da:	ec5e                	sd	s7,24(sp)
    800027dc:	e862                	sd	s8,16(sp)
    800027de:	e466                	sd	s9,8(sp)
    800027e0:	e06a                	sd	s10,0(sp)
    800027e2:	1080                	addi	s0,sp,96
    800027e4:	8b2a                	mv	s6,a0
    800027e6:	8c2e                	mv	s8,a1
    800027e8:	8bb2                	mv	s7,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800027ea:	fffff097          	auipc	ra,0xfffff
    800027ee:	1c6080e7          	jalr	454(ra) # 800019b0 <myproc>
    800027f2:	892a                	mv	s2,a0

  acquire(&wait_lock);
    800027f4:	0000f517          	auipc	a0,0xf
    800027f8:	ac450513          	addi	a0,a0,-1340 # 800112b8 <wait_lock>
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	3e8080e7          	jalr	1000(ra) # 80000be4 <acquire>

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    80002804:	4c81                	li	s9,0
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
    80002806:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002808:	00015997          	auipc	s3,0x15
    8000280c:	0c898993          	addi	s3,s3,200 # 800178d0 <tickslock>
        havekids = 1;
    80002810:	4a85                	li	s5,1
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002812:	0000fd17          	auipc	s10,0xf
    80002816:	aa6d0d13          	addi	s10,s10,-1370 # 800112b8 <wait_lock>
    havekids = 0;
    8000281a:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    8000281c:	0000f497          	auipc	s1,0xf
    80002820:	eb448493          	addi	s1,s1,-332 # 800116d0 <proc>
    80002824:	a041                	j	800028a4 <waitx+0xdc>
          pid = np->pid;
    80002826:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000282a:	5cd8                	lw	a4,60(s1)
    8000282c:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002830:	5c9c                	lw	a5,56(s1)
    80002832:	9f3d                	addw	a4,a4,a5
    80002834:	40bc                	lw	a5,64(s1)
    80002836:	9f99                	subw	a5,a5,a4
    80002838:	00fba023          	sw	a5,0(s7)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000283c:	000b0e63          	beqz	s6,80002858 <waitx+0x90>
    80002840:	4691                	li	a3,4
    80002842:	02c48613          	addi	a2,s1,44
    80002846:	85da                	mv	a1,s6
    80002848:	07093503          	ld	a0,112(s2)
    8000284c:	fffff097          	auipc	ra,0xfffff
    80002850:	e26080e7          	jalr	-474(ra) # 80001672 <copyout>
    80002854:	02054563          	bltz	a0,8000287e <waitx+0xb6>
          freeproc(np);
    80002858:	8526                	mv	a0,s1
    8000285a:	fffff097          	auipc	ra,0xfffff
    8000285e:	308080e7          	jalr	776(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002862:	8526                	mv	a0,s1
    80002864:	ffffe097          	auipc	ra,0xffffe
    80002868:	434080e7          	jalr	1076(ra) # 80000c98 <release>
          release(&wait_lock);
    8000286c:	0000f517          	auipc	a0,0xf
    80002870:	a4c50513          	addi	a0,a0,-1460 # 800112b8 <wait_lock>
    80002874:	ffffe097          	auipc	ra,0xffffe
    80002878:	424080e7          	jalr	1060(ra) # 80000c98 <release>
          return pid;
    8000287c:	a09d                	j	800028e2 <waitx+0x11a>
            release(&np->lock);
    8000287e:	8526                	mv	a0,s1
    80002880:	ffffe097          	auipc	ra,0xffffe
    80002884:	418080e7          	jalr	1048(ra) # 80000c98 <release>
            release(&wait_lock);
    80002888:	0000f517          	auipc	a0,0xf
    8000288c:	a3050513          	addi	a0,a0,-1488 # 800112b8 <wait_lock>
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	408080e7          	jalr	1032(ra) # 80000c98 <release>
            return -1;
    80002898:	59fd                	li	s3,-1
    8000289a:	a0a1                	j	800028e2 <waitx+0x11a>
    for(np = proc; np < &proc[NPROC]; np++){
    8000289c:	18848493          	addi	s1,s1,392
    800028a0:	03348463          	beq	s1,s3,800028c8 <waitx+0x100>
      if(np->parent == p){
    800028a4:	6cbc                	ld	a5,88(s1)
    800028a6:	ff279be3          	bne	a5,s2,8000289c <waitx+0xd4>
        acquire(&np->lock);
    800028aa:	8526                	mv	a0,s1
    800028ac:	ffffe097          	auipc	ra,0xffffe
    800028b0:	338080e7          	jalr	824(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800028b4:	4c9c                	lw	a5,24(s1)
    800028b6:	f74788e3          	beq	a5,s4,80002826 <waitx+0x5e>
        release(&np->lock);
    800028ba:	8526                	mv	a0,s1
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	3dc080e7          	jalr	988(ra) # 80000c98 <release>
        havekids = 1;
    800028c4:	8756                	mv	a4,s5
    800028c6:	bfd9                	j	8000289c <waitx+0xd4>
    if(!havekids || p->killed){
    800028c8:	c701                	beqz	a4,800028d0 <waitx+0x108>
    800028ca:	02892783          	lw	a5,40(s2)
    800028ce:	cb8d                	beqz	a5,80002900 <waitx+0x138>
      release(&wait_lock);
    800028d0:	0000f517          	auipc	a0,0xf
    800028d4:	9e850513          	addi	a0,a0,-1560 # 800112b8 <wait_lock>
    800028d8:	ffffe097          	auipc	ra,0xffffe
    800028dc:	3c0080e7          	jalr	960(ra) # 80000c98 <release>
      return -1;
    800028e0:	59fd                	li	s3,-1
  }
}
    800028e2:	854e                	mv	a0,s3
    800028e4:	60e6                	ld	ra,88(sp)
    800028e6:	6446                	ld	s0,80(sp)
    800028e8:	64a6                	ld	s1,72(sp)
    800028ea:	6906                	ld	s2,64(sp)
    800028ec:	79e2                	ld	s3,56(sp)
    800028ee:	7a42                	ld	s4,48(sp)
    800028f0:	7aa2                	ld	s5,40(sp)
    800028f2:	7b02                	ld	s6,32(sp)
    800028f4:	6be2                	ld	s7,24(sp)
    800028f6:	6c42                	ld	s8,16(sp)
    800028f8:	6ca2                	ld	s9,8(sp)
    800028fa:	6d02                	ld	s10,0(sp)
    800028fc:	6125                	addi	sp,sp,96
    800028fe:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002900:	85ea                	mv	a1,s10
    80002902:	854a                	mv	a0,s2
    80002904:	00000097          	auipc	ra,0x0
    80002908:	926080e7          	jalr	-1754(ra) # 8000222a <sleep>
    havekids = 0;
    8000290c:	b739                	j	8000281a <waitx+0x52>

000000008000290e <swtch>:
    8000290e:	00153023          	sd	ra,0(a0)
    80002912:	00253423          	sd	sp,8(a0)
    80002916:	e900                	sd	s0,16(a0)
    80002918:	ed04                	sd	s1,24(a0)
    8000291a:	03253023          	sd	s2,32(a0)
    8000291e:	03353423          	sd	s3,40(a0)
    80002922:	03453823          	sd	s4,48(a0)
    80002926:	03553c23          	sd	s5,56(a0)
    8000292a:	05653023          	sd	s6,64(a0)
    8000292e:	05753423          	sd	s7,72(a0)
    80002932:	05853823          	sd	s8,80(a0)
    80002936:	05953c23          	sd	s9,88(a0)
    8000293a:	07a53023          	sd	s10,96(a0)
    8000293e:	07b53423          	sd	s11,104(a0)
    80002942:	0005b083          	ld	ra,0(a1)
    80002946:	0085b103          	ld	sp,8(a1)
    8000294a:	6980                	ld	s0,16(a1)
    8000294c:	6d84                	ld	s1,24(a1)
    8000294e:	0205b903          	ld	s2,32(a1)
    80002952:	0285b983          	ld	s3,40(a1)
    80002956:	0305ba03          	ld	s4,48(a1)
    8000295a:	0385ba83          	ld	s5,56(a1)
    8000295e:	0405bb03          	ld	s6,64(a1)
    80002962:	0485bb83          	ld	s7,72(a1)
    80002966:	0505bc03          	ld	s8,80(a1)
    8000296a:	0585bc83          	ld	s9,88(a1)
    8000296e:	0605bd03          	ld	s10,96(a1)
    80002972:	0685bd83          	ld	s11,104(a1)
    80002976:	8082                	ret

0000000080002978 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002978:	1141                	addi	sp,sp,-16
    8000297a:	e406                	sd	ra,8(sp)
    8000297c:	e022                	sd	s0,0(sp)
    8000297e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002980:	00006597          	auipc	a1,0x6
    80002984:	98858593          	addi	a1,a1,-1656 # 80008308 <states.1758+0x30>
    80002988:	00015517          	auipc	a0,0x15
    8000298c:	f4850513          	addi	a0,a0,-184 # 800178d0 <tickslock>
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	1c4080e7          	jalr	452(ra) # 80000b54 <initlock>
}
    80002998:	60a2                	ld	ra,8(sp)
    8000299a:	6402                	ld	s0,0(sp)
    8000299c:	0141                	addi	sp,sp,16
    8000299e:	8082                	ret

00000000800029a0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029a0:	1141                	addi	sp,sp,-16
    800029a2:	e422                	sd	s0,8(sp)
    800029a4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029a6:	00003797          	auipc	a5,0x3
    800029aa:	61a78793          	addi	a5,a5,1562 # 80005fc0 <kernelvec>
    800029ae:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029b2:	6422                	ld	s0,8(sp)
    800029b4:	0141                	addi	sp,sp,16
    800029b6:	8082                	ret

00000000800029b8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029b8:	1141                	addi	sp,sp,-16
    800029ba:	e406                	sd	ra,8(sp)
    800029bc:	e022                	sd	s0,0(sp)
    800029be:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029c0:	fffff097          	auipc	ra,0xfffff
    800029c4:	ff0080e7          	jalr	-16(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029cc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ce:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029d2:	00004617          	auipc	a2,0x4
    800029d6:	62e60613          	addi	a2,a2,1582 # 80007000 <_trampoline>
    800029da:	00004697          	auipc	a3,0x4
    800029de:	62668693          	addi	a3,a3,1574 # 80007000 <_trampoline>
    800029e2:	8e91                	sub	a3,a3,a2
    800029e4:	040007b7          	lui	a5,0x4000
    800029e8:	17fd                	addi	a5,a5,-1
    800029ea:	07b2                	slli	a5,a5,0xc
    800029ec:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ee:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029f2:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029f4:	180026f3          	csrr	a3,satp
    800029f8:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029fa:	7d38                	ld	a4,120(a0)
    800029fc:	7134                	ld	a3,96(a0)
    800029fe:	6585                	lui	a1,0x1
    80002a00:	96ae                	add	a3,a3,a1
    80002a02:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a04:	7d38                	ld	a4,120(a0)
    80002a06:	00000697          	auipc	a3,0x0
    80002a0a:	14668693          	addi	a3,a3,326 # 80002b4c <usertrap>
    80002a0e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a10:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a12:	8692                	mv	a3,tp
    80002a14:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a16:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a1a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a1e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a22:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a26:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a28:	6f18                	ld	a4,24(a4)
    80002a2a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a2e:	792c                	ld	a1,112(a0)
    80002a30:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a32:	00004717          	auipc	a4,0x4
    80002a36:	65e70713          	addi	a4,a4,1630 # 80007090 <userret>
    80002a3a:	8f11                	sub	a4,a4,a2
    80002a3c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a3e:	577d                	li	a4,-1
    80002a40:	177e                	slli	a4,a4,0x3f
    80002a42:	8dd9                	or	a1,a1,a4
    80002a44:	02000537          	lui	a0,0x2000
    80002a48:	157d                	addi	a0,a0,-1
    80002a4a:	0536                	slli	a0,a0,0xd
    80002a4c:	9782                	jalr	a5
}
    80002a4e:	60a2                	ld	ra,8(sp)
    80002a50:	6402                	ld	s0,0(sp)
    80002a52:	0141                	addi	sp,sp,16
    80002a54:	8082                	ret

0000000080002a56 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a56:	1101                	addi	sp,sp,-32
    80002a58:	ec06                	sd	ra,24(sp)
    80002a5a:	e822                	sd	s0,16(sp)
    80002a5c:	e426                	sd	s1,8(sp)
    80002a5e:	e04a                	sd	s2,0(sp)
    80002a60:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a62:	00015917          	auipc	s2,0x15
    80002a66:	e6e90913          	addi	s2,s2,-402 # 800178d0 <tickslock>
    80002a6a:	854a                	mv	a0,s2
    80002a6c:	ffffe097          	auipc	ra,0xffffe
    80002a70:	178080e7          	jalr	376(ra) # 80000be4 <acquire>
  ticks++;
    80002a74:	00006497          	auipc	s1,0x6
    80002a78:	5bc48493          	addi	s1,s1,1468 # 80009030 <ticks>
    80002a7c:	409c                	lw	a5,0(s1)
    80002a7e:	2785                	addiw	a5,a5,1
    80002a80:	c09c                	sw	a5,0(s1)
  update_time();
    80002a82:	00000097          	auipc	ra,0x0
    80002a86:	cec080e7          	jalr	-788(ra) # 8000276e <update_time>
  wakeup(&ticks);
    80002a8a:	8526                	mv	a0,s1
    80002a8c:	00000097          	auipc	ra,0x0
    80002a90:	93a080e7          	jalr	-1734(ra) # 800023c6 <wakeup>
  release(&tickslock);
    80002a94:	854a                	mv	a0,s2
    80002a96:	ffffe097          	auipc	ra,0xffffe
    80002a9a:	202080e7          	jalr	514(ra) # 80000c98 <release>
}
    80002a9e:	60e2                	ld	ra,24(sp)
    80002aa0:	6442                	ld	s0,16(sp)
    80002aa2:	64a2                	ld	s1,8(sp)
    80002aa4:	6902                	ld	s2,0(sp)
    80002aa6:	6105                	addi	sp,sp,32
    80002aa8:	8082                	ret

0000000080002aaa <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002aaa:	1101                	addi	sp,sp,-32
    80002aac:	ec06                	sd	ra,24(sp)
    80002aae:	e822                	sd	s0,16(sp)
    80002ab0:	e426                	sd	s1,8(sp)
    80002ab2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ab4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002ab8:	00074d63          	bltz	a4,80002ad2 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002abc:	57fd                	li	a5,-1
    80002abe:	17fe                	slli	a5,a5,0x3f
    80002ac0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002ac2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ac4:	06f70363          	beq	a4,a5,80002b2a <devintr+0x80>
  }
}
    80002ac8:	60e2                	ld	ra,24(sp)
    80002aca:	6442                	ld	s0,16(sp)
    80002acc:	64a2                	ld	s1,8(sp)
    80002ace:	6105                	addi	sp,sp,32
    80002ad0:	8082                	ret
     (scause & 0xff) == 9){
    80002ad2:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ad6:	46a5                	li	a3,9
    80002ad8:	fed792e3          	bne	a5,a3,80002abc <devintr+0x12>
    int irq = plic_claim();
    80002adc:	00003097          	auipc	ra,0x3
    80002ae0:	5ec080e7          	jalr	1516(ra) # 800060c8 <plic_claim>
    80002ae4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ae6:	47a9                	li	a5,10
    80002ae8:	02f50763          	beq	a0,a5,80002b16 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002aec:	4785                	li	a5,1
    80002aee:	02f50963          	beq	a0,a5,80002b20 <devintr+0x76>
    return 1;
    80002af2:	4505                	li	a0,1
    } else if(irq){
    80002af4:	d8f1                	beqz	s1,80002ac8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002af6:	85a6                	mv	a1,s1
    80002af8:	00006517          	auipc	a0,0x6
    80002afc:	81850513          	addi	a0,a0,-2024 # 80008310 <states.1758+0x38>
    80002b00:	ffffe097          	auipc	ra,0xffffe
    80002b04:	a88080e7          	jalr	-1400(ra) # 80000588 <printf>
      plic_complete(irq);
    80002b08:	8526                	mv	a0,s1
    80002b0a:	00003097          	auipc	ra,0x3
    80002b0e:	5e2080e7          	jalr	1506(ra) # 800060ec <plic_complete>
    return 1;
    80002b12:	4505                	li	a0,1
    80002b14:	bf55                	j	80002ac8 <devintr+0x1e>
      uartintr();
    80002b16:	ffffe097          	auipc	ra,0xffffe
    80002b1a:	e92080e7          	jalr	-366(ra) # 800009a8 <uartintr>
    80002b1e:	b7ed                	j	80002b08 <devintr+0x5e>
      virtio_disk_intr();
    80002b20:	00004097          	auipc	ra,0x4
    80002b24:	aac080e7          	jalr	-1364(ra) # 800065cc <virtio_disk_intr>
    80002b28:	b7c5                	j	80002b08 <devintr+0x5e>
    if(cpuid() == 0){
    80002b2a:	fffff097          	auipc	ra,0xfffff
    80002b2e:	e5a080e7          	jalr	-422(ra) # 80001984 <cpuid>
    80002b32:	c901                	beqz	a0,80002b42 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b34:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b38:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b3a:	14479073          	csrw	sip,a5
    return 2;
    80002b3e:	4509                	li	a0,2
    80002b40:	b761                	j	80002ac8 <devintr+0x1e>
      clockintr();
    80002b42:	00000097          	auipc	ra,0x0
    80002b46:	f14080e7          	jalr	-236(ra) # 80002a56 <clockintr>
    80002b4a:	b7ed                	j	80002b34 <devintr+0x8a>

0000000080002b4c <usertrap>:
{
    80002b4c:	1101                	addi	sp,sp,-32
    80002b4e:	ec06                	sd	ra,24(sp)
    80002b50:	e822                	sd	s0,16(sp)
    80002b52:	e426                	sd	s1,8(sp)
    80002b54:	e04a                	sd	s2,0(sp)
    80002b56:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b58:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b5c:	1007f793          	andi	a5,a5,256
    80002b60:	e3ad                	bnez	a5,80002bc2 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b62:	00003797          	auipc	a5,0x3
    80002b66:	45e78793          	addi	a5,a5,1118 # 80005fc0 <kernelvec>
    80002b6a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b6e:	fffff097          	auipc	ra,0xfffff
    80002b72:	e42080e7          	jalr	-446(ra) # 800019b0 <myproc>
    80002b76:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b78:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b7a:	14102773          	csrr	a4,sepc
    80002b7e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b80:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b84:	47a1                	li	a5,8
    80002b86:	04f71c63          	bne	a4,a5,80002bde <usertrap+0x92>
    if(p->killed)
    80002b8a:	551c                	lw	a5,40(a0)
    80002b8c:	e3b9                	bnez	a5,80002bd2 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b8e:	7cb8                	ld	a4,120(s1)
    80002b90:	6f1c                	ld	a5,24(a4)
    80002b92:	0791                	addi	a5,a5,4
    80002b94:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b96:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b9a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b9e:	10079073          	csrw	sstatus,a5
    syscall();
    80002ba2:	00000097          	auipc	ra,0x0
    80002ba6:	2b6080e7          	jalr	694(ra) # 80002e58 <syscall>
  if(p->killed)
    80002baa:	549c                	lw	a5,40(s1)
    80002bac:	ebc1                	bnez	a5,80002c3c <usertrap+0xf0>
  usertrapret();
    80002bae:	00000097          	auipc	ra,0x0
    80002bb2:	e0a080e7          	jalr	-502(ra) # 800029b8 <usertrapret>
}
    80002bb6:	60e2                	ld	ra,24(sp)
    80002bb8:	6442                	ld	s0,16(sp)
    80002bba:	64a2                	ld	s1,8(sp)
    80002bbc:	6902                	ld	s2,0(sp)
    80002bbe:	6105                	addi	sp,sp,32
    80002bc0:	8082                	ret
    panic("usertrap: not from user mode");
    80002bc2:	00005517          	auipc	a0,0x5
    80002bc6:	76e50513          	addi	a0,a0,1902 # 80008330 <states.1758+0x58>
    80002bca:	ffffe097          	auipc	ra,0xffffe
    80002bce:	974080e7          	jalr	-1676(ra) # 8000053e <panic>
      exit(-1);
    80002bd2:	557d                	li	a0,-1
    80002bd4:	00000097          	auipc	ra,0x0
    80002bd8:	8ec080e7          	jalr	-1812(ra) # 800024c0 <exit>
    80002bdc:	bf4d                	j	80002b8e <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002bde:	00000097          	auipc	ra,0x0
    80002be2:	ecc080e7          	jalr	-308(ra) # 80002aaa <devintr>
    80002be6:	892a                	mv	s2,a0
    80002be8:	c501                	beqz	a0,80002bf0 <usertrap+0xa4>
  if(p->killed)
    80002bea:	549c                	lw	a5,40(s1)
    80002bec:	c3a1                	beqz	a5,80002c2c <usertrap+0xe0>
    80002bee:	a815                	j	80002c22 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bf0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bf4:	5890                	lw	a2,48(s1)
    80002bf6:	00005517          	auipc	a0,0x5
    80002bfa:	75a50513          	addi	a0,a0,1882 # 80008350 <states.1758+0x78>
    80002bfe:	ffffe097          	auipc	ra,0xffffe
    80002c02:	98a080e7          	jalr	-1654(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c06:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c0a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c0e:	00005517          	auipc	a0,0x5
    80002c12:	77250513          	addi	a0,a0,1906 # 80008380 <states.1758+0xa8>
    80002c16:	ffffe097          	auipc	ra,0xffffe
    80002c1a:	972080e7          	jalr	-1678(ra) # 80000588 <printf>
    p->killed = 1;
    80002c1e:	4785                	li	a5,1
    80002c20:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002c22:	557d                	li	a0,-1
    80002c24:	00000097          	auipc	ra,0x0
    80002c28:	89c080e7          	jalr	-1892(ra) # 800024c0 <exit>
  if(which_dev == 2)
    80002c2c:	4789                	li	a5,2
    80002c2e:	f8f910e3          	bne	s2,a5,80002bae <usertrap+0x62>
    yield();
    80002c32:	fffff097          	auipc	ra,0xfffff
    80002c36:	5bc080e7          	jalr	1468(ra) # 800021ee <yield>
    80002c3a:	bf95                	j	80002bae <usertrap+0x62>
  int which_dev = 0;
    80002c3c:	4901                	li	s2,0
    80002c3e:	b7d5                	j	80002c22 <usertrap+0xd6>

0000000080002c40 <kerneltrap>:
{
    80002c40:	7179                	addi	sp,sp,-48
    80002c42:	f406                	sd	ra,40(sp)
    80002c44:	f022                	sd	s0,32(sp)
    80002c46:	ec26                	sd	s1,24(sp)
    80002c48:	e84a                	sd	s2,16(sp)
    80002c4a:	e44e                	sd	s3,8(sp)
    80002c4c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c4e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c52:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c56:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c5a:	1004f793          	andi	a5,s1,256
    80002c5e:	c78d                	beqz	a5,80002c88 <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c60:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c64:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c66:	eb8d                	bnez	a5,80002c98 <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    80002c68:	00000097          	auipc	ra,0x0
    80002c6c:	e42080e7          	jalr	-446(ra) # 80002aaa <devintr>
    80002c70:	cd05                	beqz	a0,80002ca8 <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c72:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c76:	10049073          	csrw	sstatus,s1
}
    80002c7a:	70a2                	ld	ra,40(sp)
    80002c7c:	7402                	ld	s0,32(sp)
    80002c7e:	64e2                	ld	s1,24(sp)
    80002c80:	6942                	ld	s2,16(sp)
    80002c82:	69a2                	ld	s3,8(sp)
    80002c84:	6145                	addi	sp,sp,48
    80002c86:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c88:	00005517          	auipc	a0,0x5
    80002c8c:	71850513          	addi	a0,a0,1816 # 800083a0 <states.1758+0xc8>
    80002c90:	ffffe097          	auipc	ra,0xffffe
    80002c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002c98:	00005517          	auipc	a0,0x5
    80002c9c:	73050513          	addi	a0,a0,1840 # 800083c8 <states.1758+0xf0>
    80002ca0:	ffffe097          	auipc	ra,0xffffe
    80002ca4:	89e080e7          	jalr	-1890(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002ca8:	85ce                	mv	a1,s3
    80002caa:	00005517          	auipc	a0,0x5
    80002cae:	73e50513          	addi	a0,a0,1854 # 800083e8 <states.1758+0x110>
    80002cb2:	ffffe097          	auipc	ra,0xffffe
    80002cb6:	8d6080e7          	jalr	-1834(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cba:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cbe:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cc2:	00005517          	auipc	a0,0x5
    80002cc6:	73650513          	addi	a0,a0,1846 # 800083f8 <states.1758+0x120>
    80002cca:	ffffe097          	auipc	ra,0xffffe
    80002cce:	8be080e7          	jalr	-1858(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002cd2:	00005517          	auipc	a0,0x5
    80002cd6:	73e50513          	addi	a0,a0,1854 # 80008410 <states.1758+0x138>
    80002cda:	ffffe097          	auipc	ra,0xffffe
    80002cde:	864080e7          	jalr	-1948(ra) # 8000053e <panic>

0000000080002ce2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ce2:	1101                	addi	sp,sp,-32
    80002ce4:	ec06                	sd	ra,24(sp)
    80002ce6:	e822                	sd	s0,16(sp)
    80002ce8:	e426                	sd	s1,8(sp)
    80002cea:	1000                	addi	s0,sp,32
    80002cec:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cee:	fffff097          	auipc	ra,0xfffff
    80002cf2:	cc2080e7          	jalr	-830(ra) # 800019b0 <myproc>
  switch (n) {
    80002cf6:	4795                	li	a5,5
    80002cf8:	0497e163          	bltu	a5,s1,80002d3a <argraw+0x58>
    80002cfc:	048a                	slli	s1,s1,0x2
    80002cfe:	00006717          	auipc	a4,0x6
    80002d02:	82270713          	addi	a4,a4,-2014 # 80008520 <states.1758+0x248>
    80002d06:	94ba                	add	s1,s1,a4
    80002d08:	409c                	lw	a5,0(s1)
    80002d0a:	97ba                	add	a5,a5,a4
    80002d0c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d0e:	7d3c                	ld	a5,120(a0)
    80002d10:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d12:	60e2                	ld	ra,24(sp)
    80002d14:	6442                	ld	s0,16(sp)
    80002d16:	64a2                	ld	s1,8(sp)
    80002d18:	6105                	addi	sp,sp,32
    80002d1a:	8082                	ret
    return p->trapframe->a1;
    80002d1c:	7d3c                	ld	a5,120(a0)
    80002d1e:	7fa8                	ld	a0,120(a5)
    80002d20:	bfcd                	j	80002d12 <argraw+0x30>
    return p->trapframe->a2;
    80002d22:	7d3c                	ld	a5,120(a0)
    80002d24:	63c8                	ld	a0,128(a5)
    80002d26:	b7f5                	j	80002d12 <argraw+0x30>
    return p->trapframe->a3;
    80002d28:	7d3c                	ld	a5,120(a0)
    80002d2a:	67c8                	ld	a0,136(a5)
    80002d2c:	b7dd                	j	80002d12 <argraw+0x30>
    return p->trapframe->a4;
    80002d2e:	7d3c                	ld	a5,120(a0)
    80002d30:	6bc8                	ld	a0,144(a5)
    80002d32:	b7c5                	j	80002d12 <argraw+0x30>
    return p->trapframe->a5;
    80002d34:	7d3c                	ld	a5,120(a0)
    80002d36:	6fc8                	ld	a0,152(a5)
    80002d38:	bfe9                	j	80002d12 <argraw+0x30>
  panic("argraw");
    80002d3a:	00005517          	auipc	a0,0x5
    80002d3e:	6e650513          	addi	a0,a0,1766 # 80008420 <states.1758+0x148>
    80002d42:	ffffd097          	auipc	ra,0xffffd
    80002d46:	7fc080e7          	jalr	2044(ra) # 8000053e <panic>

0000000080002d4a <fetchaddr>:
{
    80002d4a:	1101                	addi	sp,sp,-32
    80002d4c:	ec06                	sd	ra,24(sp)
    80002d4e:	e822                	sd	s0,16(sp)
    80002d50:	e426                	sd	s1,8(sp)
    80002d52:	e04a                	sd	s2,0(sp)
    80002d54:	1000                	addi	s0,sp,32
    80002d56:	84aa                	mv	s1,a0
    80002d58:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	c56080e7          	jalr	-938(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d62:	753c                	ld	a5,104(a0)
    80002d64:	02f4f863          	bgeu	s1,a5,80002d94 <fetchaddr+0x4a>
    80002d68:	00848713          	addi	a4,s1,8
    80002d6c:	02e7e663          	bltu	a5,a4,80002d98 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d70:	46a1                	li	a3,8
    80002d72:	8626                	mv	a2,s1
    80002d74:	85ca                	mv	a1,s2
    80002d76:	7928                	ld	a0,112(a0)
    80002d78:	fffff097          	auipc	ra,0xfffff
    80002d7c:	986080e7          	jalr	-1658(ra) # 800016fe <copyin>
    80002d80:	00a03533          	snez	a0,a0
    80002d84:	40a00533          	neg	a0,a0
}
    80002d88:	60e2                	ld	ra,24(sp)
    80002d8a:	6442                	ld	s0,16(sp)
    80002d8c:	64a2                	ld	s1,8(sp)
    80002d8e:	6902                	ld	s2,0(sp)
    80002d90:	6105                	addi	sp,sp,32
    80002d92:	8082                	ret
    return -1;
    80002d94:	557d                	li	a0,-1
    80002d96:	bfcd                	j	80002d88 <fetchaddr+0x3e>
    80002d98:	557d                	li	a0,-1
    80002d9a:	b7fd                	j	80002d88 <fetchaddr+0x3e>

0000000080002d9c <fetchstr>:
{
    80002d9c:	7179                	addi	sp,sp,-48
    80002d9e:	f406                	sd	ra,40(sp)
    80002da0:	f022                	sd	s0,32(sp)
    80002da2:	ec26                	sd	s1,24(sp)
    80002da4:	e84a                	sd	s2,16(sp)
    80002da6:	e44e                	sd	s3,8(sp)
    80002da8:	1800                	addi	s0,sp,48
    80002daa:	892a                	mv	s2,a0
    80002dac:	84ae                	mv	s1,a1
    80002dae:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002db0:	fffff097          	auipc	ra,0xfffff
    80002db4:	c00080e7          	jalr	-1024(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002db8:	86ce                	mv	a3,s3
    80002dba:	864a                	mv	a2,s2
    80002dbc:	85a6                	mv	a1,s1
    80002dbe:	7928                	ld	a0,112(a0)
    80002dc0:	fffff097          	auipc	ra,0xfffff
    80002dc4:	9ca080e7          	jalr	-1590(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002dc8:	00054763          	bltz	a0,80002dd6 <fetchstr+0x3a>
  return strlen(buf);
    80002dcc:	8526                	mv	a0,s1
    80002dce:	ffffe097          	auipc	ra,0xffffe
    80002dd2:	096080e7          	jalr	150(ra) # 80000e64 <strlen>
}
    80002dd6:	70a2                	ld	ra,40(sp)
    80002dd8:	7402                	ld	s0,32(sp)
    80002dda:	64e2                	ld	s1,24(sp)
    80002ddc:	6942                	ld	s2,16(sp)
    80002dde:	69a2                	ld	s3,8(sp)
    80002de0:	6145                	addi	sp,sp,48
    80002de2:	8082                	ret

0000000080002de4 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002de4:	1101                	addi	sp,sp,-32
    80002de6:	ec06                	sd	ra,24(sp)
    80002de8:	e822                	sd	s0,16(sp)
    80002dea:	e426                	sd	s1,8(sp)
    80002dec:	1000                	addi	s0,sp,32
    80002dee:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002df0:	00000097          	auipc	ra,0x0
    80002df4:	ef2080e7          	jalr	-270(ra) # 80002ce2 <argraw>
    80002df8:	c088                	sw	a0,0(s1)
  return 0;
}
    80002dfa:	4501                	li	a0,0
    80002dfc:	60e2                	ld	ra,24(sp)
    80002dfe:	6442                	ld	s0,16(sp)
    80002e00:	64a2                	ld	s1,8(sp)
    80002e02:	6105                	addi	sp,sp,32
    80002e04:	8082                	ret

0000000080002e06 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e06:	1101                	addi	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	e426                	sd	s1,8(sp)
    80002e0e:	1000                	addi	s0,sp,32
    80002e10:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e12:	00000097          	auipc	ra,0x0
    80002e16:	ed0080e7          	jalr	-304(ra) # 80002ce2 <argraw>
    80002e1a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e1c:	4501                	li	a0,0
    80002e1e:	60e2                	ld	ra,24(sp)
    80002e20:	6442                	ld	s0,16(sp)
    80002e22:	64a2                	ld	s1,8(sp)
    80002e24:	6105                	addi	sp,sp,32
    80002e26:	8082                	ret

0000000080002e28 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e28:	1101                	addi	sp,sp,-32
    80002e2a:	ec06                	sd	ra,24(sp)
    80002e2c:	e822                	sd	s0,16(sp)
    80002e2e:	e426                	sd	s1,8(sp)
    80002e30:	e04a                	sd	s2,0(sp)
    80002e32:	1000                	addi	s0,sp,32
    80002e34:	84ae                	mv	s1,a1
    80002e36:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e38:	00000097          	auipc	ra,0x0
    80002e3c:	eaa080e7          	jalr	-342(ra) # 80002ce2 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e40:	864a                	mv	a2,s2
    80002e42:	85a6                	mv	a1,s1
    80002e44:	00000097          	auipc	ra,0x0
    80002e48:	f58080e7          	jalr	-168(ra) # 80002d9c <fetchstr>
}
    80002e4c:	60e2                	ld	ra,24(sp)
    80002e4e:	6442                	ld	s0,16(sp)
    80002e50:	64a2                	ld	s1,8(sp)
    80002e52:	6902                	ld	s2,0(sp)
    80002e54:	6105                	addi	sp,sp,32
    80002e56:	8082                	ret

0000000080002e58 <syscall>:
};
static char *syscall_name[]={"","fork","exit","wait","pipe","read","kill","exec","fstat","chdir","dup","getpid","sbrk","sleep","uptime","open","write","mknod","unlink","link","mkdir","close","trace"};
static int syscall_arg[]={0,0,1,1,1,3,1,2,2,1,1,0,1,1,0,2,3,3,1,2,1,1,1};
void
syscall(void)
{
    80002e58:	7139                	addi	sp,sp,-64
    80002e5a:	fc06                	sd	ra,56(sp)
    80002e5c:	f822                	sd	s0,48(sp)
    80002e5e:	f426                	sd	s1,40(sp)
    80002e60:	f04a                	sd	s2,32(sp)
    80002e62:	ec4e                	sd	s3,24(sp)
    80002e64:	e852                	sd	s4,16(sp)
    80002e66:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002e68:	fffff097          	auipc	ra,0xfffff
    80002e6c:	b48080e7          	jalr	-1208(ra) # 800019b0 <myproc>
    80002e70:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e72:	07853983          	ld	s3,120(a0)
    80002e76:	0a89b783          	ld	a5,168(s3)
    80002e7a:	0007891b          	sext.w	s2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e7e:	37fd                	addiw	a5,a5,-1
    80002e80:	475d                	li	a4,23
    80002e82:	08f76c63          	bltu	a4,a5,80002f1a <syscall+0xc2>
    80002e86:	00391713          	slli	a4,s2,0x3
    80002e8a:	00005797          	auipc	a5,0x5
    80002e8e:	6ae78793          	addi	a5,a5,1710 # 80008538 <syscalls>
    80002e92:	97ba                	add	a5,a5,a4
    80002e94:	639c                	ld	a5,0(a5)
    80002e96:	c3d1                	beqz	a5,80002f1a <syscall+0xc2>
    p->trapframe->a0 = syscalls[num]();
    80002e98:	9782                	jalr	a5
    80002e9a:	06a9b823          	sd	a0,112(s3)
    //strace
    int arg = 0;
    80002e9e:	fc042623          	sw	zero,-52(s0)
    int x = 0;
    //printf("[%d%d]",p->trace_mask,num);
    if (p->trace_mask >> num)
    80002ea2:	58dc                	lw	a5,52(s1)
    80002ea4:	4127d7bb          	sraw	a5,a5,s2
    80002ea8:	cbc1                	beqz	a5,80002f38 <syscall+0xe0>
    {
      printf("%d: syscall %s (", p->pid, syscall_name[num]);
    80002eaa:	00005997          	auipc	s3,0x5
    80002eae:	68e98993          	addi	s3,s3,1678 # 80008538 <syscalls>
    80002eb2:	00391793          	slli	a5,s2,0x3
    80002eb6:	97ce                	add	a5,a5,s3
    80002eb8:	67f0                	ld	a2,200(a5)
    80002eba:	588c                	lw	a1,48(s1)
    80002ebc:	00005517          	auipc	a0,0x5
    80002ec0:	56c50513          	addi	a0,a0,1388 # 80008428 <states.1758+0x150>
    80002ec4:	ffffd097          	auipc	ra,0xffffd
    80002ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
      x= 0;
      while(x < syscall_arg[num]){
    80002ecc:	090a                	slli	s2,s2,0x2
    80002ece:	99ca                	add	s3,s3,s2
    80002ed0:	1809a983          	lw	s3,384(s3)
    80002ed4:	03305863          	blez	s3,80002f04 <syscall+0xac>
      x= 0;
    80002ed8:	4901                	li	s2,0
        argint(x, &arg);
        printf("%d ",arg);
    80002eda:	00005a17          	auipc	s4,0x5
    80002ede:	566a0a13          	addi	s4,s4,1382 # 80008440 <states.1758+0x168>
        argint(x, &arg);
    80002ee2:	fcc40593          	addi	a1,s0,-52
    80002ee6:	854a                	mv	a0,s2
    80002ee8:	00000097          	auipc	ra,0x0
    80002eec:	efc080e7          	jalr	-260(ra) # 80002de4 <argint>
        printf("%d ",arg);
    80002ef0:	fcc42583          	lw	a1,-52(s0)
    80002ef4:	8552                	mv	a0,s4
    80002ef6:	ffffd097          	auipc	ra,0xffffd
    80002efa:	692080e7          	jalr	1682(ra) # 80000588 <printf>
        x++;
    80002efe:	2905                	addiw	s2,s2,1
      while(x < syscall_arg[num]){
    80002f00:	ff3911e3          	bne	s2,s3,80002ee2 <syscall+0x8a>
      } 
  
      printf(") -> %d\n", p->trapframe->a0);
    80002f04:	7cbc                	ld	a5,120(s1)
    80002f06:	7bac                	ld	a1,112(a5)
    80002f08:	00005517          	auipc	a0,0x5
    80002f0c:	54050513          	addi	a0,a0,1344 # 80008448 <states.1758+0x170>
    80002f10:	ffffd097          	auipc	ra,0xffffd
    80002f14:	678080e7          	jalr	1656(ra) # 80000588 <printf>
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f18:	a005                	j	80002f38 <syscall+0xe0>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f1a:	86ca                	mv	a3,s2
    80002f1c:	17848613          	addi	a2,s1,376
    80002f20:	588c                	lw	a1,48(s1)
    80002f22:	00005517          	auipc	a0,0x5
    80002f26:	53650513          	addi	a0,a0,1334 # 80008458 <states.1758+0x180>
    80002f2a:	ffffd097          	auipc	ra,0xffffd
    80002f2e:	65e080e7          	jalr	1630(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f32:	7cbc                	ld	a5,120(s1)
    80002f34:	577d                	li	a4,-1
    80002f36:	fbb8                	sd	a4,112(a5)
  }
}
    80002f38:	70e2                	ld	ra,56(sp)
    80002f3a:	7442                	ld	s0,48(sp)
    80002f3c:	74a2                	ld	s1,40(sp)
    80002f3e:	7902                	ld	s2,32(sp)
    80002f40:	69e2                	ld	s3,24(sp)
    80002f42:	6a42                	ld	s4,16(sp)
    80002f44:	6121                	addi	sp,sp,64
    80002f46:	8082                	ret

0000000080002f48 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f48:	1101                	addi	sp,sp,-32
    80002f4a:	ec06                	sd	ra,24(sp)
    80002f4c:	e822                	sd	s0,16(sp)
    80002f4e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f50:	fec40593          	addi	a1,s0,-20
    80002f54:	4501                	li	a0,0
    80002f56:	00000097          	auipc	ra,0x0
    80002f5a:	e8e080e7          	jalr	-370(ra) # 80002de4 <argint>
    return -1;
    80002f5e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f60:	00054963          	bltz	a0,80002f72 <sys_exit+0x2a>
  exit(n);
    80002f64:	fec42503          	lw	a0,-20(s0)
    80002f68:	fffff097          	auipc	ra,0xfffff
    80002f6c:	558080e7          	jalr	1368(ra) # 800024c0 <exit>
  return 0;  // not reached
    80002f70:	4781                	li	a5,0
}
    80002f72:	853e                	mv	a0,a5
    80002f74:	60e2                	ld	ra,24(sp)
    80002f76:	6442                	ld	s0,16(sp)
    80002f78:	6105                	addi	sp,sp,32
    80002f7a:	8082                	ret

0000000080002f7c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f7c:	1141                	addi	sp,sp,-16
    80002f7e:	e406                	sd	ra,8(sp)
    80002f80:	e022                	sd	s0,0(sp)
    80002f82:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f84:	fffff097          	auipc	ra,0xfffff
    80002f88:	a2c080e7          	jalr	-1492(ra) # 800019b0 <myproc>
}
    80002f8c:	5908                	lw	a0,48(a0)
    80002f8e:	60a2                	ld	ra,8(sp)
    80002f90:	6402                	ld	s0,0(sp)
    80002f92:	0141                	addi	sp,sp,16
    80002f94:	8082                	ret

0000000080002f96 <sys_fork>:

uint64
sys_fork(void)
{
    80002f96:	1141                	addi	sp,sp,-16
    80002f98:	e406                	sd	ra,8(sp)
    80002f9a:	e022                	sd	s0,0(sp)
    80002f9c:	0800                	addi	s0,sp,16
  return fork();
    80002f9e:	fffff097          	auipc	ra,0xfffff
    80002fa2:	e04080e7          	jalr	-508(ra) # 80001da2 <fork>
}
    80002fa6:	60a2                	ld	ra,8(sp)
    80002fa8:	6402                	ld	s0,0(sp)
    80002faa:	0141                	addi	sp,sp,16
    80002fac:	8082                	ret

0000000080002fae <sys_wait>:

uint64
sys_wait(void)
{
    80002fae:	1101                	addi	sp,sp,-32
    80002fb0:	ec06                	sd	ra,24(sp)
    80002fb2:	e822                	sd	s0,16(sp)
    80002fb4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002fb6:	fe840593          	addi	a1,s0,-24
    80002fba:	4501                	li	a0,0
    80002fbc:	00000097          	auipc	ra,0x0
    80002fc0:	e4a080e7          	jalr	-438(ra) # 80002e06 <argaddr>
    80002fc4:	87aa                	mv	a5,a0
    return -1;
    80002fc6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002fc8:	0007c863          	bltz	a5,80002fd8 <sys_wait+0x2a>
  return wait(p);
    80002fcc:	fe843503          	ld	a0,-24(s0)
    80002fd0:	fffff097          	auipc	ra,0xfffff
    80002fd4:	2ce080e7          	jalr	718(ra) # 8000229e <wait>
}
    80002fd8:	60e2                	ld	ra,24(sp)
    80002fda:	6442                	ld	s0,16(sp)
    80002fdc:	6105                	addi	sp,sp,32
    80002fde:	8082                	ret

0000000080002fe0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002fe0:	7179                	addi	sp,sp,-48
    80002fe2:	f406                	sd	ra,40(sp)
    80002fe4:	f022                	sd	s0,32(sp)
    80002fe6:	ec26                	sd	s1,24(sp)
    80002fe8:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002fea:	fdc40593          	addi	a1,s0,-36
    80002fee:	4501                	li	a0,0
    80002ff0:	00000097          	auipc	ra,0x0
    80002ff4:	df4080e7          	jalr	-524(ra) # 80002de4 <argint>
    80002ff8:	87aa                	mv	a5,a0
    return -1;
    80002ffa:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002ffc:	0207c063          	bltz	a5,8000301c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003000:	fffff097          	auipc	ra,0xfffff
    80003004:	9b0080e7          	jalr	-1616(ra) # 800019b0 <myproc>
    80003008:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    8000300a:	fdc42503          	lw	a0,-36(s0)
    8000300e:	fffff097          	auipc	ra,0xfffff
    80003012:	d20080e7          	jalr	-736(ra) # 80001d2e <growproc>
    80003016:	00054863          	bltz	a0,80003026 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000301a:	8526                	mv	a0,s1
}
    8000301c:	70a2                	ld	ra,40(sp)
    8000301e:	7402                	ld	s0,32(sp)
    80003020:	64e2                	ld	s1,24(sp)
    80003022:	6145                	addi	sp,sp,48
    80003024:	8082                	ret
    return -1;
    80003026:	557d                	li	a0,-1
    80003028:	bfd5                	j	8000301c <sys_sbrk+0x3c>

000000008000302a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000302a:	7139                	addi	sp,sp,-64
    8000302c:	fc06                	sd	ra,56(sp)
    8000302e:	f822                	sd	s0,48(sp)
    80003030:	f426                	sd	s1,40(sp)
    80003032:	f04a                	sd	s2,32(sp)
    80003034:	ec4e                	sd	s3,24(sp)
    80003036:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003038:	fcc40593          	addi	a1,s0,-52
    8000303c:	4501                	li	a0,0
    8000303e:	00000097          	auipc	ra,0x0
    80003042:	da6080e7          	jalr	-602(ra) # 80002de4 <argint>
    return -1;
    80003046:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003048:	06054563          	bltz	a0,800030b2 <sys_sleep+0x88>
  acquire(&tickslock);
    8000304c:	00015517          	auipc	a0,0x15
    80003050:	88450513          	addi	a0,a0,-1916 # 800178d0 <tickslock>
    80003054:	ffffe097          	auipc	ra,0xffffe
    80003058:	b90080e7          	jalr	-1136(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000305c:	00006917          	auipc	s2,0x6
    80003060:	fd492903          	lw	s2,-44(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003064:	fcc42783          	lw	a5,-52(s0)
    80003068:	cf85                	beqz	a5,800030a0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000306a:	00015997          	auipc	s3,0x15
    8000306e:	86698993          	addi	s3,s3,-1946 # 800178d0 <tickslock>
    80003072:	00006497          	auipc	s1,0x6
    80003076:	fbe48493          	addi	s1,s1,-66 # 80009030 <ticks>
    if(myproc()->killed){
    8000307a:	fffff097          	auipc	ra,0xfffff
    8000307e:	936080e7          	jalr	-1738(ra) # 800019b0 <myproc>
    80003082:	551c                	lw	a5,40(a0)
    80003084:	ef9d                	bnez	a5,800030c2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003086:	85ce                	mv	a1,s3
    80003088:	8526                	mv	a0,s1
    8000308a:	fffff097          	auipc	ra,0xfffff
    8000308e:	1a0080e7          	jalr	416(ra) # 8000222a <sleep>
  while(ticks - ticks0 < n){
    80003092:	409c                	lw	a5,0(s1)
    80003094:	412787bb          	subw	a5,a5,s2
    80003098:	fcc42703          	lw	a4,-52(s0)
    8000309c:	fce7efe3          	bltu	a5,a4,8000307a <sys_sleep+0x50>
  }
  release(&tickslock);
    800030a0:	00015517          	auipc	a0,0x15
    800030a4:	83050513          	addi	a0,a0,-2000 # 800178d0 <tickslock>
    800030a8:	ffffe097          	auipc	ra,0xffffe
    800030ac:	bf0080e7          	jalr	-1040(ra) # 80000c98 <release>
  return 0;
    800030b0:	4781                	li	a5,0
}
    800030b2:	853e                	mv	a0,a5
    800030b4:	70e2                	ld	ra,56(sp)
    800030b6:	7442                	ld	s0,48(sp)
    800030b8:	74a2                	ld	s1,40(sp)
    800030ba:	7902                	ld	s2,32(sp)
    800030bc:	69e2                	ld	s3,24(sp)
    800030be:	6121                	addi	sp,sp,64
    800030c0:	8082                	ret
      release(&tickslock);
    800030c2:	00015517          	auipc	a0,0x15
    800030c6:	80e50513          	addi	a0,a0,-2034 # 800178d0 <tickslock>
    800030ca:	ffffe097          	auipc	ra,0xffffe
    800030ce:	bce080e7          	jalr	-1074(ra) # 80000c98 <release>
      return -1;
    800030d2:	57fd                	li	a5,-1
    800030d4:	bff9                	j	800030b2 <sys_sleep+0x88>

00000000800030d6 <sys_kill>:

uint64
sys_kill(void)
{
    800030d6:	1101                	addi	sp,sp,-32
    800030d8:	ec06                	sd	ra,24(sp)
    800030da:	e822                	sd	s0,16(sp)
    800030dc:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800030de:	fec40593          	addi	a1,s0,-20
    800030e2:	4501                	li	a0,0
    800030e4:	00000097          	auipc	ra,0x0
    800030e8:	d00080e7          	jalr	-768(ra) # 80002de4 <argint>
    800030ec:	87aa                	mv	a5,a0
    return -1;
    800030ee:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800030f0:	0007c863          	bltz	a5,80003100 <sys_kill+0x2a>
  return kill(pid);
    800030f4:	fec42503          	lw	a0,-20(s0)
    800030f8:	fffff097          	auipc	ra,0xfffff
    800030fc:	4aa080e7          	jalr	1194(ra) # 800025a2 <kill>
}
    80003100:	60e2                	ld	ra,24(sp)
    80003102:	6442                	ld	s0,16(sp)
    80003104:	6105                	addi	sp,sp,32
    80003106:	8082                	ret

0000000080003108 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003108:	1101                	addi	sp,sp,-32
    8000310a:	ec06                	sd	ra,24(sp)
    8000310c:	e822                	sd	s0,16(sp)
    8000310e:	e426                	sd	s1,8(sp)
    80003110:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003112:	00014517          	auipc	a0,0x14
    80003116:	7be50513          	addi	a0,a0,1982 # 800178d0 <tickslock>
    8000311a:	ffffe097          	auipc	ra,0xffffe
    8000311e:	aca080e7          	jalr	-1334(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003122:	00006497          	auipc	s1,0x6
    80003126:	f0e4a483          	lw	s1,-242(s1) # 80009030 <ticks>
  release(&tickslock);
    8000312a:	00014517          	auipc	a0,0x14
    8000312e:	7a650513          	addi	a0,a0,1958 # 800178d0 <tickslock>
    80003132:	ffffe097          	auipc	ra,0xffffe
    80003136:	b66080e7          	jalr	-1178(ra) # 80000c98 <release>
  return xticks;
}
    8000313a:	02049513          	slli	a0,s1,0x20
    8000313e:	9101                	srli	a0,a0,0x20
    80003140:	60e2                	ld	ra,24(sp)
    80003142:	6442                	ld	s0,16(sp)
    80003144:	64a2                	ld	s1,8(sp)
    80003146:	6105                	addi	sp,sp,32
    80003148:	8082                	ret

000000008000314a <sys_trace>:
uint64
sys_trace()
{
    8000314a:	1101                	addi	sp,sp,-32
    8000314c:	ec06                	sd	ra,24(sp)
    8000314e:	e822                	sd	s0,16(sp)
    80003150:	1000                	addi	s0,sp,32
  int mask;
    if (argint(0, &mask) < 0)
    80003152:	fec40593          	addi	a1,s0,-20
    80003156:	4501                	li	a0,0
    80003158:	00000097          	auipc	ra,0x0
    8000315c:	c8c080e7          	jalr	-884(ra) # 80002de4 <argint>
      return -1;
    80003160:	57fd                	li	a5,-1
    if (argint(0, &mask) < 0)
    80003162:	00054a63          	bltz	a0,80003176 <sys_trace+0x2c>
    myproc()->trace_mask = mask;
    80003166:	fffff097          	auipc	ra,0xfffff
    8000316a:	84a080e7          	jalr	-1974(ra) # 800019b0 <myproc>
    8000316e:	fec42783          	lw	a5,-20(s0)
    80003172:	d95c                	sw	a5,52(a0)
    return 0;
    80003174:	4781                	li	a5,0
}
    80003176:	853e                	mv	a0,a5
    80003178:	60e2                	ld	ra,24(sp)
    8000317a:	6442                	ld	s0,16(sp)
    8000317c:	6105                	addi	sp,sp,32
    8000317e:	8082                	ret

0000000080003180 <sys_set_priority>:
uint64
sys_set_priority()
{
    80003180:	1101                	addi	sp,sp,-32
    80003182:	ec06                	sd	ra,24(sp)
    80003184:	e822                	sd	s0,16(sp)
    80003186:	1000                	addi	s0,sp,32
  int pid;
  int sp;  //static priority
    if (argint(0, &sp) < 0 || argint(1, &pid) <0 )
    80003188:	fe840593          	addi	a1,s0,-24
    8000318c:	4501                	li	a0,0
    8000318e:	00000097          	auipc	ra,0x0
    80003192:	c56080e7          	jalr	-938(ra) # 80002de4 <argint>
      return -1;
    80003196:	57fd                	li	a5,-1
    if (argint(0, &sp) < 0 || argint(1, &pid) <0 )
    80003198:	02054563          	bltz	a0,800031c2 <sys_set_priority+0x42>
    8000319c:	fec40593          	addi	a1,s0,-20
    800031a0:	4505                	li	a0,1
    800031a2:	00000097          	auipc	ra,0x0
    800031a6:	c42080e7          	jalr	-958(ra) # 80002de4 <argint>
      return -1;
    800031aa:	57fd                	li	a5,-1
    if (argint(0, &sp) < 0 || argint(1, &pid) <0 )
    800031ac:	00054b63          	bltz	a0,800031c2 <sys_set_priority+0x42>
    return set_priority(sp,pid);
    800031b0:	fec42583          	lw	a1,-20(s0)
    800031b4:	fe842503          	lw	a0,-24(s0)
    800031b8:	fffff097          	auipc	ra,0xfffff
    800031bc:	d2e080e7          	jalr	-722(ra) # 80001ee6 <set_priority>
    800031c0:	87aa                	mv	a5,a0
}
    800031c2:	853e                	mv	a0,a5
    800031c4:	60e2                	ld	ra,24(sp)
    800031c6:	6442                	ld	s0,16(sp)
    800031c8:	6105                	addi	sp,sp,32
    800031ca:	8082                	ret

00000000800031cc <sys_waitx>:

uint64
sys_waitx(void)
{
    800031cc:	7139                	addi	sp,sp,-64
    800031ce:	fc06                	sd	ra,56(sp)
    800031d0:	f822                	sd	s0,48(sp)
    800031d2:	f426                	sd	s1,40(sp)
    800031d4:	f04a                	sd	s2,32(sp)
    800031d6:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    800031d8:	fd840593          	addi	a1,s0,-40
    800031dc:	4501                	li	a0,0
    800031de:	00000097          	auipc	ra,0x0
    800031e2:	c28080e7          	jalr	-984(ra) # 80002e06 <argaddr>
    return -1;
    800031e6:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    800031e8:	08054063          	bltz	a0,80003268 <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    800031ec:	fd040593          	addi	a1,s0,-48
    800031f0:	4505                	li	a0,1
    800031f2:	00000097          	auipc	ra,0x0
    800031f6:	c14080e7          	jalr	-1004(ra) # 80002e06 <argaddr>
    return -1;
    800031fa:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    800031fc:	06054663          	bltz	a0,80003268 <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    80003200:	fc840593          	addi	a1,s0,-56
    80003204:	4509                	li	a0,2
    80003206:	00000097          	auipc	ra,0x0
    8000320a:	c00080e7          	jalr	-1024(ra) # 80002e06 <argaddr>
    return -1;
    8000320e:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    80003210:	04054c63          	bltz	a0,80003268 <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    80003214:	fc040613          	addi	a2,s0,-64
    80003218:	fc440593          	addi	a1,s0,-60
    8000321c:	fd843503          	ld	a0,-40(s0)
    80003220:	fffff097          	auipc	ra,0xfffff
    80003224:	5a8080e7          	jalr	1448(ra) # 800027c8 <waitx>
    80003228:	892a                	mv	s2,a0
  struct proc* p = myproc();
    8000322a:	ffffe097          	auipc	ra,0xffffe
    8000322e:	786080e7          	jalr	1926(ra) # 800019b0 <myproc>
    80003232:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003234:	4691                	li	a3,4
    80003236:	fc440613          	addi	a2,s0,-60
    8000323a:	fd043583          	ld	a1,-48(s0)
    8000323e:	7928                	ld	a0,112(a0)
    80003240:	ffffe097          	auipc	ra,0xffffe
    80003244:	432080e7          	jalr	1074(ra) # 80001672 <copyout>
    return -1;
    80003248:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    8000324a:	00054f63          	bltz	a0,80003268 <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    8000324e:	4691                	li	a3,4
    80003250:	fc040613          	addi	a2,s0,-64
    80003254:	fc843583          	ld	a1,-56(s0)
    80003258:	78a8                	ld	a0,112(s1)
    8000325a:	ffffe097          	auipc	ra,0xffffe
    8000325e:	418080e7          	jalr	1048(ra) # 80001672 <copyout>
    80003262:	00054a63          	bltz	a0,80003276 <sys_waitx+0xaa>
    return -1;
  return ret;
    80003266:	87ca                	mv	a5,s2
    80003268:	853e                	mv	a0,a5
    8000326a:	70e2                	ld	ra,56(sp)
    8000326c:	7442                	ld	s0,48(sp)
    8000326e:	74a2                	ld	s1,40(sp)
    80003270:	7902                	ld	s2,32(sp)
    80003272:	6121                	addi	sp,sp,64
    80003274:	8082                	ret
    return -1;
    80003276:	57fd                	li	a5,-1
    80003278:	bfc5                	j	80003268 <sys_waitx+0x9c>

000000008000327a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000327a:	7179                	addi	sp,sp,-48
    8000327c:	f406                	sd	ra,40(sp)
    8000327e:	f022                	sd	s0,32(sp)
    80003280:	ec26                	sd	s1,24(sp)
    80003282:	e84a                	sd	s2,16(sp)
    80003284:	e44e                	sd	s3,8(sp)
    80003286:	e052                	sd	s4,0(sp)
    80003288:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000328a:	00005597          	auipc	a1,0x5
    8000328e:	48e58593          	addi	a1,a1,1166 # 80008718 <syscall_arg+0x60>
    80003292:	00014517          	auipc	a0,0x14
    80003296:	65650513          	addi	a0,a0,1622 # 800178e8 <bcache>
    8000329a:	ffffe097          	auipc	ra,0xffffe
    8000329e:	8ba080e7          	jalr	-1862(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800032a2:	0001c797          	auipc	a5,0x1c
    800032a6:	64678793          	addi	a5,a5,1606 # 8001f8e8 <bcache+0x8000>
    800032aa:	0001d717          	auipc	a4,0x1d
    800032ae:	8a670713          	addi	a4,a4,-1882 # 8001fb50 <bcache+0x8268>
    800032b2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800032b6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032ba:	00014497          	auipc	s1,0x14
    800032be:	64648493          	addi	s1,s1,1606 # 80017900 <bcache+0x18>
    b->next = bcache.head.next;
    800032c2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800032c4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800032c6:	00005a17          	auipc	s4,0x5
    800032ca:	45aa0a13          	addi	s4,s4,1114 # 80008720 <syscall_arg+0x68>
    b->next = bcache.head.next;
    800032ce:	2b893783          	ld	a5,696(s2)
    800032d2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800032d4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800032d8:	85d2                	mv	a1,s4
    800032da:	01048513          	addi	a0,s1,16
    800032de:	00001097          	auipc	ra,0x1
    800032e2:	4bc080e7          	jalr	1212(ra) # 8000479a <initsleeplock>
    bcache.head.next->prev = b;
    800032e6:	2b893783          	ld	a5,696(s2)
    800032ea:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800032ec:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032f0:	45848493          	addi	s1,s1,1112
    800032f4:	fd349de3          	bne	s1,s3,800032ce <binit+0x54>
  }
}
    800032f8:	70a2                	ld	ra,40(sp)
    800032fa:	7402                	ld	s0,32(sp)
    800032fc:	64e2                	ld	s1,24(sp)
    800032fe:	6942                	ld	s2,16(sp)
    80003300:	69a2                	ld	s3,8(sp)
    80003302:	6a02                	ld	s4,0(sp)
    80003304:	6145                	addi	sp,sp,48
    80003306:	8082                	ret

0000000080003308 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003308:	7179                	addi	sp,sp,-48
    8000330a:	f406                	sd	ra,40(sp)
    8000330c:	f022                	sd	s0,32(sp)
    8000330e:	ec26                	sd	s1,24(sp)
    80003310:	e84a                	sd	s2,16(sp)
    80003312:	e44e                	sd	s3,8(sp)
    80003314:	1800                	addi	s0,sp,48
    80003316:	89aa                	mv	s3,a0
    80003318:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000331a:	00014517          	auipc	a0,0x14
    8000331e:	5ce50513          	addi	a0,a0,1486 # 800178e8 <bcache>
    80003322:	ffffe097          	auipc	ra,0xffffe
    80003326:	8c2080e7          	jalr	-1854(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000332a:	0001d497          	auipc	s1,0x1d
    8000332e:	8764b483          	ld	s1,-1930(s1) # 8001fba0 <bcache+0x82b8>
    80003332:	0001d797          	auipc	a5,0x1d
    80003336:	81e78793          	addi	a5,a5,-2018 # 8001fb50 <bcache+0x8268>
    8000333a:	02f48f63          	beq	s1,a5,80003378 <bread+0x70>
    8000333e:	873e                	mv	a4,a5
    80003340:	a021                	j	80003348 <bread+0x40>
    80003342:	68a4                	ld	s1,80(s1)
    80003344:	02e48a63          	beq	s1,a4,80003378 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003348:	449c                	lw	a5,8(s1)
    8000334a:	ff379ce3          	bne	a5,s3,80003342 <bread+0x3a>
    8000334e:	44dc                	lw	a5,12(s1)
    80003350:	ff2799e3          	bne	a5,s2,80003342 <bread+0x3a>
      b->refcnt++;
    80003354:	40bc                	lw	a5,64(s1)
    80003356:	2785                	addiw	a5,a5,1
    80003358:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000335a:	00014517          	auipc	a0,0x14
    8000335e:	58e50513          	addi	a0,a0,1422 # 800178e8 <bcache>
    80003362:	ffffe097          	auipc	ra,0xffffe
    80003366:	936080e7          	jalr	-1738(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000336a:	01048513          	addi	a0,s1,16
    8000336e:	00001097          	auipc	ra,0x1
    80003372:	466080e7          	jalr	1126(ra) # 800047d4 <acquiresleep>
      return b;
    80003376:	a8b9                	j	800033d4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003378:	0001d497          	auipc	s1,0x1d
    8000337c:	8204b483          	ld	s1,-2016(s1) # 8001fb98 <bcache+0x82b0>
    80003380:	0001c797          	auipc	a5,0x1c
    80003384:	7d078793          	addi	a5,a5,2000 # 8001fb50 <bcache+0x8268>
    80003388:	00f48863          	beq	s1,a5,80003398 <bread+0x90>
    8000338c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000338e:	40bc                	lw	a5,64(s1)
    80003390:	cf81                	beqz	a5,800033a8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003392:	64a4                	ld	s1,72(s1)
    80003394:	fee49de3          	bne	s1,a4,8000338e <bread+0x86>
  panic("bget: no buffers");
    80003398:	00005517          	auipc	a0,0x5
    8000339c:	39050513          	addi	a0,a0,912 # 80008728 <syscall_arg+0x70>
    800033a0:	ffffd097          	auipc	ra,0xffffd
    800033a4:	19e080e7          	jalr	414(ra) # 8000053e <panic>
      b->dev = dev;
    800033a8:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800033ac:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800033b0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800033b4:	4785                	li	a5,1
    800033b6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033b8:	00014517          	auipc	a0,0x14
    800033bc:	53050513          	addi	a0,a0,1328 # 800178e8 <bcache>
    800033c0:	ffffe097          	auipc	ra,0xffffe
    800033c4:	8d8080e7          	jalr	-1832(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800033c8:	01048513          	addi	a0,s1,16
    800033cc:	00001097          	auipc	ra,0x1
    800033d0:	408080e7          	jalr	1032(ra) # 800047d4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800033d4:	409c                	lw	a5,0(s1)
    800033d6:	cb89                	beqz	a5,800033e8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800033d8:	8526                	mv	a0,s1
    800033da:	70a2                	ld	ra,40(sp)
    800033dc:	7402                	ld	s0,32(sp)
    800033de:	64e2                	ld	s1,24(sp)
    800033e0:	6942                	ld	s2,16(sp)
    800033e2:	69a2                	ld	s3,8(sp)
    800033e4:	6145                	addi	sp,sp,48
    800033e6:	8082                	ret
    virtio_disk_rw(b, 0);
    800033e8:	4581                	li	a1,0
    800033ea:	8526                	mv	a0,s1
    800033ec:	00003097          	auipc	ra,0x3
    800033f0:	f0a080e7          	jalr	-246(ra) # 800062f6 <virtio_disk_rw>
    b->valid = 1;
    800033f4:	4785                	li	a5,1
    800033f6:	c09c                	sw	a5,0(s1)
  return b;
    800033f8:	b7c5                	j	800033d8 <bread+0xd0>

00000000800033fa <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800033fa:	1101                	addi	sp,sp,-32
    800033fc:	ec06                	sd	ra,24(sp)
    800033fe:	e822                	sd	s0,16(sp)
    80003400:	e426                	sd	s1,8(sp)
    80003402:	1000                	addi	s0,sp,32
    80003404:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003406:	0541                	addi	a0,a0,16
    80003408:	00001097          	auipc	ra,0x1
    8000340c:	466080e7          	jalr	1126(ra) # 8000486e <holdingsleep>
    80003410:	cd01                	beqz	a0,80003428 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003412:	4585                	li	a1,1
    80003414:	8526                	mv	a0,s1
    80003416:	00003097          	auipc	ra,0x3
    8000341a:	ee0080e7          	jalr	-288(ra) # 800062f6 <virtio_disk_rw>
}
    8000341e:	60e2                	ld	ra,24(sp)
    80003420:	6442                	ld	s0,16(sp)
    80003422:	64a2                	ld	s1,8(sp)
    80003424:	6105                	addi	sp,sp,32
    80003426:	8082                	ret
    panic("bwrite");
    80003428:	00005517          	auipc	a0,0x5
    8000342c:	31850513          	addi	a0,a0,792 # 80008740 <syscall_arg+0x88>
    80003430:	ffffd097          	auipc	ra,0xffffd
    80003434:	10e080e7          	jalr	270(ra) # 8000053e <panic>

0000000080003438 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003438:	1101                	addi	sp,sp,-32
    8000343a:	ec06                	sd	ra,24(sp)
    8000343c:	e822                	sd	s0,16(sp)
    8000343e:	e426                	sd	s1,8(sp)
    80003440:	e04a                	sd	s2,0(sp)
    80003442:	1000                	addi	s0,sp,32
    80003444:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003446:	01050913          	addi	s2,a0,16
    8000344a:	854a                	mv	a0,s2
    8000344c:	00001097          	auipc	ra,0x1
    80003450:	422080e7          	jalr	1058(ra) # 8000486e <holdingsleep>
    80003454:	c92d                	beqz	a0,800034c6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003456:	854a                	mv	a0,s2
    80003458:	00001097          	auipc	ra,0x1
    8000345c:	3d2080e7          	jalr	978(ra) # 8000482a <releasesleep>

  acquire(&bcache.lock);
    80003460:	00014517          	auipc	a0,0x14
    80003464:	48850513          	addi	a0,a0,1160 # 800178e8 <bcache>
    80003468:	ffffd097          	auipc	ra,0xffffd
    8000346c:	77c080e7          	jalr	1916(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003470:	40bc                	lw	a5,64(s1)
    80003472:	37fd                	addiw	a5,a5,-1
    80003474:	0007871b          	sext.w	a4,a5
    80003478:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000347a:	eb05                	bnez	a4,800034aa <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000347c:	68bc                	ld	a5,80(s1)
    8000347e:	64b8                	ld	a4,72(s1)
    80003480:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003482:	64bc                	ld	a5,72(s1)
    80003484:	68b8                	ld	a4,80(s1)
    80003486:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003488:	0001c797          	auipc	a5,0x1c
    8000348c:	46078793          	addi	a5,a5,1120 # 8001f8e8 <bcache+0x8000>
    80003490:	2b87b703          	ld	a4,696(a5)
    80003494:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003496:	0001c717          	auipc	a4,0x1c
    8000349a:	6ba70713          	addi	a4,a4,1722 # 8001fb50 <bcache+0x8268>
    8000349e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800034a0:	2b87b703          	ld	a4,696(a5)
    800034a4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800034a6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800034aa:	00014517          	auipc	a0,0x14
    800034ae:	43e50513          	addi	a0,a0,1086 # 800178e8 <bcache>
    800034b2:	ffffd097          	auipc	ra,0xffffd
    800034b6:	7e6080e7          	jalr	2022(ra) # 80000c98 <release>
}
    800034ba:	60e2                	ld	ra,24(sp)
    800034bc:	6442                	ld	s0,16(sp)
    800034be:	64a2                	ld	s1,8(sp)
    800034c0:	6902                	ld	s2,0(sp)
    800034c2:	6105                	addi	sp,sp,32
    800034c4:	8082                	ret
    panic("brelse");
    800034c6:	00005517          	auipc	a0,0x5
    800034ca:	28250513          	addi	a0,a0,642 # 80008748 <syscall_arg+0x90>
    800034ce:	ffffd097          	auipc	ra,0xffffd
    800034d2:	070080e7          	jalr	112(ra) # 8000053e <panic>

00000000800034d6 <bpin>:

void
bpin(struct buf *b) {
    800034d6:	1101                	addi	sp,sp,-32
    800034d8:	ec06                	sd	ra,24(sp)
    800034da:	e822                	sd	s0,16(sp)
    800034dc:	e426                	sd	s1,8(sp)
    800034de:	1000                	addi	s0,sp,32
    800034e0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034e2:	00014517          	auipc	a0,0x14
    800034e6:	40650513          	addi	a0,a0,1030 # 800178e8 <bcache>
    800034ea:	ffffd097          	auipc	ra,0xffffd
    800034ee:	6fa080e7          	jalr	1786(ra) # 80000be4 <acquire>
  b->refcnt++;
    800034f2:	40bc                	lw	a5,64(s1)
    800034f4:	2785                	addiw	a5,a5,1
    800034f6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034f8:	00014517          	auipc	a0,0x14
    800034fc:	3f050513          	addi	a0,a0,1008 # 800178e8 <bcache>
    80003500:	ffffd097          	auipc	ra,0xffffd
    80003504:	798080e7          	jalr	1944(ra) # 80000c98 <release>
}
    80003508:	60e2                	ld	ra,24(sp)
    8000350a:	6442                	ld	s0,16(sp)
    8000350c:	64a2                	ld	s1,8(sp)
    8000350e:	6105                	addi	sp,sp,32
    80003510:	8082                	ret

0000000080003512 <bunpin>:

void
bunpin(struct buf *b) {
    80003512:	1101                	addi	sp,sp,-32
    80003514:	ec06                	sd	ra,24(sp)
    80003516:	e822                	sd	s0,16(sp)
    80003518:	e426                	sd	s1,8(sp)
    8000351a:	1000                	addi	s0,sp,32
    8000351c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000351e:	00014517          	auipc	a0,0x14
    80003522:	3ca50513          	addi	a0,a0,970 # 800178e8 <bcache>
    80003526:	ffffd097          	auipc	ra,0xffffd
    8000352a:	6be080e7          	jalr	1726(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000352e:	40bc                	lw	a5,64(s1)
    80003530:	37fd                	addiw	a5,a5,-1
    80003532:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003534:	00014517          	auipc	a0,0x14
    80003538:	3b450513          	addi	a0,a0,948 # 800178e8 <bcache>
    8000353c:	ffffd097          	auipc	ra,0xffffd
    80003540:	75c080e7          	jalr	1884(ra) # 80000c98 <release>
}
    80003544:	60e2                	ld	ra,24(sp)
    80003546:	6442                	ld	s0,16(sp)
    80003548:	64a2                	ld	s1,8(sp)
    8000354a:	6105                	addi	sp,sp,32
    8000354c:	8082                	ret

000000008000354e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000354e:	1101                	addi	sp,sp,-32
    80003550:	ec06                	sd	ra,24(sp)
    80003552:	e822                	sd	s0,16(sp)
    80003554:	e426                	sd	s1,8(sp)
    80003556:	e04a                	sd	s2,0(sp)
    80003558:	1000                	addi	s0,sp,32
    8000355a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000355c:	00d5d59b          	srliw	a1,a1,0xd
    80003560:	0001d797          	auipc	a5,0x1d
    80003564:	a647a783          	lw	a5,-1436(a5) # 8001ffc4 <sb+0x1c>
    80003568:	9dbd                	addw	a1,a1,a5
    8000356a:	00000097          	auipc	ra,0x0
    8000356e:	d9e080e7          	jalr	-610(ra) # 80003308 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003572:	0074f713          	andi	a4,s1,7
    80003576:	4785                	li	a5,1
    80003578:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000357c:	14ce                	slli	s1,s1,0x33
    8000357e:	90d9                	srli	s1,s1,0x36
    80003580:	00950733          	add	a4,a0,s1
    80003584:	05874703          	lbu	a4,88(a4)
    80003588:	00e7f6b3          	and	a3,a5,a4
    8000358c:	c69d                	beqz	a3,800035ba <bfree+0x6c>
    8000358e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003590:	94aa                	add	s1,s1,a0
    80003592:	fff7c793          	not	a5,a5
    80003596:	8ff9                	and	a5,a5,a4
    80003598:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000359c:	00001097          	auipc	ra,0x1
    800035a0:	118080e7          	jalr	280(ra) # 800046b4 <log_write>
  brelse(bp);
    800035a4:	854a                	mv	a0,s2
    800035a6:	00000097          	auipc	ra,0x0
    800035aa:	e92080e7          	jalr	-366(ra) # 80003438 <brelse>
}
    800035ae:	60e2                	ld	ra,24(sp)
    800035b0:	6442                	ld	s0,16(sp)
    800035b2:	64a2                	ld	s1,8(sp)
    800035b4:	6902                	ld	s2,0(sp)
    800035b6:	6105                	addi	sp,sp,32
    800035b8:	8082                	ret
    panic("freeing free block");
    800035ba:	00005517          	auipc	a0,0x5
    800035be:	19650513          	addi	a0,a0,406 # 80008750 <syscall_arg+0x98>
    800035c2:	ffffd097          	auipc	ra,0xffffd
    800035c6:	f7c080e7          	jalr	-132(ra) # 8000053e <panic>

00000000800035ca <balloc>:
{
    800035ca:	711d                	addi	sp,sp,-96
    800035cc:	ec86                	sd	ra,88(sp)
    800035ce:	e8a2                	sd	s0,80(sp)
    800035d0:	e4a6                	sd	s1,72(sp)
    800035d2:	e0ca                	sd	s2,64(sp)
    800035d4:	fc4e                	sd	s3,56(sp)
    800035d6:	f852                	sd	s4,48(sp)
    800035d8:	f456                	sd	s5,40(sp)
    800035da:	f05a                	sd	s6,32(sp)
    800035dc:	ec5e                	sd	s7,24(sp)
    800035de:	e862                	sd	s8,16(sp)
    800035e0:	e466                	sd	s9,8(sp)
    800035e2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800035e4:	0001d797          	auipc	a5,0x1d
    800035e8:	9c87a783          	lw	a5,-1592(a5) # 8001ffac <sb+0x4>
    800035ec:	cbd1                	beqz	a5,80003680 <balloc+0xb6>
    800035ee:	8baa                	mv	s7,a0
    800035f0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035f2:	0001db17          	auipc	s6,0x1d
    800035f6:	9b6b0b13          	addi	s6,s6,-1610 # 8001ffa8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035fa:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035fc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035fe:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003600:	6c89                	lui	s9,0x2
    80003602:	a831                	j	8000361e <balloc+0x54>
    brelse(bp);
    80003604:	854a                	mv	a0,s2
    80003606:	00000097          	auipc	ra,0x0
    8000360a:	e32080e7          	jalr	-462(ra) # 80003438 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000360e:	015c87bb          	addw	a5,s9,s5
    80003612:	00078a9b          	sext.w	s5,a5
    80003616:	004b2703          	lw	a4,4(s6)
    8000361a:	06eaf363          	bgeu	s5,a4,80003680 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000361e:	41fad79b          	sraiw	a5,s5,0x1f
    80003622:	0137d79b          	srliw	a5,a5,0x13
    80003626:	015787bb          	addw	a5,a5,s5
    8000362a:	40d7d79b          	sraiw	a5,a5,0xd
    8000362e:	01cb2583          	lw	a1,28(s6)
    80003632:	9dbd                	addw	a1,a1,a5
    80003634:	855e                	mv	a0,s7
    80003636:	00000097          	auipc	ra,0x0
    8000363a:	cd2080e7          	jalr	-814(ra) # 80003308 <bread>
    8000363e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003640:	004b2503          	lw	a0,4(s6)
    80003644:	000a849b          	sext.w	s1,s5
    80003648:	8662                	mv	a2,s8
    8000364a:	faa4fde3          	bgeu	s1,a0,80003604 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000364e:	41f6579b          	sraiw	a5,a2,0x1f
    80003652:	01d7d69b          	srliw	a3,a5,0x1d
    80003656:	00c6873b          	addw	a4,a3,a2
    8000365a:	00777793          	andi	a5,a4,7
    8000365e:	9f95                	subw	a5,a5,a3
    80003660:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003664:	4037571b          	sraiw	a4,a4,0x3
    80003668:	00e906b3          	add	a3,s2,a4
    8000366c:	0586c683          	lbu	a3,88(a3)
    80003670:	00d7f5b3          	and	a1,a5,a3
    80003674:	cd91                	beqz	a1,80003690 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003676:	2605                	addiw	a2,a2,1
    80003678:	2485                	addiw	s1,s1,1
    8000367a:	fd4618e3          	bne	a2,s4,8000364a <balloc+0x80>
    8000367e:	b759                	j	80003604 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003680:	00005517          	auipc	a0,0x5
    80003684:	0e850513          	addi	a0,a0,232 # 80008768 <syscall_arg+0xb0>
    80003688:	ffffd097          	auipc	ra,0xffffd
    8000368c:	eb6080e7          	jalr	-330(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003690:	974a                	add	a4,a4,s2
    80003692:	8fd5                	or	a5,a5,a3
    80003694:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003698:	854a                	mv	a0,s2
    8000369a:	00001097          	auipc	ra,0x1
    8000369e:	01a080e7          	jalr	26(ra) # 800046b4 <log_write>
        brelse(bp);
    800036a2:	854a                	mv	a0,s2
    800036a4:	00000097          	auipc	ra,0x0
    800036a8:	d94080e7          	jalr	-620(ra) # 80003438 <brelse>
  bp = bread(dev, bno);
    800036ac:	85a6                	mv	a1,s1
    800036ae:	855e                	mv	a0,s7
    800036b0:	00000097          	auipc	ra,0x0
    800036b4:	c58080e7          	jalr	-936(ra) # 80003308 <bread>
    800036b8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036ba:	40000613          	li	a2,1024
    800036be:	4581                	li	a1,0
    800036c0:	05850513          	addi	a0,a0,88
    800036c4:	ffffd097          	auipc	ra,0xffffd
    800036c8:	61c080e7          	jalr	1564(ra) # 80000ce0 <memset>
  log_write(bp);
    800036cc:	854a                	mv	a0,s2
    800036ce:	00001097          	auipc	ra,0x1
    800036d2:	fe6080e7          	jalr	-26(ra) # 800046b4 <log_write>
  brelse(bp);
    800036d6:	854a                	mv	a0,s2
    800036d8:	00000097          	auipc	ra,0x0
    800036dc:	d60080e7          	jalr	-672(ra) # 80003438 <brelse>
}
    800036e0:	8526                	mv	a0,s1
    800036e2:	60e6                	ld	ra,88(sp)
    800036e4:	6446                	ld	s0,80(sp)
    800036e6:	64a6                	ld	s1,72(sp)
    800036e8:	6906                	ld	s2,64(sp)
    800036ea:	79e2                	ld	s3,56(sp)
    800036ec:	7a42                	ld	s4,48(sp)
    800036ee:	7aa2                	ld	s5,40(sp)
    800036f0:	7b02                	ld	s6,32(sp)
    800036f2:	6be2                	ld	s7,24(sp)
    800036f4:	6c42                	ld	s8,16(sp)
    800036f6:	6ca2                	ld	s9,8(sp)
    800036f8:	6125                	addi	sp,sp,96
    800036fa:	8082                	ret

00000000800036fc <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800036fc:	7179                	addi	sp,sp,-48
    800036fe:	f406                	sd	ra,40(sp)
    80003700:	f022                	sd	s0,32(sp)
    80003702:	ec26                	sd	s1,24(sp)
    80003704:	e84a                	sd	s2,16(sp)
    80003706:	e44e                	sd	s3,8(sp)
    80003708:	e052                	sd	s4,0(sp)
    8000370a:	1800                	addi	s0,sp,48
    8000370c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000370e:	47ad                	li	a5,11
    80003710:	04b7fe63          	bgeu	a5,a1,8000376c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003714:	ff45849b          	addiw	s1,a1,-12
    80003718:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000371c:	0ff00793          	li	a5,255
    80003720:	0ae7e363          	bltu	a5,a4,800037c6 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003724:	08052583          	lw	a1,128(a0)
    80003728:	c5ad                	beqz	a1,80003792 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000372a:	00092503          	lw	a0,0(s2)
    8000372e:	00000097          	auipc	ra,0x0
    80003732:	bda080e7          	jalr	-1062(ra) # 80003308 <bread>
    80003736:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003738:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000373c:	02049593          	slli	a1,s1,0x20
    80003740:	9181                	srli	a1,a1,0x20
    80003742:	058a                	slli	a1,a1,0x2
    80003744:	00b784b3          	add	s1,a5,a1
    80003748:	0004a983          	lw	s3,0(s1)
    8000374c:	04098d63          	beqz	s3,800037a6 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003750:	8552                	mv	a0,s4
    80003752:	00000097          	auipc	ra,0x0
    80003756:	ce6080e7          	jalr	-794(ra) # 80003438 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000375a:	854e                	mv	a0,s3
    8000375c:	70a2                	ld	ra,40(sp)
    8000375e:	7402                	ld	s0,32(sp)
    80003760:	64e2                	ld	s1,24(sp)
    80003762:	6942                	ld	s2,16(sp)
    80003764:	69a2                	ld	s3,8(sp)
    80003766:	6a02                	ld	s4,0(sp)
    80003768:	6145                	addi	sp,sp,48
    8000376a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000376c:	02059493          	slli	s1,a1,0x20
    80003770:	9081                	srli	s1,s1,0x20
    80003772:	048a                	slli	s1,s1,0x2
    80003774:	94aa                	add	s1,s1,a0
    80003776:	0504a983          	lw	s3,80(s1)
    8000377a:	fe0990e3          	bnez	s3,8000375a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000377e:	4108                	lw	a0,0(a0)
    80003780:	00000097          	auipc	ra,0x0
    80003784:	e4a080e7          	jalr	-438(ra) # 800035ca <balloc>
    80003788:	0005099b          	sext.w	s3,a0
    8000378c:	0534a823          	sw	s3,80(s1)
    80003790:	b7e9                	j	8000375a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003792:	4108                	lw	a0,0(a0)
    80003794:	00000097          	auipc	ra,0x0
    80003798:	e36080e7          	jalr	-458(ra) # 800035ca <balloc>
    8000379c:	0005059b          	sext.w	a1,a0
    800037a0:	08b92023          	sw	a1,128(s2)
    800037a4:	b759                	j	8000372a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800037a6:	00092503          	lw	a0,0(s2)
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	e20080e7          	jalr	-480(ra) # 800035ca <balloc>
    800037b2:	0005099b          	sext.w	s3,a0
    800037b6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800037ba:	8552                	mv	a0,s4
    800037bc:	00001097          	auipc	ra,0x1
    800037c0:	ef8080e7          	jalr	-264(ra) # 800046b4 <log_write>
    800037c4:	b771                	j	80003750 <bmap+0x54>
  panic("bmap: out of range");
    800037c6:	00005517          	auipc	a0,0x5
    800037ca:	fba50513          	addi	a0,a0,-70 # 80008780 <syscall_arg+0xc8>
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	d70080e7          	jalr	-656(ra) # 8000053e <panic>

00000000800037d6 <iget>:
{
    800037d6:	7179                	addi	sp,sp,-48
    800037d8:	f406                	sd	ra,40(sp)
    800037da:	f022                	sd	s0,32(sp)
    800037dc:	ec26                	sd	s1,24(sp)
    800037de:	e84a                	sd	s2,16(sp)
    800037e0:	e44e                	sd	s3,8(sp)
    800037e2:	e052                	sd	s4,0(sp)
    800037e4:	1800                	addi	s0,sp,48
    800037e6:	89aa                	mv	s3,a0
    800037e8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800037ea:	0001c517          	auipc	a0,0x1c
    800037ee:	7de50513          	addi	a0,a0,2014 # 8001ffc8 <itable>
    800037f2:	ffffd097          	auipc	ra,0xffffd
    800037f6:	3f2080e7          	jalr	1010(ra) # 80000be4 <acquire>
  empty = 0;
    800037fa:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037fc:	0001c497          	auipc	s1,0x1c
    80003800:	7e448493          	addi	s1,s1,2020 # 8001ffe0 <itable+0x18>
    80003804:	0001e697          	auipc	a3,0x1e
    80003808:	26c68693          	addi	a3,a3,620 # 80021a70 <log>
    8000380c:	a039                	j	8000381a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000380e:	02090b63          	beqz	s2,80003844 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003812:	08848493          	addi	s1,s1,136
    80003816:	02d48a63          	beq	s1,a3,8000384a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000381a:	449c                	lw	a5,8(s1)
    8000381c:	fef059e3          	blez	a5,8000380e <iget+0x38>
    80003820:	4098                	lw	a4,0(s1)
    80003822:	ff3716e3          	bne	a4,s3,8000380e <iget+0x38>
    80003826:	40d8                	lw	a4,4(s1)
    80003828:	ff4713e3          	bne	a4,s4,8000380e <iget+0x38>
      ip->ref++;
    8000382c:	2785                	addiw	a5,a5,1
    8000382e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003830:	0001c517          	auipc	a0,0x1c
    80003834:	79850513          	addi	a0,a0,1944 # 8001ffc8 <itable>
    80003838:	ffffd097          	auipc	ra,0xffffd
    8000383c:	460080e7          	jalr	1120(ra) # 80000c98 <release>
      return ip;
    80003840:	8926                	mv	s2,s1
    80003842:	a03d                	j	80003870 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003844:	f7f9                	bnez	a5,80003812 <iget+0x3c>
    80003846:	8926                	mv	s2,s1
    80003848:	b7e9                	j	80003812 <iget+0x3c>
  if(empty == 0)
    8000384a:	02090c63          	beqz	s2,80003882 <iget+0xac>
  ip->dev = dev;
    8000384e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003852:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003856:	4785                	li	a5,1
    80003858:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000385c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003860:	0001c517          	auipc	a0,0x1c
    80003864:	76850513          	addi	a0,a0,1896 # 8001ffc8 <itable>
    80003868:	ffffd097          	auipc	ra,0xffffd
    8000386c:	430080e7          	jalr	1072(ra) # 80000c98 <release>
}
    80003870:	854a                	mv	a0,s2
    80003872:	70a2                	ld	ra,40(sp)
    80003874:	7402                	ld	s0,32(sp)
    80003876:	64e2                	ld	s1,24(sp)
    80003878:	6942                	ld	s2,16(sp)
    8000387a:	69a2                	ld	s3,8(sp)
    8000387c:	6a02                	ld	s4,0(sp)
    8000387e:	6145                	addi	sp,sp,48
    80003880:	8082                	ret
    panic("iget: no inodes");
    80003882:	00005517          	auipc	a0,0x5
    80003886:	f1650513          	addi	a0,a0,-234 # 80008798 <syscall_arg+0xe0>
    8000388a:	ffffd097          	auipc	ra,0xffffd
    8000388e:	cb4080e7          	jalr	-844(ra) # 8000053e <panic>

0000000080003892 <fsinit>:
fsinit(int dev) {
    80003892:	7179                	addi	sp,sp,-48
    80003894:	f406                	sd	ra,40(sp)
    80003896:	f022                	sd	s0,32(sp)
    80003898:	ec26                	sd	s1,24(sp)
    8000389a:	e84a                	sd	s2,16(sp)
    8000389c:	e44e                	sd	s3,8(sp)
    8000389e:	1800                	addi	s0,sp,48
    800038a0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800038a2:	4585                	li	a1,1
    800038a4:	00000097          	auipc	ra,0x0
    800038a8:	a64080e7          	jalr	-1436(ra) # 80003308 <bread>
    800038ac:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800038ae:	0001c997          	auipc	s3,0x1c
    800038b2:	6fa98993          	addi	s3,s3,1786 # 8001ffa8 <sb>
    800038b6:	02000613          	li	a2,32
    800038ba:	05850593          	addi	a1,a0,88
    800038be:	854e                	mv	a0,s3
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	480080e7          	jalr	1152(ra) # 80000d40 <memmove>
  brelse(bp);
    800038c8:	8526                	mv	a0,s1
    800038ca:	00000097          	auipc	ra,0x0
    800038ce:	b6e080e7          	jalr	-1170(ra) # 80003438 <brelse>
  if(sb.magic != FSMAGIC)
    800038d2:	0009a703          	lw	a4,0(s3)
    800038d6:	102037b7          	lui	a5,0x10203
    800038da:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038de:	02f71263          	bne	a4,a5,80003902 <fsinit+0x70>
  initlog(dev, &sb);
    800038e2:	0001c597          	auipc	a1,0x1c
    800038e6:	6c658593          	addi	a1,a1,1734 # 8001ffa8 <sb>
    800038ea:	854a                	mv	a0,s2
    800038ec:	00001097          	auipc	ra,0x1
    800038f0:	b4c080e7          	jalr	-1204(ra) # 80004438 <initlog>
}
    800038f4:	70a2                	ld	ra,40(sp)
    800038f6:	7402                	ld	s0,32(sp)
    800038f8:	64e2                	ld	s1,24(sp)
    800038fa:	6942                	ld	s2,16(sp)
    800038fc:	69a2                	ld	s3,8(sp)
    800038fe:	6145                	addi	sp,sp,48
    80003900:	8082                	ret
    panic("invalid file system");
    80003902:	00005517          	auipc	a0,0x5
    80003906:	ea650513          	addi	a0,a0,-346 # 800087a8 <syscall_arg+0xf0>
    8000390a:	ffffd097          	auipc	ra,0xffffd
    8000390e:	c34080e7          	jalr	-972(ra) # 8000053e <panic>

0000000080003912 <iinit>:
{
    80003912:	7179                	addi	sp,sp,-48
    80003914:	f406                	sd	ra,40(sp)
    80003916:	f022                	sd	s0,32(sp)
    80003918:	ec26                	sd	s1,24(sp)
    8000391a:	e84a                	sd	s2,16(sp)
    8000391c:	e44e                	sd	s3,8(sp)
    8000391e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003920:	00005597          	auipc	a1,0x5
    80003924:	ea058593          	addi	a1,a1,-352 # 800087c0 <syscall_arg+0x108>
    80003928:	0001c517          	auipc	a0,0x1c
    8000392c:	6a050513          	addi	a0,a0,1696 # 8001ffc8 <itable>
    80003930:	ffffd097          	auipc	ra,0xffffd
    80003934:	224080e7          	jalr	548(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003938:	0001c497          	auipc	s1,0x1c
    8000393c:	6b848493          	addi	s1,s1,1720 # 8001fff0 <itable+0x28>
    80003940:	0001e997          	auipc	s3,0x1e
    80003944:	14098993          	addi	s3,s3,320 # 80021a80 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003948:	00005917          	auipc	s2,0x5
    8000394c:	e8090913          	addi	s2,s2,-384 # 800087c8 <syscall_arg+0x110>
    80003950:	85ca                	mv	a1,s2
    80003952:	8526                	mv	a0,s1
    80003954:	00001097          	auipc	ra,0x1
    80003958:	e46080e7          	jalr	-442(ra) # 8000479a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000395c:	08848493          	addi	s1,s1,136
    80003960:	ff3498e3          	bne	s1,s3,80003950 <iinit+0x3e>
}
    80003964:	70a2                	ld	ra,40(sp)
    80003966:	7402                	ld	s0,32(sp)
    80003968:	64e2                	ld	s1,24(sp)
    8000396a:	6942                	ld	s2,16(sp)
    8000396c:	69a2                	ld	s3,8(sp)
    8000396e:	6145                	addi	sp,sp,48
    80003970:	8082                	ret

0000000080003972 <ialloc>:
{
    80003972:	715d                	addi	sp,sp,-80
    80003974:	e486                	sd	ra,72(sp)
    80003976:	e0a2                	sd	s0,64(sp)
    80003978:	fc26                	sd	s1,56(sp)
    8000397a:	f84a                	sd	s2,48(sp)
    8000397c:	f44e                	sd	s3,40(sp)
    8000397e:	f052                	sd	s4,32(sp)
    80003980:	ec56                	sd	s5,24(sp)
    80003982:	e85a                	sd	s6,16(sp)
    80003984:	e45e                	sd	s7,8(sp)
    80003986:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003988:	0001c717          	auipc	a4,0x1c
    8000398c:	62c72703          	lw	a4,1580(a4) # 8001ffb4 <sb+0xc>
    80003990:	4785                	li	a5,1
    80003992:	04e7fa63          	bgeu	a5,a4,800039e6 <ialloc+0x74>
    80003996:	8aaa                	mv	s5,a0
    80003998:	8bae                	mv	s7,a1
    8000399a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000399c:	0001ca17          	auipc	s4,0x1c
    800039a0:	60ca0a13          	addi	s4,s4,1548 # 8001ffa8 <sb>
    800039a4:	00048b1b          	sext.w	s6,s1
    800039a8:	0044d593          	srli	a1,s1,0x4
    800039ac:	018a2783          	lw	a5,24(s4)
    800039b0:	9dbd                	addw	a1,a1,a5
    800039b2:	8556                	mv	a0,s5
    800039b4:	00000097          	auipc	ra,0x0
    800039b8:	954080e7          	jalr	-1708(ra) # 80003308 <bread>
    800039bc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800039be:	05850993          	addi	s3,a0,88
    800039c2:	00f4f793          	andi	a5,s1,15
    800039c6:	079a                	slli	a5,a5,0x6
    800039c8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039ca:	00099783          	lh	a5,0(s3)
    800039ce:	c785                	beqz	a5,800039f6 <ialloc+0x84>
    brelse(bp);
    800039d0:	00000097          	auipc	ra,0x0
    800039d4:	a68080e7          	jalr	-1432(ra) # 80003438 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800039d8:	0485                	addi	s1,s1,1
    800039da:	00ca2703          	lw	a4,12(s4)
    800039de:	0004879b          	sext.w	a5,s1
    800039e2:	fce7e1e3          	bltu	a5,a4,800039a4 <ialloc+0x32>
  panic("ialloc: no inodes");
    800039e6:	00005517          	auipc	a0,0x5
    800039ea:	dea50513          	addi	a0,a0,-534 # 800087d0 <syscall_arg+0x118>
    800039ee:	ffffd097          	auipc	ra,0xffffd
    800039f2:	b50080e7          	jalr	-1200(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800039f6:	04000613          	li	a2,64
    800039fa:	4581                	li	a1,0
    800039fc:	854e                	mv	a0,s3
    800039fe:	ffffd097          	auipc	ra,0xffffd
    80003a02:	2e2080e7          	jalr	738(ra) # 80000ce0 <memset>
      dip->type = type;
    80003a06:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a0a:	854a                	mv	a0,s2
    80003a0c:	00001097          	auipc	ra,0x1
    80003a10:	ca8080e7          	jalr	-856(ra) # 800046b4 <log_write>
      brelse(bp);
    80003a14:	854a                	mv	a0,s2
    80003a16:	00000097          	auipc	ra,0x0
    80003a1a:	a22080e7          	jalr	-1502(ra) # 80003438 <brelse>
      return iget(dev, inum);
    80003a1e:	85da                	mv	a1,s6
    80003a20:	8556                	mv	a0,s5
    80003a22:	00000097          	auipc	ra,0x0
    80003a26:	db4080e7          	jalr	-588(ra) # 800037d6 <iget>
}
    80003a2a:	60a6                	ld	ra,72(sp)
    80003a2c:	6406                	ld	s0,64(sp)
    80003a2e:	74e2                	ld	s1,56(sp)
    80003a30:	7942                	ld	s2,48(sp)
    80003a32:	79a2                	ld	s3,40(sp)
    80003a34:	7a02                	ld	s4,32(sp)
    80003a36:	6ae2                	ld	s5,24(sp)
    80003a38:	6b42                	ld	s6,16(sp)
    80003a3a:	6ba2                	ld	s7,8(sp)
    80003a3c:	6161                	addi	sp,sp,80
    80003a3e:	8082                	ret

0000000080003a40 <iupdate>:
{
    80003a40:	1101                	addi	sp,sp,-32
    80003a42:	ec06                	sd	ra,24(sp)
    80003a44:	e822                	sd	s0,16(sp)
    80003a46:	e426                	sd	s1,8(sp)
    80003a48:	e04a                	sd	s2,0(sp)
    80003a4a:	1000                	addi	s0,sp,32
    80003a4c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a4e:	415c                	lw	a5,4(a0)
    80003a50:	0047d79b          	srliw	a5,a5,0x4
    80003a54:	0001c597          	auipc	a1,0x1c
    80003a58:	56c5a583          	lw	a1,1388(a1) # 8001ffc0 <sb+0x18>
    80003a5c:	9dbd                	addw	a1,a1,a5
    80003a5e:	4108                	lw	a0,0(a0)
    80003a60:	00000097          	auipc	ra,0x0
    80003a64:	8a8080e7          	jalr	-1880(ra) # 80003308 <bread>
    80003a68:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a6a:	05850793          	addi	a5,a0,88
    80003a6e:	40c8                	lw	a0,4(s1)
    80003a70:	893d                	andi	a0,a0,15
    80003a72:	051a                	slli	a0,a0,0x6
    80003a74:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003a76:	04449703          	lh	a4,68(s1)
    80003a7a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003a7e:	04649703          	lh	a4,70(s1)
    80003a82:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003a86:	04849703          	lh	a4,72(s1)
    80003a8a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003a8e:	04a49703          	lh	a4,74(s1)
    80003a92:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003a96:	44f8                	lw	a4,76(s1)
    80003a98:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a9a:	03400613          	li	a2,52
    80003a9e:	05048593          	addi	a1,s1,80
    80003aa2:	0531                	addi	a0,a0,12
    80003aa4:	ffffd097          	auipc	ra,0xffffd
    80003aa8:	29c080e7          	jalr	668(ra) # 80000d40 <memmove>
  log_write(bp);
    80003aac:	854a                	mv	a0,s2
    80003aae:	00001097          	auipc	ra,0x1
    80003ab2:	c06080e7          	jalr	-1018(ra) # 800046b4 <log_write>
  brelse(bp);
    80003ab6:	854a                	mv	a0,s2
    80003ab8:	00000097          	auipc	ra,0x0
    80003abc:	980080e7          	jalr	-1664(ra) # 80003438 <brelse>
}
    80003ac0:	60e2                	ld	ra,24(sp)
    80003ac2:	6442                	ld	s0,16(sp)
    80003ac4:	64a2                	ld	s1,8(sp)
    80003ac6:	6902                	ld	s2,0(sp)
    80003ac8:	6105                	addi	sp,sp,32
    80003aca:	8082                	ret

0000000080003acc <idup>:
{
    80003acc:	1101                	addi	sp,sp,-32
    80003ace:	ec06                	sd	ra,24(sp)
    80003ad0:	e822                	sd	s0,16(sp)
    80003ad2:	e426                	sd	s1,8(sp)
    80003ad4:	1000                	addi	s0,sp,32
    80003ad6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ad8:	0001c517          	auipc	a0,0x1c
    80003adc:	4f050513          	addi	a0,a0,1264 # 8001ffc8 <itable>
    80003ae0:	ffffd097          	auipc	ra,0xffffd
    80003ae4:	104080e7          	jalr	260(ra) # 80000be4 <acquire>
  ip->ref++;
    80003ae8:	449c                	lw	a5,8(s1)
    80003aea:	2785                	addiw	a5,a5,1
    80003aec:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003aee:	0001c517          	auipc	a0,0x1c
    80003af2:	4da50513          	addi	a0,a0,1242 # 8001ffc8 <itable>
    80003af6:	ffffd097          	auipc	ra,0xffffd
    80003afa:	1a2080e7          	jalr	418(ra) # 80000c98 <release>
}
    80003afe:	8526                	mv	a0,s1
    80003b00:	60e2                	ld	ra,24(sp)
    80003b02:	6442                	ld	s0,16(sp)
    80003b04:	64a2                	ld	s1,8(sp)
    80003b06:	6105                	addi	sp,sp,32
    80003b08:	8082                	ret

0000000080003b0a <ilock>:
{
    80003b0a:	1101                	addi	sp,sp,-32
    80003b0c:	ec06                	sd	ra,24(sp)
    80003b0e:	e822                	sd	s0,16(sp)
    80003b10:	e426                	sd	s1,8(sp)
    80003b12:	e04a                	sd	s2,0(sp)
    80003b14:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b16:	c115                	beqz	a0,80003b3a <ilock+0x30>
    80003b18:	84aa                	mv	s1,a0
    80003b1a:	451c                	lw	a5,8(a0)
    80003b1c:	00f05f63          	blez	a5,80003b3a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b20:	0541                	addi	a0,a0,16
    80003b22:	00001097          	auipc	ra,0x1
    80003b26:	cb2080e7          	jalr	-846(ra) # 800047d4 <acquiresleep>
  if(ip->valid == 0){
    80003b2a:	40bc                	lw	a5,64(s1)
    80003b2c:	cf99                	beqz	a5,80003b4a <ilock+0x40>
}
    80003b2e:	60e2                	ld	ra,24(sp)
    80003b30:	6442                	ld	s0,16(sp)
    80003b32:	64a2                	ld	s1,8(sp)
    80003b34:	6902                	ld	s2,0(sp)
    80003b36:	6105                	addi	sp,sp,32
    80003b38:	8082                	ret
    panic("ilock");
    80003b3a:	00005517          	auipc	a0,0x5
    80003b3e:	cae50513          	addi	a0,a0,-850 # 800087e8 <syscall_arg+0x130>
    80003b42:	ffffd097          	auipc	ra,0xffffd
    80003b46:	9fc080e7          	jalr	-1540(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b4a:	40dc                	lw	a5,4(s1)
    80003b4c:	0047d79b          	srliw	a5,a5,0x4
    80003b50:	0001c597          	auipc	a1,0x1c
    80003b54:	4705a583          	lw	a1,1136(a1) # 8001ffc0 <sb+0x18>
    80003b58:	9dbd                	addw	a1,a1,a5
    80003b5a:	4088                	lw	a0,0(s1)
    80003b5c:	fffff097          	auipc	ra,0xfffff
    80003b60:	7ac080e7          	jalr	1964(ra) # 80003308 <bread>
    80003b64:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b66:	05850593          	addi	a1,a0,88
    80003b6a:	40dc                	lw	a5,4(s1)
    80003b6c:	8bbd                	andi	a5,a5,15
    80003b6e:	079a                	slli	a5,a5,0x6
    80003b70:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b72:	00059783          	lh	a5,0(a1)
    80003b76:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b7a:	00259783          	lh	a5,2(a1)
    80003b7e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b82:	00459783          	lh	a5,4(a1)
    80003b86:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b8a:	00659783          	lh	a5,6(a1)
    80003b8e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b92:	459c                	lw	a5,8(a1)
    80003b94:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b96:	03400613          	li	a2,52
    80003b9a:	05b1                	addi	a1,a1,12
    80003b9c:	05048513          	addi	a0,s1,80
    80003ba0:	ffffd097          	auipc	ra,0xffffd
    80003ba4:	1a0080e7          	jalr	416(ra) # 80000d40 <memmove>
    brelse(bp);
    80003ba8:	854a                	mv	a0,s2
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	88e080e7          	jalr	-1906(ra) # 80003438 <brelse>
    ip->valid = 1;
    80003bb2:	4785                	li	a5,1
    80003bb4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003bb6:	04449783          	lh	a5,68(s1)
    80003bba:	fbb5                	bnez	a5,80003b2e <ilock+0x24>
      panic("ilock: no type");
    80003bbc:	00005517          	auipc	a0,0x5
    80003bc0:	c3450513          	addi	a0,a0,-972 # 800087f0 <syscall_arg+0x138>
    80003bc4:	ffffd097          	auipc	ra,0xffffd
    80003bc8:	97a080e7          	jalr	-1670(ra) # 8000053e <panic>

0000000080003bcc <iunlock>:
{
    80003bcc:	1101                	addi	sp,sp,-32
    80003bce:	ec06                	sd	ra,24(sp)
    80003bd0:	e822                	sd	s0,16(sp)
    80003bd2:	e426                	sd	s1,8(sp)
    80003bd4:	e04a                	sd	s2,0(sp)
    80003bd6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003bd8:	c905                	beqz	a0,80003c08 <iunlock+0x3c>
    80003bda:	84aa                	mv	s1,a0
    80003bdc:	01050913          	addi	s2,a0,16
    80003be0:	854a                	mv	a0,s2
    80003be2:	00001097          	auipc	ra,0x1
    80003be6:	c8c080e7          	jalr	-884(ra) # 8000486e <holdingsleep>
    80003bea:	cd19                	beqz	a0,80003c08 <iunlock+0x3c>
    80003bec:	449c                	lw	a5,8(s1)
    80003bee:	00f05d63          	blez	a5,80003c08 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003bf2:	854a                	mv	a0,s2
    80003bf4:	00001097          	auipc	ra,0x1
    80003bf8:	c36080e7          	jalr	-970(ra) # 8000482a <releasesleep>
}
    80003bfc:	60e2                	ld	ra,24(sp)
    80003bfe:	6442                	ld	s0,16(sp)
    80003c00:	64a2                	ld	s1,8(sp)
    80003c02:	6902                	ld	s2,0(sp)
    80003c04:	6105                	addi	sp,sp,32
    80003c06:	8082                	ret
    panic("iunlock");
    80003c08:	00005517          	auipc	a0,0x5
    80003c0c:	bf850513          	addi	a0,a0,-1032 # 80008800 <syscall_arg+0x148>
    80003c10:	ffffd097          	auipc	ra,0xffffd
    80003c14:	92e080e7          	jalr	-1746(ra) # 8000053e <panic>

0000000080003c18 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c18:	7179                	addi	sp,sp,-48
    80003c1a:	f406                	sd	ra,40(sp)
    80003c1c:	f022                	sd	s0,32(sp)
    80003c1e:	ec26                	sd	s1,24(sp)
    80003c20:	e84a                	sd	s2,16(sp)
    80003c22:	e44e                	sd	s3,8(sp)
    80003c24:	e052                	sd	s4,0(sp)
    80003c26:	1800                	addi	s0,sp,48
    80003c28:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c2a:	05050493          	addi	s1,a0,80
    80003c2e:	08050913          	addi	s2,a0,128
    80003c32:	a021                	j	80003c3a <itrunc+0x22>
    80003c34:	0491                	addi	s1,s1,4
    80003c36:	01248d63          	beq	s1,s2,80003c50 <itrunc+0x38>
    if(ip->addrs[i]){
    80003c3a:	408c                	lw	a1,0(s1)
    80003c3c:	dde5                	beqz	a1,80003c34 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c3e:	0009a503          	lw	a0,0(s3)
    80003c42:	00000097          	auipc	ra,0x0
    80003c46:	90c080e7          	jalr	-1780(ra) # 8000354e <bfree>
      ip->addrs[i] = 0;
    80003c4a:	0004a023          	sw	zero,0(s1)
    80003c4e:	b7dd                	j	80003c34 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c50:	0809a583          	lw	a1,128(s3)
    80003c54:	e185                	bnez	a1,80003c74 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c56:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c5a:	854e                	mv	a0,s3
    80003c5c:	00000097          	auipc	ra,0x0
    80003c60:	de4080e7          	jalr	-540(ra) # 80003a40 <iupdate>
}
    80003c64:	70a2                	ld	ra,40(sp)
    80003c66:	7402                	ld	s0,32(sp)
    80003c68:	64e2                	ld	s1,24(sp)
    80003c6a:	6942                	ld	s2,16(sp)
    80003c6c:	69a2                	ld	s3,8(sp)
    80003c6e:	6a02                	ld	s4,0(sp)
    80003c70:	6145                	addi	sp,sp,48
    80003c72:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c74:	0009a503          	lw	a0,0(s3)
    80003c78:	fffff097          	auipc	ra,0xfffff
    80003c7c:	690080e7          	jalr	1680(ra) # 80003308 <bread>
    80003c80:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c82:	05850493          	addi	s1,a0,88
    80003c86:	45850913          	addi	s2,a0,1112
    80003c8a:	a811                	j	80003c9e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003c8c:	0009a503          	lw	a0,0(s3)
    80003c90:	00000097          	auipc	ra,0x0
    80003c94:	8be080e7          	jalr	-1858(ra) # 8000354e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003c98:	0491                	addi	s1,s1,4
    80003c9a:	01248563          	beq	s1,s2,80003ca4 <itrunc+0x8c>
      if(a[j])
    80003c9e:	408c                	lw	a1,0(s1)
    80003ca0:	dde5                	beqz	a1,80003c98 <itrunc+0x80>
    80003ca2:	b7ed                	j	80003c8c <itrunc+0x74>
    brelse(bp);
    80003ca4:	8552                	mv	a0,s4
    80003ca6:	fffff097          	auipc	ra,0xfffff
    80003caa:	792080e7          	jalr	1938(ra) # 80003438 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003cae:	0809a583          	lw	a1,128(s3)
    80003cb2:	0009a503          	lw	a0,0(s3)
    80003cb6:	00000097          	auipc	ra,0x0
    80003cba:	898080e7          	jalr	-1896(ra) # 8000354e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003cbe:	0809a023          	sw	zero,128(s3)
    80003cc2:	bf51                	j	80003c56 <itrunc+0x3e>

0000000080003cc4 <iput>:
{
    80003cc4:	1101                	addi	sp,sp,-32
    80003cc6:	ec06                	sd	ra,24(sp)
    80003cc8:	e822                	sd	s0,16(sp)
    80003cca:	e426                	sd	s1,8(sp)
    80003ccc:	e04a                	sd	s2,0(sp)
    80003cce:	1000                	addi	s0,sp,32
    80003cd0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cd2:	0001c517          	auipc	a0,0x1c
    80003cd6:	2f650513          	addi	a0,a0,758 # 8001ffc8 <itable>
    80003cda:	ffffd097          	auipc	ra,0xffffd
    80003cde:	f0a080e7          	jalr	-246(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ce2:	4498                	lw	a4,8(s1)
    80003ce4:	4785                	li	a5,1
    80003ce6:	02f70363          	beq	a4,a5,80003d0c <iput+0x48>
  ip->ref--;
    80003cea:	449c                	lw	a5,8(s1)
    80003cec:	37fd                	addiw	a5,a5,-1
    80003cee:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cf0:	0001c517          	auipc	a0,0x1c
    80003cf4:	2d850513          	addi	a0,a0,728 # 8001ffc8 <itable>
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	fa0080e7          	jalr	-96(ra) # 80000c98 <release>
}
    80003d00:	60e2                	ld	ra,24(sp)
    80003d02:	6442                	ld	s0,16(sp)
    80003d04:	64a2                	ld	s1,8(sp)
    80003d06:	6902                	ld	s2,0(sp)
    80003d08:	6105                	addi	sp,sp,32
    80003d0a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d0c:	40bc                	lw	a5,64(s1)
    80003d0e:	dff1                	beqz	a5,80003cea <iput+0x26>
    80003d10:	04a49783          	lh	a5,74(s1)
    80003d14:	fbf9                	bnez	a5,80003cea <iput+0x26>
    acquiresleep(&ip->lock);
    80003d16:	01048913          	addi	s2,s1,16
    80003d1a:	854a                	mv	a0,s2
    80003d1c:	00001097          	auipc	ra,0x1
    80003d20:	ab8080e7          	jalr	-1352(ra) # 800047d4 <acquiresleep>
    release(&itable.lock);
    80003d24:	0001c517          	auipc	a0,0x1c
    80003d28:	2a450513          	addi	a0,a0,676 # 8001ffc8 <itable>
    80003d2c:	ffffd097          	auipc	ra,0xffffd
    80003d30:	f6c080e7          	jalr	-148(ra) # 80000c98 <release>
    itrunc(ip);
    80003d34:	8526                	mv	a0,s1
    80003d36:	00000097          	auipc	ra,0x0
    80003d3a:	ee2080e7          	jalr	-286(ra) # 80003c18 <itrunc>
    ip->type = 0;
    80003d3e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d42:	8526                	mv	a0,s1
    80003d44:	00000097          	auipc	ra,0x0
    80003d48:	cfc080e7          	jalr	-772(ra) # 80003a40 <iupdate>
    ip->valid = 0;
    80003d4c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d50:	854a                	mv	a0,s2
    80003d52:	00001097          	auipc	ra,0x1
    80003d56:	ad8080e7          	jalr	-1320(ra) # 8000482a <releasesleep>
    acquire(&itable.lock);
    80003d5a:	0001c517          	auipc	a0,0x1c
    80003d5e:	26e50513          	addi	a0,a0,622 # 8001ffc8 <itable>
    80003d62:	ffffd097          	auipc	ra,0xffffd
    80003d66:	e82080e7          	jalr	-382(ra) # 80000be4 <acquire>
    80003d6a:	b741                	j	80003cea <iput+0x26>

0000000080003d6c <iunlockput>:
{
    80003d6c:	1101                	addi	sp,sp,-32
    80003d6e:	ec06                	sd	ra,24(sp)
    80003d70:	e822                	sd	s0,16(sp)
    80003d72:	e426                	sd	s1,8(sp)
    80003d74:	1000                	addi	s0,sp,32
    80003d76:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d78:	00000097          	auipc	ra,0x0
    80003d7c:	e54080e7          	jalr	-428(ra) # 80003bcc <iunlock>
  iput(ip);
    80003d80:	8526                	mv	a0,s1
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	f42080e7          	jalr	-190(ra) # 80003cc4 <iput>
}
    80003d8a:	60e2                	ld	ra,24(sp)
    80003d8c:	6442                	ld	s0,16(sp)
    80003d8e:	64a2                	ld	s1,8(sp)
    80003d90:	6105                	addi	sp,sp,32
    80003d92:	8082                	ret

0000000080003d94 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d94:	1141                	addi	sp,sp,-16
    80003d96:	e422                	sd	s0,8(sp)
    80003d98:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d9a:	411c                	lw	a5,0(a0)
    80003d9c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d9e:	415c                	lw	a5,4(a0)
    80003da0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003da2:	04451783          	lh	a5,68(a0)
    80003da6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003daa:	04a51783          	lh	a5,74(a0)
    80003dae:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003db2:	04c56783          	lwu	a5,76(a0)
    80003db6:	e99c                	sd	a5,16(a1)
}
    80003db8:	6422                	ld	s0,8(sp)
    80003dba:	0141                	addi	sp,sp,16
    80003dbc:	8082                	ret

0000000080003dbe <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dbe:	457c                	lw	a5,76(a0)
    80003dc0:	0ed7e963          	bltu	a5,a3,80003eb2 <readi+0xf4>
{
    80003dc4:	7159                	addi	sp,sp,-112
    80003dc6:	f486                	sd	ra,104(sp)
    80003dc8:	f0a2                	sd	s0,96(sp)
    80003dca:	eca6                	sd	s1,88(sp)
    80003dcc:	e8ca                	sd	s2,80(sp)
    80003dce:	e4ce                	sd	s3,72(sp)
    80003dd0:	e0d2                	sd	s4,64(sp)
    80003dd2:	fc56                	sd	s5,56(sp)
    80003dd4:	f85a                	sd	s6,48(sp)
    80003dd6:	f45e                	sd	s7,40(sp)
    80003dd8:	f062                	sd	s8,32(sp)
    80003dda:	ec66                	sd	s9,24(sp)
    80003ddc:	e86a                	sd	s10,16(sp)
    80003dde:	e46e                	sd	s11,8(sp)
    80003de0:	1880                	addi	s0,sp,112
    80003de2:	8baa                	mv	s7,a0
    80003de4:	8c2e                	mv	s8,a1
    80003de6:	8ab2                	mv	s5,a2
    80003de8:	84b6                	mv	s1,a3
    80003dea:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003dec:	9f35                	addw	a4,a4,a3
    return 0;
    80003dee:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003df0:	0ad76063          	bltu	a4,a3,80003e90 <readi+0xd2>
  if(off + n > ip->size)
    80003df4:	00e7f463          	bgeu	a5,a4,80003dfc <readi+0x3e>
    n = ip->size - off;
    80003df8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dfc:	0a0b0963          	beqz	s6,80003eae <readi+0xf0>
    80003e00:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e02:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e06:	5cfd                	li	s9,-1
    80003e08:	a82d                	j	80003e42 <readi+0x84>
    80003e0a:	020a1d93          	slli	s11,s4,0x20
    80003e0e:	020ddd93          	srli	s11,s11,0x20
    80003e12:	05890613          	addi	a2,s2,88
    80003e16:	86ee                	mv	a3,s11
    80003e18:	963a                	add	a2,a2,a4
    80003e1a:	85d6                	mv	a1,s5
    80003e1c:	8562                	mv	a0,s8
    80003e1e:	ffffe097          	auipc	ra,0xffffe
    80003e22:	7f6080e7          	jalr	2038(ra) # 80002614 <either_copyout>
    80003e26:	05950d63          	beq	a0,s9,80003e80 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e2a:	854a                	mv	a0,s2
    80003e2c:	fffff097          	auipc	ra,0xfffff
    80003e30:	60c080e7          	jalr	1548(ra) # 80003438 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e34:	013a09bb          	addw	s3,s4,s3
    80003e38:	009a04bb          	addw	s1,s4,s1
    80003e3c:	9aee                	add	s5,s5,s11
    80003e3e:	0569f763          	bgeu	s3,s6,80003e8c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e42:	000ba903          	lw	s2,0(s7)
    80003e46:	00a4d59b          	srliw	a1,s1,0xa
    80003e4a:	855e                	mv	a0,s7
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	8b0080e7          	jalr	-1872(ra) # 800036fc <bmap>
    80003e54:	0005059b          	sext.w	a1,a0
    80003e58:	854a                	mv	a0,s2
    80003e5a:	fffff097          	auipc	ra,0xfffff
    80003e5e:	4ae080e7          	jalr	1198(ra) # 80003308 <bread>
    80003e62:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e64:	3ff4f713          	andi	a4,s1,1023
    80003e68:	40ed07bb          	subw	a5,s10,a4
    80003e6c:	413b06bb          	subw	a3,s6,s3
    80003e70:	8a3e                	mv	s4,a5
    80003e72:	2781                	sext.w	a5,a5
    80003e74:	0006861b          	sext.w	a2,a3
    80003e78:	f8f679e3          	bgeu	a2,a5,80003e0a <readi+0x4c>
    80003e7c:	8a36                	mv	s4,a3
    80003e7e:	b771                	j	80003e0a <readi+0x4c>
      brelse(bp);
    80003e80:	854a                	mv	a0,s2
    80003e82:	fffff097          	auipc	ra,0xfffff
    80003e86:	5b6080e7          	jalr	1462(ra) # 80003438 <brelse>
      tot = -1;
    80003e8a:	59fd                	li	s3,-1
  }
  return tot;
    80003e8c:	0009851b          	sext.w	a0,s3
}
    80003e90:	70a6                	ld	ra,104(sp)
    80003e92:	7406                	ld	s0,96(sp)
    80003e94:	64e6                	ld	s1,88(sp)
    80003e96:	6946                	ld	s2,80(sp)
    80003e98:	69a6                	ld	s3,72(sp)
    80003e9a:	6a06                	ld	s4,64(sp)
    80003e9c:	7ae2                	ld	s5,56(sp)
    80003e9e:	7b42                	ld	s6,48(sp)
    80003ea0:	7ba2                	ld	s7,40(sp)
    80003ea2:	7c02                	ld	s8,32(sp)
    80003ea4:	6ce2                	ld	s9,24(sp)
    80003ea6:	6d42                	ld	s10,16(sp)
    80003ea8:	6da2                	ld	s11,8(sp)
    80003eaa:	6165                	addi	sp,sp,112
    80003eac:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003eae:	89da                	mv	s3,s6
    80003eb0:	bff1                	j	80003e8c <readi+0xce>
    return 0;
    80003eb2:	4501                	li	a0,0
}
    80003eb4:	8082                	ret

0000000080003eb6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003eb6:	457c                	lw	a5,76(a0)
    80003eb8:	10d7e863          	bltu	a5,a3,80003fc8 <writei+0x112>
{
    80003ebc:	7159                	addi	sp,sp,-112
    80003ebe:	f486                	sd	ra,104(sp)
    80003ec0:	f0a2                	sd	s0,96(sp)
    80003ec2:	eca6                	sd	s1,88(sp)
    80003ec4:	e8ca                	sd	s2,80(sp)
    80003ec6:	e4ce                	sd	s3,72(sp)
    80003ec8:	e0d2                	sd	s4,64(sp)
    80003eca:	fc56                	sd	s5,56(sp)
    80003ecc:	f85a                	sd	s6,48(sp)
    80003ece:	f45e                	sd	s7,40(sp)
    80003ed0:	f062                	sd	s8,32(sp)
    80003ed2:	ec66                	sd	s9,24(sp)
    80003ed4:	e86a                	sd	s10,16(sp)
    80003ed6:	e46e                	sd	s11,8(sp)
    80003ed8:	1880                	addi	s0,sp,112
    80003eda:	8b2a                	mv	s6,a0
    80003edc:	8c2e                	mv	s8,a1
    80003ede:	8ab2                	mv	s5,a2
    80003ee0:	8936                	mv	s2,a3
    80003ee2:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003ee4:	00e687bb          	addw	a5,a3,a4
    80003ee8:	0ed7e263          	bltu	a5,a3,80003fcc <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003eec:	00043737          	lui	a4,0x43
    80003ef0:	0ef76063          	bltu	a4,a5,80003fd0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ef4:	0c0b8863          	beqz	s7,80003fc4 <writei+0x10e>
    80003ef8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003efa:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003efe:	5cfd                	li	s9,-1
    80003f00:	a091                	j	80003f44 <writei+0x8e>
    80003f02:	02099d93          	slli	s11,s3,0x20
    80003f06:	020ddd93          	srli	s11,s11,0x20
    80003f0a:	05848513          	addi	a0,s1,88
    80003f0e:	86ee                	mv	a3,s11
    80003f10:	8656                	mv	a2,s5
    80003f12:	85e2                	mv	a1,s8
    80003f14:	953a                	add	a0,a0,a4
    80003f16:	ffffe097          	auipc	ra,0xffffe
    80003f1a:	754080e7          	jalr	1876(ra) # 8000266a <either_copyin>
    80003f1e:	07950263          	beq	a0,s9,80003f82 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f22:	8526                	mv	a0,s1
    80003f24:	00000097          	auipc	ra,0x0
    80003f28:	790080e7          	jalr	1936(ra) # 800046b4 <log_write>
    brelse(bp);
    80003f2c:	8526                	mv	a0,s1
    80003f2e:	fffff097          	auipc	ra,0xfffff
    80003f32:	50a080e7          	jalr	1290(ra) # 80003438 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f36:	01498a3b          	addw	s4,s3,s4
    80003f3a:	0129893b          	addw	s2,s3,s2
    80003f3e:	9aee                	add	s5,s5,s11
    80003f40:	057a7663          	bgeu	s4,s7,80003f8c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f44:	000b2483          	lw	s1,0(s6)
    80003f48:	00a9559b          	srliw	a1,s2,0xa
    80003f4c:	855a                	mv	a0,s6
    80003f4e:	fffff097          	auipc	ra,0xfffff
    80003f52:	7ae080e7          	jalr	1966(ra) # 800036fc <bmap>
    80003f56:	0005059b          	sext.w	a1,a0
    80003f5a:	8526                	mv	a0,s1
    80003f5c:	fffff097          	auipc	ra,0xfffff
    80003f60:	3ac080e7          	jalr	940(ra) # 80003308 <bread>
    80003f64:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f66:	3ff97713          	andi	a4,s2,1023
    80003f6a:	40ed07bb          	subw	a5,s10,a4
    80003f6e:	414b86bb          	subw	a3,s7,s4
    80003f72:	89be                	mv	s3,a5
    80003f74:	2781                	sext.w	a5,a5
    80003f76:	0006861b          	sext.w	a2,a3
    80003f7a:	f8f674e3          	bgeu	a2,a5,80003f02 <writei+0x4c>
    80003f7e:	89b6                	mv	s3,a3
    80003f80:	b749                	j	80003f02 <writei+0x4c>
      brelse(bp);
    80003f82:	8526                	mv	a0,s1
    80003f84:	fffff097          	auipc	ra,0xfffff
    80003f88:	4b4080e7          	jalr	1204(ra) # 80003438 <brelse>
  }

  if(off > ip->size)
    80003f8c:	04cb2783          	lw	a5,76(s6)
    80003f90:	0127f463          	bgeu	a5,s2,80003f98 <writei+0xe2>
    ip->size = off;
    80003f94:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f98:	855a                	mv	a0,s6
    80003f9a:	00000097          	auipc	ra,0x0
    80003f9e:	aa6080e7          	jalr	-1370(ra) # 80003a40 <iupdate>

  return tot;
    80003fa2:	000a051b          	sext.w	a0,s4
}
    80003fa6:	70a6                	ld	ra,104(sp)
    80003fa8:	7406                	ld	s0,96(sp)
    80003faa:	64e6                	ld	s1,88(sp)
    80003fac:	6946                	ld	s2,80(sp)
    80003fae:	69a6                	ld	s3,72(sp)
    80003fb0:	6a06                	ld	s4,64(sp)
    80003fb2:	7ae2                	ld	s5,56(sp)
    80003fb4:	7b42                	ld	s6,48(sp)
    80003fb6:	7ba2                	ld	s7,40(sp)
    80003fb8:	7c02                	ld	s8,32(sp)
    80003fba:	6ce2                	ld	s9,24(sp)
    80003fbc:	6d42                	ld	s10,16(sp)
    80003fbe:	6da2                	ld	s11,8(sp)
    80003fc0:	6165                	addi	sp,sp,112
    80003fc2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fc4:	8a5e                	mv	s4,s7
    80003fc6:	bfc9                	j	80003f98 <writei+0xe2>
    return -1;
    80003fc8:	557d                	li	a0,-1
}
    80003fca:	8082                	ret
    return -1;
    80003fcc:	557d                	li	a0,-1
    80003fce:	bfe1                	j	80003fa6 <writei+0xf0>
    return -1;
    80003fd0:	557d                	li	a0,-1
    80003fd2:	bfd1                	j	80003fa6 <writei+0xf0>

0000000080003fd4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fd4:	1141                	addi	sp,sp,-16
    80003fd6:	e406                	sd	ra,8(sp)
    80003fd8:	e022                	sd	s0,0(sp)
    80003fda:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fdc:	4639                	li	a2,14
    80003fde:	ffffd097          	auipc	ra,0xffffd
    80003fe2:	dda080e7          	jalr	-550(ra) # 80000db8 <strncmp>
}
    80003fe6:	60a2                	ld	ra,8(sp)
    80003fe8:	6402                	ld	s0,0(sp)
    80003fea:	0141                	addi	sp,sp,16
    80003fec:	8082                	ret

0000000080003fee <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fee:	7139                	addi	sp,sp,-64
    80003ff0:	fc06                	sd	ra,56(sp)
    80003ff2:	f822                	sd	s0,48(sp)
    80003ff4:	f426                	sd	s1,40(sp)
    80003ff6:	f04a                	sd	s2,32(sp)
    80003ff8:	ec4e                	sd	s3,24(sp)
    80003ffa:	e852                	sd	s4,16(sp)
    80003ffc:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ffe:	04451703          	lh	a4,68(a0)
    80004002:	4785                	li	a5,1
    80004004:	00f71a63          	bne	a4,a5,80004018 <dirlookup+0x2a>
    80004008:	892a                	mv	s2,a0
    8000400a:	89ae                	mv	s3,a1
    8000400c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000400e:	457c                	lw	a5,76(a0)
    80004010:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004012:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004014:	e79d                	bnez	a5,80004042 <dirlookup+0x54>
    80004016:	a8a5                	j	8000408e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004018:	00004517          	auipc	a0,0x4
    8000401c:	7f050513          	addi	a0,a0,2032 # 80008808 <syscall_arg+0x150>
    80004020:	ffffc097          	auipc	ra,0xffffc
    80004024:	51e080e7          	jalr	1310(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004028:	00004517          	auipc	a0,0x4
    8000402c:	7f850513          	addi	a0,a0,2040 # 80008820 <syscall_arg+0x168>
    80004030:	ffffc097          	auipc	ra,0xffffc
    80004034:	50e080e7          	jalr	1294(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004038:	24c1                	addiw	s1,s1,16
    8000403a:	04c92783          	lw	a5,76(s2)
    8000403e:	04f4f763          	bgeu	s1,a5,8000408c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004042:	4741                	li	a4,16
    80004044:	86a6                	mv	a3,s1
    80004046:	fc040613          	addi	a2,s0,-64
    8000404a:	4581                	li	a1,0
    8000404c:	854a                	mv	a0,s2
    8000404e:	00000097          	auipc	ra,0x0
    80004052:	d70080e7          	jalr	-656(ra) # 80003dbe <readi>
    80004056:	47c1                	li	a5,16
    80004058:	fcf518e3          	bne	a0,a5,80004028 <dirlookup+0x3a>
    if(de.inum == 0)
    8000405c:	fc045783          	lhu	a5,-64(s0)
    80004060:	dfe1                	beqz	a5,80004038 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004062:	fc240593          	addi	a1,s0,-62
    80004066:	854e                	mv	a0,s3
    80004068:	00000097          	auipc	ra,0x0
    8000406c:	f6c080e7          	jalr	-148(ra) # 80003fd4 <namecmp>
    80004070:	f561                	bnez	a0,80004038 <dirlookup+0x4a>
      if(poff)
    80004072:	000a0463          	beqz	s4,8000407a <dirlookup+0x8c>
        *poff = off;
    80004076:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000407a:	fc045583          	lhu	a1,-64(s0)
    8000407e:	00092503          	lw	a0,0(s2)
    80004082:	fffff097          	auipc	ra,0xfffff
    80004086:	754080e7          	jalr	1876(ra) # 800037d6 <iget>
    8000408a:	a011                	j	8000408e <dirlookup+0xa0>
  return 0;
    8000408c:	4501                	li	a0,0
}
    8000408e:	70e2                	ld	ra,56(sp)
    80004090:	7442                	ld	s0,48(sp)
    80004092:	74a2                	ld	s1,40(sp)
    80004094:	7902                	ld	s2,32(sp)
    80004096:	69e2                	ld	s3,24(sp)
    80004098:	6a42                	ld	s4,16(sp)
    8000409a:	6121                	addi	sp,sp,64
    8000409c:	8082                	ret

000000008000409e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000409e:	711d                	addi	sp,sp,-96
    800040a0:	ec86                	sd	ra,88(sp)
    800040a2:	e8a2                	sd	s0,80(sp)
    800040a4:	e4a6                	sd	s1,72(sp)
    800040a6:	e0ca                	sd	s2,64(sp)
    800040a8:	fc4e                	sd	s3,56(sp)
    800040aa:	f852                	sd	s4,48(sp)
    800040ac:	f456                	sd	s5,40(sp)
    800040ae:	f05a                	sd	s6,32(sp)
    800040b0:	ec5e                	sd	s7,24(sp)
    800040b2:	e862                	sd	s8,16(sp)
    800040b4:	e466                	sd	s9,8(sp)
    800040b6:	1080                	addi	s0,sp,96
    800040b8:	84aa                	mv	s1,a0
    800040ba:	8b2e                	mv	s6,a1
    800040bc:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040be:	00054703          	lbu	a4,0(a0)
    800040c2:	02f00793          	li	a5,47
    800040c6:	02f70363          	beq	a4,a5,800040ec <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800040ca:	ffffe097          	auipc	ra,0xffffe
    800040ce:	8e6080e7          	jalr	-1818(ra) # 800019b0 <myproc>
    800040d2:	17053503          	ld	a0,368(a0)
    800040d6:	00000097          	auipc	ra,0x0
    800040da:	9f6080e7          	jalr	-1546(ra) # 80003acc <idup>
    800040de:	89aa                	mv	s3,a0
  while(*path == '/')
    800040e0:	02f00913          	li	s2,47
  len = path - s;
    800040e4:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800040e6:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040e8:	4c05                	li	s8,1
    800040ea:	a865                	j	800041a2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800040ec:	4585                	li	a1,1
    800040ee:	4505                	li	a0,1
    800040f0:	fffff097          	auipc	ra,0xfffff
    800040f4:	6e6080e7          	jalr	1766(ra) # 800037d6 <iget>
    800040f8:	89aa                	mv	s3,a0
    800040fa:	b7dd                	j	800040e0 <namex+0x42>
      iunlockput(ip);
    800040fc:	854e                	mv	a0,s3
    800040fe:	00000097          	auipc	ra,0x0
    80004102:	c6e080e7          	jalr	-914(ra) # 80003d6c <iunlockput>
      return 0;
    80004106:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004108:	854e                	mv	a0,s3
    8000410a:	60e6                	ld	ra,88(sp)
    8000410c:	6446                	ld	s0,80(sp)
    8000410e:	64a6                	ld	s1,72(sp)
    80004110:	6906                	ld	s2,64(sp)
    80004112:	79e2                	ld	s3,56(sp)
    80004114:	7a42                	ld	s4,48(sp)
    80004116:	7aa2                	ld	s5,40(sp)
    80004118:	7b02                	ld	s6,32(sp)
    8000411a:	6be2                	ld	s7,24(sp)
    8000411c:	6c42                	ld	s8,16(sp)
    8000411e:	6ca2                	ld	s9,8(sp)
    80004120:	6125                	addi	sp,sp,96
    80004122:	8082                	ret
      iunlock(ip);
    80004124:	854e                	mv	a0,s3
    80004126:	00000097          	auipc	ra,0x0
    8000412a:	aa6080e7          	jalr	-1370(ra) # 80003bcc <iunlock>
      return ip;
    8000412e:	bfe9                	j	80004108 <namex+0x6a>
      iunlockput(ip);
    80004130:	854e                	mv	a0,s3
    80004132:	00000097          	auipc	ra,0x0
    80004136:	c3a080e7          	jalr	-966(ra) # 80003d6c <iunlockput>
      return 0;
    8000413a:	89d2                	mv	s3,s4
    8000413c:	b7f1                	j	80004108 <namex+0x6a>
  len = path - s;
    8000413e:	40b48633          	sub	a2,s1,a1
    80004142:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004146:	094cd463          	bge	s9,s4,800041ce <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000414a:	4639                	li	a2,14
    8000414c:	8556                	mv	a0,s5
    8000414e:	ffffd097          	auipc	ra,0xffffd
    80004152:	bf2080e7          	jalr	-1038(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004156:	0004c783          	lbu	a5,0(s1)
    8000415a:	01279763          	bne	a5,s2,80004168 <namex+0xca>
    path++;
    8000415e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004160:	0004c783          	lbu	a5,0(s1)
    80004164:	ff278de3          	beq	a5,s2,8000415e <namex+0xc0>
    ilock(ip);
    80004168:	854e                	mv	a0,s3
    8000416a:	00000097          	auipc	ra,0x0
    8000416e:	9a0080e7          	jalr	-1632(ra) # 80003b0a <ilock>
    if(ip->type != T_DIR){
    80004172:	04499783          	lh	a5,68(s3)
    80004176:	f98793e3          	bne	a5,s8,800040fc <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000417a:	000b0563          	beqz	s6,80004184 <namex+0xe6>
    8000417e:	0004c783          	lbu	a5,0(s1)
    80004182:	d3cd                	beqz	a5,80004124 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004184:	865e                	mv	a2,s7
    80004186:	85d6                	mv	a1,s5
    80004188:	854e                	mv	a0,s3
    8000418a:	00000097          	auipc	ra,0x0
    8000418e:	e64080e7          	jalr	-412(ra) # 80003fee <dirlookup>
    80004192:	8a2a                	mv	s4,a0
    80004194:	dd51                	beqz	a0,80004130 <namex+0x92>
    iunlockput(ip);
    80004196:	854e                	mv	a0,s3
    80004198:	00000097          	auipc	ra,0x0
    8000419c:	bd4080e7          	jalr	-1068(ra) # 80003d6c <iunlockput>
    ip = next;
    800041a0:	89d2                	mv	s3,s4
  while(*path == '/')
    800041a2:	0004c783          	lbu	a5,0(s1)
    800041a6:	05279763          	bne	a5,s2,800041f4 <namex+0x156>
    path++;
    800041aa:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041ac:	0004c783          	lbu	a5,0(s1)
    800041b0:	ff278de3          	beq	a5,s2,800041aa <namex+0x10c>
  if(*path == 0)
    800041b4:	c79d                	beqz	a5,800041e2 <namex+0x144>
    path++;
    800041b6:	85a6                	mv	a1,s1
  len = path - s;
    800041b8:	8a5e                	mv	s4,s7
    800041ba:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800041bc:	01278963          	beq	a5,s2,800041ce <namex+0x130>
    800041c0:	dfbd                	beqz	a5,8000413e <namex+0xa0>
    path++;
    800041c2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800041c4:	0004c783          	lbu	a5,0(s1)
    800041c8:	ff279ce3          	bne	a5,s2,800041c0 <namex+0x122>
    800041cc:	bf8d                	j	8000413e <namex+0xa0>
    memmove(name, s, len);
    800041ce:	2601                	sext.w	a2,a2
    800041d0:	8556                	mv	a0,s5
    800041d2:	ffffd097          	auipc	ra,0xffffd
    800041d6:	b6e080e7          	jalr	-1170(ra) # 80000d40 <memmove>
    name[len] = 0;
    800041da:	9a56                	add	s4,s4,s5
    800041dc:	000a0023          	sb	zero,0(s4)
    800041e0:	bf9d                	j	80004156 <namex+0xb8>
  if(nameiparent){
    800041e2:	f20b03e3          	beqz	s6,80004108 <namex+0x6a>
    iput(ip);
    800041e6:	854e                	mv	a0,s3
    800041e8:	00000097          	auipc	ra,0x0
    800041ec:	adc080e7          	jalr	-1316(ra) # 80003cc4 <iput>
    return 0;
    800041f0:	4981                	li	s3,0
    800041f2:	bf19                	j	80004108 <namex+0x6a>
  if(*path == 0)
    800041f4:	d7fd                	beqz	a5,800041e2 <namex+0x144>
  while(*path != '/' && *path != 0)
    800041f6:	0004c783          	lbu	a5,0(s1)
    800041fa:	85a6                	mv	a1,s1
    800041fc:	b7d1                	j	800041c0 <namex+0x122>

00000000800041fe <dirlink>:
{
    800041fe:	7139                	addi	sp,sp,-64
    80004200:	fc06                	sd	ra,56(sp)
    80004202:	f822                	sd	s0,48(sp)
    80004204:	f426                	sd	s1,40(sp)
    80004206:	f04a                	sd	s2,32(sp)
    80004208:	ec4e                	sd	s3,24(sp)
    8000420a:	e852                	sd	s4,16(sp)
    8000420c:	0080                	addi	s0,sp,64
    8000420e:	892a                	mv	s2,a0
    80004210:	8a2e                	mv	s4,a1
    80004212:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004214:	4601                	li	a2,0
    80004216:	00000097          	auipc	ra,0x0
    8000421a:	dd8080e7          	jalr	-552(ra) # 80003fee <dirlookup>
    8000421e:	e93d                	bnez	a0,80004294 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004220:	04c92483          	lw	s1,76(s2)
    80004224:	c49d                	beqz	s1,80004252 <dirlink+0x54>
    80004226:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004228:	4741                	li	a4,16
    8000422a:	86a6                	mv	a3,s1
    8000422c:	fc040613          	addi	a2,s0,-64
    80004230:	4581                	li	a1,0
    80004232:	854a                	mv	a0,s2
    80004234:	00000097          	auipc	ra,0x0
    80004238:	b8a080e7          	jalr	-1142(ra) # 80003dbe <readi>
    8000423c:	47c1                	li	a5,16
    8000423e:	06f51163          	bne	a0,a5,800042a0 <dirlink+0xa2>
    if(de.inum == 0)
    80004242:	fc045783          	lhu	a5,-64(s0)
    80004246:	c791                	beqz	a5,80004252 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004248:	24c1                	addiw	s1,s1,16
    8000424a:	04c92783          	lw	a5,76(s2)
    8000424e:	fcf4ede3          	bltu	s1,a5,80004228 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004252:	4639                	li	a2,14
    80004254:	85d2                	mv	a1,s4
    80004256:	fc240513          	addi	a0,s0,-62
    8000425a:	ffffd097          	auipc	ra,0xffffd
    8000425e:	b9a080e7          	jalr	-1126(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004262:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004266:	4741                	li	a4,16
    80004268:	86a6                	mv	a3,s1
    8000426a:	fc040613          	addi	a2,s0,-64
    8000426e:	4581                	li	a1,0
    80004270:	854a                	mv	a0,s2
    80004272:	00000097          	auipc	ra,0x0
    80004276:	c44080e7          	jalr	-956(ra) # 80003eb6 <writei>
    8000427a:	872a                	mv	a4,a0
    8000427c:	47c1                	li	a5,16
  return 0;
    8000427e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004280:	02f71863          	bne	a4,a5,800042b0 <dirlink+0xb2>
}
    80004284:	70e2                	ld	ra,56(sp)
    80004286:	7442                	ld	s0,48(sp)
    80004288:	74a2                	ld	s1,40(sp)
    8000428a:	7902                	ld	s2,32(sp)
    8000428c:	69e2                	ld	s3,24(sp)
    8000428e:	6a42                	ld	s4,16(sp)
    80004290:	6121                	addi	sp,sp,64
    80004292:	8082                	ret
    iput(ip);
    80004294:	00000097          	auipc	ra,0x0
    80004298:	a30080e7          	jalr	-1488(ra) # 80003cc4 <iput>
    return -1;
    8000429c:	557d                	li	a0,-1
    8000429e:	b7dd                	j	80004284 <dirlink+0x86>
      panic("dirlink read");
    800042a0:	00004517          	auipc	a0,0x4
    800042a4:	59050513          	addi	a0,a0,1424 # 80008830 <syscall_arg+0x178>
    800042a8:	ffffc097          	auipc	ra,0xffffc
    800042ac:	296080e7          	jalr	662(ra) # 8000053e <panic>
    panic("dirlink");
    800042b0:	00004517          	auipc	a0,0x4
    800042b4:	68850513          	addi	a0,a0,1672 # 80008938 <syscall_arg+0x280>
    800042b8:	ffffc097          	auipc	ra,0xffffc
    800042bc:	286080e7          	jalr	646(ra) # 8000053e <panic>

00000000800042c0 <namei>:

struct inode*
namei(char *path)
{
    800042c0:	1101                	addi	sp,sp,-32
    800042c2:	ec06                	sd	ra,24(sp)
    800042c4:	e822                	sd	s0,16(sp)
    800042c6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042c8:	fe040613          	addi	a2,s0,-32
    800042cc:	4581                	li	a1,0
    800042ce:	00000097          	auipc	ra,0x0
    800042d2:	dd0080e7          	jalr	-560(ra) # 8000409e <namex>
}
    800042d6:	60e2                	ld	ra,24(sp)
    800042d8:	6442                	ld	s0,16(sp)
    800042da:	6105                	addi	sp,sp,32
    800042dc:	8082                	ret

00000000800042de <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042de:	1141                	addi	sp,sp,-16
    800042e0:	e406                	sd	ra,8(sp)
    800042e2:	e022                	sd	s0,0(sp)
    800042e4:	0800                	addi	s0,sp,16
    800042e6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042e8:	4585                	li	a1,1
    800042ea:	00000097          	auipc	ra,0x0
    800042ee:	db4080e7          	jalr	-588(ra) # 8000409e <namex>
}
    800042f2:	60a2                	ld	ra,8(sp)
    800042f4:	6402                	ld	s0,0(sp)
    800042f6:	0141                	addi	sp,sp,16
    800042f8:	8082                	ret

00000000800042fa <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042fa:	1101                	addi	sp,sp,-32
    800042fc:	ec06                	sd	ra,24(sp)
    800042fe:	e822                	sd	s0,16(sp)
    80004300:	e426                	sd	s1,8(sp)
    80004302:	e04a                	sd	s2,0(sp)
    80004304:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004306:	0001d917          	auipc	s2,0x1d
    8000430a:	76a90913          	addi	s2,s2,1898 # 80021a70 <log>
    8000430e:	01892583          	lw	a1,24(s2)
    80004312:	02892503          	lw	a0,40(s2)
    80004316:	fffff097          	auipc	ra,0xfffff
    8000431a:	ff2080e7          	jalr	-14(ra) # 80003308 <bread>
    8000431e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004320:	02c92683          	lw	a3,44(s2)
    80004324:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004326:	02d05763          	blez	a3,80004354 <write_head+0x5a>
    8000432a:	0001d797          	auipc	a5,0x1d
    8000432e:	77678793          	addi	a5,a5,1910 # 80021aa0 <log+0x30>
    80004332:	05c50713          	addi	a4,a0,92
    80004336:	36fd                	addiw	a3,a3,-1
    80004338:	1682                	slli	a3,a3,0x20
    8000433a:	9281                	srli	a3,a3,0x20
    8000433c:	068a                	slli	a3,a3,0x2
    8000433e:	0001d617          	auipc	a2,0x1d
    80004342:	76660613          	addi	a2,a2,1894 # 80021aa4 <log+0x34>
    80004346:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004348:	4390                	lw	a2,0(a5)
    8000434a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000434c:	0791                	addi	a5,a5,4
    8000434e:	0711                	addi	a4,a4,4
    80004350:	fed79ce3          	bne	a5,a3,80004348 <write_head+0x4e>
  }
  bwrite(buf);
    80004354:	8526                	mv	a0,s1
    80004356:	fffff097          	auipc	ra,0xfffff
    8000435a:	0a4080e7          	jalr	164(ra) # 800033fa <bwrite>
  brelse(buf);
    8000435e:	8526                	mv	a0,s1
    80004360:	fffff097          	auipc	ra,0xfffff
    80004364:	0d8080e7          	jalr	216(ra) # 80003438 <brelse>
}
    80004368:	60e2                	ld	ra,24(sp)
    8000436a:	6442                	ld	s0,16(sp)
    8000436c:	64a2                	ld	s1,8(sp)
    8000436e:	6902                	ld	s2,0(sp)
    80004370:	6105                	addi	sp,sp,32
    80004372:	8082                	ret

0000000080004374 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004374:	0001d797          	auipc	a5,0x1d
    80004378:	7287a783          	lw	a5,1832(a5) # 80021a9c <log+0x2c>
    8000437c:	0af05d63          	blez	a5,80004436 <install_trans+0xc2>
{
    80004380:	7139                	addi	sp,sp,-64
    80004382:	fc06                	sd	ra,56(sp)
    80004384:	f822                	sd	s0,48(sp)
    80004386:	f426                	sd	s1,40(sp)
    80004388:	f04a                	sd	s2,32(sp)
    8000438a:	ec4e                	sd	s3,24(sp)
    8000438c:	e852                	sd	s4,16(sp)
    8000438e:	e456                	sd	s5,8(sp)
    80004390:	e05a                	sd	s6,0(sp)
    80004392:	0080                	addi	s0,sp,64
    80004394:	8b2a                	mv	s6,a0
    80004396:	0001da97          	auipc	s5,0x1d
    8000439a:	70aa8a93          	addi	s5,s5,1802 # 80021aa0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000439e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043a0:	0001d997          	auipc	s3,0x1d
    800043a4:	6d098993          	addi	s3,s3,1744 # 80021a70 <log>
    800043a8:	a035                	j	800043d4 <install_trans+0x60>
      bunpin(dbuf);
    800043aa:	8526                	mv	a0,s1
    800043ac:	fffff097          	auipc	ra,0xfffff
    800043b0:	166080e7          	jalr	358(ra) # 80003512 <bunpin>
    brelse(lbuf);
    800043b4:	854a                	mv	a0,s2
    800043b6:	fffff097          	auipc	ra,0xfffff
    800043ba:	082080e7          	jalr	130(ra) # 80003438 <brelse>
    brelse(dbuf);
    800043be:	8526                	mv	a0,s1
    800043c0:	fffff097          	auipc	ra,0xfffff
    800043c4:	078080e7          	jalr	120(ra) # 80003438 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043c8:	2a05                	addiw	s4,s4,1
    800043ca:	0a91                	addi	s5,s5,4
    800043cc:	02c9a783          	lw	a5,44(s3)
    800043d0:	04fa5963          	bge	s4,a5,80004422 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043d4:	0189a583          	lw	a1,24(s3)
    800043d8:	014585bb          	addw	a1,a1,s4
    800043dc:	2585                	addiw	a1,a1,1
    800043de:	0289a503          	lw	a0,40(s3)
    800043e2:	fffff097          	auipc	ra,0xfffff
    800043e6:	f26080e7          	jalr	-218(ra) # 80003308 <bread>
    800043ea:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043ec:	000aa583          	lw	a1,0(s5)
    800043f0:	0289a503          	lw	a0,40(s3)
    800043f4:	fffff097          	auipc	ra,0xfffff
    800043f8:	f14080e7          	jalr	-236(ra) # 80003308 <bread>
    800043fc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800043fe:	40000613          	li	a2,1024
    80004402:	05890593          	addi	a1,s2,88
    80004406:	05850513          	addi	a0,a0,88
    8000440a:	ffffd097          	auipc	ra,0xffffd
    8000440e:	936080e7          	jalr	-1738(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004412:	8526                	mv	a0,s1
    80004414:	fffff097          	auipc	ra,0xfffff
    80004418:	fe6080e7          	jalr	-26(ra) # 800033fa <bwrite>
    if(recovering == 0)
    8000441c:	f80b1ce3          	bnez	s6,800043b4 <install_trans+0x40>
    80004420:	b769                	j	800043aa <install_trans+0x36>
}
    80004422:	70e2                	ld	ra,56(sp)
    80004424:	7442                	ld	s0,48(sp)
    80004426:	74a2                	ld	s1,40(sp)
    80004428:	7902                	ld	s2,32(sp)
    8000442a:	69e2                	ld	s3,24(sp)
    8000442c:	6a42                	ld	s4,16(sp)
    8000442e:	6aa2                	ld	s5,8(sp)
    80004430:	6b02                	ld	s6,0(sp)
    80004432:	6121                	addi	sp,sp,64
    80004434:	8082                	ret
    80004436:	8082                	ret

0000000080004438 <initlog>:
{
    80004438:	7179                	addi	sp,sp,-48
    8000443a:	f406                	sd	ra,40(sp)
    8000443c:	f022                	sd	s0,32(sp)
    8000443e:	ec26                	sd	s1,24(sp)
    80004440:	e84a                	sd	s2,16(sp)
    80004442:	e44e                	sd	s3,8(sp)
    80004444:	1800                	addi	s0,sp,48
    80004446:	892a                	mv	s2,a0
    80004448:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000444a:	0001d497          	auipc	s1,0x1d
    8000444e:	62648493          	addi	s1,s1,1574 # 80021a70 <log>
    80004452:	00004597          	auipc	a1,0x4
    80004456:	3ee58593          	addi	a1,a1,1006 # 80008840 <syscall_arg+0x188>
    8000445a:	8526                	mv	a0,s1
    8000445c:	ffffc097          	auipc	ra,0xffffc
    80004460:	6f8080e7          	jalr	1784(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004464:	0149a583          	lw	a1,20(s3)
    80004468:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000446a:	0109a783          	lw	a5,16(s3)
    8000446e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004470:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004474:	854a                	mv	a0,s2
    80004476:	fffff097          	auipc	ra,0xfffff
    8000447a:	e92080e7          	jalr	-366(ra) # 80003308 <bread>
  log.lh.n = lh->n;
    8000447e:	4d3c                	lw	a5,88(a0)
    80004480:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004482:	02f05563          	blez	a5,800044ac <initlog+0x74>
    80004486:	05c50713          	addi	a4,a0,92
    8000448a:	0001d697          	auipc	a3,0x1d
    8000448e:	61668693          	addi	a3,a3,1558 # 80021aa0 <log+0x30>
    80004492:	37fd                	addiw	a5,a5,-1
    80004494:	1782                	slli	a5,a5,0x20
    80004496:	9381                	srli	a5,a5,0x20
    80004498:	078a                	slli	a5,a5,0x2
    8000449a:	06050613          	addi	a2,a0,96
    8000449e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800044a0:	4310                	lw	a2,0(a4)
    800044a2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800044a4:	0711                	addi	a4,a4,4
    800044a6:	0691                	addi	a3,a3,4
    800044a8:	fef71ce3          	bne	a4,a5,800044a0 <initlog+0x68>
  brelse(buf);
    800044ac:	fffff097          	auipc	ra,0xfffff
    800044b0:	f8c080e7          	jalr	-116(ra) # 80003438 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800044b4:	4505                	li	a0,1
    800044b6:	00000097          	auipc	ra,0x0
    800044ba:	ebe080e7          	jalr	-322(ra) # 80004374 <install_trans>
  log.lh.n = 0;
    800044be:	0001d797          	auipc	a5,0x1d
    800044c2:	5c07af23          	sw	zero,1502(a5) # 80021a9c <log+0x2c>
  write_head(); // clear the log
    800044c6:	00000097          	auipc	ra,0x0
    800044ca:	e34080e7          	jalr	-460(ra) # 800042fa <write_head>
}
    800044ce:	70a2                	ld	ra,40(sp)
    800044d0:	7402                	ld	s0,32(sp)
    800044d2:	64e2                	ld	s1,24(sp)
    800044d4:	6942                	ld	s2,16(sp)
    800044d6:	69a2                	ld	s3,8(sp)
    800044d8:	6145                	addi	sp,sp,48
    800044da:	8082                	ret

00000000800044dc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044dc:	1101                	addi	sp,sp,-32
    800044de:	ec06                	sd	ra,24(sp)
    800044e0:	e822                	sd	s0,16(sp)
    800044e2:	e426                	sd	s1,8(sp)
    800044e4:	e04a                	sd	s2,0(sp)
    800044e6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044e8:	0001d517          	auipc	a0,0x1d
    800044ec:	58850513          	addi	a0,a0,1416 # 80021a70 <log>
    800044f0:	ffffc097          	auipc	ra,0xffffc
    800044f4:	6f4080e7          	jalr	1780(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800044f8:	0001d497          	auipc	s1,0x1d
    800044fc:	57848493          	addi	s1,s1,1400 # 80021a70 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004500:	4979                	li	s2,30
    80004502:	a039                	j	80004510 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004504:	85a6                	mv	a1,s1
    80004506:	8526                	mv	a0,s1
    80004508:	ffffe097          	auipc	ra,0xffffe
    8000450c:	d22080e7          	jalr	-734(ra) # 8000222a <sleep>
    if(log.committing){
    80004510:	50dc                	lw	a5,36(s1)
    80004512:	fbed                	bnez	a5,80004504 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004514:	509c                	lw	a5,32(s1)
    80004516:	0017871b          	addiw	a4,a5,1
    8000451a:	0007069b          	sext.w	a3,a4
    8000451e:	0027179b          	slliw	a5,a4,0x2
    80004522:	9fb9                	addw	a5,a5,a4
    80004524:	0017979b          	slliw	a5,a5,0x1
    80004528:	54d8                	lw	a4,44(s1)
    8000452a:	9fb9                	addw	a5,a5,a4
    8000452c:	00f95963          	bge	s2,a5,8000453e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004530:	85a6                	mv	a1,s1
    80004532:	8526                	mv	a0,s1
    80004534:	ffffe097          	auipc	ra,0xffffe
    80004538:	cf6080e7          	jalr	-778(ra) # 8000222a <sleep>
    8000453c:	bfd1                	j	80004510 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000453e:	0001d517          	auipc	a0,0x1d
    80004542:	53250513          	addi	a0,a0,1330 # 80021a70 <log>
    80004546:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004548:	ffffc097          	auipc	ra,0xffffc
    8000454c:	750080e7          	jalr	1872(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004550:	60e2                	ld	ra,24(sp)
    80004552:	6442                	ld	s0,16(sp)
    80004554:	64a2                	ld	s1,8(sp)
    80004556:	6902                	ld	s2,0(sp)
    80004558:	6105                	addi	sp,sp,32
    8000455a:	8082                	ret

000000008000455c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000455c:	7139                	addi	sp,sp,-64
    8000455e:	fc06                	sd	ra,56(sp)
    80004560:	f822                	sd	s0,48(sp)
    80004562:	f426                	sd	s1,40(sp)
    80004564:	f04a                	sd	s2,32(sp)
    80004566:	ec4e                	sd	s3,24(sp)
    80004568:	e852                	sd	s4,16(sp)
    8000456a:	e456                	sd	s5,8(sp)
    8000456c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000456e:	0001d497          	auipc	s1,0x1d
    80004572:	50248493          	addi	s1,s1,1282 # 80021a70 <log>
    80004576:	8526                	mv	a0,s1
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	66c080e7          	jalr	1644(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004580:	509c                	lw	a5,32(s1)
    80004582:	37fd                	addiw	a5,a5,-1
    80004584:	0007891b          	sext.w	s2,a5
    80004588:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000458a:	50dc                	lw	a5,36(s1)
    8000458c:	efb9                	bnez	a5,800045ea <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000458e:	06091663          	bnez	s2,800045fa <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004592:	0001d497          	auipc	s1,0x1d
    80004596:	4de48493          	addi	s1,s1,1246 # 80021a70 <log>
    8000459a:	4785                	li	a5,1
    8000459c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000459e:	8526                	mv	a0,s1
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	6f8080e7          	jalr	1784(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800045a8:	54dc                	lw	a5,44(s1)
    800045aa:	06f04763          	bgtz	a5,80004618 <end_op+0xbc>
    acquire(&log.lock);
    800045ae:	0001d497          	auipc	s1,0x1d
    800045b2:	4c248493          	addi	s1,s1,1218 # 80021a70 <log>
    800045b6:	8526                	mv	a0,s1
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	62c080e7          	jalr	1580(ra) # 80000be4 <acquire>
    log.committing = 0;
    800045c0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800045c4:	8526                	mv	a0,s1
    800045c6:	ffffe097          	auipc	ra,0xffffe
    800045ca:	e00080e7          	jalr	-512(ra) # 800023c6 <wakeup>
    release(&log.lock);
    800045ce:	8526                	mv	a0,s1
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	6c8080e7          	jalr	1736(ra) # 80000c98 <release>
}
    800045d8:	70e2                	ld	ra,56(sp)
    800045da:	7442                	ld	s0,48(sp)
    800045dc:	74a2                	ld	s1,40(sp)
    800045de:	7902                	ld	s2,32(sp)
    800045e0:	69e2                	ld	s3,24(sp)
    800045e2:	6a42                	ld	s4,16(sp)
    800045e4:	6aa2                	ld	s5,8(sp)
    800045e6:	6121                	addi	sp,sp,64
    800045e8:	8082                	ret
    panic("log.committing");
    800045ea:	00004517          	auipc	a0,0x4
    800045ee:	25e50513          	addi	a0,a0,606 # 80008848 <syscall_arg+0x190>
    800045f2:	ffffc097          	auipc	ra,0xffffc
    800045f6:	f4c080e7          	jalr	-180(ra) # 8000053e <panic>
    wakeup(&log);
    800045fa:	0001d497          	auipc	s1,0x1d
    800045fe:	47648493          	addi	s1,s1,1142 # 80021a70 <log>
    80004602:	8526                	mv	a0,s1
    80004604:	ffffe097          	auipc	ra,0xffffe
    80004608:	dc2080e7          	jalr	-574(ra) # 800023c6 <wakeup>
  release(&log.lock);
    8000460c:	8526                	mv	a0,s1
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	68a080e7          	jalr	1674(ra) # 80000c98 <release>
  if(do_commit){
    80004616:	b7c9                	j	800045d8 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004618:	0001da97          	auipc	s5,0x1d
    8000461c:	488a8a93          	addi	s5,s5,1160 # 80021aa0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004620:	0001da17          	auipc	s4,0x1d
    80004624:	450a0a13          	addi	s4,s4,1104 # 80021a70 <log>
    80004628:	018a2583          	lw	a1,24(s4)
    8000462c:	012585bb          	addw	a1,a1,s2
    80004630:	2585                	addiw	a1,a1,1
    80004632:	028a2503          	lw	a0,40(s4)
    80004636:	fffff097          	auipc	ra,0xfffff
    8000463a:	cd2080e7          	jalr	-814(ra) # 80003308 <bread>
    8000463e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004640:	000aa583          	lw	a1,0(s5)
    80004644:	028a2503          	lw	a0,40(s4)
    80004648:	fffff097          	auipc	ra,0xfffff
    8000464c:	cc0080e7          	jalr	-832(ra) # 80003308 <bread>
    80004650:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004652:	40000613          	li	a2,1024
    80004656:	05850593          	addi	a1,a0,88
    8000465a:	05848513          	addi	a0,s1,88
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	6e2080e7          	jalr	1762(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004666:	8526                	mv	a0,s1
    80004668:	fffff097          	auipc	ra,0xfffff
    8000466c:	d92080e7          	jalr	-622(ra) # 800033fa <bwrite>
    brelse(from);
    80004670:	854e                	mv	a0,s3
    80004672:	fffff097          	auipc	ra,0xfffff
    80004676:	dc6080e7          	jalr	-570(ra) # 80003438 <brelse>
    brelse(to);
    8000467a:	8526                	mv	a0,s1
    8000467c:	fffff097          	auipc	ra,0xfffff
    80004680:	dbc080e7          	jalr	-580(ra) # 80003438 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004684:	2905                	addiw	s2,s2,1
    80004686:	0a91                	addi	s5,s5,4
    80004688:	02ca2783          	lw	a5,44(s4)
    8000468c:	f8f94ee3          	blt	s2,a5,80004628 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004690:	00000097          	auipc	ra,0x0
    80004694:	c6a080e7          	jalr	-918(ra) # 800042fa <write_head>
    install_trans(0); // Now install writes to home locations
    80004698:	4501                	li	a0,0
    8000469a:	00000097          	auipc	ra,0x0
    8000469e:	cda080e7          	jalr	-806(ra) # 80004374 <install_trans>
    log.lh.n = 0;
    800046a2:	0001d797          	auipc	a5,0x1d
    800046a6:	3e07ad23          	sw	zero,1018(a5) # 80021a9c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800046aa:	00000097          	auipc	ra,0x0
    800046ae:	c50080e7          	jalr	-944(ra) # 800042fa <write_head>
    800046b2:	bdf5                	j	800045ae <end_op+0x52>

00000000800046b4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800046b4:	1101                	addi	sp,sp,-32
    800046b6:	ec06                	sd	ra,24(sp)
    800046b8:	e822                	sd	s0,16(sp)
    800046ba:	e426                	sd	s1,8(sp)
    800046bc:	e04a                	sd	s2,0(sp)
    800046be:	1000                	addi	s0,sp,32
    800046c0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800046c2:	0001d917          	auipc	s2,0x1d
    800046c6:	3ae90913          	addi	s2,s2,942 # 80021a70 <log>
    800046ca:	854a                	mv	a0,s2
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	518080e7          	jalr	1304(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800046d4:	02c92603          	lw	a2,44(s2)
    800046d8:	47f5                	li	a5,29
    800046da:	06c7c563          	blt	a5,a2,80004744 <log_write+0x90>
    800046de:	0001d797          	auipc	a5,0x1d
    800046e2:	3ae7a783          	lw	a5,942(a5) # 80021a8c <log+0x1c>
    800046e6:	37fd                	addiw	a5,a5,-1
    800046e8:	04f65e63          	bge	a2,a5,80004744 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046ec:	0001d797          	auipc	a5,0x1d
    800046f0:	3a47a783          	lw	a5,932(a5) # 80021a90 <log+0x20>
    800046f4:	06f05063          	blez	a5,80004754 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046f8:	4781                	li	a5,0
    800046fa:	06c05563          	blez	a2,80004764 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046fe:	44cc                	lw	a1,12(s1)
    80004700:	0001d717          	auipc	a4,0x1d
    80004704:	3a070713          	addi	a4,a4,928 # 80021aa0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004708:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000470a:	4314                	lw	a3,0(a4)
    8000470c:	04b68c63          	beq	a3,a1,80004764 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004710:	2785                	addiw	a5,a5,1
    80004712:	0711                	addi	a4,a4,4
    80004714:	fef61be3          	bne	a2,a5,8000470a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004718:	0621                	addi	a2,a2,8
    8000471a:	060a                	slli	a2,a2,0x2
    8000471c:	0001d797          	auipc	a5,0x1d
    80004720:	35478793          	addi	a5,a5,852 # 80021a70 <log>
    80004724:	963e                	add	a2,a2,a5
    80004726:	44dc                	lw	a5,12(s1)
    80004728:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000472a:	8526                	mv	a0,s1
    8000472c:	fffff097          	auipc	ra,0xfffff
    80004730:	daa080e7          	jalr	-598(ra) # 800034d6 <bpin>
    log.lh.n++;
    80004734:	0001d717          	auipc	a4,0x1d
    80004738:	33c70713          	addi	a4,a4,828 # 80021a70 <log>
    8000473c:	575c                	lw	a5,44(a4)
    8000473e:	2785                	addiw	a5,a5,1
    80004740:	d75c                	sw	a5,44(a4)
    80004742:	a835                	j	8000477e <log_write+0xca>
    panic("too big a transaction");
    80004744:	00004517          	auipc	a0,0x4
    80004748:	11450513          	addi	a0,a0,276 # 80008858 <syscall_arg+0x1a0>
    8000474c:	ffffc097          	auipc	ra,0xffffc
    80004750:	df2080e7          	jalr	-526(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004754:	00004517          	auipc	a0,0x4
    80004758:	11c50513          	addi	a0,a0,284 # 80008870 <syscall_arg+0x1b8>
    8000475c:	ffffc097          	auipc	ra,0xffffc
    80004760:	de2080e7          	jalr	-542(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004764:	00878713          	addi	a4,a5,8
    80004768:	00271693          	slli	a3,a4,0x2
    8000476c:	0001d717          	auipc	a4,0x1d
    80004770:	30470713          	addi	a4,a4,772 # 80021a70 <log>
    80004774:	9736                	add	a4,a4,a3
    80004776:	44d4                	lw	a3,12(s1)
    80004778:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000477a:	faf608e3          	beq	a2,a5,8000472a <log_write+0x76>
  }
  release(&log.lock);
    8000477e:	0001d517          	auipc	a0,0x1d
    80004782:	2f250513          	addi	a0,a0,754 # 80021a70 <log>
    80004786:	ffffc097          	auipc	ra,0xffffc
    8000478a:	512080e7          	jalr	1298(ra) # 80000c98 <release>
}
    8000478e:	60e2                	ld	ra,24(sp)
    80004790:	6442                	ld	s0,16(sp)
    80004792:	64a2                	ld	s1,8(sp)
    80004794:	6902                	ld	s2,0(sp)
    80004796:	6105                	addi	sp,sp,32
    80004798:	8082                	ret

000000008000479a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000479a:	1101                	addi	sp,sp,-32
    8000479c:	ec06                	sd	ra,24(sp)
    8000479e:	e822                	sd	s0,16(sp)
    800047a0:	e426                	sd	s1,8(sp)
    800047a2:	e04a                	sd	s2,0(sp)
    800047a4:	1000                	addi	s0,sp,32
    800047a6:	84aa                	mv	s1,a0
    800047a8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800047aa:	00004597          	auipc	a1,0x4
    800047ae:	0e658593          	addi	a1,a1,230 # 80008890 <syscall_arg+0x1d8>
    800047b2:	0521                	addi	a0,a0,8
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	3a0080e7          	jalr	928(ra) # 80000b54 <initlock>
  lk->name = name;
    800047bc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800047c0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047c4:	0204a423          	sw	zero,40(s1)
}
    800047c8:	60e2                	ld	ra,24(sp)
    800047ca:	6442                	ld	s0,16(sp)
    800047cc:	64a2                	ld	s1,8(sp)
    800047ce:	6902                	ld	s2,0(sp)
    800047d0:	6105                	addi	sp,sp,32
    800047d2:	8082                	ret

00000000800047d4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800047d4:	1101                	addi	sp,sp,-32
    800047d6:	ec06                	sd	ra,24(sp)
    800047d8:	e822                	sd	s0,16(sp)
    800047da:	e426                	sd	s1,8(sp)
    800047dc:	e04a                	sd	s2,0(sp)
    800047de:	1000                	addi	s0,sp,32
    800047e0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047e2:	00850913          	addi	s2,a0,8
    800047e6:	854a                	mv	a0,s2
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	3fc080e7          	jalr	1020(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800047f0:	409c                	lw	a5,0(s1)
    800047f2:	cb89                	beqz	a5,80004804 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047f4:	85ca                	mv	a1,s2
    800047f6:	8526                	mv	a0,s1
    800047f8:	ffffe097          	auipc	ra,0xffffe
    800047fc:	a32080e7          	jalr	-1486(ra) # 8000222a <sleep>
  while (lk->locked) {
    80004800:	409c                	lw	a5,0(s1)
    80004802:	fbed                	bnez	a5,800047f4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004804:	4785                	li	a5,1
    80004806:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004808:	ffffd097          	auipc	ra,0xffffd
    8000480c:	1a8080e7          	jalr	424(ra) # 800019b0 <myproc>
    80004810:	591c                	lw	a5,48(a0)
    80004812:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004814:	854a                	mv	a0,s2
    80004816:	ffffc097          	auipc	ra,0xffffc
    8000481a:	482080e7          	jalr	1154(ra) # 80000c98 <release>
}
    8000481e:	60e2                	ld	ra,24(sp)
    80004820:	6442                	ld	s0,16(sp)
    80004822:	64a2                	ld	s1,8(sp)
    80004824:	6902                	ld	s2,0(sp)
    80004826:	6105                	addi	sp,sp,32
    80004828:	8082                	ret

000000008000482a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000482a:	1101                	addi	sp,sp,-32
    8000482c:	ec06                	sd	ra,24(sp)
    8000482e:	e822                	sd	s0,16(sp)
    80004830:	e426                	sd	s1,8(sp)
    80004832:	e04a                	sd	s2,0(sp)
    80004834:	1000                	addi	s0,sp,32
    80004836:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004838:	00850913          	addi	s2,a0,8
    8000483c:	854a                	mv	a0,s2
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	3a6080e7          	jalr	934(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004846:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000484a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000484e:	8526                	mv	a0,s1
    80004850:	ffffe097          	auipc	ra,0xffffe
    80004854:	b76080e7          	jalr	-1162(ra) # 800023c6 <wakeup>
  release(&lk->lk);
    80004858:	854a                	mv	a0,s2
    8000485a:	ffffc097          	auipc	ra,0xffffc
    8000485e:	43e080e7          	jalr	1086(ra) # 80000c98 <release>
}
    80004862:	60e2                	ld	ra,24(sp)
    80004864:	6442                	ld	s0,16(sp)
    80004866:	64a2                	ld	s1,8(sp)
    80004868:	6902                	ld	s2,0(sp)
    8000486a:	6105                	addi	sp,sp,32
    8000486c:	8082                	ret

000000008000486e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000486e:	7179                	addi	sp,sp,-48
    80004870:	f406                	sd	ra,40(sp)
    80004872:	f022                	sd	s0,32(sp)
    80004874:	ec26                	sd	s1,24(sp)
    80004876:	e84a                	sd	s2,16(sp)
    80004878:	e44e                	sd	s3,8(sp)
    8000487a:	1800                	addi	s0,sp,48
    8000487c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000487e:	00850913          	addi	s2,a0,8
    80004882:	854a                	mv	a0,s2
    80004884:	ffffc097          	auipc	ra,0xffffc
    80004888:	360080e7          	jalr	864(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000488c:	409c                	lw	a5,0(s1)
    8000488e:	ef99                	bnez	a5,800048ac <holdingsleep+0x3e>
    80004890:	4481                	li	s1,0
  release(&lk->lk);
    80004892:	854a                	mv	a0,s2
    80004894:	ffffc097          	auipc	ra,0xffffc
    80004898:	404080e7          	jalr	1028(ra) # 80000c98 <release>
  return r;
}
    8000489c:	8526                	mv	a0,s1
    8000489e:	70a2                	ld	ra,40(sp)
    800048a0:	7402                	ld	s0,32(sp)
    800048a2:	64e2                	ld	s1,24(sp)
    800048a4:	6942                	ld	s2,16(sp)
    800048a6:	69a2                	ld	s3,8(sp)
    800048a8:	6145                	addi	sp,sp,48
    800048aa:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800048ac:	0284a983          	lw	s3,40(s1)
    800048b0:	ffffd097          	auipc	ra,0xffffd
    800048b4:	100080e7          	jalr	256(ra) # 800019b0 <myproc>
    800048b8:	5904                	lw	s1,48(a0)
    800048ba:	413484b3          	sub	s1,s1,s3
    800048be:	0014b493          	seqz	s1,s1
    800048c2:	bfc1                	j	80004892 <holdingsleep+0x24>

00000000800048c4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048c4:	1141                	addi	sp,sp,-16
    800048c6:	e406                	sd	ra,8(sp)
    800048c8:	e022                	sd	s0,0(sp)
    800048ca:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048cc:	00004597          	auipc	a1,0x4
    800048d0:	fd458593          	addi	a1,a1,-44 # 800088a0 <syscall_arg+0x1e8>
    800048d4:	0001d517          	auipc	a0,0x1d
    800048d8:	2e450513          	addi	a0,a0,740 # 80021bb8 <ftable>
    800048dc:	ffffc097          	auipc	ra,0xffffc
    800048e0:	278080e7          	jalr	632(ra) # 80000b54 <initlock>
}
    800048e4:	60a2                	ld	ra,8(sp)
    800048e6:	6402                	ld	s0,0(sp)
    800048e8:	0141                	addi	sp,sp,16
    800048ea:	8082                	ret

00000000800048ec <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048ec:	1101                	addi	sp,sp,-32
    800048ee:	ec06                	sd	ra,24(sp)
    800048f0:	e822                	sd	s0,16(sp)
    800048f2:	e426                	sd	s1,8(sp)
    800048f4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048f6:	0001d517          	auipc	a0,0x1d
    800048fa:	2c250513          	addi	a0,a0,706 # 80021bb8 <ftable>
    800048fe:	ffffc097          	auipc	ra,0xffffc
    80004902:	2e6080e7          	jalr	742(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004906:	0001d497          	auipc	s1,0x1d
    8000490a:	2ca48493          	addi	s1,s1,714 # 80021bd0 <ftable+0x18>
    8000490e:	0001e717          	auipc	a4,0x1e
    80004912:	26270713          	addi	a4,a4,610 # 80022b70 <ftable+0xfb8>
    if(f->ref == 0){
    80004916:	40dc                	lw	a5,4(s1)
    80004918:	cf99                	beqz	a5,80004936 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000491a:	02848493          	addi	s1,s1,40
    8000491e:	fee49ce3          	bne	s1,a4,80004916 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004922:	0001d517          	auipc	a0,0x1d
    80004926:	29650513          	addi	a0,a0,662 # 80021bb8 <ftable>
    8000492a:	ffffc097          	auipc	ra,0xffffc
    8000492e:	36e080e7          	jalr	878(ra) # 80000c98 <release>
  return 0;
    80004932:	4481                	li	s1,0
    80004934:	a819                	j	8000494a <filealloc+0x5e>
      f->ref = 1;
    80004936:	4785                	li	a5,1
    80004938:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000493a:	0001d517          	auipc	a0,0x1d
    8000493e:	27e50513          	addi	a0,a0,638 # 80021bb8 <ftable>
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	356080e7          	jalr	854(ra) # 80000c98 <release>
}
    8000494a:	8526                	mv	a0,s1
    8000494c:	60e2                	ld	ra,24(sp)
    8000494e:	6442                	ld	s0,16(sp)
    80004950:	64a2                	ld	s1,8(sp)
    80004952:	6105                	addi	sp,sp,32
    80004954:	8082                	ret

0000000080004956 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004956:	1101                	addi	sp,sp,-32
    80004958:	ec06                	sd	ra,24(sp)
    8000495a:	e822                	sd	s0,16(sp)
    8000495c:	e426                	sd	s1,8(sp)
    8000495e:	1000                	addi	s0,sp,32
    80004960:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004962:	0001d517          	auipc	a0,0x1d
    80004966:	25650513          	addi	a0,a0,598 # 80021bb8 <ftable>
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	27a080e7          	jalr	634(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004972:	40dc                	lw	a5,4(s1)
    80004974:	02f05263          	blez	a5,80004998 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004978:	2785                	addiw	a5,a5,1
    8000497a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000497c:	0001d517          	auipc	a0,0x1d
    80004980:	23c50513          	addi	a0,a0,572 # 80021bb8 <ftable>
    80004984:	ffffc097          	auipc	ra,0xffffc
    80004988:	314080e7          	jalr	788(ra) # 80000c98 <release>
  return f;
}
    8000498c:	8526                	mv	a0,s1
    8000498e:	60e2                	ld	ra,24(sp)
    80004990:	6442                	ld	s0,16(sp)
    80004992:	64a2                	ld	s1,8(sp)
    80004994:	6105                	addi	sp,sp,32
    80004996:	8082                	ret
    panic("filedup");
    80004998:	00004517          	auipc	a0,0x4
    8000499c:	f1050513          	addi	a0,a0,-240 # 800088a8 <syscall_arg+0x1f0>
    800049a0:	ffffc097          	auipc	ra,0xffffc
    800049a4:	b9e080e7          	jalr	-1122(ra) # 8000053e <panic>

00000000800049a8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800049a8:	7139                	addi	sp,sp,-64
    800049aa:	fc06                	sd	ra,56(sp)
    800049ac:	f822                	sd	s0,48(sp)
    800049ae:	f426                	sd	s1,40(sp)
    800049b0:	f04a                	sd	s2,32(sp)
    800049b2:	ec4e                	sd	s3,24(sp)
    800049b4:	e852                	sd	s4,16(sp)
    800049b6:	e456                	sd	s5,8(sp)
    800049b8:	0080                	addi	s0,sp,64
    800049ba:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049bc:	0001d517          	auipc	a0,0x1d
    800049c0:	1fc50513          	addi	a0,a0,508 # 80021bb8 <ftable>
    800049c4:	ffffc097          	auipc	ra,0xffffc
    800049c8:	220080e7          	jalr	544(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800049cc:	40dc                	lw	a5,4(s1)
    800049ce:	06f05163          	blez	a5,80004a30 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800049d2:	37fd                	addiw	a5,a5,-1
    800049d4:	0007871b          	sext.w	a4,a5
    800049d8:	c0dc                	sw	a5,4(s1)
    800049da:	06e04363          	bgtz	a4,80004a40 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049de:	0004a903          	lw	s2,0(s1)
    800049e2:	0094ca83          	lbu	s5,9(s1)
    800049e6:	0104ba03          	ld	s4,16(s1)
    800049ea:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049ee:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049f2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049f6:	0001d517          	auipc	a0,0x1d
    800049fa:	1c250513          	addi	a0,a0,450 # 80021bb8 <ftable>
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	29a080e7          	jalr	666(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004a06:	4785                	li	a5,1
    80004a08:	04f90d63          	beq	s2,a5,80004a62 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a0c:	3979                	addiw	s2,s2,-2
    80004a0e:	4785                	li	a5,1
    80004a10:	0527e063          	bltu	a5,s2,80004a50 <fileclose+0xa8>
    begin_op();
    80004a14:	00000097          	auipc	ra,0x0
    80004a18:	ac8080e7          	jalr	-1336(ra) # 800044dc <begin_op>
    iput(ff.ip);
    80004a1c:	854e                	mv	a0,s3
    80004a1e:	fffff097          	auipc	ra,0xfffff
    80004a22:	2a6080e7          	jalr	678(ra) # 80003cc4 <iput>
    end_op();
    80004a26:	00000097          	auipc	ra,0x0
    80004a2a:	b36080e7          	jalr	-1226(ra) # 8000455c <end_op>
    80004a2e:	a00d                	j	80004a50 <fileclose+0xa8>
    panic("fileclose");
    80004a30:	00004517          	auipc	a0,0x4
    80004a34:	e8050513          	addi	a0,a0,-384 # 800088b0 <syscall_arg+0x1f8>
    80004a38:	ffffc097          	auipc	ra,0xffffc
    80004a3c:	b06080e7          	jalr	-1274(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004a40:	0001d517          	auipc	a0,0x1d
    80004a44:	17850513          	addi	a0,a0,376 # 80021bb8 <ftable>
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	250080e7          	jalr	592(ra) # 80000c98 <release>
  }
}
    80004a50:	70e2                	ld	ra,56(sp)
    80004a52:	7442                	ld	s0,48(sp)
    80004a54:	74a2                	ld	s1,40(sp)
    80004a56:	7902                	ld	s2,32(sp)
    80004a58:	69e2                	ld	s3,24(sp)
    80004a5a:	6a42                	ld	s4,16(sp)
    80004a5c:	6aa2                	ld	s5,8(sp)
    80004a5e:	6121                	addi	sp,sp,64
    80004a60:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a62:	85d6                	mv	a1,s5
    80004a64:	8552                	mv	a0,s4
    80004a66:	00000097          	auipc	ra,0x0
    80004a6a:	34c080e7          	jalr	844(ra) # 80004db2 <pipeclose>
    80004a6e:	b7cd                	j	80004a50 <fileclose+0xa8>

0000000080004a70 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a70:	715d                	addi	sp,sp,-80
    80004a72:	e486                	sd	ra,72(sp)
    80004a74:	e0a2                	sd	s0,64(sp)
    80004a76:	fc26                	sd	s1,56(sp)
    80004a78:	f84a                	sd	s2,48(sp)
    80004a7a:	f44e                	sd	s3,40(sp)
    80004a7c:	0880                	addi	s0,sp,80
    80004a7e:	84aa                	mv	s1,a0
    80004a80:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a82:	ffffd097          	auipc	ra,0xffffd
    80004a86:	f2e080e7          	jalr	-210(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a8a:	409c                	lw	a5,0(s1)
    80004a8c:	37f9                	addiw	a5,a5,-2
    80004a8e:	4705                	li	a4,1
    80004a90:	04f76763          	bltu	a4,a5,80004ade <filestat+0x6e>
    80004a94:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a96:	6c88                	ld	a0,24(s1)
    80004a98:	fffff097          	auipc	ra,0xfffff
    80004a9c:	072080e7          	jalr	114(ra) # 80003b0a <ilock>
    stati(f->ip, &st);
    80004aa0:	fb840593          	addi	a1,s0,-72
    80004aa4:	6c88                	ld	a0,24(s1)
    80004aa6:	fffff097          	auipc	ra,0xfffff
    80004aaa:	2ee080e7          	jalr	750(ra) # 80003d94 <stati>
    iunlock(f->ip);
    80004aae:	6c88                	ld	a0,24(s1)
    80004ab0:	fffff097          	auipc	ra,0xfffff
    80004ab4:	11c080e7          	jalr	284(ra) # 80003bcc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004ab8:	46e1                	li	a3,24
    80004aba:	fb840613          	addi	a2,s0,-72
    80004abe:	85ce                	mv	a1,s3
    80004ac0:	07093503          	ld	a0,112(s2)
    80004ac4:	ffffd097          	auipc	ra,0xffffd
    80004ac8:	bae080e7          	jalr	-1106(ra) # 80001672 <copyout>
    80004acc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ad0:	60a6                	ld	ra,72(sp)
    80004ad2:	6406                	ld	s0,64(sp)
    80004ad4:	74e2                	ld	s1,56(sp)
    80004ad6:	7942                	ld	s2,48(sp)
    80004ad8:	79a2                	ld	s3,40(sp)
    80004ada:	6161                	addi	sp,sp,80
    80004adc:	8082                	ret
  return -1;
    80004ade:	557d                	li	a0,-1
    80004ae0:	bfc5                	j	80004ad0 <filestat+0x60>

0000000080004ae2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ae2:	7179                	addi	sp,sp,-48
    80004ae4:	f406                	sd	ra,40(sp)
    80004ae6:	f022                	sd	s0,32(sp)
    80004ae8:	ec26                	sd	s1,24(sp)
    80004aea:	e84a                	sd	s2,16(sp)
    80004aec:	e44e                	sd	s3,8(sp)
    80004aee:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004af0:	00854783          	lbu	a5,8(a0)
    80004af4:	c3d5                	beqz	a5,80004b98 <fileread+0xb6>
    80004af6:	84aa                	mv	s1,a0
    80004af8:	89ae                	mv	s3,a1
    80004afa:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004afc:	411c                	lw	a5,0(a0)
    80004afe:	4705                	li	a4,1
    80004b00:	04e78963          	beq	a5,a4,80004b52 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b04:	470d                	li	a4,3
    80004b06:	04e78d63          	beq	a5,a4,80004b60 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b0a:	4709                	li	a4,2
    80004b0c:	06e79e63          	bne	a5,a4,80004b88 <fileread+0xa6>
    ilock(f->ip);
    80004b10:	6d08                	ld	a0,24(a0)
    80004b12:	fffff097          	auipc	ra,0xfffff
    80004b16:	ff8080e7          	jalr	-8(ra) # 80003b0a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b1a:	874a                	mv	a4,s2
    80004b1c:	5094                	lw	a3,32(s1)
    80004b1e:	864e                	mv	a2,s3
    80004b20:	4585                	li	a1,1
    80004b22:	6c88                	ld	a0,24(s1)
    80004b24:	fffff097          	auipc	ra,0xfffff
    80004b28:	29a080e7          	jalr	666(ra) # 80003dbe <readi>
    80004b2c:	892a                	mv	s2,a0
    80004b2e:	00a05563          	blez	a0,80004b38 <fileread+0x56>
      f->off += r;
    80004b32:	509c                	lw	a5,32(s1)
    80004b34:	9fa9                	addw	a5,a5,a0
    80004b36:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b38:	6c88                	ld	a0,24(s1)
    80004b3a:	fffff097          	auipc	ra,0xfffff
    80004b3e:	092080e7          	jalr	146(ra) # 80003bcc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b42:	854a                	mv	a0,s2
    80004b44:	70a2                	ld	ra,40(sp)
    80004b46:	7402                	ld	s0,32(sp)
    80004b48:	64e2                	ld	s1,24(sp)
    80004b4a:	6942                	ld	s2,16(sp)
    80004b4c:	69a2                	ld	s3,8(sp)
    80004b4e:	6145                	addi	sp,sp,48
    80004b50:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b52:	6908                	ld	a0,16(a0)
    80004b54:	00000097          	auipc	ra,0x0
    80004b58:	3c8080e7          	jalr	968(ra) # 80004f1c <piperead>
    80004b5c:	892a                	mv	s2,a0
    80004b5e:	b7d5                	j	80004b42 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b60:	02451783          	lh	a5,36(a0)
    80004b64:	03079693          	slli	a3,a5,0x30
    80004b68:	92c1                	srli	a3,a3,0x30
    80004b6a:	4725                	li	a4,9
    80004b6c:	02d76863          	bltu	a4,a3,80004b9c <fileread+0xba>
    80004b70:	0792                	slli	a5,a5,0x4
    80004b72:	0001d717          	auipc	a4,0x1d
    80004b76:	fa670713          	addi	a4,a4,-90 # 80021b18 <devsw>
    80004b7a:	97ba                	add	a5,a5,a4
    80004b7c:	639c                	ld	a5,0(a5)
    80004b7e:	c38d                	beqz	a5,80004ba0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b80:	4505                	li	a0,1
    80004b82:	9782                	jalr	a5
    80004b84:	892a                	mv	s2,a0
    80004b86:	bf75                	j	80004b42 <fileread+0x60>
    panic("fileread");
    80004b88:	00004517          	auipc	a0,0x4
    80004b8c:	d3850513          	addi	a0,a0,-712 # 800088c0 <syscall_arg+0x208>
    80004b90:	ffffc097          	auipc	ra,0xffffc
    80004b94:	9ae080e7          	jalr	-1618(ra) # 8000053e <panic>
    return -1;
    80004b98:	597d                	li	s2,-1
    80004b9a:	b765                	j	80004b42 <fileread+0x60>
      return -1;
    80004b9c:	597d                	li	s2,-1
    80004b9e:	b755                	j	80004b42 <fileread+0x60>
    80004ba0:	597d                	li	s2,-1
    80004ba2:	b745                	j	80004b42 <fileread+0x60>

0000000080004ba4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ba4:	715d                	addi	sp,sp,-80
    80004ba6:	e486                	sd	ra,72(sp)
    80004ba8:	e0a2                	sd	s0,64(sp)
    80004baa:	fc26                	sd	s1,56(sp)
    80004bac:	f84a                	sd	s2,48(sp)
    80004bae:	f44e                	sd	s3,40(sp)
    80004bb0:	f052                	sd	s4,32(sp)
    80004bb2:	ec56                	sd	s5,24(sp)
    80004bb4:	e85a                	sd	s6,16(sp)
    80004bb6:	e45e                	sd	s7,8(sp)
    80004bb8:	e062                	sd	s8,0(sp)
    80004bba:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004bbc:	00954783          	lbu	a5,9(a0)
    80004bc0:	10078663          	beqz	a5,80004ccc <filewrite+0x128>
    80004bc4:	892a                	mv	s2,a0
    80004bc6:	8aae                	mv	s5,a1
    80004bc8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bca:	411c                	lw	a5,0(a0)
    80004bcc:	4705                	li	a4,1
    80004bce:	02e78263          	beq	a5,a4,80004bf2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bd2:	470d                	li	a4,3
    80004bd4:	02e78663          	beq	a5,a4,80004c00 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bd8:	4709                	li	a4,2
    80004bda:	0ee79163          	bne	a5,a4,80004cbc <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004bde:	0ac05d63          	blez	a2,80004c98 <filewrite+0xf4>
    int i = 0;
    80004be2:	4981                	li	s3,0
    80004be4:	6b05                	lui	s6,0x1
    80004be6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004bea:	6b85                	lui	s7,0x1
    80004bec:	c00b8b9b          	addiw	s7,s7,-1024
    80004bf0:	a861                	j	80004c88 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004bf2:	6908                	ld	a0,16(a0)
    80004bf4:	00000097          	auipc	ra,0x0
    80004bf8:	22e080e7          	jalr	558(ra) # 80004e22 <pipewrite>
    80004bfc:	8a2a                	mv	s4,a0
    80004bfe:	a045                	j	80004c9e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c00:	02451783          	lh	a5,36(a0)
    80004c04:	03079693          	slli	a3,a5,0x30
    80004c08:	92c1                	srli	a3,a3,0x30
    80004c0a:	4725                	li	a4,9
    80004c0c:	0cd76263          	bltu	a4,a3,80004cd0 <filewrite+0x12c>
    80004c10:	0792                	slli	a5,a5,0x4
    80004c12:	0001d717          	auipc	a4,0x1d
    80004c16:	f0670713          	addi	a4,a4,-250 # 80021b18 <devsw>
    80004c1a:	97ba                	add	a5,a5,a4
    80004c1c:	679c                	ld	a5,8(a5)
    80004c1e:	cbdd                	beqz	a5,80004cd4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c20:	4505                	li	a0,1
    80004c22:	9782                	jalr	a5
    80004c24:	8a2a                	mv	s4,a0
    80004c26:	a8a5                	j	80004c9e <filewrite+0xfa>
    80004c28:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c2c:	00000097          	auipc	ra,0x0
    80004c30:	8b0080e7          	jalr	-1872(ra) # 800044dc <begin_op>
      ilock(f->ip);
    80004c34:	01893503          	ld	a0,24(s2)
    80004c38:	fffff097          	auipc	ra,0xfffff
    80004c3c:	ed2080e7          	jalr	-302(ra) # 80003b0a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c40:	8762                	mv	a4,s8
    80004c42:	02092683          	lw	a3,32(s2)
    80004c46:	01598633          	add	a2,s3,s5
    80004c4a:	4585                	li	a1,1
    80004c4c:	01893503          	ld	a0,24(s2)
    80004c50:	fffff097          	auipc	ra,0xfffff
    80004c54:	266080e7          	jalr	614(ra) # 80003eb6 <writei>
    80004c58:	84aa                	mv	s1,a0
    80004c5a:	00a05763          	blez	a0,80004c68 <filewrite+0xc4>
        f->off += r;
    80004c5e:	02092783          	lw	a5,32(s2)
    80004c62:	9fa9                	addw	a5,a5,a0
    80004c64:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c68:	01893503          	ld	a0,24(s2)
    80004c6c:	fffff097          	auipc	ra,0xfffff
    80004c70:	f60080e7          	jalr	-160(ra) # 80003bcc <iunlock>
      end_op();
    80004c74:	00000097          	auipc	ra,0x0
    80004c78:	8e8080e7          	jalr	-1816(ra) # 8000455c <end_op>

      if(r != n1){
    80004c7c:	009c1f63          	bne	s8,s1,80004c9a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c80:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c84:	0149db63          	bge	s3,s4,80004c9a <filewrite+0xf6>
      int n1 = n - i;
    80004c88:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004c8c:	84be                	mv	s1,a5
    80004c8e:	2781                	sext.w	a5,a5
    80004c90:	f8fb5ce3          	bge	s6,a5,80004c28 <filewrite+0x84>
    80004c94:	84de                	mv	s1,s7
    80004c96:	bf49                	j	80004c28 <filewrite+0x84>
    int i = 0;
    80004c98:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c9a:	013a1f63          	bne	s4,s3,80004cb8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c9e:	8552                	mv	a0,s4
    80004ca0:	60a6                	ld	ra,72(sp)
    80004ca2:	6406                	ld	s0,64(sp)
    80004ca4:	74e2                	ld	s1,56(sp)
    80004ca6:	7942                	ld	s2,48(sp)
    80004ca8:	79a2                	ld	s3,40(sp)
    80004caa:	7a02                	ld	s4,32(sp)
    80004cac:	6ae2                	ld	s5,24(sp)
    80004cae:	6b42                	ld	s6,16(sp)
    80004cb0:	6ba2                	ld	s7,8(sp)
    80004cb2:	6c02                	ld	s8,0(sp)
    80004cb4:	6161                	addi	sp,sp,80
    80004cb6:	8082                	ret
    ret = (i == n ? n : -1);
    80004cb8:	5a7d                	li	s4,-1
    80004cba:	b7d5                	j	80004c9e <filewrite+0xfa>
    panic("filewrite");
    80004cbc:	00004517          	auipc	a0,0x4
    80004cc0:	c1450513          	addi	a0,a0,-1004 # 800088d0 <syscall_arg+0x218>
    80004cc4:	ffffc097          	auipc	ra,0xffffc
    80004cc8:	87a080e7          	jalr	-1926(ra) # 8000053e <panic>
    return -1;
    80004ccc:	5a7d                	li	s4,-1
    80004cce:	bfc1                	j	80004c9e <filewrite+0xfa>
      return -1;
    80004cd0:	5a7d                	li	s4,-1
    80004cd2:	b7f1                	j	80004c9e <filewrite+0xfa>
    80004cd4:	5a7d                	li	s4,-1
    80004cd6:	b7e1                	j	80004c9e <filewrite+0xfa>

0000000080004cd8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004cd8:	7179                	addi	sp,sp,-48
    80004cda:	f406                	sd	ra,40(sp)
    80004cdc:	f022                	sd	s0,32(sp)
    80004cde:	ec26                	sd	s1,24(sp)
    80004ce0:	e84a                	sd	s2,16(sp)
    80004ce2:	e44e                	sd	s3,8(sp)
    80004ce4:	e052                	sd	s4,0(sp)
    80004ce6:	1800                	addi	s0,sp,48
    80004ce8:	84aa                	mv	s1,a0
    80004cea:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004cec:	0005b023          	sd	zero,0(a1)
    80004cf0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004cf4:	00000097          	auipc	ra,0x0
    80004cf8:	bf8080e7          	jalr	-1032(ra) # 800048ec <filealloc>
    80004cfc:	e088                	sd	a0,0(s1)
    80004cfe:	c551                	beqz	a0,80004d8a <pipealloc+0xb2>
    80004d00:	00000097          	auipc	ra,0x0
    80004d04:	bec080e7          	jalr	-1044(ra) # 800048ec <filealloc>
    80004d08:	00aa3023          	sd	a0,0(s4)
    80004d0c:	c92d                	beqz	a0,80004d7e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d0e:	ffffc097          	auipc	ra,0xffffc
    80004d12:	de6080e7          	jalr	-538(ra) # 80000af4 <kalloc>
    80004d16:	892a                	mv	s2,a0
    80004d18:	c125                	beqz	a0,80004d78 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d1a:	4985                	li	s3,1
    80004d1c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d20:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d24:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d28:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d2c:	00003597          	auipc	a1,0x3
    80004d30:	76458593          	addi	a1,a1,1892 # 80008490 <states.1758+0x1b8>
    80004d34:	ffffc097          	auipc	ra,0xffffc
    80004d38:	e20080e7          	jalr	-480(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004d3c:	609c                	ld	a5,0(s1)
    80004d3e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d42:	609c                	ld	a5,0(s1)
    80004d44:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d48:	609c                	ld	a5,0(s1)
    80004d4a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d4e:	609c                	ld	a5,0(s1)
    80004d50:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d54:	000a3783          	ld	a5,0(s4)
    80004d58:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d5c:	000a3783          	ld	a5,0(s4)
    80004d60:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d64:	000a3783          	ld	a5,0(s4)
    80004d68:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d6c:	000a3783          	ld	a5,0(s4)
    80004d70:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d74:	4501                	li	a0,0
    80004d76:	a025                	j	80004d9e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d78:	6088                	ld	a0,0(s1)
    80004d7a:	e501                	bnez	a0,80004d82 <pipealloc+0xaa>
    80004d7c:	a039                	j	80004d8a <pipealloc+0xb2>
    80004d7e:	6088                	ld	a0,0(s1)
    80004d80:	c51d                	beqz	a0,80004dae <pipealloc+0xd6>
    fileclose(*f0);
    80004d82:	00000097          	auipc	ra,0x0
    80004d86:	c26080e7          	jalr	-986(ra) # 800049a8 <fileclose>
  if(*f1)
    80004d8a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d8e:	557d                	li	a0,-1
  if(*f1)
    80004d90:	c799                	beqz	a5,80004d9e <pipealloc+0xc6>
    fileclose(*f1);
    80004d92:	853e                	mv	a0,a5
    80004d94:	00000097          	auipc	ra,0x0
    80004d98:	c14080e7          	jalr	-1004(ra) # 800049a8 <fileclose>
  return -1;
    80004d9c:	557d                	li	a0,-1
}
    80004d9e:	70a2                	ld	ra,40(sp)
    80004da0:	7402                	ld	s0,32(sp)
    80004da2:	64e2                	ld	s1,24(sp)
    80004da4:	6942                	ld	s2,16(sp)
    80004da6:	69a2                	ld	s3,8(sp)
    80004da8:	6a02                	ld	s4,0(sp)
    80004daa:	6145                	addi	sp,sp,48
    80004dac:	8082                	ret
  return -1;
    80004dae:	557d                	li	a0,-1
    80004db0:	b7fd                	j	80004d9e <pipealloc+0xc6>

0000000080004db2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004db2:	1101                	addi	sp,sp,-32
    80004db4:	ec06                	sd	ra,24(sp)
    80004db6:	e822                	sd	s0,16(sp)
    80004db8:	e426                	sd	s1,8(sp)
    80004dba:	e04a                	sd	s2,0(sp)
    80004dbc:	1000                	addi	s0,sp,32
    80004dbe:	84aa                	mv	s1,a0
    80004dc0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004dc2:	ffffc097          	auipc	ra,0xffffc
    80004dc6:	e22080e7          	jalr	-478(ra) # 80000be4 <acquire>
  if(writable){
    80004dca:	02090d63          	beqz	s2,80004e04 <pipeclose+0x52>
    pi->writeopen = 0;
    80004dce:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004dd2:	21848513          	addi	a0,s1,536
    80004dd6:	ffffd097          	auipc	ra,0xffffd
    80004dda:	5f0080e7          	jalr	1520(ra) # 800023c6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004dde:	2204b783          	ld	a5,544(s1)
    80004de2:	eb95                	bnez	a5,80004e16 <pipeclose+0x64>
    release(&pi->lock);
    80004de4:	8526                	mv	a0,s1
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	eb2080e7          	jalr	-334(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004dee:	8526                	mv	a0,s1
    80004df0:	ffffc097          	auipc	ra,0xffffc
    80004df4:	c08080e7          	jalr	-1016(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004df8:	60e2                	ld	ra,24(sp)
    80004dfa:	6442                	ld	s0,16(sp)
    80004dfc:	64a2                	ld	s1,8(sp)
    80004dfe:	6902                	ld	s2,0(sp)
    80004e00:	6105                	addi	sp,sp,32
    80004e02:	8082                	ret
    pi->readopen = 0;
    80004e04:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e08:	21c48513          	addi	a0,s1,540
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	5ba080e7          	jalr	1466(ra) # 800023c6 <wakeup>
    80004e14:	b7e9                	j	80004dde <pipeclose+0x2c>
    release(&pi->lock);
    80004e16:	8526                	mv	a0,s1
    80004e18:	ffffc097          	auipc	ra,0xffffc
    80004e1c:	e80080e7          	jalr	-384(ra) # 80000c98 <release>
}
    80004e20:	bfe1                	j	80004df8 <pipeclose+0x46>

0000000080004e22 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e22:	7159                	addi	sp,sp,-112
    80004e24:	f486                	sd	ra,104(sp)
    80004e26:	f0a2                	sd	s0,96(sp)
    80004e28:	eca6                	sd	s1,88(sp)
    80004e2a:	e8ca                	sd	s2,80(sp)
    80004e2c:	e4ce                	sd	s3,72(sp)
    80004e2e:	e0d2                	sd	s4,64(sp)
    80004e30:	fc56                	sd	s5,56(sp)
    80004e32:	f85a                	sd	s6,48(sp)
    80004e34:	f45e                	sd	s7,40(sp)
    80004e36:	f062                	sd	s8,32(sp)
    80004e38:	ec66                	sd	s9,24(sp)
    80004e3a:	1880                	addi	s0,sp,112
    80004e3c:	84aa                	mv	s1,a0
    80004e3e:	8aae                	mv	s5,a1
    80004e40:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e42:	ffffd097          	auipc	ra,0xffffd
    80004e46:	b6e080e7          	jalr	-1170(ra) # 800019b0 <myproc>
    80004e4a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e4c:	8526                	mv	a0,s1
    80004e4e:	ffffc097          	auipc	ra,0xffffc
    80004e52:	d96080e7          	jalr	-618(ra) # 80000be4 <acquire>
  while(i < n){
    80004e56:	0d405163          	blez	s4,80004f18 <pipewrite+0xf6>
    80004e5a:	8ba6                	mv	s7,s1
  int i = 0;
    80004e5c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e5e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e60:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e64:	21c48c13          	addi	s8,s1,540
    80004e68:	a08d                	j	80004eca <pipewrite+0xa8>
      release(&pi->lock);
    80004e6a:	8526                	mv	a0,s1
    80004e6c:	ffffc097          	auipc	ra,0xffffc
    80004e70:	e2c080e7          	jalr	-468(ra) # 80000c98 <release>
      return -1;
    80004e74:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e76:	854a                	mv	a0,s2
    80004e78:	70a6                	ld	ra,104(sp)
    80004e7a:	7406                	ld	s0,96(sp)
    80004e7c:	64e6                	ld	s1,88(sp)
    80004e7e:	6946                	ld	s2,80(sp)
    80004e80:	69a6                	ld	s3,72(sp)
    80004e82:	6a06                	ld	s4,64(sp)
    80004e84:	7ae2                	ld	s5,56(sp)
    80004e86:	7b42                	ld	s6,48(sp)
    80004e88:	7ba2                	ld	s7,40(sp)
    80004e8a:	7c02                	ld	s8,32(sp)
    80004e8c:	6ce2                	ld	s9,24(sp)
    80004e8e:	6165                	addi	sp,sp,112
    80004e90:	8082                	ret
      wakeup(&pi->nread);
    80004e92:	8566                	mv	a0,s9
    80004e94:	ffffd097          	auipc	ra,0xffffd
    80004e98:	532080e7          	jalr	1330(ra) # 800023c6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e9c:	85de                	mv	a1,s7
    80004e9e:	8562                	mv	a0,s8
    80004ea0:	ffffd097          	auipc	ra,0xffffd
    80004ea4:	38a080e7          	jalr	906(ra) # 8000222a <sleep>
    80004ea8:	a839                	j	80004ec6 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004eaa:	21c4a783          	lw	a5,540(s1)
    80004eae:	0017871b          	addiw	a4,a5,1
    80004eb2:	20e4ae23          	sw	a4,540(s1)
    80004eb6:	1ff7f793          	andi	a5,a5,511
    80004eba:	97a6                	add	a5,a5,s1
    80004ebc:	f9f44703          	lbu	a4,-97(s0)
    80004ec0:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ec4:	2905                	addiw	s2,s2,1
  while(i < n){
    80004ec6:	03495d63          	bge	s2,s4,80004f00 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004eca:	2204a783          	lw	a5,544(s1)
    80004ece:	dfd1                	beqz	a5,80004e6a <pipewrite+0x48>
    80004ed0:	0289a783          	lw	a5,40(s3)
    80004ed4:	fbd9                	bnez	a5,80004e6a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ed6:	2184a783          	lw	a5,536(s1)
    80004eda:	21c4a703          	lw	a4,540(s1)
    80004ede:	2007879b          	addiw	a5,a5,512
    80004ee2:	faf708e3          	beq	a4,a5,80004e92 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ee6:	4685                	li	a3,1
    80004ee8:	01590633          	add	a2,s2,s5
    80004eec:	f9f40593          	addi	a1,s0,-97
    80004ef0:	0709b503          	ld	a0,112(s3)
    80004ef4:	ffffd097          	auipc	ra,0xffffd
    80004ef8:	80a080e7          	jalr	-2038(ra) # 800016fe <copyin>
    80004efc:	fb6517e3          	bne	a0,s6,80004eaa <pipewrite+0x88>
  wakeup(&pi->nread);
    80004f00:	21848513          	addi	a0,s1,536
    80004f04:	ffffd097          	auipc	ra,0xffffd
    80004f08:	4c2080e7          	jalr	1218(ra) # 800023c6 <wakeup>
  release(&pi->lock);
    80004f0c:	8526                	mv	a0,s1
    80004f0e:	ffffc097          	auipc	ra,0xffffc
    80004f12:	d8a080e7          	jalr	-630(ra) # 80000c98 <release>
  return i;
    80004f16:	b785                	j	80004e76 <pipewrite+0x54>
  int i = 0;
    80004f18:	4901                	li	s2,0
    80004f1a:	b7dd                	j	80004f00 <pipewrite+0xde>

0000000080004f1c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f1c:	715d                	addi	sp,sp,-80
    80004f1e:	e486                	sd	ra,72(sp)
    80004f20:	e0a2                	sd	s0,64(sp)
    80004f22:	fc26                	sd	s1,56(sp)
    80004f24:	f84a                	sd	s2,48(sp)
    80004f26:	f44e                	sd	s3,40(sp)
    80004f28:	f052                	sd	s4,32(sp)
    80004f2a:	ec56                	sd	s5,24(sp)
    80004f2c:	e85a                	sd	s6,16(sp)
    80004f2e:	0880                	addi	s0,sp,80
    80004f30:	84aa                	mv	s1,a0
    80004f32:	892e                	mv	s2,a1
    80004f34:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f36:	ffffd097          	auipc	ra,0xffffd
    80004f3a:	a7a080e7          	jalr	-1414(ra) # 800019b0 <myproc>
    80004f3e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f40:	8b26                	mv	s6,s1
    80004f42:	8526                	mv	a0,s1
    80004f44:	ffffc097          	auipc	ra,0xffffc
    80004f48:	ca0080e7          	jalr	-864(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f4c:	2184a703          	lw	a4,536(s1)
    80004f50:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f54:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f58:	02f71463          	bne	a4,a5,80004f80 <piperead+0x64>
    80004f5c:	2244a783          	lw	a5,548(s1)
    80004f60:	c385                	beqz	a5,80004f80 <piperead+0x64>
    if(pr->killed){
    80004f62:	028a2783          	lw	a5,40(s4)
    80004f66:	ebc1                	bnez	a5,80004ff6 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f68:	85da                	mv	a1,s6
    80004f6a:	854e                	mv	a0,s3
    80004f6c:	ffffd097          	auipc	ra,0xffffd
    80004f70:	2be080e7          	jalr	702(ra) # 8000222a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f74:	2184a703          	lw	a4,536(s1)
    80004f78:	21c4a783          	lw	a5,540(s1)
    80004f7c:	fef700e3          	beq	a4,a5,80004f5c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f80:	09505263          	blez	s5,80005004 <piperead+0xe8>
    80004f84:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f86:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004f88:	2184a783          	lw	a5,536(s1)
    80004f8c:	21c4a703          	lw	a4,540(s1)
    80004f90:	02f70d63          	beq	a4,a5,80004fca <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f94:	0017871b          	addiw	a4,a5,1
    80004f98:	20e4ac23          	sw	a4,536(s1)
    80004f9c:	1ff7f793          	andi	a5,a5,511
    80004fa0:	97a6                	add	a5,a5,s1
    80004fa2:	0187c783          	lbu	a5,24(a5)
    80004fa6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004faa:	4685                	li	a3,1
    80004fac:	fbf40613          	addi	a2,s0,-65
    80004fb0:	85ca                	mv	a1,s2
    80004fb2:	070a3503          	ld	a0,112(s4)
    80004fb6:	ffffc097          	auipc	ra,0xffffc
    80004fba:	6bc080e7          	jalr	1724(ra) # 80001672 <copyout>
    80004fbe:	01650663          	beq	a0,s6,80004fca <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fc2:	2985                	addiw	s3,s3,1
    80004fc4:	0905                	addi	s2,s2,1
    80004fc6:	fd3a91e3          	bne	s5,s3,80004f88 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004fca:	21c48513          	addi	a0,s1,540
    80004fce:	ffffd097          	auipc	ra,0xffffd
    80004fd2:	3f8080e7          	jalr	1016(ra) # 800023c6 <wakeup>
  release(&pi->lock);
    80004fd6:	8526                	mv	a0,s1
    80004fd8:	ffffc097          	auipc	ra,0xffffc
    80004fdc:	cc0080e7          	jalr	-832(ra) # 80000c98 <release>
  return i;
}
    80004fe0:	854e                	mv	a0,s3
    80004fe2:	60a6                	ld	ra,72(sp)
    80004fe4:	6406                	ld	s0,64(sp)
    80004fe6:	74e2                	ld	s1,56(sp)
    80004fe8:	7942                	ld	s2,48(sp)
    80004fea:	79a2                	ld	s3,40(sp)
    80004fec:	7a02                	ld	s4,32(sp)
    80004fee:	6ae2                	ld	s5,24(sp)
    80004ff0:	6b42                	ld	s6,16(sp)
    80004ff2:	6161                	addi	sp,sp,80
    80004ff4:	8082                	ret
      release(&pi->lock);
    80004ff6:	8526                	mv	a0,s1
    80004ff8:	ffffc097          	auipc	ra,0xffffc
    80004ffc:	ca0080e7          	jalr	-864(ra) # 80000c98 <release>
      return -1;
    80005000:	59fd                	li	s3,-1
    80005002:	bff9                	j	80004fe0 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005004:	4981                	li	s3,0
    80005006:	b7d1                	j	80004fca <piperead+0xae>

0000000080005008 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005008:	df010113          	addi	sp,sp,-528
    8000500c:	20113423          	sd	ra,520(sp)
    80005010:	20813023          	sd	s0,512(sp)
    80005014:	ffa6                	sd	s1,504(sp)
    80005016:	fbca                	sd	s2,496(sp)
    80005018:	f7ce                	sd	s3,488(sp)
    8000501a:	f3d2                	sd	s4,480(sp)
    8000501c:	efd6                	sd	s5,472(sp)
    8000501e:	ebda                	sd	s6,464(sp)
    80005020:	e7de                	sd	s7,456(sp)
    80005022:	e3e2                	sd	s8,448(sp)
    80005024:	ff66                	sd	s9,440(sp)
    80005026:	fb6a                	sd	s10,432(sp)
    80005028:	f76e                	sd	s11,424(sp)
    8000502a:	0c00                	addi	s0,sp,528
    8000502c:	84aa                	mv	s1,a0
    8000502e:	dea43c23          	sd	a0,-520(s0)
    80005032:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005036:	ffffd097          	auipc	ra,0xffffd
    8000503a:	97a080e7          	jalr	-1670(ra) # 800019b0 <myproc>
    8000503e:	892a                	mv	s2,a0

  begin_op();
    80005040:	fffff097          	auipc	ra,0xfffff
    80005044:	49c080e7          	jalr	1180(ra) # 800044dc <begin_op>

  if((ip = namei(path)) == 0){
    80005048:	8526                	mv	a0,s1
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	276080e7          	jalr	630(ra) # 800042c0 <namei>
    80005052:	c92d                	beqz	a0,800050c4 <exec+0xbc>
    80005054:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005056:	fffff097          	auipc	ra,0xfffff
    8000505a:	ab4080e7          	jalr	-1356(ra) # 80003b0a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000505e:	04000713          	li	a4,64
    80005062:	4681                	li	a3,0
    80005064:	e5040613          	addi	a2,s0,-432
    80005068:	4581                	li	a1,0
    8000506a:	8526                	mv	a0,s1
    8000506c:	fffff097          	auipc	ra,0xfffff
    80005070:	d52080e7          	jalr	-686(ra) # 80003dbe <readi>
    80005074:	04000793          	li	a5,64
    80005078:	00f51a63          	bne	a0,a5,8000508c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000507c:	e5042703          	lw	a4,-432(s0)
    80005080:	464c47b7          	lui	a5,0x464c4
    80005084:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005088:	04f70463          	beq	a4,a5,800050d0 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000508c:	8526                	mv	a0,s1
    8000508e:	fffff097          	auipc	ra,0xfffff
    80005092:	cde080e7          	jalr	-802(ra) # 80003d6c <iunlockput>
    end_op();
    80005096:	fffff097          	auipc	ra,0xfffff
    8000509a:	4c6080e7          	jalr	1222(ra) # 8000455c <end_op>
  }
  return -1;
    8000509e:	557d                	li	a0,-1
}
    800050a0:	20813083          	ld	ra,520(sp)
    800050a4:	20013403          	ld	s0,512(sp)
    800050a8:	74fe                	ld	s1,504(sp)
    800050aa:	795e                	ld	s2,496(sp)
    800050ac:	79be                	ld	s3,488(sp)
    800050ae:	7a1e                	ld	s4,480(sp)
    800050b0:	6afe                	ld	s5,472(sp)
    800050b2:	6b5e                	ld	s6,464(sp)
    800050b4:	6bbe                	ld	s7,456(sp)
    800050b6:	6c1e                	ld	s8,448(sp)
    800050b8:	7cfa                	ld	s9,440(sp)
    800050ba:	7d5a                	ld	s10,432(sp)
    800050bc:	7dba                	ld	s11,424(sp)
    800050be:	21010113          	addi	sp,sp,528
    800050c2:	8082                	ret
    end_op();
    800050c4:	fffff097          	auipc	ra,0xfffff
    800050c8:	498080e7          	jalr	1176(ra) # 8000455c <end_op>
    return -1;
    800050cc:	557d                	li	a0,-1
    800050ce:	bfc9                	j	800050a0 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800050d0:	854a                	mv	a0,s2
    800050d2:	ffffd097          	auipc	ra,0xffffd
    800050d6:	9a2080e7          	jalr	-1630(ra) # 80001a74 <proc_pagetable>
    800050da:	8baa                	mv	s7,a0
    800050dc:	d945                	beqz	a0,8000508c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050de:	e7042983          	lw	s3,-400(s0)
    800050e2:	e8845783          	lhu	a5,-376(s0)
    800050e6:	c7ad                	beqz	a5,80005150 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050e8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050ea:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800050ec:	6c85                	lui	s9,0x1
    800050ee:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800050f2:	def43823          	sd	a5,-528(s0)
    800050f6:	a42d                	j	80005320 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800050f8:	00003517          	auipc	a0,0x3
    800050fc:	7e850513          	addi	a0,a0,2024 # 800088e0 <syscall_arg+0x228>
    80005100:	ffffb097          	auipc	ra,0xffffb
    80005104:	43e080e7          	jalr	1086(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005108:	8756                	mv	a4,s5
    8000510a:	012d86bb          	addw	a3,s11,s2
    8000510e:	4581                	li	a1,0
    80005110:	8526                	mv	a0,s1
    80005112:	fffff097          	auipc	ra,0xfffff
    80005116:	cac080e7          	jalr	-852(ra) # 80003dbe <readi>
    8000511a:	2501                	sext.w	a0,a0
    8000511c:	1aaa9963          	bne	s5,a0,800052ce <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005120:	6785                	lui	a5,0x1
    80005122:	0127893b          	addw	s2,a5,s2
    80005126:	77fd                	lui	a5,0xfffff
    80005128:	01478a3b          	addw	s4,a5,s4
    8000512c:	1f897163          	bgeu	s2,s8,8000530e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005130:	02091593          	slli	a1,s2,0x20
    80005134:	9181                	srli	a1,a1,0x20
    80005136:	95ea                	add	a1,a1,s10
    80005138:	855e                	mv	a0,s7
    8000513a:	ffffc097          	auipc	ra,0xffffc
    8000513e:	f34080e7          	jalr	-204(ra) # 8000106e <walkaddr>
    80005142:	862a                	mv	a2,a0
    if(pa == 0)
    80005144:	d955                	beqz	a0,800050f8 <exec+0xf0>
      n = PGSIZE;
    80005146:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005148:	fd9a70e3          	bgeu	s4,s9,80005108 <exec+0x100>
      n = sz - i;
    8000514c:	8ad2                	mv	s5,s4
    8000514e:	bf6d                	j	80005108 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005150:	4901                	li	s2,0
  iunlockput(ip);
    80005152:	8526                	mv	a0,s1
    80005154:	fffff097          	auipc	ra,0xfffff
    80005158:	c18080e7          	jalr	-1000(ra) # 80003d6c <iunlockput>
  end_op();
    8000515c:	fffff097          	auipc	ra,0xfffff
    80005160:	400080e7          	jalr	1024(ra) # 8000455c <end_op>
  p = myproc();
    80005164:	ffffd097          	auipc	ra,0xffffd
    80005168:	84c080e7          	jalr	-1972(ra) # 800019b0 <myproc>
    8000516c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000516e:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    80005172:	6785                	lui	a5,0x1
    80005174:	17fd                	addi	a5,a5,-1
    80005176:	993e                	add	s2,s2,a5
    80005178:	757d                	lui	a0,0xfffff
    8000517a:	00a977b3          	and	a5,s2,a0
    8000517e:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005182:	6609                	lui	a2,0x2
    80005184:	963e                	add	a2,a2,a5
    80005186:	85be                	mv	a1,a5
    80005188:	855e                	mv	a0,s7
    8000518a:	ffffc097          	auipc	ra,0xffffc
    8000518e:	298080e7          	jalr	664(ra) # 80001422 <uvmalloc>
    80005192:	8b2a                	mv	s6,a0
  ip = 0;
    80005194:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005196:	12050c63          	beqz	a0,800052ce <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000519a:	75f9                	lui	a1,0xffffe
    8000519c:	95aa                	add	a1,a1,a0
    8000519e:	855e                	mv	a0,s7
    800051a0:	ffffc097          	auipc	ra,0xffffc
    800051a4:	4a0080e7          	jalr	1184(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800051a8:	7c7d                	lui	s8,0xfffff
    800051aa:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800051ac:	e0043783          	ld	a5,-512(s0)
    800051b0:	6388                	ld	a0,0(a5)
    800051b2:	c535                	beqz	a0,8000521e <exec+0x216>
    800051b4:	e9040993          	addi	s3,s0,-368
    800051b8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800051bc:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800051be:	ffffc097          	auipc	ra,0xffffc
    800051c2:	ca6080e7          	jalr	-858(ra) # 80000e64 <strlen>
    800051c6:	2505                	addiw	a0,a0,1
    800051c8:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051cc:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800051d0:	13896363          	bltu	s2,s8,800052f6 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051d4:	e0043d83          	ld	s11,-512(s0)
    800051d8:	000dba03          	ld	s4,0(s11)
    800051dc:	8552                	mv	a0,s4
    800051de:	ffffc097          	auipc	ra,0xffffc
    800051e2:	c86080e7          	jalr	-890(ra) # 80000e64 <strlen>
    800051e6:	0015069b          	addiw	a3,a0,1
    800051ea:	8652                	mv	a2,s4
    800051ec:	85ca                	mv	a1,s2
    800051ee:	855e                	mv	a0,s7
    800051f0:	ffffc097          	auipc	ra,0xffffc
    800051f4:	482080e7          	jalr	1154(ra) # 80001672 <copyout>
    800051f8:	10054363          	bltz	a0,800052fe <exec+0x2f6>
    ustack[argc] = sp;
    800051fc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005200:	0485                	addi	s1,s1,1
    80005202:	008d8793          	addi	a5,s11,8
    80005206:	e0f43023          	sd	a5,-512(s0)
    8000520a:	008db503          	ld	a0,8(s11)
    8000520e:	c911                	beqz	a0,80005222 <exec+0x21a>
    if(argc >= MAXARG)
    80005210:	09a1                	addi	s3,s3,8
    80005212:	fb3c96e3          	bne	s9,s3,800051be <exec+0x1b6>
  sz = sz1;
    80005216:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000521a:	4481                	li	s1,0
    8000521c:	a84d                	j	800052ce <exec+0x2c6>
  sp = sz;
    8000521e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005220:	4481                	li	s1,0
  ustack[argc] = 0;
    80005222:	00349793          	slli	a5,s1,0x3
    80005226:	f9040713          	addi	a4,s0,-112
    8000522a:	97ba                	add	a5,a5,a4
    8000522c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005230:	00148693          	addi	a3,s1,1
    80005234:	068e                	slli	a3,a3,0x3
    80005236:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000523a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000523e:	01897663          	bgeu	s2,s8,8000524a <exec+0x242>
  sz = sz1;
    80005242:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005246:	4481                	li	s1,0
    80005248:	a059                	j	800052ce <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000524a:	e9040613          	addi	a2,s0,-368
    8000524e:	85ca                	mv	a1,s2
    80005250:	855e                	mv	a0,s7
    80005252:	ffffc097          	auipc	ra,0xffffc
    80005256:	420080e7          	jalr	1056(ra) # 80001672 <copyout>
    8000525a:	0a054663          	bltz	a0,80005306 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000525e:	078ab783          	ld	a5,120(s5)
    80005262:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005266:	df843783          	ld	a5,-520(s0)
    8000526a:	0007c703          	lbu	a4,0(a5)
    8000526e:	cf11                	beqz	a4,8000528a <exec+0x282>
    80005270:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005272:	02f00693          	li	a3,47
    80005276:	a039                	j	80005284 <exec+0x27c>
      last = s+1;
    80005278:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000527c:	0785                	addi	a5,a5,1
    8000527e:	fff7c703          	lbu	a4,-1(a5)
    80005282:	c701                	beqz	a4,8000528a <exec+0x282>
    if(*s == '/')
    80005284:	fed71ce3          	bne	a4,a3,8000527c <exec+0x274>
    80005288:	bfc5                	j	80005278 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000528a:	4641                	li	a2,16
    8000528c:	df843583          	ld	a1,-520(s0)
    80005290:	178a8513          	addi	a0,s5,376
    80005294:	ffffc097          	auipc	ra,0xffffc
    80005298:	b9e080e7          	jalr	-1122(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000529c:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    800052a0:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    800052a4:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800052a8:	078ab783          	ld	a5,120(s5)
    800052ac:	e6843703          	ld	a4,-408(s0)
    800052b0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800052b2:	078ab783          	ld	a5,120(s5)
    800052b6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052ba:	85ea                	mv	a1,s10
    800052bc:	ffffd097          	auipc	ra,0xffffd
    800052c0:	854080e7          	jalr	-1964(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052c4:	0004851b          	sext.w	a0,s1
    800052c8:	bbe1                	j	800050a0 <exec+0x98>
    800052ca:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800052ce:	e0843583          	ld	a1,-504(s0)
    800052d2:	855e                	mv	a0,s7
    800052d4:	ffffd097          	auipc	ra,0xffffd
    800052d8:	83c080e7          	jalr	-1988(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    800052dc:	da0498e3          	bnez	s1,8000508c <exec+0x84>
  return -1;
    800052e0:	557d                	li	a0,-1
    800052e2:	bb7d                	j	800050a0 <exec+0x98>
    800052e4:	e1243423          	sd	s2,-504(s0)
    800052e8:	b7dd                	j	800052ce <exec+0x2c6>
    800052ea:	e1243423          	sd	s2,-504(s0)
    800052ee:	b7c5                	j	800052ce <exec+0x2c6>
    800052f0:	e1243423          	sd	s2,-504(s0)
    800052f4:	bfe9                	j	800052ce <exec+0x2c6>
  sz = sz1;
    800052f6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052fa:	4481                	li	s1,0
    800052fc:	bfc9                	j	800052ce <exec+0x2c6>
  sz = sz1;
    800052fe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005302:	4481                	li	s1,0
    80005304:	b7e9                	j	800052ce <exec+0x2c6>
  sz = sz1;
    80005306:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000530a:	4481                	li	s1,0
    8000530c:	b7c9                	j	800052ce <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000530e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005312:	2b05                	addiw	s6,s6,1
    80005314:	0389899b          	addiw	s3,s3,56
    80005318:	e8845783          	lhu	a5,-376(s0)
    8000531c:	e2fb5be3          	bge	s6,a5,80005152 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005320:	2981                	sext.w	s3,s3
    80005322:	03800713          	li	a4,56
    80005326:	86ce                	mv	a3,s3
    80005328:	e1840613          	addi	a2,s0,-488
    8000532c:	4581                	li	a1,0
    8000532e:	8526                	mv	a0,s1
    80005330:	fffff097          	auipc	ra,0xfffff
    80005334:	a8e080e7          	jalr	-1394(ra) # 80003dbe <readi>
    80005338:	03800793          	li	a5,56
    8000533c:	f8f517e3          	bne	a0,a5,800052ca <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005340:	e1842783          	lw	a5,-488(s0)
    80005344:	4705                	li	a4,1
    80005346:	fce796e3          	bne	a5,a4,80005312 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000534a:	e4043603          	ld	a2,-448(s0)
    8000534e:	e3843783          	ld	a5,-456(s0)
    80005352:	f8f669e3          	bltu	a2,a5,800052e4 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005356:	e2843783          	ld	a5,-472(s0)
    8000535a:	963e                	add	a2,a2,a5
    8000535c:	f8f667e3          	bltu	a2,a5,800052ea <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005360:	85ca                	mv	a1,s2
    80005362:	855e                	mv	a0,s7
    80005364:	ffffc097          	auipc	ra,0xffffc
    80005368:	0be080e7          	jalr	190(ra) # 80001422 <uvmalloc>
    8000536c:	e0a43423          	sd	a0,-504(s0)
    80005370:	d141                	beqz	a0,800052f0 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005372:	e2843d03          	ld	s10,-472(s0)
    80005376:	df043783          	ld	a5,-528(s0)
    8000537a:	00fd77b3          	and	a5,s10,a5
    8000537e:	fba1                	bnez	a5,800052ce <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005380:	e2042d83          	lw	s11,-480(s0)
    80005384:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005388:	f80c03e3          	beqz	s8,8000530e <exec+0x306>
    8000538c:	8a62                	mv	s4,s8
    8000538e:	4901                	li	s2,0
    80005390:	b345                	j	80005130 <exec+0x128>

0000000080005392 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005392:	7179                	addi	sp,sp,-48
    80005394:	f406                	sd	ra,40(sp)
    80005396:	f022                	sd	s0,32(sp)
    80005398:	ec26                	sd	s1,24(sp)
    8000539a:	e84a                	sd	s2,16(sp)
    8000539c:	1800                	addi	s0,sp,48
    8000539e:	892e                	mv	s2,a1
    800053a0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800053a2:	fdc40593          	addi	a1,s0,-36
    800053a6:	ffffe097          	auipc	ra,0xffffe
    800053aa:	a3e080e7          	jalr	-1474(ra) # 80002de4 <argint>
    800053ae:	04054063          	bltz	a0,800053ee <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053b2:	fdc42703          	lw	a4,-36(s0)
    800053b6:	47bd                	li	a5,15
    800053b8:	02e7ed63          	bltu	a5,a4,800053f2 <argfd+0x60>
    800053bc:	ffffc097          	auipc	ra,0xffffc
    800053c0:	5f4080e7          	jalr	1524(ra) # 800019b0 <myproc>
    800053c4:	fdc42703          	lw	a4,-36(s0)
    800053c8:	01e70793          	addi	a5,a4,30
    800053cc:	078e                	slli	a5,a5,0x3
    800053ce:	953e                	add	a0,a0,a5
    800053d0:	611c                	ld	a5,0(a0)
    800053d2:	c395                	beqz	a5,800053f6 <argfd+0x64>
    return -1;
  if(pfd)
    800053d4:	00090463          	beqz	s2,800053dc <argfd+0x4a>
    *pfd = fd;
    800053d8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800053dc:	4501                	li	a0,0
  if(pf)
    800053de:	c091                	beqz	s1,800053e2 <argfd+0x50>
    *pf = f;
    800053e0:	e09c                	sd	a5,0(s1)
}
    800053e2:	70a2                	ld	ra,40(sp)
    800053e4:	7402                	ld	s0,32(sp)
    800053e6:	64e2                	ld	s1,24(sp)
    800053e8:	6942                	ld	s2,16(sp)
    800053ea:	6145                	addi	sp,sp,48
    800053ec:	8082                	ret
    return -1;
    800053ee:	557d                	li	a0,-1
    800053f0:	bfcd                	j	800053e2 <argfd+0x50>
    return -1;
    800053f2:	557d                	li	a0,-1
    800053f4:	b7fd                	j	800053e2 <argfd+0x50>
    800053f6:	557d                	li	a0,-1
    800053f8:	b7ed                	j	800053e2 <argfd+0x50>

00000000800053fa <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800053fa:	1101                	addi	sp,sp,-32
    800053fc:	ec06                	sd	ra,24(sp)
    800053fe:	e822                	sd	s0,16(sp)
    80005400:	e426                	sd	s1,8(sp)
    80005402:	1000                	addi	s0,sp,32
    80005404:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005406:	ffffc097          	auipc	ra,0xffffc
    8000540a:	5aa080e7          	jalr	1450(ra) # 800019b0 <myproc>
    8000540e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005410:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    80005414:	4501                	li	a0,0
    80005416:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005418:	6398                	ld	a4,0(a5)
    8000541a:	cb19                	beqz	a4,80005430 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000541c:	2505                	addiw	a0,a0,1
    8000541e:	07a1                	addi	a5,a5,8
    80005420:	fed51ce3          	bne	a0,a3,80005418 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005424:	557d                	li	a0,-1
}
    80005426:	60e2                	ld	ra,24(sp)
    80005428:	6442                	ld	s0,16(sp)
    8000542a:	64a2                	ld	s1,8(sp)
    8000542c:	6105                	addi	sp,sp,32
    8000542e:	8082                	ret
      p->ofile[fd] = f;
    80005430:	01e50793          	addi	a5,a0,30
    80005434:	078e                	slli	a5,a5,0x3
    80005436:	963e                	add	a2,a2,a5
    80005438:	e204                	sd	s1,0(a2)
      return fd;
    8000543a:	b7f5                	j	80005426 <fdalloc+0x2c>

000000008000543c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000543c:	715d                	addi	sp,sp,-80
    8000543e:	e486                	sd	ra,72(sp)
    80005440:	e0a2                	sd	s0,64(sp)
    80005442:	fc26                	sd	s1,56(sp)
    80005444:	f84a                	sd	s2,48(sp)
    80005446:	f44e                	sd	s3,40(sp)
    80005448:	f052                	sd	s4,32(sp)
    8000544a:	ec56                	sd	s5,24(sp)
    8000544c:	0880                	addi	s0,sp,80
    8000544e:	89ae                	mv	s3,a1
    80005450:	8ab2                	mv	s5,a2
    80005452:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005454:	fb040593          	addi	a1,s0,-80
    80005458:	fffff097          	auipc	ra,0xfffff
    8000545c:	e86080e7          	jalr	-378(ra) # 800042de <nameiparent>
    80005460:	892a                	mv	s2,a0
    80005462:	12050f63          	beqz	a0,800055a0 <create+0x164>
    return 0;

  ilock(dp);
    80005466:	ffffe097          	auipc	ra,0xffffe
    8000546a:	6a4080e7          	jalr	1700(ra) # 80003b0a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000546e:	4601                	li	a2,0
    80005470:	fb040593          	addi	a1,s0,-80
    80005474:	854a                	mv	a0,s2
    80005476:	fffff097          	auipc	ra,0xfffff
    8000547a:	b78080e7          	jalr	-1160(ra) # 80003fee <dirlookup>
    8000547e:	84aa                	mv	s1,a0
    80005480:	c921                	beqz	a0,800054d0 <create+0x94>
    iunlockput(dp);
    80005482:	854a                	mv	a0,s2
    80005484:	fffff097          	auipc	ra,0xfffff
    80005488:	8e8080e7          	jalr	-1816(ra) # 80003d6c <iunlockput>
    ilock(ip);
    8000548c:	8526                	mv	a0,s1
    8000548e:	ffffe097          	auipc	ra,0xffffe
    80005492:	67c080e7          	jalr	1660(ra) # 80003b0a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005496:	2981                	sext.w	s3,s3
    80005498:	4789                	li	a5,2
    8000549a:	02f99463          	bne	s3,a5,800054c2 <create+0x86>
    8000549e:	0444d783          	lhu	a5,68(s1)
    800054a2:	37f9                	addiw	a5,a5,-2
    800054a4:	17c2                	slli	a5,a5,0x30
    800054a6:	93c1                	srli	a5,a5,0x30
    800054a8:	4705                	li	a4,1
    800054aa:	00f76c63          	bltu	a4,a5,800054c2 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800054ae:	8526                	mv	a0,s1
    800054b0:	60a6                	ld	ra,72(sp)
    800054b2:	6406                	ld	s0,64(sp)
    800054b4:	74e2                	ld	s1,56(sp)
    800054b6:	7942                	ld	s2,48(sp)
    800054b8:	79a2                	ld	s3,40(sp)
    800054ba:	7a02                	ld	s4,32(sp)
    800054bc:	6ae2                	ld	s5,24(sp)
    800054be:	6161                	addi	sp,sp,80
    800054c0:	8082                	ret
    iunlockput(ip);
    800054c2:	8526                	mv	a0,s1
    800054c4:	fffff097          	auipc	ra,0xfffff
    800054c8:	8a8080e7          	jalr	-1880(ra) # 80003d6c <iunlockput>
    return 0;
    800054cc:	4481                	li	s1,0
    800054ce:	b7c5                	j	800054ae <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800054d0:	85ce                	mv	a1,s3
    800054d2:	00092503          	lw	a0,0(s2)
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	49c080e7          	jalr	1180(ra) # 80003972 <ialloc>
    800054de:	84aa                	mv	s1,a0
    800054e0:	c529                	beqz	a0,8000552a <create+0xee>
  ilock(ip);
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	628080e7          	jalr	1576(ra) # 80003b0a <ilock>
  ip->major = major;
    800054ea:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800054ee:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800054f2:	4785                	li	a5,1
    800054f4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054f8:	8526                	mv	a0,s1
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	546080e7          	jalr	1350(ra) # 80003a40 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005502:	2981                	sext.w	s3,s3
    80005504:	4785                	li	a5,1
    80005506:	02f98a63          	beq	s3,a5,8000553a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000550a:	40d0                	lw	a2,4(s1)
    8000550c:	fb040593          	addi	a1,s0,-80
    80005510:	854a                	mv	a0,s2
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	cec080e7          	jalr	-788(ra) # 800041fe <dirlink>
    8000551a:	06054b63          	bltz	a0,80005590 <create+0x154>
  iunlockput(dp);
    8000551e:	854a                	mv	a0,s2
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	84c080e7          	jalr	-1972(ra) # 80003d6c <iunlockput>
  return ip;
    80005528:	b759                	j	800054ae <create+0x72>
    panic("create: ialloc");
    8000552a:	00003517          	auipc	a0,0x3
    8000552e:	3d650513          	addi	a0,a0,982 # 80008900 <syscall_arg+0x248>
    80005532:	ffffb097          	auipc	ra,0xffffb
    80005536:	00c080e7          	jalr	12(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000553a:	04a95783          	lhu	a5,74(s2)
    8000553e:	2785                	addiw	a5,a5,1
    80005540:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005544:	854a                	mv	a0,s2
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	4fa080e7          	jalr	1274(ra) # 80003a40 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000554e:	40d0                	lw	a2,4(s1)
    80005550:	00003597          	auipc	a1,0x3
    80005554:	3c058593          	addi	a1,a1,960 # 80008910 <syscall_arg+0x258>
    80005558:	8526                	mv	a0,s1
    8000555a:	fffff097          	auipc	ra,0xfffff
    8000555e:	ca4080e7          	jalr	-860(ra) # 800041fe <dirlink>
    80005562:	00054f63          	bltz	a0,80005580 <create+0x144>
    80005566:	00492603          	lw	a2,4(s2)
    8000556a:	00003597          	auipc	a1,0x3
    8000556e:	3ae58593          	addi	a1,a1,942 # 80008918 <syscall_arg+0x260>
    80005572:	8526                	mv	a0,s1
    80005574:	fffff097          	auipc	ra,0xfffff
    80005578:	c8a080e7          	jalr	-886(ra) # 800041fe <dirlink>
    8000557c:	f80557e3          	bgez	a0,8000550a <create+0xce>
      panic("create dots");
    80005580:	00003517          	auipc	a0,0x3
    80005584:	3a050513          	addi	a0,a0,928 # 80008920 <syscall_arg+0x268>
    80005588:	ffffb097          	auipc	ra,0xffffb
    8000558c:	fb6080e7          	jalr	-74(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005590:	00003517          	auipc	a0,0x3
    80005594:	3a050513          	addi	a0,a0,928 # 80008930 <syscall_arg+0x278>
    80005598:	ffffb097          	auipc	ra,0xffffb
    8000559c:	fa6080e7          	jalr	-90(ra) # 8000053e <panic>
    return 0;
    800055a0:	84aa                	mv	s1,a0
    800055a2:	b731                	j	800054ae <create+0x72>

00000000800055a4 <sys_dup>:
{
    800055a4:	7179                	addi	sp,sp,-48
    800055a6:	f406                	sd	ra,40(sp)
    800055a8:	f022                	sd	s0,32(sp)
    800055aa:	ec26                	sd	s1,24(sp)
    800055ac:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800055ae:	fd840613          	addi	a2,s0,-40
    800055b2:	4581                	li	a1,0
    800055b4:	4501                	li	a0,0
    800055b6:	00000097          	auipc	ra,0x0
    800055ba:	ddc080e7          	jalr	-548(ra) # 80005392 <argfd>
    return -1;
    800055be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800055c0:	02054363          	bltz	a0,800055e6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800055c4:	fd843503          	ld	a0,-40(s0)
    800055c8:	00000097          	auipc	ra,0x0
    800055cc:	e32080e7          	jalr	-462(ra) # 800053fa <fdalloc>
    800055d0:	84aa                	mv	s1,a0
    return -1;
    800055d2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800055d4:	00054963          	bltz	a0,800055e6 <sys_dup+0x42>
  filedup(f);
    800055d8:	fd843503          	ld	a0,-40(s0)
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	37a080e7          	jalr	890(ra) # 80004956 <filedup>
  return fd;
    800055e4:	87a6                	mv	a5,s1
}
    800055e6:	853e                	mv	a0,a5
    800055e8:	70a2                	ld	ra,40(sp)
    800055ea:	7402                	ld	s0,32(sp)
    800055ec:	64e2                	ld	s1,24(sp)
    800055ee:	6145                	addi	sp,sp,48
    800055f0:	8082                	ret

00000000800055f2 <sys_read>:
{
    800055f2:	7179                	addi	sp,sp,-48
    800055f4:	f406                	sd	ra,40(sp)
    800055f6:	f022                	sd	s0,32(sp)
    800055f8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055fa:	fe840613          	addi	a2,s0,-24
    800055fe:	4581                	li	a1,0
    80005600:	4501                	li	a0,0
    80005602:	00000097          	auipc	ra,0x0
    80005606:	d90080e7          	jalr	-624(ra) # 80005392 <argfd>
    return -1;
    8000560a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000560c:	04054163          	bltz	a0,8000564e <sys_read+0x5c>
    80005610:	fe440593          	addi	a1,s0,-28
    80005614:	4509                	li	a0,2
    80005616:	ffffd097          	auipc	ra,0xffffd
    8000561a:	7ce080e7          	jalr	1998(ra) # 80002de4 <argint>
    return -1;
    8000561e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005620:	02054763          	bltz	a0,8000564e <sys_read+0x5c>
    80005624:	fd840593          	addi	a1,s0,-40
    80005628:	4505                	li	a0,1
    8000562a:	ffffd097          	auipc	ra,0xffffd
    8000562e:	7dc080e7          	jalr	2012(ra) # 80002e06 <argaddr>
    return -1;
    80005632:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005634:	00054d63          	bltz	a0,8000564e <sys_read+0x5c>
  return fileread(f, p, n);
    80005638:	fe442603          	lw	a2,-28(s0)
    8000563c:	fd843583          	ld	a1,-40(s0)
    80005640:	fe843503          	ld	a0,-24(s0)
    80005644:	fffff097          	auipc	ra,0xfffff
    80005648:	49e080e7          	jalr	1182(ra) # 80004ae2 <fileread>
    8000564c:	87aa                	mv	a5,a0
}
    8000564e:	853e                	mv	a0,a5
    80005650:	70a2                	ld	ra,40(sp)
    80005652:	7402                	ld	s0,32(sp)
    80005654:	6145                	addi	sp,sp,48
    80005656:	8082                	ret

0000000080005658 <sys_write>:
{
    80005658:	7179                	addi	sp,sp,-48
    8000565a:	f406                	sd	ra,40(sp)
    8000565c:	f022                	sd	s0,32(sp)
    8000565e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005660:	fe840613          	addi	a2,s0,-24
    80005664:	4581                	li	a1,0
    80005666:	4501                	li	a0,0
    80005668:	00000097          	auipc	ra,0x0
    8000566c:	d2a080e7          	jalr	-726(ra) # 80005392 <argfd>
    return -1;
    80005670:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005672:	04054163          	bltz	a0,800056b4 <sys_write+0x5c>
    80005676:	fe440593          	addi	a1,s0,-28
    8000567a:	4509                	li	a0,2
    8000567c:	ffffd097          	auipc	ra,0xffffd
    80005680:	768080e7          	jalr	1896(ra) # 80002de4 <argint>
    return -1;
    80005684:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005686:	02054763          	bltz	a0,800056b4 <sys_write+0x5c>
    8000568a:	fd840593          	addi	a1,s0,-40
    8000568e:	4505                	li	a0,1
    80005690:	ffffd097          	auipc	ra,0xffffd
    80005694:	776080e7          	jalr	1910(ra) # 80002e06 <argaddr>
    return -1;
    80005698:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000569a:	00054d63          	bltz	a0,800056b4 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000569e:	fe442603          	lw	a2,-28(s0)
    800056a2:	fd843583          	ld	a1,-40(s0)
    800056a6:	fe843503          	ld	a0,-24(s0)
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	4fa080e7          	jalr	1274(ra) # 80004ba4 <filewrite>
    800056b2:	87aa                	mv	a5,a0
}
    800056b4:	853e                	mv	a0,a5
    800056b6:	70a2                	ld	ra,40(sp)
    800056b8:	7402                	ld	s0,32(sp)
    800056ba:	6145                	addi	sp,sp,48
    800056bc:	8082                	ret

00000000800056be <sys_close>:
{
    800056be:	1101                	addi	sp,sp,-32
    800056c0:	ec06                	sd	ra,24(sp)
    800056c2:	e822                	sd	s0,16(sp)
    800056c4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800056c6:	fe040613          	addi	a2,s0,-32
    800056ca:	fec40593          	addi	a1,s0,-20
    800056ce:	4501                	li	a0,0
    800056d0:	00000097          	auipc	ra,0x0
    800056d4:	cc2080e7          	jalr	-830(ra) # 80005392 <argfd>
    return -1;
    800056d8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800056da:	02054463          	bltz	a0,80005702 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800056de:	ffffc097          	auipc	ra,0xffffc
    800056e2:	2d2080e7          	jalr	722(ra) # 800019b0 <myproc>
    800056e6:	fec42783          	lw	a5,-20(s0)
    800056ea:	07f9                	addi	a5,a5,30
    800056ec:	078e                	slli	a5,a5,0x3
    800056ee:	97aa                	add	a5,a5,a0
    800056f0:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800056f4:	fe043503          	ld	a0,-32(s0)
    800056f8:	fffff097          	auipc	ra,0xfffff
    800056fc:	2b0080e7          	jalr	688(ra) # 800049a8 <fileclose>
  return 0;
    80005700:	4781                	li	a5,0
}
    80005702:	853e                	mv	a0,a5
    80005704:	60e2                	ld	ra,24(sp)
    80005706:	6442                	ld	s0,16(sp)
    80005708:	6105                	addi	sp,sp,32
    8000570a:	8082                	ret

000000008000570c <sys_fstat>:
{
    8000570c:	1101                	addi	sp,sp,-32
    8000570e:	ec06                	sd	ra,24(sp)
    80005710:	e822                	sd	s0,16(sp)
    80005712:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005714:	fe840613          	addi	a2,s0,-24
    80005718:	4581                	li	a1,0
    8000571a:	4501                	li	a0,0
    8000571c:	00000097          	auipc	ra,0x0
    80005720:	c76080e7          	jalr	-906(ra) # 80005392 <argfd>
    return -1;
    80005724:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005726:	02054563          	bltz	a0,80005750 <sys_fstat+0x44>
    8000572a:	fe040593          	addi	a1,s0,-32
    8000572e:	4505                	li	a0,1
    80005730:	ffffd097          	auipc	ra,0xffffd
    80005734:	6d6080e7          	jalr	1750(ra) # 80002e06 <argaddr>
    return -1;
    80005738:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000573a:	00054b63          	bltz	a0,80005750 <sys_fstat+0x44>
  return filestat(f, st);
    8000573e:	fe043583          	ld	a1,-32(s0)
    80005742:	fe843503          	ld	a0,-24(s0)
    80005746:	fffff097          	auipc	ra,0xfffff
    8000574a:	32a080e7          	jalr	810(ra) # 80004a70 <filestat>
    8000574e:	87aa                	mv	a5,a0
}
    80005750:	853e                	mv	a0,a5
    80005752:	60e2                	ld	ra,24(sp)
    80005754:	6442                	ld	s0,16(sp)
    80005756:	6105                	addi	sp,sp,32
    80005758:	8082                	ret

000000008000575a <sys_link>:
{
    8000575a:	7169                	addi	sp,sp,-304
    8000575c:	f606                	sd	ra,296(sp)
    8000575e:	f222                	sd	s0,288(sp)
    80005760:	ee26                	sd	s1,280(sp)
    80005762:	ea4a                	sd	s2,272(sp)
    80005764:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005766:	08000613          	li	a2,128
    8000576a:	ed040593          	addi	a1,s0,-304
    8000576e:	4501                	li	a0,0
    80005770:	ffffd097          	auipc	ra,0xffffd
    80005774:	6b8080e7          	jalr	1720(ra) # 80002e28 <argstr>
    return -1;
    80005778:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000577a:	10054e63          	bltz	a0,80005896 <sys_link+0x13c>
    8000577e:	08000613          	li	a2,128
    80005782:	f5040593          	addi	a1,s0,-176
    80005786:	4505                	li	a0,1
    80005788:	ffffd097          	auipc	ra,0xffffd
    8000578c:	6a0080e7          	jalr	1696(ra) # 80002e28 <argstr>
    return -1;
    80005790:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005792:	10054263          	bltz	a0,80005896 <sys_link+0x13c>
  begin_op();
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	d46080e7          	jalr	-698(ra) # 800044dc <begin_op>
  if((ip = namei(old)) == 0){
    8000579e:	ed040513          	addi	a0,s0,-304
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	b1e080e7          	jalr	-1250(ra) # 800042c0 <namei>
    800057aa:	84aa                	mv	s1,a0
    800057ac:	c551                	beqz	a0,80005838 <sys_link+0xde>
  ilock(ip);
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	35c080e7          	jalr	860(ra) # 80003b0a <ilock>
  if(ip->type == T_DIR){
    800057b6:	04449703          	lh	a4,68(s1)
    800057ba:	4785                	li	a5,1
    800057bc:	08f70463          	beq	a4,a5,80005844 <sys_link+0xea>
  ip->nlink++;
    800057c0:	04a4d783          	lhu	a5,74(s1)
    800057c4:	2785                	addiw	a5,a5,1
    800057c6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057ca:	8526                	mv	a0,s1
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	274080e7          	jalr	628(ra) # 80003a40 <iupdate>
  iunlock(ip);
    800057d4:	8526                	mv	a0,s1
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	3f6080e7          	jalr	1014(ra) # 80003bcc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800057de:	fd040593          	addi	a1,s0,-48
    800057e2:	f5040513          	addi	a0,s0,-176
    800057e6:	fffff097          	auipc	ra,0xfffff
    800057ea:	af8080e7          	jalr	-1288(ra) # 800042de <nameiparent>
    800057ee:	892a                	mv	s2,a0
    800057f0:	c935                	beqz	a0,80005864 <sys_link+0x10a>
  ilock(dp);
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	318080e7          	jalr	792(ra) # 80003b0a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800057fa:	00092703          	lw	a4,0(s2)
    800057fe:	409c                	lw	a5,0(s1)
    80005800:	04f71d63          	bne	a4,a5,8000585a <sys_link+0x100>
    80005804:	40d0                	lw	a2,4(s1)
    80005806:	fd040593          	addi	a1,s0,-48
    8000580a:	854a                	mv	a0,s2
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	9f2080e7          	jalr	-1550(ra) # 800041fe <dirlink>
    80005814:	04054363          	bltz	a0,8000585a <sys_link+0x100>
  iunlockput(dp);
    80005818:	854a                	mv	a0,s2
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	552080e7          	jalr	1362(ra) # 80003d6c <iunlockput>
  iput(ip);
    80005822:	8526                	mv	a0,s1
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	4a0080e7          	jalr	1184(ra) # 80003cc4 <iput>
  end_op();
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	d30080e7          	jalr	-720(ra) # 8000455c <end_op>
  return 0;
    80005834:	4781                	li	a5,0
    80005836:	a085                	j	80005896 <sys_link+0x13c>
    end_op();
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	d24080e7          	jalr	-732(ra) # 8000455c <end_op>
    return -1;
    80005840:	57fd                	li	a5,-1
    80005842:	a891                	j	80005896 <sys_link+0x13c>
    iunlockput(ip);
    80005844:	8526                	mv	a0,s1
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	526080e7          	jalr	1318(ra) # 80003d6c <iunlockput>
    end_op();
    8000584e:	fffff097          	auipc	ra,0xfffff
    80005852:	d0e080e7          	jalr	-754(ra) # 8000455c <end_op>
    return -1;
    80005856:	57fd                	li	a5,-1
    80005858:	a83d                	j	80005896 <sys_link+0x13c>
    iunlockput(dp);
    8000585a:	854a                	mv	a0,s2
    8000585c:	ffffe097          	auipc	ra,0xffffe
    80005860:	510080e7          	jalr	1296(ra) # 80003d6c <iunlockput>
  ilock(ip);
    80005864:	8526                	mv	a0,s1
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	2a4080e7          	jalr	676(ra) # 80003b0a <ilock>
  ip->nlink--;
    8000586e:	04a4d783          	lhu	a5,74(s1)
    80005872:	37fd                	addiw	a5,a5,-1
    80005874:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005878:	8526                	mv	a0,s1
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	1c6080e7          	jalr	454(ra) # 80003a40 <iupdate>
  iunlockput(ip);
    80005882:	8526                	mv	a0,s1
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	4e8080e7          	jalr	1256(ra) # 80003d6c <iunlockput>
  end_op();
    8000588c:	fffff097          	auipc	ra,0xfffff
    80005890:	cd0080e7          	jalr	-816(ra) # 8000455c <end_op>
  return -1;
    80005894:	57fd                	li	a5,-1
}
    80005896:	853e                	mv	a0,a5
    80005898:	70b2                	ld	ra,296(sp)
    8000589a:	7412                	ld	s0,288(sp)
    8000589c:	64f2                	ld	s1,280(sp)
    8000589e:	6952                	ld	s2,272(sp)
    800058a0:	6155                	addi	sp,sp,304
    800058a2:	8082                	ret

00000000800058a4 <sys_unlink>:
{
    800058a4:	7151                	addi	sp,sp,-240
    800058a6:	f586                	sd	ra,232(sp)
    800058a8:	f1a2                	sd	s0,224(sp)
    800058aa:	eda6                	sd	s1,216(sp)
    800058ac:	e9ca                	sd	s2,208(sp)
    800058ae:	e5ce                	sd	s3,200(sp)
    800058b0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058b2:	08000613          	li	a2,128
    800058b6:	f3040593          	addi	a1,s0,-208
    800058ba:	4501                	li	a0,0
    800058bc:	ffffd097          	auipc	ra,0xffffd
    800058c0:	56c080e7          	jalr	1388(ra) # 80002e28 <argstr>
    800058c4:	18054163          	bltz	a0,80005a46 <sys_unlink+0x1a2>
  begin_op();
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	c14080e7          	jalr	-1004(ra) # 800044dc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800058d0:	fb040593          	addi	a1,s0,-80
    800058d4:	f3040513          	addi	a0,s0,-208
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	a06080e7          	jalr	-1530(ra) # 800042de <nameiparent>
    800058e0:	84aa                	mv	s1,a0
    800058e2:	c979                	beqz	a0,800059b8 <sys_unlink+0x114>
  ilock(dp);
    800058e4:	ffffe097          	auipc	ra,0xffffe
    800058e8:	226080e7          	jalr	550(ra) # 80003b0a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800058ec:	00003597          	auipc	a1,0x3
    800058f0:	02458593          	addi	a1,a1,36 # 80008910 <syscall_arg+0x258>
    800058f4:	fb040513          	addi	a0,s0,-80
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	6dc080e7          	jalr	1756(ra) # 80003fd4 <namecmp>
    80005900:	14050a63          	beqz	a0,80005a54 <sys_unlink+0x1b0>
    80005904:	00003597          	auipc	a1,0x3
    80005908:	01458593          	addi	a1,a1,20 # 80008918 <syscall_arg+0x260>
    8000590c:	fb040513          	addi	a0,s0,-80
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	6c4080e7          	jalr	1732(ra) # 80003fd4 <namecmp>
    80005918:	12050e63          	beqz	a0,80005a54 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000591c:	f2c40613          	addi	a2,s0,-212
    80005920:	fb040593          	addi	a1,s0,-80
    80005924:	8526                	mv	a0,s1
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	6c8080e7          	jalr	1736(ra) # 80003fee <dirlookup>
    8000592e:	892a                	mv	s2,a0
    80005930:	12050263          	beqz	a0,80005a54 <sys_unlink+0x1b0>
  ilock(ip);
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	1d6080e7          	jalr	470(ra) # 80003b0a <ilock>
  if(ip->nlink < 1)
    8000593c:	04a91783          	lh	a5,74(s2)
    80005940:	08f05263          	blez	a5,800059c4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005944:	04491703          	lh	a4,68(s2)
    80005948:	4785                	li	a5,1
    8000594a:	08f70563          	beq	a4,a5,800059d4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000594e:	4641                	li	a2,16
    80005950:	4581                	li	a1,0
    80005952:	fc040513          	addi	a0,s0,-64
    80005956:	ffffb097          	auipc	ra,0xffffb
    8000595a:	38a080e7          	jalr	906(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000595e:	4741                	li	a4,16
    80005960:	f2c42683          	lw	a3,-212(s0)
    80005964:	fc040613          	addi	a2,s0,-64
    80005968:	4581                	li	a1,0
    8000596a:	8526                	mv	a0,s1
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	54a080e7          	jalr	1354(ra) # 80003eb6 <writei>
    80005974:	47c1                	li	a5,16
    80005976:	0af51563          	bne	a0,a5,80005a20 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000597a:	04491703          	lh	a4,68(s2)
    8000597e:	4785                	li	a5,1
    80005980:	0af70863          	beq	a4,a5,80005a30 <sys_unlink+0x18c>
  iunlockput(dp);
    80005984:	8526                	mv	a0,s1
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	3e6080e7          	jalr	998(ra) # 80003d6c <iunlockput>
  ip->nlink--;
    8000598e:	04a95783          	lhu	a5,74(s2)
    80005992:	37fd                	addiw	a5,a5,-1
    80005994:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005998:	854a                	mv	a0,s2
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	0a6080e7          	jalr	166(ra) # 80003a40 <iupdate>
  iunlockput(ip);
    800059a2:	854a                	mv	a0,s2
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	3c8080e7          	jalr	968(ra) # 80003d6c <iunlockput>
  end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	bb0080e7          	jalr	-1104(ra) # 8000455c <end_op>
  return 0;
    800059b4:	4501                	li	a0,0
    800059b6:	a84d                	j	80005a68 <sys_unlink+0x1c4>
    end_op();
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	ba4080e7          	jalr	-1116(ra) # 8000455c <end_op>
    return -1;
    800059c0:	557d                	li	a0,-1
    800059c2:	a05d                	j	80005a68 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059c4:	00003517          	auipc	a0,0x3
    800059c8:	f7c50513          	addi	a0,a0,-132 # 80008940 <syscall_arg+0x288>
    800059cc:	ffffb097          	auipc	ra,0xffffb
    800059d0:	b72080e7          	jalr	-1166(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059d4:	04c92703          	lw	a4,76(s2)
    800059d8:	02000793          	li	a5,32
    800059dc:	f6e7f9e3          	bgeu	a5,a4,8000594e <sys_unlink+0xaa>
    800059e0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059e4:	4741                	li	a4,16
    800059e6:	86ce                	mv	a3,s3
    800059e8:	f1840613          	addi	a2,s0,-232
    800059ec:	4581                	li	a1,0
    800059ee:	854a                	mv	a0,s2
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	3ce080e7          	jalr	974(ra) # 80003dbe <readi>
    800059f8:	47c1                	li	a5,16
    800059fa:	00f51b63          	bne	a0,a5,80005a10 <sys_unlink+0x16c>
    if(de.inum != 0)
    800059fe:	f1845783          	lhu	a5,-232(s0)
    80005a02:	e7a1                	bnez	a5,80005a4a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a04:	29c1                	addiw	s3,s3,16
    80005a06:	04c92783          	lw	a5,76(s2)
    80005a0a:	fcf9ede3          	bltu	s3,a5,800059e4 <sys_unlink+0x140>
    80005a0e:	b781                	j	8000594e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a10:	00003517          	auipc	a0,0x3
    80005a14:	f4850513          	addi	a0,a0,-184 # 80008958 <syscall_arg+0x2a0>
    80005a18:	ffffb097          	auipc	ra,0xffffb
    80005a1c:	b26080e7          	jalr	-1242(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005a20:	00003517          	auipc	a0,0x3
    80005a24:	f5050513          	addi	a0,a0,-176 # 80008970 <syscall_arg+0x2b8>
    80005a28:	ffffb097          	auipc	ra,0xffffb
    80005a2c:	b16080e7          	jalr	-1258(ra) # 8000053e <panic>
    dp->nlink--;
    80005a30:	04a4d783          	lhu	a5,74(s1)
    80005a34:	37fd                	addiw	a5,a5,-1
    80005a36:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a3a:	8526                	mv	a0,s1
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	004080e7          	jalr	4(ra) # 80003a40 <iupdate>
    80005a44:	b781                	j	80005984 <sys_unlink+0xe0>
    return -1;
    80005a46:	557d                	li	a0,-1
    80005a48:	a005                	j	80005a68 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a4a:	854a                	mv	a0,s2
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	320080e7          	jalr	800(ra) # 80003d6c <iunlockput>
  iunlockput(dp);
    80005a54:	8526                	mv	a0,s1
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	316080e7          	jalr	790(ra) # 80003d6c <iunlockput>
  end_op();
    80005a5e:	fffff097          	auipc	ra,0xfffff
    80005a62:	afe080e7          	jalr	-1282(ra) # 8000455c <end_op>
  return -1;
    80005a66:	557d                	li	a0,-1
}
    80005a68:	70ae                	ld	ra,232(sp)
    80005a6a:	740e                	ld	s0,224(sp)
    80005a6c:	64ee                	ld	s1,216(sp)
    80005a6e:	694e                	ld	s2,208(sp)
    80005a70:	69ae                	ld	s3,200(sp)
    80005a72:	616d                	addi	sp,sp,240
    80005a74:	8082                	ret

0000000080005a76 <sys_open>:

uint64
sys_open(void)
{
    80005a76:	7131                	addi	sp,sp,-192
    80005a78:	fd06                	sd	ra,184(sp)
    80005a7a:	f922                	sd	s0,176(sp)
    80005a7c:	f526                	sd	s1,168(sp)
    80005a7e:	f14a                	sd	s2,160(sp)
    80005a80:	ed4e                	sd	s3,152(sp)
    80005a82:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a84:	08000613          	li	a2,128
    80005a88:	f5040593          	addi	a1,s0,-176
    80005a8c:	4501                	li	a0,0
    80005a8e:	ffffd097          	auipc	ra,0xffffd
    80005a92:	39a080e7          	jalr	922(ra) # 80002e28 <argstr>
    return -1;
    80005a96:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a98:	0c054163          	bltz	a0,80005b5a <sys_open+0xe4>
    80005a9c:	f4c40593          	addi	a1,s0,-180
    80005aa0:	4505                	li	a0,1
    80005aa2:	ffffd097          	auipc	ra,0xffffd
    80005aa6:	342080e7          	jalr	834(ra) # 80002de4 <argint>
    80005aaa:	0a054863          	bltz	a0,80005b5a <sys_open+0xe4>

  begin_op();
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	a2e080e7          	jalr	-1490(ra) # 800044dc <begin_op>

  if(omode & O_CREATE){
    80005ab6:	f4c42783          	lw	a5,-180(s0)
    80005aba:	2007f793          	andi	a5,a5,512
    80005abe:	cbdd                	beqz	a5,80005b74 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ac0:	4681                	li	a3,0
    80005ac2:	4601                	li	a2,0
    80005ac4:	4589                	li	a1,2
    80005ac6:	f5040513          	addi	a0,s0,-176
    80005aca:	00000097          	auipc	ra,0x0
    80005ace:	972080e7          	jalr	-1678(ra) # 8000543c <create>
    80005ad2:	892a                	mv	s2,a0
    if(ip == 0){
    80005ad4:	c959                	beqz	a0,80005b6a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ad6:	04491703          	lh	a4,68(s2)
    80005ada:	478d                	li	a5,3
    80005adc:	00f71763          	bne	a4,a5,80005aea <sys_open+0x74>
    80005ae0:	04695703          	lhu	a4,70(s2)
    80005ae4:	47a5                	li	a5,9
    80005ae6:	0ce7ec63          	bltu	a5,a4,80005bbe <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	e02080e7          	jalr	-510(ra) # 800048ec <filealloc>
    80005af2:	89aa                	mv	s3,a0
    80005af4:	10050263          	beqz	a0,80005bf8 <sys_open+0x182>
    80005af8:	00000097          	auipc	ra,0x0
    80005afc:	902080e7          	jalr	-1790(ra) # 800053fa <fdalloc>
    80005b00:	84aa                	mv	s1,a0
    80005b02:	0e054663          	bltz	a0,80005bee <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b06:	04491703          	lh	a4,68(s2)
    80005b0a:	478d                	li	a5,3
    80005b0c:	0cf70463          	beq	a4,a5,80005bd4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b10:	4789                	li	a5,2
    80005b12:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b16:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b1a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b1e:	f4c42783          	lw	a5,-180(s0)
    80005b22:	0017c713          	xori	a4,a5,1
    80005b26:	8b05                	andi	a4,a4,1
    80005b28:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b2c:	0037f713          	andi	a4,a5,3
    80005b30:	00e03733          	snez	a4,a4
    80005b34:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b38:	4007f793          	andi	a5,a5,1024
    80005b3c:	c791                	beqz	a5,80005b48 <sys_open+0xd2>
    80005b3e:	04491703          	lh	a4,68(s2)
    80005b42:	4789                	li	a5,2
    80005b44:	08f70f63          	beq	a4,a5,80005be2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b48:	854a                	mv	a0,s2
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	082080e7          	jalr	130(ra) # 80003bcc <iunlock>
  end_op();
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	a0a080e7          	jalr	-1526(ra) # 8000455c <end_op>

  return fd;
}
    80005b5a:	8526                	mv	a0,s1
    80005b5c:	70ea                	ld	ra,184(sp)
    80005b5e:	744a                	ld	s0,176(sp)
    80005b60:	74aa                	ld	s1,168(sp)
    80005b62:	790a                	ld	s2,160(sp)
    80005b64:	69ea                	ld	s3,152(sp)
    80005b66:	6129                	addi	sp,sp,192
    80005b68:	8082                	ret
      end_op();
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	9f2080e7          	jalr	-1550(ra) # 8000455c <end_op>
      return -1;
    80005b72:	b7e5                	j	80005b5a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b74:	f5040513          	addi	a0,s0,-176
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	748080e7          	jalr	1864(ra) # 800042c0 <namei>
    80005b80:	892a                	mv	s2,a0
    80005b82:	c905                	beqz	a0,80005bb2 <sys_open+0x13c>
    ilock(ip);
    80005b84:	ffffe097          	auipc	ra,0xffffe
    80005b88:	f86080e7          	jalr	-122(ra) # 80003b0a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b8c:	04491703          	lh	a4,68(s2)
    80005b90:	4785                	li	a5,1
    80005b92:	f4f712e3          	bne	a4,a5,80005ad6 <sys_open+0x60>
    80005b96:	f4c42783          	lw	a5,-180(s0)
    80005b9a:	dba1                	beqz	a5,80005aea <sys_open+0x74>
      iunlockput(ip);
    80005b9c:	854a                	mv	a0,s2
    80005b9e:	ffffe097          	auipc	ra,0xffffe
    80005ba2:	1ce080e7          	jalr	462(ra) # 80003d6c <iunlockput>
      end_op();
    80005ba6:	fffff097          	auipc	ra,0xfffff
    80005baa:	9b6080e7          	jalr	-1610(ra) # 8000455c <end_op>
      return -1;
    80005bae:	54fd                	li	s1,-1
    80005bb0:	b76d                	j	80005b5a <sys_open+0xe4>
      end_op();
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	9aa080e7          	jalr	-1622(ra) # 8000455c <end_op>
      return -1;
    80005bba:	54fd                	li	s1,-1
    80005bbc:	bf79                	j	80005b5a <sys_open+0xe4>
    iunlockput(ip);
    80005bbe:	854a                	mv	a0,s2
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	1ac080e7          	jalr	428(ra) # 80003d6c <iunlockput>
    end_op();
    80005bc8:	fffff097          	auipc	ra,0xfffff
    80005bcc:	994080e7          	jalr	-1644(ra) # 8000455c <end_op>
    return -1;
    80005bd0:	54fd                	li	s1,-1
    80005bd2:	b761                	j	80005b5a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005bd4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005bd8:	04691783          	lh	a5,70(s2)
    80005bdc:	02f99223          	sh	a5,36(s3)
    80005be0:	bf2d                	j	80005b1a <sys_open+0xa4>
    itrunc(ip);
    80005be2:	854a                	mv	a0,s2
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	034080e7          	jalr	52(ra) # 80003c18 <itrunc>
    80005bec:	bfb1                	j	80005b48 <sys_open+0xd2>
      fileclose(f);
    80005bee:	854e                	mv	a0,s3
    80005bf0:	fffff097          	auipc	ra,0xfffff
    80005bf4:	db8080e7          	jalr	-584(ra) # 800049a8 <fileclose>
    iunlockput(ip);
    80005bf8:	854a                	mv	a0,s2
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	172080e7          	jalr	370(ra) # 80003d6c <iunlockput>
    end_op();
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	95a080e7          	jalr	-1702(ra) # 8000455c <end_op>
    return -1;
    80005c0a:	54fd                	li	s1,-1
    80005c0c:	b7b9                	j	80005b5a <sys_open+0xe4>

0000000080005c0e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c0e:	7175                	addi	sp,sp,-144
    80005c10:	e506                	sd	ra,136(sp)
    80005c12:	e122                	sd	s0,128(sp)
    80005c14:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c16:	fffff097          	auipc	ra,0xfffff
    80005c1a:	8c6080e7          	jalr	-1850(ra) # 800044dc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c1e:	08000613          	li	a2,128
    80005c22:	f7040593          	addi	a1,s0,-144
    80005c26:	4501                	li	a0,0
    80005c28:	ffffd097          	auipc	ra,0xffffd
    80005c2c:	200080e7          	jalr	512(ra) # 80002e28 <argstr>
    80005c30:	02054963          	bltz	a0,80005c62 <sys_mkdir+0x54>
    80005c34:	4681                	li	a3,0
    80005c36:	4601                	li	a2,0
    80005c38:	4585                	li	a1,1
    80005c3a:	f7040513          	addi	a0,s0,-144
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	7fe080e7          	jalr	2046(ra) # 8000543c <create>
    80005c46:	cd11                	beqz	a0,80005c62 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c48:	ffffe097          	auipc	ra,0xffffe
    80005c4c:	124080e7          	jalr	292(ra) # 80003d6c <iunlockput>
  end_op();
    80005c50:	fffff097          	auipc	ra,0xfffff
    80005c54:	90c080e7          	jalr	-1780(ra) # 8000455c <end_op>
  return 0;
    80005c58:	4501                	li	a0,0
}
    80005c5a:	60aa                	ld	ra,136(sp)
    80005c5c:	640a                	ld	s0,128(sp)
    80005c5e:	6149                	addi	sp,sp,144
    80005c60:	8082                	ret
    end_op();
    80005c62:	fffff097          	auipc	ra,0xfffff
    80005c66:	8fa080e7          	jalr	-1798(ra) # 8000455c <end_op>
    return -1;
    80005c6a:	557d                	li	a0,-1
    80005c6c:	b7fd                	j	80005c5a <sys_mkdir+0x4c>

0000000080005c6e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c6e:	7135                	addi	sp,sp,-160
    80005c70:	ed06                	sd	ra,152(sp)
    80005c72:	e922                	sd	s0,144(sp)
    80005c74:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c76:	fffff097          	auipc	ra,0xfffff
    80005c7a:	866080e7          	jalr	-1946(ra) # 800044dc <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c7e:	08000613          	li	a2,128
    80005c82:	f7040593          	addi	a1,s0,-144
    80005c86:	4501                	li	a0,0
    80005c88:	ffffd097          	auipc	ra,0xffffd
    80005c8c:	1a0080e7          	jalr	416(ra) # 80002e28 <argstr>
    80005c90:	04054a63          	bltz	a0,80005ce4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005c94:	f6c40593          	addi	a1,s0,-148
    80005c98:	4505                	li	a0,1
    80005c9a:	ffffd097          	auipc	ra,0xffffd
    80005c9e:	14a080e7          	jalr	330(ra) # 80002de4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ca2:	04054163          	bltz	a0,80005ce4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ca6:	f6840593          	addi	a1,s0,-152
    80005caa:	4509                	li	a0,2
    80005cac:	ffffd097          	auipc	ra,0xffffd
    80005cb0:	138080e7          	jalr	312(ra) # 80002de4 <argint>
     argint(1, &major) < 0 ||
    80005cb4:	02054863          	bltz	a0,80005ce4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005cb8:	f6841683          	lh	a3,-152(s0)
    80005cbc:	f6c41603          	lh	a2,-148(s0)
    80005cc0:	458d                	li	a1,3
    80005cc2:	f7040513          	addi	a0,s0,-144
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	776080e7          	jalr	1910(ra) # 8000543c <create>
     argint(2, &minor) < 0 ||
    80005cce:	c919                	beqz	a0,80005ce4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cd0:	ffffe097          	auipc	ra,0xffffe
    80005cd4:	09c080e7          	jalr	156(ra) # 80003d6c <iunlockput>
  end_op();
    80005cd8:	fffff097          	auipc	ra,0xfffff
    80005cdc:	884080e7          	jalr	-1916(ra) # 8000455c <end_op>
  return 0;
    80005ce0:	4501                	li	a0,0
    80005ce2:	a031                	j	80005cee <sys_mknod+0x80>
    end_op();
    80005ce4:	fffff097          	auipc	ra,0xfffff
    80005ce8:	878080e7          	jalr	-1928(ra) # 8000455c <end_op>
    return -1;
    80005cec:	557d                	li	a0,-1
}
    80005cee:	60ea                	ld	ra,152(sp)
    80005cf0:	644a                	ld	s0,144(sp)
    80005cf2:	610d                	addi	sp,sp,160
    80005cf4:	8082                	ret

0000000080005cf6 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005cf6:	7135                	addi	sp,sp,-160
    80005cf8:	ed06                	sd	ra,152(sp)
    80005cfa:	e922                	sd	s0,144(sp)
    80005cfc:	e526                	sd	s1,136(sp)
    80005cfe:	e14a                	sd	s2,128(sp)
    80005d00:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d02:	ffffc097          	auipc	ra,0xffffc
    80005d06:	cae080e7          	jalr	-850(ra) # 800019b0 <myproc>
    80005d0a:	892a                	mv	s2,a0
  
  begin_op();
    80005d0c:	ffffe097          	auipc	ra,0xffffe
    80005d10:	7d0080e7          	jalr	2000(ra) # 800044dc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d14:	08000613          	li	a2,128
    80005d18:	f6040593          	addi	a1,s0,-160
    80005d1c:	4501                	li	a0,0
    80005d1e:	ffffd097          	auipc	ra,0xffffd
    80005d22:	10a080e7          	jalr	266(ra) # 80002e28 <argstr>
    80005d26:	04054b63          	bltz	a0,80005d7c <sys_chdir+0x86>
    80005d2a:	f6040513          	addi	a0,s0,-160
    80005d2e:	ffffe097          	auipc	ra,0xffffe
    80005d32:	592080e7          	jalr	1426(ra) # 800042c0 <namei>
    80005d36:	84aa                	mv	s1,a0
    80005d38:	c131                	beqz	a0,80005d7c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d3a:	ffffe097          	auipc	ra,0xffffe
    80005d3e:	dd0080e7          	jalr	-560(ra) # 80003b0a <ilock>
  if(ip->type != T_DIR){
    80005d42:	04449703          	lh	a4,68(s1)
    80005d46:	4785                	li	a5,1
    80005d48:	04f71063          	bne	a4,a5,80005d88 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d4c:	8526                	mv	a0,s1
    80005d4e:	ffffe097          	auipc	ra,0xffffe
    80005d52:	e7e080e7          	jalr	-386(ra) # 80003bcc <iunlock>
  iput(p->cwd);
    80005d56:	17093503          	ld	a0,368(s2)
    80005d5a:	ffffe097          	auipc	ra,0xffffe
    80005d5e:	f6a080e7          	jalr	-150(ra) # 80003cc4 <iput>
  end_op();
    80005d62:	ffffe097          	auipc	ra,0xffffe
    80005d66:	7fa080e7          	jalr	2042(ra) # 8000455c <end_op>
  p->cwd = ip;
    80005d6a:	16993823          	sd	s1,368(s2)
  return 0;
    80005d6e:	4501                	li	a0,0
}
    80005d70:	60ea                	ld	ra,152(sp)
    80005d72:	644a                	ld	s0,144(sp)
    80005d74:	64aa                	ld	s1,136(sp)
    80005d76:	690a                	ld	s2,128(sp)
    80005d78:	610d                	addi	sp,sp,160
    80005d7a:	8082                	ret
    end_op();
    80005d7c:	ffffe097          	auipc	ra,0xffffe
    80005d80:	7e0080e7          	jalr	2016(ra) # 8000455c <end_op>
    return -1;
    80005d84:	557d                	li	a0,-1
    80005d86:	b7ed                	j	80005d70 <sys_chdir+0x7a>
    iunlockput(ip);
    80005d88:	8526                	mv	a0,s1
    80005d8a:	ffffe097          	auipc	ra,0xffffe
    80005d8e:	fe2080e7          	jalr	-30(ra) # 80003d6c <iunlockput>
    end_op();
    80005d92:	ffffe097          	auipc	ra,0xffffe
    80005d96:	7ca080e7          	jalr	1994(ra) # 8000455c <end_op>
    return -1;
    80005d9a:	557d                	li	a0,-1
    80005d9c:	bfd1                	j	80005d70 <sys_chdir+0x7a>

0000000080005d9e <sys_exec>:

uint64
sys_exec(void)
{
    80005d9e:	7145                	addi	sp,sp,-464
    80005da0:	e786                	sd	ra,456(sp)
    80005da2:	e3a2                	sd	s0,448(sp)
    80005da4:	ff26                	sd	s1,440(sp)
    80005da6:	fb4a                	sd	s2,432(sp)
    80005da8:	f74e                	sd	s3,424(sp)
    80005daa:	f352                	sd	s4,416(sp)
    80005dac:	ef56                	sd	s5,408(sp)
    80005dae:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005db0:	08000613          	li	a2,128
    80005db4:	f4040593          	addi	a1,s0,-192
    80005db8:	4501                	li	a0,0
    80005dba:	ffffd097          	auipc	ra,0xffffd
    80005dbe:	06e080e7          	jalr	110(ra) # 80002e28 <argstr>
    return -1;
    80005dc2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005dc4:	0c054a63          	bltz	a0,80005e98 <sys_exec+0xfa>
    80005dc8:	e3840593          	addi	a1,s0,-456
    80005dcc:	4505                	li	a0,1
    80005dce:	ffffd097          	auipc	ra,0xffffd
    80005dd2:	038080e7          	jalr	56(ra) # 80002e06 <argaddr>
    80005dd6:	0c054163          	bltz	a0,80005e98 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005dda:	10000613          	li	a2,256
    80005dde:	4581                	li	a1,0
    80005de0:	e4040513          	addi	a0,s0,-448
    80005de4:	ffffb097          	auipc	ra,0xffffb
    80005de8:	efc080e7          	jalr	-260(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005dec:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005df0:	89a6                	mv	s3,s1
    80005df2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005df4:	02000a13          	li	s4,32
    80005df8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005dfc:	00391513          	slli	a0,s2,0x3
    80005e00:	e3040593          	addi	a1,s0,-464
    80005e04:	e3843783          	ld	a5,-456(s0)
    80005e08:	953e                	add	a0,a0,a5
    80005e0a:	ffffd097          	auipc	ra,0xffffd
    80005e0e:	f40080e7          	jalr	-192(ra) # 80002d4a <fetchaddr>
    80005e12:	02054a63          	bltz	a0,80005e46 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e16:	e3043783          	ld	a5,-464(s0)
    80005e1a:	c3b9                	beqz	a5,80005e60 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e1c:	ffffb097          	auipc	ra,0xffffb
    80005e20:	cd8080e7          	jalr	-808(ra) # 80000af4 <kalloc>
    80005e24:	85aa                	mv	a1,a0
    80005e26:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e2a:	cd11                	beqz	a0,80005e46 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e2c:	6605                	lui	a2,0x1
    80005e2e:	e3043503          	ld	a0,-464(s0)
    80005e32:	ffffd097          	auipc	ra,0xffffd
    80005e36:	f6a080e7          	jalr	-150(ra) # 80002d9c <fetchstr>
    80005e3a:	00054663          	bltz	a0,80005e46 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005e3e:	0905                	addi	s2,s2,1
    80005e40:	09a1                	addi	s3,s3,8
    80005e42:	fb491be3          	bne	s2,s4,80005df8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e46:	10048913          	addi	s2,s1,256
    80005e4a:	6088                	ld	a0,0(s1)
    80005e4c:	c529                	beqz	a0,80005e96 <sys_exec+0xf8>
    kfree(argv[i]);
    80005e4e:	ffffb097          	auipc	ra,0xffffb
    80005e52:	baa080e7          	jalr	-1110(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e56:	04a1                	addi	s1,s1,8
    80005e58:	ff2499e3          	bne	s1,s2,80005e4a <sys_exec+0xac>
  return -1;
    80005e5c:	597d                	li	s2,-1
    80005e5e:	a82d                	j	80005e98 <sys_exec+0xfa>
      argv[i] = 0;
    80005e60:	0a8e                	slli	s5,s5,0x3
    80005e62:	fc040793          	addi	a5,s0,-64
    80005e66:	9abe                	add	s5,s5,a5
    80005e68:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e6c:	e4040593          	addi	a1,s0,-448
    80005e70:	f4040513          	addi	a0,s0,-192
    80005e74:	fffff097          	auipc	ra,0xfffff
    80005e78:	194080e7          	jalr	404(ra) # 80005008 <exec>
    80005e7c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e7e:	10048993          	addi	s3,s1,256
    80005e82:	6088                	ld	a0,0(s1)
    80005e84:	c911                	beqz	a0,80005e98 <sys_exec+0xfa>
    kfree(argv[i]);
    80005e86:	ffffb097          	auipc	ra,0xffffb
    80005e8a:	b72080e7          	jalr	-1166(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e8e:	04a1                	addi	s1,s1,8
    80005e90:	ff3499e3          	bne	s1,s3,80005e82 <sys_exec+0xe4>
    80005e94:	a011                	j	80005e98 <sys_exec+0xfa>
  return -1;
    80005e96:	597d                	li	s2,-1
}
    80005e98:	854a                	mv	a0,s2
    80005e9a:	60be                	ld	ra,456(sp)
    80005e9c:	641e                	ld	s0,448(sp)
    80005e9e:	74fa                	ld	s1,440(sp)
    80005ea0:	795a                	ld	s2,432(sp)
    80005ea2:	79ba                	ld	s3,424(sp)
    80005ea4:	7a1a                	ld	s4,416(sp)
    80005ea6:	6afa                	ld	s5,408(sp)
    80005ea8:	6179                	addi	sp,sp,464
    80005eaa:	8082                	ret

0000000080005eac <sys_pipe>:

uint64
sys_pipe(void)
{
    80005eac:	7139                	addi	sp,sp,-64
    80005eae:	fc06                	sd	ra,56(sp)
    80005eb0:	f822                	sd	s0,48(sp)
    80005eb2:	f426                	sd	s1,40(sp)
    80005eb4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005eb6:	ffffc097          	auipc	ra,0xffffc
    80005eba:	afa080e7          	jalr	-1286(ra) # 800019b0 <myproc>
    80005ebe:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ec0:	fd840593          	addi	a1,s0,-40
    80005ec4:	4501                	li	a0,0
    80005ec6:	ffffd097          	auipc	ra,0xffffd
    80005eca:	f40080e7          	jalr	-192(ra) # 80002e06 <argaddr>
    return -1;
    80005ece:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ed0:	0e054063          	bltz	a0,80005fb0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ed4:	fc840593          	addi	a1,s0,-56
    80005ed8:	fd040513          	addi	a0,s0,-48
    80005edc:	fffff097          	auipc	ra,0xfffff
    80005ee0:	dfc080e7          	jalr	-516(ra) # 80004cd8 <pipealloc>
    return -1;
    80005ee4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ee6:	0c054563          	bltz	a0,80005fb0 <sys_pipe+0x104>
  fd0 = -1;
    80005eea:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005eee:	fd043503          	ld	a0,-48(s0)
    80005ef2:	fffff097          	auipc	ra,0xfffff
    80005ef6:	508080e7          	jalr	1288(ra) # 800053fa <fdalloc>
    80005efa:	fca42223          	sw	a0,-60(s0)
    80005efe:	08054c63          	bltz	a0,80005f96 <sys_pipe+0xea>
    80005f02:	fc843503          	ld	a0,-56(s0)
    80005f06:	fffff097          	auipc	ra,0xfffff
    80005f0a:	4f4080e7          	jalr	1268(ra) # 800053fa <fdalloc>
    80005f0e:	fca42023          	sw	a0,-64(s0)
    80005f12:	06054863          	bltz	a0,80005f82 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f16:	4691                	li	a3,4
    80005f18:	fc440613          	addi	a2,s0,-60
    80005f1c:	fd843583          	ld	a1,-40(s0)
    80005f20:	78a8                	ld	a0,112(s1)
    80005f22:	ffffb097          	auipc	ra,0xffffb
    80005f26:	750080e7          	jalr	1872(ra) # 80001672 <copyout>
    80005f2a:	02054063          	bltz	a0,80005f4a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f2e:	4691                	li	a3,4
    80005f30:	fc040613          	addi	a2,s0,-64
    80005f34:	fd843583          	ld	a1,-40(s0)
    80005f38:	0591                	addi	a1,a1,4
    80005f3a:	78a8                	ld	a0,112(s1)
    80005f3c:	ffffb097          	auipc	ra,0xffffb
    80005f40:	736080e7          	jalr	1846(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f44:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f46:	06055563          	bgez	a0,80005fb0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005f4a:	fc442783          	lw	a5,-60(s0)
    80005f4e:	07f9                	addi	a5,a5,30
    80005f50:	078e                	slli	a5,a5,0x3
    80005f52:	97a6                	add	a5,a5,s1
    80005f54:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f58:	fc042503          	lw	a0,-64(s0)
    80005f5c:	0579                	addi	a0,a0,30
    80005f5e:	050e                	slli	a0,a0,0x3
    80005f60:	9526                	add	a0,a0,s1
    80005f62:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005f66:	fd043503          	ld	a0,-48(s0)
    80005f6a:	fffff097          	auipc	ra,0xfffff
    80005f6e:	a3e080e7          	jalr	-1474(ra) # 800049a8 <fileclose>
    fileclose(wf);
    80005f72:	fc843503          	ld	a0,-56(s0)
    80005f76:	fffff097          	auipc	ra,0xfffff
    80005f7a:	a32080e7          	jalr	-1486(ra) # 800049a8 <fileclose>
    return -1;
    80005f7e:	57fd                	li	a5,-1
    80005f80:	a805                	j	80005fb0 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005f82:	fc442783          	lw	a5,-60(s0)
    80005f86:	0007c863          	bltz	a5,80005f96 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005f8a:	01e78513          	addi	a0,a5,30
    80005f8e:	050e                	slli	a0,a0,0x3
    80005f90:	9526                	add	a0,a0,s1
    80005f92:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005f96:	fd043503          	ld	a0,-48(s0)
    80005f9a:	fffff097          	auipc	ra,0xfffff
    80005f9e:	a0e080e7          	jalr	-1522(ra) # 800049a8 <fileclose>
    fileclose(wf);
    80005fa2:	fc843503          	ld	a0,-56(s0)
    80005fa6:	fffff097          	auipc	ra,0xfffff
    80005faa:	a02080e7          	jalr	-1534(ra) # 800049a8 <fileclose>
    return -1;
    80005fae:	57fd                	li	a5,-1
}
    80005fb0:	853e                	mv	a0,a5
    80005fb2:	70e2                	ld	ra,56(sp)
    80005fb4:	7442                	ld	s0,48(sp)
    80005fb6:	74a2                	ld	s1,40(sp)
    80005fb8:	6121                	addi	sp,sp,64
    80005fba:	8082                	ret
    80005fbc:	0000                	unimp
	...

0000000080005fc0 <kernelvec>:
    80005fc0:	7111                	addi	sp,sp,-256
    80005fc2:	e006                	sd	ra,0(sp)
    80005fc4:	e40a                	sd	sp,8(sp)
    80005fc6:	e80e                	sd	gp,16(sp)
    80005fc8:	ec12                	sd	tp,24(sp)
    80005fca:	f016                	sd	t0,32(sp)
    80005fcc:	f41a                	sd	t1,40(sp)
    80005fce:	f81e                	sd	t2,48(sp)
    80005fd0:	fc22                	sd	s0,56(sp)
    80005fd2:	e0a6                	sd	s1,64(sp)
    80005fd4:	e4aa                	sd	a0,72(sp)
    80005fd6:	e8ae                	sd	a1,80(sp)
    80005fd8:	ecb2                	sd	a2,88(sp)
    80005fda:	f0b6                	sd	a3,96(sp)
    80005fdc:	f4ba                	sd	a4,104(sp)
    80005fde:	f8be                	sd	a5,112(sp)
    80005fe0:	fcc2                	sd	a6,120(sp)
    80005fe2:	e146                	sd	a7,128(sp)
    80005fe4:	e54a                	sd	s2,136(sp)
    80005fe6:	e94e                	sd	s3,144(sp)
    80005fe8:	ed52                	sd	s4,152(sp)
    80005fea:	f156                	sd	s5,160(sp)
    80005fec:	f55a                	sd	s6,168(sp)
    80005fee:	f95e                	sd	s7,176(sp)
    80005ff0:	fd62                	sd	s8,184(sp)
    80005ff2:	e1e6                	sd	s9,192(sp)
    80005ff4:	e5ea                	sd	s10,200(sp)
    80005ff6:	e9ee                	sd	s11,208(sp)
    80005ff8:	edf2                	sd	t3,216(sp)
    80005ffa:	f1f6                	sd	t4,224(sp)
    80005ffc:	f5fa                	sd	t5,232(sp)
    80005ffe:	f9fe                	sd	t6,240(sp)
    80006000:	c41fc0ef          	jal	ra,80002c40 <kerneltrap>
    80006004:	6082                	ld	ra,0(sp)
    80006006:	6122                	ld	sp,8(sp)
    80006008:	61c2                	ld	gp,16(sp)
    8000600a:	7282                	ld	t0,32(sp)
    8000600c:	7322                	ld	t1,40(sp)
    8000600e:	73c2                	ld	t2,48(sp)
    80006010:	7462                	ld	s0,56(sp)
    80006012:	6486                	ld	s1,64(sp)
    80006014:	6526                	ld	a0,72(sp)
    80006016:	65c6                	ld	a1,80(sp)
    80006018:	6666                	ld	a2,88(sp)
    8000601a:	7686                	ld	a3,96(sp)
    8000601c:	7726                	ld	a4,104(sp)
    8000601e:	77c6                	ld	a5,112(sp)
    80006020:	7866                	ld	a6,120(sp)
    80006022:	688a                	ld	a7,128(sp)
    80006024:	692a                	ld	s2,136(sp)
    80006026:	69ca                	ld	s3,144(sp)
    80006028:	6a6a                	ld	s4,152(sp)
    8000602a:	7a8a                	ld	s5,160(sp)
    8000602c:	7b2a                	ld	s6,168(sp)
    8000602e:	7bca                	ld	s7,176(sp)
    80006030:	7c6a                	ld	s8,184(sp)
    80006032:	6c8e                	ld	s9,192(sp)
    80006034:	6d2e                	ld	s10,200(sp)
    80006036:	6dce                	ld	s11,208(sp)
    80006038:	6e6e                	ld	t3,216(sp)
    8000603a:	7e8e                	ld	t4,224(sp)
    8000603c:	7f2e                	ld	t5,232(sp)
    8000603e:	7fce                	ld	t6,240(sp)
    80006040:	6111                	addi	sp,sp,256
    80006042:	10200073          	sret
    80006046:	00000013          	nop
    8000604a:	00000013          	nop
    8000604e:	0001                	nop

0000000080006050 <timervec>:
    80006050:	34051573          	csrrw	a0,mscratch,a0
    80006054:	e10c                	sd	a1,0(a0)
    80006056:	e510                	sd	a2,8(a0)
    80006058:	e914                	sd	a3,16(a0)
    8000605a:	6d0c                	ld	a1,24(a0)
    8000605c:	7110                	ld	a2,32(a0)
    8000605e:	6194                	ld	a3,0(a1)
    80006060:	96b2                	add	a3,a3,a2
    80006062:	e194                	sd	a3,0(a1)
    80006064:	4589                	li	a1,2
    80006066:	14459073          	csrw	sip,a1
    8000606a:	6914                	ld	a3,16(a0)
    8000606c:	6510                	ld	a2,8(a0)
    8000606e:	610c                	ld	a1,0(a0)
    80006070:	34051573          	csrrw	a0,mscratch,a0
    80006074:	30200073          	mret
	...

000000008000607a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000607a:	1141                	addi	sp,sp,-16
    8000607c:	e422                	sd	s0,8(sp)
    8000607e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006080:	0c0007b7          	lui	a5,0xc000
    80006084:	4705                	li	a4,1
    80006086:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006088:	c3d8                	sw	a4,4(a5)
}
    8000608a:	6422                	ld	s0,8(sp)
    8000608c:	0141                	addi	sp,sp,16
    8000608e:	8082                	ret

0000000080006090 <plicinithart>:

void
plicinithart(void)
{
    80006090:	1141                	addi	sp,sp,-16
    80006092:	e406                	sd	ra,8(sp)
    80006094:	e022                	sd	s0,0(sp)
    80006096:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006098:	ffffc097          	auipc	ra,0xffffc
    8000609c:	8ec080e7          	jalr	-1812(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060a0:	0085171b          	slliw	a4,a0,0x8
    800060a4:	0c0027b7          	lui	a5,0xc002
    800060a8:	97ba                	add	a5,a5,a4
    800060aa:	40200713          	li	a4,1026
    800060ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060b2:	00d5151b          	slliw	a0,a0,0xd
    800060b6:	0c2017b7          	lui	a5,0xc201
    800060ba:	953e                	add	a0,a0,a5
    800060bc:	00052023          	sw	zero,0(a0)
}
    800060c0:	60a2                	ld	ra,8(sp)
    800060c2:	6402                	ld	s0,0(sp)
    800060c4:	0141                	addi	sp,sp,16
    800060c6:	8082                	ret

00000000800060c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060c8:	1141                	addi	sp,sp,-16
    800060ca:	e406                	sd	ra,8(sp)
    800060cc:	e022                	sd	s0,0(sp)
    800060ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060d0:	ffffc097          	auipc	ra,0xffffc
    800060d4:	8b4080e7          	jalr	-1868(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060d8:	00d5179b          	slliw	a5,a0,0xd
    800060dc:	0c201537          	lui	a0,0xc201
    800060e0:	953e                	add	a0,a0,a5
  return irq;
}
    800060e2:	4148                	lw	a0,4(a0)
    800060e4:	60a2                	ld	ra,8(sp)
    800060e6:	6402                	ld	s0,0(sp)
    800060e8:	0141                	addi	sp,sp,16
    800060ea:	8082                	ret

00000000800060ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060ec:	1101                	addi	sp,sp,-32
    800060ee:	ec06                	sd	ra,24(sp)
    800060f0:	e822                	sd	s0,16(sp)
    800060f2:	e426                	sd	s1,8(sp)
    800060f4:	1000                	addi	s0,sp,32
    800060f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800060f8:	ffffc097          	auipc	ra,0xffffc
    800060fc:	88c080e7          	jalr	-1908(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006100:	00d5151b          	slliw	a0,a0,0xd
    80006104:	0c2017b7          	lui	a5,0xc201
    80006108:	97aa                	add	a5,a5,a0
    8000610a:	c3c4                	sw	s1,4(a5)
}
    8000610c:	60e2                	ld	ra,24(sp)
    8000610e:	6442                	ld	s0,16(sp)
    80006110:	64a2                	ld	s1,8(sp)
    80006112:	6105                	addi	sp,sp,32
    80006114:	8082                	ret

0000000080006116 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006116:	1141                	addi	sp,sp,-16
    80006118:	e406                	sd	ra,8(sp)
    8000611a:	e022                	sd	s0,0(sp)
    8000611c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000611e:	479d                	li	a5,7
    80006120:	06a7c963          	blt	a5,a0,80006192 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006124:	0001d797          	auipc	a5,0x1d
    80006128:	edc78793          	addi	a5,a5,-292 # 80023000 <disk>
    8000612c:	00a78733          	add	a4,a5,a0
    80006130:	6789                	lui	a5,0x2
    80006132:	97ba                	add	a5,a5,a4
    80006134:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006138:	e7ad                	bnez	a5,800061a2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000613a:	00451793          	slli	a5,a0,0x4
    8000613e:	0001f717          	auipc	a4,0x1f
    80006142:	ec270713          	addi	a4,a4,-318 # 80025000 <disk+0x2000>
    80006146:	6314                	ld	a3,0(a4)
    80006148:	96be                	add	a3,a3,a5
    8000614a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000614e:	6314                	ld	a3,0(a4)
    80006150:	96be                	add	a3,a3,a5
    80006152:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006156:	6314                	ld	a3,0(a4)
    80006158:	96be                	add	a3,a3,a5
    8000615a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000615e:	6318                	ld	a4,0(a4)
    80006160:	97ba                	add	a5,a5,a4
    80006162:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006166:	0001d797          	auipc	a5,0x1d
    8000616a:	e9a78793          	addi	a5,a5,-358 # 80023000 <disk>
    8000616e:	97aa                	add	a5,a5,a0
    80006170:	6509                	lui	a0,0x2
    80006172:	953e                	add	a0,a0,a5
    80006174:	4785                	li	a5,1
    80006176:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000617a:	0001f517          	auipc	a0,0x1f
    8000617e:	e9e50513          	addi	a0,a0,-354 # 80025018 <disk+0x2018>
    80006182:	ffffc097          	auipc	ra,0xffffc
    80006186:	244080e7          	jalr	580(ra) # 800023c6 <wakeup>
}
    8000618a:	60a2                	ld	ra,8(sp)
    8000618c:	6402                	ld	s0,0(sp)
    8000618e:	0141                	addi	sp,sp,16
    80006190:	8082                	ret
    panic("free_desc 1");
    80006192:	00002517          	auipc	a0,0x2
    80006196:	7ee50513          	addi	a0,a0,2030 # 80008980 <syscall_arg+0x2c8>
    8000619a:	ffffa097          	auipc	ra,0xffffa
    8000619e:	3a4080e7          	jalr	932(ra) # 8000053e <panic>
    panic("free_desc 2");
    800061a2:	00002517          	auipc	a0,0x2
    800061a6:	7ee50513          	addi	a0,a0,2030 # 80008990 <syscall_arg+0x2d8>
    800061aa:	ffffa097          	auipc	ra,0xffffa
    800061ae:	394080e7          	jalr	916(ra) # 8000053e <panic>

00000000800061b2 <virtio_disk_init>:
{
    800061b2:	1101                	addi	sp,sp,-32
    800061b4:	ec06                	sd	ra,24(sp)
    800061b6:	e822                	sd	s0,16(sp)
    800061b8:	e426                	sd	s1,8(sp)
    800061ba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061bc:	00002597          	auipc	a1,0x2
    800061c0:	7e458593          	addi	a1,a1,2020 # 800089a0 <syscall_arg+0x2e8>
    800061c4:	0001f517          	auipc	a0,0x1f
    800061c8:	f6450513          	addi	a0,a0,-156 # 80025128 <disk+0x2128>
    800061cc:	ffffb097          	auipc	ra,0xffffb
    800061d0:	988080e7          	jalr	-1656(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061d4:	100017b7          	lui	a5,0x10001
    800061d8:	4398                	lw	a4,0(a5)
    800061da:	2701                	sext.w	a4,a4
    800061dc:	747277b7          	lui	a5,0x74727
    800061e0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061e4:	0ef71163          	bne	a4,a5,800062c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061e8:	100017b7          	lui	a5,0x10001
    800061ec:	43dc                	lw	a5,4(a5)
    800061ee:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061f0:	4705                	li	a4,1
    800061f2:	0ce79a63          	bne	a5,a4,800062c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061f6:	100017b7          	lui	a5,0x10001
    800061fa:	479c                	lw	a5,8(a5)
    800061fc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061fe:	4709                	li	a4,2
    80006200:	0ce79363          	bne	a5,a4,800062c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006204:	100017b7          	lui	a5,0x10001
    80006208:	47d8                	lw	a4,12(a5)
    8000620a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000620c:	554d47b7          	lui	a5,0x554d4
    80006210:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006214:	0af71963          	bne	a4,a5,800062c6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006218:	100017b7          	lui	a5,0x10001
    8000621c:	4705                	li	a4,1
    8000621e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006220:	470d                	li	a4,3
    80006222:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006224:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006226:	c7ffe737          	lui	a4,0xc7ffe
    8000622a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000622e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006230:	2701                	sext.w	a4,a4
    80006232:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006234:	472d                	li	a4,11
    80006236:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006238:	473d                	li	a4,15
    8000623a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000623c:	6705                	lui	a4,0x1
    8000623e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006240:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006244:	5bdc                	lw	a5,52(a5)
    80006246:	2781                	sext.w	a5,a5
  if(max == 0)
    80006248:	c7d9                	beqz	a5,800062d6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000624a:	471d                	li	a4,7
    8000624c:	08f77d63          	bgeu	a4,a5,800062e6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006250:	100014b7          	lui	s1,0x10001
    80006254:	47a1                	li	a5,8
    80006256:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006258:	6609                	lui	a2,0x2
    8000625a:	4581                	li	a1,0
    8000625c:	0001d517          	auipc	a0,0x1d
    80006260:	da450513          	addi	a0,a0,-604 # 80023000 <disk>
    80006264:	ffffb097          	auipc	ra,0xffffb
    80006268:	a7c080e7          	jalr	-1412(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000626c:	0001d717          	auipc	a4,0x1d
    80006270:	d9470713          	addi	a4,a4,-620 # 80023000 <disk>
    80006274:	00c75793          	srli	a5,a4,0xc
    80006278:	2781                	sext.w	a5,a5
    8000627a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000627c:	0001f797          	auipc	a5,0x1f
    80006280:	d8478793          	addi	a5,a5,-636 # 80025000 <disk+0x2000>
    80006284:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006286:	0001d717          	auipc	a4,0x1d
    8000628a:	dfa70713          	addi	a4,a4,-518 # 80023080 <disk+0x80>
    8000628e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006290:	0001e717          	auipc	a4,0x1e
    80006294:	d7070713          	addi	a4,a4,-656 # 80024000 <disk+0x1000>
    80006298:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000629a:	4705                	li	a4,1
    8000629c:	00e78c23          	sb	a4,24(a5)
    800062a0:	00e78ca3          	sb	a4,25(a5)
    800062a4:	00e78d23          	sb	a4,26(a5)
    800062a8:	00e78da3          	sb	a4,27(a5)
    800062ac:	00e78e23          	sb	a4,28(a5)
    800062b0:	00e78ea3          	sb	a4,29(a5)
    800062b4:	00e78f23          	sb	a4,30(a5)
    800062b8:	00e78fa3          	sb	a4,31(a5)
}
    800062bc:	60e2                	ld	ra,24(sp)
    800062be:	6442                	ld	s0,16(sp)
    800062c0:	64a2                	ld	s1,8(sp)
    800062c2:	6105                	addi	sp,sp,32
    800062c4:	8082                	ret
    panic("could not find virtio disk");
    800062c6:	00002517          	auipc	a0,0x2
    800062ca:	6ea50513          	addi	a0,a0,1770 # 800089b0 <syscall_arg+0x2f8>
    800062ce:	ffffa097          	auipc	ra,0xffffa
    800062d2:	270080e7          	jalr	624(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800062d6:	00002517          	auipc	a0,0x2
    800062da:	6fa50513          	addi	a0,a0,1786 # 800089d0 <syscall_arg+0x318>
    800062de:	ffffa097          	auipc	ra,0xffffa
    800062e2:	260080e7          	jalr	608(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800062e6:	00002517          	auipc	a0,0x2
    800062ea:	70a50513          	addi	a0,a0,1802 # 800089f0 <syscall_arg+0x338>
    800062ee:	ffffa097          	auipc	ra,0xffffa
    800062f2:	250080e7          	jalr	592(ra) # 8000053e <panic>

00000000800062f6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062f6:	7159                	addi	sp,sp,-112
    800062f8:	f486                	sd	ra,104(sp)
    800062fa:	f0a2                	sd	s0,96(sp)
    800062fc:	eca6                	sd	s1,88(sp)
    800062fe:	e8ca                	sd	s2,80(sp)
    80006300:	e4ce                	sd	s3,72(sp)
    80006302:	e0d2                	sd	s4,64(sp)
    80006304:	fc56                	sd	s5,56(sp)
    80006306:	f85a                	sd	s6,48(sp)
    80006308:	f45e                	sd	s7,40(sp)
    8000630a:	f062                	sd	s8,32(sp)
    8000630c:	ec66                	sd	s9,24(sp)
    8000630e:	e86a                	sd	s10,16(sp)
    80006310:	1880                	addi	s0,sp,112
    80006312:	892a                	mv	s2,a0
    80006314:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006316:	00c52c83          	lw	s9,12(a0)
    8000631a:	001c9c9b          	slliw	s9,s9,0x1
    8000631e:	1c82                	slli	s9,s9,0x20
    80006320:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006324:	0001f517          	auipc	a0,0x1f
    80006328:	e0450513          	addi	a0,a0,-508 # 80025128 <disk+0x2128>
    8000632c:	ffffb097          	auipc	ra,0xffffb
    80006330:	8b8080e7          	jalr	-1864(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006334:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006336:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006338:	0001db97          	auipc	s7,0x1d
    8000633c:	cc8b8b93          	addi	s7,s7,-824 # 80023000 <disk>
    80006340:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006342:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006344:	8a4e                	mv	s4,s3
    80006346:	a051                	j	800063ca <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006348:	00fb86b3          	add	a3,s7,a5
    8000634c:	96da                	add	a3,a3,s6
    8000634e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006352:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006354:	0207c563          	bltz	a5,8000637e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006358:	2485                	addiw	s1,s1,1
    8000635a:	0711                	addi	a4,a4,4
    8000635c:	25548063          	beq	s1,s5,8000659c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006360:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006362:	0001f697          	auipc	a3,0x1f
    80006366:	cb668693          	addi	a3,a3,-842 # 80025018 <disk+0x2018>
    8000636a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000636c:	0006c583          	lbu	a1,0(a3)
    80006370:	fde1                	bnez	a1,80006348 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006372:	2785                	addiw	a5,a5,1
    80006374:	0685                	addi	a3,a3,1
    80006376:	ff879be3          	bne	a5,s8,8000636c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000637a:	57fd                	li	a5,-1
    8000637c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000637e:	02905a63          	blez	s1,800063b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006382:	f9042503          	lw	a0,-112(s0)
    80006386:	00000097          	auipc	ra,0x0
    8000638a:	d90080e7          	jalr	-624(ra) # 80006116 <free_desc>
      for(int j = 0; j < i; j++)
    8000638e:	4785                	li	a5,1
    80006390:	0297d163          	bge	a5,s1,800063b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006394:	f9442503          	lw	a0,-108(s0)
    80006398:	00000097          	auipc	ra,0x0
    8000639c:	d7e080e7          	jalr	-642(ra) # 80006116 <free_desc>
      for(int j = 0; j < i; j++)
    800063a0:	4789                	li	a5,2
    800063a2:	0097d863          	bge	a5,s1,800063b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063a6:	f9842503          	lw	a0,-104(s0)
    800063aa:	00000097          	auipc	ra,0x0
    800063ae:	d6c080e7          	jalr	-660(ra) # 80006116 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063b2:	0001f597          	auipc	a1,0x1f
    800063b6:	d7658593          	addi	a1,a1,-650 # 80025128 <disk+0x2128>
    800063ba:	0001f517          	auipc	a0,0x1f
    800063be:	c5e50513          	addi	a0,a0,-930 # 80025018 <disk+0x2018>
    800063c2:	ffffc097          	auipc	ra,0xffffc
    800063c6:	e68080e7          	jalr	-408(ra) # 8000222a <sleep>
  for(int i = 0; i < 3; i++){
    800063ca:	f9040713          	addi	a4,s0,-112
    800063ce:	84ce                	mv	s1,s3
    800063d0:	bf41                	j	80006360 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800063d2:	20058713          	addi	a4,a1,512
    800063d6:	00471693          	slli	a3,a4,0x4
    800063da:	0001d717          	auipc	a4,0x1d
    800063de:	c2670713          	addi	a4,a4,-986 # 80023000 <disk>
    800063e2:	9736                	add	a4,a4,a3
    800063e4:	4685                	li	a3,1
    800063e6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800063ea:	20058713          	addi	a4,a1,512
    800063ee:	00471693          	slli	a3,a4,0x4
    800063f2:	0001d717          	auipc	a4,0x1d
    800063f6:	c0e70713          	addi	a4,a4,-1010 # 80023000 <disk>
    800063fa:	9736                	add	a4,a4,a3
    800063fc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006400:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006404:	7679                	lui	a2,0xffffe
    80006406:	963e                	add	a2,a2,a5
    80006408:	0001f697          	auipc	a3,0x1f
    8000640c:	bf868693          	addi	a3,a3,-1032 # 80025000 <disk+0x2000>
    80006410:	6298                	ld	a4,0(a3)
    80006412:	9732                	add	a4,a4,a2
    80006414:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006416:	6298                	ld	a4,0(a3)
    80006418:	9732                	add	a4,a4,a2
    8000641a:	4541                	li	a0,16
    8000641c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000641e:	6298                	ld	a4,0(a3)
    80006420:	9732                	add	a4,a4,a2
    80006422:	4505                	li	a0,1
    80006424:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006428:	f9442703          	lw	a4,-108(s0)
    8000642c:	6288                	ld	a0,0(a3)
    8000642e:	962a                	add	a2,a2,a0
    80006430:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006434:	0712                	slli	a4,a4,0x4
    80006436:	6290                	ld	a2,0(a3)
    80006438:	963a                	add	a2,a2,a4
    8000643a:	05890513          	addi	a0,s2,88
    8000643e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006440:	6294                	ld	a3,0(a3)
    80006442:	96ba                	add	a3,a3,a4
    80006444:	40000613          	li	a2,1024
    80006448:	c690                	sw	a2,8(a3)
  if(write)
    8000644a:	140d0063          	beqz	s10,8000658a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000644e:	0001f697          	auipc	a3,0x1f
    80006452:	bb26b683          	ld	a3,-1102(a3) # 80025000 <disk+0x2000>
    80006456:	96ba                	add	a3,a3,a4
    80006458:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000645c:	0001d817          	auipc	a6,0x1d
    80006460:	ba480813          	addi	a6,a6,-1116 # 80023000 <disk>
    80006464:	0001f517          	auipc	a0,0x1f
    80006468:	b9c50513          	addi	a0,a0,-1124 # 80025000 <disk+0x2000>
    8000646c:	6114                	ld	a3,0(a0)
    8000646e:	96ba                	add	a3,a3,a4
    80006470:	00c6d603          	lhu	a2,12(a3)
    80006474:	00166613          	ori	a2,a2,1
    80006478:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000647c:	f9842683          	lw	a3,-104(s0)
    80006480:	6110                	ld	a2,0(a0)
    80006482:	9732                	add	a4,a4,a2
    80006484:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006488:	20058613          	addi	a2,a1,512
    8000648c:	0612                	slli	a2,a2,0x4
    8000648e:	9642                	add	a2,a2,a6
    80006490:	577d                	li	a4,-1
    80006492:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006496:	00469713          	slli	a4,a3,0x4
    8000649a:	6114                	ld	a3,0(a0)
    8000649c:	96ba                	add	a3,a3,a4
    8000649e:	03078793          	addi	a5,a5,48
    800064a2:	97c2                	add	a5,a5,a6
    800064a4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800064a6:	611c                	ld	a5,0(a0)
    800064a8:	97ba                	add	a5,a5,a4
    800064aa:	4685                	li	a3,1
    800064ac:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800064ae:	611c                	ld	a5,0(a0)
    800064b0:	97ba                	add	a5,a5,a4
    800064b2:	4809                	li	a6,2
    800064b4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800064b8:	611c                	ld	a5,0(a0)
    800064ba:	973e                	add	a4,a4,a5
    800064bc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800064c0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800064c4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800064c8:	6518                	ld	a4,8(a0)
    800064ca:	00275783          	lhu	a5,2(a4)
    800064ce:	8b9d                	andi	a5,a5,7
    800064d0:	0786                	slli	a5,a5,0x1
    800064d2:	97ba                	add	a5,a5,a4
    800064d4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800064d8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800064dc:	6518                	ld	a4,8(a0)
    800064de:	00275783          	lhu	a5,2(a4)
    800064e2:	2785                	addiw	a5,a5,1
    800064e4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800064e8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800064ec:	100017b7          	lui	a5,0x10001
    800064f0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800064f4:	00492703          	lw	a4,4(s2)
    800064f8:	4785                	li	a5,1
    800064fa:	02f71163          	bne	a4,a5,8000651c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800064fe:	0001f997          	auipc	s3,0x1f
    80006502:	c2a98993          	addi	s3,s3,-982 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006506:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006508:	85ce                	mv	a1,s3
    8000650a:	854a                	mv	a0,s2
    8000650c:	ffffc097          	auipc	ra,0xffffc
    80006510:	d1e080e7          	jalr	-738(ra) # 8000222a <sleep>
  while(b->disk == 1) {
    80006514:	00492783          	lw	a5,4(s2)
    80006518:	fe9788e3          	beq	a5,s1,80006508 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000651c:	f9042903          	lw	s2,-112(s0)
    80006520:	20090793          	addi	a5,s2,512
    80006524:	00479713          	slli	a4,a5,0x4
    80006528:	0001d797          	auipc	a5,0x1d
    8000652c:	ad878793          	addi	a5,a5,-1320 # 80023000 <disk>
    80006530:	97ba                	add	a5,a5,a4
    80006532:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006536:	0001f997          	auipc	s3,0x1f
    8000653a:	aca98993          	addi	s3,s3,-1334 # 80025000 <disk+0x2000>
    8000653e:	00491713          	slli	a4,s2,0x4
    80006542:	0009b783          	ld	a5,0(s3)
    80006546:	97ba                	add	a5,a5,a4
    80006548:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000654c:	854a                	mv	a0,s2
    8000654e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006552:	00000097          	auipc	ra,0x0
    80006556:	bc4080e7          	jalr	-1084(ra) # 80006116 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000655a:	8885                	andi	s1,s1,1
    8000655c:	f0ed                	bnez	s1,8000653e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000655e:	0001f517          	auipc	a0,0x1f
    80006562:	bca50513          	addi	a0,a0,-1078 # 80025128 <disk+0x2128>
    80006566:	ffffa097          	auipc	ra,0xffffa
    8000656a:	732080e7          	jalr	1842(ra) # 80000c98 <release>
}
    8000656e:	70a6                	ld	ra,104(sp)
    80006570:	7406                	ld	s0,96(sp)
    80006572:	64e6                	ld	s1,88(sp)
    80006574:	6946                	ld	s2,80(sp)
    80006576:	69a6                	ld	s3,72(sp)
    80006578:	6a06                	ld	s4,64(sp)
    8000657a:	7ae2                	ld	s5,56(sp)
    8000657c:	7b42                	ld	s6,48(sp)
    8000657e:	7ba2                	ld	s7,40(sp)
    80006580:	7c02                	ld	s8,32(sp)
    80006582:	6ce2                	ld	s9,24(sp)
    80006584:	6d42                	ld	s10,16(sp)
    80006586:	6165                	addi	sp,sp,112
    80006588:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000658a:	0001f697          	auipc	a3,0x1f
    8000658e:	a766b683          	ld	a3,-1418(a3) # 80025000 <disk+0x2000>
    80006592:	96ba                	add	a3,a3,a4
    80006594:	4609                	li	a2,2
    80006596:	00c69623          	sh	a2,12(a3)
    8000659a:	b5c9                	j	8000645c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000659c:	f9042583          	lw	a1,-112(s0)
    800065a0:	20058793          	addi	a5,a1,512
    800065a4:	0792                	slli	a5,a5,0x4
    800065a6:	0001d517          	auipc	a0,0x1d
    800065aa:	b0250513          	addi	a0,a0,-1278 # 800230a8 <disk+0xa8>
    800065ae:	953e                	add	a0,a0,a5
  if(write)
    800065b0:	e20d11e3          	bnez	s10,800063d2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800065b4:	20058713          	addi	a4,a1,512
    800065b8:	00471693          	slli	a3,a4,0x4
    800065bc:	0001d717          	auipc	a4,0x1d
    800065c0:	a4470713          	addi	a4,a4,-1468 # 80023000 <disk>
    800065c4:	9736                	add	a4,a4,a3
    800065c6:	0a072423          	sw	zero,168(a4)
    800065ca:	b505                	j	800063ea <virtio_disk_rw+0xf4>

00000000800065cc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800065cc:	1101                	addi	sp,sp,-32
    800065ce:	ec06                	sd	ra,24(sp)
    800065d0:	e822                	sd	s0,16(sp)
    800065d2:	e426                	sd	s1,8(sp)
    800065d4:	e04a                	sd	s2,0(sp)
    800065d6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065d8:	0001f517          	auipc	a0,0x1f
    800065dc:	b5050513          	addi	a0,a0,-1200 # 80025128 <disk+0x2128>
    800065e0:	ffffa097          	auipc	ra,0xffffa
    800065e4:	604080e7          	jalr	1540(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065e8:	10001737          	lui	a4,0x10001
    800065ec:	533c                	lw	a5,96(a4)
    800065ee:	8b8d                	andi	a5,a5,3
    800065f0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800065f2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800065f6:	0001f797          	auipc	a5,0x1f
    800065fa:	a0a78793          	addi	a5,a5,-1526 # 80025000 <disk+0x2000>
    800065fe:	6b94                	ld	a3,16(a5)
    80006600:	0207d703          	lhu	a4,32(a5)
    80006604:	0026d783          	lhu	a5,2(a3)
    80006608:	06f70163          	beq	a4,a5,8000666a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000660c:	0001d917          	auipc	s2,0x1d
    80006610:	9f490913          	addi	s2,s2,-1548 # 80023000 <disk>
    80006614:	0001f497          	auipc	s1,0x1f
    80006618:	9ec48493          	addi	s1,s1,-1556 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000661c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006620:	6898                	ld	a4,16(s1)
    80006622:	0204d783          	lhu	a5,32(s1)
    80006626:	8b9d                	andi	a5,a5,7
    80006628:	078e                	slli	a5,a5,0x3
    8000662a:	97ba                	add	a5,a5,a4
    8000662c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000662e:	20078713          	addi	a4,a5,512
    80006632:	0712                	slli	a4,a4,0x4
    80006634:	974a                	add	a4,a4,s2
    80006636:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000663a:	e731                	bnez	a4,80006686 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000663c:	20078793          	addi	a5,a5,512
    80006640:	0792                	slli	a5,a5,0x4
    80006642:	97ca                	add	a5,a5,s2
    80006644:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006646:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000664a:	ffffc097          	auipc	ra,0xffffc
    8000664e:	d7c080e7          	jalr	-644(ra) # 800023c6 <wakeup>

    disk.used_idx += 1;
    80006652:	0204d783          	lhu	a5,32(s1)
    80006656:	2785                	addiw	a5,a5,1
    80006658:	17c2                	slli	a5,a5,0x30
    8000665a:	93c1                	srli	a5,a5,0x30
    8000665c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006660:	6898                	ld	a4,16(s1)
    80006662:	00275703          	lhu	a4,2(a4)
    80006666:	faf71be3          	bne	a4,a5,8000661c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000666a:	0001f517          	auipc	a0,0x1f
    8000666e:	abe50513          	addi	a0,a0,-1346 # 80025128 <disk+0x2128>
    80006672:	ffffa097          	auipc	ra,0xffffa
    80006676:	626080e7          	jalr	1574(ra) # 80000c98 <release>
}
    8000667a:	60e2                	ld	ra,24(sp)
    8000667c:	6442                	ld	s0,16(sp)
    8000667e:	64a2                	ld	s1,8(sp)
    80006680:	6902                	ld	s2,0(sp)
    80006682:	6105                	addi	sp,sp,32
    80006684:	8082                	ret
      panic("virtio_disk_intr status");
    80006686:	00002517          	auipc	a0,0x2
    8000668a:	38a50513          	addi	a0,a0,906 # 80008a10 <syscall_arg+0x358>
    8000668e:	ffffa097          	auipc	ra,0xffffa
    80006692:	eb0080e7          	jalr	-336(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
