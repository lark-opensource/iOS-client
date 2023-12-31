//
//  AWEURLModel.h
//  Aweme
//
//  Created by Quan Quan on 16/8/10.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import <Mantle/Mantle.h>
#import "AWEBaseApiModel.h"

@interface AWEURLModel : MTLModel <MTLJSONSerializing, AWEProcessRequestInfoProtocol>
{
    NSArray *URLList;
    BOOL needsParametersWhenInitialized;
}

@property (nonatomic, copy, readonly, nullable) NSArray *originURLList;
@property (nonatomic, copy, readonly, nullable) NSArray *whiteKeys;
@property (nonatomic, assign, readonly) CGFloat imageWidth;
@property (nonatomic, assign, readonly) CGFloat imageHeight;
@property (nonatomic, copy, readonly, nullable) NSString *requestID;

@property (nonatomic, assign) CGFloat sizeByte;
@property (nonatomic, copy, nullable) NSString *URI;
@property (nonatomic, copy, readonly, nullable) NSString *fileCs;
@property (nonatomic, copy, readonly, nullable) NSString *URLKey;
@property (nonatomic, copy, readonly, nullable) NSString *playerAccessKey;
@property (nonatomic, copy, readonly, nullable) NSString *fileHash;

- (NSArray * _Nullable)URLList;

- (instancetype)initWithDict:(NSDictionary * _Nullable)dict;
- (instancetype)initWithURLList:(NSArray <NSString *> * _Nullable)URLList;

- (NSURL * _Nullable)recommendUrl;
/**
 keys为空时，  默认增加通用参数；
 keys为非空时，能匹配到白名单中关键字的 URL 才会增加通用参数。
 
 @return 关键字白名单
 */
- (void)setNeedsParametersWhenInitializedWithAllowList:(NSArray * _Nullable)keys;

- (NSDictionary * _Nullable)getURLDict;

+ (void)setDidFinishInitBlock:(void(^)(AWEURLModel *_Nonnull model))block;
+ (void)setShouldChangeCommonParamsBlock:(BOOL(^)(AWEURLModel *_Nonnull model))block;
+ (void)setFilterCommonParamsBlock:(NSArray * _Nullable (^ _Nullable)(NSArray * _Nullable))block;

- (NSDictionary * _Nullable)JSONDictionaryWithoutCommonParameters;


+ (NSString * _Nullable)URLString:(NSString * _Nullable)URLStr appendCommonParams:(NSDictionary * _Nullable)commonParams;
- (void)convertUrlListAddCommonParams;

@end

@interface NSArray (ReuquestID)

@property (nonatomic, copy, nullable) NSString *URLRequestID;

@end

