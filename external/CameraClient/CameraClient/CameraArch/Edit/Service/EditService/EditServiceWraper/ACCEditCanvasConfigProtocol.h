//
//  ACCEditCanvasConfigProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/5/10.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <TTVideoEditor/IESMMCanvasSource.h>
#import <TTVideoEditor/IESMMCanvasConfig.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditCanvasConfigProtocol <NSObject>

- (IESMMCanvasConfig *)configWithPublishModel:(AWEVideoPublishViewModel *)publishModel;
- (IESMMCanvasSource *)sourceWithPublishModel:(AWEVideoPublishViewModel *)publishModel mediaContainerView:(nullable UIView *)mediaContainerView;

@end

NS_ASSUME_NONNULL_END
