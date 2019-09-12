#include <stdio.h>  
#include <stdlib.h>  
#include <unistd.h>  
#include <string.h>  
#include <errno.h>  
#include <fcntl.h>  
#include "../include/linux/hyperv.h"  
  
typedef struct kvp_record  
{  
    unsigned char key [HV_KVP_EXCHANGE_MAX_KEY_SIZE];  
    unsigned char value [HV_KVP_EXCHANGE_MAX_VALUE_SIZE];  
} KVP_RECORD;  
  
void KVPAcquireWriteLock(int fd)  
{  
    struct flock fl = {F_WRLCK, SEEK_SET, 0, 0, 0};  
    fl.l_pid = getpid();  
  
    if (-1 == fcntl(fd, F_SETLKW, &fl))  
    {  
        perror("fcntl lock");  
        exit (-10);  
    }  
}  
  
void KVPReleaseLock(int fd)  
{  
    struct flock fl = {F_UNLCK, SEEK_SET, 0, 0, 0};  
    fl.l_pid = getpid();  
  
    if (-1 == fcntl(fd, F_SETLK, &fl))  
    {  
        perror("fcntl unlock");  
        exit (-20);  
    }  
}  
  
int main (int argc, char **argv)  
{  
    char poolName[] = "/var/lib/hyperv/.kvp_pool_1";  
    int   fd;  
    KVP_RECORD newKvp;   
  
    if (3 != argc)  
    {  
        printf("Usage: WritePool keyName valueString\n\n");  
        exit (-5);  
    }  
  
    //  
    // Open the specific pool file  
    // Note: Pool 1 is the only pool a user program should write to!  
    //  
    fd = open(poolName, O_WRONLY);  
    if (-1 == fd)  
    {  
        printf("Error: Unable to open pool file %s\n", poolName);  
        exit (-30);  
    }  
  
    //  
    // Populate the data buffer with the key value items  
    //  
    memset((void *)&newKvp, 0, sizeof(KVP_RECORD));  
    memcpy(newKvp.key, argv[1], strlen(argv[1]));  
    memcpy(newKvp.value, argv[2], strlen(argv[2]));  
  
    //  
    // Write the KVP data to the pool  
    //  
    KVPAcquireWriteLock(fd);  
    write(fd, (void *)&newKvp, sizeof(KVP_RECORD));  
    KVPReleaseLock(fd);  
  
    close(fd);  
  
    return 0;  
}