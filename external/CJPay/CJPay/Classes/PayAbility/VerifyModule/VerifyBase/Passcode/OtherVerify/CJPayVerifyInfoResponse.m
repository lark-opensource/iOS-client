//
//  CJPayVerifyInfoResponse.m
//  Pods
//
//  Created by wangxinhua on 2021/7/30.
//

#import "CJPayVerifyInfoResponse.h"

@implementation CJPayVerifyInfoResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *mutablePro = [[super basicDict] mutableCopy];
    [mutablePro addEntriesFromDictionary:@{
        @"jumpUrl" : @"response.jump_url",
        @"faceVerifyInfo" : @"response.face_verify_info",
        @"verifyType" : @"response.verify_type",
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[mutablePro copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
