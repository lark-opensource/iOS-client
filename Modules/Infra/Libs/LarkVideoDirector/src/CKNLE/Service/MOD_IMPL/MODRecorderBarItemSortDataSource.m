//
//  MODRecorderBarItemSortDataSource.m
//  CameraClient
//
//  Created by haoyipeng on 2022/1/20.
//  Copyright © 2022 chengfei xiao. All rights reserved.
//

#import "MODRecorderBarItemSortDataSource.h"
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import <CameraClient/ACCRecorderToolBarDefinesD.h>

@implementation MODRecorderBarItemSortDataSource

- (NSArray *)barItemSortArray
{
    return @[
      [NSValue valueWithPointer:ACCRecorderToolBarSwapContext],
      [NSValue valueWithPointer:ACCRecorderToolBarFilterContext],
      [NSValue valueWithPointer:ACCRecorderToolBarModernBeautyContext],
      [NSValue valueWithPointer:ACCRecorderToolBarFlashContext],
    ];
}

@end
