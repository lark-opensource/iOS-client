//
//  AWEStudioCaptionModel.m
//  Pods
//
//  Created by lixingdong on 2019/8/29.
//

#import "AWEStudioCaptionModel.h"
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitArch/AWEInteractionStickerModel.h>

@implementation AWEStudioCaptionCommitModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return [@{
              @"videoCaption" : @"video_caption",
              } acc_apiPropertyKey];
}

+ (NSValueTransformer *)captionsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[AWEStudioCaptionModel class]];
}

@end

@implementation AWEStudioCaptionQueryModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return [@{
              @"captionId" : @"id",
              @"code" : @"code",
              @"message" : @"message",
              @"captions" : @"utterances",
              } acc_apiPropertyKey];
}

+ (NSValueTransformer *)captionsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[AWEStudioCaptionModel class]];
}

@end

@implementation AWEStudioCaptionInfoModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return [@{
              @"captions" : @"utterances",
              @"textInfoModel" : @"textInfoModel",
              @"location" : @"location",
              } acc_apiPropertyKey];
}

+ (NSValueTransformer *)captionsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[AWEStudioCaptionModel class]];
}

+ (NSValueTransformer *)textInfoModelJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWEStoryTextImageModel class]];
}

+ (NSValueTransformer *)locationJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWEInteractionStickerLocationModel class]];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    AWEStudioCaptionInfoModel *model = [super copyWithZone:zone];
    
    model.captions = [self.captions copy];
    model.location = [self.location copy];
    model.textInfoModel = [self.textInfoModel copy];
    
    return model;
}

- (NSString *)md5
{
    NSString *captionsStr = [self.captions componentsJoinedByString:@";"];
    NSString *textInfoStr = [[MTLJSONAdapter JSONDictionaryFromModel:self.textInfoModel error:nil] acc_safeJsonStringEncoded];
    NSString *locationStr = [NSString stringWithFormat:@"%@%@%@%@", self.location.x, self.location.y, self.location.scale, self.location.rotation];
    
    NSString *composeStr = [NSString stringWithFormat:@"%@%@%@", captionsStr, textInfoStr, locationStr];
    return [composeStr acc_md5String];
}

#pragma mark - Getter

- (AWEStoryTextImageModel *)textInfoModel
{
    if (!_textInfoModel) {
        _textInfoModel = [AWEStoryTextImageModel new];
        _textInfoModel.colorIndex = [NSIndexPath indexPathForRow:0 inSection:0];
        _textInfoModel.fontIndex = [NSIndexPath indexPathForRow:0 inSection:0];
        _textInfoModel.realStartTime = 0;
        _textInfoModel.realDuration = -1;
        _textInfoModel.fontSize = 40.0;
        _textInfoModel.isCaptionSticker = YES;
    }

    return _textInfoModel;
}

@end

@implementation AWEStudioCaptionModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return [@{
              @"text"       : @"text",
              @"startTime"  : @"start_time",
              @"endTime"    : @"end_time",
              @"words"      : @"words",
              @"rect"       : @"rect",
              @"lineRectArray"       : @"lineRectArray"
              } acc_apiPropertyKey];
}

+ (NSValueTransformer *)wordsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[AWEStudioCaptionModel class]];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    AWEStudioCaptionModel *model = [super copyWithZone:zone];

    model.text = [self.text copy];
    model.startTime = self.startTime;
    model.endTime = self.endTime;
    model.words = [self.words copy];
    model.rect = [self.rect copy];
    model.lineRectArray = [self.lineRectArray copy];

    return model;
}

- (NSString *)text
{
    if (!_text) {
        _text = @"";
    }
    return _text;
}

@end
