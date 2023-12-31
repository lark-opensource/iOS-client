//
//  TTBridgeAuthManager.h
//  BridgeUnifyDemo
//
//  Created by renpeng on 2018/10/9.
//  Copyright © 2018年 tt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTBridgeAuthorization.h"

@protocol TTBridgeAuthDefaultSettings <NSObject>

- (NSString *)defaultAuthRequesthHost;

- (NSArray *)defaultInnerDomains;

@end

typedef NSDictionary *(^TTBridgeAuthCommonParamsBlock)(void);
@interface TTBridgeAuthManager : NSObject<TTBridgeAuthorization, TTBridgeAuthDefaultSettings>

+ (instancetype)sharedManager;

// Union the local inner domains and domains from Allowlist in settings.
- (void)updateInnerDomainsFromRemote:(NSArray<NSString *> *)domains;

- (void)updateInnerDomainsFromRemote:(NSArray<NSString *> *)domains shouldUpdateGeckoPrivateDomains:(BOOL) shouldUpdateGeckoPrivateDomains;

// If YES is returned, the url has the authorization to call all protected and public jsbridges.
// It will return YES in the following cases.
// 1. If the url has the Prefix "file://", return YES.
// 2. If the gecko auth is used, it will return YES when the url's authType in gecko is protected or privated.
// 3. If the gecko auth is not used, it will return YES when the url's domain is in the remoteInnerDomains or the defaultInnerDomains.
- (BOOL)isInnerDomainForURL:(NSURL *)url;

- (void)startGetAuthConfigWithPartnerClientKey:(NSString*)clientKey
                                 partnerDomain:(NSString*)domain
                                     secretKey:(NSString*)secretKey
                                   finishBlock:(void(^)(BOOL success))finishBlock;

// 3.0 new auth interface
+ (void)configureWithAuthDomain:(NSString *)authDomain accessKey:(NSString *)accessKey commonParams:(TTBridgeAuthCommonParamsBlock)commonParams;

/**
Configure the auth manager.

@param authDomain The gecko domain, checkout https://bytedance.feishu.cn/docs/doccnwnn2vuLNgrD45ztowWF3Cb#M9Ix6A.
@param accessKey The gecko access key.
@param boeHostSuffix The BOE host suffix used to match and truncate when authenticating.
@param commonParams The network common parameters.
@param delay The delay after which it starts to fetch the auth infos.
*/
+ (void)configureWithAuthDomain:(nullable NSString *)authDomain accessKey:(NSString *)accessKey boeHostSuffix:(nullable NSString *)boeHostSuffix afterDelay:(NSTimeInterval)delay commonParams:(TTBridgeAuthCommonParamsBlock)commonParams;

/**
 Default YES.
 */
@property (nonatomic, assign) BOOL authEnabled;

/**
 Default @"https://i.snssdk.com".
 */
@property (atomic, copy) NSString *authRequesthHost;

/**
Default YES.
*/
@property (nonatomic, assign) BOOL geckoAuthEnabled;

@end

#if __has_include(<TTBridgeUnify/TTBridgeAuthManager+CN.h>)
@interface TTBridgeAuthManager (CN)
+ (void)configureWithAccessKey:(NSString *)accessKey commonParams:(TTBridgeAuthCommonParamsBlock)commonParams;
@end
#endif
