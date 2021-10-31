# Enhancing-xv6-OS
## Specification 1: syscall tracing
### Added $U/_strace to UPROGS in Makefile
### Added a sys_trace() function in kernel/sysproc.c that implements the new system call by remembering its argument in a new variable in the proc structure 
        uint64
    sys_trace()
    {
    int mask;
        if (argint(0, &mask) < 0)
        return -1;
        myproc()->trace_mask = mask;
        return 0;
    } 
###  Modifed fork() (see kernel/proc.c) to copy the trace mask from the parent to the child process.
    np->trace_mask = p->trace_mask;
### Modifed the syscall() function in kernel/syscall.c to print the trace output. You will need to add an array of syscall names and number of arguments to index into.
        static char *syscall_name[]={"","fork","exit","wait","pipe","read","kill","exec","fstat","chdir","dup","getpid","sbrk","sleep","uptime","open","write","mknod","unlink","link","mkdir","close","trace"};
static int syscall_arg[]={0,0,1,1,1,3,1,2,2,1,1,0,1,1,0,2,3,3,1,2,1,1,1};
void
    syscall(void)
    {
    int num;
    struct proc *p = myproc();

    num = p->trapframe->a7;
    if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
        int arg = 0;
        int x = 0;
        int farg = p->trapframe->a0;

        p->trapframe->a0 = syscalls[num]();
        //strace
        int mask = p->trace_mask;
        if (mask >> num)
        {
        printf("%d: syscall %s (", p->pid, syscall_name[num]);
        x= 1;
        printf("%d",farg);
        while(x < syscall_arg[num]){
            printf(" ");
            argint(x, &arg);
            printf("%d",arg);
            x++;
        } 
    
        printf(") -> %d\n", p->trapframe->a0);
        }
    } else {
        printf("%d %s: unknown sys call %d\n",
                p->pid, p->name, num);
        p->trapframe->a0 = -1;
    }
    }


### Created a user program in user/strace.c , to generate the user-space stubs for the system call,
    #include "kernel/types.h"
    #include "kernel/stat.h"
    #include "user/user.h"

    int 
    main(int argc, char *argv[]) 
    { 
        char s[128];
    int id;
    if(argc <= 1){
        fprintf(2, "argument missing \n");
        exit(1);
    }
        int mask = atoi(argv[1]);
        strcpy(s,argv[2]);
        argv+=2;
    id = fork();

        
        if (id == 0) { 
        trace(mask);
        exec(s, argv); 
        exit(0);  
        } else { 
        id = wait(0); 
        } 
        exit(0); 
    }

### added a prototype for the system call to user/user.h , a stub to user/usys.pl , and a syscall number to kernel/syscall.h. The Makefile invokes the Perl script user/usys.pl , which produces user/usys.S , the actual system call stubs, which use the RISC-V ecall instruction to transition to the kernel

# Specification 2: Scheduling
## changes in MAKEFILE
        SCHEDULER = RR
    ifeq ($(SCHEDULER),FCFS)
        SCHEDULER = FCFS
    endif
    ifeq ($(SCHEDULER), PBS)
        SCHEDULER = PBS
    endif
    ifeq ($(SCHEDULER), MLFQ)
        SCHEDULER = MLFQ
    endif

    CFLAGS += -D$(SCHEDULER)

    ifndef CPUS
    CPUS := 3
    endif
    ifeq ($(SCHEDULER), MLFQ)
    CPUS := 1
    endif

## FCFS
### selects the process with the lowest creation time(creation time refers to the tick number when the process was created). The process will run until it no longer needs CPU time.

    void scheduler(void)
        { //printf("FCFS");
        struct proc *p;
        struct proc *fcfs_process = 0;
        struct cpu *c = mycpu();
        c->proc = 0;
        for (;;)
        {
            // Avoid deadlock by ensuring that devices can interrupt.
            intr_on();
            fcfs_process = 0;
            //get the process with minimum creation time and that is runnable
            for (p = proc; p < &proc[NPROC]; p++)
            {
            
                if (p->state == RUNNABLE)
                {
                    if (!fcfs_process)
                    {
                    fcfs_process = p;
                    }
                    else if (fcfs_process->ctime > p->ctime)
                    {
                    fcfs_process = p;
                    //printf("aaa%s",fcfs_process->state);
                    }
                }
            
            }
            //context swich and run the process
            if (fcfs_process)
            {
                p = fcfs_process;

                acquire(&p->lock);
                if (p->state == RUNNABLE)
                {
                    //printf("about to run: %s  [pid %d]\n",p->name,p->pid);
                    // Switch to chosen process.  It is the process's job
                    // to release its lock and then reacquire it
                    // before jumping back to us.
                    p->scheduleNum+=1;
                    p->state = RUNNING;
                    c->proc = p;
                    swtch(&c->context, &p->context);

                    // Process is done running for now.
                    // It should have changed its p->state before coming back.
                    c->proc = 0;
                }
                release(&p->lock);
            }
        }
    }
## PBS
### a non-preemptive priority-based scheduler that selects the processwith the highest priority for execution. In case two or more processes have the same priority, we use the number of times the process has been scheduled to break the tie. If the tie remains, use the start-time of the process to break the tie(processes with lower start times should be scheduled further).
    void scheduler(void)
    {
        //printf("PBS");
        struct proc *p;
        struct proc *pbs_process = 0;
        struct cpu *c = mycpu();
        int niceness = 5;
        int highestDpriority = 0;
        int dp;
        c->proc = 0;
        for (;;)
        {
            // Avoid deadlock by ensuring that devices can interrupt.
            intr_on();
            pbs_process = 0;
            for (p = proc; p < &proc[NPROC]; p++)
            {

                if (p->state == RUNNABLE)
                {
                    niceness = calculate_niceness(p);
                    dp = max(0, min(p->sp - niceness + 5, 100));
                    p->dp = dp;
                    //printf("%d\n", dp);
                    if (!pbs_process)
                    {
                        pbs_process = p;
                        highestDpriority = dp;
                    }
                    else if (highestDpriority > dp)
                    {
                        pbs_process = p;
                
                    }
                    //if dynamic priority is same check number of schedules
                    else if (highestDpriority == dp)
                    {
                        if (p->scheduleNum < pbs_process->scheduleNum)
                        {
                            pbs_process = p;
                        }
                        //check creation time 
                        else if (p->scheduleNum == pbs_process->scheduleNum && p->ctime < pbs_process->ctime)
                        {
                            pbs_process = p;
                        }
                    }
                }
            }
            //switch
            if (pbs_process)
            {
            p = pbs_process;

            acquire(&p->lock);
            if (p->state == RUNNABLE)
            { //if(p->stime >0){
                //printf("about to run: %s [pid %d] %d %d %d,%d %d\n", p->name, p->pid, highestDpriority, niceness, p->rtime, p->stime,p->sp);
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                //}
                p->state = RUNNING;
                p->scheduleNum += 1;
                c->proc = p;
                swtch(&c->context, &p->context);

                // Process is done running for now.
                // It should have changed its p->state before coming back.
                c->proc = 0;
            }
            release(&p->lock);
            }
        }
    }

### niceness
    int calculate_niceness(struct proc *p)
    {
        int niceness = 5;
        if (p->stime == 0 && p->rtime == 0)
            {
                niceness = 5;
            }
        else
        {
            niceness = (p->stime * 10) / (p->stime + p->rtime);
        }
        return niceness;
    }

## set priority system call
### To change the Static Priority add a new system call ​ set_priority(). This resets the niceness to 5 as well. corresponding user program setproiority is also implemented setpriority priority pid
    int set_priority(int sp, int pid)
    {
        int prev = -1;
        struct proc *p;
        for (p = proc; p < &proc[NPROC]; p++)
        {
            if (p->pid == pid)
            {
                prev = p->sp;
                acquire(&p->lock);
                p->sp = sp;
                p->rtime = 0;
                p->stime = 0; //niceness =5
                release(&p->lock);
                if (p->sp > prev)
                {
                    yield();
                }
                break;
            }
        }
        return prev;
    }
## Multilevel Feedback queue scheduling (MLFQ)
### MFQS runs a process for a time quantum and then it can change its priority(if it is a long process). Thus it learns from past behavior of the process and then predicts its future behavior. This way it tries to run a shorter process first thus optimizing turnaround time. MFQS also reduces the response time.
### a simplified preemptive MLFQ scheduler that allows processes to move between different priority queues based on their behavior and CPU bursts.
    ● If a process uses too much CPU time, it is pushed to a lower priority queue,
        leaving I/O bound and interactive processes in the higher priority queues.
    ● To prevent starvation, implement aging.

        void scheduler(void)
    { 
        struct proc *p;
        struct proc *mlfq_process = 0;
        struct cpu *c = mycpu();
        c->proc = 0;
        initializeQueue();
        for (;;)
        {
            // Avoid deadlock by ensuring that devices can interrupt.
            intr_on();
            mlfq_process = 0;
            for (p = proc; p < &proc[NPROC]; p++)
            {
                if (p->state == RUNNABLE && p->level < 0)
                {
                    //printf("%d",p->pid);
                    enqueue(&mlfq[0], p);
                    p->qEntry[0] = ticks;
                    p->level = 0;
                    p->inqueue = 1;
                }
                else if (p->state == RUNNABLE && p->inqueue == 0)
                {
                    enqueue(&mlfq[p->level], p);
                    p->qEntry[p->level]= ticks;
                    
                    p->inqueue = 1;
                }
            }
            for (int i = 0; i < 5; i++)
            {
                if (mlfq[i].rear)
                {
                    mlfq_process = mlfq[i].level[0];
                    dequeue(&mlfq[i]);
                    break;
                    //once out of the queue
                    //1)can exit
                    //2)can go to lower level
                    //3)if its not runnable it will get into same queue when it will be runnable
                }
            }

            if (mlfq_process)
            {
                p = mlfq_process;

                acquire(&p->lock);
                if (p->state == RUNNABLE)
                {
                    //printf("about to run: %s [pid %d]\n",p->name,p->pid);
                    // Switch to chosen process.  It is the process's job
                    // to release its lock and then reacquire it
                    // before jumping back to us
                    p->starttime = ticks;
                    p->scheduleNum +=1;
                    p->state = RUNNING;
                    c->proc = p;
                    swtch(&c->context, &p->context);
                    // Process is done running for now.
                    // It should have changed its p->state before coming back.
                    c->proc = 0;
                }
            release(&p->lock);
            mlfq_process->inqueue = 0;
            ageing();
            }
        }
    }

### helper function
            void dequeue(struct Queue *queue)
        {
        // if queue is empty
        if (!queue->rear)
        {
            panic("Dequeing Emty queue\n");
            return;
        }
        else
        {
            for (int i = 0; i < queue->rear - 1; i++)
            {
            queue->level[i] = queue->level[i + 1];
            }

            // decrement rear
            queue->rear--;
        }
        return;
        }

        void enqueue(struct Queue *queue, struct proc *p)
        {
        // check queue is full or not
        if (QSIZE == queue->rear)
        {
            panic("trying to enqueue in full queue\n");
            return;
        }
        else
        {
            queue->level[queue->rear] = p;
            queue->rear++;
        }
        return;
        }
        void delete (struct Queue *queue, int pos)
        {
        // if queue is empty
        if (queue->rear < pos)
        {
            panic("invalid delete from queue\n");
            return;
        }
        else
        {
            for (int i = pos; i < queue->rear - 1; i++)
            {
            queue->level[i] = queue->level[i + 1];
            }

            // decrement rear
            queue->rear--;
        }
        return;
        }

        void initializeQueue()
        {
            for (int i = 0; i < 5; i++)
            {
                mlfq[i].rear = 0;
            }
        }

    int checknewprocesses(struct proc *current)
        { 
        struct proc *p;
        for (p = proc; p < &proc[NPROC]; p++)
        {
            if (p->state == RUNNABLE && p->level < current->level && current->level != 0 && current->parent->pid!=p->pid)
            {
            return 1;
            }
        }
        return 0;
        }
### Ageing  to prevent starvation   
called in clockintr()

        void ageing()
        {
            struct proc *p;
            for (p = proc; p < &proc[NPROC]; p++)
            {   int age =0;
                if (ticks-p->qEntry[p->level]!=0){
                    age = ticks-p->qEntry[p->level];
                }
                acquire(&p->lock);
                if (p->state == RUNNABLE &&  age > 48 && p->level > 0 && p->inqueue == 1)
                { 
                    for (int i = 0; i < mlfq[p->level].rear; i++)
                    {
                        if (mlfq[p->level].level[i]->pid == p->pid)
                        {
                            delete (&mlfq[p->level], i);
                            break;
                        }
                    }
                    p->level--;
                    p->inqueue = 0;
                    p->qEntry[p->level] = 0;

                } //for rescheduling see kerenel trap and user trap
                release(&p->lock);
            }
        }
### For Preemtion
    Added this in both usertrap and kernel trap in trap.c

        #if MLFQ
    if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    { 
        
        if (ticks - myproc()->starttime >= time_slice[myproc()->level])
        { 
        if (myproc()->level != 4){

            myproc()->level = myproc()->level + 1;
            myproc()->qEntry[myproc()->level] =0;
        }
        yield();
        }
        if(myproc() != 0 &&  checknewprocesses(myproc())){
        
        yield();
        }
    }
    #endif

# Specification 3: procdump
## procdump is a function that is useful for debugging (see kernel/proc.c). It prints a list of processes to the console when a user types Ctrl-p on the console.
    void procdump(void)
        {
        static char *states[] = {
            [UNUSED] "unused",
            [SLEEPING] "sleeping",
            [RUNNABLE] "runnable",
            [RUNNING] "running",
            [ZOMBIE] "zombie"};
        struct proc *p;
        char *state;

        #ifdef MLFQ
            printf("PID Priority  State    rtime  wtime  nrun  q0  q1  q2  q3  q4");
        #elif PBS
            printf("PID    Priority    State    rtime  wtime  nrun ");
        #else 
            printf("PID  State   rtime  wtime  nrun ");
        #endif
        printf("\n");
        for (p = proc; p < &proc[NPROC]; p++)
        {
            if (p->state == UNUSED)
            continue;
            if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
            state = states[p->state];
            else
            state = "???";


            #ifdef PBS
            int wtime = ticks-p->ctime-p->rtime;
            printf("%d    %d        %s    %d    %d    %d", p->pid,p->dp,state,p->rtime,wtime,p->scheduleNum);
            
            #elif MLFQ
            int wtime = ticks-p->qEntry[p->level]; 
            if(p->inqueue == 0){
            wtime =0;
            }
            printf("%d    %d       %s    %d    %d     %d" , p->pid,p->level,state,p->rtime,wtime,p->scheduleNum);
            for(int i=0;i<5;i++){

            printf("    %d",p->q[i]);
            }
            
            #else 
            int wtime = ticks-p->ctime-p->rtime;
            printf("%d   %s    %d    %d    %d", p->pid,state,p->rtime,wtime,p->scheduleNum);
            #endif
            printf("\n");
        }
        }

void update_time()
{
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    {
      p->rtime++;
      p->qrtime[p->level]+=1;
      //printf("%d\n", p->rtime);
    }
    if (p->state == SLEEPING)
    {
      p->stime++;
      //printf("%d\n", p->stime);
    }
    if (p->inqueue == 1)
    {
      p->q[p->level]++;
      //printf("%d\n", p->stime);
    }
    release(&p->lock);
  }
}
nrun is updated in scheduler

## QUESTION
### If a process voluntarily relinquishes control of the CPU(eg. For doing I/O), it leaves the queuing network, and when the process becomes ready again after the I/O, it is​ ​inserted at the tail of the same queue, from which it is relinquished earlier​ ​( Q: Explain in the README how could this be exploited by a process
    A process can have I/O every time just before the timeslice completes and the I/o burst could be really small
    so though the process is more cpu bound it remains in the same priority queue and doesnot degrade .thus gain a higher percentage of CPU time.
# Performance 
    with 25 I/o bound and 50 cpu bound process with 3 cpu
    RR: Average rtime 31,  wtime 328

    with 25 I/o bound and 50 cpu bound process with 1 cpu
    MLFQ:Average rtime 24,  wtime 654

    PBS:with 25 I/o bound with 80 static priority and 50 cpu bound process with deafaut(60) priority with 3 cpu
   Average rtime 36,  wtime 234

    50 cpubound processes   with 3 cpu
    FCFS: Average rtime 62,  wtime 477
