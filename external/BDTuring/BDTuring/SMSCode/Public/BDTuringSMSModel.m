//
//  BDTuringSMSModel.m
//  BDTuring
//
//  Created by bob on 2021/8/5.
//

#import "BDTuringSMSModel.h"
#import "BDTuringUtility.h"

@implementation BDTuringSMSModel

- (BOOL)isValid {
    return BDTuring_isValidString(self.requestURL);
}

- (void)appendCommonKVParameters:(NSMutableDictionary *)parameters {
    [parameters setValue:self.mobile forKey:@"mobile"];
    [parameters setValue:@(self.scene) forKey:@"scene"];
}

@end
