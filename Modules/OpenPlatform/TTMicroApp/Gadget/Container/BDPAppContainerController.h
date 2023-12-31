//
//  BDPAppContainerController.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/16.
//

#import <UIKit/UIKit.h>
#import "BDPBaseContainerController.h"

@class BDPAppController;

NS_ASSUME_NONNULL_BEGIN

/**
 * 小程序外层容器，处理navigate、底部tabbar切换等特性。每个页面具体的VC是BDPAppController。
 */
@interface BDPAppContainerController : BDPBaseContainerController

@property (nonatomic, strong, readonly, nullable) BDPAppController *appController;

/// 该属性即将迁移新容器
@property (nonatomic, strong, nullable) BDPAppPageURL *startPage;

@end

NS_ASSUME_NONNULL_END
