#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int 
main(int argc, char *argv[]) 
{ 
	char s[64];
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
      //printf("Child: WE DON'T SEE THIS\n"); 
      exit(0);  
    } else { 
      id = wait(0); 
      //printf("Parent: child terminated\n"); 
    } 
    exit(0); 
}