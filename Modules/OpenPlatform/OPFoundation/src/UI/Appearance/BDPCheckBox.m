//
//  BDPCheckBox.m
//  Timor
//
//  Created by liuxiangxin on 2019/6/18.
//

#import "BDPCheckBox.h"
#import "UIColor+BDPExtension.h"
#import "BDPBundle.h"
#import "BDPAppearanceHelper.h"

static const CGFloat kDefaultWidth = 24.f;
static const CGFloat kDefaultHeight = kDefaultWidth;

static NSString *const kDefaultSelectedTintColor = @"#F85959";

@interface BDPCheckBox ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIColor *> *tintColorDictionary;

@end

@implementation BDPCheckBox
@synthesize bdp_styleCategories = _bdp_styleCategories;

#pragma mark - init

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

#pragma mark - Life cycle

STANDARD_MOVE_TO_WINDOW_IMPL

STANDARD_LAYOUT_SUB_VIES_IMPL

#pragma mark - BDPAppearance Implementation

+ (instancetype)bdp_styleForCategory:(NSString *)category
{
    return (BDPCheckBox *)[[BDPCascadeStyleManager sharedManager] styleNodeForClass:self category:category];
}

- (void)setBdp_styleCategories:(NSArray<NSString *> *)bdp_styleCategories
{
    _bdp_styleCategories = bdp_styleCategories;
    
    for (NSString *category in bdp_styleCategories) {
        //pre set node
        [[BDPCascadeStyleManager sharedManager] styleNodeForClass:self.class category:category];
    }
}

#pragma mark - UI

- (void)setupUI
{
    self.backgroundColor = UIColor.bdp_WhiteColor1;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self addTarget:self action:@selector(onTap:) forControlEvents:UIControlEventTouchUpInside];

    [self setupImageView];
}

- (void)setupImageView
{
    UIImage *image = [UIImage imageNamed:@"tma_checkbox_select"
                                inBundle:BDPBundle.mainBundle
           compatibleWithTraitCollection:nil];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    [self addSubview:imageView];
    self.imageView = imageView;
    
    imageView.contentMode = UIViewContentModeCenter;
    
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [imageView.leftAnchor constraintEqualToAnchor:self.leftAnchor].active = YES;
    [imageView.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
    [imageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
    [imageView.rightAnchor constraintEqualToAnchor:self.rightAnchor].active = YES;
}

- (void)updateAppearance
{
    UIColor *tintColor = [self tintColorForStatus:self.status];
    self.layer.borderWidth = 1.f;
    self.layer.borderColor = tintColor.CGColor;
    
    switch (self.status) {
        case BDPCheckBoxStatusSelected:
            self.imageView.backgroundColor = tintColor;
            self.imageView.hidden = NO;
            break;
        case BDPCheckBoxStatusUnselected:
            self.imageView.hidden = YES;
            break;
        case BDPCheckBoxStatusDisable:
            self.imageView.hidden = NO;
            self.imageView.backgroundColor = tintColor;
            break;
            
    }
}

- (UIColor *)tintColorForStatus:(BDPCheckBoxStatus)status
{
    return [self.tintColorDictionary objectForKey:@(status)];
}

- (void)setTintColor:(UIColor *)color forStatus:(BDPCheckBoxStatus)status
{
    if (!color) {
        return;
    }
    
    [self.tintColorDictionary setObject:color forKey:@(status)];
    
    [self updateAppearance];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(kDefaultWidth, kDefaultHeight);
}

#pragma mark - Action

- (void)onTap:(id)sender
{
    switch (self.status) {
        case BDPCheckBoxStatusSelected:
            self.status = BDPCheckBoxStatusUnselected;
            break;
        case BDPCheckBoxStatusUnselected:
            self.status = BDPCheckBoxStatusSelected;
            break;
        case BDPCheckBoxStatusDisable:
            break;
    }
}

#pragma mark - Getter && Setter

- (NSMutableDictionary<NSNumber *, UIColor *> *)tintColorDictionary
{
    if (!_tintColorDictionary) {
        _tintColorDictionary = [NSMutableDictionary dictionary];
        UIColor *color = [UIColor colorWithHexString:kDefaultSelectedTintColor];
        if (color) {
            [_tintColorDictionary setObject:color forKey:@(BDPCheckBoxStatusSelected)];
        }
        [_tintColorDictionary setObject:UIColor.bdp_BlackColor7 forKey:@(BDPCheckBoxStatusUnselected)];
        [_tintColorDictionary setObject:UIColor.bdp_BlackColor7 forKey:@(BDPCheckBoxStatusDisable)];
    }
    
    return _tintColorDictionary;
}

- (void)setStatus:(BDPCheckBoxStatus)status
{
    _status = status;
    
    [self updateAppearance];
}

@end
