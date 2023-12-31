//
//  BDASplashViewTargetActionManager.h
//  TTAdSplashSDK
//
//  Created by YangFani on 2020/8/17.
//
//  该类统一封装了所有的开屏视图，为一个公共的target action 抽象类，该类实际封装了具体的splah view(target)的update,clear等操作（action）
//  外部不需要再关心是由哪个具体target去执行action，后期所有的新增开屏视图，只需要实现指定的协议

#import <Foundation/Foundation.h>
#import "TTAdSplashModel.h"
#import "BDASplashViewTargetActionProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDASplashViewTargetActionManager : NSObject

@property (nonatomic, strong) TTAdSplashModel *model;

@property (nonatomic, strong, nullable) UIView<BDASplashViewTargetActionProtocol> *splashView;

- (instancetype)initWithModel:(TTAdSplashModel *)model;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)new NS_UNAVAILABLE;

- (UIView<BDASplashViewTargetActionProtocol> *)generateSplashView:(CGRect)frame delegate:(id<BDASplashViewProtocol>)delegate;

- (void)clear;

- (void)updateModel:(TTAdSplashModel *)model;

- (TTAdSplashModel *)openActionModel;

- (void)willMoveToWindow:(UIWindow *)newWindow;

- (void)didMoveToWindow;

- (void)willDisappear;

- (void)didDisappear;

- (void)skipAdWithSource:(NSString *)source;

@end

NS_ASSUME_NONNULL_END
