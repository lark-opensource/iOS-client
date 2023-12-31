//
//  HMDJSONToken.m
//  Heimdallr
//
//  Created by xuminghao.eric on 2019/11/14.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import "HMDJSONToken.h"

@implementation HMDJSONToken

- (instancetype)initWithTokenType:(HMDInvalidJSONToken)tokenType tokenValue:(NSString *)tokenValue{
    if(self = [super init]){
        _tokenType = tokenType;
        if(tokenValue){
            _tokenValue = tokenValue;
            _tokenLength = [tokenValue length];
        } else {
            return nil;
        }
    }
    return self;
}

@end
