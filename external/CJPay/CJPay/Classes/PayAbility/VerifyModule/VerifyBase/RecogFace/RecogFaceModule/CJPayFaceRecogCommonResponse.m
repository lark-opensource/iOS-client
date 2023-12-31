//
//  CJPayFaceRecogCommonResponse.m
//  Pods
//
//  Created by 尚怀军 on 2022/10/31.
//

#import "CJPayFaceRecogCommonResponse.h"

@implementation CJPayFaceRecogCommonResponse

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[self basicMapperWith:@{
            @"lynxUrl": @"data.lynx_url",
            @"faceVerifyInfo": @"data.face_verify_info"
    }]];
}

@end
