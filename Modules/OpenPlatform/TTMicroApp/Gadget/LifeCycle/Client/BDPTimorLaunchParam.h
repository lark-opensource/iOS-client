//
//  BDPTimorLaunchParam.h
//  Timor
//
//  Created by MacPu on 2019/11/28.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

extern NSString *const kRealMachineDebugAddressKey;
extern NSString *const kTargetWindowKey; // 目标打开window(iPad多Scene)

NS_ASSUME_NONNULL_BEGIN

@interface BDPTimorLaunchVdomParam : NSObject

@property (nonatomic, copy, readonly) NSString *vdom;
@property (nonatomic, copy, readonly) NSString *css;
@property (nonatomic, copy, readonly) NSDictionary *config;
@property (nonatomic, assign, readonly) int64_t version_code;

@end

// 增加的其他启动参数
@interface BDPTimorLaunchExtraParma : NSObject

// 真机调试地址
@property (nonatomic, copy) NSString *realMachineDebugAddress;
@property (nonatomic, weak, nullable) UIWindow *window;

- (instancetype)initWithExtra:(NSDictionary *)extra;

@end

/// 启动参数
@interface BDPTimorLaunchParam : NSObject

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong, nullable) NSDictionary *vdom;
@property (nonatomic, strong) BDPTimorLaunchExtraParma *extra;
/// 根据snapshot 更新LaunchParam
/// @param snapshot snapshot 压缩过后的 vdom
- (void)updateWithSnapshot:(NSString *)snapshot;

@end

NS_ASSUME_NONNULL_END
