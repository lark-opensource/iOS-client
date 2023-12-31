//
//  CAKAlbumSwitchMultiSelectBottomView.m
//  CreativeAlbumKit-Pods-Aweme
//
//  Created by shaohua yang on 2/4/21.
//

#import <Masonry/Masonry.h>

#import "CAKAlbumSwitchBottomView.h"
#import "CAKLanguageManager.h"
#import "UIColor+AlbumKit.h"
#import "UIImage+AlbumKit.h"

#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

@interface CAKAlbumSwitchBottomView ()

@property (nonatomic, strong) UIView *seperatorLineView;
@property (nonatomic, strong) UIButton *switchButton;
@property (nonatomic, strong) void (^switchBlock)(BOOL selected);

@end


@implementation CAKAlbumSwitchBottomView

- (instancetype)initWithSwitchBlock:(void (^)(BOOL))block multiSelect:(BOOL)isMultiSelect
{
    if (self = [super initWithFrame:CGRectZero]) {
        _seperatorLineView = [[UIView alloc] init];
        _seperatorLineView.backgroundColor = CAKResourceColor(ACCUIColorConstLineSecondary);
        [self addSubview:_seperatorLineView];

        _switchBlock = block;
        _switchButton = [[UIButton alloc] init];
        _switchButton.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 4);
        _switchButton.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, -4);
        _switchButton.imageEdgeInsets = UIEdgeInsetsMake(0, -4, 0, 4);
        _switchButton.titleLabel.font = [ACCFont() acc_boldSystemFontOfSize:15];
        [_switchButton setTitle:@"多选" forState:UIControlStateNormal];
        [_switchButton setTitleColor:CAKResourceColor(ACCColorTextReverse) forState:UIControlStateNormal];
        [_switchButton setImage:CAKResourceImage(@"icon_album_selected") forState:UIControlStateSelected];
        [_switchButton setImage:CAKResourceImage(@"icon_album_unselected") forState:UIControlStateNormal];
        [_switchButton addTarget:self action:@selector(onSwitch) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_switchButton];

        _nextButton = [[UIButton alloc] init];
        _nextButton.backgroundColor = CAKResourceColor(ACCUIColorConstPrimary);
        [_nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_nextButton setTitleColor:CAKResourceColor(ACCColorConstTextInverse) forState:UIControlStateDisabled];
        [_nextButton setTitle:CAKLocalizedString(@"common_next", @"next") forState:UIControlStateNormal];
        _nextButton.titleLabel.font = [ACCFont() acc_systemFontOfSize:14.0f weight:ACCFontWeightMedium];
        _nextButton.titleEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 12);
        _nextButton.layer.cornerRadius = 2.0f;
        _nextButton.clipsToBounds = YES;
        _nextButton.hidden = YES;
        [self addSubview:_nextButton];

        ACCMasMaker(_seperatorLineView, {
            make.leading.trailing.top.equalTo(@(0.0f));
            make.height.equalTo(@(0.5f));
        });

        CGSize sizeFits = [_nextButton sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)];
        ACCMasMaker(_nextButton, {
            make.top.equalTo(@(8.0f));
            make.height.equalTo(@(36.0f));
            make.trailing.equalTo(@(-16.0f));
            make.width.equalTo(@(sizeFits.width+24));
        });
        
        ACCMasMaker(_switchButton, {
            make.leading.mas_equalTo(4);
            make.centerY.mas_equalTo(self.nextButton);
            make.height.mas_equalTo(44);
            make.width.mas_equalTo(88);
        });

        // Disable the next button by default.
        _nextButton.enabled = NO;
        _nextButton.backgroundColor = CAKResourceColor(ACCUIColorConstBGInput);
        
        self.switchButton.selected = isMultiSelect;
        self.nextButton.hidden = !isMultiSelect;
    }
    return self;
}

- (void)onSwitch
{
    self.switchButton.selected = !self.switchButton.selected;
    self.nextButton.hidden = !self.switchButton.selected;
    if (self.switchBlock) {
        self.switchBlock(self.switchButton.selected);
    }
}

@end
