//
//  ObjcExceptionHandler.m
//  LarkUIKit
//
//  Created by 姚启灏 on 2019/10/9.
//

#import "ObjcExceptionHandler.h"

@implementation ObjcExceptionHandler

+ (BOOL)catchException: (void(NS_NOESCAPE ^)(void))tryBlock error:(__autoreleasing NSError **)error {
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
