//
//  IESGurdEventTraceManager+Business.h
//  BDAssert
//
//  Created by 陈煜钏 on 2020/7/28.
//

#import "IESGurdEventTraceManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdTraceMessageInfo : NSObject

@property (nonatomic, copy) NSString *accessKey;

@property (nonatomic, copy) NSString *channel;

@property (nonatomic, copy) NSString *message;

@property (nonatomic, assign) BOOL hasError;

@property (nonatomic, assign) BOOL shouldLog;

+ (instancetype)messageInfoWithAccessKey:(NSString *)accessKey
                                 channel:(NSString *)channel
                                 message:(NSString *)message
                                hasError:(BOOL)hasError;

@end

@interface IESGurdEventTraceManager (Business)

+ (void)traceEventWithMessageInfo:(IESGurdTraceMessageInfo *)messageInfo;

// accessKey : @{ channel : @[ message, ... ] }
+ (NSDictionary<NSString *, NSDictionary<NSString *, NSArray<NSString *> *> *> *)allMessagesDictionary;

// accessKey : @{ channel : @[ message, ... ] }
+ (NSDictionary<NSString *, NSDictionary<NSString *, NSArray<NSString *> *> *> *)errorMessagesDictionary;

+ (void)cleanMessagesForAccessKey:(NSString *)accessKey
                          channel:(NSString *)channel;

@end

NS_ASSUME_NONNULL_END
