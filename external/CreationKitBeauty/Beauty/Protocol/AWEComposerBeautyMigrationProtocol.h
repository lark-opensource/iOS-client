//
//  AWEComposerBeautyMigrationProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by ZhangYuanming on 2020/6/18.
//

#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWEComposerBeautyMigrationProtocol <NSObject>

- (void)startCacheDataMigration:(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)categories
                    lastABGroup:(NSNumber *)lastABGroup
                     completion:(void(^)(void))completion;

@end

NS_ASSUME_NONNULL_END
