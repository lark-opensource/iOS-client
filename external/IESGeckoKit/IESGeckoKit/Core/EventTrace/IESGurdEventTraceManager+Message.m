//
//  IESGurdEventTraceManager+Message.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/7/28.
//

#import "IESGurdEventTraceManager+Message.h"
#import "IESGurdEventTraceManager+Private.h"
#import "IESGeckoDefines+Private.h"
#import "IESGurdLogProxy.h"

#import <pthread/pthread.h>

static pthread_mutex_t messageLock = PTHREAD_MUTEX_INITIALIZER;

@implementation IESGurdEventTraceManager (Message)

+ (void)traceEventWithMessage:(NSString *)message
                     hasError:(BOOL)hasError
                    shouldLog:(BOOL)shouldLog
{
    if (message.length == 0) {
        return;
    }
    
    if (shouldLog) {
        if (hasError) {
            IESGurdLogError(message);
        } else {
            IESGurdLogInfo(message);
        }
    }
    
    if (!self.isEnabled) {
        return;
    }
    
    GURD_MUTEX_LOCK(messageLock);
    
    NSMutableArray<NSString *> *messagesArray = [self sharedManager].messagesArray;
    if (!messagesArray) {
        messagesArray = [NSMutableArray array];
        [self sharedManager].messagesArray = messagesArray;
    }
    NSString *formedMessage = [self formedMessageWithMessage:message];
    [messagesArray addObject:formedMessage];
    
    [self addGlobalMessage:formedMessage];
}

+ (NSArray<NSString *> *)allGlobalMessagesArray
{
    GURD_MUTEX_LOCK(messageLock);
    
    return [[[[self sharedManager].messagesArray reverseObjectEnumerator] allObjects] copy] ? : @[];
}

+ (void)cleanAllGlobalMessages
{
    GURD_MUTEX_LOCK(messageLock);
    
    [[self sharedManager].messagesArray removeAllObjects];
}

+ (void)addGlobalMessage:(NSString *)message
{
    
}

@end
