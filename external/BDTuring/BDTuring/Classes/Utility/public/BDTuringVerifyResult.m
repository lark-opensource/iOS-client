//
//  BDTuringVerifyResult.m
//  BDTuring
//
//  Created by bob on 2020/7/9.
//

#import "BDTuringVerifyResult.h"
#import "BDTuringVerifyResult+Result.h"

@interface BDTuringVerifyResult ()

@property (nonatomic, assign) BDTuringVerifyStatus status;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *mobile;

@end

@implementation BDTuringVerifyResult

+ (instancetype)unsupportResult {
    BDTuringVerifyResult *result = [self new];
    result.status = BDTuringVerifyStatusNotSupport;
    
    return result;
}

+ (instancetype)conflictResult {
    BDTuringVerifyResult *result = [self new];
    result.status = BDTuringVerifyStatusConflict;
    
    return result;
}

+ (instancetype)okResult {
    BDTuringVerifyResult *result = [self new];
    result.status = BDTuringVerifyStatusOK;
    
    return result;
}

+ (instancetype)failResult {
    BDTuringVerifyResult *result = [self new];
    result.status = BDTuringVerifyStatusError;
    
    return result;
}

@end
