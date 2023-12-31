//
//  ACCBeautyBuildInDataSource.h
//  AWEStudio-Pods-Aweme
//
//  Created by ZhangYuanming on 2020/6/8.
//

#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>

@protocol ACCBeautyBuildInDataSource <NSObject>

- (NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)buildInCategories;
- (UIImage *)iconForItem:(AWEComposerBeautyEffectWrapper *)item;

@end
