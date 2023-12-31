//
//  AWEComposerBeautyCacheMigration.h
//  CameraClient
//
//  Created by ZhangYuanming on 2020/3/30.
//

#import <Foundation/Foundation.h>
#import <CreationKitBeauty/AWEComposerBeautyMigrationProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEComposerBeautyCacheViewModel;
@class AWEComposerBeautyEffectCategoryWrapper;
@interface AWEComposerBeautyCacheMigration: NSObject<AWEComposerBeautyMigrationProtocol>

- (instancetype)initWithCacheManager:(AWEComposerBeautyCacheViewModel *)cacheManager
                           panelName:(NSString *)panelName;
- (void)startCacheDataMigration:(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)categories
                    lastABGroup:(NSNumber *)lastABGroup
                     completion:(void(^)(void))completion;

@end

NS_ASSUME_NONNULL_END
