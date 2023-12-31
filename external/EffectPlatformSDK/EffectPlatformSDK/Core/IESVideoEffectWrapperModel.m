//
//  IESVideoEffectWrapperModel.m
//  Indexer
//
//  Created by Fengfanhua.byte on 2021/12/10.
//

#import "IESVideoEffectWrapperModel.h"

@interface IESVideoEffectWrapperModel ()

@property (nonatomic, copy, readwrite) IESEffectModel *effect;
@property (nonatomic, copy, readwrite) IESSimpleVideoModel *video;

@end

@implementation IESVideoEffectWrapperModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"effect" : @"effect",
        @"video" : @"simple_video_info"
    };
}

+ (NSValueTransformer *)effectJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:IESEffectModel.class];
}

+ (NSValueTransformer *)videoJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:IESSimpleVideoModel.class];
}

@end
