//
//  IESLiveResouceBundleSwitchButton.m
//  Pods
//
//  Created by Zeus on 2016/12/28.
//
//

#import "IESLiveResouceBundleSwitchButton.h"
#import "IESLiveResouceBundle+Loader.h"
#import "IESLiveResouceBundle+Switcher.h"
#import <QuartzCore/QuartzCore.h>

@interface IESLiveResouceBundleSwitchButton ()

@property (nonatomic, strong) NSString *category;

@end

@implementation IESLiveResouceBundleSwitchButton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithCategory:(NSString *)category {
    self = [super initWithFrame:CGRectMake(0, 0, 40, 40)];
    if (self) {
        self.category = category;
        self.layer.cornerRadius = 20;
        self.layer.borderColor = [UIColor grayColor].CGColor;
        self.layer.borderWidth = 1.0;
        self.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
        [self addTarget:self action:@selector(showSwitchButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(dragMoving:withEvent:) forControlEvents: UIControlEventTouchDragInside];
    }
    return self;
}

static BOOL dragPerformed = NO;

- (void)showSwitchButtonClicked
{
    if (dragPerformed) {
        dragPerformed = NO;
    } else {
        NSArray <NSString *> *bundleNames = [IESLiveResouceBundle loadBundleNamesWithCategory:self.category];
        if ([bundleNames count] > 0) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
            UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"选择资源包"
                                                                           message:self.category
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            NSString *category = self.category;
            __weak typeof(self) weakSelf = self;
            void (^handler)(UIAlertAction *) = ^(UIAlertAction *action) {
                [IESLiveResouceBundle switchToBundle:action.title forCategory:category];
                if (weakSelf.bundleDidSwiched) {
                    weakSelf.bundleDidSwiched(action.title);
                }
            };
            
            for (NSString *bundleName in bundleNames) {
                UIAlertAction *action = [UIAlertAction actionWithTitle:bundleName style:UIAlertActionStyleDefault handler:handler];
                [actionSheet addAction:action];
            }
            
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            [actionSheet addAction:action];
            
            UIPopoverPresentationController *popPresenter = [actionSheet popoverPresentationController];
            if (popPresenter) {
                popPresenter.sourceView = weakSelf;
                popPresenter.sourceRect = weakSelf.bounds;
            }
            UIViewController *viewController = self.sourceViewController;
            if (!viewController) {
                viewController = [UIApplication sharedApplication].delegate.window.rootViewController;
            }
            [viewController presentViewController:actionSheet animated:YES completion:nil];
#pragma clang diagnostic pop
        }
    }
}

- (void)dragMoving:(UIButton *)button withEvent:(UIEvent *)event
{
    CGPoint point = [[[event allTouches] anyObject] locationInView:self.superview];
    if (!CGRectContainsPoint(button.frame, point)) {
        dragPerformed = YES;
        CGFloat buttonHalfWidth = button.frame.size.width / 2;
        CGFloat buttonHalfHeight = button.frame.size.height / 2;
        point.x = MIN(self.superview.frame.size.width - buttonHalfWidth, MAX(buttonHalfWidth, point.x));
        point.y = MIN(self.superview.frame.size.height - buttonHalfHeight, MAX(buttonHalfHeight, point.y));
        [UIView animateWithDuration:0.2 animations:^{
            button.center = point;
        }];
    }
}

@end
