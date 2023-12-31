//
//  IESGurdKitUtil.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/3/5.
//

#import <Foundation/Foundation.h>

#import "IESGeckoDefines.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Base

extern NSString *IESGurdPollingLevel1Group;
extern NSString *IESGurdPollingLevel2Group;
extern NSString *IESGurdPollingLevel3Group;

extern NSArray<NSString *> *IESGurdPollingLevelGroups (void);

/**
 返回客户端通用参数
 */
extern NSDictionary *IESGurdClientCommonParams (void);

/**
 返回客户端基础通用参数
 */
extern NSDictionary *IESGurdClientBasicParams (void);

/**
 返回轮询优先级 key
 */
extern NSString *IESGurdPollingPriorityString (IESGurdPollingPriority priority);

#pragma mark - Hook

extern void IESGurdKitHookInstanceMethod(Class targetClass, SEL originalSEL, SEL swizzledSEL);

extern void IESGurdKitHookClassMethod(Class targetClass, SEL originalSEL, SEL swizzledSEL);

#pragma mark - Queue

extern dispatch_queue_t IESGurdKitCreateSerialQueue(const char *_Nullable label);

extern dispatch_queue_t IESGurdKitCreateConcurrentQueue(const char *_Nullable label);

#pragma mark - NSCoding

extern void IESGurdKitKeyedArchive (id rootObject, NSString *path);

extern id IESGurdKitKeyedUnarchiveObject (NSString *path, NSArray *classes);

extern BOOL decompressFile (NSString *_Nonnull src, NSString *_Nonnull dest, NSString **_Nonnull errorMsg);

NS_ASSUME_NONNULL_END
