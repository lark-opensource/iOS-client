//
//  IESGurdEventTraceManager+Business.m
//  BDAssert
//
//  Created by 陈煜钏 on 2020/7/28.
//

#import "IESGurdEventTraceManager+Business.h"
#import "IESGurdEventTraceManager+Private.h"
#import "IESGeckoDefines+Private.h"
#import "IESGurdLogProxy.h"

#import <pthread/pthread.h>

@implementation IESGurdTraceMessageInfo

+ (instancetype)messageInfoWithAccessKey:(NSString *)accessKey
                                 channel:(NSString *)channel
                                 message:(NSString *)message
                                hasError:(BOOL)hasError
{
    IESGurdTraceMessageInfo *messageInfo = [[self alloc] init];
    messageInfo.accessKey = accessKey;
    messageInfo.channel = channel;
    messageInfo.message = message;
    messageInfo.hasError = hasError;
    return messageInfo;
}

@end

static pthread_mutex_t businessLock = PTHREAD_MUTEX_INITIALIZER;

@implementation IESGurdEventTraceManager (Business)

#pragma mark - Public

+ (void)traceEventWithMessageInfo:(IESGurdTraceMessageInfo *)messageInfo
{
    NSString *accessKey = messageInfo.accessKey;
    NSString *channel = messageInfo.channel;
    NSString *message = messageInfo.message;
    if (IES_isEmptyString(accessKey) || IES_isEmptyString(channel) || IES_isEmptyString(message)) {
        return;
    }
    
    if (messageInfo.shouldLog) {
        if (messageInfo.hasError) {
            IESGurdLogError(@"%@|%@|%@", accessKey, channel, message);
        } else {
            IESGurdLogInfo(@"%@|%@|%@", accessKey, channel, message);
        }
    }
    
    if (!self.isEnabled) {
        return;
    }
    messageInfo.message = [self formedMessageWithMessage:message];
    
    GURD_MUTEX_LOCK(businessLock);
    
    IESGurdEventTraceManager *manager = [self sharedManager];
    IESGurdEventMessagesDictionary messagesDictionary = manager.messagesDictionary;
    if (!messagesDictionary) {
        messagesDictionary = [NSMutableDictionary dictionary];
        manager.messagesDictionary = messagesDictionary;
    }
    
    NSMutableDictionary *accessKeyDictionary = messagesDictionary[accessKey];
    if (!accessKeyDictionary) {
        accessKeyDictionary = [NSMutableDictionary dictionary];
        messagesDictionary[accessKey] = accessKeyDictionary;
    }
    
    NSMutableArray<IESGurdTraceMessageInfo *> *messageInfosArray = accessKeyDictionary[channel];
    if (!messageInfosArray) {
        messageInfosArray = [NSMutableArray array];
        accessKeyDictionary[channel] = messageInfosArray;
    }
    
    [messageInfosArray addObject:messageInfo];
    
    [self addMessageInfo:messageInfo];
    GurdLog(@"【%@ : %@】%@", accessKey, channel, message);
}

+ (NSDictionary<NSString *, NSDictionary<NSString *, NSArray<NSString *> *> *> *)allMessagesDictionary
{
    return [self _messagesDictionary:NO];
}

+ (NSDictionary<NSString *, NSDictionary<NSString *, NSArray<NSString *> *> *> *)errorMessagesDictionary
{
    return [self _messagesDictionary:YES];
}

+ (void)cleanMessagesForAccessKey:(NSString *)accessKey
                          channel:(NSString *)channel
{
    if (accessKey.length == 0 || channel.length == 0) {
        return;
    }
    
    GURD_MUTEX_LOCK(businessLock);
    
    NSMutableArray *messageInfos = [self sharedManager].messagesDictionary[accessKey][channel];
    if ([messageInfos isKindOfClass:[NSMutableArray class]]) {
        [messageInfos removeAllObjects];
    }
}

#pragma mark - Private

+ (void)addMessageInfo:(IESGurdTraceMessageInfo *)messageInfo
{
    
}

+ (NSDictionary<NSString *, NSDictionary<NSString *, NSArray<NSString *> *> *> *)_messagesDictionary:(BOOL)errorOnly
{
    GURD_MUTEX_LOCK(businessLock);
    
    NSMutableDictionary *errorMessagesDictionary = [NSMutableDictionary dictionary];
    [[self sharedManager].messagesDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSMutableDictionary<NSString *, NSMutableArray<IESGurdTraceMessageInfo *> *> *messageInfoDictionary, BOOL *stop) {
        if (messageInfoDictionary.count == 0) {
            return;
        }
        NSMutableDictionary *channelDictionary = [NSMutableDictionary dictionary];
        [messageInfoDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *channel, NSMutableArray<IESGurdTraceMessageInfo *> *messageInfoArray, BOOL *stop) {
            if (messageInfoArray.count == 0) {
                return;
            }
            NSMutableArray *messagesArray = [NSMutableArray array];
            [messageInfoArray enumerateObjectsUsingBlock:^(IESGurdTraceMessageInfo *messageInfo, NSUInteger idx, BOOL *stop) {
                if (errorOnly) {
                    if (messageInfo.hasError) {
                        [messagesArray addObject:messageInfo.message];
                    }
                } else {
                    [messagesArray addObject:messageInfo.message];
                }
            }];
            if (messagesArray.count > 0) {
                channelDictionary[channel] = [messagesArray copy];
            }
        }];
        if (channelDictionary.count > 0) {
            errorMessagesDictionary[accessKey] = [channelDictionary copy];
        }
    }];
    return [errorMessagesDictionary copy];
}

@end
