//
//  IESEffectListManager.h
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/13.
//

#import <Foundation/Foundation.h>

typedef void(^IESEffectListCompletionBlock)(BOOL success, id _Nullable result, NSError * _Nullable error, BOOL fromCache);

NS_ASSUME_NONNULL_BEGIN

@class IESEffectConfig;
@protocol IESEffectListManagerDelegate;

/**
 * @breif 特效列表的加载管理
 * 特效列表的加载分两种加载方式：全量加载和按分类加载（即每次只加载一个分类的数据）
 * 1. 全量加载使用 [IESEffectListManager loadEffectsListWithPanelName:completion:] 方法；
 * 2. 按分类加载先使用 [IESEffectListManager loadCategoryListWithPanelName:completion:] 获取所有的分类数据和第一个分类的特效列表数据，
 *    再使用 [IESEffectListManager loadCategoryEffectListWithPanelName:categoryKey:completion:] 获取指定分类的特效列表数据。
 */
@interface IESEffectListManager : NSObject

@property (nonatomic, copy, readonly) NSString *accessKey;

@property (nonatomic, strong, readonly) IESEffectConfig *config;

@property (nonatomic, weak) id<IESEffectListManagerDelegate> delegate;

- (instancetype)initWithAccessKey:(NSString *)accessKey
                           config:(IESEffectConfig *)config;

- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Public

/**
 * @breif Fetch all effects of the panel at one time.
 * 一次性加载指定面板(panelName)下的所有特效数据。
 *
 * @param completion Block execute on main thread.
 */
- (void)loadEffectsListWithPanelName:(NSString *)panelName
                          completion:(IESEffectListCompletionBlock)completion;

/**
 * @breif Fetch all categories and the effects of the default category at one time.
 * 获取面板下的所有分类数据和第一个分类（一般是热门）的特效列表数据。
 *
 * @param panelName panel name, can not be nil.
 * @param completion Block execute on main thread.
 */
- (void)loadCategoryListWithPanelName:(NSString *)panelName
                           completion:(IESEffectListCompletionBlock)completion;

/**
 * @breif Fetch effects of the specific category.
 * 获取指定面板的指定分类下的特效列表数据。
 *
 * @param panelName panel name, can not be nil.
 * @param categoryKey categoryKey
 * @param completion Block execute on main thread.
 */
- (void)loadCategoryEffectListWithPanelName:(NSString *)panelName
                                categoryKey:(NSString *)categoryKey
                                 completion:(IESEffectListCompletionBlock)completion;

@end

@protocol IESEffectListManagerDelegate <NSObject>

- (void)effectListManager:(IESEffectListManager *)effectListManager
   willSendRequestWithURL:(NSString *)URL
               parameters:(NSMutableDictionary *)parameters;

@end

NS_ASSUME_NONNULL_END
