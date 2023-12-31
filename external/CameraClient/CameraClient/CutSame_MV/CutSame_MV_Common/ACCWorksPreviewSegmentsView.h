//
//  AWEWorksPreviewSegmentsView.h
//  AWEStudio-Pods-Aweme
//
//  Created by Pinka on 2020/3/15.
//

#import <UIKit/UIKit.h>
#import "ACCVideoListCell.h"
#import "ACCButton.h"
#import "ACCCutSameWorksPreviewBottomViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^AWEWorksPreviewSegmentsViewSelectBlock)(NSInteger idx);

@interface ACCWorksPreviewSegmentsView : UIView<ACCCutSameWorksPreviewBottomViewProtocol>

@property (nonatomic, copy  ) NSArray<UIImage *> *thumbnailImages;
@property (nonatomic, copy  ) NSArray<NSNumber *> *thumbnailTimes;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) ACCButton *editTextButton;

@property (nonatomic, strong) UIImageView *cursorView;

@property (nonatomic, strong) UICollectionView *videosCollectionView;
@property (nonatomic, assign) NSInteger currentVideoIndex;

@property (nonatomic, assign) NSTimeInterval panelAnimationDuration;

@property (nonatomic, copy  ) AWEWorksPreviewSegmentsViewSelectBlock selectCallback;

+ (CGFloat)defaultHeight;

+ (CGSize)thumbnailPixelSize;

- (instancetype)initWithFrame:(CGRect)frame textEditEnable:(BOOL)textEditEnable;

- (void)updateCursorWithIndex:(NSUInteger)index animated:(BOOL)animated;

- (void)hideCursor;

- (void)snapshotForPanelTransitionAnimation:(ACCVideoListCell *)listCell heightDiff:(CGFloat)heightDiff;

- (void)hidePanelWithAnimationWithCoverFrame:(CGRect)targetCoverFrame;

- (void)showPanelWithAnimationWithCompletion:(dispatch_block_t)completion;

- (void)animateForShowCropViewWithSelectedIndex:(NSUInteger)index isImage:(BOOL)isImage;

- (void)animateForHideCropView;

@end

NS_ASSUME_NONNULL_END
