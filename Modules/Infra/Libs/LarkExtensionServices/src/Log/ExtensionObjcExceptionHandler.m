//
//  ExtensionObjcExceptionHandler.m
//  LarkUIKit
//
//  Created by 王元洵 on 2022/04/22.
//

#import "ExtensionObjcExceptionHandler.h"

@implementation ExtensionObjcExceptionHandler

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
