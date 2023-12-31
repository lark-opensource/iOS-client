//
//  ACCTagsSearchBar.m
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/10/9.
//

#import "ACCTagsSearchBar.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UISearchBar+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import "UIImage+ACCUIKit.h"

static const CGFloat kACCTagsItemSearchBarHeight = 36.f;

@interface ACCTagsSearchBar ()<UITextFieldDelegate>
@property (nonatomic, strong, readwrite) UITextField *textField;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UIImageView *searchIconView;
@property (nonatomic, strong) UIView *leftView;
@property (nonatomic, assign) BOOL showsCancelButton;
@property (nonatomic, assign) CGFloat canceelButtonWidth;
@end

@implementation ACCTagsSearchBar

- (instancetype)initWithLeftView:(UIView *)leftView leftViewWidth:(CGFloat)leftViewWidth
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _cancelButton = [[UIButton alloc] init];
        NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:@"取消"
                                                                        attributes:@{
                                                                            NSFontAttributeName : [ACCFont() systemFontOfSize:15.f],
                                                                            NSForegroundColorAttributeName : ACCResourceColor(ACCColorConstTextInverse)
                                                                        }];
        CGRect rect = [attrTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, [self searchBarHeight]) options:NSStringDrawingUsesLineFragmentOrigin context:NULL];
        _canceelButtonWidth = rect.size.width + 2;
        [_cancelButton setAttributedTitle:attrTitle forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        _cancelButton.alpha = 0.f;
        [self addSubview:_cancelButton];
        ACCMasMaker(_cancelButton, {
            make.left.equalTo(self.mas_right).offset(-8.f);
            make.centerY.equalTo(self);
            make.width.equalTo(@(_canceelButtonWidth));
            make.height.equalTo(self);
        });
        
        _containerView = [[UIView alloc] init];
        _containerView.backgroundColor = ACCResourceColor(ACCColorConstBGContainer5);
        _containerView.layer.cornerRadius = [self searchBarHeight] / 2.f;
        _containerView.layer.masksToBounds = YES;
        [self addSubview:_containerView];
        ACCMasMaker(_containerView, {
            make.left.equalTo(self).offset(16.f);
            make.right.equalTo(_cancelButton.mas_left).offset(-8.f);
            make.top.bottom.equalTo(self);
        })
        
        if (!leftView) {
            leftView = [[UIView alloc] init];
            leftViewWidth = 0.f;
        }
        _leftView = leftView;
        [_containerView addSubview:_leftView];
        ACCMasMaker(_leftView, {
            make.left.equalTo(_containerView);
            make.width.equalTo(@(leftViewWidth));
            make.top.bottom.equalTo(_containerView);
        })
        
        _searchIconView = [[UIImageView alloc] init];
        _searchIconView.image = ACCResourceImage(@"icon_edit_tags_search");
        [_containerView addSubview:_searchIconView];
        ACCMasMaker(_searchIconView, {
            make.left.equalTo(_leftView.mas_right).offset(8.f);
            make.centerY.equalTo(_containerView);
            make.width.height.equalTo(@24.f);
        });
        
        _clearButton = [[UIButton alloc] init];
        _clearButton.backgroundColor = [UIColor clearColor];
        [_clearButton setImage:ACCResourceImage(@"icon_edit_tags_clear") forState:UIControlStateNormal];
        _clearButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-6, -4, -6, -4);
        _clearButton.hidden = YES;
        [_clearButton addTarget:self action:@selector(handleClearButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [_containerView addSubview:_clearButton];
        ACCMasMaker(_clearButton, {
            make.right.equalTo(_containerView).offset(-8.f);
            make.centerY.equalTo(_containerView);
            make.width.height.equalTo(@24.f);
        })
        
        _textField = [[UITextField alloc] init];
        _textField.delegate = self;
        _textField.backgroundColor = [UIColor clearColor];
        _textField.tintColor = ACCResourceColor(ACCColorPrimary);
        _textField.textColor = ACCResourceColor(ACCColorConstTextInverse);
        _textField.returnKeyType = UIReturnKeySearch;
        [_containerView addSubview:_textField];
        ACCMasMaker(_textField, {
            make.left.equalTo(_searchIconView.mas_right).offset(4.f);
            make.right.equalTo(_clearButton.mas_left).offset(-4.f);
            make.top.bottom.equalTo(_containerView);
        });
    }
    return self;
}

- (CGFloat)searchBarHeight
{
    return kACCTagsItemSearchBarHeight;
}

- (void)setShowsCancelButton:(BOOL)showsCancelButton
{
    if (showsCancelButton != _showsCancelButton) {
        _showsCancelButton = showsCancelButton;
        if (showsCancelButton) {
            ACCMasReMaker(self.cancelButton, {
                make.right.equalTo(self).offset(-16.f);
                make.centerY.equalTo(self);
                make.height.equalTo(self);
                make.width.equalTo(@(self.canceelButtonWidth));
            });
        } else {
            ACCMasReMaker(self.cancelButton, {
                make.left.equalTo(self.mas_right).offset(-8.f);
                make.centerY.equalTo(self);
                make.width.equalTo(@(self.canceelButtonWidth));
                make.height.equalTo(self);
            });
        }
        [UIView animateWithDuration:0.2 animations:^{
            self.cancelButton.alpha = showsCancelButton ? 1.f : 0.f;
            [self layoutIfNeeded];
        }];
    }
}

#pragma mark - Event Handling

- (void)handleClearButtonClicked
{
    self.textField.text = @"";
    [self handleTextDidChangeWithNewText:@""];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self setShowsCancelButton:YES];
    self.clearButton.hidden = ACC_isEmptyString(textField.text);
    [self.delegate searchBarTextDidBeginEditing:self];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self handleTextDidChangeWithNewText:newString];
    return YES;
}

- (void)cancelButtonTapped
{
    [self setShowsCancelButton:NO];
    [self handleClearButtonClicked];
    [self.textField resignFirstResponder];
    [self.delegate searchBarCancelButtonClicked:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (ACC_isEmptyString(textField.text)) {
        return NO;
    }
    [self resignFirstResponder];
    return YES;
}

- (BOOL)resignFirstResponder
{
    [super resignFirstResponder];
    self.clearButton.hidden = YES;
    return [self.textField resignFirstResponder];
}

- (void)handleTextDidChangeWithNewText:(NSString *)newText
{
    self.clearButton.hidden = ACC_isEmptyString(newText);
    [self.delegate searchBar:self textDidChange:newText];
}


@end
