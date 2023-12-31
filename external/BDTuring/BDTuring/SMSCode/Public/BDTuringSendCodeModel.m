//
//  BDTuringSendCodeModel.m
//  BDTuring
//
//  Created by bob on 2021/8/6.
//

#import "BDTuringSendCodeModel.h"
#import "BDTuringUtility.h"
#import "BDTuringVerifyModel+Config.h"

@implementation BDTuringSendCodeModel

- (void)appendCommonKVParameters:(NSMutableDictionary *)parameters {
    [super appendCommonKVParameters:parameters];
    [parameters setValue:self.vid forKey:@"vid"];
    [parameters setValue:@(self.codeType) forKey:@"code_type"];
    [parameters setValue:@(self.eventType) forKey:@"event_type"];
    [parameters setValue:@(self.channelID) forKey:@"channel_id"];
}

- (BOOL)isValid {
    return [super isValid] && BDTuring_isValidString(self.mobile) && BDTuring_isValidString(self.vid);
}

@end
