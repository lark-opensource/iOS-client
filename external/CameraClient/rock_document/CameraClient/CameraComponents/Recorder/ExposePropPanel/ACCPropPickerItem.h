//
//  ACCPropPickerItem.h
//  CameraClient
//
//  Created by Shen Chen on 2020/4/20.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/EffectPlatform.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCPropPickerItemType) {
    ACCPropPickerItemTypeHome = 0,
    ACCPropPickerItemTypeEffect,
    ACCPropPickerItemTypeMoreFavor,
    ACCPropPickerItemTypeMoreHot,
    ACCPropPickerItemTypePlaceholder,
};

typedef NS_ENUM(NSUInteger, ACCPropPickerItemCategoryType) {
    ACCPropPickerItemCategoryTypeHot = 0,
    ACCPropPickerItemCategoryTypeFavor,
    ACCPropPickerItemCategoryTypeRecognition,
    ACCPropPickerItemCategoryTypeFlower
};

@interface ACCPropPickerItem : NSObject <NSCopying>
@property (nonatomic, assign) ACCPropPickerItemType type;
@property (nonatomic, assign) ACCPropPickerItemCategoryType categoryType;

@property (nonatomic, strong, nullable) IESEffectModel *effect;

- (instancetype)initWithType:(ACCPropPickerItemType)type;
- (instancetype)initWithType:(ACCPropPickerItemType)type effect:(IESEffectModel * _Nullable)effect;
@end

NS_ASSUME_NONNULL_END
