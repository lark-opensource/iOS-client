//
//  AWEURLModel.m
//  Aweme
//
//  Created by Quan Quan on 16/8/10.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import "AWEURLModel.h"
#import <objc/runtime.h>
#import <IESFoundation/NSDictionary+AWEAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>

#define AWEBLOCK_INVOKE(block, ...) (block ? block(__VA_ARGS__) : 0)

static void(^awe_didInitBlock)(AWEURLModel *model);
static BOOL(^awe_shouldChangeCommonParams)(AWEURLModel *model);
static NSArray*(^awe_FilterCommonParamsBlock)(NSArray *UrlList);

@interface AWEURLModel ()

@property (nonatomic, copy) NSArray *originURLList;
@property (nonatomic, copy) NSArray *whiteKeys;
@property (nonatomic, copy) NSString *requestID;

@property (nonatomic, assign) CGFloat imageWidth;
@property (nonatomic, assign) CGFloat imageHeight;
@property (nonatomic, copy) NSString *playerAccessKey;

@end

@implementation AWEURLModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        AWEBLOCK_INVOKE(awe_didInitBlock, self);
    }
    return self;
}

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        _URI = [[dict awe_stringValueForKey:@"uri"] copy];
        _originURLList = [[dict awe_arrayValueForKey:@"url_list"] copy];
        _sizeByte = [dict awe_floatValueForKey:@"data_size"];
        _imageWidth = [dict awe_floatValueForKey:@"width"];
        _imageHeight = [dict awe_floatValueForKey:@"height"];
        _fileCs = [[dict awe_stringValueForKey:@"file_cs"] copy];
        _URLKey = [[dict awe_stringValueForKey:@"url_key"] copy];
        _playerAccessKey = [[dict awe_stringValueForKey:@"player_access_key"] copy];
        _fileHash = [[dict awe_stringValueForKey:@"file_hash"] copy];
        AWEBLOCK_INVOKE(awe_didInitBlock, self);
    }
    return self;
}

- (instancetype)initWithURLList:(NSArray <NSString *> *)URLList
{
    self = [super init];
    if (self) {
        _originURLList = URLList;
        AWEBLOCK_INVOKE(awe_didInitBlock, self);
    }
    return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{@"URI"     : @"uri",
             @"sizeByte"     : @"data_size",
             @"originURLList" : @"url_list",
             @"imageWidth" : @"width",
             @"imageHeight" : @"height",
             @"fileCs" : @"file_cs",
             @"URLKey" : @"url_key",
             @"playerAccessKey" : @"player_access_key",
             @"fileHash" : @"file_hash",
    };
}

- (NSArray *)URLList
{
    if (!URLList || AWEBLOCK_INVOKE(awe_shouldChangeCommonParams, self)) {
        if (!URLList) {
            if (needsParametersWhenInitialized) {
                [self convertUrlListAddCommonParams];
            } else {
                URLList = self.originURLList;
            }
        } else {
            [self convertUrlListAddCommonParams];
        }
    }
    if (awe_FilterCommonParamsBlock) {
        URLList = AWEBLOCK_INVOKE(awe_FilterCommonParamsBlock, URLList);
    }
    return [URLList copy];
}

- (NSURL *)recommendUrl
{
    return [NSURL URLWithString:self.URLList.firstObject?:@""];
}

- (void)convertUrlListAddCommonParams
{
    URLList = [self.originURLList copy];
}

- (void)setNeedsParametersWhenInitializedWithAllowList:(NSArray *)keys
{
    self.whiteKeys = keys;
    needsParametersWhenInitialized = YES;
}

- (NSDictionary *)getURLDict {
    return @{@"uri": self.URI?:@"", @"url_list":self.URLList?:@[]};
}

+ (NSString*)URLString:(NSString *)URLStr appendCommonParams:(NSDictionary *)commonParams
{
    if (!URLStr || ![URLStr isKindOfClass:[NSString class]] || URLStr.length == 0) {
        return URLStr;
    }
    
    if ([commonParams count] == 0) {
        return URLStr;
    }
    
    URLStr = [URLStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSString *sep = @"?";
    if ([URLStr rangeOfString:@"?"].location != NSNotFound) {
        sep = @"&";
    }
    
    NSMutableString *query = [NSMutableString new];
    for (NSString *key in [commonParams allKeys]) {
        NSString *value = commonParams[key];
        if (![value isKindOfClass:[NSString class]]) {
            if ([value respondsToSelector:@selector(stringValue)]) {
                value = [(id)value stringValue];
            } else {
                value = @"";
            }
        }
        [query appendFormat:@"%@%@=%@", sep, [key btd_stringByURLEncode], [value btd_stringByURLEncode]];
        sep = @"&";
    }
    
    NSString *result = [NSString stringWithFormat:@"%@%@", URLStr, query];
    if ([NSURL URLWithString:result]) {
        return result;
    }
    
    return URLStr;
}

+ (void)setDidFinishInitBlock:(void(^)(AWEURLModel *))block
{
    awe_didInitBlock = [block copy];
}

+ (void)setShouldChangeCommonParamsBlock:(BOOL(^)(AWEURLModel *))block
{
    awe_shouldChangeCommonParams = [block copy];
}

+ (void)setFilterCommonParamsBlock:(NSArray*(^)(NSArray*))block
{
    awe_FilterCommonParamsBlock = [block copy];
}

- (NSDictionary *)JSONDictionaryWithoutCommonParameters
{
    NSMutableDictionary *URLDict = [[self getURLDict] mutableCopy];
    if (self.originURLList) {
        [URLDict setValue:self.originURLList forKey:@"url_list"];
    }
    
    return [URLDict copy];
}

#pragma mark AWEProcessRequestInfoProtocol

- (void)processRequestID:(NSString *)requestID
{
    self.requestID = requestID;
    self.URLList.URLRequestID = requestID;
}

@end

@implementation NSArray (ReuquestID)

- (NSString *)URLRequestID
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setURLRequestID:(NSString *)URLRequestID
{
    objc_setAssociatedObject(self, @selector(URLRequestID), URLRequestID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
