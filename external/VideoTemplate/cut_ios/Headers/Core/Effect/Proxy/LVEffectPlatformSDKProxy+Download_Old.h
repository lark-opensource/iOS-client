//
//  LVEffectPlatformSDKProxy+Download_Old.h
//  VideoTemplate
//
//  Created by wuweixin on 2020/10/23.
//

#import "LVEffectPlatformSDKProxy.h"
@class IESEffectModel;
@class IESEffectPlatformResponseModel;
@class LVEffectPanelItem;
@protocol LVEffectValidator;

NS_ASSUME_NONNULL_BEGIN

@interface LVEffectPlatformSDKProxy (Download_Old)
- (EffectPlatform *)lvEffectPlatform;

- (void)downloadList:(NSString *)panel completion:(nullable void(^)(IESEffectPlatformResponseModel  * _Nullable result, NSError * _Nullable error))completion;

- (void)downloadList:(NSString *)panel needCache:(BOOL)needCache completion:(nullable void(^)(IESEffectPlatformResponseModel * _Nullable result, NSError * _Nullable error))completion;

- (void)downloadList:(NSString *)panel needCache:(BOOL)needCache resourceIDs:(NSArray<NSString *> *)resourceIDs completion:(nullable void(^)(NSArray<IESEffectModel *> * _Nullable result, NSError * _Nullable error))completion;

- (void)downloadEffect:(IESEffectModel *)effect completion:(nullable void(^)(NSString * _Nullable filePath, NSError * _Nullable error))completion;

- (void)downloadEffect:(IESEffectModel *)effect tryMaxCount:(NSUInteger)tryMaxCount validator:(_Nullable id<LVEffectValidator>)validator completionWithTryCount:(nullable void(^)(NSString * _Nullable filePath, NSUInteger tryCount, NSError * _Nullable error))completionWithTryCount completion:(nullable void(^)(NSString * _Nullable filePath, NSError * _Nullable error))completion;

- (void)downloadEffectItem:(LVEffectPanelItem *)item completion:(nullable void(^)(NSString * _Nullable filePath, NSError * _Nullable error))completion;

- (void)downloadEffectItem:(LVEffectPanelItem *)item tryMaxCount:(NSUInteger)tryMaxCount validator:(_Nullable id<LVEffectValidator>)validator completionWithTryCount:(nullable void(^)(NSString * _Nullable filePath, NSUInteger tryCount, NSError * _Nullable error))completionWithTryCount completion:(nullable void(^)(NSString * _Nullable filePath, NSError * _Nullable error))completion;

- (void)checkEffectUpdate:(NSString *)pannel completion:(nullable void(^)(BOOL needUpdate))completion;

- (nullable IESEffectPlatformResponseModel *)cachedEffects:(NSString *)pannel;


- (void)downloadEffectListWithEffectIDS:(NSArray<NSString *> *)effectIDs
                             completion:(void (^)(NSError *_Nullable error, NSArray<IESEffectModel *> *_Nullable effects))completion;

- (void)downloadEffectListWithResourceIds:(NSArray<NSString *> *)resourceIds
                                    panel:(NSString *)panel
                               completion:(void (^)(NSError *_Nullable error, NSArray<IESEffectModel *> *_Nullable effects))completion;
@end

NS_ASSUME_NONNULL_END
