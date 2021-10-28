
user/_strace:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/stat.h"
#include "user/user.h"

int 
main(int argc, char *argv[]) 
{ 
   0:	711d                	addi	sp,sp,-96
   2:	ec86                	sd	ra,88(sp)
   4:	e8a2                	sd	s0,80(sp)
   6:	e4a6                	sd	s1,72(sp)
   8:	e0ca                	sd	s2,64(sp)
   a:	1080                	addi	s0,sp,96
	char s[64];
  int id;
  if(argc <= 1){
   c:	4785                	li	a5,1
   e:	04a7d763          	bge	a5,a0,5c <main+0x5c>
  12:	84ae                	mv	s1,a1
    fprintf(2, "argument missing \n");
    exit(1);
  }
    int mask = atoi(argv[1]);
  14:	6588                	ld	a0,8(a1)
  16:	00000097          	auipc	ra,0x0
  1a:	1ec080e7          	jalr	492(ra) # 202 <atoi>
  1e:	892a                	mv	s2,a0
	strcpy(s,argv[2]);
  20:	688c                	ld	a1,16(s1)
  22:	fa040513          	addi	a0,s0,-96
  26:	00000097          	auipc	ra,0x0
  2a:	066080e7          	jalr	102(ra) # 8c <strcpy>
    argv+=2;
  id = fork();
  2e:	00000097          	auipc	ra,0x0
  32:	2cc080e7          	jalr	716(ra) # 2fa <fork>

	
    if (id == 0) { 
  36:	e129                	bnez	a0,78 <main+0x78>
      trace(mask);
  38:	854a                	mv	a0,s2
  3a:	00000097          	auipc	ra,0x0
  3e:	370080e7          	jalr	880(ra) # 3aa <trace>
      exec(s, argv); 
  42:	01048593          	addi	a1,s1,16
  46:	fa040513          	addi	a0,s0,-96
  4a:	00000097          	auipc	ra,0x0
  4e:	2f8080e7          	jalr	760(ra) # 342 <exec>
      //printf("Child: WE DON'T SEE THIS\n"); 
      exit(0);  
  52:	4501                	li	a0,0
  54:	00000097          	auipc	ra,0x0
  58:	2ae080e7          	jalr	686(ra) # 302 <exit>
    fprintf(2, "argument missing \n");
  5c:	00000597          	auipc	a1,0x0
  60:	7dc58593          	addi	a1,a1,2012 # 838 <malloc+0xe8>
  64:	4509                	li	a0,2
  66:	00000097          	auipc	ra,0x0
  6a:	5fe080e7          	jalr	1534(ra) # 664 <fprintf>
    exit(1);
  6e:	4505                	li	a0,1
  70:	00000097          	auipc	ra,0x0
  74:	292080e7          	jalr	658(ra) # 302 <exit>
    } else { 
      id = wait(0); 
  78:	4501                	li	a0,0
  7a:	00000097          	auipc	ra,0x0
  7e:	290080e7          	jalr	656(ra) # 30a <wait>
      //printf("Parent: child terminated\n"); 
    } 
    exit(0); 
  82:	4501                	li	a0,0
  84:	00000097          	auipc	ra,0x0
  88:	27e080e7          	jalr	638(ra) # 302 <exit>

000000000000008c <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  8c:	1141                	addi	sp,sp,-16
  8e:	e422                	sd	s0,8(sp)
  90:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  92:	87aa                	mv	a5,a0
  94:	0585                	addi	a1,a1,1
  96:	0785                	addi	a5,a5,1
  98:	fff5c703          	lbu	a4,-1(a1)
  9c:	fee78fa3          	sb	a4,-1(a5)
  a0:	fb75                	bnez	a4,94 <strcpy+0x8>
    ;
  return os;
}
  a2:	6422                	ld	s0,8(sp)
  a4:	0141                	addi	sp,sp,16
  a6:	8082                	ret

00000000000000a8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  a8:	1141                	addi	sp,sp,-16
  aa:	e422                	sd	s0,8(sp)
  ac:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  ae:	00054783          	lbu	a5,0(a0)
  b2:	cb91                	beqz	a5,c6 <strcmp+0x1e>
  b4:	0005c703          	lbu	a4,0(a1)
  b8:	00f71763          	bne	a4,a5,c6 <strcmp+0x1e>
    p++, q++;
  bc:	0505                	addi	a0,a0,1
  be:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  c0:	00054783          	lbu	a5,0(a0)
  c4:	fbe5                	bnez	a5,b4 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  c6:	0005c503          	lbu	a0,0(a1)
}
  ca:	40a7853b          	subw	a0,a5,a0
  ce:	6422                	ld	s0,8(sp)
  d0:	0141                	addi	sp,sp,16
  d2:	8082                	ret

00000000000000d4 <strlen>:

uint
strlen(const char *s)
{
  d4:	1141                	addi	sp,sp,-16
  d6:	e422                	sd	s0,8(sp)
  d8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  da:	00054783          	lbu	a5,0(a0)
  de:	cf91                	beqz	a5,fa <strlen+0x26>
  e0:	0505                	addi	a0,a0,1
  e2:	87aa                	mv	a5,a0
  e4:	4685                	li	a3,1
  e6:	9e89                	subw	a3,a3,a0
  e8:	00f6853b          	addw	a0,a3,a5
  ec:	0785                	addi	a5,a5,1
  ee:	fff7c703          	lbu	a4,-1(a5)
  f2:	fb7d                	bnez	a4,e8 <strlen+0x14>
    ;
  return n;
}
  f4:	6422                	ld	s0,8(sp)
  f6:	0141                	addi	sp,sp,16
  f8:	8082                	ret
  for(n = 0; s[n]; n++)
  fa:	4501                	li	a0,0
  fc:	bfe5                	j	f4 <strlen+0x20>

00000000000000fe <memset>:

void*
memset(void *dst, int c, uint n)
{
  fe:	1141                	addi	sp,sp,-16
 100:	e422                	sd	s0,8(sp)
 102:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 104:	ce09                	beqz	a2,11e <memset+0x20>
 106:	87aa                	mv	a5,a0
 108:	fff6071b          	addiw	a4,a2,-1
 10c:	1702                	slli	a4,a4,0x20
 10e:	9301                	srli	a4,a4,0x20
 110:	0705                	addi	a4,a4,1
 112:	972a                	add	a4,a4,a0
    cdst[i] = c;
 114:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 118:	0785                	addi	a5,a5,1
 11a:	fee79de3          	bne	a5,a4,114 <memset+0x16>
  }
  return dst;
}
 11e:	6422                	ld	s0,8(sp)
 120:	0141                	addi	sp,sp,16
 122:	8082                	ret

0000000000000124 <strchr>:

char*
strchr(const char *s, char c)
{
 124:	1141                	addi	sp,sp,-16
 126:	e422                	sd	s0,8(sp)
 128:	0800                	addi	s0,sp,16
  for(; *s; s++)
 12a:	00054783          	lbu	a5,0(a0)
 12e:	cb99                	beqz	a5,144 <strchr+0x20>
    if(*s == c)
 130:	00f58763          	beq	a1,a5,13e <strchr+0x1a>
  for(; *s; s++)
 134:	0505                	addi	a0,a0,1
 136:	00054783          	lbu	a5,0(a0)
 13a:	fbfd                	bnez	a5,130 <strchr+0xc>
      return (char*)s;
  return 0;
 13c:	4501                	li	a0,0
}
 13e:	6422                	ld	s0,8(sp)
 140:	0141                	addi	sp,sp,16
 142:	8082                	ret
  return 0;
 144:	4501                	li	a0,0
 146:	bfe5                	j	13e <strchr+0x1a>

0000000000000148 <gets>:

char*
gets(char *buf, int max)
{
 148:	711d                	addi	sp,sp,-96
 14a:	ec86                	sd	ra,88(sp)
 14c:	e8a2                	sd	s0,80(sp)
 14e:	e4a6                	sd	s1,72(sp)
 150:	e0ca                	sd	s2,64(sp)
 152:	fc4e                	sd	s3,56(sp)
 154:	f852                	sd	s4,48(sp)
 156:	f456                	sd	s5,40(sp)
 158:	f05a                	sd	s6,32(sp)
 15a:	ec5e                	sd	s7,24(sp)
 15c:	1080                	addi	s0,sp,96
 15e:	8baa                	mv	s7,a0
 160:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 162:	892a                	mv	s2,a0
 164:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 166:	4aa9                	li	s5,10
 168:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 16a:	89a6                	mv	s3,s1
 16c:	2485                	addiw	s1,s1,1
 16e:	0344d863          	bge	s1,s4,19e <gets+0x56>
    cc = read(0, &c, 1);
 172:	4605                	li	a2,1
 174:	faf40593          	addi	a1,s0,-81
 178:	4501                	li	a0,0
 17a:	00000097          	auipc	ra,0x0
 17e:	1a8080e7          	jalr	424(ra) # 322 <read>
    if(cc < 1)
 182:	00a05e63          	blez	a0,19e <gets+0x56>
    buf[i++] = c;
 186:	faf44783          	lbu	a5,-81(s0)
 18a:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 18e:	01578763          	beq	a5,s5,19c <gets+0x54>
 192:	0905                	addi	s2,s2,1
 194:	fd679be3          	bne	a5,s6,16a <gets+0x22>
  for(i=0; i+1 < max; ){
 198:	89a6                	mv	s3,s1
 19a:	a011                	j	19e <gets+0x56>
 19c:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 19e:	99de                	add	s3,s3,s7
 1a0:	00098023          	sb	zero,0(s3)
  return buf;
}
 1a4:	855e                	mv	a0,s7
 1a6:	60e6                	ld	ra,88(sp)
 1a8:	6446                	ld	s0,80(sp)
 1aa:	64a6                	ld	s1,72(sp)
 1ac:	6906                	ld	s2,64(sp)
 1ae:	79e2                	ld	s3,56(sp)
 1b0:	7a42                	ld	s4,48(sp)
 1b2:	7aa2                	ld	s5,40(sp)
 1b4:	7b02                	ld	s6,32(sp)
 1b6:	6be2                	ld	s7,24(sp)
 1b8:	6125                	addi	sp,sp,96
 1ba:	8082                	ret

00000000000001bc <stat>:

int
stat(const char *n, struct stat *st)
{
 1bc:	1101                	addi	sp,sp,-32
 1be:	ec06                	sd	ra,24(sp)
 1c0:	e822                	sd	s0,16(sp)
 1c2:	e426                	sd	s1,8(sp)
 1c4:	e04a                	sd	s2,0(sp)
 1c6:	1000                	addi	s0,sp,32
 1c8:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1ca:	4581                	li	a1,0
 1cc:	00000097          	auipc	ra,0x0
 1d0:	17e080e7          	jalr	382(ra) # 34a <open>
  if(fd < 0)
 1d4:	02054563          	bltz	a0,1fe <stat+0x42>
 1d8:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1da:	85ca                	mv	a1,s2
 1dc:	00000097          	auipc	ra,0x0
 1e0:	186080e7          	jalr	390(ra) # 362 <fstat>
 1e4:	892a                	mv	s2,a0
  close(fd);
 1e6:	8526                	mv	a0,s1
 1e8:	00000097          	auipc	ra,0x0
 1ec:	14a080e7          	jalr	330(ra) # 332 <close>
  return r;
}
 1f0:	854a                	mv	a0,s2
 1f2:	60e2                	ld	ra,24(sp)
 1f4:	6442                	ld	s0,16(sp)
 1f6:	64a2                	ld	s1,8(sp)
 1f8:	6902                	ld	s2,0(sp)
 1fa:	6105                	addi	sp,sp,32
 1fc:	8082                	ret
    return -1;
 1fe:	597d                	li	s2,-1
 200:	bfc5                	j	1f0 <stat+0x34>

0000000000000202 <atoi>:

int
atoi(const char *s)
{
 202:	1141                	addi	sp,sp,-16
 204:	e422                	sd	s0,8(sp)
 206:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 208:	00054603          	lbu	a2,0(a0)
 20c:	fd06079b          	addiw	a5,a2,-48
 210:	0ff7f793          	andi	a5,a5,255
 214:	4725                	li	a4,9
 216:	02f76963          	bltu	a4,a5,248 <atoi+0x46>
 21a:	86aa                	mv	a3,a0
  n = 0;
 21c:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 21e:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 220:	0685                	addi	a3,a3,1
 222:	0025179b          	slliw	a5,a0,0x2
 226:	9fa9                	addw	a5,a5,a0
 228:	0017979b          	slliw	a5,a5,0x1
 22c:	9fb1                	addw	a5,a5,a2
 22e:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 232:	0006c603          	lbu	a2,0(a3)
 236:	fd06071b          	addiw	a4,a2,-48
 23a:	0ff77713          	andi	a4,a4,255
 23e:	fee5f1e3          	bgeu	a1,a4,220 <atoi+0x1e>
  return n;
}
 242:	6422                	ld	s0,8(sp)
 244:	0141                	addi	sp,sp,16
 246:	8082                	ret
  n = 0;
 248:	4501                	li	a0,0
 24a:	bfe5                	j	242 <atoi+0x40>

000000000000024c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 24c:	1141                	addi	sp,sp,-16
 24e:	e422                	sd	s0,8(sp)
 250:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 252:	02b57663          	bgeu	a0,a1,27e <memmove+0x32>
    while(n-- > 0)
 256:	02c05163          	blez	a2,278 <memmove+0x2c>
 25a:	fff6079b          	addiw	a5,a2,-1
 25e:	1782                	slli	a5,a5,0x20
 260:	9381                	srli	a5,a5,0x20
 262:	0785                	addi	a5,a5,1
 264:	97aa                	add	a5,a5,a0
  dst = vdst;
 266:	872a                	mv	a4,a0
      *dst++ = *src++;
 268:	0585                	addi	a1,a1,1
 26a:	0705                	addi	a4,a4,1
 26c:	fff5c683          	lbu	a3,-1(a1)
 270:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 274:	fee79ae3          	bne	a5,a4,268 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 278:	6422                	ld	s0,8(sp)
 27a:	0141                	addi	sp,sp,16
 27c:	8082                	ret
    dst += n;
 27e:	00c50733          	add	a4,a0,a2
    src += n;
 282:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 284:	fec05ae3          	blez	a2,278 <memmove+0x2c>
 288:	fff6079b          	addiw	a5,a2,-1
 28c:	1782                	slli	a5,a5,0x20
 28e:	9381                	srli	a5,a5,0x20
 290:	fff7c793          	not	a5,a5
 294:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 296:	15fd                	addi	a1,a1,-1
 298:	177d                	addi	a4,a4,-1
 29a:	0005c683          	lbu	a3,0(a1)
 29e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2a2:	fee79ae3          	bne	a5,a4,296 <memmove+0x4a>
 2a6:	bfc9                	j	278 <memmove+0x2c>

00000000000002a8 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2a8:	1141                	addi	sp,sp,-16
 2aa:	e422                	sd	s0,8(sp)
 2ac:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2ae:	ca05                	beqz	a2,2de <memcmp+0x36>
 2b0:	fff6069b          	addiw	a3,a2,-1
 2b4:	1682                	slli	a3,a3,0x20
 2b6:	9281                	srli	a3,a3,0x20
 2b8:	0685                	addi	a3,a3,1
 2ba:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2bc:	00054783          	lbu	a5,0(a0)
 2c0:	0005c703          	lbu	a4,0(a1)
 2c4:	00e79863          	bne	a5,a4,2d4 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2c8:	0505                	addi	a0,a0,1
    p2++;
 2ca:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2cc:	fed518e3          	bne	a0,a3,2bc <memcmp+0x14>
  }
  return 0;
 2d0:	4501                	li	a0,0
 2d2:	a019                	j	2d8 <memcmp+0x30>
      return *p1 - *p2;
 2d4:	40e7853b          	subw	a0,a5,a4
}
 2d8:	6422                	ld	s0,8(sp)
 2da:	0141                	addi	sp,sp,16
 2dc:	8082                	ret
  return 0;
 2de:	4501                	li	a0,0
 2e0:	bfe5                	j	2d8 <memcmp+0x30>

00000000000002e2 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2e2:	1141                	addi	sp,sp,-16
 2e4:	e406                	sd	ra,8(sp)
 2e6:	e022                	sd	s0,0(sp)
 2e8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2ea:	00000097          	auipc	ra,0x0
 2ee:	f62080e7          	jalr	-158(ra) # 24c <memmove>
}
 2f2:	60a2                	ld	ra,8(sp)
 2f4:	6402                	ld	s0,0(sp)
 2f6:	0141                	addi	sp,sp,16
 2f8:	8082                	ret

00000000000002fa <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2fa:	4885                	li	a7,1
 ecall
 2fc:	00000073          	ecall
 ret
 300:	8082                	ret

0000000000000302 <exit>:
.global exit
exit:
 li a7, SYS_exit
 302:	4889                	li	a7,2
 ecall
 304:	00000073          	ecall
 ret
 308:	8082                	ret

000000000000030a <wait>:
.global wait
wait:
 li a7, SYS_wait
 30a:	488d                	li	a7,3
 ecall
 30c:	00000073          	ecall
 ret
 310:	8082                	ret

0000000000000312 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 312:	48e1                	li	a7,24
 ecall
 314:	00000073          	ecall
 ret
 318:	8082                	ret

000000000000031a <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 31a:	4891                	li	a7,4
 ecall
 31c:	00000073          	ecall
 ret
 320:	8082                	ret

0000000000000322 <read>:
.global read
read:
 li a7, SYS_read
 322:	4895                	li	a7,5
 ecall
 324:	00000073          	ecall
 ret
 328:	8082                	ret

000000000000032a <write>:
.global write
write:
 li a7, SYS_write
 32a:	48c1                	li	a7,16
 ecall
 32c:	00000073          	ecall
 ret
 330:	8082                	ret

0000000000000332 <close>:
.global close
close:
 li a7, SYS_close
 332:	48d5                	li	a7,21
 ecall
 334:	00000073          	ecall
 ret
 338:	8082                	ret

000000000000033a <kill>:
.global kill
kill:
 li a7, SYS_kill
 33a:	4899                	li	a7,6
 ecall
 33c:	00000073          	ecall
 ret
 340:	8082                	ret

0000000000000342 <exec>:
.global exec
exec:
 li a7, SYS_exec
 342:	489d                	li	a7,7
 ecall
 344:	00000073          	ecall
 ret
 348:	8082                	ret

000000000000034a <open>:
.global open
open:
 li a7, SYS_open
 34a:	48bd                	li	a7,15
 ecall
 34c:	00000073          	ecall
 ret
 350:	8082                	ret

0000000000000352 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 352:	48c5                	li	a7,17
 ecall
 354:	00000073          	ecall
 ret
 358:	8082                	ret

000000000000035a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 35a:	48c9                	li	a7,18
 ecall
 35c:	00000073          	ecall
 ret
 360:	8082                	ret

0000000000000362 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 362:	48a1                	li	a7,8
 ecall
 364:	00000073          	ecall
 ret
 368:	8082                	ret

000000000000036a <link>:
.global link
link:
 li a7, SYS_link
 36a:	48cd                	li	a7,19
 ecall
 36c:	00000073          	ecall
 ret
 370:	8082                	ret

0000000000000372 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 372:	48d1                	li	a7,20
 ecall
 374:	00000073          	ecall
 ret
 378:	8082                	ret

000000000000037a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 37a:	48a5                	li	a7,9
 ecall
 37c:	00000073          	ecall
 ret
 380:	8082                	ret

0000000000000382 <dup>:
.global dup
dup:
 li a7, SYS_dup
 382:	48a9                	li	a7,10
 ecall
 384:	00000073          	ecall
 ret
 388:	8082                	ret

000000000000038a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 38a:	48ad                	li	a7,11
 ecall
 38c:	00000073          	ecall
 ret
 390:	8082                	ret

0000000000000392 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 392:	48b1                	li	a7,12
 ecall
 394:	00000073          	ecall
 ret
 398:	8082                	ret

000000000000039a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 39a:	48b5                	li	a7,13
 ecall
 39c:	00000073          	ecall
 ret
 3a0:	8082                	ret

00000000000003a2 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3a2:	48b9                	li	a7,14
 ecall
 3a4:	00000073          	ecall
 ret
 3a8:	8082                	ret

00000000000003aa <trace>:
.global trace
trace:
 li a7, SYS_trace
 3aa:	48d9                	li	a7,22
 ecall
 3ac:	00000073          	ecall
 ret
 3b0:	8082                	ret

00000000000003b2 <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 3b2:	48dd                	li	a7,23
 ecall
 3b4:	00000073          	ecall
 ret
 3b8:	8082                	ret

00000000000003ba <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3ba:	1101                	addi	sp,sp,-32
 3bc:	ec06                	sd	ra,24(sp)
 3be:	e822                	sd	s0,16(sp)
 3c0:	1000                	addi	s0,sp,32
 3c2:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3c6:	4605                	li	a2,1
 3c8:	fef40593          	addi	a1,s0,-17
 3cc:	00000097          	auipc	ra,0x0
 3d0:	f5e080e7          	jalr	-162(ra) # 32a <write>
}
 3d4:	60e2                	ld	ra,24(sp)
 3d6:	6442                	ld	s0,16(sp)
 3d8:	6105                	addi	sp,sp,32
 3da:	8082                	ret

00000000000003dc <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3dc:	7139                	addi	sp,sp,-64
 3de:	fc06                	sd	ra,56(sp)
 3e0:	f822                	sd	s0,48(sp)
 3e2:	f426                	sd	s1,40(sp)
 3e4:	f04a                	sd	s2,32(sp)
 3e6:	ec4e                	sd	s3,24(sp)
 3e8:	0080                	addi	s0,sp,64
 3ea:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3ec:	c299                	beqz	a3,3f2 <printint+0x16>
 3ee:	0805c863          	bltz	a1,47e <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3f2:	2581                	sext.w	a1,a1
  neg = 0;
 3f4:	4881                	li	a7,0
 3f6:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3fa:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3fc:	2601                	sext.w	a2,a2
 3fe:	00000517          	auipc	a0,0x0
 402:	45a50513          	addi	a0,a0,1114 # 858 <digits>
 406:	883a                	mv	a6,a4
 408:	2705                	addiw	a4,a4,1
 40a:	02c5f7bb          	remuw	a5,a1,a2
 40e:	1782                	slli	a5,a5,0x20
 410:	9381                	srli	a5,a5,0x20
 412:	97aa                	add	a5,a5,a0
 414:	0007c783          	lbu	a5,0(a5)
 418:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 41c:	0005879b          	sext.w	a5,a1
 420:	02c5d5bb          	divuw	a1,a1,a2
 424:	0685                	addi	a3,a3,1
 426:	fec7f0e3          	bgeu	a5,a2,406 <printint+0x2a>
  if(neg)
 42a:	00088b63          	beqz	a7,440 <printint+0x64>
    buf[i++] = '-';
 42e:	fd040793          	addi	a5,s0,-48
 432:	973e                	add	a4,a4,a5
 434:	02d00793          	li	a5,45
 438:	fef70823          	sb	a5,-16(a4)
 43c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 440:	02e05863          	blez	a4,470 <printint+0x94>
 444:	fc040793          	addi	a5,s0,-64
 448:	00e78933          	add	s2,a5,a4
 44c:	fff78993          	addi	s3,a5,-1
 450:	99ba                	add	s3,s3,a4
 452:	377d                	addiw	a4,a4,-1
 454:	1702                	slli	a4,a4,0x20
 456:	9301                	srli	a4,a4,0x20
 458:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 45c:	fff94583          	lbu	a1,-1(s2)
 460:	8526                	mv	a0,s1
 462:	00000097          	auipc	ra,0x0
 466:	f58080e7          	jalr	-168(ra) # 3ba <putc>
  while(--i >= 0)
 46a:	197d                	addi	s2,s2,-1
 46c:	ff3918e3          	bne	s2,s3,45c <printint+0x80>
}
 470:	70e2                	ld	ra,56(sp)
 472:	7442                	ld	s0,48(sp)
 474:	74a2                	ld	s1,40(sp)
 476:	7902                	ld	s2,32(sp)
 478:	69e2                	ld	s3,24(sp)
 47a:	6121                	addi	sp,sp,64
 47c:	8082                	ret
    x = -xx;
 47e:	40b005bb          	negw	a1,a1
    neg = 1;
 482:	4885                	li	a7,1
    x = -xx;
 484:	bf8d                	j	3f6 <printint+0x1a>

0000000000000486 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 486:	7119                	addi	sp,sp,-128
 488:	fc86                	sd	ra,120(sp)
 48a:	f8a2                	sd	s0,112(sp)
 48c:	f4a6                	sd	s1,104(sp)
 48e:	f0ca                	sd	s2,96(sp)
 490:	ecce                	sd	s3,88(sp)
 492:	e8d2                	sd	s4,80(sp)
 494:	e4d6                	sd	s5,72(sp)
 496:	e0da                	sd	s6,64(sp)
 498:	fc5e                	sd	s7,56(sp)
 49a:	f862                	sd	s8,48(sp)
 49c:	f466                	sd	s9,40(sp)
 49e:	f06a                	sd	s10,32(sp)
 4a0:	ec6e                	sd	s11,24(sp)
 4a2:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4a4:	0005c903          	lbu	s2,0(a1)
 4a8:	18090f63          	beqz	s2,646 <vprintf+0x1c0>
 4ac:	8aaa                	mv	s5,a0
 4ae:	8b32                	mv	s6,a2
 4b0:	00158493          	addi	s1,a1,1
  state = 0;
 4b4:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4b6:	02500a13          	li	s4,37
      if(c == 'd'){
 4ba:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 4be:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 4c2:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 4c6:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4ca:	00000b97          	auipc	s7,0x0
 4ce:	38eb8b93          	addi	s7,s7,910 # 858 <digits>
 4d2:	a839                	j	4f0 <vprintf+0x6a>
        putc(fd, c);
 4d4:	85ca                	mv	a1,s2
 4d6:	8556                	mv	a0,s5
 4d8:	00000097          	auipc	ra,0x0
 4dc:	ee2080e7          	jalr	-286(ra) # 3ba <putc>
 4e0:	a019                	j	4e6 <vprintf+0x60>
    } else if(state == '%'){
 4e2:	01498f63          	beq	s3,s4,500 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 4e6:	0485                	addi	s1,s1,1
 4e8:	fff4c903          	lbu	s2,-1(s1)
 4ec:	14090d63          	beqz	s2,646 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 4f0:	0009079b          	sext.w	a5,s2
    if(state == 0){
 4f4:	fe0997e3          	bnez	s3,4e2 <vprintf+0x5c>
      if(c == '%'){
 4f8:	fd479ee3          	bne	a5,s4,4d4 <vprintf+0x4e>
        state = '%';
 4fc:	89be                	mv	s3,a5
 4fe:	b7e5                	j	4e6 <vprintf+0x60>
      if(c == 'd'){
 500:	05878063          	beq	a5,s8,540 <vprintf+0xba>
      } else if(c == 'l') {
 504:	05978c63          	beq	a5,s9,55c <vprintf+0xd6>
      } else if(c == 'x') {
 508:	07a78863          	beq	a5,s10,578 <vprintf+0xf2>
      } else if(c == 'p') {
 50c:	09b78463          	beq	a5,s11,594 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 510:	07300713          	li	a4,115
 514:	0ce78663          	beq	a5,a4,5e0 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 518:	06300713          	li	a4,99
 51c:	0ee78e63          	beq	a5,a4,618 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 520:	11478863          	beq	a5,s4,630 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 524:	85d2                	mv	a1,s4
 526:	8556                	mv	a0,s5
 528:	00000097          	auipc	ra,0x0
 52c:	e92080e7          	jalr	-366(ra) # 3ba <putc>
        putc(fd, c);
 530:	85ca                	mv	a1,s2
 532:	8556                	mv	a0,s5
 534:	00000097          	auipc	ra,0x0
 538:	e86080e7          	jalr	-378(ra) # 3ba <putc>
      }
      state = 0;
 53c:	4981                	li	s3,0
 53e:	b765                	j	4e6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 540:	008b0913          	addi	s2,s6,8
 544:	4685                	li	a3,1
 546:	4629                	li	a2,10
 548:	000b2583          	lw	a1,0(s6)
 54c:	8556                	mv	a0,s5
 54e:	00000097          	auipc	ra,0x0
 552:	e8e080e7          	jalr	-370(ra) # 3dc <printint>
 556:	8b4a                	mv	s6,s2
      state = 0;
 558:	4981                	li	s3,0
 55a:	b771                	j	4e6 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 55c:	008b0913          	addi	s2,s6,8
 560:	4681                	li	a3,0
 562:	4629                	li	a2,10
 564:	000b2583          	lw	a1,0(s6)
 568:	8556                	mv	a0,s5
 56a:	00000097          	auipc	ra,0x0
 56e:	e72080e7          	jalr	-398(ra) # 3dc <printint>
 572:	8b4a                	mv	s6,s2
      state = 0;
 574:	4981                	li	s3,0
 576:	bf85                	j	4e6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 578:	008b0913          	addi	s2,s6,8
 57c:	4681                	li	a3,0
 57e:	4641                	li	a2,16
 580:	000b2583          	lw	a1,0(s6)
 584:	8556                	mv	a0,s5
 586:	00000097          	auipc	ra,0x0
 58a:	e56080e7          	jalr	-426(ra) # 3dc <printint>
 58e:	8b4a                	mv	s6,s2
      state = 0;
 590:	4981                	li	s3,0
 592:	bf91                	j	4e6 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 594:	008b0793          	addi	a5,s6,8
 598:	f8f43423          	sd	a5,-120(s0)
 59c:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5a0:	03000593          	li	a1,48
 5a4:	8556                	mv	a0,s5
 5a6:	00000097          	auipc	ra,0x0
 5aa:	e14080e7          	jalr	-492(ra) # 3ba <putc>
  putc(fd, 'x');
 5ae:	85ea                	mv	a1,s10
 5b0:	8556                	mv	a0,s5
 5b2:	00000097          	auipc	ra,0x0
 5b6:	e08080e7          	jalr	-504(ra) # 3ba <putc>
 5ba:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5bc:	03c9d793          	srli	a5,s3,0x3c
 5c0:	97de                	add	a5,a5,s7
 5c2:	0007c583          	lbu	a1,0(a5)
 5c6:	8556                	mv	a0,s5
 5c8:	00000097          	auipc	ra,0x0
 5cc:	df2080e7          	jalr	-526(ra) # 3ba <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5d0:	0992                	slli	s3,s3,0x4
 5d2:	397d                	addiw	s2,s2,-1
 5d4:	fe0914e3          	bnez	s2,5bc <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 5d8:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5dc:	4981                	li	s3,0
 5de:	b721                	j	4e6 <vprintf+0x60>
        s = va_arg(ap, char*);
 5e0:	008b0993          	addi	s3,s6,8
 5e4:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 5e8:	02090163          	beqz	s2,60a <vprintf+0x184>
        while(*s != 0){
 5ec:	00094583          	lbu	a1,0(s2)
 5f0:	c9a1                	beqz	a1,640 <vprintf+0x1ba>
          putc(fd, *s);
 5f2:	8556                	mv	a0,s5
 5f4:	00000097          	auipc	ra,0x0
 5f8:	dc6080e7          	jalr	-570(ra) # 3ba <putc>
          s++;
 5fc:	0905                	addi	s2,s2,1
        while(*s != 0){
 5fe:	00094583          	lbu	a1,0(s2)
 602:	f9e5                	bnez	a1,5f2 <vprintf+0x16c>
        s = va_arg(ap, char*);
 604:	8b4e                	mv	s6,s3
      state = 0;
 606:	4981                	li	s3,0
 608:	bdf9                	j	4e6 <vprintf+0x60>
          s = "(null)";
 60a:	00000917          	auipc	s2,0x0
 60e:	24690913          	addi	s2,s2,582 # 850 <malloc+0x100>
        while(*s != 0){
 612:	02800593          	li	a1,40
 616:	bff1                	j	5f2 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 618:	008b0913          	addi	s2,s6,8
 61c:	000b4583          	lbu	a1,0(s6)
 620:	8556                	mv	a0,s5
 622:	00000097          	auipc	ra,0x0
 626:	d98080e7          	jalr	-616(ra) # 3ba <putc>
 62a:	8b4a                	mv	s6,s2
      state = 0;
 62c:	4981                	li	s3,0
 62e:	bd65                	j	4e6 <vprintf+0x60>
        putc(fd, c);
 630:	85d2                	mv	a1,s4
 632:	8556                	mv	a0,s5
 634:	00000097          	auipc	ra,0x0
 638:	d86080e7          	jalr	-634(ra) # 3ba <putc>
      state = 0;
 63c:	4981                	li	s3,0
 63e:	b565                	j	4e6 <vprintf+0x60>
        s = va_arg(ap, char*);
 640:	8b4e                	mv	s6,s3
      state = 0;
 642:	4981                	li	s3,0
 644:	b54d                	j	4e6 <vprintf+0x60>
    }
  }
}
 646:	70e6                	ld	ra,120(sp)
 648:	7446                	ld	s0,112(sp)
 64a:	74a6                	ld	s1,104(sp)
 64c:	7906                	ld	s2,96(sp)
 64e:	69e6                	ld	s3,88(sp)
 650:	6a46                	ld	s4,80(sp)
 652:	6aa6                	ld	s5,72(sp)
 654:	6b06                	ld	s6,64(sp)
 656:	7be2                	ld	s7,56(sp)
 658:	7c42                	ld	s8,48(sp)
 65a:	7ca2                	ld	s9,40(sp)
 65c:	7d02                	ld	s10,32(sp)
 65e:	6de2                	ld	s11,24(sp)
 660:	6109                	addi	sp,sp,128
 662:	8082                	ret

0000000000000664 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 664:	715d                	addi	sp,sp,-80
 666:	ec06                	sd	ra,24(sp)
 668:	e822                	sd	s0,16(sp)
 66a:	1000                	addi	s0,sp,32
 66c:	e010                	sd	a2,0(s0)
 66e:	e414                	sd	a3,8(s0)
 670:	e818                	sd	a4,16(s0)
 672:	ec1c                	sd	a5,24(s0)
 674:	03043023          	sd	a6,32(s0)
 678:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 67c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 680:	8622                	mv	a2,s0
 682:	00000097          	auipc	ra,0x0
 686:	e04080e7          	jalr	-508(ra) # 486 <vprintf>
}
 68a:	60e2                	ld	ra,24(sp)
 68c:	6442                	ld	s0,16(sp)
 68e:	6161                	addi	sp,sp,80
 690:	8082                	ret

0000000000000692 <printf>:

void
printf(const char *fmt, ...)
{
 692:	711d                	addi	sp,sp,-96
 694:	ec06                	sd	ra,24(sp)
 696:	e822                	sd	s0,16(sp)
 698:	1000                	addi	s0,sp,32
 69a:	e40c                	sd	a1,8(s0)
 69c:	e810                	sd	a2,16(s0)
 69e:	ec14                	sd	a3,24(s0)
 6a0:	f018                	sd	a4,32(s0)
 6a2:	f41c                	sd	a5,40(s0)
 6a4:	03043823          	sd	a6,48(s0)
 6a8:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6ac:	00840613          	addi	a2,s0,8
 6b0:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6b4:	85aa                	mv	a1,a0
 6b6:	4505                	li	a0,1
 6b8:	00000097          	auipc	ra,0x0
 6bc:	dce080e7          	jalr	-562(ra) # 486 <vprintf>
}
 6c0:	60e2                	ld	ra,24(sp)
 6c2:	6442                	ld	s0,16(sp)
 6c4:	6125                	addi	sp,sp,96
 6c6:	8082                	ret

00000000000006c8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6c8:	1141                	addi	sp,sp,-16
 6ca:	e422                	sd	s0,8(sp)
 6cc:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6ce:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6d2:	00000797          	auipc	a5,0x0
 6d6:	19e7b783          	ld	a5,414(a5) # 870 <freep>
 6da:	a805                	j	70a <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6dc:	4618                	lw	a4,8(a2)
 6de:	9db9                	addw	a1,a1,a4
 6e0:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6e4:	6398                	ld	a4,0(a5)
 6e6:	6318                	ld	a4,0(a4)
 6e8:	fee53823          	sd	a4,-16(a0)
 6ec:	a091                	j	730 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6ee:	ff852703          	lw	a4,-8(a0)
 6f2:	9e39                	addw	a2,a2,a4
 6f4:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 6f6:	ff053703          	ld	a4,-16(a0)
 6fa:	e398                	sd	a4,0(a5)
 6fc:	a099                	j	742 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6fe:	6398                	ld	a4,0(a5)
 700:	00e7e463          	bltu	a5,a4,708 <free+0x40>
 704:	00e6ea63          	bltu	a3,a4,718 <free+0x50>
{
 708:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 70a:	fed7fae3          	bgeu	a5,a3,6fe <free+0x36>
 70e:	6398                	ld	a4,0(a5)
 710:	00e6e463          	bltu	a3,a4,718 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 714:	fee7eae3          	bltu	a5,a4,708 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 718:	ff852583          	lw	a1,-8(a0)
 71c:	6390                	ld	a2,0(a5)
 71e:	02059713          	slli	a4,a1,0x20
 722:	9301                	srli	a4,a4,0x20
 724:	0712                	slli	a4,a4,0x4
 726:	9736                	add	a4,a4,a3
 728:	fae60ae3          	beq	a2,a4,6dc <free+0x14>
    bp->s.ptr = p->s.ptr;
 72c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 730:	4790                	lw	a2,8(a5)
 732:	02061713          	slli	a4,a2,0x20
 736:	9301                	srli	a4,a4,0x20
 738:	0712                	slli	a4,a4,0x4
 73a:	973e                	add	a4,a4,a5
 73c:	fae689e3          	beq	a3,a4,6ee <free+0x26>
  } else
    p->s.ptr = bp;
 740:	e394                	sd	a3,0(a5)
  freep = p;
 742:	00000717          	auipc	a4,0x0
 746:	12f73723          	sd	a5,302(a4) # 870 <freep>
}
 74a:	6422                	ld	s0,8(sp)
 74c:	0141                	addi	sp,sp,16
 74e:	8082                	ret

0000000000000750 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 750:	7139                	addi	sp,sp,-64
 752:	fc06                	sd	ra,56(sp)
 754:	f822                	sd	s0,48(sp)
 756:	f426                	sd	s1,40(sp)
 758:	f04a                	sd	s2,32(sp)
 75a:	ec4e                	sd	s3,24(sp)
 75c:	e852                	sd	s4,16(sp)
 75e:	e456                	sd	s5,8(sp)
 760:	e05a                	sd	s6,0(sp)
 762:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 764:	02051493          	slli	s1,a0,0x20
 768:	9081                	srli	s1,s1,0x20
 76a:	04bd                	addi	s1,s1,15
 76c:	8091                	srli	s1,s1,0x4
 76e:	0014899b          	addiw	s3,s1,1
 772:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 774:	00000517          	auipc	a0,0x0
 778:	0fc53503          	ld	a0,252(a0) # 870 <freep>
 77c:	c515                	beqz	a0,7a8 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 77e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 780:	4798                	lw	a4,8(a5)
 782:	02977f63          	bgeu	a4,s1,7c0 <malloc+0x70>
 786:	8a4e                	mv	s4,s3
 788:	0009871b          	sext.w	a4,s3
 78c:	6685                	lui	a3,0x1
 78e:	00d77363          	bgeu	a4,a3,794 <malloc+0x44>
 792:	6a05                	lui	s4,0x1
 794:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 798:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 79c:	00000917          	auipc	s2,0x0
 7a0:	0d490913          	addi	s2,s2,212 # 870 <freep>
  if(p == (char*)-1)
 7a4:	5afd                	li	s5,-1
 7a6:	a88d                	j	818 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 7a8:	00000797          	auipc	a5,0x0
 7ac:	0d078793          	addi	a5,a5,208 # 878 <base>
 7b0:	00000717          	auipc	a4,0x0
 7b4:	0cf73023          	sd	a5,192(a4) # 870 <freep>
 7b8:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7ba:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7be:	b7e1                	j	786 <malloc+0x36>
      if(p->s.size == nunits)
 7c0:	02e48b63          	beq	s1,a4,7f6 <malloc+0xa6>
        p->s.size -= nunits;
 7c4:	4137073b          	subw	a4,a4,s3
 7c8:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7ca:	1702                	slli	a4,a4,0x20
 7cc:	9301                	srli	a4,a4,0x20
 7ce:	0712                	slli	a4,a4,0x4
 7d0:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7d2:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7d6:	00000717          	auipc	a4,0x0
 7da:	08a73d23          	sd	a0,154(a4) # 870 <freep>
      return (void*)(p + 1);
 7de:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7e2:	70e2                	ld	ra,56(sp)
 7e4:	7442                	ld	s0,48(sp)
 7e6:	74a2                	ld	s1,40(sp)
 7e8:	7902                	ld	s2,32(sp)
 7ea:	69e2                	ld	s3,24(sp)
 7ec:	6a42                	ld	s4,16(sp)
 7ee:	6aa2                	ld	s5,8(sp)
 7f0:	6b02                	ld	s6,0(sp)
 7f2:	6121                	addi	sp,sp,64
 7f4:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7f6:	6398                	ld	a4,0(a5)
 7f8:	e118                	sd	a4,0(a0)
 7fa:	bff1                	j	7d6 <malloc+0x86>
  hp->s.size = nu;
 7fc:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 800:	0541                	addi	a0,a0,16
 802:	00000097          	auipc	ra,0x0
 806:	ec6080e7          	jalr	-314(ra) # 6c8 <free>
  return freep;
 80a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 80e:	d971                	beqz	a0,7e2 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 810:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 812:	4798                	lw	a4,8(a5)
 814:	fa9776e3          	bgeu	a4,s1,7c0 <malloc+0x70>
    if(p == freep)
 818:	00093703          	ld	a4,0(s2)
 81c:	853e                	mv	a0,a5
 81e:	fef719e3          	bne	a4,a5,810 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 822:	8552                	mv	a0,s4
 824:	00000097          	auipc	ra,0x0
 828:	b6e080e7          	jalr	-1170(ra) # 392 <sbrk>
  if(p == (char*)-1)
 82c:	fd5518e3          	bne	a0,s5,7fc <malloc+0xac>
        return 0;
 830:	4501                	li	a0,0
 832:	bf45                	j	7e2 <malloc+0x92>
