#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int 
main(int argc, char *argv[]) 
{ 
  
  if(argc <= 2){
    fprintf(2, "argument missing \n");
    exit(1);
  }
    int pid = atoi(argv[2]);
    int sp = atoi(argv[1]); //static priority
    int oldsp = set_priority(sp,pid);
    if(oldsp==-1){
        fprintf(2, "set_priority: did not find pid %s\n", argv[1]);
    }
    exit(0); 
}