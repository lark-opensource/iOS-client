//
//  CJPaySkipPwdGuideInfoModel.m
//  Pods
//
//  Created by 尚怀军 on 2021/3/11.
//

#import "CJPaySkipPwdGuideInfoModel.h"
@implementation  BDPaySkipPwdSubGuideInfoModel
+(JSONKeyMapper *)keyMapper{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"iconUrl": @"icon_url",
                @"iconDesc": @"desc"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}
@end


@implementation CJPaySkipPwdGuideInfoModel

+ (JSONKeyMapper *)keyMapper {
    
    NSMutableDictionary *dict = [self basicDict];
       [dict addEntriesFromDictionary:@{
           @"isChecked": @"is_checked",
           @"subGuide": @"sub_guide_desc",
           @"guideType": @"guide_type",
           @"isShowButton": @"is_show_button",
           @"guideStyle" : @"guide_style",
           @"quota" : @"quota",
           @"style": @"style"
       }];
       
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
