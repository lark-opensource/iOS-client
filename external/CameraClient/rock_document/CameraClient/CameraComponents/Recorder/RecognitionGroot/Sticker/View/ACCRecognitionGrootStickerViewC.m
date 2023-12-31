//
//  ACCRecognitionGrootStickerViewC.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/23.
//

#import "ACCRecognitionGrootStickerViewC.h"

#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKitSticker/ACCStickerUtils.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <Masonry/Masonry.h>

static CGFloat verticalValue = 6;

@interface ACCRecognitionGrootStickerViewC()

@property (nonatomic, strong) UILabel *speciesNameLabel;

@property (nonatomic, strong) UILabel *engNameLabel;

@property (nonatomic, strong) UIImageView *categoryImageView;

@property (nonatomic, strong) UILabel *categoryNameLabel;

@end

@implementation ACCRecognitionGrootStickerViewC

@synthesize coordinateDidChange = _coordinateDidChange;
@synthesize currentScale = _currentScale;

#pragma mark - public

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:1 alpha:0.96];
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
    self.engNameLabel.text = grootStickerModel.engName;
    self.categoryNameLabel.text = grootStickerModel.categoryName;
    if (ACC_isEmptyString(self.categoryNameLabel.text)) {
        self.categoryNameLabel.text = @"抖音自然";
    }

    [self updateFrame];
}

#pragma mark - private

- (void)setupUI
{
    [self addSubview:self.speciesNameLabel];
    [self addSubview:self.engNameLabel];
    [self addSubview:self.categoryImageView];
    [self addSubview:self.categoryNameLabel];

    // update subviews
    ACCMasMaker(self.speciesNameLabel, {
        make.centerX.equalTo(self);
        make.top.equalTo(self.mas_top).offset(9 + verticalValue);
    });

    ACCMasMaker(self.engNameLabel, {
        make.centerX.equalTo(self);
        make.top.equalTo(self.speciesNameLabel.mas_bottom).offset(1);
    });

    ACCMasUpdate(self.categoryImageView, {
        make.size.equalTo(@(CGSizeMake(8, 8)));
        make.top.equalTo(self.engNameLabel.mas_bottom).offset(6);
    });

    ACCMasMaker(self.categoryNameLabel, {
        make.left.equalTo(self.categoryImageView.mas_right).offset(5);
        make.centerY.equalTo(self.categoryImageView);
    });
}

- (void)updateFrame
{
    CGFloat newWidth = 0;
    CGFloat newHeight = 0;

    // update self's frame
    CGSize speciesNameTextSize = [self.speciesNameLabel.text acc_sizeWithFont:self.speciesNameLabel.font width:300 maxLine:1];
    CGSize engNameTextSize = [self.engNameLabel.text acc_sizeWithFont:self.engNameLabel.font width:300 maxLine:1];
    CGSize categoryNameTextSize = [self.categoryNameLabel.text acc_sizeWithFont:self.categoryNameLabel.font width:300 maxLine:1];
    CGSize categoryImageSize = CGSizeMake(8, 8);
    CGFloat categoryWidth = categoryNameTextSize.width + 5 + categoryImageSize.width;
    CGFloat maxWidth = MAX(MAX(speciesNameTextSize.width, engNameTextSize.width), categoryWidth);

    CGFloat tempWidth = MAX(speciesNameTextSize.width, categoryWidth) * 1.5f;
    if (engNameTextSize.width == maxWidth && engNameTextSize.width > tempWidth) {
        ACCMasUpdate(self.engNameLabel, {
            make.width.equalTo(@(tempWidth));
        });
        maxWidth = tempWidth;
    }
    newWidth = 18 * 2 + maxWidth;
    newHeight = 15 + speciesNameTextSize.height + 1 + categoryNameTextSize.height + 11;
    if (self.engNameLabel.text.length != 0) {
        newHeight += engNameTextSize.height + 3;
    }

    CGRect newFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y, newWidth, newHeight);
    self.frame = newFrame;

    ACCMasUpdate(self.categoryImageView, {
        make.left.equalTo(self).offset((newWidth - categoryWidth) * 0.5f);
    });

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

#pragma mark - setter & getter
- (UILabel *)speciesNameLabel
{
    if (!_speciesNameLabel) {
        _speciesNameLabel = [[UILabel alloc] init];
        _speciesNameLabel.numberOfLines = 1;
        _speciesNameLabel.font = [self getSocialFont:20.f retry:3];
        _speciesNameLabel.textColor = ACCResourceColor(ACCColorTextReverse);
    }
    return _speciesNameLabel;
}

- (UILabel *)engNameLabel
{
    if (!_engNameLabel) {
        _engNameLabel = [[UILabel alloc] init];
        _engNameLabel.font = [ACCFont() systemFontOfSize:8 weight:ACCFontWeightThin];
        _engNameLabel.textColor = [UIColor acc_colorWithHex:@"#28643B"];
        _engNameLabel.numberOfLines = 1;
        _engNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _engNameLabel;
}

- (UIImageView *)categoryImageView
{
    if (!_categoryImageView) {
        _categoryImageView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"icon_sticker_groot")];
    }
    return _categoryImageView;
}

- (UILabel *)categoryNameLabel
{
    if (!_categoryNameLabel) {
        _categoryNameLabel = [[UILabel alloc] init];
        _categoryNameLabel.font = [ACCFont() systemFontOfSize:10 weight:ACCFontWeightBold];
        _categoryNameLabel.textColor = ACCResourceColor(ACCColorTextReverse4);
        _categoryNameLabel.numberOfLines = 1;
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
    self.engNameLabel.contentScaleFactor = contentScaleFactor;

    [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.speciesNameLabel.layer];
    [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.categoryNameLabel.layer];
    [ACCStickerUtils applyScale:contentScaleFactor toLayer:self.engNameLabel.layer];
}

@end
