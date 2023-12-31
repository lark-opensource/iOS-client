//
//  ACCEditTRToolBarContainer.h
//  CameraClient
//
//  Created by wishes on 2020/6/2.
//

#import <Foundation/Foundation.h>
#import "ACCBarItemContainerView.h"
#import "AWEEditActionItemView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditBarItemContainerView <ACCBarItemContainerView>

- (AWEEditActionItemView*)viewWithBarItemID:(nonnull void *)itemId;

@property (nonatomic, weak) UIView *contentView;

@property (nonatomic, assign) ACCBarItemResourceLocation location;

@property (nonatomic, copy) void (^clickCallback)(AWEEditActionItemView *itemView);

@end

NS_ASSUME_NONNULL_END
