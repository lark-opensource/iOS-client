//
//  ACCLocalAudioAuthFooterSection.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/7/2.
//

#import "ACCLocalAudioAuthFooterSection.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCLocalAudioAuthFooterSection()

@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UILabel *clickableLabel;

@end

@implementation ACCLocalAudioAuthFooterSection

+ (CGFloat)sectionHeight
{
    return 30;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goSettingButtonClick)];
        [self.clickableLabel addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)setupUI{
    [self.contentView addSubview:self.descriptionLabel];
    [self.contentView addSubview:self.clickableLabel];
    CGFloat marginValue = (ACC_SCREEN_WIDTH - self.descriptionLabel.bounds.size.width - self.clickableLabel.bounds.size.width) / 2;
    ACCMasMaker(self.descriptionLabel, {
        make.top.equalTo(self).offset(12);
        make.height.mas_equalTo(17);
        make.left.equalTo(self).offset(marginValue);
    });
    ACCMasMaker(self.clickableLabel, {
        make.top.equalTo(self).offset(12);
        make.left.equalTo(self.descriptionLabel.mas_right);
        make.height.mas_equalTo(17);
    });
    
}

- (void)goSettingButtonClick
{
    if(self.clickAction){
        self.clickAction();
    }
}


#pragma mark - getter

- (UILabel *)descriptionLabel{
    if (!_descriptionLabel) {
        _descriptionLabel = [[UILabel alloc] init];
        _descriptionLabel.text = @"未开启音乐访问权限，";
        _descriptionLabel.font = [ACCFont() systemFontOfSize:12.0];
        _descriptionLabel.textColor = ACCResourceColor(ACCColorTextReverse3);
        [_descriptionLabel sizeToFit];
    }
    return _descriptionLabel;
}

- (UILabel *)clickableLabel{
    if (!_clickableLabel) {
        _clickableLabel = [[UILabel alloc] init];
        _clickableLabel.text = @"去开启";
        _clickableLabel.font = [ACCFont() systemFontOfSize:12.0];
        _clickableLabel.textColor = ACCResourceColor(ACCColorPrimary);
        _clickableLabel.userInteractionEnabled = YES;
        [_clickableLabel sizeToFit];
    }
    return _clickableLabel;
}

@end
