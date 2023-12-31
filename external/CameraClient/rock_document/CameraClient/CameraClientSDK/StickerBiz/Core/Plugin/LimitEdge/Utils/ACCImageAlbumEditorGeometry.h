//
//  ACCImageAlbumEditorGeometry.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/1/25.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

/// 图片高宽比是否是16:9
FOUNDATION_EXPORT BOOL ACCImageEditRatioIs16To9(CGSize size);

/// Width  边长的意思width / height 不单指宽
FOUNDATION_EXTERN BOOL ACCImageEditWidthIsValid(CGFloat width);

FOUNDATION_EXTERN BOOL ACCImageEditSizeIsValid(CGSize size);

/// 获取图片在父容器最终按照width to fit展示的最合适的content model
FOUNDATION_EXTERN UIViewContentMode ACCImageEditGetWidthFitImageDisplayContentMode(CGSize imageSize, CGSize contentSize);

/// 获取图片在父容器最终按照width to fit展示的最合适的size
FOUNDATION_EXTERN CGSize  ACCImageEditGetWidthFitImageDisplaySize(CGSize imageSize, CGSize contentSize, BOOL needClipHeight);

/// 获取图片在父容器最终按照height to fit展示的最合适的size
FOUNDATION_EXTERN CGSize  ACCImageEditGetHeightFitImageDisplaySize(CGSize imageSize, CGSize contentSize, BOOL needClipWidth);

/// 类似于AVMakeRectWithAspectRatioInsideRect，获取一个能包住aspectRatio区域的最小rect
FOUNDATION_EXTERN CGRect ACCImageEditorMakeRectWithAspectRatioOutsideRect(CGSize aspectRatio, CGRect boundingRect);

/**
 * 根据图片比例设定展示尺寸
 * 高宽比=16:9，高度撑满，左右裁切
 * 高宽比>16:9，宽度撑满，上下裁切
 * 高宽比<16:9，宽度撑满，上下留黑
 */
FOUNDATION_EXPORT CGRect ACCImageEditorMakeRectWithAspectRatio16To9(CGSize containerSize, CGSize imageSize);


/// 转换视频中心绝对坐标到图集的坐标系（图集为左上相对归一坐标系）
/// @param videoOffset 视频坐标
/// @param imageLayerSize 图片layer的大小，无需裁剪
FOUNDATION_EXPORT CGPoint ACCImageEditorCovertVideoCenterAbsoluteOffsetToImageOffset(CGPoint videoOffset, CGSize imageLayerSize);


@interface ACCImageAlbumEditorGeometry : NSObject

@end

NS_ASSUME_NONNULL_END
