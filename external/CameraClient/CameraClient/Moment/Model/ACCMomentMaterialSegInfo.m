//
//  ACCMomentMaterialSegInfo.m
//  Pods
//
//  Created by Pinka on 2020/6/8.
//

#import "ACCMomentMaterialSegInfo.h"

@implementation ACCMomentMaterialSegInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"fragmentId": @"fragment_id",
        @"materialId": @"material_d",
        @"startTime": @"start_time",
        @"endTime": @"end_time",
        @"clipFrame": @"clip_frame"
    };
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    ACCMomentMaterialSegInfo *copy = [[ACCMomentMaterialSegInfo alloc] init];
    copy.fragmentId = [self.fragmentId copy];
    copy.materialId = [self.materialId copy];
    copy.startTime = self.startTime;
    copy.endTime = self.endTime;
    return copy;
}

+ (NSValueTransformer *)clipFrameJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ACCMomentReframe class]];
}

@end
