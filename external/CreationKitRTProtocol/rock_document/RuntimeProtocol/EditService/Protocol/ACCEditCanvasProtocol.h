//
//  ACCEditCanvasProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by hongcheng on 2020/12/29.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCEditWrapper.h>

@class IESMMCanvasSource, AVAsset, ACCRepoVideoInfoModel;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditCanvasProtocol <ACCEditWrapper>

- (void)setUpCanvas;

- (void)updateCanvasContent;

- (void)updateWithVideoInfo:(ACCRepoVideoInfoModel *)videoInfo source:(IESMMCanvasSource *)source;

- (void)updateWithVideoInfo:(ACCRepoVideoInfoModel *)videoInfo duration:(double)duration completion:(void (^)(NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
