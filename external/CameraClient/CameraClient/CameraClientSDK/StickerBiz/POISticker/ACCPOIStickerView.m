//
//  ACCPOIStickerView.m
//  CameraClient
//
//  Created by Yangguocheng on 2020/6/15.
//

#import "ACCPOIStickerView.h"
#import <CreativeKit/UIView+AWESubtractMask.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/NSString+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCPOIStickerView ()

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *darkBGView;

@end

@implementation ACCPOIStickerView
@synthesize transparent = _transparent;
@synthesize triggerDragDeleteCallback = _triggerDragDeleteCallback;

CGFloat kACCPOIDisplayLeftMargin = 12;
CGFloat kACCPOIDisplayTopMargin = 6;
CGFloat kACCPOIDisplayBorderMargin = 6;
CGFloat kACCPOIContainerInset = 20;
CGFloat kACCTopMaskMargin = 52;

static const CGFloat kACCPOIDefaultFontSize = 28.f;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self addSubview:self.darkBGView];
        [self addSubview:self.contentView];
    }
    
    return self;
}

- (void)updateWithModel:(ACCPOIStickerModel *)model
{
    if (!model || [self isSamePOI:model]) {
        return;
    }
    
    _model = model;
    [self p_updateFrame];
    [self.contentView awe_setSubtractMaskView:[self poiLblWithAlpha:0.8f]];
}

#pragma mark - Private Methods

- (void)p_updateFrame
{
    CGSize contentSize  = [self poiContentSize];
    if (contentSize.width <= 0.0001) {
        contentSize.width = 20;
    } else if (contentSize.width > (ACC_SCREEN_WIDTH - 32)) {
        contentSize.width = ACC_SCREEN_WIDTH - 32;
    }
    
    CGFloat selfWidth = contentSize.width + (kACCPOIDisplayLeftMargin + kACCPOIDisplayBorderMargin) * 2;
    CGFloat selfHeight = contentSize.height + (kACCPOIDisplayTopMargin + kACCPOIDisplayBorderMargin) * 2;

    self.frame = CGRectMake(0, 0, selfWidth, selfHeight);
    CGPoint basicCenterInScreen = CGPointMake(ACC_SCREEN_WIDTH * 0.5, ACC_SCREEN_HEIGHT * 0.5);
    if (@available(iOS 9.0, *)) {
        basicCenterInScreen = [[[UIApplication sharedApplication].delegate window] convertPoint:basicCenterInScreen toView:self];
    }
    self.center = CGPointMake(basicCenterInScreen.x, basicCenterInScreen.y);

    self.contentView.frame = CGRectMake(kACCPOIDisplayLeftMargin + kACCPOIDisplayBorderMargin - kACCPOIContainerInset, kACCPOIDisplayTopMargin + kACCPOIDisplayBorderMargin - kACCPOIContainerInset, contentSize.width, contentSize.height);
    self.contentView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    self.darkBGView.frame = CGRectMake(self.contentView.frame.origin.x+2, self.contentView.frame.origin.y+2, self.contentView.frame.size.width-4, self.contentView.frame.size.height-4);
    self.darkBGView.center = self.contentView.center;
    if (self.coordinateDidChange != NULL) {
        self.coordinateDidChange();
    }
}

- (BOOL)isSamePOI:(ACCPOIStickerModel *)model
{
    return [self.model.poiID isEqualToString:model.poiID] && [self.model.poiName isEqualToString:model.poiName];
}

- (CGSize)poiContentSize
{
    NSString *poiContent = [self poiContent:self.model.poiName];
    
    CGFloat height = 34;
    CGFloat width = [poiContent acc_widthWithFont:[ACCFont() systemFontOfSize:kACCPOIDefaultFontSize weight:ACCFontWeightMedium] height:34];
    if (width > (ACC_SCREEN_WIDTH - 16 * 2 - 16 * 2 + 2)) {
        height = 26;
        width = [poiContent acc_widthWithFont:[ACCFont() systemFontOfSize:20 weight:ACCFontWeightMedium] height:26];
    }
    
    return CGSizeMake(width + 16 * 2 - 10, height + 2 * 8); // -10因为文本时左对齐
}

- (UILabel *)poiLblWithAlpha:(CGFloat)alpha
{
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(14, 0, self.contentView.frame.size.width-14, self.contentView.frame.size.height)];
    label1.textColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:alpha];
    label1.textAlignment = NSTextAlignmentLeft;
    label1.attributedText = [self poiAttributedStringWithName:self.model.poiName];
    return label1;
}

- (NSString *)poiContent:(NSString *)poiName
{
    NSString *icon = @"\U0000e900"; // poi icon
    NSString *fontName = @"icomoon";
    NSString *poiAddress = poiName;
    
    NSString *totalStr;
    NSString *fontFullName = [NSString stringWithFormat:@"%@.ttf",fontName];
    NSURL *poiFontPath = [NSURL fileURLWithPath:ACCResourceFile(fontFullName)];
    UIFont *iconFont = [ACCFont() iconFontWithPath:poiFontPath name:fontName size:20];
    if (iconFont) {
        totalStr = [NSString stringWithFormat:@"%@ %@",icon,poiAddress];
    } else {
        totalStr = poiAddress;
    }
    return totalStr;
}

- (NSAttributedString *)poiAttributedStringWithName:(NSString *)poiName
{
    NSString *fontName = @"icomoon";
    NSString *totalStr = [self poiContent:self.model.poiName] ? : @"";
    NSString *fontFullName = [NSString stringWithFormat:@"%@.ttf",fontName];
    NSURL *poiFontPath = [NSURL fileURLWithPath:ACCResourceFile(fontFullName)];
    
    NSMutableAttributedString *atts = [[NSMutableAttributedString alloc]initWithString:totalStr];
    
    // fix AME-85516, avoid nil crash
    if (!poiName) {
        return atts;
    }
    NSRange poiRange = [totalStr rangeOfString:poiName];
    
    CGFloat width = [totalStr acc_widthWithFont:[ACCFont() systemFontOfSize:kACCPOIDefaultFontSize weight:ACCFontWeightMedium] height:34];
    if (width > (ACC_SCREEN_WIDTH - 16*2 - 16*2 + 2)) {//contaner screen edge gap 16*2,textview container gap 16*2, 2-compensation
        UIFont *iconFont = [ACCFont() iconFontWithPath:poiFontPath name:fontName size:16];
        if (iconFont) {
            [atts addAttribute:NSFontAttributeName value:iconFont range:NSMakeRange(0, poiRange.location)];
            [atts addAttribute:NSBaselineOffsetAttributeName value:@0.5 range:NSMakeRange(0, poiRange.location)];
            [atts addAttribute:NSKernAttributeName value:@(-1.0) range:NSMakeRange(0, poiRange.location)];
        }
        [atts addAttribute:NSFontAttributeName value:[ACCFont() systemFontOfSize:20 weight:ACCFontWeightMedium] range:poiRange];
    } else {
        UIFont *iconFont = [ACCFont() iconFontWithPath:poiFontPath name:fontName size:20];
        if (iconFont) {
            [atts addAttribute:NSFontAttributeName value:iconFont range:NSMakeRange(0, poiRange.location)];
            [atts addAttribute:NSBaselineOffsetAttributeName value:@1.5 range:NSMakeRange(0, poiRange.location)];
            [atts addAttribute:NSKernAttributeName value:@(-1.0) range:NSMakeRange(0, poiRange.location)];
        }
        [atts addAttribute:NSFontAttributeName value:[ACCFont() systemFontOfSize:kACCPOIDefaultFontSize weight:ACCFontWeightMedium] range:poiRange];
    }
    
    return atts;
}

#pragma mark - Getter

- (UIView *)darkBGView
{
    if (!_darkBGView) {
        _darkBGView = [[UIView alloc] initWithFrame:CGRectZero];
        _darkBGView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5f];
        _darkBGView.layer.cornerRadius = 6.f;
        _darkBGView.layer.masksToBounds = YES;
    }
    return _darkBGView;
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentView.backgroundColor = [UIColor whiteColor];
        _contentView.layer.cornerRadius = 6.f;
        _contentView.layer.masksToBounds = YES;
    }
    
    return _contentView;
}

#pragma mark - ACCStickerContentProtocol

@synthesize coordinateDidChange;
@synthesize stickerContainer;

- (id)copyForContext:(id)contextId
{
    ACCPOIStickerView *viewCopy = [[[self class] alloc] initWithFrame:self.frame];
    ACCPOIStickerModel *modelCopy = [[ACCPOIStickerModel alloc] init];
    modelCopy.effectIdentifier = self.model.effectIdentifier;
    modelCopy.poiID = self.model.poiID;
    modelCopy.poiName = self.model.poiName;
    modelCopy.interactionStickerInfo = self.model.interactionStickerInfo;
    [viewCopy updateWithModel:modelCopy];

    return viewCopy;
}

- (void)updateWithInstance:(id)instance context:(id)contextId
{
    
}

#pragma mark - ACCStickerEditContentProtocol
- (void)setTransparent:(BOOL)transparent
{
    _transparent = transparent;
    
    self.alpha = transparent? 0.5: 1.0;
}

@end
