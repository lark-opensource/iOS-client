//
//  ACCEditTRToolBarContainer.h
//  CameraClient
//
//  Created by wishes on 2020/6/2.
//

#import <Foundation/Foundation.h>
#import "ACCEditBarItemContainerView.h"

@class AWEEditActionItemView;

NS_ASSUME_NONNULL_BEGIN

typedef void(^EditToolBarMoreClickEvent)(BOOL isFold);

@protocol ACCEditTRBarItemContainerView <ACCEditBarItemContainerView>

@property (nonatomic, strong) NSNumber *maxHeightValue;
@property (nonatomic, strong, nullable, readonly) AWEEditActionItemView *moreItemView;

- (void)setMoreTouchUpEvent:(EditToolBarMoreClickEvent)event;

- (void)resetUpBarContentView;

- (void)resetFoldState;

@end

NS_ASSUME_NONNULL_END
