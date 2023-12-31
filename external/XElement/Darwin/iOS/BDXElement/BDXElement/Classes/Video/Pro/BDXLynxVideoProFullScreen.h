//
//  BDXLynxVideoProFullScreen.h
//
// Copyright 2022 The Lynx Authors. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxVideoProFullScreen : UIViewController

- (instancetype)initWithPlayerView:(UIView *)playerView dismiss:(void (^)(void))dismiss;

- (void)show:(void (^)(void))completion;

- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
