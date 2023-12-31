//
//  AWERepoFilterModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/24.
//

#import <CreationKitArch/ACCRepoFilterModel.h>
#import <EffectPlatformSDK/IESEffectModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWERepoFilterModel : ACCRepoFilterModel<ACCRepositoryContextProtocol>

@property (nonatomic, assign) BOOL capturedWithLightningFilter;
@property (nonatomic, assign) BOOL editedWithLightningFilter;
@property (nonatomic, assign) BOOL hasDeselectionBeenMadeRecently;

//  @description: 获取当前使用拍摄页+编辑页滤镜的上报信息
- (NSDictionary *)filterInfoDictionary;

@end

@interface AWEVideoPublishViewModel (AWERepoFilter)
 
@property (nonatomic, strong, readonly) AWERepoFilterModel *repoFilter;
 
@end


NS_ASSUME_NONNULL_END
