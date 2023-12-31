//
//  UIView+ACCStickerSDKUtils.h
//  ACCStickerSDK-Pods-Aweme
//
//  Created by Pinka on 2020/11/13.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (ACCStickerSDKUtils)

- (UIImage * _Nullable)accs_imageWithViewOnScreenScale;

- (void)accs_setAnchorPointForRotateAndScale:(CGPoint)anchorPoint;

@end

NS_ASSUME_NONNULL_END
