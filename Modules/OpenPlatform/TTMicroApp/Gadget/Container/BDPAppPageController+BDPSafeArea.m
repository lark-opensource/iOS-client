//
//  BDPAppPageController+BDPSafeArea.m
//  Timor
//
//  Created by changrong on 2020/9/2.
//

#import "BDPAppPageController+BDPSafeArea.h"
#import <TTMicroApp/TTMicroApp-Swift.h>

@interface BDPNaviBarSafeArea()
@property (nonatomic, readwrite) CGFloat left;
@property (nonatomic, readwrite) CGFloat right;
@property (nonatomic, readwrite) CGFloat top;
@property (nonatomic, readwrite) CGFloat bottom;
@property (nonatomic, readwrite) CGFloat width;
@property (nonatomic, readwrite) CGFloat height;
@end
@implementation BDPNaviBarSafeArea
@end

@implementation BDPAppPageController (BDPSafeArea)

- (BDPNaviBarSafeArea *)getNavigationBarSafeArea {
    if (![self isCustomNavigationBar]) {
        return nil;
    }
    CGRect frame = [self.view convertRect:self.toolBarView.bounds fromView:self.toolBarView];
    CGFloat navigationBarHeight = 44; // 视觉需求，导航栏保证44，不按照系统的设置。
    // 支持横竖屏时,横屏下的导航栏高度需要根据设备型号获取.
    // 否则自定义导航栏页面->系统导航栏页面.导航栏尺寸如果不同,则会前后两个页面尺寸不同.
    if ([OPGadgetRotationHelper enableGadgdetRotation:self.uniqueID]) {
        navigationBarHeight = [OPGadgetRotationHelper navigationBarHeight];
    }
    BDPNaviBarSafeArea *safeArea = [[BDPNaviBarSafeArea alloc] init];
    safeArea.left = 0;
    safeArea.right = frame.origin.x;
    safeArea.top = frame.origin.y;
    safeArea.bottom = frame.origin.y + navigationBarHeight;
    safeArea.width = frame.origin.x;
    safeArea.height = navigationBarHeight;
    return safeArea;
}

- (BOOL)isCustomNavigationBar {
    BDPWindowConfig *windowConfig = self.pageConfig.window;
    if (!windowConfig) {
        return false;
    }
    return [windowConfig.navigationStyle isEqualToString:@"custom"];
}

@end
