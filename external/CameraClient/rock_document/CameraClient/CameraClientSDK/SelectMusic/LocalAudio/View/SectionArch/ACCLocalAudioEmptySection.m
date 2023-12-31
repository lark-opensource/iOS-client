//
//  ACCLocalAudioEmptySection.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/7/4.
//

#import "ACCLocalAudioEmptySection.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>


@interface ACCLocalAudioEmptySection()

@property (nonatomic, strong) UILabel *tipLabel;

@end

@implementation ACCLocalAudioEmptySection

+ (CGFloat)sectionHeight
{
    return 120;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    [self.contentView addSubview:self.tipLabel];
    
    ACCMasMaker(self.tipLabel, {
        make.top.equalTo(self).offset(96);
        make.height.mas_equalTo(21);
        make.centerX.equalTo(self);
    });
}

#pragma mark - getter

- (UILabel *)tipLabel{
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.text = @"暂无本地音乐";
        _tipLabel.font = [ACCFont() systemFontOfSize:15.0];
        _tipLabel.textColor = ACCResourceColor(ACCColorTextReverse3);
        [_tipLabel sizeToFit];
    }
    return _tipLabel;
}

@end
