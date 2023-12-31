//
//  UIView+ACCUIKit.h
//  ACCUIKit
//
//  Created by zhangrenfeng on 2019/9/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCViewDirection) {
    ACCViewDirectionLeft,
    ACCViewDirectionTop,
    ACCViewDirectionRight,
    ACCViewDirectionBottom
};

@interface UIView (ACCUIKit)

@property (nonatomic, assign) CGFloat acc_cornerRadius;
@property (nonatomic, strong) CAShapeLayer * _Nullable acc_innerLayer;
@property (nonatomic, readonly, assign) UIEdgeInsets acc_safeAdjustment;

- (void)acc_disableUserInteractionWithTimeInterval:(NSTimeInterval)interval;
- (void)acc_enableUserInteraction;

/* Generate a larger clickable area for small icons */
- (UIView * _Nonnull)acc_touchView;
- (UIView * _Nonnull)acc_touchViewWithSize:(CGSize)size;

- (void)acc_addRotateAnimationWithDuration:(CGFloat)duration;
- (void)acc_addRotateAnimationWithDuration:(CGFloat)duration forKey:(nullable NSString *)key;

- (void)acc_addBlurEffect;
- (void)acc_addSystemBlurEffect:(UIBlurEffectStyle)style;

- (UIImage * _Nullable)acc_snapshotImage;
- (UIImage * _Nullable)acc_snapshotImageAfterScreenUpdates:(BOOL)afterUpdate;
- (UIImage *_Nullable)acc_snapshotImageAfterScreenUpdates:(BOOL)afterUpdates withSize:(CGSize)size;

- (UIImageView * _Nullable)acc_snapshotImageView;
- (UIImageView * _Nullable)acc_snapshotImageViewAfterScreenUpdates:(BOOL)afterUpdate;

- (UIColor * _Nonnull)acc_colorOfPoint:(CGPoint)point;

- (UIImage * _Nonnull)acc_roundedImage:(UIImage * _Nonnull)image;

- (UIEdgeInsets)acc_safeAdjustment;

- (CGRect)acc_frameInView:(UIView * _Nonnull)view;

/**
 Remove all child controls
 */
- (void)acc_removeAllSubviews;

/**
 Find the controller where the current view is located

 @return the controller where the current view is located
 */
- (nullable UIViewController *)acc_viewController;

///*
// * return anchor offset from default CGPoint (0.5, 0.5)
// */
//- (CGPoint)anchorOffsetWithPositive:(BOOL)positive;

/*
 * return distance from center to border on direction
 */
- (CGFloat)acc_centerToBorderDirection:(ACCViewDirection)direction;

- (void)acc_setAnchorPointForRotateAndScale:(CGPoint)anchorPoint;

- (CGFloat)acc_maxScaleWithinRect:(CGRect)rect;

/// setup different border radius, implemented by mask layer
/// @param topLeftRadius top left radius
/// @param topRightRadius top right radius
/// @param bottomLeftRadius bottom left radius
/// @param bottomRightRadius bottom right radius
- (void)acc_setupBorderWithTopLeftRadius:(CGSize)topLeftRadius
                          topRightRadius:(CGSize)topRightRadius
                        bottomLeftRadius:(CGSize)bottomLeftRadius
                       bottomRightRadius:(CGSize)bottomRightRadius;

@end


@interface UIView (ACCLayout)

@property (nonatomic, assign) CGFloat acc_top;

@property (nonatomic, assign) CGFloat acc_bottom;

@property (nonatomic, assign) CGFloat acc_left;

@property (nonatomic, assign) CGFloat acc_right;

@property (nonatomic, assign) CGFloat acc_width;

@property (nonatomic, assign) CGFloat acc_height;

@property (nonatomic, assign) CGFloat acc_centerX;

@property (nonatomic, assign) CGFloat acc_centerY;

@property (nonatomic, assign) CGSize acc_size;

@property (nonatomic, assign) CGPoint acc_origin;

@end


@interface UIView (ACCHierarchy)

- (id)acc_nearestAncestorOfClass:(Class)clazz;

@end


@interface UIView (ACCAddGestureRecognizer)

- (UITapGestureRecognizer *)acc_addDoubleTapRecognizerWithTarget:(id)target action:(SEL)sel;
- (UITapGestureRecognizer *)acc_addSingleTapRecognizerWithTarget:(id)target action:(SEL)sel;

@end


@interface UIView (ACCViewImageMirror)

- (UIImage * _Nullable)acc_imageWithView;
- (UIImage * _Nullable)acc_imageWithViewOnScreenScale;
- (UIImage * _Nullable)acc_imageWithViewOnScale:(CGFloat)scale;

@end


@interface UIView (acc_FadeShowAndHidden)

- (void)acc_fadeShow;

- (void)acc_fadeHidden;

- (void)acc_fadeShowWithDuration:(NSTimeInterval)duration;

- (void)acc_fadeHiddenDuration:(NSTimeInterval)duration;

- (void)acc_fadeShowWithCompletion:(nullable void(^)(void))completion;

- (void)acc_fadeHiddenWithCompletion:(nullable void(^)(void))completion;

- (void)acc_fadeShow:(BOOL)show duration:(NSTimeInterval)duration;

@end


UIKIT_EXTERN CGFloat const ACCEdgeFadeValue;

typedef NS_ENUM(NSInteger, ACCEdgeFadeDirection) {
    ACCEdgeFadeDirectionHorizontal,   // Default
    ACCEdgeFadeDirectionVertical
};


/**
 Set the view's edge fade to one line, which will automatically adapt to the view's bounds
 will automatically adapt to the edge fading effect based on changes to the view's bounds
 
 Alternatively, if the original view uses a mask, it cannot be used directly, so you can wrap the view yourself.
 */
@interface UIView (ACCEdgeFading)

/**
 Edge fade, default edge value is ACCViewFadeValue, horizontal
 */
- (void)acc_edgeFading;

/**
 Edge fade, default is horizontal
 
 @param value edge fade length
 */
- (void)acc_edgeFadingWithValue:(CGFloat)value;

/**
add horizontal two-end fading mask
@param ratio  ratio = fading band / view width,  0 ~ 0.5
*/
- (void)acc_edgeFadingWithRatio:(CGFloat)ratio;

/**
 Edge fade, default edge value is ACCViewFadeValue
 
 @param direction The direction of the edge fade.
 */
- (void)acc_edgeFadingWithDirection:(ACCEdgeFadeDirection)direction;

/**
 Edge Fade
 
 @param value the length of the edge fade
 @param direction The direction of the edge fade.
 */
- (void)acc_edgeFadingWithValue:(CGFloat)value direction:(ACCEdgeFadeDirection)direction;

@end


@interface UIView (ACCVisible)

- (BOOL)acc_isDisplayedOnScreen;

@end



@interface ACCEdgeFadeView : UIView<CALayerDelegate>

@property (nonatomic, strong, readonly) CAGradientLayer *fadeLayer;
@property (nonatomic, assign) ACCEdgeFadeDirection direction;
@property (nonatomic, assign) CGFloat value;
@property (nonatomic, assign) CGFloat fadeRatio;

- (void)refresh;

@end



NS_ASSUME_NONNULL_END
