//
//  HMDEMCollectData.cpp
//  AWECloudCommand
//
//  Created by maniackk on 2021/5/28.
//

#include "HMDEMCollectData.h"
#include "HMDMacro.h"
#import "HeimdallrUtilities.h"
#import "HMDSessionTracker.h"
#import "HMDEvilMethodTracer+private.h"
#include "HMDEMMacro.h"
#include <string>
#include <sys/mman.h>
#include <vector>
#import "NSDictionary+HMDJSON.h"
#import "NSDictionary+HMDSafe.h"

static const int HMDEMfileMaxBytesNums = 2 * HMD_MB;
static const int HMDEMcustomParameterBytes = 300;
static const int HMDEMfuncDataBytes = 43;

static dispatch_queue_t HMDEMSerialQueue = nil;
static int file = -1;
static char *addr = NULL;
static char *currentPath = NULL;
static off_t currentSize = 0;//__int64_t

void getEMFilePath(char **path) {
    NSString *baseDir = [HMDEvilMethodTracer sharedInstance].uploader.EMRootPath;
    NSString *emname = [NSString stringWithFormat:@"%@-%lld",[[HMDSessionTracker sharedInstance] eternalSessionID], (long long)([NSDate date].timeIntervalSince1970 * 1000)];
    NSString *EMPath = [baseDir stringByAppendingPathComponent:emname];
    *path = strdup([EMPath UTF8String]);
}

bool bulidEMMmap(int *file, char **addr, off_t *fileBeginPosition, char **path) {
    getEMFilePath(path);
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
    
    //写入文件表头
    char buff[1024];
    char* header = [[HMDEvilMethodTracer sharedInstance] getEMParameter];
    if (header) {
        snprintf(buff, sizeof(buff), "%s%s\n", header, EMSeparator);
        free(header);
    }
    std::string commitid = buff;
    const char *temp = commitid.c_str();
    ssize_t writeRes = write(*file, temp, commitid.length());
    
    
    if (writeRes == -1) {
        close(*file);
        //Error writing start byte to the file
        if (remove(*path) == -1) {
            //after writing start byte to the file fail,delete file fail
        }
        return false;
    }
    
    *fileBeginPosition = lseek(*file, 0, SEEK_END);
    if ( *fileBeginPosition == -1) {
        close(*file);
        //Error get file lengt
        return false;
    }
    
    if (ftruncate(*file, HMDEMfileMaxBytesNums) != 0) {
        return false;
    }
    
    *addr = (char *)mmap(NULL, HMDEMfileMaxBytesNums, PROT_READ | PROT_WRITE, MAP_SHARED, *file, 0);//mmap 要求是unsigned long
    if (*addr == MAP_FAILED)
    {
        close(*file);
        //Error mmapping the file
        return false;
    }
    return true;
}

static bool deallocEMMmap(){
    bool flag = true;
    //this file is full, deallocEMMmap
    if (msync(addr, currentSize, MS_SYNC) == -1)
    {
        //Could not sync the file to disk
        flag = false;
    }
    
    if (flag && ftruncate(file, currentSize) != 0) {
        flag = false;
    }

    if (flag && munmap(addr, HMDEMfileMaxBytesNums) == -1)
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

static void freeDataVec(std::vector<EMFuncMeta *> *data) {
    typename std::vector<EMFuncMeta *>::iterator iter;
    for(iter = (*data).begin(); iter != (*data).end(); iter++) {
        free(*iter);
    }
    delete data;
    data = NULL;
}

bool writeParamsToDisk(integer_t runloopCostTime, uint64_t runloopStartTime, uint64_t runloopEndTime) {
    NSDictionary *dic = [[HMDEvilMethodTracer sharedInstance] getEventsParameter:runloopCostTime runloopStartTime:runloopStartTime runloopEndTime:runloopEndTime];
    if (!dic) {
        return false;
    }
    NSString *tmpNum = @"\"%@\":%@,";
    NSString *tmpStr = @"\"%@\":\"%@\",";
    std::string paramsDataStr = "{";
    for (NSString * key in dic) {
        id value = dic[key];
        NSString *Val;
        if ([key isEqualToString:@"is_background"]) {
            Val = [NSString stringWithFormat:tmpNum, key, value];
        }
        else {
            Val = [NSString stringWithFormat:[value isKindOfClass:NSNumber.class]?tmpNum:tmpStr, key, value];
        }
        std::string ValStr = std::string([Val UTF8String]);
        paramsDataStr = paramsDataStr.append(ValStr);
    }
    paramsDataStr = paramsDataStr + "\"emdata\":\"";
    
    if (paramsDataStr.length() + currentSize > HMDEMfileMaxBytesNums){
        if (!deallocEMMmap() || !bulidEMMmap(&file, &addr,&currentSize, &currentPath)) {
            //bulidEMMmap fail
            file = -1;
            addr = NULL;
            return false;
        }
    }
    memcpy(addr + currentSize, paramsDataStr.c_str(), paramsDataStr.length());
    currentSize += paramsDataStr.length();
    return true;
}

void writeEndFlagsToDisk(void) {
    size_t buff_len = 16;
    char *buff = new char[buff_len];
    if (buff == NULL) {
        return;
    }
    snprintf(buff, buff_len, "\"}\n%s\n",EMSeparator);
    std::string dataStr(buff);
    delete[] buff;
    if (dataStr.length() + currentSize > HMDEMfileMaxBytesNums){
        return;
    }
    memcpy(addr + currentSize, dataStr.c_str(), dataStr.length());
    currentSize += dataStr.length();
}

template<typename T> void mmapWriteEMVectorDataToDisk(T *datamap, integer_t runloopCostTime, uint64_t runloopStartTime, uint64_t runloopEndTime) {
    //（去掉错误数据） 头条上慢函数数据，很多中间多一个函数开始的记录；但是调试还无法复现,先做兼容
    EMFuncMeta* lastFuncMeta = NULL;
    typename T::iterator iter;
    for(iter = (*datamap).begin(); iter != (*datamap).end();) {
        EMFuncMeta* curFuncMeta = *iter;
        if (lastFuncMeta && lastFuncMeta->phase=='B' && curFuncMeta->phase=='E' && lastFuncMeta->hash!=curFuncMeta->hash) {
            iter = (*datamap).erase(iter-1);
//            lastFuncMeta = *(iter-1);
            lastFuncMeta = NULL;
        }
        else {
            iter++;
            lastFuncMeta = curFuncMeta;
        }
    }
    if ((*datamap).size()==0) {
        return;
    }
    
    if (file == -1) {
        if (!bulidEMMmap(&file, &addr,&currentSize, &currentPath)) {
            freeDataVec(datamap);//bulidEMMmap fail；丢弃本次数据
            file = -1;//防止bulidEMMmap由于非打开文件失败，下次进来的时候不走bulidEMMmap
            addr = NULL;
            return;
        }
    }
    //判断本次数据是否可以写满
    unsigned long estimatedLen = 200 + (*datamap).size() * 43; //ParamsLen:200
    if (estimatedLen +  currentSize > HMDEMfileMaxBytesNums) {
        if (!deallocEMMmap() || !bulidEMMmap(&file, &addr,&currentSize, &currentPath)) {
            //bulidEMMmap fail
            freeDataVec(datamap);//丢弃本次数据
            file = -1;
            addr = NULL;
            return;
        }
    }
    
    //写入磁盘
    if (!writeParamsToDisk(runloopCostTime, runloopStartTime, runloopEndTime)) {
        freeDataVec(datamap);//丢弃本次数据
        return;
    }
    for(iter = (*datamap).begin(); iter != (*datamap).end(); iter++) {
        EMFuncMeta* curFuncMeta = *iter;
        char record_buff[43];
        snprintf(record_buff, 43, "%c,%llu,%d.%06d\\n",
                 curFuncMeta->phase,
                 curFuncMeta->hash,
                 curFuncMeta->wall_ts.seconds, curFuncMeta->wall_ts.microseconds);
        size_t strLen = strlen(record_buff);
        if (strLen + currentSize > HMDEMfileMaxBytesNums){
            if (!deallocEMMmap() || !bulidEMMmap(&file, &addr,&currentSize, &currentPath)) {
                //bulidEMMmap fail
                freeDataVec(datamap);//丢弃本次数据
                file = -1;
                addr = NULL;
                return;
            }
        }
        memcpy(addr + currentSize, record_buff, strLen);
        currentSize += strLen;
    }
    writeEndFlagsToDisk();
    freeDataVec(datamap);
}

void writeEMDataToDisk(void *dataMap, integer_t runloopCostTime, uint64_t runloopStartTime, uint64_t runloopEndTime) {
    if (!HMDEMSerialQueue) {
        HMDEMSerialQueue = dispatch_queue_create("com.heimdallr.evilmethodrecord", DISPATCH_QUEUE_SERIAL);
    }
    if (dataMap) {
        dispatch_async(HMDEMSerialQueue, ^(){
            mmapWriteEMVectorDataToDisk((std::vector<EMFuncMeta *> *)dataMap, runloopCostTime, runloopStartTime, runloopEndTime);
        });
    }
}


template<typename T>
void cleanEMVecData(T *datamap) {
    //（去掉错误数据） 头条上慢函数数据，很多中间多一个函数开始的记录；但是调试还无法复现,先做兼容
    EMFuncMeta* lastFuncMeta = NULL;
    for(typename T::iterator iter = (*datamap).begin(); iter != (*datamap).end();) {
        EMFuncMeta* curFuncMeta = *iter;
        if (lastFuncMeta && lastFuncMeta->phase=='B' && curFuncMeta->phase=='E' && lastFuncMeta->hash!=curFuncMeta->hash) {
            iter = (*datamap).erase(iter-1);
            lastFuncMeta = NULL;
        }
        else {
            iter++;
            lastFuncMeta = curFuncMeta;
        }
    }
}

BOOL checkFileAvailable(size_t dataMapSize) {
    // 1. 创建文件，写入文件表头
    if (file == -1) {
        if (!bulidEMMmap(&file, &addr,&currentSize, &currentPath)) {
            return NO;
        }
    }
    // 2. 当前文件不能容纳过多数据，创建新文件
    unsigned long estimatedLen = HMDEMcustomParameterBytes + dataMapSize * HMDEMfuncDataBytes;
    if (estimatedLen +  currentSize > HMDEMfileMaxBytesNums) {
        if (!deallocEMMmap() || !bulidEMMmap(&file, &addr,&currentSize, &currentPath)) {
            return NO;
        }
    }
    return YES;
}

template<typename T>
void writeFrameDropParameterAndEMVecData(T *datamap, integer_t costTime, uint64_t startTime, uint64_t endTime, NSTimeInterval hitch, bool isScrolling) {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    NSDictionary *params = [[HMDEvilMethodTracer sharedInstance] getEventsParameter:costTime startTime:startTime endTime:endTime hitch:hitch isScrolling:isScrolling];
    [data addEntriesFromDictionary:params];
    
    std::string emFuncData;
    for(typename T::iterator iter = (*datamap).begin(); iter != (*datamap).end(); iter++) {
        EMFuncMeta* curFuncMeta = *iter;
        char record_buff[HMDEMfuncDataBytes];
        snprintf(record_buff, HMDEMfuncDataBytes, "%c,%llu,%d.%06d\n",
                 curFuncMeta->phase,
                 curFuncMeta->hash,
                 curFuncMeta->wall_ts.seconds, curFuncMeta->wall_ts.microseconds);
        emFuncData += std::string(record_buff);
    }
    NSString *emFuncDataStr = [NSString stringWithCString:emFuncData.c_str() encoding:NSUTF8StringEncoding];
    [data hmd_setObject:emFuncDataStr forKey:@"emdata"];
    NSString *dataStr = [data hmd_jsonString];
    
    const char *emData =(char*)[dataStr UTF8String];

    size_t buff_len = strlen(emData) +16;
    char *buff = new char[buff_len];
    if (buff == NULL) {
        return;
    }
    snprintf(buff, buff_len, "%s\n%s\n", emData, EMSeparator);
    
    if (strlen(buff) + currentSize > HMDEMfileMaxBytesNums){
        return;
    }
    memcpy(addr + currentSize, buff, strlen(buff));
    currentSize += strlen(buff);
    delete[] buff;
}


template<typename T>
void mmapWriteCustomEMDataToDisk(T *datamap, integer_t costTime, uint64_t startTime, uint64_t endTime, NSTimeInterval hitch, bool isScrolling) {
    // 1. 清洗脏数据
    cleanEMVecData(datamap);
    if ((*datamap).size()==0) {
        return;
    }
    
    // 2. 创建文件，写入文件表头
    if(!checkFileAvailable((*datamap).size())) {
        freeDataVec(datamap);//丢弃本次数据
        file = -1;
        addr = NULL;
        return;
    }
    
    writeFrameDropParameterAndEMVecData(datamap, costTime, startTime, endTime, hitch, isScrolling);
    
}

void writeCustomEMDataToDisk(void *dataMap, integer_t costTime, uint64_t startTime, uint64_t endTime, NSTimeInterval hitch, bool isScrolling) {
    if (!HMDEMSerialQueue) {
        HMDEMSerialQueue = dispatch_queue_create("com.heimdallr.evilmethodrecord", DISPATCH_QUEUE_SERIAL);
    }
    if (dataMap) {
        dispatch_async(HMDEMSerialQueue, ^(){
            mmapWriteCustomEMDataToDisk((std::vector<EMFuncMeta *> *)dataMap, costTime, startTime, endTime, hitch, isScrolling);
        });
    }
}

void __heimdallr_instrument_sync_close_file(void) {
    if (HMDEMSerialQueue) {
        dispatch_sync(HMDEMSerialQueue, ^(){
            deallocEMMmap();
        });
    }
}

