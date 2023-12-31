//
//  IESGurdEventTraceManager+Message.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/7/28.
//

#import "IESGurdEventTraceManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdEventTraceManager (Message)

+ (void)traceEventWithMessage:(NSString *)message
                     hasError:(BOOL)hasError
                    shouldLog:(BOOL)shouldLog;

+ (NSArray<NSString *> *)allGlobalMessagesArray;

+ (void)cleanAllGlobalMessages;

@end

NS_ASSUME_NONNULL_END
