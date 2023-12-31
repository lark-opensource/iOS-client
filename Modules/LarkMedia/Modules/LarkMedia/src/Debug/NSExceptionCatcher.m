//
//  NSExceptionCatcher.m
//  LarkMedia
//
//  Created by fakegourmet on 2023/3/8.
//

#import "NSExceptionCatcher.h"

@implementation NSExceptionCatcher

+(NSException* _Nullable) tryCatch: (NSExceptionExecution _Nonnull)execution {
    @try {
        execution();
    }
    @catch (NSException *exception) {
        return exception;
    }
    return nil;
}

@end
