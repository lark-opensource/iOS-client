/*
 * MediaLoader
 *
 * Author:taohaiqing(taohaiqing@bytedance.com)
 * Date:2018-10-23
 * Copyright (c) 2018 bytedance

 * This file is part of MediaLoader.
 *
 */
#pragma once
#include"AVMDLBase.h"
#include <vector>
#include <map>
NS_MEDIALOADER_BEGIN

// interface version for so plugin version check
#define AVMDLIOManagerInterfaceVersion 5

class AVMDLIOTask;
class AVMDLIOTaskInfo;
class AVMDLoader;
class AVMDLIOTaskListener {
public:
    // @param session: 下载session
    // @param key: 事件枚举
    enum IOTaskCallBack{
     IsTaskCallbackDownStart = 1000,
     IsTaskCallbackDownEnd = 1001,
     IsTaskCallbackProgress = 1002,
     IsTaskCallbackFileSize = 1003,
    };
    // @param value: [optional]
    AVMDLIOTaskListener();
    virtual ~AVMDLIOTaskListener();
    virtual void onTaskInfo(IOTaskCallBack key, int64_t value, const char* param, AVMDLIOTask*task, AVMDLIOTaskInfo &info,
            std::map<std::string, std::string>* otherInfo = nullptr) = 0;
};
class AVMDLDownloadContext {
public:
    AVMDLDownloadContext();
    AVMDLDownloadContext(const AVMDLDownloadContext& src);
    ~AVMDLDownloadContext();
    AVMDLDownloadContext& operator =(const AVMDLDownloadContext& src);
    void reset();
public:
    int64_t off, size;     // 下载起始位置和大小 [MUST]
    int   downloaderType;  // 下载器类型 [MUST]
    int   socketFd;        // 连接socekt [OPTIONAL]
    int   openTimeout;     // 连接超时[OPTIONAL]
    int   readTimeout;     // 读超时 [OPTIONAL]
    int   bufferSize;      // buffer 大小 [OPTIONAL]
    int   blockFlag;
    char* url;             // 下载地址 [MUST]
    char* header;          // 自定义header [OPTIONAL]
    char* iplist;          // 节点列表，可以为空 [OPTIONAL]
    int64_t pieceSize;     // (bytes)拆分 range 尾部边界需要对齐的 size [OPTIONAL]
    int64_t rangeSizeMin;  // (bytes)拆分的range大小不低于该值 [OPTIONAL]
    int64_t jitterBufMin;  // (ms)全链路水位控制不低于该值 [OPTIONAL]
};
typedef enum AVMDLStrategyResult {
    StrategyReturnOK = 0,
    StrategyReturnFail = -1,
} AVMDLStrategyResult;
class AVMDLStrategyInterface {
public:
    AVMDLStrategyInterface();
    virtual ~AVMDLStrategyInterface();
public:
    // @param ctx: download context which can be modified by strategy
    // @return value:
    // TIPS: if return value is ok, then we trust the ctx and use it to download
    // if return value is fail, then fallback to our local strategy.
    virtual int obtainAVMDLDownloadContext(AVMDLDownloadContext* ctx, AVMDLIOTask* task) = 0;
};
typedef enum AVMDLIOTaskReadSource {
    IsNormalRead = 1,
    IsPreRead = 2,
} AVMDLIOTaskReadSource;
class AVMDLIOTaskInfo {
public:
    AVMDLIOTaskInfo();
    AVMDLIOTaskInfo(const AVMDLIOTaskInfo& src);
    ~AVMDLIOTaskInfo();
    bool isMatched(AVMDLIOTaskInfo& info);
    AVMDLIOTaskInfo& operator =(const AVMDLIOTaskInfo& src);
public:
    char* vid;
    char* fileKey;
    char* traceId;
    char* taskId;
    int64_t off;
    int64_t size;
    int taskType;
    int isHeader;
    int bitrate;
    bool isForbidP2P;
    AVMDLIOTaskReadSource readSource;
    /*request url list*/
    std::vector<char*> mUrls;
    char* extraInfo;
};
typedef enum AVMDLIOTaskType {
    IsPlayIOTask = 1 ,
    IsPreloadIOTask = 2 ,
    IsSimplePostTask = 3,
} AVMDLIOTaskType;
typedef enum AVMDLIOTaskKey{
    AVMDLIOTaskKeyIsDownloadOff = 100,
    AVMDLIOTaskKeyIsState = 101,
    AVMDLIOTaskKeyIsSetNonBlockRange = 102,
    AVMDLIOTaskKeyIsSetNonBlockRangeMaxSizeKB = 103,
}AVMDLIOTaskKey;
typedef enum AVMDLIOTaskState{
    AVMDLIOTaskStateIsNotInited = 1000,
    AVMDLIOTaskStateIsActive = 1001,
    AVMDLIOTaskStateIsRunning = 1002,
    AVMDLIOTaskStateIsClosed = 1003,
}AVMDLIOTaskState;

class AVMDLIOTask {
public:
    AVMDLIOTask();
    virtual ~AVMDLIOTask();
    virtual void setTaskInfo(AVMDLIOTaskInfo &info);
    virtual bool isMatched(AVMDLIOTaskInfo &info);
    virtual void getTaskInfo(AVMDLIOTaskInfo& info);
    virtual int start();
    virtual int stop();
    virtual int pause();
    virtual int resume();
    virtual int64_t getInt64Value(AVMDLIOTaskKey key);
    virtual void setInt64Value(AVMDLIOTaskKey key, int64_t value);
    virtual void setListener(AVMDLIOTaskListener* listener);
    virtual void setStrategy(AVMDLStrategyInterface* listener);
    virtual int syncPostBody(const std::string& body);
    virtual AVMDLoader* getLoaderPtr();
private:
    AVMDLIOTaskState mState;
};
typedef enum AVMDLStrategyCenterKey {
    AVMDLStrategyCenterKeyIsTaskStart = 1000,
    AVMDLStrategyCenterKeyIsTaskEnd = 1001,
    AVMDLStrategyCenterKeyIsUseCache = 1002,
    AVMDLStrategyCenterKeyIsFileDelete = 1003,
    AVMDLStrategyCenterKeyIsSpeedInfo = 1004,
    AVMDLStrategyCenterKeyIsTaskBeginOpen = 1005,
    AVMDLStrategyCenterKeyIsMDLStateUpdate = 1006,
    AVMDLStrategyCenterKeyIsSpeedEngine = 1007,
}AVMDLStrategyCenterKey;
class AVMDLStrategyCenterListener {
public:
    AVMDLStrategyCenterListener();
    virtual ~AVMDLStrategyCenterListener();
    virtual void onNotify(AVMDLStrategyCenterKey key, AVMDLIOTaskInfo& info, AVMDLIOTask* task,
                          std::map<std::string, std::string>* otherInfo, int64_t value = -1, char* param = nullptr);


    enum StrategyCenterInfoKey {
        IsGetCurrentMediaId_String = 1000,
        IsGetMeidaAudioBitrate_Int64 = 1001,
        IsGetMeidaVideoBitrate_Int64 = 1002,
        IsGetCurrentPlayVideoCacheMS_Int64 = 1003,
        IsGetCurrentPlayAudioCacheMS_Int64 = 1004,
        IsGetCurrentPlayAudioReadCacheOffset_Int64 = 1005,
        IsGetCurrentPlayVideoReadCacheOffset_Int64 = 1006,
    };

    virtual int64_t getInt64Value(StrategyCenterInfoKey key, const char* param) = 0;
    virtual float getFloatValue(StrategyCenterInfoKey key, const char* param) = 0;
    virtual char *getCStringValue(StrategyCenterInfoKey key, const char *param) = 0;
};
typedef enum AVMDLIOManagerKey{
    AVMDLIOManagerKeyIsTaskStart = 1001,
    AVMDLIOManagerKeyIsTaskEnd = 1002,
    AVMDLIOManagerKeyIsUseCache = 1003,
    AVMDLIOManagerKeyIsFileDelete = 1004,
    AVMDLIOManagerKeyIsSpeedInfo = 1005,
    AVMDLIOManagerKeyIsTaskBeginOpen = 1006,
    AVMDLIOManagerKeyIsSpeedEngine = 1007,
    AVMDLIOManagerKeyIsUtilFactory = 2000,
    AVMDLIOManagerKeyIsFileSize = 2001,
    AVMDLIOManagerKeyIsCacheEndOff = 2002,
    AVMDLIOManagerKeyIsMDLState = 2003,
} AVMDLIOManagerKey;

typedef enum AVMDLIOManagerMDLState {
    AVMDLIOManagerMDLStateInit = 0,
    AVMDLIOManagerMDLStateRunning = 1,
    AVMDLIOManagerMDLStateExit = 2,
} AVMDLIOManagerMDLState;

class AVMDLIOManager {
public:
    AVMDLIOManager();
    virtual ~AVMDLIOManager();
    virtual void notifyTaskInfo(AVMDLIOManagerKey key, AVMDLIOTask* task, AVMDLIOTaskInfo& info,
                                std::map<std::string, std::string>* otherInfo, int64_t value = -1, char* param = nullptr);
    virtual void setStrategyCenter(AVMDLStrategyCenterListener* listener);
    // task
    virtual const char* rewriteUri(const char* fileId, const char* params);
    virtual void convertToIOTaskInfo(const char* uri, AVMDLIOTaskInfo** infoP);
    virtual AVMDLIOTask *addTask(AVMDLIOTaskInfo &info, AVMDLIOTask *ioTask);
    virtual bool removeTask(AVMDLIOTask *ioTask);
    virtual AVMDLIOTask* getTask(AVMDLIOTaskInfo& info);

    virtual AVMDLIOTask* getPostTask(AVMDLIOTaskInfo& info);
    //if task find, return true, if not return false
    virtual bool releaseTask(AVMDLIOTask **taskPtr);
    // info
    virtual int64_t getInt64Value(AVMDLIOManagerKey key, const char* key1, int64_t key2);
    virtual const char* getInfo(AVMDLIOManagerKey key, char* key1);
    virtual void setInt64Value(AVMDLIOManagerKey key, char* key1, int64_t value);
    virtual AVMDLIOTask *createAndStarPreloadTask(AVMDLIOTaskInfo &info, AVMDLIOTaskListener* listener);
public:
    
};
NS_MEDIALOADER_END
