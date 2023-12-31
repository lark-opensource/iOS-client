//
//  HMDOrderFileCollectData.cpp
//  AWECloudCommand
//
//  Created by maniackk on 2021/11/16.
//

#include "HMDOrderFileCollectData.h"
#import "HeimdallrUtilities.h"
#import "HMDSessionTracker.h"
#include <string>
#include <sys/mman.h>
#include <map>

static const int HMDOrderFileMaxBytesNums = 100 * (1024.f * 1024.f); //100MB
static dispatch_queue_t HMDOFSerialQueue = nil;
static int file = -1;
static char *addr = NULL;
static char *currentPath = NULL;
static off_t currentSize = 0;


void getOrderFilePath(char **path) {
    NSString *baseDir = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:@"HMDOrderFile"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:baseDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:baseDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *ofname = [NSString stringWithFormat:@"%@",[[HMDSessionTracker sharedInstance] eternalSessionID]];
    NSString *OFPath = [baseDir stringByAppendingPathComponent:ofname];
    *path = strdup([OFPath UTF8String]);
}

bool bulidOrderMmap(int *file, char **addr, off_t *fileBeginPosition, char **path) {
    getOrderFilePath(path);
    if (!path || !*path) {
        return false;
    }
    
    if( 0 == access(*path,F_OK)){
        return false;
    }
    
    *file = open(*path, O_CREAT|O_RDWR,0666);
    if(-1 == *file)
    {
        //open file eror
        return false;
    }
    
    if (ftruncate(*file, HMDOrderFileMaxBytesNums) != 0) {
        return false;
    }
    
    *addr = (char *)mmap(NULL, HMDOrderFileMaxBytesNums, PROT_READ | PROT_WRITE, MAP_SHARED, *file, 0);//mmap 要求是unsigned long
    if (*addr == MAP_FAILED)
    {
        close(*file);
        *file = -1;
        //Error mmapping the file
        return false;
    }
    return true;
}

void writeFinishTag() {
    if (file != -1) {
        const char *record_buff = "====order_file_end====";
        size_t strLen = strlen(record_buff);
        assert((strLen + currentSize < HMDOrderFileMaxBytesNums) && "TODO: OrderFile is too small!");
        memcpy(addr + currentSize, record_buff, strLen);
        currentSize += strLen;
    }
}

static bool deallocOrderMmap(){
    writeFinishTag();
    bool flag = true;
    //this file is full, deallocOrderMmap
    if (msync(addr, currentSize, MS_SYNC) == -1)
    {
        //Could not sync the file to disk
        flag = false;
    }
    
    if (flag && ftruncate(file, currentSize) != 0) {
        flag = false;
    }

    if (flag && munmap(addr, HMDOrderFileMaxBytesNums) == -1)
    {
        //Error un-mmapping the file
        flag = false;
    }
    close(file);
    file = -1;
    addr = NULL;
    currentSize = 0;
    currentPath = NULL;
    return flag;
}

template<typename T> void mmapWriteOrderVectorDataToDisk(T *datamap) {
    if (file == -1) {
        if (!bulidOrderMmap(&file, &addr,&currentSize, &currentPath)) {
            delete datamap;//bulidOrderMmap fail；丢弃本次数据
            if (file != -1) close(file);
            file = -1;//防止bulidOrderMmap由于非打开文件失败，下次进来的时候不走bulidOrderMmap
            addr = NULL;
            return;
        }
    }
    
    typename T::iterator iter;
    for(iter = (*datamap).begin(); iter != (*datamap).end(); iter++) {
        std::pair<u_int64_t, std::pair<integer_t, integer_t>> pair = *iter;
        u_int64_t hash = pair.first;
        std::pair<integer_t, integer_t> second = pair.second;
        char record_buff[41];
        snprintf(record_buff, 41, "%d.%06d,%llu\\n", second.first, second.second, hash);
        size_t strLen = strlen(record_buff);
        assert((strLen + currentSize < HMDOrderFileMaxBytesNums) && "TODO: OrderFile is too small!");
        memcpy(addr + currentSize, record_buff, strLen);
        currentSize += strLen;
    }
    delete datamap;
}

void writeOrderFileDataToDisk(void *dataMap) {
    if (dataMap) {
        dispatch_async(HMDOFSerialQueue, ^(){
            mmapWriteOrderVectorDataToDisk((std::map<u_int64_t, std::pair<integer_t, integer_t>> *)dataMap);
        });
    }
}

BOOL setupOFCollectData(void) {
    if (!HMDOFSerialQueue) {
        HMDOFSerialQueue = dispatch_queue_create("com.heimdallr.orderfilerecord", DISPATCH_QUEUE_SERIAL);
    }
    return true;
}

void finishWriteFile(void) {
    dispatch_async(HMDOFSerialQueue, ^(){
        deallocOrderMmap();
    });
}
