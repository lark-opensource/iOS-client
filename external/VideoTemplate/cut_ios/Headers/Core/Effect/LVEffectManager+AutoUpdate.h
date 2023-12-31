//
//  LVEffectManager+AutoUpdate.h
//  LVTemplate
//
//  Created by lxp on 2020/2/19.
//
#import "LVEffectManager.h"
#import "LVEffectPlatformConfig.h"
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVEffectManager (AutoUpdate)

+ (void)requestAllEffectListWithCache:(BOOL)needCache;

+ (void)checkUpdateIfNeeded:(LVMediaDraft *)draft rootPath:(NSString *)rootPath;

+ (void)cleanUnusedResourceIfNeeded:(LVMediaDraft *)draft rootPath:(NSString *)rootPath;

+ (NSArray<LVEffectPanelType> *)effectPanelList;

+ (IESEffectModel *_Nullable)cacheEffect:(LVEffectPanelType)panel resourceID:(NSString *)resourceID effectID: (NSString *)effectID;

@end

NS_ASSUME_NONNULL_END
