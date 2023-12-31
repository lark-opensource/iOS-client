//
//  AWEComposerBeautyTopBarCollectionViewCell.m
//  CameraClient-Pods-Aweme
//
//  Created by ZhangYuanming on 2020/5/29.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitBeauty/AWEComposerBeautyTopBarCollectionViewCell.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEComposerBeautyTopBarCollectionViewCell ()

@property (nonatomic, strong) UIView *flagDotView;

@end

@implementation AWEComposerBeautyTopBarCollectionViewCell

+ (NSString *)identifier
{
    return @"AWEComposerBeautyTopBarCollectionViewCell";
}

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _selectedTitleFont = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightSemibold];
        _selectedTitleColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        _unselectedTitleFont = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightRegular];
        _unselectedTitleColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightRegular];
        _titleLabel.textColor = self.unselectedTitleColor;
        [self addSubview:_titleLabel];
        
        ACCMasMaker(_titleLabel, {
            make.center.equalTo(self);
        });
        
        _underline = [[UIView alloc] init];
        _underline.backgroundColor = self.selectedTitleColor;
        _underline.hidden = YES;
        [self addSubview:_underline];
        
        ACCMasMaker(_underline, {
            make.bottom.equalTo(self);
            make.height.equalTo(@2);
            make.left.right.equalTo(self.titleLabel);
        });
    }
    return self;
}

- (void)updateWithTitle:(NSString *)title selected:(BOOL)selected
{
    self.titleLabel.text = title;
    [self updateWithUserSelected:selected];
}

- (void)updateWithUserSelected:(BOOL)userSelected
{
    if (userSelected) {
        self.titleLabel.font = self.selectedTitleFont;
        self.titleLabel.textColor = self.selectedTitleColor;
        self.underline.hidden = !self.shouldShowUnderline;
    } else {
        self.titleLabel.font = self.unselectedTitleFont;
        self.titleLabel.textColor = self.unselectedTitleColor;
        self.underline.hidden = YES;
    }
}

- (void)setFlagDotViewHidden:(BOOL)hidden
{
    if (!hidden && !_flagDotView) {
        _flagDotView = [[UIView alloc] init];
        _flagDotView.layer.cornerRadius = 4;
        _flagDotView.layer.masksToBounds = YES;
        _flagDotView.backgroundColor = ACCResourceColor(ACCColorLink);
        _flagDotView.hidden = YES;
        [self.contentView addSubview:_flagDotView];
        
        ACCMasMaker(_flagDotView, {
            make.width.height.mas_equalTo(8);
            make.left.equalTo(self.titleLabel.mas_right);
            make.centerY.equalTo(self.titleLabel.mas_top);
        });
    }
    _flagDotView.hidden = hidden;
}

@end
