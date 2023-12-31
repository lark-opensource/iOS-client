//
//  ACCSearchBar.m
//  CameraClient
//
//  Created by bytedance on 2017/11/8.
//  Copyright © 2017 Bytedance. All rights reserved.
//

#import "ACCSearchBar.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UISearchBar+ACCAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCResourceHeaders.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

@interface ACCSearchBar() <UITextFieldDelegate>

@property (nonatomic, assign) ACCSearchBarColorStyle colorStyle;

@end

@implementation ACCSearchBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _needShowKeyBoard = YES;
        [self configureUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame colorStyle:(ACCSearchBarColorStyle)style
{
    self = [super initWithFrame:frame];
    if (self) {
        _needShowKeyBoard = YES;
        _colorStyle = style;
        [self configureUI];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    UITextField *searchField = self.acc_textField;
    CGRect bounds = searchField.frame;
    bounds.size.height = 36;
    bounds.origin.x = 0;
    bounds.origin.y = 0;

    bounds.size.width = self.bounds.size.width;
    bounds.origin.y = (self.bounds.size.height - bounds.size.height) / 2;
    searchField.frame = bounds;
    CGFloat verticalOffset = (searchField.font.lineHeight - ACCStandardFont(ACCFontClassH4, ACCFontWeightRegular).lineHeight) / 2;
    if (verticalOffset != 0 && !self.banAutoSearchTextPositionAdjustment) {
        self.searchTextPositionAdjustment = UIOffsetMake(9, verticalOffset);
    }
    searchField.font = ACCStandardFont(ACCFontClassH4, ACCFontWeightRegular);
    [self setPlaceholder: self.placeholder];
    if (self.needShowKeyBoard) {
        [self becomeFirstResponder];
    }
    
    if (@available(iOS 13.0, *)) {
        UIView *view = self.acc_textField.superview;
        ACCMasMaker(self.acc_textField,
         {
            make.left.equalTo(view);
            make.top.equalTo(view).mas_offset(bounds.origin.y);
            make.height.mas_equalTo(bounds.size.height);
            make.width.equalTo(view.mas_width);
        });
    }
    
    for (UIView *view in searchField.subviews) {
        if ([view isKindOfClass:[UIImageView class]]) {
            CGRect frame = view.frame;
            frame.size = CGSizeMake(24, 24);
            view.frame = frame;
        }
    }
}

- (void)configureUI
{
    self.backgroundImage = [[UIImage alloc] init];
    self.barTintColor = [UIColor clearColor];
    NSString *imageName = @"icSearshbarSearch";
    if (self.colorStyle == ACCSearchBarColorStyleD) {
        imageName = @"icDiscoverbarSearch";
    }

    [self setImage:[UIImage imageNamed:imageName] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    [self setPositionAdjustment:UIOffsetMake(1, 0) forSearchBarIcon:UISearchBarIconSearch];
    self.tintColor = ACCResourceColor(ACCUIColorPrimary);
    [self setSearchFieldBackgroundImage:[[UIImage alloc] init] forState:UIControlStateNormal];

    UITextField *searchField = self.acc_textField;
    searchField.textColor = ACCResourceColor(ACCUIColorTextPrimary);
    searchField.backgroundColor = ACCResourceColor(ACCUIColorBGInput);
    searchField.layer.cornerRadius = 2.0f;
    searchField.layer.masksToBounds = YES;
    searchField.delegate = self;
    self.ownSearchField = searchField;
   
    if (self.colorStyle == ACCSearchBarColorStyleD) {
        [self setImage:ACCResourceImage(@"icDiscoverbarSearch") forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
        self.tintColor = ACCResourceColor(ACCColorPrimary);
        searchField.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        searchField.backgroundColor = ACCResourceColor(ACCColorConstBGContainer5);
    }
    if (self.colorStyle != ACCSearchBarColorStyleD) {
        self.layer.cornerRadius = 2;
        self.layer.masksToBounds = YES;
    }
}

- (void)setPlaceholder:(NSString *)placeholder
{
    [super setPlaceholder:placeholder];
    if (!placeholder) {
        return;
    }
    NSMutableAttributedString *placeholderText = [[NSMutableAttributedString alloc] initWithString:placeholder];
    
    UIColor *placeholderColor = ACCResourceColor(ACCColorConstTextInverse4);
    if (self.colorStyle != ACCSearchBarColorStyleD) {
        placeholderColor = ACCResourceColor(ACCColorTextTertiary);
    }
    
    [placeholderText addAttribute:NSForegroundColorAttributeName
                        value:placeholderColor
                        range:NSMakeRange(0, placeholder.length)];
    [placeholderText addAttribute:NSFontAttributeName
                            value:ACCStandardFont(ACCFontClassH4, ACCFontWeightRegular)
                        range:NSMakeRange(0, placeholder.length)];
    self.ownSearchField.attributedPlaceholder = placeholderText;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if (self.clearButtonTappedBlock) {
        self.clearButtonTappedBlock();
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    ACCBLOCK_INVOKE(self.beginEditBlock);
} 

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    ACCBLOCK_INVOKE(self.endEditBlock);
}

@end
