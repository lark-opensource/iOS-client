//
//  IESMetadataIndexesMap.m
//  IESMetadataStorage
//
//  Created by 陈煜钏 on 2021/9/1.
//

#import "IESMetadataIndexesMap.h"

@implementation IESMetadataIndexesMap
{
    CFMutableDictionaryRef _cache;
    dispatch_semaphore_t _lock;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        _lock = dispatch_semaphore_create(1);
    }
    return self;
}

- (int)indexForMetadata:(NSObject<IESMetadataProtocol> *)metadata
{
    NSString *identity = [metadata metadataIdentity];
    if (identity.length == 0) {
        NSCAssert(NO, @"Metadata identity should not be nil");
        return -1;
    }
    
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    CFNumberRef indexRef = CFDictionaryGetValue(_cache, (__bridge const void *)identity);
    int index = -1;
    if (indexRef != NULL) {
        CFNumberGetValue(indexRef, kCFNumberIntType, &index);
    }
    dispatch_semaphore_signal(_lock);
    return index;
}

- (void)setIndex:(int)index forMetadata:(NSObject<IESMetadataProtocol> *)metadata
{
    NSString *identity = [metadata metadataIdentity];
    if (identity.length == 0) {
        NSCAssert(NO, @"Metadata identity should not be nil");
        return;
    }
    
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    CFNumberRef indexRef = CFNumberCreate(NULL, kCFNumberIntType, &index);
    CFDictionarySetValue(_cache, (__bridge const void *)identity, indexRef);
    CFRelease(indexRef);
    dispatch_semaphore_signal(_lock);
}

- (void)clearAllIndexes
{
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    CFDictionaryRemoveAllValues(_cache);
    dispatch_semaphore_signal(_lock);
}

@end
