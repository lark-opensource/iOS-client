//
//  AWEAutoCaptionStickerInfoModel.m
//  CameraClientTikTok
//
//  Created by liuqing on 2021/2/5.
//

#import "AWEAutoCaptionStickerInfoModel.h"

NSString * const AWEInteractionAutoCaptionStickerCaptionsKey = @"utterances";

@implementation AWEAutoCaptionUrlModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"urlList" : @"url_list",
    };
}

@end

@implementation AWEAutoCaptionInfoModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"language" : @"language",
        @"url" : @"url",
    };
}

+ (NSValueTransformer *)urlJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:AWEAutoCaptionUrlModel.class];
}

@end

@implementation AWEAutoCaptionStickerInfoModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"locationType" : @"location",
        @"audioUri" : @"audio_uri",
        @"taskId" : @"task_id",
        @"captions" : AWEInteractionAutoCaptionStickerCaptionsKey,
        @"captionInfos" : @"auto_captions",
    };
}

+ (NSValueTransformer *)captionsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:AWEStudioCaptionModel.class];
}

+ (NSValueTransformer *)captionInfosJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:AWEAutoCaptionInfoModel.class];
}

@end
