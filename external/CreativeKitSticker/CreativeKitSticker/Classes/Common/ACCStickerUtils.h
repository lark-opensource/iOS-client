//
//  ACCStickerUtils.h
//  CameraClient
//
//  Created by Yangguocheng on 2020/7/17.
//

#import <Foundation/Foundation.h>

#import "ACCStickerGeometryModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCStickerUtils : NSObject

+ (BOOL)isValidRect:(CGRect)rect;

+ (void)applyScale:(CGFloat)scale toLayer:(CALayer *)layer;

+ (CGPoint)anchorDiffWithCenterOfView:(UIView *)view;

/// given a frame, return a geometry model, which is used to set the sticker's position according to the playerFrame
/// @param viewFrame sticker view's frame, based on sticker container view's coordinator system
/// @param containerFrame sticker container view's frame, frame's origin does NOT matter
/// @param playerFrame video player's frame
+ (ACCStickerGeometryModel *)convertStickerViewFrame:(CGRect)viewFrame
                       fromContainerCoordinateSystem:(CGRect)containerFrame
                            toPlayerCoordinateSystem:(CGRect)playerFrame;

@end

NS_ASSUME_NONNULL_END
