//
//  ACCVideoEditBottomControlRectangleLayout.m
//  CameraClient-Pods-AwemeCore
//
//  Created by ZZZ on 2021/9/28.
//

#import "ACCVideoEditBottomControlRectangleLayout.h"
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/ACCEditViewContainer.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CameraClient/ACCRepoQuickStoryModel.h>

CGFloat acc_bottomPanelButtonHeight(void)
{
    return 44;
}

NSString * acc_bottomPanelButtonTitle(ACCVideoEditFlowBottomItemType type)
{
    static NSDictionary<NSNumber *, NSString *> *titles = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary<NSNumber *, NSString *> *dictionary = [NSMutableDictionary dictionary];
        dictionary[@(ACCVideoEditFlowBottomItemPublish)] = @"发日常";
        dictionary[@(ACCVideoEditFlowBottomItemNext)] = @"下一步";
        dictionary[@(ACCVideoEditFlowBottomItemShareIM)] = @"私信给";
        dictionary[@(ACCVideoEditFlowBottomItemSaveDraft)] = @"存草稿";
        dictionary[@(ACCVideoEditFlowBottomItemSaveAlbum)] = @"存本地";
        dictionary[@(ACCVideoEditFlowBottomItemPublishWish)] = @"发布心愿";
        titles = [dictionary copy];
    });
    return titles[@(type)];
}

ACCAnimatedButton * acc_bottomPanelButtonCreate(ACCVideoEditFlowBottomItemColor color)
{
    ACCAnimatedButton *view = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
    view.layer.cornerRadius = 4;
    view.imageEdgeInsets = UIEdgeInsetsMake(0, -2, 0, 2);
    view.titleLabel.font = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightMedium];
    
    switch (color) {
        case ACCVideoEditFlowBottomItemColorWhite: {
            view.backgroundColor = ACCResourceColor(ACCColorConstTextInverse);
            [view setTitleColor:ACCResourceColor(ACCColorTextReverse) forState:UIControlStateNormal];
            break;
        }
        case ACCVideoEditFlowBottomItemColorBlack: {
            view.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.2];
            [view setTitleColor:ACCResourceColor(ACCColorConstTextInverse) forState:UIControlStateNormal];
            break;
        }
        case ACCVideoEditFlowBottomItemColorRed: {
            view.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary);
            [view setTitleColor:ACCResourceColor(ACCColorConstTextInverse) forState:UIControlStateNormal];
            break;
        }
        case ACCVideoEditFlowBottomItemColorGray: {
            view.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.34];
            [view setTitleColor:ACCResourceColor(ACCColorConstTextInverse) forState:UIControlStateNormal];
            break;
        }
    }
    
    return view;
}

@interface ACCVideoEditBottomControlRectangleLayout ()

@property (nonatomic, copy) NSArray<NSNumber *> *types;
@property (nonatomic, copy) NSArray<UIButton *> *buttons;

@end

@implementation ACCVideoEditBottomControlRectangleLayout

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
    
    const CGFloat x = 6;
    const CGFloat mid = 6;
    const CGFloat total_space = x * 2 + mid * (types.count - 1);
    const CGFloat width = (ACC_SCREEN_WIDTH - total_space) / types.count;
    
    @weakify(self);
    NSMutableArray *buttons = [NSMutableArray array];
    [types enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        ACCVideoEditFlowBottomItemType type = obj.integerValue;
        ACCVideoEditFlowBottomItemColor color = ACCVideoEditFlowBottomItemColorWhite;
        if (type == ACCVideoEditFlowBottomItemNext) {
            color = ACCVideoEditFlowBottomItemColorRed;
        }
        ACCAnimatedButton *button = acc_bottomPanelButtonCreate(color);
        button.tag = type;
        CGFloat moreHitX = -mid / 2;
        CGFloat moreHitY = -7;
        button.acc_hitTestEdgeInsets = UIEdgeInsetsMake(moreHitY, moreHitX, moreHitY, moreHitX);
        [button setTitle:acc_bottomPanelButtonTitle(type) forState:UIControlStateNormal];
        [button setImage:[self p_imageWithType:type] forState:UIControlStateNormal];
        
        button.tap_block = ^{
            @strongify(self);
            [self.delegate bottomControlLayout:self didTapWithType:type];
        };
        
        CGRect frame = CGRectMake(0, self.originY, width, acc_bottomPanelButtonHeight());
        frame.origin.x = x + (width + mid) * idx;
        button.frame = frame;
        [viewContainer.containerView addSubview:button];
        
        [buttons btd_addObject:button];
    }];
    
    self.types = types;
    self.buttons = buttons;
}

- (UIImage *)p_imageWithType:(ACCVideoEditFlowBottomItemType)type
{
    static NSDictionary<NSNumber *, NSString *> *images = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary<NSNumber *, NSString *> *dictionary = [NSMutableDictionary dictionary];
        dictionary[@(ACCVideoEditFlowBottomItemPublish)] = @"edit_bottom_icon_publish_black";
        dictionary[@(ACCVideoEditFlowBottomItemShareIM)] = @"edit_bottom_icon_send_black";
        dictionary[@(ACCVideoEditFlowBottomItemSaveDraft)] = @"edit_bottom_icon_save_draft";
        images = [dictionary copy];
    });
    return ACCResourceImage(images[@(type)]);
}

@end
