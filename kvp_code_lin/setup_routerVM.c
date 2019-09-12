#include <stdio.h>  
#include <stdlib.h>  
#include <unistd.h>  
#include <string.h>  
#include <errno.h>  
#include <fcntl.h>
#include <time.h>  
#include <sys/stat.h>
#include "/usr/include/linux/hyperv.h"  

#define BUFSIZE 256
  
typedef struct kvp_record  
{  
    unsigned char key [HV_KVP_EXCHANGE_MAX_KEY_SIZE];  
    unsigned char value [HV_KVP_EXCHANGE_MAX_VALUE_SIZE];  
} KVP_RECORD;  


void KVPAcquireWriteLock(int);
void KVPAcquireLock(int);
void KVPReleaseLock(int);
void createKVP(char *key, char *value);
char *readKVP(char *key);
void deleteKVP(char *key);
int find_record_offset(int fd, char *key);
void str_replace(char *, char *, char *);

int main (int argc, char **argv)
{   
    FILE *fp, *fp_in, *fp_out;
    char readValue[BUFSIZE];
    char line[BUFSIZE];
    char buf[BUFSIZE];
    char ipPub[BUFSIZE];
    char ipApp[BUFSIZE];
    char ipGateway[BUFSIZE];
    char ipDns[BUFSIZE];
    clock_t c_start, c_end;
    int i;
    

    //
    // Initialize KVP
    //
    deleteKVP("init");
    deleteKVP("key");
    deleteKVP("ip");

    //
    // This program is started by cron after the boot
    // Create init key
    //
    createKVP("init", "SYN");
    
    //
    // Check if host sent ssh key to router VM
    //
    while (1) {
        strcpy(readValue, readKVP("key"));    
        if (!strcmp(readValue, "SEND")) {
            break;
        }
        sleep(1);
        continue;
    }
    printf("key : %s\n", readValue);
    
    //
    // Rename ssh key and change its permission
    //
    rename("/root/.ssh/id_rsa.pub", "/root/.ssh/authorized_keys"); 
    chmod("/root/.ssh/authorized_keys", S_IRUSR | S_IWUSR);

    createKVP("key", "OK");
    
    //
    // Check if host sent IP address to router VM
    //
    while (1) {
        strcpy(readValue, readKVP("ip"));
        if (!strcmp(readValue, "NULL")) {
            sleep(1);
            continue;
        }
        break;
    }
    printf("ip : %s\n", readValue);

    //
    // Set IP address
    //
    strcpy(ipPub, readKVP("ipPub"));
    strcpy(ipApp, readKVP("ipApp"));
    strcpy(ipGateway, readKVP("ipGateway"));
    strcpy(ipDns, readKVP("ipDns"));

    strcpy(line, "/root/routerVM_setup/setup_eth0.sh ");
    strcat(line, ipPub);
    strcat(line, " ");
    strcat(line, ipGateway);
    strcat(line, " ");
    strcat(line, ipDns);
    system(line);

    strcpy(line, "/root/routerVM_setup/setup_eth1.sh ");
    strcat(line, ipApp);
    system(line);

    //
    // Setup OSPF
    //
    strcpy(readValue, readKVP("netPub"));

    if ((fp_in = fopen("/etc/quagga/ospfd.conf.sav", "r")) == NULL) {
        exit(1);
    }
    if ((fp_out = fopen("/etc/quagga/ospfd.conf.bak1", "w")) == NULL) {
        exit(1);
    }
    while (fgets(buf,  BUFSIZE, fp_in) != NULL) {
        str_replace(buf, "sample1", readValue);
        if (fputs(buf, fp_out) == EOF) {
            fprintf(stderr, "Error: cannot write ospf file\n");
            exit(1);
        }
    }
    fclose(fp_in);
    fclose(fp_out);
    
    strcpy(readValue, readKVP("netApp"));

    if ((fp_in = fopen("/etc/quagga/ospfd.conf.bak1", "r")) == NULL) {
        exit(1);
    }
    if ((fp_out = fopen("/etc/quagga/ospfd.conf.bak2", "w")) == NULL) {
        exit(1);
    }
    while (fgets(buf,  BUFSIZE, fp_in) != NULL) {
        str_replace(buf, "sample2", readValue);
        if (fputs(buf, fp_out) == EOF) {
            fprintf(stderr, "Error: cannot write ospf file\n");
            exit(1);
        }
    }
    fclose(fp_in);
    fclose(fp_out);

    strcpy(line, "/root/routerVM_setup/setup_ospf.sh");
    system(line); 

    createKVP("ip", "OK");

    strcpy(line, "/root/routerVM_setup/setup_cron.sh");
    system(line);

    //
    // tmp
    //
    for (i = 0; i < 5; i++) {
        sleep(1);
    }


    //
    // Initialize KVP
    //
    deleteKVP("init");
    deleteKVP("key");
    deleteKVP("ip");
    
    return 0;
}

  
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
  
void createKVP (char *key, char *value)  
{  
    char poolName[] = "/var/lib/hyperv/.kvp_pool_1";  
    int   fd;  
    KVP_RECORD newKvp;   
  
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
    memcpy(newKvp.key, key, strlen(key));  
    memcpy(newKvp.value, value, strlen(value));  
  
    //  
    // Write the KVP data to the pool  
    //  
    KVPAcquireWriteLock(fd);  
    write(fd, (void *)&newKvp, sizeof(KVP_RECORD));  
    KVPReleaseLock(fd);  
  
    close(fd);  
}

char *readKVP (char *key)
{
    char poolName[] = "/var/lib/hyperv/.kvp_pool_0";
    int i;
    int fd;
    int bytesRead;
    int numRecords;
    KVP_RECORD myRecords[200];
    char value[20];

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

    strcpy(value, "NULL");    

    for (i=0; i<numRecords; i++)
    {
        if (!strcmp(key, myRecords[i].key)) {
            strcpy(value, myRecords[i].value);
            close(fd);

            return value;
        }
    }

    close(fd);
    
    return value;
}

void deleteKVP (char *key)
{
    char  poolName[] = "/var/lib/hyperv/.kvp_pool_1";
    int   fd;
    int   exitVal = -1;
    int   bytesRead;
    int   bytesWritten;
    int   offset_to_delete;
    int   offset_last_record;
    KVP_RECORD kvpRec;

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
    offset_to_delete = find_record_offset(fd, key);
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

void str_replace(char *buf, char *old, char *new)
{
    char tmp[BUFSIZE];
    char *p;

    while ((p = strstr(buf, old)) != NULL) {
        *p = '\0';
        p += strlen(old);
        strcpy(tmp, p);
        strcat(buf, new);
        strcat(buf, tmp);
    }
}
