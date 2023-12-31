//
//  BDASplashBaseView.h
//  BDAlogProtocol
//
//  Created by YangFani on 2020/4/23.
//

#import <UIKit/UIKit.h>
#import "BDASplashViewTargetActionProtocol.h"
#import "TTAdSplashModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDASplashBaseView : UIView<BDASplashViewTargetActionProtocol>

@property (nonatomic, strong) TTAdSplashModel       * model;
@property (nonatomic, weak) id<BDASplashViewProtocol> delegate;

/// 资源开始展示的时间
@property (nonatomic, assign) CFAbsoluteTime          srcBeginShowTime;
///界面初始化到开始播放的时间
@property (nonatomic, assign) CFAbsoluteTime          srcLoadDuration;
/// 播放完成的标识
@property (nonatomic, assign) BOOL                    markWillDismiss;

- (void)updateModel:(TTAdSplashModel *)model;

- (void)willAppear;

- (void)didAppear;

- (void)didDisappear;

- (void)willDisappear;

- (void)showAdVideo;

- (void)invalidPerform;

- (BOOL)haveClickAction;

- (void)trackAdEventWithLabel:(NSString *)label extra:(nullable NSDictionary *)extra adExtra:(nullable NSDictionary *)adExtra;

- (void)trackAdEventWithLabel:(NSString *)label extra:(nullable NSDictionary *)extra;

/// 三方监测
/// @param URLs 链接
/// @param label  label
- (void)trackURLs:(NSArray *)URLs label:(NSString *)label;

- (void)skipAdWithSource:(NSString *)source;

@end

NS_ASSUME_NONNULL_END
