//
//  AWEStoryTextImageModel.m
//  AWEStudio
//
//  Created by li xingdong on 2019/1/16.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import "AWEStoryTextImageModel.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreativeKit/UIColor+ACCAdditions.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import "ACCTextStickerExtraModel.h"

static NSString * const Row = @"row";
static NSString * const Section = @"section";

@implementation AWEStoryColor

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"color" : @"color",
             @"colorString" : @"colorString",
             @"borderColor" : @"borderColor",
             @"borderColorString" : @"borderColorString"
             };
}

+ (NSValueTransformer *)colorJSONTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        if (!value || ![value isKindOfClass:[NSString class]]) {
            return nil;
        }
        
        return [UIColor acc_colorWithHexString:value];
    } reverseBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        if (!value || ![value isKindOfClass:[UIColor class]]) {
            return nil;
        }
        
        return [UIColor acc_hexStringFromColor:value];
    }];
}

+ (NSValueTransformer *)borderColorJSONTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        if (!value || ![value isKindOfClass:[NSString class]]) {
            return nil;
        }
        
        return [UIColor acc_colorWithHexString:value];
    } reverseBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        if (!value || ![value isKindOfClass:[UIColor class]]) {
            return nil;
        }
        
        return [UIColor acc_hexStringFromColor:value];
    }];
}

+ (instancetype)colorWithHexString:(NSString *)hexString
{
    return [self colorWithTextColorHexString:hexString borderColorHexString:nil];
}

+ (instancetype)colorWithHexString:(NSString *)hexString alpha:(float)opacity
{
    return [self colorWithTextColorHexString:hexString borderColorHexString:nil alpha:opacity];
}

+ (instancetype)colorWithTextColorHexString:(NSString *)textHexString borderColorHexString:(NSString *)borderHexString
{
    return [[self alloc] initWithTextHexString:textHexString borderHexString:borderHexString alpha:1.0];
}

+ (instancetype)colorWithTextColorHexString:(NSString *)textHexString borderColorHexString:(NSString *)borderHexString alpha:(float)opacity
{
    return [[self alloc] initWithTextHexString:textHexString borderHexString:borderHexString alpha:opacity];
}

- (instancetype)initWithTextHexString:(NSString *)textHexString borderHexString:(NSString *)borderHexString alpha:(float)opacity
{
    if (self = [super init]) {
        
        if (textHexString) {
            self.color = [self colorFromHexString:textHexString alpha:opacity];
            self.colorString = textHexString;
        } else {
            self.color = [UIColor blackColor];
            self.colorString = @"0x000000";
        }
        
        if (borderHexString) {
            self.borderColor = [self colorFromHexString:borderHexString alpha:opacity];
            self.borderColorString = borderHexString;
        }
    }
    return self;
}

- (UIColor *)colorFromHexString:(NSString *)hexString alpha:(float)opacity
{
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:2]; // bypass '0x' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0 green:((rgbValue & 0xFF00) >> 8) / 255.0 blue:(rgbValue & 0xFF) / 255.0 alpha: opacity];
}

@end

@interface AWEStoryFontModel()

@end

@implementation AWEStoryFontModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"title" : @"title",
             @"fontName" : @"fontName",
             @"fontFileName": @"fontFileName",
             @"localUrl" : @"localUrl",
             @"hasBgColor" : @"hasBgColor",
             @"hasShadeColor" : @"hasShadeColor",
             @"defaultFontSize" : @"defaultFontSize",
             @"effectId" : @"effectId",
             };
}

+ (BOOL)isValidEffectModel:(IESEffectModel *)effectModel
{
    return [effectModel.extra dataUsingEncoding:NSUTF8StringEncoding] != nil;
}

- (instancetype)initWithEffectModel:(IESEffectModel *)effectModel {
    self = [self init];
    
    if (self) {
        NSData *extraData = [effectModel.extra dataUsingEncoding:NSUTF8StringEncoding];
        if (extraData != nil) {
            NSDictionary *extraDict = [NSJSONSerialization JSONObjectWithData:extraData options:0 error:nil];

            _title = [extraDict acc_stringValueForKey:@"title"];
            _fontName = [extraDict acc_stringValueForKey:@"font_name"];
            _fontFileName = [extraDict acc_stringValueForKey:@"font_file_name"];
            _hasBgColor = [extraDict acc_boolValueForKey:@"enable_bg_color"];
            _hasShadeColor = [extraDict acc_boolValueForKey:@"enable_maskblur_light_color"];

            if (![[extraDict objectForKey:@"default_font_size"] isKindOfClass:[NSNull class]]) {
                _defaultFontSize = [extraDict acc_integerValueForKey:@"default_font_size"];
            }
        }

        _effectId = effectModel.effectIdentifier;
    }
    
    return self;
}

- (void)setLocalUrl:(NSString *)localUrl
{
    NSString *realLocalURLString = [self p_realLocalURLStringWithString:localUrl];
    if (realLocalURLString.length) {
        _localUrl = realLocalURLString;
    } else {
        _localUrl = localUrl;
    }
}

- (NSString *)p_realLocalURLStringWithString:(NSString *)string
{
    if (string.length == 0) {
        return nil;
    }

    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    if ([string hasPrefix:documentPath]) {
        return string;
    }

    NSString *pattern = @"(Application/)[A-Za-z0-9-]{36}(/Documents)";
    NSError *error = nil;
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        return nil;
    }

    __block NSInteger toIndex = 0;
    [expression enumerateMatchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, string.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        *stop = YES;
        if (result) {
            toIndex = result.range.location + result.range.length;
        }
    }];

    if (0 < toIndex && toIndex < string.length && toIndex == documentPath.length) {
        return [string stringByReplacingCharactersInRange:NSMakeRange(0, toIndex) withString:documentPath];
    }
    
    return nil;
}

- (BOOL)download {
    if (self.localUrl.length == 0) {
        return NO;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.localUrl]) {
        return NO;
    }

    return YES;
}

- (BOOL)supportStroke
{
    return !self.hasShadeColor && self.hasBgColor;
}

@end

@implementation AWETextStickerReadModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"text" : @"text",
        @"stickerKey" : @"stickerKey",
        @"useTextRead" : @"useTextRead",
        @"audioPath" : @"audioPath",
        @"soundEffect" : @"speakerID"
    };
}

+ (NSValueTransformer *)useTextReadJSONTransformer
{
    return [NSValueTransformer valueTransformerForName:MTLBooleanValueTransformerName];
}

@end

@implementation AWETextStickerStylePreferenceModel

- (id)copyWithZone:(NSZone *)zone
{
    AWETextStickerStylePreferenceModel *model = [[AWETextStickerStylePreferenceModel alloc] init];
    model.enableUsingUserPreference = self.enableUsingUserPreference;
    model.preferenceTextFont = [self.preferenceTextFont copy];
    model.preferenceTextColor = [self.preferenceTextColor copy];
    return model;
}

@end

@implementation AWEStoryTextImageModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{@"isCaptionSticker"   :    @"isCaptionSticker",
             @"isPOISticker"   :    @"isPOISticker",
             @"content"        :    @"content",
             @"colorIndex"     :    @"colorIndex",
             @"fontColor"      :    @"fontColor",
             @"fontIndex"      :    @"fontIndex",
             @"fontModel"      :    @"fontModel",
             @"textStyle"      :    @"textStyle",
             @"alignmentType"  :    @"alignmentType",
             @"keyboardHeight" :    @"keyboardHeight",
             @"realStartTime"  :    @"realStartTime",
             @"realDuration"   :    @"realDuration",
             @"fontSize"       :    @"fontSize",
             @"readModel"      :    @"readModel",
             @"extraInfos"     :    @"extraInfos",
             @"extra"          :    @"extra"
             };
}

+ (NSValueTransformer *)colorIndexJSONTransformer
{
    return [self indexPathJSONTransformer];
}

+ (NSValueTransformer *)fontIndexJSONTransformer
{
    return [self indexPathJSONTransformer];
}

+ (NSValueTransformer *)fontColorJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWEStoryColor class]];
}

+ (NSValueTransformer *)fontModelJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWEStoryFontModel class]];
}

+ (NSValueTransformer *)extraInfosJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[ACCTextStickerExtraModel class]];
}

+ (NSValueTransformer *)indexPathJSONTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError *__autoreleasing *error) {
        if (value && [value isKindOfClass:[NSString class]]) {
            NSDictionary *dictionary = [value acc_jsonValueDecoded];
            NSInteger row = [[dictionary objectForKey:Row] integerValue];
            NSInteger section = [[dictionary objectForKey:Section] integerValue];
            NSIndexPath *model = [NSIndexPath indexPathForRow:row inSection:section];
            return model;
        }
        return nil;
    } reverseBlock:^id(NSIndexPath *value, BOOL *success, NSError *__autoreleasing *error) {
        
        NSDictionary *dict = [NSDictionary new];
        if (!value) {
            dict = @{Row : @(0), Section : @(0)};
        } else {
            dict = @{Row : @(value.row), Section : @(value.section)};
        }
        return [dict acc_dictionaryToJson];
    }];
}

+ (NSValueTransformer *)readModelJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWETextStickerReadModel class]];
}

- (NSDictionary *)trackInfo
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"selected_from"] = self.isAutoAdded? @"auto":@"text_entrance";
    params[@"at_cnt"] = @([ACCTextStickerExtraModel numberOfValidExtrasInList:self.extraInfos forType:ACCTextStickerExtraTypeMention]);
    params[@"tag_cnt"] = @([ACCTextStickerExtraModel numberOfValidExtrasInList:self.extraInfos forType:ACCTextStickerExtraTypeHashtag]);
    return [params copy];
}

@end
