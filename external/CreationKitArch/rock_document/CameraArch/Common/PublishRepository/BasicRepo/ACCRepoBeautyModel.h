//
//  ACCRepoBeautyModel.h
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2021/1/21.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRepoBeautyModel : NSObject<NSCopying>

@property (nonatomic, copy) NSString *lastSelectBeautyCategoryId;

/// {categoryId : effectId} record every last selected beauty effectId in each category
///Note that here value is effect ID, not resource ID, because Android is effect ID, which is very complicated to change, so
///It's compatible here
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *selectedBeautyDic;

/// {effect.resourceId: slider value} slider value in [0, 100] or [-50, 50]
@property (nonatomic, copy) NSDictionary<NSString *, NSNumber *> *beautyValueDic;

///{parent. Resourceid, effect. Resourceid} records the parent-child relationship of the selected application subitem: the first level subitem corresponding to the second level subitem
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *selectedAlbumDic;

///Effect.effectid of all beauty apps
@property (nonatomic, copy) NSArray<NSString *> *appliedEffectIds;

///The last time I went from shooting to editing, I recognized the gender (AWE composer beauty gender)
@property (nonatomic, assign) NSInteger gender;

- (BOOL)hadUseBeauty;

- (BOOL)isEqualToObject:(ACCRepoBeautyModel *)object;

@end

@interface AWEVideoPublishViewModel (RepoBeauty)
 
@property (nonatomic, strong, readonly) ACCRepoBeautyModel *repoBeauty;
 
@end


NS_ASSUME_NONNULL_END
