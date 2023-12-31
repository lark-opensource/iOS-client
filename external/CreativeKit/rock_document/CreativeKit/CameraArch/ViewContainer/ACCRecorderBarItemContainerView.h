//
//  ACCRecorderBarItemContainerView.h
//  CreativeKit-Pods-Aweme
//
//  Created by Liu Deping on 2021/3/22.
//

#import <Foundation/Foundation.h>
#import "ACCBarItemContainerView.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCRecorderToolBarFoldOrExpandBlock)(BOOL isToFolded);

@protocol ACCRecorderBarItemContainerView <ACCBarItemContainerView>

- (id<ACCBarItemCustomView>)viewWithBarItemID:(void *)itemId;

@optional
- (void)setFoldOrExpandBlock:(ACCRecorderToolBarFoldOrExpandBlock)block;
- (void)addMaskViewAboveToolBar:(UIView *)maskView;

@end

NS_ASSUME_NONNULL_END
