//
//  BDTuringCheckCodeModel.m
//  BDTuring
//
//  Created by bob on 2021/8/6.
//

#import "BDTuringCheckCodeModel.h"
#import "BDTuringUtility.h"
#import "BDTuringVerifyModel+Config.h"

@implementation BDTuringCheckCodeModel

- (void)appendCommonKVParameters:(NSMutableDictionary *)parameters {
    [super appendCommonKVParameters:parameters];
    [parameters setValue:self.code forKey:@"code"];
}

- (BOOL)isValid {
    return [super isValid] && BDTuring_isValidString(self.code);
}

@end
