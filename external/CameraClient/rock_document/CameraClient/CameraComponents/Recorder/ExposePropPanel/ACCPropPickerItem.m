//
//  ACCPropPickerItem.m
//  CameraClient
//
//  Created by Shen Chen on 2020/4/20.
//

#import "ACCPropPickerItem.h"

@implementation ACCPropPickerItem

- (instancetype)initWithType:(ACCPropPickerItemType)type {
    return [self initWithType:type effect:nil];
}

- (instancetype)initWithType:(ACCPropPickerItemType)type effect:(IESEffectModel * _Nullable)effect
{
    self = [super init];
    if (self) {
        self.type = type;
        self.effect = effect;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    ACCPropPickerItem *item = [[ACCPropPickerItem alloc] initWithType:self.type effect:self.effect];
    item.categoryType = self.categoryType;
    return item;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:ACCPropPickerItem.class]) {
        return NO;
    }
    ACCPropPickerItem *item = (ACCPropPickerItem *)object;
    if (self.type == ACCPropPickerItemTypeHome || self.type == ACCPropPickerItemTypeMoreHot || self.type == ACCPropPickerItemTypeMoreFavor) {
        return self.type == item.type;
    }
    if (self.categoryType != item.categoryType) {
        return NO;
    }
    return [self.effect.effectIdentifier isEqualToString:item.effect.effectIdentifier];
}

@end
