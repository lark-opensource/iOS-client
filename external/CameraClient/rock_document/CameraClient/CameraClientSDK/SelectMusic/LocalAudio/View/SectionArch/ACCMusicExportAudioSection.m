//
//  ACCMusicExportAudioSection.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/7/2.
//

#import "ACCMusicExportAudioSection.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

static const CGFloat kExportAudioButtonHeight = 44;

@interface ACCMusicExportAudioSection()

@property (nonatomic, strong) UIButton *exportButton;

@end

@implementation ACCMusicExportAudioSection
#pragma mark - public

+ (CGFloat)sectionHeight
{
    return 11 + kExportAudioButtonHeight;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    [self.contentView addSubview:self.exportButton];
    ACCMasMaker(self.exportButton, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.height.mas_equalTo(kExportAudioButtonHeight);
        make.bottom.equalTo(self);
    });
}

#pragma mark - action

- (void)exportButtonClick
{
    if (self.clickAction) {
        self.clickAction();
    }
}

#pragma mark - getter

- (UIButton *)exportButton{
    if (!_exportButton) {
        _exportButton = [[UIButton alloc] init];
        _exportButton.layer.cornerRadius = 2.0;
        _exportButton.layer.borderWidth = 1.0;
        _exportButton.layer.borderColor = ACCResourceColor(ACCColorLineReverse2).CGColor;
        
        [_exportButton setTitle:@"提取视频中的音频" forState:UIControlStateNormal];
        [_exportButton setTitleColor:ACCResourceColor(ACCColorTextReverse) forState:UIControlStateNormal];
        _exportButton.titleLabel.font = [ACCFont() systemFontOfSize:15.f weight:ACCFontWeightMedium];
        [_exportButton setImage:ACCResourceImage(@"icon_export_audio") forState:UIControlStateNormal];
        _exportButton.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
        
        [_exportButton addTarget:self action:@selector(exportButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _exportButton;
}

@end
