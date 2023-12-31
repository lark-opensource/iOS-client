//
//  ACCToolBarAdapterUtils.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/7/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCToolBarAdapterUtils : NSObject

+ (BOOL) useAdaptedToolBarContainer;

+ (BOOL) useToolBarFoldStyle;

+ (BOOL) useToolBarPageStyle;

+ (BOOL) showAllItemsPageStyle;

+ (BOOL) modifyOrder;

@end

NS_ASSUME_NONNULL_END
