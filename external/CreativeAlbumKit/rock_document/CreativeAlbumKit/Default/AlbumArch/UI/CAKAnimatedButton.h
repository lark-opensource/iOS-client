//
//  CAKAnimatedButton.h
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/6.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, CAKAnimatedButtonType) {
    CAKAnimatedButtonTypeScale,        // 放大缩小动画
    CAKAnimatedButtonTypeAlpha,        // 透明度动画
};

@interface CAKAnimatedButton : UIButton

@property (nonatomic, assign) NSTimeInterval animationDuration;
@property (nonatomic, assign) CGFloat highlightedScale;
@property (nonatomic, strong, nullable) NSURL *audioURL;
@property (nonatomic, assign) BOOL downgrade; // Downgrade to UIButton;
/**
 根据传入的 frame 与 按钮按下时需要做的动画类型生成 ACCAnimatedButton 的实例

 @param frame frame
 @param btnType 按钮的动画类型，为 ACCAnimatedButtonType
 @return 对应类型的 ACCAnimatedButton 实例
 */
- (instancetype _Nonnull)initWithFrame:(CGRect)frame type:(CAKAnimatedButtonType)btnType;

/**
 根据传入的按钮按下时需要做的动画类型生成 ACCAnimatedButton 的实例

 @param btnType 按钮的动画类型，为 ACCAnimatedButtonType
 @return 对应类型的ACCAnimatedButton 实例
 */
- (instancetype _Nonnull)initWithType:(CAKAnimatedButtonType)btnType;


/**
 生成 ACCAnimatedButtonTypeScale 类型的 ACCAnimatedButton 实例

 @param frame frame
 @return ACCAnimatedButtonTypeScale 类型的 ACCAnimatedButton 实例
 */
- (instancetype _Nonnull)initWithFrame:(CGRect)frame;

@end
