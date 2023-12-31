//
//  BDTuringVerifyModel+Result.m
//  BDTuring
//
//  Created by bob on 2020/7/9.
//

#import "BDTuringVerifyModel+Result.h"
#import "BDTuringVerifyResult+Result.h"

@implementation BDTuringVerifyModel (Result)

- (void)handleResultStatus:(BDTuringVerifyStatus)status {
    BDTuringVerifyResult *result = [BDTuringVerifyResult new];
    result.status = status;
    
    [self handleResult:result];
}

@end
