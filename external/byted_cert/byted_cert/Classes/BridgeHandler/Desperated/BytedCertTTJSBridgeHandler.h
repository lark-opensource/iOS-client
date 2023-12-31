//
//  BytedCertTTJSBridgeHandler.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface BytedCertTTJSBridgeHandler : NSObject

- (instancetype)initWithParams:(NSDictionary *_Nullable)params;

/// 开始加载SDK
- (void)start;

/// 开始加载SDK
/// @param superVC 当前页面vc，用于实名h5页面跳转
- (void)startWithSuperViewController:(UIViewController *_Nullable)superVC;

@end

NS_ASSUME_NONNULL_END
