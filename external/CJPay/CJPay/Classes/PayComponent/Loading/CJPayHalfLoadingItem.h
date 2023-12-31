//
//  CJPayHalfLoadingItem.h
//  Pods
//
//  Created by 易培淮 on 2021/8/17.
//

#import <Foundation/Foundation.h>
#import "CJPayLoadingManager.h"
#import "CJPayTimerManager.h"
#import "CJPayHalfPageBaseViewController.h"
#import <BDWebImage/BDWebImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayHalfLoadingItem : CJPayHalfPageBaseViewController <CJPayAdvanceLoadingProtocol>

@property (nonatomic, strong) BDImageView *imageView;
@property (nonatomic, strong) CJPayTimerManager *timerManager;
@property (nonatomic,   weak) UIViewController *topVc;
@property (nonatomic,   weak) UINavigationController *originNavigationController;

- (void)startAnimation;
- (NSString *)loadingTitle;
+ (CJPayLoadingType)loadingType;

@end

NS_ASSUME_NONNULL_END
