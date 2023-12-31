//
//  BDXLynxVideoProFullScreen.m
//
// Copyright 2022 The Lynx Authors. All rights reserved.
//

#import "BDXLynxVideoProFullScreen.h"
#import <ByteDanceKit/UIDevice+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/BTDResponder.h>
#import <ByteDanceKit/UIView+BTDAdditions.h>
#import <BDWebImage/BDWebImage.h>
#import <Masonry/Masonry.h>



@interface BDXLynxVideoProFullScreen ()
@property (nonatomic, strong) NSString *imageURL;
@property (nonatomic, weak) UIView *playerView;
@property (nonatomic, assign) UIInterfaceOrientationMask restoreOrientation;
@property (nonatomic, copy) void(^dismissBlk)(void);
@end

@implementation BDXLynxVideoProFullScreen



- (instancetype)initWithPlayerView:(UIView *)playerView dismiss:(void (^)(void))dismiss {
  if (self = [super init]) {
    self.playerView = playerView;
    self.dismissBlk = dismiss;
    self.modalPresentationStyle = UIModalPresentationFullScreen;
  }
  return self;
}


- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupUI];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  self.playerView.frame = self.view.bounds;
}

- (BOOL)shouldAutorotate {
  return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  BOOL isAPPHorizonal = UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation);
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad || isAPPHorizonal) {
    return [super supportedInterfaceOrientations];
  } else {
    return UIInterfaceOrientationMaskLandscapeRight;
  }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
  return UIInterfaceOrientationLandscapeRight;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
  return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
  return YES;
}

- (void)setupUI {
  [self.view addSubview:self.playerView];
  self.playerView.frame = self.view.bounds;
}

- (void)dismiss {
  __weak __typeof(self) weakSelf = self;
  [self.presentingViewController dismissViewControllerAnimated:NO completion:^{
    if (weakSelf.dismissBlk) {
      weakSelf.dismissBlk();
    }
  }];
}

- (void)show:(void (^)(void))completion {
  [[BTDResponder topViewController] presentViewController:self animated:NO completion:^{
    !completion ?: completion();
  }];
}


@end
