//
//  LarkStorageObjcExceptionHandler.m
//  LarkStorage
//
//  Created by 李昊哲 on 2023/6/15.
//

#import "LarkStorageObjcExceptionHandler.h"

@implementation LarkStorageObjcExceptionHandler

+ (BOOL)catchException: (void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain: exception.name code:0
                                        userInfo:exception.userInfo];
        return NO;
    }
}

@end
