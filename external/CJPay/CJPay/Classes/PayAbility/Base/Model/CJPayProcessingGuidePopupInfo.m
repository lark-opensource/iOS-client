//
//  CJPayProcessingGuidePopupInfo.m
//  Pods
//
//  Created by xutianxi on 2021/11/12.
//

#import "CJPayProcessingGuidePopupInfo.h"
#import "CJPaySDKMacro.h"

@implementation CJPayProcessingGuidePopupInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"title" : @"title",
                @"desc" : @"desc",
                @"btnText" : @"btn_text",
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (BOOL)isValid {
    if ( Check_ValidString(self.title) &&
        Check_ValidString(self.desc) &&
        Check_ValidString(self.btnText) ) {
        return YES;
    }
    
    return NO;
}

@end
