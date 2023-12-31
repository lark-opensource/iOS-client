//
//  ACCRefreshHeader.h
//  CameraClient
//
//  Created by Quan Quan on 16/8/30.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import <MJRefresh/MJRefreshHeader.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRefreshHeader : MJRefreshHeader

+ (instancetype)headerWithRefreshingBlock:(MJRefreshComponentRefreshingBlock)refreshingBlock backgroundColor:(UIColor *)backgroundColor;

+ (instancetype)headerWithRefreshingBlock:(MJRefreshComponentRefreshingBlock)refreshingBlock backgroundColor:(UIColor *)backgroundColor parentView:(nullable UIView *)parentView position:(CGPoint)position;

- (void)setLoadingViewBackgroundColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
