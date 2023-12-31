//
//  OCMockAssistant.m
//  OPPlugin-Unit-Tests
//
//  Created by zhangxudong.999 on 2023/3/20.
//
#import <NetworkExtension/NetworkExtension.h>
#import "OCMockAssistant.h"
#import <OCMock/OCMock.h>
#import <OPFoundation/EMARequestUtil.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <TTMicroApp/BDPStorageModule.h>
#import <OPPluginBiz/BDPPluginImageCustomImpl.h>
#import <OPFoundation/BDPCommonManager.h>
#import <ECOInfra/EMANetworkManager.h>
#import <OPFoundation/EMANetworkCipher.h>
@import OPFoundation.EMARouteMediator;
@import OPFoundation.Swift;

@implementation OCMockAssistant
+ (nonnull id)mockEMARequestUtil_fetchEnvVariableByUniqueIDCompletion_mockResult:(nullable NSDictionary *)mockResult
                                                                       mockError:(nullable NSError *) mockError {
    // 创建要被mock的类
    Class AClassToMock = [EMARequestUtil class];
    // 为类生成一个mock对象
    id mockAClass = OCMClassMock(AClassToMock);
    OCMStubRecorder *recorder = OCMStub([mockAClass fetchEnvVariableByUniqueID:[OCMArg any] completion:[OCMArg any]])
        .andDo(^( NSInvocation *invocation) {
            // 获取block参数
            // __unsafe_unretained 是必要的
            // 从 invocation 中获取参数或者返回值，参数需要 __unsafe_unretained 修饰，否则会有 过度释放的问题
            __unsafe_unretained void (^completion)(NSDictionary * _Nullable, NSError * _Nullable);
            [invocation getArgument:&completion atIndex:3];
            // 调用block，返回mock数据
            completion(mockResult, mockError);
        });
    
    return  @[mockAClass, recorder];
}

+ (nonnull id)mock_NEHotspotNetwork_fetch_bssid:(nonnull NSString *)bssid ssid:(nonnull NSString *)ssid {
    NEHotspotNetwork *mockResult = [[NEHotspotNetwork alloc] init];
    id partialMock = OCMPartialMock(mockResult);
    OCMStub([partialMock BSSID]).andReturn(bssid);
    OCMStub([partialMock SSID]).andReturn(ssid);
    OCMStub([partialMock signalStrength]).andReturn(1.0);
    OCMStub([partialMock isSecure]).andReturn(YES);
    OCMStub([partialMock securityType]).andReturn(NEHotspotNetworkSecurityTypeWEP);
    
    id mockClass = OCMClassMock([NEHotspotNetwork class]);
    OCMStub([mockClass fetchCurrentWithCompletionHandler: [OCMArg any]])
        .andDo(^(NSInvocation *invocation) {
            // 获取block参数
            __unsafe_unretained void (^completion)(NEHotspotNetwork * __nullable);
            [invocation getArgument:&completion atIndex:2];
            // 调用block，返回mock数据
            completion(mockResult);
        });
    return @[mockResult, partialMock, mockClass];
}
+(nonnull id)mock_CBCentralManager_manager:(nonnull CBCentralManager *)mockManager
                                     state:(CBManagerState) state
                                isScanning:(BOOL) isScanning {
    id partialMock = OCMPartialMock(mockManager);
    OCMStub([partialMock state]).andReturn(state);
    OCMStub([partialMock isScanning]).andReturn(isScanning);
    return @[partialMock];
}

+ (nonnull OCMockObject *)mock_EERoute_deleate:(EERoute *)route delegate:(id<EMAProtocol>)delegate liveFaceDelegate:(id<EMALiveFaceProtocol>)liveFaceDelegate {
    id partialMock = OCMPartialMock(route);
    OCMStub([partialMock delegate]).andReturn(delegate);
    OCMStub([partialMock liveFaceDelegate]).andReturn(liveFaceDelegate);
    return partialMock;
}

+ (nonnull OCMockObject *)mock_BDPStorageModule:(BDPStorageModule *)storageModule sandboxBlk:(id<BDPSandboxProtocol> (^)(BDPUniqueID *uniqueID))sandboxBlk {
    // OCMockObject
    id partialMock = OCMPartialMock(storageModule);
    
    __block id<BDPSandboxProtocol> result;
    OCMStub([partialMock sandboxForUniqueId: [OCMArg any]])
        .andDo(^(NSInvocation *invocation) {
            __unsafe_unretained BDPUniqueID *uniqueID;
            [invocation getArgument:&uniqueID atIndex:2];
            id<BDPSandboxProtocol> sandbox = sandboxBlk(uniqueID);
            result = sandbox;
        }).andReturn(result);
    
    return partialMock;
}

+ (nonnull OCMockObject *)mock_BDPPluginImageCustomImpl {
    id partialMock = OCMPartialMock([BDPPluginImageCustomImpl sharedPlugin]);
    OCMStub([partialMock bdp_chooseImageWithModel:[OCMArg any] fromController:[OCMArg any] completion:[OCMArg any]])
        .andDo(^(NSInvocation *invocation) {
            __unsafe_unretained void (^ _Nonnull completion)(NSArray<UIImage *> * _Nullable images, BOOL isOriginal, BDPImageAuthResult authResult);
            [invocation getArgument:&completion atIndex:4];
            UIImage *image = [[UIImage alloc] init];
            completion(@[image], YES, BDPImageAuthPass);
        });
    return partialMock;
}

+ (nonnull OCMockObject *)mock_BDPCommonManager_getCommonWithUniqueIDBlock:(BDPCommon * _Nonnull (^)(void))block {
    id partialMock = OCMPartialMock([BDPCommonManager sharedManager]);
    
    OCMStub([partialMock getCommonWithUniqueID:[OCMArg any]])
        .andDo(^(NSInvocation *invocation) {
        }).andReturn(block());
    return partialMock;
}

+ (nonnull OCMockObject *)mock_BDPAuthorization_checkAuthorizationURL_authType:(BDPAuthorization * _Nonnull)auth {
    id partialMock = OCMPartialMock(auth);
    OCMStub([partialMock checkAuthorizationURL:[OCMArg any] authType:[OCMArg any]])
        .andReturn(YES);
    return partialMock;
}

/** postUrl:(NSString *)urlString
    params:(NSDictionary *)params
    header:(NSDictionary *)header
    completionWithJsonData:(nonnull void (^)(NSDictionary * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable))completionHandler
    eventName:(nonnull NSString *)eventName
    requestTracing:(OPTrace * _Nullable)tracing
 */
+ (nonnull OCMockObject *)mock_PostUrl_EMANetworkManager_shared:(EMANetworkManager *)shared completionDictionary:(NSDictionary * _Nullable (^)(void))completionDictionary completionResponse:(NSURLResponse * _Nullable (^)(void))completionResponse completionError:(NSError * _Nullable (^)(void))completionError {
    id partialMock = OCMPartialMock(shared);
    
    OCMStub([partialMock postUrl:[OCMArg any] params:[OCMArg any] header:[OCMArg any] completionWithJsonData:[OCMArg any] eventName:[OCMArg any] requestTracing:[OCMArg any]])
        .andDo(^(NSInvocation *invocation) {
            __unsafe_unretained void (^ _Nonnull completion)(NSDictionary * _Nullable dictionary, NSURLResponse * _Nullable response, NSError * _Nullable error);
            [invocation getArgument:&completion atIndex:5];
            completion(completionDictionary(), completionResponse(), completionError());
        });
    return partialMock;
}

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
                                                  completionError:(NSError * _Nullable (^)(void))completionError {
    id partialMock = OCMPartialMock(shared);
    
    OCMStub([partialMock requestUrl:[OCMArg any] method:[OCMArg any] params:[OCMArg any] header:[OCMArg any]  completionWithJsonData:[OCMArg any] eventName:[OCMArg any] requestTracing:[OCMArg any]])
        .andDo(^(NSInvocation *invocation) {
            __unsafe_unretained void (^ _Nonnull completion)(NSDictionary * _Nullable dictionary, NSURLResponse * _Nullable response, NSError * _Nullable error);
            [invocation getArgument:&completion atIndex:6];
            completion(completionDictionary(), completionResponse(), completionError());
        });
    return partialMock;
}

+ (nonnull OCMockObject *)mock_EMANetworkCipher:(EMANetworkCipher * _Nonnull (^)(void))cipher {
    id mockAClass = OCMClassMock(EMANetworkCipher.class);
    OCMStub([mockAClass getCipher])
        .andReturn(cipher());
    
    return mockAClass;
}

+ (nonnull OCMockObject *)mock_OPECONetworkInterface {
    id mockAClass = OCMClassMock(OPECONetworkInterface.class);
    OCMStub([mockAClass enableECOWithPath:[OCMArg any]])
        .andReturn(YES);
    
    return mockAClass;
}

+ (nonnull OCMockObject *)mock_OPECONetworkInterface_postForOpenDomainWithCompletionDictionary:(NSDictionary * _Nullable (^)(void))completionDictionary completionResponse:(NSURLResponse * _Nullable (^)(void))completionResponse completionError:(NSError * _Nullable (^)(void))completionError {
    id mockAClass = OCMClassMock(OPECONetworkInterface.class);
    
    OCMStub(ClassMethod([mockAClass postForOpenDomainWithUrl: [OCMArg any] context: [OCMArg any] params: [OCMArg any] header: [OCMArg any] completionHandler: [OCMArg any]]))
        .andDo(^(NSInvocation *invocation) {
            __unsafe_unretained void (^ _Nonnull completion)(NSDictionary * _Nullable dictionary, NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error);
            [invocation getArgument:&completion atIndex:6];
            completion(completionDictionary(), nil, completionResponse(), completionError());
        });
    return mockAClass;
}

@end
