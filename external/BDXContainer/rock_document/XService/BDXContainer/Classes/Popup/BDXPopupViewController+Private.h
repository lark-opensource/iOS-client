//
//  BDXPopupViewController+Private.h
//  BDXContainer
//
//  Created by xinwen tan on 2021/4/9.
//

#import "BDXPopupViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class BDXView;
@class BDXPopupSchemaParam;

@interface BDXPopupViewController ()

@property(nonatomic, strong) BDXPopupSchemaParam *config;
@property(nonatomic, nullable) BDXView *viewContainer;
@property(nonatomic, assign) BOOL userInteractionEnabled;
@property(nonatomic, assign) BOOL animationCompleted;

@property(nonatomic) CGRect frame;
@property(nonatomic) CGRect initialFrame;
@property(nonatomic) CGRect finalFrame;

+ (nullable BDXPopupViewController *)createWithConfiguration:(BDXPopupSchemaParam *)config context:(BDXContext *)context completion:(nullable void (^)(BDXPopupViewController *vc))completion;

- (void)hide;
- (void)show;
- (void)destroy;

- (void)removeSelf:(nullable NSDictionary *)params;

- (void)resize:(CGRect)frame;
- (void)resizeWithAnimation:(CGRect)frame completion:(nullable dispatch_block_t)completion;

// gesture相关
@property(nonatomic) CGPoint panStartLocation;
@property(nonatomic) CGRect panStartFrame;
@property(nonatomic) CGRect dragHeightFrame;
// 是否处于最大高度状态
@property(nonatomic, assign) BOOL dragInMaxHeight;
@property(nonatomic, assign) BOOL handleTouchFinish;

@end

NS_ASSUME_NONNULL_END
