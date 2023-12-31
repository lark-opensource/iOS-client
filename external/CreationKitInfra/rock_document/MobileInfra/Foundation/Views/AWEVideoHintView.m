//
//  AWEVideoHintView.m
//  AAWELaunchMainPlaceholder-iOS8.0
//
//  Created by hanxu on 2019/5/27.
//

#import "UIView+ACCMasonry.h"
#import "AWEVideoHintView.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEVideoHintView()

@property (nonatomic, strong, readwrite) UILabel *topLabel;
@property (nonatomic, strong, readwrite) UILabel *bottomLabel;

@end

@implementation AWEVideoHintView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.topLabel = [[UILabel alloc] init];
        self.topLabel.font = [ACCFont() systemFontOfSize:28 weight:ACCFontWeightLight];
        
        self.bottomLabel = [[UILabel alloc] init];
        self.bottomLabel.font = ACCStandardFont(ACCFontClassP1, ACCFontWeightRegular);
        
        [self uniformSettingForLabel:self.topLabel];
        [self uniformSettingForLabel:self.bottomLabel];
        
        [self addSubview:self.topLabel];
        [self addSubview:self.bottomLabel];
        
        ACCMasMaker(self.topLabel, {
            make.centerX.equalTo(self.mas_centerX);
            make.top.equalTo(self.mas_top);
            make.bottom.equalTo(self.bottomLabel.mas_top);
        });
        
        ACCMasMaker(self.bottomLabel, {
            make.centerX.equalTo(self.mas_centerX);
            make.bottom.equalTo(self.mas_bottom);
        });
        
        ACCMasMaker(self, {
            make.width.greaterThanOrEqualTo(self.topLabel.mas_width);
            make.width.greaterThanOrEqualTo(self.bottomLabel.mas_width);
        });
    }
    return self;
}

- (void)uniformSettingForLabel:(UILabel *)label
{
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
    ACC_LANGUAGE_DISABLE_LOCALIZATION(label);

}

- (void)updateTopText:(NSString *)topText bottomText:(NSString *)bottomText
{
    self.topLabel.text = topText;
    self.bottomLabel.text = bottomText;
}

@end
