//
//  TTBridgeAuthManager.m
//  BridgeUnifyDemo
//
//  Created by renpeng on 2018/10/9.
//  Copyright © 2018年 tt. All rights reserved.
//

#import "TTBridgeAuthManager.h"
#import "TTBridgeForwarding.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import "TTBridgeRegister.h"
#import <BDJSBridgeAuthManager/IESBridgeAuthManager.h>
#import <objc/runtime.h>
#import "NSObject+IESAuthManager.h"

static NSString *kRemoteInnerDomainsKey = @"kRemoteInnerDomainsKey";

@interface TTBridgeAuthInfo : NSObject

@property(nonatomic, copy) NSArray *methodList;
@property(nonatomic, copy) NSArray *metaList;

@end

@implementation TTBridgeAuthInfo

@end

@interface TTBridgeAuthManager ()

@property(nonatomic, strong) NSMutableDictionary<NSString*, TTBridgeAuthInfo*> *friendDomainMethods;
@property(nonatomic, copy) NSArray<NSString*> *remoteInnerDomains;
@property(nonatomic, copy) NSArray<NSString*> *innerDomains;

@end

@implementation TTBridgeAuthManager


static TTBridgeAuthManager *s = nil;
+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s = [[super allocWithZone:NULL] init];
    });
    return s;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedManager];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        if ([self respondsToSelector:@selector(defaultAuthRequesthHost)]){
            _authRequesthHost = [self defaultAuthRequesthHost];
        }
        _authEnabled = YES;
        _geckoAuthEnabled = YES;
        _friendDomainMethods = [NSMutableDictionary dictionary];
        _remoteInnerDomains = [self adjustedDomains:[[NSUserDefaults standardUserDefaults] arrayForKey:kRemoteInnerDomainsKey]];
        
        if ([self respondsToSelector:@selector(defaultInnerDomains)]){
            _innerDomains = [self defaultInnerDomains];
        }
    }
    return self;
}

#pragma mark - TTBridgeAuthorization

+ (BOOL)_isAuthorizedBridgeCommand:(TTBridgeCommand *)command engine:(id<TTBridgeEngine>)engine URL:(NSURL *)URL {
    if ([URL.absoluteString.lowercaseString hasPrefix:@"file://"]) {
         return YES;
    }
    IESBridgeAuthManager *authManager = ies_getAuthManagerFromEngine(engine);
    if ([TTBridgeAuthManager sharedManager].geckoAuthEnabled &&
        (authManager.hasFetchedAuthInfos || authManager.hasCachedAuthInfos || authManager.builtinAuthInfosEnabled)) {
        return [authManager isAuthorizedMethod:command.bridgeName forURL:URL];
    }
    NSString *domain = URL.host.lowercaseString;
    return [self _isAuthorizedBridgeCommand:command engine:engine domain:domain];
}

+ (BOOL)_isAuthorizedBridgeCommand:(TTBridgeCommand *)command engine:(id<TTBridgeEngine>)engine domain:(NSString *)domain {
    if (command.protocolType == TTPiperProtocolSchemaInterception && self.class.rexxarPublicBridge[command.bridgeName]) {
        return YES;
    }
    TTBridgeRegister *bridgeRegister = [engine.bridgeRegister respondsToBridge:command.bridgeName] ? engine.bridgeRegister : TTBridgeRegister.sharedRegister;
    TTBridgeMethodInfo *methodInfo = [bridgeRegister methodInfoForBridge:command.bridgeName];
    TTBridgeAuthType authType = [[methodInfo.authTypes objectForKey:@([engine engineType])] unsignedIntegerValue];
    if (TTBridgeAuthNotRegistered == authType) {
        return NO;
    }
    
    if (TTBridgeAuthPublic == authType) {//Public bridges can be called by all domains.
        return YES;
    }
    NSDictionary<NSString*, TTBridgeAuthInfo*> *friendDomainMethods;
    @synchronized ([TTBridgeAuthManager sharedManager].friendDomainMethods) {
        friendDomainMethods = [[TTBridgeAuthManager sharedManager].friendDomainMethods copy];
    }
    if (domain.length) {
        if (TTBridgeAuthPrivate == authType) { //Private bridges can only be called by private domains.
            NSMutableArray *methodsUnderDomain = [bridgeRegister privateBridgesOfDomain:domain];
            return [methodsUnderDomain containsObject:command.bridgeName];
        }
        else if ([self isInnerDomain:domain]//Protected bridges can also be called by inner domains and domains in Allowlist.
                 || ([[friendDomainMethods valueForKey:domain].methodList containsObject:command.bridgeName])) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)engine:(id<TTBridgeEngine>)engine isAuthorizedBridge:(TTBridgeCommand *)command domain:(NSString *)domain {
    return self.authEnabled ? [[self class] _isAuthorizedBridgeCommand:command engine:engine domain:domain] : YES;
}

- (void)engine:(id<TTBridgeEngine>)engine isAuthorizedBridge:(TTBridgeCommand *)command domain:(NSString *)domain completion:(void (^)(BOOL success))completion {
    if (completion) {
        completion(self.authEnabled ? [[self class] _isAuthorizedBridgeCommand:command engine:engine domain:domain] : YES);
    }
}

- (BOOL)engine:(id<TTBridgeEngine>)engine isAuthorizedBridge:(TTBridgeCommand *)command URL:(NSURL *)URL {
    return self.authEnabled ? [[self class] _isAuthorizedBridgeCommand:command engine:engine URL:URL] : YES;
}

- (BOOL)engine:(id<TTBridgeEngine>)engine isAuthorizedMeta:(NSString *)meta domain:(NSString *)domain {
    if ([domain.lowercaseString hasPrefix:@"file://"]) {
         return YES;
    }
    if (!self.authEnabled) {
        return YES;
    }
    
    if ([self.class isInnerDomain:domain]) {
        return YES;
    }
    
    TTBridgeAuthInfo *authInfoModel;
    @synchronized (self.friendDomainMethods) {
       authInfoModel = [self.friendDomainMethods objectForKey:domain];
    }
    
    if (!authInfoModel) {
        return NO;
    }
    
    if ([authInfoModel.metaList containsObject:meta]) {
        return YES;
    }
    
    return NO;
}


+ (NSDictionary<NSString *, NSNumber *> *)rexxarPublicBridge {
    return @{@"config" : @YES,
             @"appInfo" : @YES,
             @"adInfo" : @YES,
             @"login" : @YES,
             @"comment" : @YES,
             @"close" : @YES,
             @"isVisible" : @YES,
             @"is_visible" : @YES,
             @"is_login" : @YES,
             @"playVideo" : @YES,
             @"gallery" : @YES,
             @"shareInfo" : @YES,
             @"searchParams" : @YES,
             @"requestChangeOrientation" : @YES,
             @"formDialogClose" : @YES,
             @"showActionSheet" : @YES,
             @"dislike" : @YES,
             @"typos" : @YES,
             @"user_follow_action" : @YES,
             @"toggleGalleryBars" : @YES,
             @"slideShow" : @YES,
             @"relatedShow" : @YES,
             @"adImageShow" : @YES,
             @"slideDownload" : @YES,
             @"zoomStatus" : @YES,
             @"adImageLoadFinish" : @YES,
             @"adImageClick" : @YES,
             @"setupFollowButton" : @YES,
             @"tellClientRetryPrefetch" : @YES,
             @"report" : @YES,
             @"openComment" : @YES,
             @"commentDigg" : @YES};
}

- (BOOL)authEnabled {
    return _authEnabled;
}

#pragma mark - Auth Update
- (void)startGetAuthConfigWithPartnerClientKey:(NSString*)clientKey
                                 partnerDomain:(NSString*)domain
                                     secretKey:(NSString*)secretKey
                                   finishBlock:(void(^)(BOOL success))finishBlock
{
    void(^finish)(BOOL) = ^(BOOL success) {
        if (finishBlock) {
            finishBlock(success);
        }
    };
    if (!domain.length) {
        return finish(NO);
    }
    
    NSDictionary<NSString*, TTBridgeAuthInfo*> *friendDomainMethods;
    @synchronized ([TTBridgeAuthManager sharedManager].friendDomainMethods) {
        friendDomainMethods = [[TTBridgeAuthManager sharedManager].friendDomainMethods copy];
    }
    if ([friendDomainMethods objectForKey:domain]) {
        return finish(YES);
    }
    NSMutableDictionary * getParam = [NSMutableDictionary dictionary];
    [getParam setValue:clientKey forKey:@"client_id"];
    [getParam setValue:domain forKey:@"partner_domain"];
    
    [[TTNetworkManager shareInstance] requestForJSONWithURL:[self.authRequesthHost stringByAppendingString:@"/client_auth/js_sdk/config/v1/"] params:getParam method:@"GET" needCommonParams:NO callback:^(NSError *error, id jsonObj) {
        if (error) {
            return finish(NO);
        }
        if (![jsonObj[@"data"] isKindOfClass:[NSDictionary class]]) {
            return finish(NO);
        }
        
        NSDictionary *data = jsonObj[@"data"] ;

        TTBridgeAuthInfo *infoModel = [[TTBridgeAuthInfo alloc] init];
        NSMutableArray *methodList = [NSMutableArray array];
        if ([data[@"call"] isKindOfClass:[NSArray class]]) {
            [methodList addObjectsFromArray:data[@"call"]];
        }
        if ([data[@"event"] isKindOfClass:[NSArray class]]) {
            [methodList addObjectsFromArray:data[@"event"]];
        }
        infoModel.methodList = methodList;
        if ([data[@"info"] isKindOfClass:[NSArray class]]) {
            infoModel.metaList = data[@"info"];
        }
        @synchronized (self.friendDomainMethods) {
            [self.friendDomainMethods setValue:infoModel forKey:domain];
        }
        return finish(YES);
    }];
}
     
+ (BOOL)isInnerDomain:(NSString *)host {
    host = [host lowercaseString];
    
    for(NSString *innerDomain in [TTBridgeAuthManager sharedManager].innerDomains) {
        if([host hasSuffix:[innerDomain lowercaseString]]) {
            return YES;
        }
    }

    NSArray<NSString*> *remoteInnerDomains;
    @synchronized (self) {
        remoteInnerDomains = [TTBridgeAuthManager sharedManager].remoteInnerDomains;
    }
    for(NSString *innerDomain in remoteInnerDomains) {
        if([host hasSuffix:[innerDomain lowercaseString]]) {
            return YES;
        }
    }
    return NO;
 }
 
- (void)updateInnerDomainsFromRemote:(NSArray<NSString *> *)domains{
    [self updateInnerDomainsFromRemote:domains shouldUpdateGeckoPrivateDomains:YES];
}

 - (void)updateInnerDomainsFromRemote:(NSArray<NSString *> *)domains shouldUpdateGeckoPrivateDomains:(BOOL)shouldUpdateGeckoPrivateDomains{
     if (![domains isKindOfClass:[NSArray class]]) {
         return;
     }
     @synchronized (self) {
         _remoteInnerDomains = [self adjustedDomains:domains];
         [[NSUserDefaults standardUserDefaults] setValue:_remoteInnerDomains forKey:kRemoteInnerDomainsKey];
     }
     if (shouldUpdateGeckoPrivateDomains){
         [IESBridgeAuthManager addPrivateDomains:domains inNamespace:IESPiperDefaultNamespace];
     }
 }

- (BOOL)isInnerDomainForURL:(NSURL *)url{
    if (url.absoluteString.length == 0) {
        return NO;
    }
    if ([url.absoluteString.lowercaseString hasPrefix:@"file://"]) {
         return YES;
    }
    if (self.geckoAuthEnabled &&
        (IESBridgeAuthManager.sharedManager.hasFetchedAuthInfos ||
         IESBridgeAuthManager.sharedManager.hasCachedAuthInfos ||
         IESBridgeAuthManager.sharedManager.builtinAuthInfosEnabled)) {
        IESPiperAuthType authType = [[IESBridgeAuthManager sharedManager] authGroupForURL:url];
        if (authType == IESPiperAuthProtected || authType == IESPiperAuthPrivate ){
            return YES;
        }
        return NO;
    }
    NSString *domain = url.host.lowercaseString;
    if (domain.length){
        return [self.class isInnerDomain:domain];
    }
    return NO;
}

- (NSArray *)adjustedDomains:(NSArray *)domains {
    NSMutableArray *a = NSMutableArray.array;
    [domains enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger supposedDotCount = 1;
        if ([obj hasSuffix:@".com.cn"]) {
            supposedDotCount = 2;
        }
        if ([obj componentsSeparatedByString:@"."].count == supposedDotCount + 1) {
            [a addObject:[NSString stringWithFormat:@".%@", obj]];
        }
        else {
            [a addObject:obj];
        }
    }];
    return a.copy;
}

+ (void)configureWithAuthDomain:(NSString *)authDomain accessKey:(NSString *)accessKey commonParams:(TTBridgeAuthCommonParamsBlock)commonParams {
    [IESBridgeAuthManager configureWithAuthDomain:authDomain accessKey:accessKey commonParams:commonParams];
}

+ (void)configureWithAuthDomain:(nullable NSString *)authDomain accessKey:(NSString *)accessKey boeHostSuffix:(nullable NSString *)boeHostSuffix afterDelay:(NSTimeInterval)delay commonParams:(TTBridgeAuthCommonParamsBlock)commonParams{
    [IESBridgeAuthManager configureWithAuthDomain:authDomain accessKey:accessKey boeHostSuffix:boeHostSuffix afterDelay:delay commonParams:commonParams extraChannels:nil];
}

 @end
