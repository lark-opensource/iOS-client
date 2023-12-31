//
//  OCMockAssistant.h
//  OPPlugin-Unit-Tests
//
//  Created by zhangxudong.999 on 2023/3/20.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
@import EEMicroAppSDK;

@class BDPStorageModule;
@protocol BDPSandboxProtocol;
@class OCMockObject, OCMStubRecorder;
@class EMANetworkManager;
@class EMANetworkCipher;

@interface OCMockAssistant : NSObject

+ (nonnull id)mockEMARequestUtil_fetchEnvVariableByUniqueIDCompletion_mockResult:(nullable NSDictionary *)mockResult
                                                                 mockError:(nullable NSError *) mockError;

+ (nonnull id)mock_NEHotspotNetwork_fetch_bssid:(nonnull NSString *)bssid
                                           ssid:(nonnull NSString *)ssid
API_AVAILABLE(ios(15.0), watchos(7.0), macCatalyst(14.0)) API_UNAVAILABLE(macos, tvos);

+(nonnull id)mock_CBCentralManager_manager:(nonnull CBCentralManager *)mockManager
                                     state:(CBManagerState) state
                                isScanning:(BOOL) isScanning;

+ (nonnull OCMockObject *)mock_EERoute_deleate:(EERoute *)route delegate:(id<EMAProtocol>)delegate liveFaceDelegate:(id<EMALiveFaceProtocol>)liveFaceDelegate;

+ (nonnull OCMockObject *)mock_BDPStorageModule:(BDPStorageModule *)storageModule sandboxBlk:(id<BDPSandboxProtocol> (^)(BDPUniqueID *uniqueID))sandboxBlk;

+ (nonnull OCMockObject *)mock_BDPPluginImageCustomImpl;

+ (nonnull OCMockObject *)mock_BDPCommonManager_getCommonWithUniqueIDBlock:(nonnull BDPCommon * (^)(void))block;

+ (nonnull OCMockObject *)mock_BDPAuthorization_checkAuthorizationURL_authType:(BDPAuthorization * _Nonnull)auth;

/** postUrl:(NSString *)urlString
    params:(NSDictionary *)params
    header:(NSDictionary *)header
    completionWithJsonData:(nonnull void (^)(NSDictionary * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable))completionHandler
    eventName:(nonnull NSString *)eventName
    requestTracing:(OPTrace * _Nullable)tracing
 */
+ (nonnull OCMockObject *)mock_PostUrl_EMANetworkManager_shared:(EMANetworkManager *)shared completionDictionary:(NSDictionary * _Nullable (^)(void))completionDictionary completionResponse:(NSURLResponse * _Nullable (^)(void))completionResponse completionError:(NSError * _Nullable (^)(void))completionError;

/**
 - (NSURLSessionTask *)requestUrl:(NSString *)urlString
                           method:(NSString *)method
                           params:(NSDictionary *)params
                           header:(NSDictionary *)header
           completionWithJsonData:(void (^)(NSDictionary * _Nullable json, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                        eventName:(nonnull NSString *)eventName
                   requestTracing:(OPTrace * _Nullable)tracing;
 */
+ (nonnull OCMockObject *)mock_RequestUrl_EMANetworkManager_shared:(EMANetworkManager *)shared
                                              completionDictionary:(NSDictionary * _Nullable (^)(void))completionDictionary
                                                completionResponse:(NSURLResponse * _Nullable (^)(void))completionResponse
                                                   completionError:(NSError * _Nullable (^)(void))completionError;

+ (nonnull OCMockObject *)mock_EMANetworkCipher:(EMANetworkCipher * _Nonnull (^)(void))cipher;

+ (nonnull OCMockObject *)mock_OPECONetworkInterface;
/**
 postForOpenDomain(
     url: String,
     context: ECONetworkServiceContext,
     params: [String: Any],
     header: [String: String],
     completionHandler: @escaping ([String: Any]?, Data?, URLResponse?, Error?) -> Void
 )
 */
+ (nonnull OCMockObject *)mock_OPECONetworkInterface_postForOpenDomainWithCompletionDictionary:(NSDictionary * _Nullable (^)(void))completionDictionary completionResponse:(NSURLResponse * _Nullable (^)(void))completionResponse completionError:(NSError * _Nullable (^)(void))completionError;

@end


