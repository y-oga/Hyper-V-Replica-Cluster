#include <stdio.h>  
#include <stdlib.h>  
#include <unistd.h>  
#include <string.h>  
#include <errno.h>  
#include <fcntl.h>  
#include <uapi/linux/hyperv.h>  
  
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
  
int find_record_offset(int fd, char *key)  
{  
    int bytesRead;  
    int offset = 0;  
    int retval = -1;  
  
    KVP_RECORD kvpRec;  
  
    while (1)  
    {  
        lseek(fd, offset, SEEK_SET);  
    bytesRead = read(fd, &kvpRec, sizeof(KVP_RECORD));  
        if (0 == bytesRead)  
        {  
            break;  
        }  
  
        if (0 == strcmp(key, (const char *) kvpRec.key))  
        {  
            retval = offset;  
            break;  
        }  
  
        offset += sizeof(KVP_RECORD);  
    }  
  
    return retval;  
}  
  
int main (int argc, char **argv)  
{  
    char  poolName[] = "/var/lib/hyperv/.kvp_pool_1";  
    int   fd;  
    int   exitVal = -1;  
    int   bytesRead;  
    int   bytesWritten;  
    int   offset_to_delete;  
    int   offset_last_record;  
    KVP_RECORD kvpRec;   
  
    if (2 != argc)  
    {  
        printf("Usage: WritePool keyName valueString\n\n");  
        exit (-5);  
    }  
  
    //  
    // Open the specific pool file  
    // Note: Pool 1 is the only pool a user program should write to!  
    //  
    fd = open(poolName, O_RDWR, 0644);  
    if (-1 == fd)  
    {  
        printf("Error: Unable to open pool file %s\n", poolName);  
        exit (-10);  
    }  
  
    //  
    // Try to find the record to delete  
    //  
    KVPAcquireWriteLock(fd);  
    offset_to_delete = find_record_offset(fd, argv[1]);  
    if (offset_to_delete < 0)  
    {  
        exitVal = -15;  
        goto cleanup2;  
    }  
  
    //  
    // Compute offset of last record in file  
    //  
    offset_last_record = lseek(fd, -sizeof(KVP_RECORD), SEEK_END);  
    if (offset_last_record < 0)  
    {  
        exitVal = -20;  
        goto cleanup2;  
    }  
  
    //  
    // If record to delete is not last record in file,  
    // copy last record in file over record to delete  
    //  
    if (offset_last_record != offset_to_delete)  
    {  
        lseek(fd, offset_last_record, SEEK_SET);  
        bytesRead = read(fd, &kvpRec, sizeof(KVP_RECORD));  
        lseek(fd, offset_to_delete, SEEK_SET);  
        bytesWritten = write(fd, &kvpRec, sizeof(KVP_RECORD));  
    }  
  
    //  
    // Truncate file by size of KVP record  
    //  
    ftruncate(fd, offset_last_record);  
  
    exitVal = 0;  
  
 cleanup2:  
    KVPReleaseLock(fd);  
  
cleanup1:  
    close(fd);  
  
    return exitVal;  
}