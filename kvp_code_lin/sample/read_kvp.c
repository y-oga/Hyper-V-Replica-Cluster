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
  
KVP_RECORD myRecords[200];  
  
void KVPAcquireLock(int fd)  
{  
    struct flock fl = {F_RDLCK, SEEK_SET, 0, 0, 0};  
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
    char poolName[] = "/var/lib/hyperv/.kvp_pool_0";  
    int   i;  
    int   fd;  
    int   bytesRead;  
    int   numRecords;  
  
    //  
    // Open the specific pool file  
    //  
    fd = open(poolName, O_RDONLY);  
    if (-1 == fd)  
    {  
        printf("Error: Unable to open pool file %s\n", poolName);  
        exit (-30);  
    }  
  
    //  
    // Read a bunch of records.  Note, this sample code  
    // may not read all records (it will read a max of 200 records).  
    //  
    KVPAcquireLock(fd);  
    bytesRead = read(fd, myRecords, sizeof(myRecords));  
    KVPReleaseLock(fd);  
  
    //  
    // Compute the number of records read and display the data  
    //  
    numRecords = bytesRead / sizeof(struct kvp_record);  
    printf("Number of records : %d\n", numRecords);  
  
    for (i=0; i<numRecords; i++)  
    {  
        printf("  Key  : %s\n  Value: %s\n\n", myRecords[i].key, myRecords[i].value);  
    }  
  
    close(fd);  
  
    return 0;  
}