//
//  OPObjcExceptionHandler.m
//  ECOInfra
//
//  Created by lixiaorui on 2021/6/8.
//

#import "OPObjcExceptionHandler.h"

@implementation OPObjcExceptionHandler

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
