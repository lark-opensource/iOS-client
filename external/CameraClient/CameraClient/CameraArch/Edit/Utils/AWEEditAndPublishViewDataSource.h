//
//  AWEEditAndPublishViewDataSource.h
//  AWEStudio
//
//  Created by hanxu on 2018/11/16.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    AWEEditPagePublishTypeNormal,
    AWEEditPagePublishTypeStory,
    AWEEditPagePublishTypeIM,
    AWEEditPagePublishTypeIMEdit, // IM 相册编辑
} AWEEditPagePublishType;

@class AWEEditAndPublishViewData;

@protocol AWEEditAndPublishViewDataSource <NSObject>

@optional
//右上角
- (NSArray<AWEEditAndPublishViewData *> *)editAndPublishViewRightTopData;

//左下角
- (NSArray<AWEEditAndPublishViewData *> *)editAndPublishViewLeftBottomData;

//是否显示更多按钮
- (BOOL)editAndPublishViewNeedMoreButton;

//是否显示发布相关内容
- (BOOL)editAndPublishViewShowPublish;

- (AWEEditPagePublishType)publishType;

//调整右上按钮距离顶部的间距
- (CGFloat)rightTopOffset;

- (UIEdgeInsets)rightTopContainerInset; ///<右上角容器边距
- (UIEdgeInsets)leftBottomContainerInset; ///<左下角容器边距

- (CGFloat)rightTopItemSpacing; ///<右上角按钮间距
- (CGFloat)leftBottomItemSpacing; ///<左下角按钮间距

//返回按钮的文案
- (NSString *)editAndPublishViewBackButtonTitle;
//返回按钮图片
- (UIImage *)editAndPublishViewBackButtonImage;
//点击返回按钮
- (void)editAndPublishViewBackButtonClicked;

// 点击废片拯救
- (void)editAndPublishViewVideoHDRButtonClicked:(UIButton *)button;

//点击下一步按钮(可能是发布,可能是下一步)
- (void)editAndPublishViewNextButtonClicked;


//发布按钮的图片
- (NSString *)publishIconUrl;

- (void)editAndPublishViewPauseButtonClicked;

- (void)onEditFinishButtonClicked;

//昵称
- (NSString *)nickname;
- (void)syncToFriendsButtonClicked;
- (void)sendToCurrentFriendButtonClicked;
- (void)sendWatchOnceButtonClicked;
- (void)nextStepButtonClicked;

@end

