//
//  ACCRefreshHeader.m
//  CameraClient
//
//  Created by Quan Quan on 16/8/30.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import "ACCRefreshHeader.h"
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/ACCTapticEngineManager.h>

@interface ACCRefreshHeader()

@property (nonatomic, strong) UIView<ACCLoadingViewProtocol> *loading;
@property (weak, nonatomic) UIView *parentView;
@property (assign, nonatomic) CGPoint position;

@end

@implementation ACCRefreshHeader

+ (instancetype)headerWithRefreshingBlock:(MJRefreshComponentRefreshingBlock)refreshingBlock backgroundColor:(UIColor *)backgroundColor
{
    return [self headerWithRefreshingBlock:refreshingBlock backgroundColor:backgroundColor parentView:nil position:CGPointZero];
}

+ (instancetype)headerWithRefreshingBlock:(MJRefreshComponentRefreshingBlock)refreshingBlock backgroundColor:(UIColor *)backgroundColor parentView:(UIView *)parentView position:(CGPoint)position
{
    ACCRefreshHeader *header = [self headerWithRefreshingBlock:refreshingBlock];
    if (parentView) {
        header.parentView = parentView;
        header.position = position;
    }
    return header;
}

- (void)setLoadingViewBackgroundColor:(UIColor *)color
{
    self.loading.backgroundColor = color;
}

#pragma mark - 重写方法
#pragma mark 在这里做一些初始化配置（比如添加子控件）
- (void)prepare
{
    [super prepare];
    
    // 设置控件的高度
    self.mj_h = 60;
    
    // loading
    UIView<ACCLoadingViewProtocol> *loading = [ACCLoading() loadingView];
    if (self.parentView) {
        [self.parentView addSubview:loading];
    } else {
        [self addSubview:loading];
    }
    self.loading = loading;
}

#pragma mark 在这里设置子控件的位置和尺寸
- (void)placeSubviews
{
    [super placeSubviews];

    if (self.parentView) {
        self.loading.frame = CGRectMake(self.position.x, self.position.y, 32, 32);
    } else {
        self.loading.center = CGPointMake(self.mj_w * 0.5, self.mj_h * 0.5);
    }
}

#pragma mark 监听scrollView的contentOffset改变
- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change
{
    [super scrollViewContentOffsetDidChange:change];
}

#pragma mark 监听scrollView的contentSize改变
- (void)scrollViewContentSizeDidChange:(NSDictionary *)change
{
    [super scrollViewContentSizeDidChange:change];
}

#pragma mark 监听scrollView的拖拽状态改变
- (void)scrollViewPanStateDidChange:(NSDictionary *)change
{
    [super scrollViewPanStateDidChange:change];
}

#pragma mark 监听控件的刷新状态
- (void)setState:(MJRefreshState)state
{
    MJRefreshCheckState;
    
    switch (state) {
        case MJRefreshStateIdle:
            [self.loading stopAnimating];
            break;
        case MJRefreshStatePulling:
            [self.loading stopAnimating];
            [ACCTapticEngineManager tap];
            break;
        case MJRefreshStateRefreshing:
            [self.loading startAnimating];
            break;
        default:
            break;
    }
}

@end
