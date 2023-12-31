//
//  BDTuringIdentityResult.m
//  BDTuring
//
//  Created by bob on 2020/6/30.
//

#import "BDTuringIdentityResult.h"

@implementation BDTuringIdentityResult

+ (instancetype)unsupportResult {
    BDTuringIdentityResult *result = [super unsupportResult];
    result.identityAuthCode = BDTuringIdentityCodeNotSupport;
    result.livingDetectCode = BDTuringIdentityCodeNotSupport;
    
    return result;
}

+ (instancetype)conflictResult {
    BDTuringIdentityResult *result = [super conflictResult];
    result.identityAuthCode = BDTuringIdentityCodeConflict;
    result.livingDetectCode = BDTuringIdentityCodeConflict;
    
    return result;
}

@end
