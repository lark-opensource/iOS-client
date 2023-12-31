//
//  BDPAppPageManager.h
//  Timor
//
//  Created by 王浩宇 on 2019/1/7.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <OPFoundation/BDPUniqueID.h>

NS_ASSUME_NONNULL_BEGIN

@class BDPCommon;
@class BDPAppPage;

@protocol BDPlatformContainerProtocol;

@interface BDPAppPageManager : NSObject

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID;

- (BDPAppPage *)dequeueAppPage;
- (void)addAppPage:(BDPAppPage *)view;
- (BDPAppPage *)appPageWithPath:(NSString *)path;
- (BDPAppPage *)appPageWithID:(NSInteger)ID;
/// 获取所有AppPage
- (NSArray<BDPAppPage *> *)getAllAppPages;
- (NSArray<BDPAppPage *> *)appPagesWithIDs:(NSArray<NSNumber *> *)ids;

- (void)preparePreloadAppPageIfNeed;
- (void)releaseTerminatedPreloadAppPage:(BDPAppPage *)page;
/// 释放所有已经预加载的appPage
- (void)releaseAllPreloadAppPage;

- (void)updateContainerVC:(UIViewController<BDPlatformContainerProtocol> *)containerVC;

/** 开启自动预加载新的AppPage */
- (void)setAutoCreateAppPageEnable:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END
