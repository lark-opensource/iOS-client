//
//  HMDNotificationConnection.h
//  CLT
//
//  Created by sunrunwang on 2019/3/27.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// [警告⚠️] 非线程安全 [Thread unsafe]
/// [附加功能] 提供类型检查
/// HMDNotificationConnection 是指每一次 connection 的逻辑
@interface HMDNotificationConnection : NSObject

#pragma mark - Basic Info of Attribute 

@property(nonatomic, weak, readonly) __kindof NSObject *observer;  // 消息接收者
@property(nonatomic, assign, readonly)void *observerPtr; // 消息接受者指针
@property(nonatomic, assign, readonly) size_t observerSize; // observer内存大小
@property(nonatomic, readonly, nonnull) SEL selector; // 接受者方法
@property(nonatomic, copy, readonly, nonnull) NSNotificationName name;
@property(nonatomic, weak, readonly) __kindof NSObject *object;
@property(nonatomic, unsafe_unretained, nonnull) Class observerClass;
@property(nonatomic, unsafe_unretained, nullable) Class objectClass;
@property(nonatomic, assign, readonly, getter=isActived) BOOL actived;
@property(nonatomic, assign, readonly, getter=isCrashed) BOOL crashed;

- (instancetype)initWithObserver:(__kindof NSObject  * _Nonnull)observer
                        selector:(SEL _Nonnull)selector
                            name:(NSNotificationName _Nullable)name
                          object:(__kindof NSObject * _Nullable)object;

- (instancetype)init __attribute__((unavailable("Please use initWithObserver:selector:name:object: to obtain an instance.")));

- (BOOL)valid;

- (void)active;

- (void)deactive;

@end

NS_ASSUME_NONNULL_END
