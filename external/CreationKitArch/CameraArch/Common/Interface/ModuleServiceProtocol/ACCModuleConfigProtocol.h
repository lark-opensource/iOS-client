//
//  ACCModuleConfigProtocol.h
//  CameraClient
//
//  Created by liyingpeng on 2020/4/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCModuleConfigProtocol <NSObject>

// EffectPlatform

- (NSString *)effectRequestDomainString;

- (NSString *)effectPlatformAccessKey;

- (void)effectDealWithRegionDidChange;

- (void)configureExtraInfoForEffectPlatform;

- (nullable NSDictionary *)effectPlatformExtraCustomParameters;
- (NSDictionary *(^_Nullable)(void))effectPlatformIOPParametersBlock;

// upload service

- (BOOL)shouldUploadServiceSetOptimizationPatameter;

// video router

- (NSString *)routerTitleUserDisplayName:(id)user;

- (BOOL)needCheckLoginStatusWhenStartRecording;

// UIViewController+ACCUIKitEmptyPage

- (BOOL)shouldTitleColorUseDefaultConfigColor;

// FilterViewModel

- (BOOL)disableFilterEffectWhenUseNormalFilter;

// Cell Title

- (BOOL)useBoldTextForCellTitle;

// publish view model

- (BOOL)allowCommerceChallenge;

- (BOOL)useDefaultFormatNumberPolicy;

@end

NS_ASSUME_NONNULL_END
