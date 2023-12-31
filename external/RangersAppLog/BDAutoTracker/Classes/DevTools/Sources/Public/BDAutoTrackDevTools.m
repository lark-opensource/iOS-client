//
//  BDAutoTrackDevTools.m
//  RangersAppLog
//
//  Created by bytedance on 6/27/22.
//

#import "BDAutoTrackDevTools.h"
#import "BDAutoTrackInspector.h"
#import "RangersLogManager.h"
#import "BDAutoTrackVisualLogger.h"
#import "BDAutoTrackFileLogger.h"
#import "BDAutoTrackDevToolsMonitor.h"
#import "BDAutoTrackDevEvent.h"
#import "BDAutoTrackUtilities.h"
#import "BDAutoTrackDevToolsHolder.h"

@implementation BDAutoTrackDevTools

+ (void)install:(BDAutoTrack *) tracker
{
    [RangersLogManager registerLogger:[BDAutoTrackVisualLogger class]];
    [RangersLogManager registerLogger:[BDAutoTrackFileLogger class]];
    [BDAutoTrackDevToolsHolder shared];
    [[BDAutoTrackDevEvent shared] bindEvents:tracker];
}

BOOL inDragState;

+ (void)presentInspector
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (inDragState) {
            return;
        }
        if ([self mainWindow]) {
            [[self inspectorNavigation] popToRootViewControllerAnimated:NO];
            [[self mainWindow].rootViewController presentViewController:[self inspectorNavigation] animated:YES completion:^{
            }];
        }
    });
}

+ (void)dragStart {
    if (!inDragState) {
        inDragState = YES;
    }
}

+ (void)dragEnd {
    if (inDragState) {
        inDragState = NO;
    }
}

+ (void)dragMoving:(UIControl *)view withEvent:event
{
    UIWindow *mainWindow = [self mainWindow];
    CGSize mainSize = mainWindow.frame.size;
    CGFloat top_edge = 57;
    CGFloat bottom_edge = 30;
    CGFloat half_w = view.frame.size.width / 2;
    CGFloat half_h = view.frame.size.height / 2;
    
    CGPoint p = [[[event allTouches] anyObject] locationInView:mainWindow];
    CGFloat x = p.x;
    CGFloat y = p.y;
    if (x < half_w) {
        x = half_w;
    }
    if (x > mainSize.width - half_w) {
        x = mainSize.width - half_w;
    }
    if (y < half_h + top_edge) {
        y = half_h + top_edge;
    }
    if (y > mainSize.height - half_h - bottom_edge) {
        y = mainSize.height - half_h - bottom_edge;
    }
    view.center = CGPointMake(x, y);
}

#pragma mark - properties

+ (UINavigationController *)inspectorNavigation
{
    static UINavigationController *navigation;
    static BDAutoTrackInspector *inspector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inspector = [BDAutoTrackInspector new];
        navigation = [[UINavigationController alloc] initWithRootViewController:inspector];
    });
    return navigation;
}

+ (UIButton *)floatingEntryButton
{
    static UIButton *_fltEntryButton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"floating_icon" ofType:@"png" inDirectory:@"RangersAppLogDevTools.bundle"];
        UIImage *img = [UIImage imageWithContentsOfFile:path];
        [btn setImage:img forState:UIControlStateNormal];
        _fltEntryButton = btn;
        [btn addTarget:self action:@selector(dragStart)forControlEvents:UIControlEventTouchDragInside];
        [btn addTarget:self action:@selector(dragEnd)forControlEvents:UIControlEventTouchUpInside];
        [btn addTarget:self action:@selector(dragMoving:withEvent:)forControlEvents:UIControlEventTouchDragInside];
        [btn addTarget:self action:@selector(presentInspector) forControlEvents:UIControlEventTouchDown];
        btn.layer.cornerRadius = [[self class] floatingButtonDiameter]/2.0f;
        btn.clipsToBounds = YES;
        [BDAutoTrackUtilities ignoreAutoTrack:btn];
    });
    return _fltEntryButton;
}

+ (UIWindow *)mainWindow
{
    return [[UIApplication sharedApplication].windows firstObject];
}
                  
            
+ (void)setMonitorEnabled:(BOOL) monitorEnabled
{
    BDAutoTrackDevToolsMonitor *monitor = [BDAutoTrackDevToolsHolder shared].monitor;
    monitor.enabled = monitorEnabled;
}

+ (void)showFloatingEntryButton
{
    dispatch_block_t displayBlock = ^{
        UIWindow *window = [self mainWindow];
        UIButton *button = [self floatingEntryButton];
        if (button.superview != window) {
            [window addSubview:button];
            CGRect initialFrame = CGRectMake([self initialPositionEdge] / 2, (CGRectGetHeight(window.bounds) / 2 + [self floatingButtonDiameter]), [self floatingButtonDiameter], [self floatingButtonDiameter]);
            button.frame = initialFrame;
        }
        [window bringSubviewToFront:button];
    };
    
    if ([self mainWindow]) {
        
        displayBlock();
        
    } else {
        id __block observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            displayBlock();
            [NSNotificationCenter.defaultCenter removeObserver:observer];
        }];
    }
}
                
            
#pragma mark - layout
+ (CGFloat)floatingButtonDiameter
{
    return 48.0f;
}

+ (CGFloat)initialPositionEdge
{
    return 48.0f;
}
                
                  


@end
