//
//  ACCLocalAudioManageSection.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/7/2.
//

#import "ACCLocalAudioManageSection.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>


@interface ACCLocalAudioManageSection()

@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UILabel *clickableLabel;

@end

@implementation ACCLocalAudioManageSection

- (void)configWithEditStatus:(BOOL)isEditing{
    if (isEditing) {
        self.clickableLabel.text = @"完成";
        self.clickableLabel.textColor = ACCResourceColor(ACCColorPrimary);
    } else {
        self.clickableLabel.text = @"管理";
        self.clickableLabel.textColor = ACCResourceColor(ACCColorTextReverse3);
    }
}

+ (CGFloat)sectionHeight
{
    return 41;
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
    
    ACCMasMaker(self.descriptionLabel, {
        make.top.equalTo(self).offset(16);
        make.height.mas_equalTo(17);
        make.left.equalTo(self).offset(16);
    });
    ACCMasMaker(self.clickableLabel, {
        make.top.equalTo(self.descriptionLabel);
        make.right.equalTo(self).offset(-16);
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
        _descriptionLabel.text = @"本地音频";
        _descriptionLabel.font = [ACCFont() systemFontOfSize:13.0 weight:ACCFontWeightMedium];
        _descriptionLabel.textColor = ACCResourceColor(ACCColorTextReverse3);
        [_descriptionLabel sizeToFit];
    }
    return _descriptionLabel;
}

- (UILabel *)clickableLabel{
    if (!_clickableLabel) {
        _clickableLabel = [[UILabel alloc] init];
        _clickableLabel.text = @"管理";
        _clickableLabel.font = [ACCFont() systemFontOfSize:13.0 weight:ACCFontWeightMedium];
        _clickableLabel.textColor = ACCResourceColor(ACCColorTextReverse3);
        _clickableLabel.userInteractionEnabled = YES;
        [_clickableLabel sizeToFit];
    }
    return _clickableLabel;
}

@end
