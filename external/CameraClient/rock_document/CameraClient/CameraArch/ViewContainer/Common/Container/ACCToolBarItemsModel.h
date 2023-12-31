//
//  ACCToolBarItemsModel.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/4.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCBarItem.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCToolBarItemsModel : NSObject

- (BOOL)addBarItem:(ACCBarItem *)item;
- (void)removeBarItem:(void *)itemId;
- (ACCBarItem *)barItemWithItemId:(void *)itemId;
- (NSArray<ACCBarItem *> *)barItems;

@end

NS_ASSUME_NONNULL_END
