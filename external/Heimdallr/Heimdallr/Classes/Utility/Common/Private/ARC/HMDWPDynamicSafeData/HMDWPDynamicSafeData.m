//
//  HMDWPDynamicSafeData.m
//  Heimdallr
//
//  Created by sunrunwang on 2021/11/29.
//

#include <stdatomic.h>
#import "HMDWPDynamicSafeData.h"
#import "HMDMacro.h"
#import "HMDDynamicCall.h"
# // pthread_extended.h 需要放在最后导入 望周知
#include "pthread_extended.h"

// HMDWPDynamicSafeData 实现原理文档
// https://bytedance.feishu.cn/docs/doccnhSyJexxN1THZYbEwn2c9ye

typedef void * pointerStoreType;

@interface HMDWPDynamicSafeData ()
@end

@implementation HMDWPDynamicSafeData {
    pthread_mutex_t _mtx;    // 用于保护所有数据的访问
    BOOL _valueStored;       // 异步等待线程是否已经放置好数据
    
    /* 数据储存和读取 */
    
    NSMutableData *_data;    // 如果存入的是非 OC Object 类型, 应该放置在这里
                             // 并且在初始化的时刻, data 就应该初始化了合理的大小
    
                             // 如果存入的是 OC Object 类型, 不应该放置在这里
                             // 并且在初始化的时刻, data 并没有初始化, 应该全局为 nil
    
    pointerStoreType _store; // 用于存放 object 类型的中转处
    id __strong _object;     // 用来存放返回为 object 类型
}

@synthesize atomicInfo = _atomicInfo;

#pragma mark - 创建时根据返回参数不同类型进行初始化 2 选 1

#pragma mark 返回类型是 数据类型 (非 OC object)

+ (instancetype)safeDataWithSize:(NSUInteger)size {
    return [[HMDWPDynamicSafeData alloc] initWithLength:size];
}

#pragma mark 返回类型是 OC Object

+ (instancetype)safeDataStoreObject {
    return [[HMDWPDynamicSafeData alloc] initStoreObject];
}

#pragma mark - 异步执行工作线程存放数据通用使用以下方法 (统一使用以下这一个方法)

- (void)storeData:(void *)data {
    DEBUG_ASSERT(data != NULL);
    if(data == NULL) return;
    mutex_lock(_mtx);
    if(_data == nil) {      // 我们正在尝试存入 OC Object
        memcpy(&_store, data, sizeof(_store));
        _object = (__bridge id)_store;
        
    } else {                // 我们正在尝试存入 data blob
        size_t size = _data.length;
        void *destination = _data.mutableBytes;
        if(size > 0 && destination != NULL) {
            memcpy(destination, data, size);
        } DEBUG_ELSE
    }
    _valueStored = YES;
    mutex_unlock(_mtx);
}

#pragma mark - 同步等待完成工作线程读取数据方法 (从下列2选1, 需要和创建时使用的方法匹配)

#pragma mark 创建时使用的是 safeDataWithSize: 那么用此方法获取数据

- (BOOL)getDataIfPossible:(void *)data {
    if(data == NULL) DEBUG_RETURN(NO);
    BOOL valueAcquired = NO;
    int tryLockSuccess = mutex_trylock(_mtx);
    if(tryLockSuccess == 0) {
        if(_valueStored) {
            if(_data != NULL) {
                size_t size = _data.length;
                void *from = _data.mutableBytes;
                if(size > 0 && from != NULL) {
                    memcpy(data, from, size);
                    valueAcquired = YES;
                } DEBUG_ELSE
            } DEBUG_ELSE        // critical error: should not happen
        } ELSE_DEBUG_LOG("[HMDWP] value not stored");
        mutex_unlock(_mtx);
    } ELSE_DEBUG_LOG("[HMDWP] try lock failed");
    return valueAcquired;
}

#pragma mark 创建时使用的是 safeDataStoreObject 那么用此方法获取数据

- (id _Nullable)getObject {
    id returnValue = nil;
    int tryLockSuccess = mutex_trylock(_mtx);
    if(tryLockSuccess == 0) {
        DEBUG_ASSERT(_data == nil);
        if(_valueStored) {
            returnValue = _object;
        } ELSE_DEBUG_LOG("[HMDWP] value not stored");
        mutex_unlock(_mtx);
    } ELSE_DEBUG_LOG("[HMDWP] try lock failed");
    return returnValue;
}

#pragma mark - 安全的原子数据同步

- (uint64_t)atomicInfo {
    return __atomic_load_n(&_atomicInfo, __ATOMIC_ACQUIRE);
}

- (void)setAtomicInfo:(uint64_t)atomicInfo {
    __atomic_store_n(&_atomicInfo, atomicInfo, __ATOMIC_RELEASE);
}

#pragma mark - Private 不应该对外暴露

- (instancetype)initStoreObject {
    if(self = [super init]) {
        mutex_init_normal(_mtx);
    }
    return self;
}

- (instancetype)initWithLength:(NSUInteger)length {
    if(self = [super init]) {
        mutex_init_normal(_mtx);
        _data = [[NSMutableData alloc] initWithLength:length];
//        _valueStored = NO;
    }
    return self;
}

- (void)dealloc {
    // mutex 最后是否销毁并不会引起问题
    mutex_destroy(_mtx);
}

@end
