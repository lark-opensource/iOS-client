//
//  BDPAppPageAnimatedTransitioning.m
//  Timor
//
//  Created by MacPu on 2019/6/21.
//

#import "BDPAppPageAnimatedTransitioning.h"
#import <OPFoundation/BDPUtils.h>
#import "BDPAppPageController.h"
#import "BDPToolBarView.h"
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import "BDPAppPage+BDPNavBarAutoChange.h"
#import <OPFoundation/EEFeatureGating.h>
#import "BDPXScreenManager.h"

typedef void(^ClearAnimation)(BOOL cancel);

@interface BDPAppPageAnimatedTransitioning()

@property (nonatomic, weak) ClearAnimation clearAnimation;
@end

@implementation BDPAppPageAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.28f;
}
// ⚠️ 这个方法内部存在大问题，错误的使用fromView与fromVC.view等概念，在计算布局以及addSubview/removeSubview将存在隐患
- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIView *containerView = [transitionContext containerView];
    
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    BDPAppPageController *fromVC = (BDPAppPageController*)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    BDPAppPageController *toVC = (BDPAppPageController*)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UINavigationBar *navigationBar = fromVC.navigationController.navigationBar;
    
    // 判断半屏模式
    BOOL isXScreenMode = NO;
    CGFloat XScreenRate = -1.f;
    // 再次增加保护，方式后续改动影响
    if ([fromVC isKindOfClass:[BDPAppPageController class]]) {
        isXScreenMode = [BDPXScreenManager isXScreenMode:fromVC.uniqueID];
        XScreenRate = [BDPXScreenManager XScreenPresentationRate:fromVC.uniqueID];
    }
    
    // 胶囊按钮动画， 希望胶囊按钮能随着手势一起做动画。并且在没有改变style的时候， 胶囊按钮不做任何变化。
    // 胶囊按钮这部分的动画特别的复杂， 有导航栏和没有导航栏的时候
    BDPToolBarView *fromToolBarView = [self toolBarViewFromVC:fromVC]; // 当FromVC没有导航栏的时候有为空
    BDPToolBarView *toToolBarView = [self toolBarViewFromVC:toVC]; // 当ToVC没有导航栏的时候为空
    
    // 当有一个有导航栏有一个没有的时候，导航栏也需要做动画。
    UIView *naviContainerView = [[UIView alloc] initWithFrame:containerView.frame];
    UIView *naviSuperView = navigationBar.superview;
    UIView *contentView = nil; // 用于记录 fromView 和 toView，动画结束是还原。
    
    // 用于特殊处理半屏的动画
    UIView *XScreenNaviContainerView = [[UIView alloc] initWithFrame:containerView.frame];
    UIView *XScreenPopContentView = nil;
    
    // 如果有一个导航栏是custom的，有一个default的。
    // 这里有一个坑，在ios 11 的时候。这种情况下，rightBarButton布局不对，所以copy一份来做动画，
    BDPToolBarView *copyToolBar = nil;
    BDPToolBarView *originToolBar = nil;
    if (!!fromToolBarView != !!toToolBarView) {
        if (fromToolBarView) {
            // 进入此逻辑，说明由普通导航栏 push 自定义导航栏的页面
            if (fromVC.pageConfig.window.navigationBarBgTransparent) {
                fromView.bdp_top = containerView.bdp_top;
                fromView.bdp_height = containerView.bdp_height;
            } else {
                fromView.bdp_top = navigationBar.bdp_bottom;
                fromView.bdp_height = containerView.bdp_height - navigationBar.bdp_bottom;
                if([EEFeatureGating boolValueForKey:EEFeatureGatingKeyFixNavigationPushPosition] && navigationBar.bdp_top < 0) {
                    /**
                     * 开启 openplatform.gadget.disable_set_theme_color_ininit 后会出现动画前，导航栏被移到页面上方，动画开始后容器 view 会向上跳动
                     * 此时 navigationBar.bdp_top = -44, 具体原因无法确认，和 setNavigationBar hidden、needLayoutSubviews 等相关
                     * 进入这段逻辑，说明 fromView 有导航栏并且应该显示在页面上，若导航栏的 frame.origin.y < 0(导航栏跑到页面上方)，直接设置回正常值
                     * Oncall 记录：
                     * https://lark-oncall.bytedance.net/tickets/ticket_16723109278630787
                     * https://applink.feishu.cn/client/chat/open?openChatId=oc_2323649ce77267e5e502d7d304b4a218
                     */
                    navigationBar.bdp_top = containerView.safeAreaInsets.top;
                    fromView.bdp_top = navigationBar.bdp_bottom;
                    fromView.bdp_height = containerView.bdp_height - navigationBar.bdp_bottom;
                }
            }
            toView.frame = toVC.navigationController.view.frame;
            [naviContainerView addSubview:fromView];
            contentView = fromView;
            fromView = naviContainerView;

            copyToolBar = [self copyToolBar:fromToolBarView];
            originToolBar = fromToolBarView;
            fromToolBarView = copyToolBar;
        } else {
            if (toVC.pageConfig.window.navigationBarBgTransparent) {
                toView.bdp_top = containerView.bdp_top;
                toView.bdp_height = containerView.bdp_height;
            } else {
                toView.bdp_top = navigationBar.bdp_bottom;
                toView.bdp_height = containerView.bdp_height - navigationBar.bdp_bottom;
            }
            fromView.frame = fromVC.navigationController.view.frame;
            [naviContainerView addSubview:toView];
            contentView = toView;
            toView = naviContainerView;
            
            // 这里非常关键，不要觉得是无意义代码，在半屏下，pop时系统对于与屏幕尺寸不一致的view的动画处理存在异常，所以用一个同尺寸的view包一下fromView
            if (isXScreenMode && self.operation == UINavigationControllerOperationPop) {
                XScreenPopContentView = fromView;
                [XScreenNaviContainerView addSubview:fromView];
                fromView = XScreenNaviContainerView;
            }
            
            copyToolBar = [self copyToolBar:toToolBarView];
            originToolBar = toToolBarView;
            toToolBarView = copyToolBar;
        }
        originToolBar.hidden = YES;
        //半屏模式下，当page的导航栏从无到有/从有到无的情况下会出现白屏闪过，不能通过修改frame缩小承载的view的大小，会透出一些奇怪的专场view，这里做透明处理，因为是临时创建的view，所以在切换半屏/全屏下不会有影响
        if (isXScreenMode) {
            naviContainerView.backgroundColor = [UIColor clearColor];
        } else {
            naviContainerView.backgroundColor = navigationBar.barTintColor;
        }
        // 导航栏应该最后添加，不能被其他view遮住
        [naviContainerView addSubview:navigationBar];
        navigationBar.alpha = 1;
    } else {
        // 这里非常关键，pop时系统对于与屏幕尺寸不一致的view的动画处理存在异常，所以用一个同尺寸的view包一下fromView
        if (isXScreenMode && self.operation == UINavigationControllerOperationPop) {
            XScreenPopContentView = fromView;
            [XScreenNaviContainerView addSubview:fromView];
            fromView = XScreenNaviContainerView;
        }
    }
    
    // 如果fromVC的导航栏是custom的
    UIView *toolBarContainer = navigationBar;
    UIView *fromToolBarSuperView;
    UIView *toToolBarSuperView;
    if (!fromToolBarView) {
        fromToolBarView = fromVC.toolBarView;
//        fromView.frame = toView.frame;
        toolBarContainer = containerView;
        fromToolBarSuperView = fromToolBarView.superview;
    }
    // 如果 toVC的导航栏是custom的
    if (!toToolBarView) {
        toToolBarView = toVC.toolBarView;
//        toView.frame = fromView.frame;
        toolBarContainer = containerView;
        toToolBarSuperView = toToolBarView.superview;
    }
    
// test code
//    fromToolBarView.backgroundColor = [UIColor redColor];
//    toToolBarView.backgroundColor = [UIColor yellowColor];
//    copyToolBar.backgroundColor = [UIColor blueColor];
    
    // 记录一下toolBar 原始的状态，用于动画结束时的还原。
    CGPoint fromToolBarOrigin = fromToolBarView.bdp_origin;
    CGPoint toToolBarOrigin = toToolBarView.bdp_origin;
    
    BOOL toolBarNeedAnimation = fromToolBarView.toolBarStyle != toToolBarView.toolBarStyle; // 胶囊按钮是否需要做动画。
    
    // tabbar 动画， 模拟系统的动画效果。
    UITabBar *tabBar = fromVC.tabBarController.tabBar;
    UIView *tabbarSuperView = tabBar.superview;
    
    // 显示 阴影的view， 模拟系统转场是有的阴影效果
    UIView *shadowView = [[UIView alloc] initWithFrame:containerView.bounds];
    
    // 在半屏模式下需要调整shadow的高度,否则会在过场中显示出浅白色的阴影;曾经尝试将shadowView背景色改成透明，这样会产生半透效果，请勿更改;
    if (isXScreenMode) {
        shadowView.frame = CGRectMake(0, shadowView.bdp_height * (1 - XScreenRate), shadowView.bdp_width, shadowView.bdp_height * XScreenRate);
        shadowView.backgroundColor = [UIColor clearColor];
    } else {
        shadowView.backgroundColor = [UIColor whiteColor];
    }
    shadowView.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    shadowView.layer.shadowOffset = CGSizeZero;
    shadowView.layer.shadowRadius = 3;
    shadowView.layer.shadowOpacity = 0.8;
    
    // 背景变暗的 view， 模拟系统转场动画的 背景变暗效果
    UIView *opacityView = [[UIView alloc] initWithFrame:containerView.bounds];
    // 在半屏模式下需要调整opacityView的高度,否则会在过场中显示渐变的阴影，并在动画结束后出现阶跃的闪动
    if (isXScreenMode) {
        opacityView.frame = CGRectMake(0, opacityView.bdp_height * (1 - XScreenRate), opacityView.bdp_width, opacityView.bdp_height * XScreenRate);
    }
    opacityView.backgroundColor = [UIColor darkGrayColor];
    
    // 动画结束是做的一些清理 以及还原， 通用部分。
    void(^clearAnimation)(BOOL cancel) = ^(BOOL cancel){
        // 恢复 toolBar 的a样式
        toToolBarView.alpha = 1.0f;
        fromToolBarView.alpha = 1.0f;
        navigationBar.alpha = 1.0f;
        toToolBarView.bdp_origin = toToolBarOrigin;
        fromToolBarView.bdp_origin = fromToolBarOrigin;
        toToolBarView.hidden = NO;
        originToolBar.hidden = NO;
        
        // 下面两个view的顺序不要调整，目前存在2种情况，1.XScreenPopContentView contentView都存在，contentView为toView，XScreenPopContentView为fromView，所以先加fromView再加toView 2.只存在XScreenPopContentView,那么谁先谁后都只加一个view
        if (XScreenPopContentView) {
            [containerView addSubview:XScreenPopContentView];
        }
        
        if (contentView) {
            [containerView addSubview:contentView];
        }
        
        [naviSuperView addSubview:navigationBar];
        [tabbarSuperView addSubview:tabBar];
        [toToolBarSuperView addSubview:toToolBarView];
        [fromToolBarSuperView addSubview:fromToolBarView];
        
        if (cancel) {
            // custom 的不应该从原来的superView上移除掉，否则下一次没有动画的情况下，navi就没了
            if (!toToolBarSuperView) {
                [toToolBarView removeFromSuperview];
            }
            [fromVC.navigationController.navigationBar setNeedsLayout];
        } else {
            // custom 的不应该从原来的superView上移除掉，否则下一次没有动画的情况下，navi就没了
            if (!fromToolBarSuperView) {
                [fromToolBarView removeFromSuperview];
            }
        }
        [copyToolBar removeFromSuperview];
        [opacityView removeFromSuperview];
        [shadowView removeFromSuperview];
        [naviContainerView removeFromSuperview];
        
        [transitionContext completeTransition:!cancel];
        
        if (toVC.tabBarController) {
            UIView *view = [[((UITabBarController *)toVC.tabBarController).view subviews] objectAtIndex:0];
            view.bdp_size = view.superview.bdp_size;
        }
    };
    
    // 初始化动画，这里是不管pop 还是 push都有的通用初始化
    [containerView addSubview:self.operation == UINavigationControllerOperationPop ? toView : fromView];
    [containerView addSubview:tabBar];
    [containerView addSubview:opacityView];
    [containerView addSubview:shadowView];
    [containerView addSubview:self.operation == UINavigationControllerOperationPop ? fromView : toView];
    
    // 在这里转换才是正确的位置，因为这时候才把fromVC/toVC加入到containerView中
    CGPoint point = [fromToolBarView.superview convertPoint:fromToolBarView.bdp_origin toView:toolBarContainer];
    fromToolBarView.bdp_origin = point;
    toToolBarView.bdp_origin = point;
    // 切记一个View不能同时加入到两个Superview上，否则会引发奇怪的问题，fromToolBarView是copy出来的，copy方法将其挂在被copy的view的父视图上，在这里remove掉
    [fromToolBarView removeFromSuperview];

    [toolBarContainer addSubview:fromToolBarView];
    [toolBarContainer addSubview:toToolBarView];
    if (toolBarNeedAnimation) {
        toToolBarView.alpha = 0.0f;
        fromToolBarView.alpha = 1.0f;
        toToolBarView.hidden = YES;
    } else {
        // 如果不做动画的时候，需要把其中一个隐藏，不然两个重叠会导致在动画过程中透明度不对的问题。
        toToolBarView.hidden = YES;
    }
    
    if (self.operation == UINavigationControllerOperationPop) {  // pop animation
        // init pop animation
        opacityView.alpha = 0.2f;
        shadowView.alpha = 0.8f;
        toView.bdp_left = 0;
        if ([BDPDeviceHelper OSVersionNumber] < 13.f) {
            toView.bdp_left = -1* containerView.bdp_width / 3.0;
        }
        tabBar.bdp_left = toView.bdp_left;
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            toView.bdp_left = 0.f;
            tabBar.bdp_left = 0.f;
            fromView.bdp_left = containerView.bdp_width;
            shadowView.bdp_left = fromView.bdp_left;
            opacityView.alpha = 0.0f;
            shadowView.alpha = 0.0f;
            if (toolBarNeedAnimation) {
                toToolBarView.alpha = 1.0f;
                fromToolBarView.alpha = 0.0f;
            }
        } completion:^(BOOL finished) {
            if (clearAnimation) {
                BOOL cancelled = [transitionContext transitionWasCancelled];
                clearAnimation(cancelled);
            }
        }];
        
    } else if (self.operation == UINavigationControllerOperationPush) { // push animation
        // init push animation
        toView.bdp_left = containerView.bdp_width;
        shadowView.bdp_left = toView.bdp_width;
        opacityView.alpha = 0.f;
        shadowView.alpha = 0.f;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            shadowView.bdp_left = 0.f;
            toView.bdp_left = 0.f;
            
            if (isXScreenMode) {
                // 由于半屏下的厚层背景透明，所以需要将初始值设置到0，否则会出现背景空洞(屏幕左侧空白)
                fromView.bdp_left = 0;
            } else {
                fromView.bdp_left = -1 * containerView.bdp_width / 3.0;
            }
            tabBar.bdp_left = containerView.bdp_width / 3.0 *2;
            
            opacityView.alpha = 0.2f;
            shadowView.alpha = 0.8f;
            if (toolBarNeedAnimation) {
                toToolBarView.alpha = 1.0f;
                fromToolBarView.alpha = 0.0f;
            }
        } completion:^(BOOL finished) {
            if (clearAnimation) {
                BOOL cancelled = [transitionContext transitionWasCancelled];
                clearAnimation(cancelled);
            }
        }];
    } else {
        [transitionContext completeTransition:YES];
    }
}

- (BDPToolBarView *)toolBarViewFromVC:(UIViewController *)vc
{
    UIBarButtonItem *toolBar = vc.navigationItem.rightBarButtonItem;
    if ([toolBar.customView isKindOfClass:[BDPToolBarView class]]) {
        return toolBar.customView;
    } else {
        for (UIBarButtonItem *item in vc.navigationItem.rightBarButtonItems) {
            if ([item.customView isKindOfClass:[BDPToolBarView class]]) {
                return item.customView;
            }
        }
    }
    return nil;
}

- (UILabel *)copyLabel:(UILabel *)label
{
    UILabel *copyLabel = [[UILabel alloc] initWithFrame:label.frame];
    copyLabel.text = label.text;
    copyLabel.font = label.font;
    copyLabel.textColor = label.textColor;
    
    return copyLabel;
}

- (BDPToolBarView *)copyToolBar:(BDPToolBarView *)toolbar
{
    BDPToolBarView *copyToolBar = [[BDPToolBarView alloc] initWithUniqueID:toolbar.uniqueID];
    copyToolBar.moreButtonBadgeNum = toolbar.moreButtonBadgeNum;
    copyToolBar.h5Style = toolbar.h5Style;
    copyToolBar.toolBarStyle = toolbar.toolBarStyle;
    copyToolBar.frame = toolbar.frame;
    [toolbar.superview addSubview:copyToolBar];
    
    return copyToolBar;
}

@end
