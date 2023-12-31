//
//  IESBridgeAuthManager+BDJSBridgeAuthDebug.h
//  BDJSBridgeAuthManager-CN-Core
//
//  Created by bytedance on 2020/8/26.
//

#import "IESBridgeAuthManager.h"
#import "IESBridgeAuthModel.h"

typedef void (^IESBridgeAuthJSONFinishBlock)(NSError * _Nullable error, id _Nullable jsonObj);

@interface IESBridgeAuthManager (BDPiperAuthDebug)

+ (IESBridgeAuthRequestParams *)requestParams;

+ (NSDictionary *)getRequestParamsWithAccessKey:(NSString *)accessKey commonParams:(NSDictionary *)commonParams extraChannels:(NSArray<NSString *> *)extraChannels;
+ (void)fetchAuthInfosWithCompletion:(IESBridgeAuthJSONFinishBlock)completion;
+ (void)getBuiltInAuthInfosWithCompletion:(IESBridgeAuthJSONFinishBlock)completion;

@end
