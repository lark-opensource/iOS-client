//
//  BDASplashGestureRecognizer.h
//  ABRInterface
//
//  Created by YangFani on 2020/7/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDASplashTapGestureRecognizer : UITapGestureRecognizer

@property (nonatomic, assign, readonly) CGPoint endPoint;  ///<点击时相对于事件绑定view的坐标
@property (nonatomic, strong, readonly) UIEvent *endEvent; ///<点击时的事件

@end

@interface BDASplashPanGestureRecognizer : UIPanGestureRecognizer

@property (nonatomic, assign, readonly) CGPoint beganPoint; ///<开始滑动时相对于事件绑定view的坐标
@property (nonatomic, assign, readonly) CGPoint endPoint;  ///<滑动结束时相对于事件绑定view的坐标
@property (nonatomic, strong, readonly) UIEvent *endEvent; ///<点击时的事件

@end

NS_ASSUME_NONNULL_END
