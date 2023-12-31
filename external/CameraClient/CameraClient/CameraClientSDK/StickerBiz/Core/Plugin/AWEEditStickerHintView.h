//
//  AWEEditStickerHintView.h
//  Pods
//
//  Created by 赖霄冰 on 2019/9/4.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const AWEEditStickerHintViewResignActiveNotification;

typedef NS_ENUM(NSUInteger, AWEEditStickerHintType) {
    AWEEditStickerHintTypeInfo,
    AWEEditStickerHintTypeInteractive,
    AWEEditStickerHintTypeText,
    AWEEditStickerHintTypeTextReading,
    AWEEditStickerHintTypeInteractiveMultiPOI,// multi poi style hint
};


@interface AWEEditStickerHintView : UIView

- (instancetype)initWithGradientAndFrame:(CGRect)frame;
- (void)showHint:(NSString *)hint type:(AWEEditStickerHintType)type;
- (void)showHint:(NSString *)hint;
- (void)showHint:(NSString *)hint
        animated:(BOOL)animated
     autoDismiss:(BOOL)autoDismiss;
- (void)dismissWithAnimation:(BOOL)animated;
+ (BOOL)isNeedShowHintViewForType:(AWEEditStickerHintType)type;
+ (void)setNoNeedShowForType:(AWEEditStickerHintType)type;

@end

NS_ASSUME_NONNULL_END
