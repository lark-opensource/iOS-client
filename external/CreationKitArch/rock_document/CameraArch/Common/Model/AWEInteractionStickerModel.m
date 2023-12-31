//
//  AWEInteractionStickerModel.m
//  Pods
//
//  Created by chengfei xiao on 2019/12/9.
//

#import "AWEInteractionStickerModel.h"
#import <CreativeKit/ACCMacros.h>

#define AWEInteractionStickerModelSelectToStr(sel) NSStringFromSelector(@selector(sel))

@implementation AWEInteractionStickerLocationModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
              @"x" : @"x",
              @"y" : @"y",
              @"width"  : @"w",
              @"height" : @"h",
              @"rotation" : @"r",
              @"scale"    : @"s",
              @"pts"      : @"p",
              AWEInteractionStickerModelSelectToStr(startTime) : @"start_time",
              AWEInteractionStickerModelSelectToStr(endTime) : @"end_time",
              @"isRatioCoord" : @"isRatioCoord",
              };
}

+ (MTLValueTransformer *)transformerForDecimalNumber {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        if ([value isKindOfClass:[NSString class]]) {
            return [NSDecimalNumber decimalNumberWithString:value];
        } else if ([value isKindOfClass:[NSNumber class]]) {
            return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f",[(NSNumber *)value floatValue]]];
        } else {
            return nil;
        }
    }];
}

+ (NSValueTransformer *)xJSONTransformer
{
    return [self transformerForDecimalNumber];
}

+ (NSValueTransformer *)yJSONTransformer
{
    return [self transformerForDecimalNumber];
}

+ (NSValueTransformer *)widthJSONTransformer
{
    return [self transformerForDecimalNumber];
}

+ (NSValueTransformer *)heightJSONTransformer
{
    return [self transformerForDecimalNumber];
}

+ (NSValueTransformer *)rotationJSONTransformer
{
    return [self transformerForDecimalNumber];
}

+ (NSValueTransformer *)scaleJSONTransformer
{
    return [self transformerForDecimalNumber];
}

+ (NSValueTransformer *)ptsJSONTransformer
{
    return [self transformerForDecimalNumber];
}

+ (NSValueTransformer *)startTimeJSONTransformer {
    return [self transformerForDecimalNumber];
}

+ (NSValueTransformer *)endTimeJSONTransformer {
    return [self transformerForDecimalNumber];
}

- (void)reset {
    self.x = self.y = self.width = self.height = self.rotation = self.scale = self.pts = self.startTime = self.endTime = nil;
    self.isRatioCoord = NO;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    AWEInteractionStickerLocationModel *copy = [[[self class] allocWithZone:zone] init];
    
    copy.x = [self.x copy];
    copy.y = [self.y copy];
    copy.width = [self.width copy];
    copy.height = [self.height copy];
    copy.rotation = [self.rotation copy];
    copy.scale = [self.scale copy];
    copy.pts = [self.pts copy];
    copy.startTime = [self.startTime copy];
    copy.endTime = [self.endTime copy];

    return copy;
}

#pragma mark - Getter

- (void)setX:(NSDecimalNumber *)x
{
    _x = [self validNumber:x];
}

- (void)setY:(NSDecimalNumber *)y
{
    _y = [self validNumber:y];
}

- (void)setWidth:(NSDecimalNumber *)width
{
    _width = [self validNumber:width];
}

- (void)setHeight:(NSDecimalNumber *)height
{
    _height = [self validNumber:height];
}

- (void)setRotation:(NSDecimalNumber *)rotation
{
    _rotation = [self validNumber:rotation];
}

- (void)setScale:(NSDecimalNumber *)scale
{
    _scale = [self validNumber:scale];
}

- (void)setPts:(NSDecimalNumber *)pts
{
    _pts = [self validNumber:pts];
}

- (void)setStartTime:(NSDecimalNumber *)startTime {
    _startTime = [self validNumber:startTime];
}

- (void)setEndTime:(NSDecimalNumber *)endTime {
    _endTime = [self validNumber:endTime];
}

#pragma mark - Utils

- (NSDecimalNumber *)validNumber:(NSDecimalNumber *)x
{
    if (isnan([x doubleValue])) {
        x = nil;
    }
    
    return x;
}

+ (NSDecimalNumber *)convertCGFloatToNSDecimalNumber:(CGFloat)value
{
    NSString *strValue = [NSString stringWithFormat:@"%.4f", value];
    return [NSDecimalNumber decimalNumberWithString:strValue];
}

@end


@implementation AWEInteractionExtraModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"stickerID" : @"sticker_id",
             @"type"      : @"interaction_type",
             @"popIcon"   : @"interaction_icon",
             @"popText"   : @"interaction_text",
             @"schemeURL" : @"interaction_url",
             @"clickableOpenURL" : @"clickable_open_url",
             @"clickableWebURL"  : @"clickable_web_url"
             };
}

@end


@implementation AWEInteractionVoteStickerOptionsModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"optionText" : @"option_text",
             @"optionID"   : @"option_id",
             @"voteCount"  : @"vote_count",
             };
}

@end

@implementation AWEInteractionVoteStickerInfoModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"question" : @"question",
             @"voteID"   : @"vote_id",
             @"refID"    : @"ref_id",
             @"refType"  : @"ref_type",
             @"options"  : @"options",
             @"selectOptionID" : @"select_option_id",
             @"style" : @"style"
             };
}

+ (NSValueTransformer *)optionsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:AWEInteractionVoteStickerOptionsModel.class];
}

@end

@implementation AWEInteractionStickerModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
              @"type"      : @"type",
              @"trackInfo" : @"track_info",
              @"index"     : @"index",
              @"adaptorPlayer"  : @"adaptorPlayer",
              @"attr"      : @"attr",
              @"voteID"     : @"vote_id",
              @"voteInfo"   : @"vote_info",
              @"stickerID"  : @"stickerID",
              @"imageIndex" : @"image_index",
              @"localStickerUniqueId" : @"localStickerUniqueId",
              AWEInteractionStickerModelSelectToStr(textInfo) : @"text_info",
              @"isAutoAdded" : @"isAutoAdded"
              };
}

+ (NSValueTransformer *)voteInfoJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:AWEInteractionVoteStickerInfoModel.class];
}

- (BOOL)storeLocationModelToTrackInfo:(AWEInteractionStickerLocationModel *)locationModel {
    
    if (!locationModel) {
        return NO;
    }
    
    BOOL stored = NO;
    @try {
        NSArray *arr = [MTLJSONAdapter JSONArrayFromModels:@[locationModel] error:nil];
        if (arr) {
            NSData *arrJsonData = [NSJSONSerialization dataWithJSONObject:arr options:kNilOptions error:nil];
            if (arrJsonData) {
                NSString *arrJsonStr = [[NSString alloc] initWithData:arrJsonData encoding:NSUTF8StringEncoding];
                self.trackInfo = arrJsonStr;
                stored = YES;
            }
        }
    } @catch (NSException *exception) {
        
    }
 
    return stored;
}

- (AWEInteractionStickerLocationModel *)fetchLocationModelFromTrackInfo {
    
    if (ACC_isEmptyString(self.trackInfo)){
        return nil;
    }
    
    AWEInteractionStickerLocationModel *location = nil;
    
    @try {
        
        NSData* data = [self.trackInfo dataUsingEncoding:NSUTF8StringEncoding];
        if (data) {
            NSArray *values = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if ([values count]) {
                NSArray *locationArr = [MTLJSONAdapter modelsOfClass:[AWEInteractionStickerLocationModel class] fromJSONArray:values error:nil];
                if ([locationArr count]) {
                    location = [locationArr firstObject];
                }
            }
        }
    } @catch (NSException *exception) {
        
    }

    return location;
}

@end
