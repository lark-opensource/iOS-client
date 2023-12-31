//
//  UIViewController+TMATrack.h
//  Timor
//
//  Created by CsoWhy on 2018/8/31.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@protocol TMAUIViewControllerTrackProtocol <NSObject>

@optional
- (void)trackEndedByAppWillEnterBackground;
- (void)trackStartedByAppWillEnterForground;
@end

@interface UIViewController (TMATrack) <TMAUIViewControllerTrackProtocol>

@property (nonatomic, assign) IBInspectable BOOL tmaTrackStayEnable;
@property (nonatomic, assign) NSTimeInterval tmaTrackStayTime;
@property (nonatomic, assign) NSTimeInterval tmaTrackStartTime;

- (void)tma_resetStayTime;

@end
