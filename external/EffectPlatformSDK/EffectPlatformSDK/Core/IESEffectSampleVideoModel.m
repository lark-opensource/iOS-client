//
//  IESEffectSampleVideoModel.m
//  EffectPlatformSDK
//
//  Created by Fengfanhua.byte on 2021/9/27.
//

#import "IESEffectSampleVideoModel.h"
#import "IESEffectURLModel.h"

@implementation IESEffectSampleVideoModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"h264URL" : @"PlayAddrH264",
        @"coverURL" : @"Cover",
        @"downloadURL" : @"DownloadAddr",
        @"playURL" : @"PlayAddr",
        @"dynamicCover" : @"DynamicCover",
        @"height" : @"Height",
        @"width" : @"Width"
    };
}

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    if ([key isEqualToString:@"h264URL"]
        || [key isEqualToString:@"coverURL"]
        || [key isEqualToString:@"downloadURL"]
        || [key isEqualToString:@"playURL"]
        || [key isEqualToString:@"dynamicCover"]) {
        return [MTLJSONAdapter dictionaryTransformerWithModelClass:IESEffectURLModel.class];
    }
    return nil;
}


@end
