//
//  ACCFilterComponent.h
//  ASVE
//
//Created by Hao Yipeng on August 5, 2019
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCFeatureComponent.h>

//message
@class IESEffectModel;

NS_ASSUME_NONNULL_BEGIN
@interface ACCFilterComponent : ACCFeatureComponent

- (NSString *)tabNameForFilter:(nonnull IESEffectModel *)filter;

- (void)handleClickFilterAction;

@end

NS_ASSUME_NONNULL_END
