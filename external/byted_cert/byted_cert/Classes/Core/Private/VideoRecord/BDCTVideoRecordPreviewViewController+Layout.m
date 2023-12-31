//
//  BDCTVideoRecordPreviewViewController+Layout.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/16.
//

#import "BDCTVideoRecordPreviewViewController+Layout.h"
#import "UIViewController+BDCTAdditions.h"
#import "UIImage+BDCTAdditions.h"
#import "BytedCertUIConfig.h"
#import "BDCTVideoView.h"
#import "BDCTVideoRecordViewController.h"
#import "BDCTAdditions+VideoRecord.h"
#import "BDCTLocalization.h"

#import <ByteDanceKit/UIButton+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/UIImage+BTDAdditions.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <Masonry/Masonry.h>


@implementation BDCTVideoRecordPreviewViewController (Layout)

- (void)layoutContentViews {
    self.view.backgroundColor = BytedCertUIConfig.sharedInstance.backgroundColor;

    UIButton *navBackBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    navBackBtn.frame = CGRectMake(5, UIApplication.sharedApplication.statusBarFrame.size.height, 44, 44);
    [navBackBtn setImage:[BytedCertUIConfig.sharedInstance.backBtnImage btd_ImageWithTintColor:BytedCertUIConfig.sharedInstance.textColor] forState:UIControlStateNormal];
    @weakify(self);
    [navBackBtn btd_addActionBlockForTouchUpInside:^(__kindof UIButton *_Nonnull sender) {
        @strongify(self);
        [self bdct_dismiss];
    }];
    [self.view addSubview:navBackBtn];

    UILabel *titleLabel = [UILabel new];
    titleLabel.text = BytedCertLocalizedString(@"视频录制");
    titleLabel.textColor = BytedCertUIConfig.sharedInstance.textColor;
    titleLabel.font = [UIFont systemFontOfSize:17 weight:500];
    [self.view addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(navBackBtn);
    }];

    NSArray<NSDictionary *> *buttonContents = @[
        @{@"title" : BytedCertLocalizedString(@"重新拍摄"),
          @"titleColor" : BytedCertUIConfig.sharedInstance.textColor,
          @"bgColor" : [UIColor btd_colorWithHexString:BytedCertUIConfig.sharedInstance.textColor.btd_hexString alpha:0.05],
          @"tag" : @(0)},
        @{@"title" : BytedCertLocalizedString(@"开始上传"),
          @"titleColor" : UIColor.whiteColor,
          @"bgColor" : BytedCertUIConfig.sharedInstance.primaryColor,
          @"tag" : @(1)}
    ];
    NSArray<UIButton *> *buttons = [buttonContents btd_map:^UIButton *_Nullable(NSDictionary *_Nonnull item) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:[item btd_stringValueForKey:@"title"] forState:UIControlStateNormal];
        [button setTitleColor:[item btd_objectForKey:@"titleColor" default:[UIColor blackColor]] forState:UIControlStateNormal];
        [button setBackgroundColor:[item btd_objectForKey:@"bgColor" default:[UIColor clearColor]]];
        button.titleLabel.font = [UIFont systemFontOfSize:15.0f weight:500];
        button.layer.cornerRadius = 4.0f;
        [button.layer setMasksToBounds:YES];

        @weakify(self);
        [button btd_addActionBlockForTouchUpInside:^(__kindof UIButton *_Nonnull sender) {
            @strongify(self);
            if ([item btd_intValueForKey:@"tag"] == 0) {
                [self.delegate videoRecordPreviewViewControllerDidTapRerecordVideo:self];
            } else {
                [self.delegate videoRecordPreviewViewControllerDidTapUploadVideo:self videoPathURL:self.videoURL];
            }
        }];
        return button;
    }];
    UIStackView *buttonStackView = [[UIStackView alloc] initWithArrangedSubviews:buttons];
    buttonStackView.distribution = UIStackViewDistributionFillEqually;
    buttonStackView.alignment = UIStackViewAlignmentFill;
    buttonStackView.spacing = 8.0f;
    [self.view addSubview:buttonStackView];
    [buttonStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(44);
        make.left.right.equalTo(self.view).insets(UIEdgeInsetsMake(0, 16, 6, 16));
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-15);
        } else {
            make.bottom.equalTo(self.view).offset(-15);
        }
    }];

    NSArray<NSDictionary *> *uiItems = @[ @{@"title" : BytedCertLocalizedString(@"光线充足"),
                                            @"icon" : @"bdct_icon_video_record_light"},
                                          @{@"title" : @"脸部完整",
                                            @"icon" : @"bdct_icon_video_record_face"},
                                          @{@"title" : @"环境安静",
                                            @"icon" : @"bdct_icon_video_record_silence"} ];
    NSArray<UIView *> *tipViews = [uiItems btd_map:^UIView *_Nullable(NSDictionary *_Nonnull item) {
        UIImageView *imageView = [UIImageView new];
        imageView.image = [[UIImage bdct_videoRecordimageWithName:[item btd_stringValueForKey:@"icon"]] btd_ImageWithTintColor:BytedCertUIConfig.sharedInstance.textColor];

        UILabel *label = [UILabel new];
        label.font = [UIFont systemFontOfSize:13];
        label.textColor = BytedCertUIConfig.sharedInstance.textColor;
        label.text = [item btd_stringValueForKey:@"title"];

        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[ imageView, label ]];
        stackView.spacing = 14;
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.alignment = UIStackViewAlignmentCenter;
        return stackView;
    }];
    UIStackView *tipStackView = [[UIStackView alloc] initWithArrangedSubviews:tipViews];
    tipStackView.distribution = UIStackViewDistributionFillEqually;
    tipStackView.alignment = UIStackViewAlignmentFill;
    tipStackView.spacing = 8.0f;
    [self.view addSubview:tipStackView];
    [tipStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(buttonStackView.mas_top).offset(-40);
        make.left.right.equalTo(buttonStackView);
    }];

    UILabel *finishLabel = [UILabel new];
    finishLabel.text = BytedCertLocalizedString(@"拍摄完成请确认");
    finishLabel.font = [UIFont systemFontOfSize:13];
    finishLabel.textColor = BytedCertUIConfig.sharedInstance.textColor;
    finishLabel.alpha = 0.6;
    [finishLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.view addSubview:finishLabel];
    [finishLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(tipStackView.mas_top).offset(-16);
    }];

    BDCTVideoView *videoView = [BDCTVideoView new];
    videoView.videoURL = self.videoURL;
    videoView.backgroundColor = UIColor.blackColor;
    [videoView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    [self.view addSubview:videoView];
    [videoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(navBackBtn.mas_bottom);
        make.bottom.equalTo(finishLabel.mas_top).offset(-20);
    }];
}

@end
