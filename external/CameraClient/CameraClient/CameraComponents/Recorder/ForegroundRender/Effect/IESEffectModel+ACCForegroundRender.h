//
//  IESEffectModel+ACCForegroundRender.h
//  CameraClient-Pods-Aweme
//
//  Created by Howie He on 2020/9/6.
//

#import <EffectPlatformSDK/IESEffectModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCForegroundRenderParams : NSObject

@property (nonatomic, assign, readonly) BOOL hasForeground;
@property (nonatomic, strong, readonly, nullable) NSString *foregroundRenderResourcePath;
@property (nonatomic, assign, readonly) CGSize foregroundRenderSize;
@property (nonatomic, assign, readonly) NSInteger foregroundRenderFPS;
@property (nonatomic, strong, nullable, readonly) NSValue *foregroundRenderViewFrame;
@property (nonatomic, assign, readonly) NSInteger foregroundRenderFitMode;

@end

@interface IESEffectModel (ACCForegroundRender)

@property (nonatomic, readonly) ACCForegroundRenderParams *acc_foregroundRenderParams;

@end

NS_ASSUME_NONNULL_END
