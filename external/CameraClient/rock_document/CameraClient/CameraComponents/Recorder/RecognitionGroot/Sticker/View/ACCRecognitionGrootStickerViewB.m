//
//  ACCRecognitionGrootStickerViewB.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/23.
//

#import "ACCRecognitionGrootStickerViewB.h"

#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKitSticker/ACCStickerUtils.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <Masonry/Masonry.h>

static CGFloat verticalValue = 6;

@interface ACCRecognitionGrootStickerViewB()

@property (nonatomic, strong) UILabel *speciesNameLabel;

@property (nonatomic, strong) UILabel *categoryNameLabel;

@property (nonatomic, strong) UIImageView *avatarImageView;

@end

@implementation ACCRecognitionGrootStickerViewB

@synthesize coordinateDidChange = _coordinateDidChange;
@synthesize currentScale = _currentScale;

#pragma mark - public

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:1 alpha:0.96f];
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
    self.categoryNameLabel.text = grootStickerModel.categoryName;
    if (ACC_isEmptyString(self.categoryNameLabel.text)) {
        self.categoryNameLabel.text = @"抖音自然";
    }

    [self updateFrame];

    [ACCWebImage() imageView:self.avatarImageView setImageWithURLArray:@[grootStickerModel.baikeIcon ?: @""]
                 placeholder:nil
                     options:ACCWebImageOptionsIgnoreAnimatedImage | ACCWebImageOptionsSetImageWithFadeAnimation
                  completion:^(UIImage *image, NSURL *url, NSError *error) {
        if (error || ACC_isEmptyString(grootStickerModel.baikeIcon)) {
            self.avatarImageView.image = ACCResourceImage(@"icon_groot_placeholder");
            AWELogToolError2(@"groot_sticker", AWELogToolTagRecord | AWELogToolTagEdit, @"ACCRecognitionGrootStickerViewB download image failed: %@", error);
            return;
        }
        ACCBLOCK_INVOKE(self.coordinateDidChange);
    }];
}

#pragma mark - private

- (void)setupUI
{
    [self addSubview:self.speciesNameLabel];
    [self addSubview:self.categoryNameLabel];
    [self addSubview:self.avatarImageView];

    ACCMasMaker(self.avatarImageView, {
        make.centerY.equalTo(self).offset(verticalValue / 2);
        make.left.equalTo(self).offset(12);
        make.size.equalTo(@(CGSizeMake(36, 36)));
    });

    ACCMasMaker(self.speciesNameLabel, {
        make.left.equalTo(self.avatarImageView.mas_right).offset(8);
        make.top.equalTo(self.avatarImageView.mas_top).offset(-3);
    });

    ACCMasMaker(self.categoryNameLabel, {
        make.left.equalTo(self.speciesNameLabel.mas_left).offset(-1);
        make.top.equalTo(self.speciesNameLabel.mas_bottom).offset(2);
    });
}

- (void)updateFrame
{
    CGFloat newWidth = 0;
    CGFloat newHeight = 0;

    // update self's frame
    CGSize avatarImageSize = CGSizeMake(36, 36);
    CGSize speciesNameLabelSize = [self.speciesNameLabel.text acc_sizeWithFont:self.speciesNameLabel.font width:300 maxLine:1];
    CGSize categoryNameLabelSize = [self.categoryNameLabel.text acc_sizeWithFont:self.categoryNameLabel.font width:300 maxLine:1];

    newWidth = 12 + avatarImageSize.width + 8 + MAX(speciesNameLabelSize.width, categoryNameLabelSize.width) + 18;
    newHeight = 11 + speciesNameLabelSize.height + 1 + categoryNameLabelSize.height + 8;
    CGRect newFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y, newWidth, newHeight);
    self.frame = CGRectMake(newFrame.origin.x, newFrame.origin.y, newFrame.size.width, newFrame.size.height);

    ACCBLOCK_INVOKE(self.coordinateDidChange);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    UIBezierPath *bezierPath = [self p_createPath];
    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.path = bezierPath.CGPath;

    self.layer.mask = mask;
    ACCBLOCK_INVOKE(self.coordinateDidChange);
}

- (UIBezierPath *)p_createPath
{
    CGSize viewSize = self.frame.size;
    CGFloat triangleBottom = viewSize.width / 9;

    CGFloat tris = viewSize.width * 0.5 - (triangleBottom * 0.5);
    CGFloat trie = viewSize.width * 0.5 + (triangleBottom * 0.5);
    CGFloat radius = 8.f;

    UIBezierPath *path = [UIBezierPath bezierPath];

    // [origin point] left top‘s corner
    [path moveToPoint:CGPointMake(radius, verticalValue)];
    [path addArcWithCenter:CGPointMake(radius, verticalValue + radius)
                        radius:radius
                    startAngle:M_PI
                      endAngle:3 * M_PI_2
                     clockwise:YES];

    // The triangle and circular arc
    CGFloat triangleRadius = 2.f;
    [path addLineToPoint:CGPointMake(tris, verticalValue)];
    [path addArcWithCenter:CGPointMake(viewSize.width / 2, triangleRadius)
                        radius:triangleRadius
                    startAngle:-3 * M_PI / 4
                      endAngle:-M_PI_2 / 2
                     clockwise:YES];
    [path addLineToPoint:CGPointMake(trie, verticalValue)];

    // right top‘s corner
    [path addLineToPoint:CGPointMake(viewSize.width - radius, verticalValue)];
    [path addArcWithCenter:CGPointMake(viewSize.width - radius, verticalValue + radius)
                        radius:radius
                    startAngle:M_PI_2
                      endAngle:0
                     clockwise:YES];

    // right bottom‘s corner
    [path addLineToPoint:CGPointMake(viewSize.width, viewSize.height - radius)];
    [path addArcWithCenter:CGPointMake(viewSize.width - radius, viewSize.height - radius)
                        radius:radius
                    startAngle:0
                      endAngle:M_PI_2
                     clockwise:YES];

    // left bottom‘s corner
    [path addLineToPoint:CGPointMake(radius, viewSize.height)];
    [path addArcWithCenter:CGPointMake(radius, viewSize.height - radius)
                        radius:radius
                    startAngle:3 * M_PI_2
                      endAngle:M_PI
                     clockwise:YES];
    [path addLineToPoint:CGPointMake(0, verticalValue + radius)];
    [path closePath];

    return path;
}

#pragma mark - Getters and Setters

- (UIImageView *)avatarImageView
{
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.layer.cornerRadius = 18.f;
        _avatarImageView.layer.masksToBounds = true;
    }
    return _avatarImageView;
}

- (UILabel *)speciesNameLabel
{
    if (!_speciesNameLabel) {
        _speciesNameLabel = [[UILabel alloc] init];
        _speciesNameLabel.font = [self getSocialFont:22.f retry:3];
        _speciesNameLabel.textColor = ACCResourceColor(ACCColorTextReverse);
    }
    return _speciesNameLabel;
}

- (UILabel *)categoryNameLabel
{
    if (!_categoryNameLabel) {
        _categoryNameLabel = [[UILabel alloc] init];
        _categoryNameLabel.font = [ACCFont() systemFontOfSize:12];
        _categoryNameLabel.textColor = [UIColor acc_colorWithHex:@"#161823" alpha:0.6];
    }
    return _categoryNameLabel;
}

#pragma mark - ACCStickerContentProtocol
- (void)contentDidUpdateToScale:(CGFloat)scale {
    scale = MAX(1, scale);
    self.currentScale = scale;
    CGFloat contentScaleFactor = MIN(3, scale) * [UIScreen mainScreen].scale;
    self.speciesNameLabel.contentScaleFactor = contentScaleFactor;
    self.categoryNameLabel.contentScaleFactor = contentScaleFactor;

    [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.speciesNameLabel.layer];
    [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.categoryNameLabel.layer];
}

@end
