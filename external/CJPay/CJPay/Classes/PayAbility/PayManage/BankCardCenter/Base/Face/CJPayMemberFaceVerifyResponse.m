//
//  CJPayMemberFaceVerifyResponse.m
//  Pods
//
//  Created by 尚怀军 on 2020/12/31.
//

#import "CJPayMemberFaceVerifyResponse.h"

@implementation CJPayMemberFaceVerifyResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *keyV = [self basicDict];
    [keyV addEntriesFromDictionary:@{
        @"faceRecognitionType": @"response.face_recognition_type",
        @"faceContent": @"response.face_content",
        @"nameMask": @"response.name_mask",
        @"status": @"response.ret_status",
        @"token": @"response.token"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:keyV];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
