//
//  BDPAppPageFactory.h
//  Timor
//
//  Created by liubo on 2019/5/14.
//

#import <OPFoundation/BDPUniqueID.h>

@class BDPAppPage, WKProcessPool;

@interface BDPAppPageFactory : NSObject

@property (nonatomic, strong, readonly) BDPAppPage *preloadAppPage;

+ (instancetype)sharedManager;

/**
 @brief 获取一个可用的BDPAppPage
 @return 可用的BDPAppPage
 */
- (BDPAppPage *)appPageWithUniqueID:(BDPUniqueID *)uniqueID;

/**
 @brief 创建or重建 预加载的BDPAppPage
 */
- (void)reloadPreloadedAppPage;

/**
 @brief 释放 预加载的BDPAppPage
 */
- (void)releaseAllPreloadedAppPage;

/**
 @brief 释放 预加载的BDPAppPage,调用防给出原因，目前只有内存紧张时调用
 */
+ (void)releaseAllPreloadedAppPageWithReason:(NSString * _Nonnull)reason;

- (void)tryPreloadAppPage;

#pragma mark - WKProcessPool
- (WKProcessPool *)getPreloadProcessPool;
- (void)tryPreloadPrecessPool;


/// 预加载当前场景值
/// @param preloadFrom 预加载场景
- (void)updatePreloadFrom:(NSString * _Nonnull)preloadFrom;

/// 记录上次打开小程序信息
- (void)updatePreGadget:(NSString * _Nullable)appId startPath:(NSString *_Nullable)startPath;

/// 为提升性能和效率，将page preload 和 上一次打开小程序信息 封装后一次性返回
- (NSDictionary<NSString *, id> * _Nonnull)pagePreloadAndPreGadgetInfo;

@end
