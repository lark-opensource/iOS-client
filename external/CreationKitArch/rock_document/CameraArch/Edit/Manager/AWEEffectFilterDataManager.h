//
//  AWEEffectFilterDataManager.h
//  AWEStudio
//
//  Created by liubing on 19/04/2018.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <TTVideoEditor/IESMMBaseDefine.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <EffectPlatformSDK/IESEffectPlatformResponseModel.h>
#import <CreationKitInfra/AWEModernStickerDefine.h>

#ifndef AWEEffectFilterDataManagerRefreshNotification
#define AWEEffectFilterDataManagerRefreshNotification @"kAWEEffectFilterDataManagerRefreshNotification"
#endif

#ifndef AWEEffectFilterDataManagerListUpdateNotification
#define AWEEffectFilterDataManagerListUpdateNotification @"kAWEEffectFilterDataManagerListUpdateSuccessNotification"
#endif

@class IESMMEffectStickerInfo;

typedef IESMMEffectStickerInfo * (^AWEEffectFilterPathBlock)(NSString *effectPathId, IESEffectFilterType effectType);

@interface AWEEffectFilterDataManager : NSObject
@property (nonatomic, assign, readonly) BOOL isFetching;
@property (nonatomic, copy) NSDictionary *trackExtraDic;

+ (instancetype)defaultManager;

- (void)updateEffectFilters;
- (IESEffectModel *)effectWithID:(NSString *)effectId;
- (NSString *)effectIdWithType:(IESEffectFilterType)effectType;
- (UIColor *)maskColorForEffect:(IESEffectModel *)effect;
- (AWEEffectDownloadStatus)downloadStatusOfEffect:(IESEffectModel *)effect;
- (void)appendDownloadedEffect:(IESEffectModel *)effectModel;
- (AWEEffectFilterPathBlock)pathConvertBlock;

- (IESEffectPlatformResponseModel *)effectPlatformModel;

- (NSArray<IESEffectModel *> *)builtinEffects;

/// Transition effect duration
- (CGFloat)effectDurationForEffect:(IESEffectModel *)effect;

- (void)addEffectToDownloadQueue:(IESEffectModel *)effect;
@end
