//
//  UIView+DVE.h
//  DVEFoundationKit
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (DVE)

@property (nonatomic, assign) CGFloat dve_left;        ///< Shortcut for frame.origin.x.
@property (nonatomic, assign) CGFloat dve_top;         ///< Shortcut for frame.origin.y
@property (nonatomic, assign) CGFloat dve_right;       ///< Shortcut for frame.origin.x + frame.size.width
@property (nonatomic, assign) CGFloat dve_bottom;      ///< Shortcut for frame.origin.y + frame.size.height
@property (nonatomic, assign) CGFloat dve_width;       ///< Shortcut for frame.size.width.
@property (nonatomic, assign) CGFloat dve_height;      ///< Shortcut for frame.size.height.
@property (nonatomic, assign) CGFloat dve_centerX;     ///< Shortcut for center.x
@property (nonatomic, assign) CGFloat dve_centerY;     ///< Shortcut for center.y
@property (nonatomic, assign) CGPoint dve_origin;      ///< Shortcut for frame.origin.
@property (nonatomic, assign) CGSize  dve_size;        ///< Shortcut for frame.size.

+ (UIViewController *)dve_currentViewController;

+ (UIViewController *)dve_currentRootController;

+ (UIWindow *)dve_currentWindow;

- (UIViewController *)dve_firstAvailableUIViewController;

@end

NS_ASSUME_NONNULL_END
