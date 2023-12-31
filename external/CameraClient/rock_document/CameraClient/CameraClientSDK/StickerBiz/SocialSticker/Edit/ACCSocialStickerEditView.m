//
//  ACCSocialStickerEditView.m
//  CameraClient-Pods-Aweme-CameraResource_base
//
//  Created by qiuhang on 2020/8/5.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCSocialStickerEditView.h"
#import <CreationKitArch/AWEEditGradientView.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <Masonry/Masonry.h>
#import "ACCCameraClient.h"
#import <CreativeKit/ACCAnimatedButton.h>
#import "ACCSocialStickerEditToolbar.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>

@interface ACCSocialStickerEditView ()

@property (nonatomic, strong) ACCAnimatedButton *saveButton;
@property (nonatomic, strong) AWEEditGradientView *upperMaskView;
@property (nonatomic, strong) UIView *lowerMaskView;
@property (nonatomic,   weak) UIView *orignalSuperView;

@property (nonatomic, strong) ACCSocialStickerEditToolbar *editToolbar;

@property (nonatomic, strong) ACCSocialStickerView *editingStickerView;
@property (nonatomic, assign) BOOL isEdting;

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;

@end

@implementation ACCSocialStickerEditView
@synthesize editingStickerView = _editingStickerView;

#pragma mark - life cycle
+ (instancetype)editViewWithPublishModel:(AWEVideoPublishViewModel *)publishModel {
     return [[self alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT)
                           publishModel:publishModel];
}

- (instancetype)initWithFrame:(CGRect)frame
                 publishModel:(AWEVideoPublishViewModel *)publishModel {
    
    if (self = [super initWithFrame:frame]) {
        _publishModel = publishModel;
        [self setup];
        [self addObservers];
    }
    return self;
}

- (void)dealloc {
    [self removeObservers];
}

#pragma mark - setup
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

    self.saveButton = ({
        
        ACCAnimatedButton *button = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        [self addSubview:button];
        [button.titleLabel setFont:[ACCFont() systemFontOfSize:17.f weight:ACCFontWeightMedium]];
        [button setTitle: ACCLocalizedString(@"done", @"done") forState:UIControlStateNormal];
        [button addTarget:self action:@selector(didClickedSaveButton:) forControlEvents:UIControlEventTouchUpInside];
        
        ACCMasMaker(button, {
            make.trailing.equalTo(self.mas_trailing).offset(-12.f);
            make.top.equalTo(self.mas_top).offset(ACC_NAVIGATION_BAR_OFFSET + ([UIDevice acc_isIPhoneX] ? 22.f : 16.f));
            make.height.equalTo(@32.f);
        });
        button.alpha = 0.f;
        button.hidden = YES;
        button;
    });
    
    self.editToolbar = ({
        
        ACCSocialStickerEditToolbar *view = [[ACCSocialStickerEditToolbar alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, [ACCSocialStickerEditToolbar defaulBarHeight]) publishModel:self.publishModel];
        view;
    });
    
    @weakify(self);
    [self.editToolbar setOnSelectMention:^(ACCSocialStickeMentionBindingModel * _Nonnull mentionBindingData) {
        @strongify(self);
        NSAssert(self.isEdting, @"bad case, need check");
        if (self.editingStickerView && self.isEdting) {
            BOOL bindSucceed = [self.editingStickerView bindingWithMentionModel:mentionBindingData];
            if (bindSucceed) {
                [self stopEdit];
            }
        }
    }];
    
    [self.editToolbar setOnSelectHashTag:^(ACCSocialStickeHashTagBindingModel * _Nonnull hashTagBindingData) {
        @strongify(self);
        NSAssert(self.isEdting, @"bad case, need check");
        if (self.editingStickerView && self.isEdting) {
            BOOL bindSucceed =[self.editingStickerView bindingWithHashTagModel:hashTagBindingData];
            if (bindSucceed) {
                [self stopEdit];
            }
        }
    }];
}

#pragma mark - notify
- (void)addObservers {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardChangeFrameNoti:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleKeyboardChangeFrameNoti:(NSNotification *)noti {
    
    if (!self.window || !self.superview || !self.editingStickerView) {
        return;
    }
    
    CGRect keyboardBounds;
    [[noti.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
    CGFloat keyboardHeight = (keyboardBounds.size.height > 0) ? keyboardBounds.size.height : 260.f;
    [self.editingStickerView updateKeyboardHeight:keyboardHeight];
}

#pragma mark - action
- (void)didClickedTextMaskView {
    [self stopEdit];
}

- (void)didClickedSaveButton:(UIButton *)button {
    [self stopEdit];
}

- (void)stopEdit {
    
    if (!self.isEdting) {
        return;
    }
    
    self.isEdting = NO;
    
    // clean
    [self.editingStickerView setOnSearchKeywordChanged:nil];
    [self.editingStickerView setOnMentionBindingDataChanged:nil];
    
    @weakify(self);
    [self endEditing:YES];
    [self.editingStickerView restoreToSuperView:self.orignalSuperView animationDuration:0.35 animationBlock:^{
        @strongify(self);
        if (!self.editingStickerView.stickerModel.isNotEmpty) {
            // will remove if sticker is emtpty, add extra alpha animation
            self.editingStickerView.alpha = 0;
        }
        self.lowerMaskView.alpha = 0;
        self.saveButton.alpha    = 0;
        self.saveButton.hidden   = YES;
        ACCBLOCK_INVOKE(self.finishEditAnimationBlock, self.editingStickerView);
    } completion:^{
        @strongify(self);
        ACCBLOCK_INVOKE(self.onEditFinishedBlock, self.editingStickerView);
        self.upperMaskView.alpha = 0;
        self.editingStickerView  = nil;
        [self.editToolbar cancelSearch];
    }];
}

- (void)startEditStickerView:(ACCSocialStickerView *)stickerView {
    
    NSParameterAssert(stickerView != nil);
    
    if (self.isEdting) {
        return;
    }
    
    self.isEdting = YES;

    self.orignalSuperView = stickerView.superview;
    self.editingStickerView = stickerView;
    
    self.editToolbar.trackInfo = @{@"at_selected_from" : stickerView.stickerModel.isAutoAdded?@"auto":@"prop_entrance"};
    
    ACCBLOCK_INVOKE(self.startEditBlock, stickerView);
    
    // reset binding tool bar
    self.editToolbar.stickerType = stickerView.stickerType;
    [self.editToolbar updateSelectedMention:self.editingStickerView.stickerModel.mentionBindingModel];
    [self.editToolbar searchWithKeyword:stickerView.currentSearchKeyword];
    
    @weakify(self);
    [self.editingStickerView setOnSearchKeywordChanged:^{
        @strongify(self);
        [self.editToolbar searchWithKeyword:stickerView.currentSearchKeyword];
    }];
    
    [self.editingStickerView setOnMentionBindingDataChanged:^{
        @strongify(self);
        [self.editToolbar updateSelectedMention:self.editingStickerView.stickerModel.mentionBindingModel];
    }];
    
    [stickerView bindInputAccessoryView:self.editToolbar];
    
    self.upperMaskView.alpha = 1;
    [stickerView transportToEditWithSuperView:self.upperMaskView animation:^{
        @strongify(self);
        self.lowerMaskView.alpha = 1;
        self.saveButton.alpha    = 1;
        self.saveButton.hidden   = NO;
        self.editingStickerView.alpha = 1;
    } animationDuration:0.35];
}

@end
