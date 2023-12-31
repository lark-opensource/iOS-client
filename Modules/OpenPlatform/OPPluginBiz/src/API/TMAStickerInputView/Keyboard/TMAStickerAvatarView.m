//
//  TMAStickerAvatarView.m
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/28.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import "TMAStickerAvatarView.h"
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/UIButton+EMA.h>
#import "TMAStickerInputModel.h"
#import <OPFoundation/BDPNetworking.h>
#import <OPFoundation/BDPPickerView.h>
#import <OPFoundation/UIImage+EMA.h>
#import <OPFoundation/UIColor+EMA.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>

static CGFloat const TMAStickerAvatarViewAvatarWidth = 28;
static CGFloat const TMAStickerAvatarViewSubviewMarginX = 5;

@interface TMAStickerAvatarView () <BDPPickerViewDelegate>

@property (nonatomic, weak) UIViewController *currentViewController;

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UIButton *anonymousButton;
@property (nonatomic, strong, readwrite) TMAStickerInputUserSelectModel *userSelectModel;
@property (nonatomic, strong) BDPPickerView *picker;
@property (nonatomic, copy) void (^showPickerViewCompletionBlock)(BOOL shows);
@property (nonatomic, assign) BOOL userModelSelectOpt;

@end

@implementation TMAStickerAvatarView

#pragma mark - life cycle

- (instancetype)initWithFrame:(CGRect)frame currentViewController:(UIViewController *)currentViewController userModelSelectOpt:(BOOL)userModelSelectOpt {
    if (self = [super initWithFrame:frame]) {
        self.currentViewController = currentViewController;
        _userModelSelectOpt = userModelSelectOpt;
        [self setupViews];
    }
    return self;
}

#pragma mark - setup views

- (void)setupViews {
    self.avatarImageView = ({
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage ema_imageNamed:@"tma_icn_anonymous"]];
        imageView.bdp_size = CGSizeMake(TMAStickerAvatarViewAvatarWidth, TMAStickerAvatarViewAvatarWidth);
        imageView.layer.cornerRadius = TMAStickerAvatarViewAvatarWidth / 2.0;
        imageView.layer.masksToBounds = YES;
        imageView;
    });
    
    self.anonymousButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.titleLabel.font = [UIFont systemFontOfSize:16];
        [button setTitleColor:UDOCColor.textCaption forState:UIControlStateNormal];
        [button setImage:[UIImage ema_imageNamed:@"tma_arrrow_down"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(anonymousButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [button sizeToFit];
        [self updateAnonymouseButton];
        button;
    });
    
    UIView *superview = self;
    [superview addSubview:self.avatarImageView];
    [superview addSubview:self.anonymousButton];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.bdp_height = MAX(self.avatarImageView.bdp_height, self.anonymousButton.bdp_height);
    
    self.avatarImageView.bdp_left = 0;
    self.avatarImageView.bdp_centerY = self.bdp_height / 2.0;
    self.anonymousButton.bdp_left = self.avatarImageView.bdp_right + TMAStickerAvatarViewSubviewMarginX;
    self.anonymousButton.bdp_centerY = self.bdp_height / 2.0;
    self.bdp_width = self.anonymousButton.bdp_right;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat height = MAX(self.avatarImageView.bdp_height, self.anonymousButton.bdp_height);
    CGFloat width = self.anonymousButton.bdp_width + TMAStickerAvatarViewSubviewMarginX + self.anonymousButton.bdp_width;
    return CGSizeMake(width, height);
}

- (void)sizeToFit {
    self.bdp_size = [self sizeThatFits:self.bdp_size];
}

#pragma mark - actions

- (void)anonymousButtonClicked {
    if (self.userModelSelectOpt && BDPIsEmptyArray(self.userSelectModel.items)) {
        return;
    }
    [self showPickerViewInViewController:self.currentViewController];
}

- (void)configureViewsWithAvatarURL:(NSURL *)avatarURL userSelectModel:(TMAStickerInputUserSelectModel *)userSelectModel showPickerViewCompletionBlock:(void(^)(BOOL shows))showPickerViewCompletionBlock {
    self.userSelectModel = userSelectModel;
    [self.avatarImageView ema_setImageWithUrl:avatarURL placeHolder:nil];
    [self updateAnonymouseButton];
    self.showPickerViewCompletionBlock = showPickerViewCompletionBlock;
}

- (void)updateAnonymouseButton {
    if (self.userModelSelectOpt) {
        [self.anonymousButton setImage:BDPIsEmptyArray(self.userSelectModel.items) ? nil : [UIImage ema_imageNamed:@"tma_arrrow_down"] forState:UIControlStateNormal];
    }
    [self.anonymousButton setTitle:self.userSelectModel.data forState:UIControlStateNormal];
    [self.anonymousButton sizeToFit];
    CGFloat imageTitlespace = 2;
    [self.anonymousButton ema_layoutButtonWithEdgeInsetsStyle:EMAButtonEdgeInsetsStyleImageRight imageTitlespace:imageTitlespace];
    self.anonymousButton.bdp_width += imageTitlespace;
}

#pragma mark picker view

- (void)showPickerViewInViewController:(UIViewController *)viewController {
    if (self.showPickerViewCompletionBlock) {
        self.showPickerViewCompletionBlock(YES);
    }
    
    NSDictionary *params = @{
                             @"array": self.userSelectModel.items ?: @[],
                             @"current": @([self.userSelectModel.items indexOfObjectIdenticalTo:self.userSelectModel.data])
                             };
    BDPPickerPluginModel *model = [[BDPPickerPluginModel alloc] initWithDictionary:params error:nil];
    
    if (self.userModelSelectOpt) {
        id<BDPPickerPluginDelegate> pickerPlugin = (id<BDPPickerPluginDelegate>)[[[BDPTimorClient sharedClient] pickerPlugin] sharedPlugin];
        __weak typeof(self) weakSelf = self;
        [pickerPlugin bdp_showPickerViewWithModel:model fromController:self.currentViewController pickerSelectedCallback:nil completion:^(BOOL isCanceled, NSArray<NSNumber *> *selectedRow, BDPPickerPluginModel *model) {
            __strong typeof(weakSelf) self = weakSelf;
            if (isCanceled) {
                if (self.showPickerViewCompletionBlock) {
                    self.showPickerViewCompletionBlock(NO);
                }
            } else {
                [self onPickerConfirmed:selectedRow];
            }
        }];
    } else {
        BDPPickerView *picker = [[BDPPickerView alloc] initWithFrame:viewController.view.bounds];
        picker.delegate = self;
        [picker updateWithModel:model];
        [picker showInView:viewController.view];
        self.picker = picker;
    }
}

- (void)onPickerConfirmed:(NSArray<NSNumber *> *)indexes {
    NSString *title = [self.userSelectModel.items objectAtIndex:[indexes.firstObject integerValue]];
    self.userSelectModel.data = title;
    [self updateAnonymouseButton];

    if (self.modelChangedBlock) {
        self.modelChangedBlock(TMAStickerInputEventTypeModelSelect);
    }

    if (self.showPickerViewCompletionBlock) {
        self.showPickerViewCompletionBlock(NO);
    }
}

#pragma mark - BDPPickerViewDelegate

- (void)didCancelPicker:(BDPPickerView *)picker
{
    if (self.showPickerViewCompletionBlock) {
        self.showPickerViewCompletionBlock(NO);
    }
}

- (void)picker:(BDPPickerView *)picker didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
}

- (void)picker:(BDPPickerView *)picker didConfirmOnIndexs:(NSArray<NSNumber *> *)indexs
{
    [self onPickerConfirmed:indexs];
}

@end
