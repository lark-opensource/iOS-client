//
//  CJPayStyleCheckBox.m
//  CJPay
//
//  Created by liyu on 2019/10/28.
//

#import "CJPayStyleCheckBox.h"
#import "CJPayProtocolManager.h"
#import "CJPayUIMacro.h"
#import "CJPayPrivateServiceHeader.h"

@interface CJPayStyleCheckBox ()

@property (nonatomic, strong) UIColor *cjStyleSelectedCheckBoxColor;
@property (nonatomic, copy) NSString *checkImgName;
@property (nonatomic, copy) NSString *noCheckImageName;

@end

@implementation CJPayStyleCheckBox

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_applyDefaultAppearance];
        [self p_updateStyle];
    }
    return self;
}

#pragma mark - Public

- (void)setSelectedCheckBoxColor:(UIColor *)selectedCheckBoxColor {
    self.cjStyleSelectedCheckBoxColor = selectedCheckBoxColor;
    
    [self p_updateStyle];
}

#pragma mark - Private

- (void)p_updateStyle {
    NSString *temp_nocheckImageName = self.noCheckImageName ?: @"cj_agree_nocheck_icon";
    NSString *temp_checkImageName = self.checkImgName ?: @"cj_agree_check_icon";
    UIImage *checkImageBg = [UIImage cj_imageWithColor:self.cjStyleSelectedCheckBoxColor];
    UIImage *noCheckImage = [UIImage cj_imageWithName:temp_nocheckImageName];
    UIImage *checkImage = [UIImage cj_imageWithName:temp_checkImageName];
    UIImage *selectedImage = [[checkImage cj_imageWithAnotherImage:checkImageBg] cj_imageWithAnotherImage:checkImage];
    UIImage *nomarlHightlightedImage = [noCheckImage cj_imageWithAnotherImage:checkImage];
    [self setImage:noCheckImage forState:UIControlStateNormal];
    [self setImage:nomarlHightlightedImage forState:UIControlStateHighlighted];
    [self setImage:selectedImage forState:UIControlStateSelected];
    [self setImage:selectedImage forState:UIControlStateSelected | UIControlStateHighlighted];
}

- (void)updateWithCheckImgName:(NSString *)checkImgName
                noCheckImgName:(NSString *)noCheckImgName {
    _checkImgName = checkImgName;
    _noCheckImageName = noCheckImgName;
    [self p_updateStyle];
}

- (void)p_applyDefaultAppearance {
    CJPayStyleCheckBox *appearance = [CJPayStyleCheckBox appearance];
    if (appearance.selectedCheckBoxColor == nil) {
        self.selectedCheckBoxColor = [UIColor cj_fe2c55ff];
    }
}

@end
