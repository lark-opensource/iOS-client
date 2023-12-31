//
//  EMARequestUtil.h
//  EEMicroAppSDK
//
//  Created by tujinqiu on 2019/8/19.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPSandboxProtocol.h>
//#import <OPFoundation/OPFoundation-Swift.h>
#import <OPFoundation/BDPTracing.h>
NS_ASSUME_NONNULL_BEGIN

/// error domain
extern NSString *const EMARequestErrorDomain;

typedef NS_ENUM(NSInteger, EMARequestErrorCode) {
    EMARequestFailed = -9999,
    EMARequestJSONParseFailed
};
@protocol BDPContextProtocol;
@interface EMARequestUtil : NSObject

/// V2版本支持多种形态
+ (void)fetchOpenChatIDsByChatIDs:(nonnull NSArray<NSDictionary *> *)chatItems
                          sandbox:(nullable id<BDPSandboxProtocol> )sandbox
                        orContext:(nullable NSObject<BDPContextProtocol> *)context
                completionHandler:(nonnull void (^)(NSDictionary<NSString *, NSString *> *_Nullable openChatIdDict, NSError *_Nullable error))completionHandler;

+ (void)fetchChatIDByOpenChatIDs:(NSArray<NSString *> *)openChatids
                        uniqueID:(nonnull OPAppUniqueID *)uniqueID
                         sandbox:(nonnull id<BDPSandboxProtocol> )sandbox
                   tracing:(OPTrace * _Nullable)parentTracing
               completionHandler:(nonnull void (^)(NSDictionary<NSString *, NSString *>  * _Nullable, NSError * _Nullable))completionHandler;

/// V2版本支持多种形态
/// using uniqueID replaced
+ (void)fetchChatIDByOpenChatIDs:(nonnull NSArray<NSString *> *)openChatids
                         context:(nonnull NSObject<BDPContextProtocol> *)context
                   tracing:(OPTrace * _Nullable)parentTracing
               completionHandler:(nonnull void (^)(NSDictionary<NSString *, NSString *>  * _Nullable, NSError * _Nullable))completionHandler;


/// 获取配置在对应环境(比如SAAS,KA)下的业务配置
/// @param uniqueID uniqueID
/// @param completion 完成回调
+ (void)fetchEnvVariableByUniqueID:(nonnull OPAppUniqueID *)uniqueID
                        completion:(nonnull void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion;

+ (void)requestLightServiceInvokeByAppID:(NSString *)appID
                                 context:(NSDictionary *)context
                              completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion;

+ (void)fetchTenantAppScopesByUniqueID:(OPAppUniqueID *)uniqueID
                            completion:(void (^)(NSDictionary * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable))completion;
+ (void)fetchApplyAppScopeStatusByUniqueID:(OPAppUniqueID *)uniqueID
                                completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion;
+ (void)requestApplyAppScopeByUniqueID:(OPAppUniqueID *)uniqueID
                            completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion;

+ (BDPTracing *)generateRequestTracing:(OPAppUniqueID *)uniqueID;

///迁移API适配
+ (void)fetchOpenPluginChatIDsByChatIDs:(nonnull NSArray<NSDictionary *> *)chatItems
                               uniqueID:(OPAppUniqueID *)uniqueID
                                session:(NSString *)session
                          sessionHeader:(NSDictionary*)sessionHeader
                      completionHandler:(nonnull void (^)(NSDictionary *_Nullable openChatIdDict, NSError *_Nullable error))completionHandler;

+ (NSString * _Nullable)userSession;

@end

NS_ASSUME_NONNULL_END
