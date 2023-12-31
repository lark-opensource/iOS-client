//
//  AWECaptionBottomView.h
//  Pods
//
//  Created by lixingdong on 2019/8/29.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import "AWECaptionTableViewCell.h"
#import "AWEStoryToolBar.h"

typedef NS_ENUM(NSInteger, AWECaptionBottomViewType) {
    AWECaptionBottomViewTypeLoading = 0,
    AWECaptionBottomViewTypeRetry   = 1,
    AWECaptionBottomViewTypeEmpty   = 2,
    AWECaptionBottomViewTypeCaption = 3,
    AWECaptionBottomViewTypeStyle   = 4
};

FOUNDATION_EXPORT CGFloat AWEAutoCaptionsBottomViewHeigth;
FOUNDATION_EXPORT CGFloat kAWECaptionBottomTableViewCellHeight;
FOUNDATION_EXPORT CGFloat kAWECaptionBottomTableViewContentInsetTop;
FOUNDATION_EXPORT CGFloat kAWECaptionBottomTableViewHighlightOffset;

@protocol AWECaptionScrollFlowLayoutDelegate <NSObject>

- (void)collectionViewScrollStopAtIndex:(NSInteger)index;

@end

@interface AWECaptionScrollFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, weak) id<AWECaptionScrollFlowLayoutDelegate>delegate;

@end

@interface AWECaptionBottomView : UIView

@property (nonatomic, copy) void (^refreshUICompletion)(AWECaptionBottomViewType type);

@property (nonatomic, strong, readonly) UIButton *cancelButton;         // 识别过程中取消识别
@property (nonatomic, strong, readonly) UIButton *retryButton;          // 重试
@property (nonatomic, strong, readonly) UIButton *quitButton;           // 退出字幕识别
@property (nonatomic, strong, readonly) UIButton *emptyCancelButton;    // 退出字幕识别

// CaptionUI
@property (nonatomic, strong) AWECaptionScrollFlowLayout *layout;
@property (nonatomic, strong, readonly) UILabel *captionTitle; // 字幕title
@property (nonatomic, strong, readonly) UIView *separateLine;
@property (nonatomic, strong, readonly) ACCAnimatedButton *styleButton; // 字幕样式设置
@property (nonatomic, strong, readonly) ACCAnimatedButton *deleteButton;// 删除字幕
@property (nonatomic, strong, readonly) ACCAnimatedButton *editButton; // 编辑字幕

// StyleUI
@property (nonatomic, strong, readonly) UIView *styleSeparateLine;
@property (nonatomic, strong, readonly) ACCAnimatedButton *styleCancelButton;   // 样式取消
@property (nonatomic, strong, readonly) ACCAnimatedButton *styleSaveButton;     // 样式保存
@property (nonatomic, strong, readonly) AWEStoryToolBar *styleToolBar;          // 样式

@property (nonatomic, strong, readonly) UICollectionView *captionCollectionView;  // 字幕列表

// BgView
@property (nonatomic, strong, readonly) UIView *loadingBgView;
@property (nonatomic, strong, readonly) UIView *retryBgView;
@property (nonatomic, strong, readonly) UIView *emptyBgView;
@property (nonatomic, strong, readonly) UIView *captionBgView;
@property (nonatomic, strong, readonly) UIView *styleBgView;

@property (nonatomic, weak) id<AWECaptionScrollFlowLayoutDelegate> layoutDelegate;

@property (nonatomic, assign) NSInteger currentRow;

- (void)refreshUIWithType:(AWECaptionBottomViewType)type;

- (void)refreshCellHighlightWithRow:(NSInteger)row;

- (UICollectionView *)createCaptionCollectionView;

- (void)setupUI;

@end
