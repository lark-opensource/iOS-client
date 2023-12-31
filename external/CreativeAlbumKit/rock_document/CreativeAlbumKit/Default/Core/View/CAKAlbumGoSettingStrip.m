//
//  CAKAlbumGoSettingStrip.m
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2020/9/12.
//
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIFont+ACCAdditions.h>

#import "CAKAlbumGoSettingStrip.h"
#import "UIColor+AlbumKit.h"
#import "UIImage+AlbumKit.h"
#import "CAKLanguageManager.h"

static BOOL CAKAlbumGoSettingStripClosedByUser;

@interface CAKAlbumGoSettingStrip ()

@property (nonatomic, strong) UIView *topLine;

@end

@implementation CAKAlbumGoSettingStrip

+ (BOOL)closedByUser
{
    return CAKAlbumGoSettingStripClosedByUser;
}

+ (void)setClosedByUser
{
    CAKAlbumGoSettingStripClosedByUser = YES;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = CAKResourceColor(ACCUIColorConstBGContainer);
        _topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 0.5)];
        _topLine.backgroundColor = CAKResourceColor(ACCUIColorConstLineSecondary);
        [self addSubview:_topLine];
        CGFloat widthScaleFactor = ACC_SCREEN_WIDTH / 375;
        // label
        _label = [[UILabel alloc] initWithFrame:CGRectMake(16 * widthScaleFactor, 10, 313 * widthScaleFactor, 20)];
        NSString *text1 = CAKLocalizedString(@"authorization_gotosettings", @"\"%@\" to allow access to photos.");
        NSRange specifierRange = [text1 rangeOfString:@"%@"];
        NSAssert(specifierRange.length > 0, @"provided text should containt one specifier");
        NSString *text2 = CAKLocalizedString(@"authorization_gotosetting", @"Go to settings");
        NSString *text = [NSString stringWithFormat:text1, text2];
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:text];
        NSRange range1 = NSMakeRange(0, specifierRange.location);
        [attrString setAttributes:@{
            NSForegroundColorAttributeName:CAKResourceColor(ACCColorTextReverse),
            NSFontAttributeName:[UIFont acc_systemFontOfSize:14 weight:ACCFontWeightRegular]
        } range:range1];
        NSRange range2 = NSMakeRange(specifierRange.location, text2.length);
        [attrString setAttributes:@{
            NSForegroundColorAttributeName:CAKResourceColor(ACCColorPrimary),
            NSFontAttributeName:[UIFont acc_systemFontOfSize:14 weight:ACCFontWeightMedium]
        } range:range2];
        NSRange range3 = NSMakeRange(specifierRange.location + text2.length, text.length - (specifierRange.location + text2.length));
        [attrString setAttributes:@{
            NSForegroundColorAttributeName:CAKResourceColor(ACCColorTextReverse),
            NSFontAttributeName:[UIFont acc_systemFontOfSize:14 weight:ACCFontWeightRegular]
        } range:range3];
        _label.attributedText = [attrString copy];
        _label.userInteractionEnabled = YES;
        [self addSubview:_label];
        // closeButton
        _closeButton = [[UIButton alloc] initWithFrame:CGRectMake(351 * widthScaleFactor, 12, 16, 16)];
        [_closeButton setImage:CAKResourceImage(@"icon_Album_GoSettingStrip_Close") forState:UIControlStateNormal];
        [self addSubview:_closeButton];

    }
    return self;
}

@end
