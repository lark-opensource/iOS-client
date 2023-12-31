//
//  IESGurdLogProxy.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2021/3/12.
//

#import "IESGurdLogProxy.h"

static BOOL kGurdShouldLog = NO;
static NSMutableArray<id<IESGurdLogProxyDelegate>> *businessGurdLogDelegateArray = nil;

void IESGurdLogAddDelegate(id<IESGurdLogProxyDelegate> delegate)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        businessGurdLogDelegateArray = [NSMutableArray array];
    });
    @synchronized (businessGurdLogDelegateArray) {
        if ([delegate respondsToSelector:@selector(gurdLogLevel:logMessage:)]) {
            kGurdShouldLog = YES;
            [businessGurdLogDelegateArray addObject:delegate];
        }
    }
}

void IESGurdLogRemoveDelegate(id<IESGurdLogProxyDelegate> delegate)
{
    @synchronized (businessGurdLogDelegateArray) {
        [businessGurdLogDelegateArray removeObject:delegate];
        if (![businessGurdLogDelegateArray count]) {
            kGurdShouldLog = NO;
        }
    }
}

void IESGurdLog(IESGurdLogLevel level, NSString *format, ...)
{
    if (kGurdShouldLog) {
        va_list arguments;
        va_start(arguments, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
        va_end(arguments);
        @synchronized (businessGurdLogDelegateArray) {
            for (id<IESGurdLogProxyDelegate> delegate in businessGurdLogDelegateArray) {
                [delegate gurdLogLevel:level logMessage:message];
            }
        }
    }
}
