//
//  AWEEditActionContainerViewLayout.m
//  Pods
//
//  Created by 赖霄冰 on 2019/7/8.
//

#import "AWEEditActionContainerViewLayout.h"

@implementation AWEEditActionContainerViewLayout

- (id)copyWithZone:(nullable NSZone *)zone {
    AWEEditActionContainerViewLayout *copy = [AWEEditActionContainerViewLayout new];
    copy.itemSize = self.itemSize;
    copy.itemSpacing = self.itemSpacing;
    copy.containerInset = self.containerInset;
    copy.contentInset = self.contentInset;
    copy.direction = self.direction;
    return copy;
}

@end
