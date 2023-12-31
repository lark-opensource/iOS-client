//
//  ACCVideoEditBottomControlRoundLayout.m
//  CameraClient-Pods-AwemeCore
//
//  Created by ZZZ on 2021/9/28.
//

#import "ACCVideoEditBottomControlRoundLayout.h"
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/ACCEditViewContainer.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIDevice+ACCHardware.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCVideoEditBottomControlRoundLayout ()

@property (nonatomic, copy) NSArray<NSNumber *> *types;
@property (nonatomic, copy) NSArray<UIButton *> *buttons;
@property (nonatomic, strong) UIView *blackView;

@end

@implementation ACCVideoEditBottomControlRoundLayout

@synthesize originY;
@synthesize delegate;

- (UIButton *)buttonWithType:(ACCVideoEditFlowBottomItemType)type
{
    return [self.buttons btd_find:^BOOL(UIButton *obj) {
        return obj.tag == type;
    }];
}

- (NSArray<UIButton *> *)allButtons
{
    return self.buttons;
}

- (void)updateWithTypes:(nullable NSArray<NSNumber *> *)types
             repository:(nullable AWEVideoPublishViewModel *)repository
          viewContainer:(nullable id <ACCEditViewContainer>)viewContainer
{
    if (types.count == 0) {
        return;
    }
    
    if (self.types && types && [self.types isEqualToArray:types]) {
        return;
    }
    
    for (UIView *view in self.buttons) {
        [view removeFromSuperview];
    }
    [self.blackView removeFromSuperview];
    
    const CGFloat padding = 12;
    const CGFloat mid = 6;
    const CGFloat height = acc_bottomPanelButtonHeight();
    const CGFloat bigIconWidth = 44;
    const CGFloat bigButtonWidth = 72;
    
    CGFloat startX = padding;
    CGFloat endX = ACC_SCREEN_WIDTH - padding;
    NSMutableArray *remainTypes = [types mutableCopy];
    
    ACCAnimatedButton *leftSmallItem = nil;
    ACCAnimatedButton *rightSmallItem = nil;
    NSMutableArray *buttons = [NSMutableArray array];
    
    // 样式太多 完全不知道下面写了什么
    // 参考 https://bytedance.feishu.cn/sheets/shtcn5aYBm9sG6kEXm2TnEGxVve
    if ([self p_containsLeftSmallItem:types]) {
        ACCVideoEditFlowBottomItemType type = [types.firstObject integerValue];
        ACCAnimatedButton *view = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        view.tag = type;
        view.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-7, 0, -7, 0);
        
        // icon
        {
            ACCVideoEditFlowBottomItemColor color = [self p_fullDisplay] ? ACCVideoEditFlowBottomItemColorGray : ACCVideoEditFlowBottomItemColorBlack;
            ACCAnimatedButton *fakeBackgroundView = acc_bottomPanelButtonCreate(color);
            fakeBackgroundView.layer.cornerRadius = bigIconWidth / 2;
            fakeBackgroundView.userInteractionEnabled = NO;
            [view addSubview:fakeBackgroundView];
            ACCMasMaker(fakeBackgroundView, {
                make.left.equalTo(fakeBackgroundView.superview).inset(padding);
                make.centerY.equalTo(fakeBackgroundView.superview);
                make.size.mas_equalTo(CGSizeMake(bigIconWidth, bigIconWidth));
            });
            
            UIImage *image = nil;
            if (type == ACCVideoEditFlowBottomItemSaveDraft) {
                image = ACCResourceImage(@"edit_bottom_icon_save_draft_big");
            } else if (type == ACCVideoEditFlowBottomItemSaveAlbum) {
                image = ACCResourceImage(@"edit_bottom_icon_save_album_big");
            }
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            [fakeBackgroundView addSubview:imageView];
            ACCMasMaker(imageView, {
                make.left.right.top.bottom.equalTo(imageView.superview);
            });
        }
        
        leftSmallItem = view;
        [remainTypes btd_removeObjectAtIndex:0];
        startX = padding + bigIconWidth + mid;
    }
    
    if ([self p_containsRightSmallItem:types]) {
        ACCVideoEditFlowBottomItemType type = [types.lastObject integerValue];
        ACCAnimatedButton *view = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        view.tag = type;
        view.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-7, 0, -7, 0);
        
        // icon
        {
            ACCAnimatedButton *fakeBackgroundView = acc_bottomPanelButtonCreate(ACCVideoEditFlowBottomItemColorRed);
            fakeBackgroundView.layer.cornerRadius = bigIconWidth / 2;
            fakeBackgroundView.userInteractionEnabled = NO;
            [view addSubview:fakeBackgroundView];
            ACCMasMaker(fakeBackgroundView, {
                make.right.equalTo(fakeBackgroundView.superview).inset(padding);
                make.centerY.equalTo(fakeBackgroundView.superview);
                make.size.mas_equalTo(CGSizeMake(bigIconWidth, bigIconWidth));
            });
            
            UIImage *image = ACCResourceImage(@"edit_bottom_icon_next_white");
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            [fakeBackgroundView addSubview:imageView];
            ACCMasMaker(imageView, {
                make.left.right.top.bottom.equalTo(imageView.superview);
            });
        }
        
        rightSmallItem = view;
        [remainTypes btd_removeObjectAtIndex:remainTypes.count - 1];
        endX = ACC_SCREEN_WIDTH - padding - bigIconWidth - mid;
    }
    
    [remainTypes enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        ACCVideoEditFlowBottomItemType type = obj.integerValue;
        NSString *icon = @"";
        ACCVideoEditFlowBottomItemColor color = ACCVideoEditFlowBottomItemColorWhite;
        if (type == ACCVideoEditFlowBottomItemPublish) {
            if ([types containsObject:@(ACCVideoEditFlowBottomItemNext)] &&
                [types containsObject:@(ACCVideoEditFlowBottomItemShareIM)]) {
                icon = @"edit_bottom_icon_publish_white";
                color = ACCVideoEditFlowBottomItemColorBlack;
            } else {
                icon = @"edit_bottom_icon_publish_black";
                color = ACCVideoEditFlowBottomItemColorWhite;
            }
        } else if (type == ACCVideoEditFlowBottomItemNext) {
            icon = nil;
            color = ACCVideoEditFlowBottomItemColorRed;
        } else if (type == ACCVideoEditFlowBottomItemShareIM) {
            icon = @"edit_bottom_icon_send_white";
            color = ACCVideoEditFlowBottomItemColorBlack;
        } else if (type == ACCVideoEditFlowBottomItemPublishWish) {
            color = ACCVideoEditFlowBottomItemColorRed;
        }
        
        if ([self p_fullDisplay]) {
            icon = [icon stringByReplacingOccurrencesOfString:@"_black" withString:@"_white"];
            color = ACCVideoEditFlowBottomItemColorGray;
        }
        
        ACCAnimatedButton *button = acc_bottomPanelButtonCreate(color);
        button.layer.cornerRadius = type == ACCVideoEditFlowBottomItemPublishWish ? 2.f : height / 2;
        button.tag = type;
        CGFloat moreHitX = -mid / 2;
        CGFloat moreHitY = -7;
        button.acc_hitTestEdgeInsets = UIEdgeInsetsMake(moreHitY, moreHitX, moreHitY, moreHitX);
        [button setTitle:acc_bottomPanelButtonTitle(type) forState:UIControlStateNormal];
        [button setImage:ACCResourceImage(icon ?: @"") forState:UIControlStateNormal];
        
        CGFloat width = (endX - startX - (remainTypes.count - 1) * mid) / remainTypes.count;
        button.frame = CGRectMake(startX + (width + mid) * idx, self.originY, width, height);
        [viewContainer.containerView addSubview:button];
        
        [buttons btd_addObject:button];
    }];
    
    // 由于要优先响应 这两个最后再加
    if (leftSmallItem) {
        [viewContainer.containerView addSubview:leftSmallItem];
        leftSmallItem.frame = CGRectMake(0, self.originY, bigButtonWidth, height);
        [buttons btd_addObject:leftSmallItem];
    }
    if (rightSmallItem) {
        [viewContainer.containerView addSubview:rightSmallItem];
        rightSmallItem.frame = CGRectMake(ACC_SCREEN_WIDTH - bigButtonWidth, self.originY, bigButtonWidth, height);
        [buttons btd_addObject:rightSmallItem];
    }
    
    for (UIButton *button in buttons) {
        ACCVideoEditFlowBottomItemType type = button.tag;
        @weakify(self);
        button.tap_block = ^{
            @strongify(self);
            [self.delegate bottomControlLayout:self didTapWithType:type];
        };
    }
    
    self.types = types;
    self.buttons = buttons;
    
    if (![self p_fullDisplay]) {
        UIButton *anyButton = self.buttons.firstObject;
        if (anyButton && anyButton.superview) {
            self.blackView = [[UIView alloc] init];
            self.blackView.userInteractionEnabled = NO;
            self.blackView.backgroundColor = UIColor.blackColor;
            [anyButton.superview insertSubview:self.blackView belowSubview:anyButton];
            ACCMasMaker(self.blackView, {
                make.left.right.bottom.equalTo(self.blackView.superview);
                make.top.equalTo(anyButton).offset(-6);
            });
        }
    }
}

- (BOOL)p_containsLeftSmallItem:(NSArray<NSNumber *> *)types
{
    ACCVideoEditFlowBottomItemType leftType = [types.firstObject integerValue];
    return leftType == ACCVideoEditFlowBottomItemSaveDraft || leftType == ACCVideoEditFlowBottomItemSaveAlbum;
}

- (BOOL)p_containsRightSmallItem:(NSArray<NSNumber *> *)types
{
    ACCVideoEditFlowBottomItemType rightType = [types.lastObject integerValue];
    if (rightType != ACCVideoEditFlowBottomItemNext) {
        return NO;
    }
    if ([self p_containsLeftSmallItem:types]) {
        return types.count >= 4;
    }
    return types.count >= 3;
}

- (BOOL)p_fullDisplay
{
    if ([UIDevice acc_isIPad]) {
        return YES;
    }
    if ([UIDevice acc_isIPhoneX] || [UIDevice acc_isIPhoneXsMax]) {
        return NO;
    }
    return YES;
}

@end
