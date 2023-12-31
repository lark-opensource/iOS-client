//
//  ACCRecognitionGrootStickerViewA.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/23.
//

#import "ACCRecognitionGrootStickerViewA.h"

#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKitSticker/ACCStickerUtils.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <Masonry/Masonry.h>

@interface ACCRecognitionGrootStickerViewA()

@property (nonatomic, strong) UILabel *speciesNameLabel;

@property (nonatomic, strong) UIImageView *avatarImageView;

@property (nonatomic, strong) UIImageView *vectorImageView;

@end

@implementation ACCRecognitionGrootStickerViewA

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
    [ACCWebImage() imageView:self.avatarImageView setImageWithURLArray:@[grootStickerModel.baikeIcon ?: @""]
                 placeholder:nil
                     options:ACCWebImageOptionsIgnoreAnimatedImage | ACCWebImageOptionsSetImageWithFadeAnimation
                  completion:^(UIImage *image, NSURL *url, NSError *error) {
        if (error || ACC_isEmptyString(grootStickerModel.baikeIcon)) {
            AWELogToolError2(@"groot_sticker", AWELogToolTagRecord | AWELogToolTagEdit, @"ACCRecognitionGrootStickerViewA download image failed: %@", error);
            self.avatarImageView.image = ACCResourceImage(@"icon_groot_placeholder");
            return;
        }
        ACCBLOCK_INVOKE(self.coordinateDidChange);
    }];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    ACCBLOCK_INVOKE(self.coordinateDidChange);
}

#pragma mark - private

- (void)setupUI
{
    self.backgroundColor = [UIColor colorWithPatternImage:ACCResourceImage(@"groot_viewA_background.png")];

    [self addSubview:self.speciesNameLabel];
    [self addSubview:self.avatarImageView];
    [self addSubview:self.vectorImageView];

    ACCMasMaker(self.avatarImageView, {
        make.centerY.equalTo(self);
        make.left.equalTo(self).offset(8);
        make.size.equalTo(@(CGSizeMake(30, 30)));
    });

    ACCMasMaker(self.speciesNameLabel, {
        make.centerY.equalTo(self);
        make.height.equalTo(@30);
        make.left.equalTo(self.avatarImageView.mas_right).offset(8);
    });

    ACCMasMaker(self.vectorImageView, {
        make.centerY.equalTo(self);
        make.left.equalTo(self.speciesNameLabel.mas_right).offset(6);
        make.size.equalTo(@(CGSizeMake(12, 20)));
        make.right.equalTo(self.mas_right).offset(-17);
    });
}

- (void)updateFrame
{
    CGFloat newWidth = 0;
    CGFloat newHeight = 47;
    self.layer.cornerRadius = newHeight / 2;
    self.layer.masksToBounds = YES;

    // update self's frame
    CGSize avatarImageSize = CGSizeMake(30, 30);
    CGSize vectorImageSize = CGSizeMake(12, 20);
    CGSize textSize = [self.speciesNameLabel.text acc_sizeWithFont:self.speciesNameLabel.font width:300 maxLine:1];

    newWidth = 8 + avatarImageSize.width + 8 + textSize.width + 6 + vectorImageSize.width + 17;
    CGRect newFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y, newWidth, newHeight);
    self.frame = CGRectMake(newFrame.origin.x, newFrame.origin.y, newFrame.size.width, newFrame.size.height);

    ACCBLOCK_INVOKE(self.coordinateDidChange);
}

#pragma mark - getter & setter

- (UIImageView *)avatarImageView
{
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        _avatarImageView.layer.cornerRadius = 15.f;
        _avatarImageView.layer.masksToBounds = true;
        _avatarImageView.layer.borderWidth = 1.f;
        _avatarImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    }
    return _avatarImageView;
}

- (UIImageView *)vectorImageView
{
    if (!_vectorImageView) {
        _vectorImageView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"icon_sticker_groot_vector")];
    }
    return _vectorImageView;
}

- (UILabel *)speciesNameLabel
{
    if (!_speciesNameLabel) {
        _speciesNameLabel = [[UILabel alloc] init];
        _speciesNameLabel.font = [self getSocialFont:24.f retry:3];
        _speciesNameLabel.textColor = [UIColor whiteColor];
    }
    return _speciesNameLabel;
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
