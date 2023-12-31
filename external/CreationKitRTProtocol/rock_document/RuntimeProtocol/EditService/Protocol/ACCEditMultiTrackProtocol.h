//
//  ACCEditMultiTrackProtocol.h
//  CreationKitRTProtocol-Pods-Aweme
//
//  Created by 饶骏华 on 2021/9/18.
//

#import <Foundation/Foundation.h>
#import "ACCEditWrapper.h"

@protocol ACCEditMultiTrackProtocol <ACCEditWrapper>

- (void)setupMultiTrackCanvas;

- (CGSize)sizeWithAsset:(AVAsset *)asset;
- (CMTime)mainTrackDuration; // 主轨道所有片段总时长
- (CMTime)subTrackDuration; // 副轨道所有片段总时长

- (void)updateMainTrackWithTransformX:(float)transformX transformY:(float)transformY scale:(float)scale;
- (void)updateSubTrackWithTransformX:(float)transformX transformY:(float)transformY scale:(float)scale;

- (void)updateMainTrackWithClipTimeEnd:(CMTime)timeClipEnd; // 更新主轨道首个片段时长
- (void)updateSubTrackWithClipTimeEnd:(CMTime)timeClipEnd;  // 更新副轨道首个片段时长

- (void)updateMainTrackWithCropLeftTopPoint:(CGPoint)leftTopPoint rightBottomPoint:(CGPoint)rightBottomPoint; // 更新主轨道片段裁减
- (void)updateSubTrackWithCropLeftTopPoint:(CGPoint)leftTopPoint rightBottomPoint:(CGPoint)rightBottomPoint; // 更新副轨道片段裁减

- (void)updateMainTrackCanvasStyleWithBorderWidth:(NSInteger)borderWidth borderColor:(UIColor *)borderColor; // 更新主轨道片段边框
- (void)updateSubTrackCanvasStyleWithBorderWidth:(NSInteger)borderWidth borderColor:(UIColor *)borderColor; // 更新副轨道片段边框

@end
