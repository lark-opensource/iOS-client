//
//  AWEComposerBeautyEffectCacheManager.h
//  CameraClient
//
//  Created by HuangHongsen on 2020/3/10.
//

#import <Foundation/Foundation.h>
#import <CreationKitBeauty/ACCBeautyDefine.h>

// provide interface called external

@class AWEComposerBeautyEffectViewModel;

@interface AWEComposerBeautyEffectCacheManager : NSObject

+ (AWEComposerBeautyEffectCacheManager *)sharedManager;

- (void)updateWithBeautyEffectViewModel:(AWEComposerBeautyEffectViewModel *)effectViewModel;

- (double)ratioForEffectWithResourceID:(NSString *)resourceID
                                   tag:(NSString *)tag
                                gender:(AWEComposerBeautyGender)gender;

- (void)setRatio:(double)ratio forEffectWithResourceID:(NSString *)resourceID tag:(NSString *)tag gender:(AWEComposerBeautyGender)gender;

- (void)applySecondaryComposerItemWithResourceID:(NSString *)resourceID
                                          gender:(AWEComposerBeautyGender)gender;

- (NSArray *)resourceIDsForAppliedEffectsForGender:(AWEComposerBeautyGender)gender;

- (BOOL)userHasModifiedBeautyConfigInCameraPage;

- (AWEComposerBeautyGender)currentGender;

- (void)cleanUpUnifiedBeautyResource;

@end
