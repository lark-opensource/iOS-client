//
//  ACCBeautyManager.h
//  CameraClient
//
//  Created by chengfei xiao on 2020/1/16.
//

#import <Foundation/Foundation.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCBeautyManager : NSObject
@property (nonatomic, assign, readonly) BOOL hasDetectMale;
@property (nonatomic, strong, readonly) AWEComposerBeautyEffectViewModel *composerEffectVM;

+ (instancetype)defaultManager;

- (void)resetWhenQuitRecoder;

- (void)setHasDetectMale:(BOOL)hasDetectMale;

- (void)setComposerEffectVM:(nullable AWEComposerBeautyEffectViewModel *)composerEffectVM;

@end

NS_ASSUME_NONNULL_END
