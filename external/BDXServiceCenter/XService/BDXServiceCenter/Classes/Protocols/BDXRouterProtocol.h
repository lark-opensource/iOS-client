//
//  BDXRouterProtocol.h
//  BDXServiceCenter-Pods-Aweme
//
//  Created by bill on 2021/3/4.
//

#import <Foundation/Foundation.h>
#import "BDXServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDXContainerProtocol;
@class BDXContext;

@protocol BDXRouterProtocol <BDXServiceProtocol>

+ (instancetype)sharedInstance;

/// 打开一个Page/Popup容器
/// @param urlString 页面地址
/// @param context 相关的配置可以通过这里设置
/// @param completion 回调
- (void)openWithUrl:(NSString *)urlString context:(BDXContext *)context completion:(nullable void (^)(id<BDXContainerProtocol>, NSError *_Nullable))completion;

/// 创建一个Page/Popup容器
/// @param urlString 页面地址
/// @param context 相关的配置可以通过这里设置
/// @param autoPush 是否自动打开
- (id<BDXContainerProtocol>)containerWithUrl:(NSString *)urlString context:(BDXContext *)context autoPush:(BOOL)autoPush;

/// 关闭容器，返回值代表是否成功关闭
/// @param containerID 容器ID
/// @param params 某些场景下当容器关闭的时候，会广播一个event, params作为event的参数
/// @param completion 回调
- (BOOL)closeWithContainerID:(NSString *)containerID params:(nullable NSDictionary *)params completion:(nullable void (^)(NSError *_Nullable))completion;

/// 返回Page容器的列表，顺序为栈（最后打开的在最前面）
- (nullable NSArray<id<BDXContainerProtocol>> *)routeStack;

@end

NS_ASSUME_NONNULL_END
