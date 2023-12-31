//
//  ACCToolBarSortDataSource.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/7.
//

#import <Foundation/Foundation.h>

#import <CreativeKit/ACCBarItemContainerView.h>

#import "ACCToolBarContainerPageEnum.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCToolBarSortDataSource : NSObject<ACCBarItemSortDataSource>

- (nonnull NSArray *)barItemSortArrayWithPage:(ACCToolBarContainerPageEnum)page;
- (nullable NSArray *)barItemRedPointArrayWithPage:(ACCToolBarContainerPageEnum)page;
- (NSArray *)typeBItemsArray;
- (NSArray *)typeAItemsArray;
@end

NS_ASSUME_NONNULL_END
