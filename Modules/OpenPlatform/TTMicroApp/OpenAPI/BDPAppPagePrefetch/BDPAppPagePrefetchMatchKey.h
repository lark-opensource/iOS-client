//
//  BDPAppPagePrefetchMatchKey.h
//  Timor
//
//  Created by insomnia on 2021/2/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDPPrefetchDetailMatchType)
{
    BDPPrefetchDetailMatchErrorUnknow            = -999,          // 未知错误（仅在代码中方便使用，未写入文档，且与文档上不对应）
    BDPPrefetchDetailMatchErrorURLorQuery        = 0,             // 该请求是否在启动时已发出的预取请求列表中（url + query, 不区分 query 顺序）
    BDPPrefetchDetailMatchErrorMethod            = 1,             // 该请求规则校验失败(method)
    BDPPrefetchDetailMatchErrorHeader            = 2,             // 该请求规则校验失败(header)
    BDPPrefetchDetailMatchErrorResponseType      = 3,             // 该请求规则校验失败(responseType)
    BDPPrefetchDetailMatchErrorDataType          = 4,             // 该请求规则校验失败(dataType)
    BDPPrefetchDetailMatchErrorInner             = 20,            // 未发起预取（应该不可能吧......）
    BDPPrefetchDetailMatchSuccess                = 999,           // match成功(仅在代码中方便使用，未写入文档，且与文档上不对应)
};

@class OPPrefetchErrnoWrapper;

@interface BDPAppPagePrefetchMissKeyItem: NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy, nullable) NSString *defaultValue;
@property (nonatomic, assign) BOOL shouldDelete;

@end

@interface BDPAppPagePrefetchMatchKey : NSObject<NSCopying>

@property (nonatomic ,copy, readonly) NSArray<NSString*> *requiredStorageKeys;
@property (nonatomic, copy, readonly) NSString* url;
@property (nonatomic, copy, readonly) NSString* method;
@property (nonatomic, copy, readonly) NSDictionary* header;
@property (nonatomic, copy, readonly) NSString* data;
@property (nonatomic, copy, readonly) NSString* responseType;

@property (nonatomic, copy, readonly) NSString *dateFormatter;
@property (nonatomic, copy, readonly) NSArray<BDPAppPagePrefetchMissKeyItem *> *missKeyItems;

@property (nonatomic, copy) NSArray<NSString *> *missKeysResult;

@property (nonatomic, copy) NSArray<NSString *> * (^getCacheUrls)(void);

- (instancetype)initWithParam:(NSDictionary*)param;
- (instancetype)initWithUrl:(NSString*)url;
- (OPPrefetchErrnoWrapper *)isEqualToMatchKey:(BDPAppPagePrefetchMatchKey *)object;
-(void)updateUrlIfNewVersion:(NSString *) url;
-(void)updateHeaderIfNewVersion:(NSDictionary *) header;
-(void)updateDataIfNewVersion:(NSString *) data;

@end

NS_ASSUME_NONNULL_END
