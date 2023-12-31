//
//  BDTNetworkManager.h
//  BDTuring
//
//  Created by bob on 2019/8/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    BDTNetworkTagTypeAuto,
    BDTNetworkTagTypeManual,
} BDTNetworkTagType;

typedef void (^BDTuringNetworkFinishBlock)(NSData * _Nullable data);
typedef void (^BDTuringTwiceVerifyNetworkFinishBlock)(NSError * _Nullable error, NSData * _Nullable data, NSInteger statusCode);

FOUNDATION_EXTERN NSString * const kBDTuringHeaderContentType;
FOUNDATION_EXTERN NSString * const kBDTuringHeaderAccept;
FOUNDATION_EXTERN NSString * const kBDTuringHeaderConnection;

FOUNDATION_EXTERN NSString * const BDTuringHeaderContentTypeJSON;
FOUNDATION_EXTERN NSString * const BDTuringHeaderContentTypeData;
FOUNDATION_EXTERN NSString * const BDTuringHeaderAccept;
FOUNDATION_EXTERN NSString * const BDTuringHeaderConnection;
FOUNDATION_EXTERN NSString * const kBDTuringHeaderSDKVersion;
FOUNDATION_EXTERN NSString * const kBDTuringHeaderSDKParameters;

@protocol BDTNetworkManagerImp <NSObject>

- (void)asyncRequestForURL:(NSString *)requestURL
                    method:(NSString *)method
           queryParameters:(nullable NSDictionary *)queryParameters
            postParameters:(nullable NSDictionary *)postParameters
                  callback:(BDTuringNetworkFinishBlock)callback
             callbackQueue:(nullable dispatch_queue_t)queue
                   encrypt:(BOOL)encrypt
                   tagType:(BDTNetworkTagType)type;

- (void)tvRequestForJSONWithResponse:(NSString *)requestURL
                              params:(id)params
                              method:(NSString *)method
                    needCommonParams:(BOOL)commonParams
                         headerField:(NSDictionary *)headerField
                            callback:(BDTuringTwiceVerifyNetworkFinishBlock)callback
                             tagType:(BDTNetworkTagType)type;

- (void)uploadEvent:(NSString *)key param:(NSDictionary *)param;
- (nullable NSString *)networkType;

@end

@interface BDTNetworkManager : NSObject<BDTNetworkManagerImp>

- (nullable NSDictionary *)createTaggedHeaderFieldWith:(nullable NSDictionary *)headerField type:(BDTNetworkTagType)type;
- (void)setup;

+ (instancetype)sharedInstance;

+ (void)asyncRequestForURL:(NSString *)requestURL
                    method:(NSString *)method
           queryParameters:(nullable NSDictionary *)queryParameters
            postParameters:(nullable NSDictionary *)postParameters
                  callback:(BDTuringNetworkFinishBlock)callback
             callbackQueue:(nullable dispatch_queue_t)queue
                   encrypt:(BOOL)encrypt
                   tagType:(BDTNetworkTagType)type;


+ (void)tvRequestForJSONWithResponse:(NSString *)requestURL
                              params:(id)params
                              method:(NSString *)method
                    needCommonParams:(BOOL)commonParams
                         headerField:(NSDictionary *)headerField
                            callback:(BDTuringTwiceVerifyNetworkFinishBlock)callback
                             tagType:(BDTNetworkTagType)type;

+ (void)uploadEvent:(NSString *)key param:(NSDictionary *)param;
+ (nullable NSString *)networkType;

@end

NS_ASSUME_NONNULL_END
