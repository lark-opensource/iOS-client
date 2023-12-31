//
//  AWEEditBottomActionItemView.h
//  Pods
//
//  Created by resober on 2019/5/8.
//

#import <UIKit/UIKit.h>
#import "AWEEditAndPublishViewData.h"
#import "AWEEditAndPublishViewActionContainerModel.h"

NS_ASSUME_NONNULL_BEGIN

extern const CGFloat AWEEditActionItemButtonSideLength;

@interface AWEEditActionItemView : UIView
@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) UIButton *button;
@property (nonatomic, strong, readonly) UIView *buttonBgView;
@property (nonatomic, strong, readonly) UILabel *label;
@property (nonatomic, strong, readonly) AWEEditAndPublishViewData *itemData;
@property (nonatomic, strong, readonly) AWEEditAndPublishViewActionContainerModel *container;
@property (nonatomic, assign) BOOL enable;
@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, strong) void (^itemViewDidClicked)(AWEEditActionItemView *itemView);
- (instancetype)initWithItemData:(AWEEditAndPublishViewData *)itemData NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (void)updateActionView:(UIView *)actionView;

@end

NS_ASSUME_NONNULL_END
