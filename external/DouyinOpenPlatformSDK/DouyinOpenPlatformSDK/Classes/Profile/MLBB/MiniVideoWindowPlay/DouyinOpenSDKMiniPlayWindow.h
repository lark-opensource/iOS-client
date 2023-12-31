//
//  DouyinOpenSDKMiniPlayWindow.h
//  DouyinOpenPlatformSDK
//
//  Created by AnchorCat on 2022/4/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DouyinOpenSDKWindowEventDelegate;

@interface DouyinOpenSDKMiniPlayWindow : UIWindow

@property (nonatomic, weak) id <DouyinOpenSDKWindowEventDelegate> eventDelegate;

@end

@protocol DouyinOpenSDKWindowEventDelegate <NSObject>

- (BOOL)shouldHandleTouchAtPoint:(CGPoint)pointInWindow;

@end

NS_ASSUME_NONNULL_END
