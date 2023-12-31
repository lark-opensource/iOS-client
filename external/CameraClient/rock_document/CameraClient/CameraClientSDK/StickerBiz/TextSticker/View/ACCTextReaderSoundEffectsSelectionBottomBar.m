//
//  ACCTextReaderSoundEffectsSelectionBottomBar.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/4.
//

#import "ACCTextReaderSoundEffectsSelectionBottomBar.h"

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>

CGFloat const kACCTextReaderSoundEffectsSelectionBottomBarHeight = 51.0f;

@implementation ACCTextReaderSoundEffectsSelectionBottomBar

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI
{
    _titleLbl = ({
        UILabel *label = [[UILabel alloc] init];
        [self addSubview:label];
        label.text = @"音色选择";
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        label.font = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightMedium];
        
        label;
    });
    
    _cancelBtn = ({
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self addSubview:btn];
        [btn setImage:ACCResourceImage(@"ic_camera_cancel") forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(p_didClickCancelBtn:) forControlEvents:UIControlEventTouchUpInside];
        btn.accessibilityLabel = @"取消";
        
        btn;
    });
    
    _saveBtn = ({
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self addSubview:btn];
        [btn setImage:ACCResourceImage(@"ic_camera_save") forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(p_didClickSaveBtn:) forControlEvents:UIControlEventTouchUpInside];
        btn.accessibilityLabel = @"保存";
        
        btn;
    });
    
    _lineView = ({
        UIView *view = [[UIView alloc] init];
        [self addSubview:view];
        view.backgroundColor = ACCResourceColor(ACCUIColorConstLineSecondary2);
        
        view;
    });
    
    ACCMasMaker(self.cancelBtn, {
        make.leading.equalTo(self).offset(16);
        make.bottom.equalTo(self).offset(-11);
        make.width.height.equalTo(@(28));
    });
    
    ACCMasMaker(self.saveBtn, {
        make.bottom.equalTo(self).offset(-11);
        make.trailing.equalTo(self).offset(-16);
        make.width.height.equalTo(@(28));
    });
    
    ACCMasMaker(self.titleLbl, {
        make.top.bottom.centerX.equalTo(self);
    });
    
    ACCMasMaker(self.lineView, {
        make.top.leading.trailing.equalTo(self);
        make.height.equalTo(@(0.5));
    });
}

- (void)p_didClickCancelBtn:(id)sender
{
    ACCBLOCK_INVOKE(self.didTapCancelButtonBlock);
}

- (void)p_didClickSaveBtn:(id)sender
{
    ACCBLOCK_INVOKE(self.didTapSaveButtonBlock);
}

@end
