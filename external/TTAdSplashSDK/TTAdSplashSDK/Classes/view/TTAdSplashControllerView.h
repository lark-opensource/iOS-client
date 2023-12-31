//
//  TTAdSplashControllerView.h
//  Article
//
//  Created by Zhang Leonardo on 14-9-26.
//
//

#import <UIKit/UIKit.h>

@class TTAdSplashModel;
@protocol TTAdSplashControllerViewDelegate;

@interface TTAdSplashControllerView : UIView
@property (nonatomic, weak) id<TTAdSplashControllerViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame model:(TTAdSplashModel *)model;

- (TTAdSplashModel *)openActionModel;

- (void)didDisappear;

/**
 跳过广告移除splashView
 */
- (void)skipAd;

- (void)removeBgView;

@end

@protocol TTAdSplashControllerViewDelegate <NSObject>
- (void)splashControllerViewShowFinished:(TTAdSplashControllerView *)view
                                 adModel:(TTAdSplashModel *)model
                               animation:(BOOL)animation;
- (void)splashViewClickBanner:(TTAdSplashModel *)adModel;
- (void)splashViewClickBackground:(TTAdSplashModel *)adModel extraData:(NSDictionary *)extraData;
- (void)splashViewClickNineBoxIndex:(TTAdSplashModel *)adModel
                              index:(NSInteger)index;
- (void)splashViewVideoPlayCompleted:(TTAdSplashModel *)adModel;
- (void)splashControllerViewShowImageAdCompleted:(TTAdSplashControllerView *)view
                                           model:(TTAdSplashModel *)model;

@end
