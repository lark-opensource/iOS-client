//
//  ACCFilterUtils.m
//  CameraClient
//
//  Created by Haoyipeng on 2020/2/11.
//

#import "ACCFilterUtils.h"
#import <CreationKitInfra/ACCRTLProtocol.h>

@implementation ACCFilterUtils

+ (IESEffectModel *)prevFilterOfFilter:(IESEffectModel *)filter filterArray:(NSArray *)filterArray
{
    if (filterArray.count == 0) {
        return nil;
    }

    NSUInteger currentFilterIndex = [filterArray indexOfObject:filter];
    if (currentFilterIndex == NSNotFound) {
        currentFilterIndex = 0;
    }
    NSInteger step = [ACCRTL() isRTL] ? 1 : -1;
    NSUInteger prevFilterIndex = (currentFilterIndex + step + filterArray.count) % filterArray.count;
    return filterArray[prevFilterIndex];
}

+ (IESEffectModel *)nextFilterOfFilter:(IESEffectModel *)filter filterArray:(NSArray *)filterArray
{
    if (filterArray.count == 0) {
        return nil;
    }

    NSUInteger currentFilterIndex = [filterArray indexOfObject:filter];
    if (currentFilterIndex == NSNotFound) {
        currentFilterIndex = 0;
    }
    NSInteger step = [ACCRTL() isRTL] ? -1 : 1;
    NSUInteger nextFilterIndex = (currentFilterIndex + step + filterArray.count) % filterArray.count;
    return filterArray[nextFilterIndex];
}

@end
