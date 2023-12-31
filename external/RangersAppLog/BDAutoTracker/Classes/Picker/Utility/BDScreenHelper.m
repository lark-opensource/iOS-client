//
//  BDScreenHelper.m
//  Applog
//
//  Created by bob on 2019/2/13.
//

#import "BDScreenHelper.h"
#import "BDKeyWindowTracker.h"

static CGFloat bd_picker_statusBarHeight() {
    if ([UIApplication sharedApplication].statusBarHidden) return 0;

    CGSize size =  [UIApplication sharedApplication].statusBarFrame.size;

    return MIN(size.width, size.height);
}

CGFloat bd_picker_safeAreaInsetsTop() {
    CGFloat top = 0;
    if (@available(iOS 11.0, *))  {
        UIWindow *keyWindow = [BDKeyWindowTracker sharedInstance].keyWindow;
        top = keyWindow.safeAreaInsets.top;
    } else {
        top = bd_picker_statusBarHeight();
    }

    return top;
}

CGFloat bd_picker_safeAreaInsetsBottom() {
    CGFloat bottom = 0;
    if (@available(iOS 11.0, *))  {
        UIWindow *keyWindow = [BDKeyWindowTracker sharedInstance].keyWindow;
        bottom = keyWindow.safeAreaInsets.bottom;
    }

    return bottom;
}

CGSize bd_picker_screenSize() {
    return [UIScreen mainScreen].bounds.size;
}

UIImage * bd_picker_imageForView(UIView *view) {
    return bd_picker_imageForViewWithScale(view, [UIScreen mainScreen].scale);
}

UIImage * bd_picker_imageForViewWithScale(UIView *view, CGFloat scale) {
    UIGraphicsBeginImageContextWithOptions(view.frame.size, false, scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

UIImage * bd_picker_combineImage(UIImage *first, UIImage *second) {
    CGRect rect = [UIScreen mainScreen].bounds;
    UIGraphicsBeginImageContextWithOptions(rect.size, false, [UIScreen mainScreen].scale);
    [second drawInRect:rect];
    [first drawInRect:rect];

    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}
