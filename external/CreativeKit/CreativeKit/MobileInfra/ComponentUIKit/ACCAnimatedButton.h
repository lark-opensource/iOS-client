//
//  ACCAnimatedButton.h
//  Aweme
//
//  Created by xiangwu on 2017/6/8.
//  Copyright  ©  Byedance. All rights reserved, 2017
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ACCAnimatedButtonType) {
    ACCAnimatedButtonTypeScale,        // Zoom in and out animation
    ACCAnimatedButtonTypeAlpha,        // Transparency animation
};

@interface ACCAnimatedButton : UIButton

@property (nonatomic, assign) NSTimeInterval animationDuration;
@property (nonatomic, assign) CGFloat highlightedScale;
@property (nonatomic, strong) NSURL *audioURL;
@property (nonatomic, assign) BOOL downgrade; // Downgrade to UIButton;
/**
 Generate an instance of ACCAnimatedButton based on the frame passed in and the type of animation required when the button is pressed

 @param frame frame
 @param btnType The animation type of the button, as ACCAnimatedButtonType
 @return the ACCAnimatedButton instance of the corresponding type
 */
- (instancetype)initWithFrame:(CGRect)frame type:(ACCAnimatedButtonType)btnType;

/**
 Generate an instance of ACCAnimatedButton based on the type of animation that needs to be done when the button is pressed

 @param btnType The animation type of the button, as ACCAnimatedButtonType
 @return the ACCAnimatedButton instance of the corresponding type
 */
- (instancetype)initWithType:(ACCAnimatedButtonType)btnType;


/**
 Generate an ACCAnimatedButton instance of type ACCAnimatedButtonTypeScale
 @param frame frame
 @return ACCAnimatedButton instance of type ACCAnimatedButtonTypeScale
 */
- (instancetype)initWithFrame:(CGRect)frame;

@end
