//
//  ACCSelfieEmojiAuthorityView.m
//  CameraClient-Pods-Aweme
//
//  Created by liujingchuan on 2021/9/3.
//

#import "ACCSelfieEmojiAuthorityView.h"
#import <Masonry/Masonry.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>

@interface ACCSelfieEmojiAuthorityView()

@property (nonatomic, strong) UIImageView *faceCircleImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *openCameraAuthBtn;

@end

@implementation ACCSelfieEmojiAuthorityView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor blackColor];
    self.faceCircleImageView = [[UIImageView alloc] init];
    self.faceCircleImageView.image = ACCResourceImage(@"ic_selfie_emoji_record_disabled");
    [self addSubview:self.faceCircleImageView];
    [self.faceCircleImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.width.mas_equalTo(300);
        make.width.mas_equalTo(240);
        make.centerX.mas_equalTo(self);
        make.top.mas_equalTo(ACC_STATUS_BAR_NORMAL_HEIGHT + 102);
    }];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"允许访问即可进入拍摄";
    self.titleLabel.font = [ACCFont() acc_systemFontOfSize:15];
    self.titleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse4);
    [self addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.faceCircleImageView.mas_bottom).mas_offset(100);
        make.centerX.mas_equalTo(self);
    }];

    self.openCameraAuthBtn = [[UIButton alloc] init];
    [self.openCameraAuthBtn setTitle:@"启用相机访问权限" forState:UIControlStateNormal];
    [self.openCameraAuthBtn setTitleColor:ACCResourceColor(ACCColorAssistColorBlue) forState:UIControlStateNormal];
    [self.openCameraAuthBtn addTarget:self action:@selector(goToOpenCameraAuth) forControlEvents:UIControlEventTouchUpInside];
    self.openCameraAuthBtn.titleLabel.font = [ACCFont() acc_systemFontOfSize:15];
    [self addSubview:self.openCameraAuthBtn];
    [self.openCameraAuthBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleLabel).mas_offset(36);
        make.centerX.mas_equalTo(self);
    }];
}

- (void)goToOpenCameraAuth {    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

@end
