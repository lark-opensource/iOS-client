//
//  ACCGrootStickerRecognitionView.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/14.
//

#import "ACCGrootStickerRecognitionView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/AWEEditGradientView.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCGrootStickerModel.h"
#import "ACCGrootStickerSelectView.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import "ACCRecognitionGrootConfig.h"

@interface ACCGrootStickerRecognitionView  () <ACCGrootStickerSelectViewDelegate>

@property (nonatomic, strong) ACCGrootStickerView *grootStickerView;
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong) AWEEditGradientView *upperMaskView;
@property (nonatomic, strong) UIView *lowerMaskView;
@property (nonatomic,   weak) UIView *orignalSuperView;
@property (nonatomic, assign) BOOL isEdting;

@property (nonatomic, assign) NSUInteger selectedIndex; // track
@property (nonatomic, strong) ACCGrootStickerSelectView *selectGrootView;
@property (nonatomic, strong) ACCGrootDetailsStickerModel *snapDetailsStickerModel;
@property (nonatomic, strong) ACCGrootDetailsStickerModel *originalDetailsStickerModel;

@end

@implementation ACCGrootStickerRecognitionView
@synthesize grootStickerView = _grootStickerView;

#pragma mark - life cycle
+ (instancetype)editViewWithPublishModel:(AWEVideoPublishViewModel *)publishModel {
     return [[self alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT)
                           publishModel:publishModel];
}

- (instancetype)initWithFrame:(CGRect)frame publishModel:(AWEVideoPublishViewModel *)publishModel {
    if (self = [super initWithFrame:frame]) {
        _publishModel = publishModel;
        [self setup];
    }
    return self;
}

#pragma mark - private

- (void)setup {
    self.lowerMaskView = ({
        UIView *view = [[UIView alloc] init];
        [self addSubview:view];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        [view acc_addSingleTapRecognizerWithTarget:self action:@selector(didClickedTextMaskView)];
        ACCMasMaker(view, {
            make.edges.equalTo(self);
        });
        view.alpha = 0.f;
        view;
    });
    
    self.upperMaskView = ({
        AWEEditGradientView *view = [[AWEEditGradientView alloc] init];
        [self addSubview:view];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.backgroundColor = [UIColor clearColor];
        view.clipsToBounds = YES;
        ACCMasMaker(view, {
            make.top.equalTo(self.mas_top).offset(52.f + ACC_NAVIGATION_BAR_OFFSET);
            make.right.left.bottom.equalTo(self);
        });
        view.alpha = 0.f;
        view;
    });
    
    self.selectGrootView = ({
        CGSize collectionSize = [ACCGrootStickerSelectView adaptionCollectionViewSize];
        CGFloat bottomOffset = ACC_IPHONE_X_BOTTOM_OFFSET > 0 ? ACC_IPHONE_X_BOTTOM_OFFSET : 10;
        CGFloat height = 160 + collectionSize.height + bottomOffset;
        ACCGrootStickerSelectView *view = [[ACCGrootStickerSelectView alloc] initWithFrame:CGRectMake(0, ACC_SCREEN_HEIGHT - height, ACC_SCREEN_WIDTH, height)];
        [self addSubview:view];
        view.backgroundColor = [UIColor whiteColor];
        view.alpha = 0.f;
        view;
    });
}

- (void)saveSelectedModelAction {
    if (self.snapDetailsStickerModel.isDummy) {
        self.grootStickerView.stickerModel.selectedGrootStickerModel = nil;
    } else {
        ACCGrootDetailsStickerModel *detailModel = self.snapDetailsStickerModel;
        self.grootStickerView.stickerModel.selectedGrootStickerModel = detailModel;
        [self.grootStickerView configGrootDetailsStickerModel:detailModel snapIsDummy:detailModel.isDummy];
    }
    ACCBLOCK_INVOKE(self.confirmCallback);
}

#pragma mark - ACCGrootStickerSelectViewDelegate

- (void)selectedGrootStickerModel:(ACCGrootDetailsStickerModel *)model index:(NSUInteger)index {
    self.selectedIndex = index;
    self.snapDetailsStickerModel = model;
    self.grootStickerView.stickerModel.selectedGrootStickerModel  = model;
    [self.grootStickerView configGrootDetailsStickerModel:model snapIsDummy:model.isDummy];
    ACCBLOCK_INVOKE(self.selectModelCallback, model);
}

- (void)didClickedSaveButtonAction:(BOOL)allowed {
    [self saveSelectedModelAction];
    [self stopEdit:NO clickMask:NO];

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"prop_id"] = [ACCRecognitionGrootConfig grootStickerId];
    params[@"enter_from"] = @"video_edit_page";
    params[@"is_sticker"] = @1;
    params[@"is_authorized"] = @(allowed);
    [ACCTracker() trackEvent:@"confirm_species_card" params:params needStagingFlag:NO];
}

- (void)didClickCancelButtonAction {
    // 点击取消关闭按钮，还原初始状态的groot模型
    self.grootStickerView.stickerModel.selectedGrootStickerModel = self.originalDetailsStickerModel;
    [self.grootStickerView configGrootDetailsStickerModel:self.originalDetailsStickerModel snapIsDummy:self.snapDetailsStickerModel.isDummy];
    self.snapDetailsStickerModel =  self.originalDetailsStickerModel;
    [self stopEdit:YES clickMask:NO];
}

- (void)didClickAllowResearchButtonAction:(BOOL)allowed {
    self.grootStickerView.stickerModel.allowGrootResearch = allowed;
}

- (void)didSlideCard {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_from"] = @"video_edit_page";
    params[@"prop_id"] = [ACCRecognitionGrootConfig grootStickerId];
    params[@"is_sticker"] = @1;
    [ACCTracker() trackEvent:@"slide_species_card" params:params needStagingFlag:NO];
}

#pragma mark - public

- (void)startEditStickerView:(ACCGrootStickerView *_Nonnull)stickerView {
    // config models
    NSArray<ACCGrootDetailsStickerModel *> *models = stickerView.stickerModel.grootDetailStickerModels;
    ACCGrootDetailsStickerModel *selectedStickerModel = stickerView.stickerModel.selectedGrootStickerModel;
    self.originalDetailsStickerModel = selectedStickerModel;
    BOOL allowResearch = stickerView.stickerModel.allowGrootResearch;
    if (self.isEdting) {
        return;
    }
    self.isEdting = YES;
    
    self.orignalSuperView = stickerView.superview;
    self.grootStickerView = stickerView;
    
    [self.selectGrootView configData:models selectedModel:selectedStickerModel allowResearch:allowResearch  delegate:self];
    
    ACCBLOCK_INVOKE(self.startEditBlock, stickerView);
    
    self.upperMaskView.alpha = 1;
    CGRect selectViewFrame = self.selectGrootView.frame;
    selectViewFrame.origin.y = ACC_SCREEN_HEIGHT;
    self.selectGrootView.frame = selectViewFrame;
    self.selectGrootView.alpha = 1;
    @weakify(self);
    [stickerView transportToEditWithSuperView:self.upperMaskView animation:^{
        @strongify(self);
        self.lowerMaskView.alpha = 1;
        self.grootStickerView.alpha = 1;
    } selectedViewAnimationBlock:^{
        @strongify(self);
        // groot selected edit view
        CGRect selectViewFrame = self.selectGrootView.frame;
        selectViewFrame.origin.y = ACC_SCREEN_HEIGHT - selectViewFrame.size.height;
        self.selectGrootView.frame = selectViewFrame;
    } animationDuration:0.26];
}

- (void)stopEdit:(BOOL)isCancel clickMask:(BOOL)clickMask {
    if (!self.isEdting) {
        return;
    }
    
    self.isEdting = NO;
    
    @weakify(self);
    [self.grootStickerView restoreToSuperView:self.orignalSuperView animationDuration:0.22 animationBlock:^{
        @strongify(self)
        if (!self.grootStickerView.stickerModel.selectedGrootStickerModel) {
            // will remove if selected sticker is emtpty, add extra alpha animation
            self.grootStickerView.alpha = 0;
        }
        self.lowerMaskView.alpha = 0;
        NSDictionary *trackInfo = @{
            @"selectedIndex" : @(self.selectedIndex),
            @"isCancel" : @(isCancel),
            @"clickMask" : @(clickMask)
        };
        ACCBLOCK_INVOKE(self.finishEditAnimationBlock, self.grootStickerView, self.snapDetailsStickerModel.isDummy, trackInfo);
    } selectedViewAnimationBlock:^{
        @strongify(self);
        CGRect selectViewFrame = self.selectGrootView.frame;
        selectViewFrame.origin.y = ACC_SCREEN_HEIGHT;
        self.selectGrootView.frame = selectViewFrame;
    } completion:^{
        @strongify(self);
        ACCBLOCK_INVOKE(self.onEditFinishedBlock, self.grootStickerView);
        self.upperMaskView.alpha = 0;
        self.grootStickerView  = nil;
    }];
}

#pragma mark - action

- (void)didClickedTextMaskView {
    [self saveSelectedModelAction];
    [self stopEdit:NO clickMask:YES];
}

@end
