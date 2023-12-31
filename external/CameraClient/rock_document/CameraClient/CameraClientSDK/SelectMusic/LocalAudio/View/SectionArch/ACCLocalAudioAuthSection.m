//
//  ACCLocalAudioAuthSection.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/7/2.
//

#import "ACCLocalAudioAuthSection.h"
#import <MediaPlayer/MediaPlayer.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

@interface ACCLocalAudioAuthSection()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *goSettingButton;
@property (nonatomic, assign) BOOL isNotDetermined;

@end

@implementation ACCLocalAudioAuthSection

+ (CGFloat)sectionHeight
{
    return 250;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        if (@available(iOS 9.3, *)) {
            MPMediaLibraryAuthorizationStatus authStatus = [MPMediaLibrary authorizationStatus];
            self.isNotDetermined = authStatus == MPMediaLibraryAuthorizationStatusNotDetermined;
        }
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.messageLabel];
    [self.contentView addSubview:self.goSettingButton];
    ACCMasMaker(self.titleLabel, {
        make.top.equalTo(self).offset(100);
        make.height.mas_equalTo(28);
        make.centerX.equalTo(self);
    });
    ACCMasMaker(self.messageLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.height.mas_equalTo(42);
        make.centerX.equalTo(self);
    });
    ACCMasMaker(self.goSettingButton, {
        make.top.equalTo(self.messageLabel.mas_bottom).offset(28);
        make.size.mas_equalTo(CGSizeMake(112, 36));
        make.centerX.equalTo(self);
    });
}

- (void)goSettingButtonClick
{
    if(self.clickAction){
        self.clickAction();
    }
}

#pragma mark - getter

- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = self.isNotDetermined ? @"开启访问音乐权限" : @"未开启访问音乐权限";
        _titleLabel.numberOfLines = 1;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = ACCResourceColor(ACCColorTextReverse);
        _titleLabel.font = [ACCFont() systemFontOfSize:20.0 weight:ACCFontWeightMedium];
        [_titleLabel sizeToFit];
    }
    return _titleLabel;
}

- (UILabel *)messageLabel{
    if (!_messageLabel) {
        _messageLabel = [[UILabel alloc] init];
        if (self.isNotDetermined) {
            _messageLabel.text = @"此功能需要媒体资料库权限，才能访问到\n你的本地音乐";
        } else {
            _messageLabel.text = @"此功能需要媒体资料库权限，才能访问到\n你的本地音乐。可以在系统设置中开启";
        }
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:_messageLabel.text];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
        [paragraphStyle setLineSpacing:6];
        [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, _messageLabel.text.length)];
        _messageLabel.attributedText = attributedString;
        _messageLabel.numberOfLines = 2;
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.textColor = ACCResourceColor(ACCColorTextReverse3);
        _messageLabel.font = [ACCFont() systemFontOfSize:15.0];
        [_messageLabel sizeToFit];
    }
    return _messageLabel;
}

- (UIButton *)goSettingButton{
    if (!_goSettingButton) {
        _goSettingButton = [[UIButton alloc] init];
        _goSettingButton.layer.cornerRadius = 2.0;
        _goSettingButton.backgroundColor = ACCResourceColor(ACCColorPrimary);
        [_goSettingButton addTarget:self action:@selector(goSettingButtonClick) forControlEvents:UIControlEventTouchUpInside];
        NSString *buttonTitle = self.isNotDetermined ? @"开启" : @"去开启";
        [_goSettingButton setTitle:buttonTitle forState:UIControlStateNormal];
        [_goSettingButton setTitleColor:ACCResourceColor(ACCColorConstTextInverse) forState:UIControlStateNormal];
        _goSettingButton.titleLabel.font = [ACCFont() systemFontOfSize:13.0 weight:ACCFontWeightMedium];
    }
    return _goSettingButton;
}

@end
