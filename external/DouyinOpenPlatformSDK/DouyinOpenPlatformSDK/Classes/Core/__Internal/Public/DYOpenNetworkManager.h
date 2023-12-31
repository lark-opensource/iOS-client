//
//  DYOpenNetworkManager.h
//  DouyinOpenSDKExtension
//
//  Created by bytedance on 2022/2/10.
//

#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/TTDefaultHTTPRequestSerializer.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^DouyinOpenNetworkCompletion)(NSDictionary *_Nullable userInfo);
typedef void (^DYOpenNetworkCompletion)(NSDictionary * _Nullable respDict, NSError * _Nullable originError);

@interface DYOpenNetworkManager : NSObject

+ (void)addLaneHeaderIfNeeded:(NSMutableURLRequest *)request;

+ (void)downloadImagesWithURLs:(NSArray *)urls completion:(DouyinOpenNetworkCompletion)completion;

+ (void)requestSettingsWithParams:(NSDictionary *)params completion:(DouyinOpenNetworkCompletion)completion;

/// passport 通用接口规范的处理
+ (void)handlePassportRespDict:(nullable NSDictionary *)respDict
                         error:(nullable NSError *)error
                    completion:(void (^_Nullable)(NSDictionary *_Nullable dataDict, NSError *_Nullable error))completion;

@end

@interface DYOpenRequestJsonSerializer: TTDefaultHTTPRequestSerializer

@end

NS_ASSUME_NONNULL_END
