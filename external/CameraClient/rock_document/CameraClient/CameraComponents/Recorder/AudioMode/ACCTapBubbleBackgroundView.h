//
//  ACCTapBubbleBackgroundView.h
//  CameraClient-Pods-AwemeCore
//
//  Created by liujinze on 2021/11/3.
//

#import <UIKit/UIKit.h>

@protocol ACCHideBubbleDelegate <NSObject>

- (void)bubbleBackgroundViewTap:(CGPoint)touchPoint;

@end

@interface ACCTapBubbleBackgroundView : UIView

@property (nonatomic, weak, nullable) id<ACCHideBubbleDelegate> delegate;

@end
