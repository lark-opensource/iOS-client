//
//  IESLiveResouceBundle+Hooks.h
//  Pods
//
//  Created by Zeus on 2016/12/26.
//
//  用于在从Bundle获取资源前(pre)或获取资源后(post)，替换掉资源内容
//  在线文案配置、在线keyvalue服务等，可以通过这种方式对接进来
//
//

#import "IESLiveResouceBundle.h"

typedef id (^IESLiveResouceBundlePreHookBlock)(NSString *key, NSString *type, NSString *category);
typedef id (^IESLiveResouceBundlePostHookBlock)(NSString *key, NSString *type, NSString *category, id originValue);

@protocol IESLiveResouceBundleHookerProtocol <NSObject>

@optional
- (IESLiveResouceBundlePreHookBlock)preHook;
- (IESLiveResouceBundlePostHookBlock)postHook;

@end

@interface IESLiveResouceBundle (Hooker)

+ (void)addHooker:(id<IESLiveResouceBundleHookerProtocol>)hooker forCategory:(NSString *)category;
+ (void)addPreHook:(IESLiveResouceBundlePreHookBlock)preHookBlock forCategory:(NSString *)category;
+ (void)addPostHook:(IESLiveResouceBundlePostHookBlock)postHookBlock forCategory:(NSString *)category;
+ (void)removeHooker:(id<IESLiveResouceBundleHookerProtocol>)hooker forCategory:(NSString *)category;
+ (void)removeAllHookersForCategory:(NSString *)category;

- (void)addHooker:(id<IESLiveResouceBundleHookerProtocol>)hooker;
- (void)addPreHook:(IESLiveResouceBundlePreHookBlock)preHookBlock;
- (void)addPostHook:(IESLiveResouceBundlePostHookBlock)postHookBlock;
- (void)removeHooker:(id<IESLiveResouceBundleHookerProtocol>)hooker;
- (void)removeAllHookers;

@end

@interface IESLiveResouceBundleHooker : NSObject <IESLiveResouceBundleHookerProtocol>

@property (nonatomic, copy) IESLiveResouceBundlePreHookBlock preHook;
@property (nonatomic, copy) IESLiveResouceBundlePostHookBlock postHook;

- (instancetype)initWithPreHook:(IESLiveResouceBundlePreHookBlock)preHook postHook:(IESLiveResouceBundlePostHookBlock)postHook;

@end
