//
//  ACCFilterDefine.m
//  CameraClient
//
//  Created by 郝一鹏 on 2020/1/13.
//

#import "ACCFilterDefine.h"

@implementation ACCFilterModel

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[ACCFilterModel class]]) {
        return NO;
    }

    return [self isEqualToFilter:(ACCFilterModel *)object];
}

- (BOOL)isEqualToFilter:(ACCFilterModel *)filter
{
    if (!filter) {
      return NO;
    }

    if (![self.filterID isEqualToString:filter.filterID]) {
        return NO;
    }

    if (![self.filterName isEqualToString:filter.filterName]) {
        return NO;
    }

    return [self.originData isEqual:filter.originData];
}

- (NSUInteger)hash
{
    return self.filterName.hash ^ self.filterName.hash;
}

@end
