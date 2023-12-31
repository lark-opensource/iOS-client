//
//  ACCEditVideoBeautyRestorer.h
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2021/1/23.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditVideoBeautyRestorer : NSObject

/// 找到所有待恢复的美颜小项，并判断是否已经下载了，如果没有下载，则返回
/// 需要下载的effectId 列表
/// @param publishModel AWEVideoPublishViewModel
+ (NSArray<NSString *> *)effectIdsToDownloadForResume:(nonnull AWEVideoPublishViewModel *)publishModel;


/// 返回需要恢复的所有美颜小项：会初始化对应的ViewModel，获取过滤好的分类数据，
/// 并与ACCRepoBeautyModel数据对比，找到草稿中用到的美颜小项列表
/// @param publishModel AWEVideoPublishViewModel
+ (NSArray<AWEComposerBeautyEffectWrapper *> *)effectsToApplyForResume:(nonnull AWEVideoPublishViewModel *)publishModel;


/// 返回需要恢复的所有美颜小项：会直接拿传入的分类数据与ACCRepoBeautyModel数据对比，
/// 同时也会根据草稿中的数据恢复每个小项的滑竿值、互斥分类选中的小项、二级小项中选中的小项
/// @param publishModel AWEVideoPublishViewModel
/// @param categories 美颜分类数据
+ (NSArray<AWEComposerBeautyEffectWrapper *> *)effectsToApplyForResume:(nonnull AWEVideoPublishViewModel *)publishModel
                                                         forCategories:(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)categories;


/// 重新应用草稿中所有已经下载好的美颜小项：如果没有下载，不会主动下载
/// @param publishViewModel 草稿
/// @param editService 效果应用
+ (void)reapplyBeautyEffectFrom:(AWEVideoPublishViewModel *)publishViewModel
                withEditService:(id<ACCEditServiceProtocol>)editService;

@end

NS_ASSUME_NONNULL_END
