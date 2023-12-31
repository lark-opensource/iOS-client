//
//  ACCVideoEditBottomControlService.h
//  CameraClient
//
//  Created by ZZZ on 2021/9/27.
//

#ifndef ACCVideoEditBottomControlService_h
#define ACCVideoEditBottomControlService_h

typedef NS_ENUM(NSInteger, ACCVideoEditFlowBottomItemType) {
    ACCVideoEditFlowBottomItemPublish = 1, // 发日常
    ACCVideoEditFlowBottomItemNext, // 下一步
    ACCVideoEditFlowBottomItemShareIM, // 私信给
    ACCVideoEditFlowBottomItemSaveDraft, // 存草稿
    ACCVideoEditFlowBottomItemSaveAlbum, // 存本地
    ACCVideoEditFlowBottomItemPublishWish // 发心愿
};

@protocol ACCVideoEditBottomControlSubscriber <NSObject>

@optional

- (void)editBottomPanelDidTapType:(ACCVideoEditFlowBottomItemType)type;

@end

@protocol ACCVideoEditBottomControlService <NSObject>

@required

- (void)addSubscriber:(nonnull id <ACCVideoEditBottomControlSubscriber>)subscriber;

- (BOOL)enabled;

// 暂时先通过外部设置 之后可以把相关逻辑移到内部
- (void)updatePublishButtonTitle:(nullable NSString *)title;
- (void)hidePublishButton;
- (void)hideNextButton;

- (UIButton *)publishButton;
- (UIButton *)nextButton;
- (NSArray *)allButtons;

- (void)updatePanelIfNeeded;

@end

#endif /* ACCVideoEditBottomControlService_h */
