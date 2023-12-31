//
//  UIView+WaterMark.h
//  WaterMark
//
//  Created by qihao on 2019/4/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface UIView (WaterMark)
@end

@interface UIWindow (DidAddSubview)
@end

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0
@interface UIViewController (Present)

@end
#endif

NS_ASSUME_NONNULL_END
