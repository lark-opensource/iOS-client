//
//  ACCRecognitionGrootStickerViewD.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/23.
//

#import "ACCRecognitionGrootStickerViewD.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKitSticker/ACCStickerUtils.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <Masonry/Masonry.h>

@interface ACCRecognitionGrootStickerViewD()

@property (nonatomic, strong) UILabel *speciesNameLabel;

@property (nonatomic, strong) UIView *centerView;

@property (nonatomic, strong) UIView *outsideCircleView;

@property (nonatomic, strong) UIView *contentView;

@end

@implementation ACCRecognitionGrootStickerViewD

@synthesize coordinateDidChange = _coordinateDidChange;
@synthesize currentScale = _currentScale;

#pragma mark - public

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupUI];
        [self updateFrame];
    }
    return self;
}

- (void)configWithModel:(ACCGrootDetailsStickerModel *)grootStickerModel
{
    if (!grootStickerModel) {
        return;
    }
    self.stickerModel = grootStickerModel;
    self.speciesNameLabel.text = grootStickerModel.speciesName;
    [self updateFrame];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    ACCBLOCK_INVOKE(self.coordinateDidChange); 
}

#pragma mark - private

- (void)setupUI
{
    self.backgroundColor = [UIColor clearColor];

    [self addSubview:self.contentView];
    [self addSubview:self.speciesNameLabel];
    [self addSubview:self.outsideCircleView];
    [self addSubview:self.centerView];

    // update subviews
    ACCMasMaker(self.contentView, {
        make.left.equalTo(self);
        make.bottom.equalTo(self);
        make.width.equalTo(self.mas_width);
        make.height.equalTo(@40);
    });

    ACCMasMaker(self.speciesNameLabel, {
        make.centerY.equalTo(self.contentView);
        make.centerX.equalTo(self.contentView);
        make.height.equalTo(@20);
    });

    ACCMasMaker(self.outsideCircleView, {
        make.centerX.equalTo(self);
        make.bottom.equalTo(self.contentView.mas_top).offset(-8);
        make.size.equalTo(@(CGSizeMake(9, 9)));
    });
    _outsideCircleView.layer.cornerRadius = 4.5f;

    ACCMasMaker(self.centerView, {
        make.centerX.equalTo(self.outsideCircleView);
        make.centerY.equalTo(self.outsideCircleView);
        make.size.equalTo(@(CGSizeMake(5, 5)));
    });
    _centerView.layer.cornerRadius = 2.5f;
}

- (void)updateFrame
{
    CGFloat newWidth = 0;
    CGFloat newHeight = 0;

    // update self's frame
    CGSize textSize = [self.speciesNameLabel.text acc_sizeWithFont:self.speciesNameLabel.font width:300 maxLine:1];
    newWidth = 23 + textSize.width + 24;
    newHeight = 57;

    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, newWidth, newHeight);

    ACCBLOCK_INVOKE(self.coordinateDidChange);
}

#pragma mark - getter & setter
- (UILabel *)speciesNameLabel
{
    if (!_speciesNameLabel) {
        _speciesNameLabel = [[UILabel alloc] init];
        _speciesNameLabel.font = [self getSocialFont:20.f retry:3];
        _speciesNameLabel.textColor = [UIColor whiteColor];
    }
    return _speciesNameLabel;
}

- (UIView *)centerView
{
    if (!_centerView) {
        _centerView = [[UIView alloc] init];
        _centerView.layer.masksToBounds = true;
        _centerView.backgroundColor = [UIColor whiteColor];
    }
    return _centerView;
}

- (UIView *)outsideCircleView
{
    if (!_outsideCircleView) {
        _outsideCircleView = [[UIView alloc] init];
        _outsideCircleView.layer.masksToBounds = true;
        _outsideCircleView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    }
    return _outsideCircleView;
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _contentView.layer.borderWidth = 1;
        _contentView.layer.borderColor = [UIColor whiteColor].CGColor;
        _contentView.layer.cornerRadius = 20.f;
    }
    return _contentView;
}

#pragma mark - ACCStickerContentProtocol
- (void)contentDidUpdateToScale:(CGFloat)scale {
    scale = MAX(1, scale);
    self.currentScale = scale;
    CGFloat contentScaleFactor = MIN(3, scale) * [UIScreen mainScreen].scale;

    self.speciesNameLabel.contentScaleFactor = contentScaleFactor;
    
    [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.speciesNameLabel.layer];
}
@end
