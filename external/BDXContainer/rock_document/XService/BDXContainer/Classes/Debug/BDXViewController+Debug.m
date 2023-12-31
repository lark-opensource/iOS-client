//
//  RifleViewController+Debug.m
//  Bullet-Pods-Aweme
//
//  Created by suixudong on 2021/3/14.
//
#if INHOUSE_TARGET || DEBUG

#import <AWELazyRegister/AWELazyRegisterPremain.h>
#import <BulletX/BulletXFpsLabel.h>
#import <BytedanceKit/NSObject+BTDAdditions.h>
#import <Masonry/Masonry.h>
#import "BDXViewController+Private.h"
#import "BDXViewController.h"

@implementation BDXViewController (Debug)

AWELazyRegisterPremainClassCategory(BDXViewController, Debug) { [self btd_swizzleInstanceMethod:@selector(viewDidLoadHeadPart) with:@selector(debug_viewDidLoadHeadPart)]; }

- (void)debug_viewDidLoadHeadPart
{
    // add fps label
    CGRect viewRect = self.view.frame;
    CGRect fpsFrame = CGRectMake(viewRect.size.width - 120, viewRect.size.height - 30, 100, 20);
    RifleFpsLabel *fpsLabel = [[RifleFpsLabel alloc] initWithFrame:fpsFrame];
    self.fpsLabel = fpsLabel;

    [self debug_viewDidLoadHeadPart];

    [self.view addSubview:fpsLabel];
    [self.view bringSubviewToFront:fpsLabel];

    [self addDebugInfo];
}

- (void)addDebugInfo
{
    RifleEngineType engineType = self.fpsLabel.currentEngine;
    NSString *type = @"";
    if (engineType == RifleEngineTypeLynx) {
        type = @" - Lynx";
    } else if (engineType == RifleEngineTypeWeb) {
        type = @" - Web";
    }

    UILabel *bulletViewLabel = [[UILabel alloc] init];
    bulletViewLabel.text = [NSString stringWithFormat:@"Bullet%@", type];
    bulletViewLabel.font = [UIFont boldSystemFontOfSize:13];
    bulletViewLabel.textAlignment = NSTextAlignmentCenter;
    bulletViewLabel.backgroundColor = [UIColor colorWithRed:244 / 255.f green:96 / 255.f blue:108 / 255.f alpha:1];
    [self.view addSubview:bulletViewLabel];
    [bulletViewLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(100, 20));
        make.left.equalTo(self.view).with.offset(20);
        make.bottom.equalTo(self.view).with.offset(-10);
    }];

    self.debugLabel = bulletViewLabel;
}

@end

#endif
