//
//  ACCVideoEditBottomControlLayout.h
//  CameraClient
//
//  Created by ZZZ on 2021/9/28.
//

#ifndef ACCVideoEditBottomControlLayout_h
#define ACCVideoEditBottomControlLayout_h

#import <Foundation/Foundation.h>
#import "ACCVideoEditBottomControlService.h"

@class ACCAnimatedButton;
@class AWEVideoPublishViewModel;

@protocol ACCEditViewContainer;
@protocol ACCVideoEditBottomControlLayout;

typedef NS_ENUM(NSInteger, ACCVideoEditFlowBottomItemColor) {
    ACCVideoEditFlowBottomItemColorWhite = 0, // 白底黑字
    ACCVideoEditFlowBottomItemColorBlack, // 黑底白字
    ACCVideoEditFlowBottomItemColorRed, // 红底白字
    ACCVideoEditFlowBottomItemColorGray // 灰底白字
};

UIKIT_EXTERN CGFloat acc_bottomPanelButtonHeight(void);
UIKIT_EXTERN NSString * acc_bottomPanelButtonTitle(ACCVideoEditFlowBottomItemType type);
UIKIT_EXTERN ACCAnimatedButton * acc_bottomPanelButtonCreate(ACCVideoEditFlowBottomItemColor color);

@protocol ACCVideoEditBottomControlLayoutDelegate <NSObject>

@required

- (void)bottomControlLayout:(nullable id <ACCVideoEditBottomControlLayout>)layout didTapWithType:(ACCVideoEditFlowBottomItemType)type;

@end

@protocol ACCVideoEditBottomControlLayout <NSObject>

@required

@property (nonatomic, assign) CGFloat originY;
@property (nonatomic,weak, nullable) id <ACCVideoEditBottomControlLayoutDelegate> delegate;

- (UIButton *)buttonWithType:(ACCVideoEditFlowBottomItemType)type;

- (NSArray<UIButton *> *)allButtons;

- (void)updateWithTypes:(nullable NSArray<NSNumber *> *)types
             repository:(nullable AWEVideoPublishViewModel *)repository
          viewContainer:(nullable id <ACCEditViewContainer>)viewContainer;

@end

#endif /* ACCVideoEditBottomControlLayout_h */
