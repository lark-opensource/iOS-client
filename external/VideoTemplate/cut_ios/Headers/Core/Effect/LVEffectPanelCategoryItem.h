//
//  LVEffectPanelCategoryItem.h
//  LVTemplate
//
//  Created by lxp on 2020/2/19.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/IESCategoryModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LVEffectPanelCategoryItemPrototype <NSObject>
@property(nonatomic, copy, readonly) NSString *categoryId;
@property(nonatomic, copy, readonly) NSString *categoryName; // 分类名，例如热门
@property(nonatomic, copy, readonly) NSString *categoryKey; // 分类名，例如hot
//普通状态图标
@property(nonatomic, copy, readonly) NSArray<NSString *> *normalIconUrls;
//选中状态图标
@property(nonatomic, copy, readonly) NSArray<NSString *> *selectedIconUrls;
@end

@interface LVEffectPanelCategoryItem : NSObject

@property (nullable, nonatomic, readonly) IESCategoryModel *categoryModel;

- (instancetype)initWithCategoryModel:(nullable IESCategoryModel *)categoryModel;

@end

NS_ASSUME_NONNULL_END
