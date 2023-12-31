//  Copyright 2022 The Lynx Authors. All rights reserved.

#import <UIKit/UIKit.h>
#import <Lynx/LynxUI.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDXLynxViewPagerLightDelegate <NSObject>

- (void)didIndexChanged:(NSUInteger)index;

@end

@interface BDXLynxViewPagerLight : LynxUI

@property(nonatomic, weak) id<BDXLynxViewPagerLightDelegate> pagerDelegate;

@end

NS_ASSUME_NONNULL_END
