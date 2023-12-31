//
//  IESBridgeAuthManager.h
//  IESWebKit
//
//  Created by Lizhen Hu on 2019/8/12.
//

#import <Foundation/Foundation.h>

#if __has_include(<BDJSBridgeAuthManager/BDJSBridgeAuthManager_Rename.h>)
#import <BDJSBridgeAuthManager/BDJSBridgeAuthManager_Rename.h>
#endif

NS_ASSUME_NONNULL_BEGIN

#ifndef IESPiperAuthTypeDef
#define IESPiperAuthTypeDef
typedef NS_ENUM(NSUInteger, IESPiperAuthType){
    IESPiperAuthPublic = 0,
    IESPiperAuthProtected,
    IESPiperAuthPrivate,
    IESPiperAuthSecure,
};
#endif
extern NSString * const IESPiperDefaultNamespace;

typedef NSDictionary * _Nonnull (^IESBridgeAuthCommonParamsBlock)(void);

@class IESBridgeAuthManager;

@protocol IESBridgeAuthManagerDelegate <NSObject>

- (BOOL)authManager:(IESBridgeAuthManager *)authManager isAuthorizedMethod:(NSString *)method forURL:(NSURL *)url;

- (void)authManager:(IESBridgeAuthManager *)authManager isAuthorizedMethod:(NSString *)method success:(BOOL)success forURL:(NSURL *)url stage:(NSString *)stage list:(nullable NSArray <NSString *> *)list;

@end

@interface IESBridgeAuthManager : NSObject

/**
Configure the auth manager.

@param authDomain The gecko domain, checkout https://bytedance.feishu.cn/docs/doccnwnn2vuLNgrD45ztowWF3Cb#M9Ix6A.
@param accessKey The gecko access key.
@param boeHostSuffix The BOE host suffix used to match and truncate when authenticating.
@param commonParams The network common parameters.
@param delay The delay after which it starts to fetch the auth infos.
*/
+ (void)configureWithAuthDomain:(nullable NSString *)authDomain accessKey:(NSString *)accessKey boeHostSuffix:(nullable NSString *)boeHostSuffix afterDelay:(NSTimeInterval)delay commonParams:(IESBridgeAuthCommonParamsBlock)commonParams extraChannels:(nullable NSArray<NSString *> *)extraChannels;
+ (void)configureWithAuthDomain:(nullable NSString *)authDomain accessKey:(NSString *)accessKey afterDelay:(NSTimeInterval)delay commonParams:(IESBridgeAuthCommonParamsBlock)commonParams extraChannels:(nullable NSArray<NSString *> *)extraChannels;
+ (void)configureWithAuthDomain:(nullable NSString *)authDomain accessKey:(NSString *)accessKey commonParams:(IESBridgeAuthCommonParamsBlock)commonParams;
+ (void)configureWithAuthDomain:(nullable NSString *)authDomain accessKey:(NSString *)accessKey afterDelay:(NSTimeInterval)delay commonParams:(IESBridgeAuthCommonParamsBlock)commonParams;

+ (void)addPrivateDomains:(NSArray<NSString *> *)privateDomains inNamespace:(NSString *)namespace;

+ (instancetype)sharedManager;

+ (instancetype)sharedManagerWithNamesapce:(NSString *_Nullable)namespace;

- (void)addPrivateDomains:(NSArray<NSString *> *)privateDomains;

- (void)registerMethod:(NSString *)method withAuthType:(IESPiperAuthType)authType;

- (BOOL)isAuthorizedMethod:(NSString *)method forURL:(NSURL *)url;
- (IESPiperAuthType)authGroupForURL:(NSURL *)url;

// Reminder: keep disabled in production environment.
@property (nonatomic, assign, getter=isBypassJSBAuthEnabled) BOOL bypassJSBAuthEnabled;

@property (nonatomic, assign, getter=isBuiltinAuthInfosEnabled) BOOL builtinAuthInfosEnabled;
@property (nonatomic, assign, getter=hasFetchedAuthInfos, readonly) BOOL fetchedAuthInfos;
@property (nonatomic, assign, readonly) BOOL hasCachedAuthInfos;
@property (nonatomic, weak) id<IESBridgeAuthManagerDelegate> delegate;

@property (nonatomic, copy) NSArray<NSString *> *innerDomains;

@end


#if __has_include(<BDJSBridgeAuthManager/IESBridgeAuthManager+CN.h>)
@interface IESBridgeAuthManager (CN)
+ (void)configureWithAccessKey:(NSString *)accessKey commonParams:(IESBridgeAuthCommonParamsBlock)commonParams;
+ (NSArray<NSString *> *)defaultPrivateDomains;
@end
#endif


NS_ASSUME_NONNULL_END
