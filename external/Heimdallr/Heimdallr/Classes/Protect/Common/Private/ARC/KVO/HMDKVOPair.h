//
//  HMDKVOPair.h
//  CLT
//
//  Created by sunrunwang on 2019/3/27.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMDProtectCapture.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDKVOPair : NSObject

@property(nonatomic, weak, readonly)__kindof NSObject *HMDObserver;  // 消息接收者
@property(nonatomic, strong, readonly)Class HMDObserverClass; // 消息接受者类
@property(nonatomic, assign, readonly)void *HMDObserverPtr; // 消息接受者指针
@property(nonatomic, assign, readonly) size_t HMDObserverSize; // 消息接受者内存大小
@property(nonatomic, copy, readonly, nonnull)NSString *HMDKeyPath;   // 观察路径
@property(nonatomic, assign, readonly)NSKeyValueObservingOptions HMDOption;
@property(nonatomic, assign, readonly, nullable)void *HMDContext;
@property(nonatomic, assign, readonly, getter=isActived)BOOL actived; // 当前KVO是否有效
@property(nonatomic, assign, readonly, getter=isCrashed)BOOL crashed; // 该KVO配对是否已触发Crash

- (instancetype)initWithObserver:(__kindof NSObject  * _Nonnull)observer
                         keypath:(NSString * _Nonnull)keypath
                         options:(NSKeyValueObservingOptions)option
                         context:(void * _Nullable)context;

- (instancetype)init __attribute__((unavailable("Please use initWithObservee:observer:options:context: to obtain an instance.")));

- (void)activeWithObservee:(NSObject *_Nullable)observee; // KVO连接

- (void)deactiveWithObservee:(NSObject *_Nullable)observee; // KVO断开连接

@end



@interface HMDKVOPairsInfo : NSObject

@property(nonatomic, weak, readonly)__kindof NSObject *HMDObservee;  // 消息发送者
@property(nonatomic, assign, readonly)void *HMDObserveePtr; // 消息发送者指针
@property(nonatomic, strong, readonly)Class HMDObserveeClass; // 消息发送者类
@property(nonatomic, strong, readonly)NSMutableArray<HMDKVOPair *>* pairList; // 所有监听者信息

- (instancetype)initWithObservee:(NSObject *)observee;
- (instancetype)init __attribute__((unavailable("Please use initWithObservee: to obtain an instance.")));

@end

NS_ASSUME_NONNULL_END
