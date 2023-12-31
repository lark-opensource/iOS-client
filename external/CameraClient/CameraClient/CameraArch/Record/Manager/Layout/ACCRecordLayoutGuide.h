//
//  ACCRecordLayoutGuide.h
//  CameraClient
//
//  Created by Shen Chen on 2020/4/12.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCRecordLayoutGuideProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecordLayoutGuide : NSObject <ACCRecordLayoutGuideProtocol>

@property (nonatomic, weak) UIView *containerView;

- (UIEdgeInsets)hitTestEdgeInsets;

- (CGFloat)recordButtonSwitchViewHeight;

- (CGFloat)recordButtonSwitchViewBottomOffset;

- (CGFloat)recordButtonSwitchViewCenterY;

- (CGFloat)sideButtonHeight;

- (CGFloat)sideButtonWidth;

- (CGFloat)bottomCircleButtonHeight;

- (CGFloat)bottomCircleButtonWidth;

- (CGFloat)sideCircleButtonHeight;

- (CGFloat)sideCircleButtonWidth;

- (CGFloat)bottomSideButtonMargin;

- (CGFloat)bottomSideButtonCenterXOffset;

- (CGFloat)bottomSideButtonSwitchViewSpace;

- (CGFloat)sideButtonCenterXOffset;

- (CGFloat)sideButtonLabelSpace;

- (CGFloat)deleteButtonWidth;

- (CGFloat)deleteButtonHeight;

- (CGFloat)bottomDeleteButtonHeight;

- (CGFloat)bottomDeleteButtonIconHeight;

- (CGFloat)bottomDeleteButtonIconWidth;

- (CGFloat)bottomDeleteButtonIconTitleSpace;

- (CGFloat)completeButtonWidth;

- (CGFloat)completeButtonHeight;

- (CGFloat)recordFlowControlEvenSpace;

- (CGFloat)propPanelHeight;

- (CGFloat)speedControlMargin;

- (CGFloat)speedControlHeight;

- (CGFloat)speedControlRecordBottomSpace;

- (CGFloat)speedControlTop;

- (CGFloat)propBubbleHeight;

- (CGFloat)propBubbleWidth;

- (CGFloat)propTrayViewMargin;

- (CGFloat)propTrayViewHeight;

- (CGFloat)commerceEnterViewHeight;

- (CGFloat)commerceEnterViewBottomSpace;

@end

NS_ASSUME_NONNULL_END
