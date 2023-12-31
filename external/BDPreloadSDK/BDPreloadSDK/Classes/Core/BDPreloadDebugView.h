//
//  BDPreloadDebugView.h
//  BDPreloadSDK
//
//  Created by wealong on 2019/8/28.
//

#import <UIKit/UIKit.h>


@interface BDPreloadDebugView : UIView

@property (strong, nonatomic, readonly) UILabel *finishLabel;
@property (strong, nonatomic, readonly) UILabel *runningLabel;
@property (strong, nonatomic, readonly) UILabel *pendingLabel;
@property (strong, nonatomic, readonly) UILabel *waitingLabel;

+ (instancetype)sharedInstance;

@property (class, nonatomic, assign, readonly) BOOL enable;

@end
