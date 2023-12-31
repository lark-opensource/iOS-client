//
//  ADFeelGoodTestViewController.h
//  FeelGoodDemo
//
//  Created by bytedance on 2020/8/25.
//  Copyright © 2020 huangyuanqing. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ADFeelGoodOpenModel;

NS_ASSUME_NONNULL_BEGIN

@interface ADFeelGoodViewController : UIViewController

@property (nonatomic, copy) void(^closeBlock)(void);

- (instancetype)initWithOpenModel:(ADFeelGoodOpenModel *)openModel;
- (void)close;
- (void)prepareiPadLayoutModeParams;

@end

@interface ADFeedGoodLoadStatusView : UIView

@property (nonatomic, copy) void(^retryFetchBlock)(void);
@property (nonatomic, copy) void(^closeBlock)(void);

- (void)startLoading;
- (void)stopLoading;
- (void)showErrorView;


@end

NS_ASSUME_NONNULL_END
