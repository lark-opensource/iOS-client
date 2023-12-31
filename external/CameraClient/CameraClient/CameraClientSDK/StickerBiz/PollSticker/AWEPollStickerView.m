//
//  AWEPollStickerView.m
//  AAWELaunchMainPlaceholder-iOS8.0
//
//  Created by chengfei xiao on 2019/4/26.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEPollStickerView.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>


#define kAWEPollStickerOPTCorner   22.f
#define kAWEPollStickerOPTWidth    167.f
#define kAWEPollStickerOPTBGWidth  197.f



@interface AWEPollStickerView ()<UITextViewDelegate>

@property (nonatomic,   copy) NSString *placeHolderStr;
@property (nonatomic, strong) UIFont *placeHolderFont;
@property (nonatomic,   copy) NSString *opt1PlaceHolder;
@property (nonatomic,   copy) NSString *opt2PlaceHolder;

@property (nonatomic, assign) CGFloat placeHolderWidth;
@property (nonatomic, assign) CGFloat opt1PlaceHolderWidth;
@property (nonatomic, assign) CGFloat opt2PlaceHolderWidth;
@property (nonatomic, assign) BOOL reLayoutQuestionWhenEmpty;

@property (nonatomic, assign) BOOL hasAddShadow;
@end


@implementation AWEPollStickerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.currentEditType = AWEPollStickerEditTypeNone;
        self.placeHolderStr = ACCLocalizedString(@"voting_sticker_title", @"提个问题吧...");
        self.placeHolderFont = [ACCFont() systemFontOfSize:20 weight:ACCFontWeightHeavy];
        self.opt1PlaceHolder = ACCLocalizedString(@"com_mig_yes", @"是的");
        self.opt2PlaceHolder = ACCLocalizedString(@"voting_sticker_option_2", @"不是");
        
        [self addSubview:self.questionView];
        
        [self addSubview:self.option1BGView];
        [self.option1BGView addSubview:self.option1View];
        
        [self addSubview:self.option2BGView];
        [self.option2BGView addSubview:self.option2View];
        
        //default
        [self refreshPlaceHolderWidth];
        
        [self p_makeSubViewConstraints];
        [self p_updateOPT1Constraints];
        [self p_updateOPT2Constraints];
        [self updateQuestionConstraints];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.option1BGView.bounds.size.width && self.option1BGView.bounds.size.width && !self.hasAddShadow) {
        self.hasAddShadow = YES;
        [self addShadowToView:self.option2BGView shadowLayer:self.op2ShadowLayer withOpacity:0.6 shadowRadius:3 andCornerRadius:kAWEPollStickerOPTCorner];
        [self addShadowToView:self.option1BGView shadowLayer:self.op1ShadowLayer withOpacity:0.6 shadowRadius:3 andCornerRadius:kAWEPollStickerOPTCorner];
    }
    self.op1ShadowLayer.frame = self.option1BGView.frame;
    self.op2ShadowLayer.frame = self.option2BGView.frame;
}

#pragma mark - lazy load

- (UITextView *)questionView
{
    if (!_questionView) {
        _questionView = [[UITextView alloc] init];
        _questionView.tintColor = ACCResourceColor(ACCUIColorPrimary);
        _questionView.font = [ACCFont() systemFontOfSize:20 weight:ACCFontWeightHeavy];
        _questionView.textColor = [UIColor whiteColor];
        _questionView.scrollEnabled = NO;
        _questionView.showsVerticalScrollIndicator = NO;
        _questionView.showsHorizontalScrollIndicator = NO;
        _questionView.textAlignment = NSTextAlignmentLeft;
        _questionView.backgroundColor = [UIColor clearColor];
        _questionView.returnKeyType = UIReturnKeyDefault;
        _questionView.autocorrectionType = UITextAutocorrectionTypeNo;
        _questionView.textContainer.maximumNumberOfLines = kAWEPollStickerMaxLines;
        _questionView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
        _questionView.textContainerInset = UIEdgeInsetsMake(4, 4, 4, 4);
        _questionView.textContainer.lineFragmentPadding = 0;
        _questionView.placeholderTextView.textContainer.maximumNumberOfLines = 1;
        _questionView.placeholderTextView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
        _questionView.attributedPlaceholder = [[NSMutableAttributedString alloc] initWithString:self.placeHolderStr
                                                                                     attributes:@{NSFontAttributeName: _questionView.font,
                                                                                                  NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
    }
    return _questionView;
}

- (UIView *)option1BGView {
    if (!_option1BGView) {
        _option1BGView = [UIView new];
        _option1BGView.backgroundColor = [UIColor whiteColor];
        _option1BGView.layer.cornerRadius = kAWEPollStickerOPTCorner;
        _option1BGView.layer.masksToBounds = YES;
    }
    return _option1BGView;
}

- (UITextView *)option1View
{
    if (!_option1View) {
        _option1View = [[UITextView alloc] initWithFrame:CGRectZero];
        _option1View.backgroundColor = [UIColor whiteColor];
        _option1View.delegate = self;
        _option1View.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
        _option1View.tintColor = ACCResourceColor(ACCUIColorPrimary);
        _option1View.textColor = ACCResourceColor(ACCUIColorConstTextPrimary);
        
        _option1View.scrollEnabled = NO;
        _option1View.showsVerticalScrollIndicator = NO;
        _option1View.showsHorizontalScrollIndicator = NO;
        _option1View.textContainer.maximumNumberOfLines = 1;
        _option1View.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
        _option1View.textContainerInset = UIEdgeInsetsMake(6, 6, 6, 6);
        _option1View.textContainer.lineFragmentPadding = 0;
        
        _option1View.textAlignment = NSTextAlignmentCenter;
        _option1View.returnKeyType = UIReturnKeyDone;
        _option1View.autocorrectionType = UITextAutocorrectionTypeNo;
        _option1View.placeholderTextView.textContainer.maximumNumberOfLines = 1;
        _option1View.placeholderTextView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
        _option1View.attributedPlaceholder = [[NSMutableAttributedString alloc] initWithString:self.opt1PlaceHolder
                                                                                     attributes:@{NSFontAttributeName: _option1View.font,
                                                                                                  NSForegroundColorAttributeName: [UIColor lightGrayColor]
                                                                                                  }];
    }
    return _option1View;
}

- (UIView *)option2BGView {
    if (!_option2BGView) {
        _option2BGView = [UIView new];
        _option2BGView.backgroundColor = [UIColor whiteColor];
        _option2BGView.layer.cornerRadius = kAWEPollStickerOPTCorner;
        _option2BGView.layer.masksToBounds = YES;
    }
    return _option2BGView;
}

- (UITextView *)option2View
{
    if (!_option2View) {
        _option2View = [[UITextView alloc] initWithFrame:CGRectZero];
        _option2View.backgroundColor = [UIColor whiteColor];
        _option2View.delegate = self;
        _option2View.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
        _option2View.tintColor = ACCResourceColor(ACCUIColorPrimary);
        _option2View.textColor = ACCResourceColor(ACCUIColorConstTextPrimary);
        
        _option2View.scrollEnabled = NO;
        _option2View.showsVerticalScrollIndicator = NO;
        _option2View.showsHorizontalScrollIndicator = NO;
        _option2View.textContainer.maximumNumberOfLines = 1;
        _option2View.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
        _option2View.textContainerInset = UIEdgeInsetsMake(6, 6, 6, 6);
        _option2View.textContainer.lineFragmentPadding = 0;
        
        _option2View.textAlignment = NSTextAlignmentCenter;
        _option2View.returnKeyType = UIReturnKeyDone;
        _option2View.autocorrectionType = UITextAutocorrectionTypeNo;
        _option2View.placeholderTextView.textContainer.maximumNumberOfLines = 1;
        _option2View.placeholderTextView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
        _option2View.attributedPlaceholder = [[NSMutableAttributedString alloc] initWithString:self.opt2PlaceHolder
                                                                                     attributes:@{NSFontAttributeName: _option2View.font,
                                                                                                  NSForegroundColorAttributeName: [UIColor lightGrayColor]
                                                                                                  }];
    }
    return _option2View;
}

- (CGFloat)opt1PlaceHolderWidth {
    if (!_opt1PlaceHolderWidth) {
        CGFloat textHeight = CGRectGetHeight(UIEdgeInsetsInsetRect(self.option1View.frame, self.option1View.textContainerInset));
        CGSize boundingRect = [self sizeOfString:self.option1View.attributedPlaceholder.string constrainedToHeight:textHeight font:self.option1View.font];
        if (boundingRect.width) {
            _opt1PlaceHolderWidth = boundingRect.width+14;
        }
    }
    return _opt1PlaceHolderWidth;
}

- (CGFloat)opt2PlaceHolderWidth {
    if (!_opt2PlaceHolderWidth) {
        CGFloat textHeight = CGRectGetHeight(UIEdgeInsetsInsetRect(self.option2View.frame, self.option2View.textContainerInset));
        CGSize boundingRect = [self sizeOfString:self.option2View.attributedPlaceholder.string constrainedToHeight:textHeight font:self.option2View.font];
        if (boundingRect.width) {
            _opt2PlaceHolderWidth = boundingRect.width+14;
        }
    }
    return _opt2PlaceHolderWidth;
}

- (CALayer *)op1ShadowLayer {
    if (!_op1ShadowLayer) {
        _op1ShadowLayer = [CALayer layer];
    }
    return _op1ShadowLayer;
}

- (CALayer *)op2ShadowLayer {
    if (!_op2ShadowLayer) {
        _op2ShadowLayer = [CALayer layer];
    }
    return _op2ShadowLayer;
}

#pragma mark - public methods

- (void)refreshPlaceHolderWidth {
    self.placeHolderFont = self.questionView.font;
    CGFloat textHeight = fabs(self.questionView.font.ascender) + fabs(self.questionView.font.descender);
    CGSize boundingRect = [self sizeOfString:self.questionView.attributedPlaceholder.string constrainedToHeight:textHeight font:self.placeHolderFont];
    if (boundingRect.width) {
        self.placeHolderWidth = boundingRect.width+2.f;
        if (self.placeHolderWidth > (kAWEPollStickerWitdth -20.f)) {//问题的placeHolder宽度太长，字体size减2
            UIFont *newFont = [UIFont fontWithName:self.questionView.font.fontName size:18];
            if (newFont) {
                self.placeHolderFont = newFont;
                boundingRect = [self sizeOfString:self.questionView.attributedPlaceholder.string constrainedToHeight:textHeight font:self.placeHolderFont];
                if (boundingRect.width) {
                    self.placeHolderWidth = boundingRect.width+2.f;
                }
            }
        }
    }
}

- (void)displayQuestionPlaceHolder:(BOOL)show {
    CGFloat baselineOffset = 0.f;
    if (self.placeHolderFont.pointSize != self.questionView.font.pointSize) {
        baselineOffset = -2.f;
    }
    self.questionView.attributedPlaceholder = !show ? nil:[[NSMutableAttributedString alloc] initWithString:self.placeHolderStr
                                                                                                 attributes:@{NSFontAttributeName: self.placeHolderFont,
                                                                                                              NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                                                                                              NSBaselineOffsetAttributeName: @(baselineOffset)}];
}

- (void)displayShadowLayer:(BOOL)show {
    self.op1ShadowLayer.hidden = show ? NO:YES;
    self.op2ShadowLayer.hidden = show ? NO:YES;
}

- (void)updateQuestionConstraints {
    if ([self.questionView.text length]) {
        self.questionView.textAlignment = NSTextAlignmentCenter;
        self.questionView.textContainer.maximumNumberOfLines = kAWEPollStickerMaxLines;
    } else {
        self.questionView.textAlignment = NSTextAlignmentLeft;
        self.questionView.textContainer.maximumNumberOfLines = 1;
    }
    
    CGFloat gap = [self p_questionPlaceHolderGap];

    if (self.reLayoutQuestionWhenEmpty) {
        ACCMasReMaker(self.questionView, {
            if ([self.questionView.text length]) {
                make.left.equalTo(self).offset(0);
                make.right.equalTo(self).offset(0);
            } else {
                make.left.equalTo(self).offset(gap);
                make.right.equalTo(self).offset(-gap);
            }
            make.top.equalTo(self);
            make.height.mas_greaterThanOrEqualTo(@(kAWEPollStickerQuestionDefaultHeight));
        });
        self.reLayoutQuestionWhenEmpty = NO;
    } else {
        ACCMasUpdate(self.questionView, {
            if ([self.questionView.text length]) {
                make.left.equalTo(self).offset(0);
                make.right.equalTo(self).offset(0);
            } else {
                make.left.equalTo(self).offset(gap);
                make.right.equalTo(self).offset(-gap);
            }
            make.top.equalTo(self);
            make.height.mas_greaterThanOrEqualTo(@(kAWEPollStickerQuestionDefaultHeight));
        });
    }
}

- (void)updateQuestionConstraintsWhenHide:(BOOL)hide {
    self.reLayoutQuestionWhenEmpty = YES;
    self.questionView.textContainer.maximumNumberOfLines = 1;
    
    CGFloat gap = [self p_questionPlaceHolderGap];

    ACCMasReMaker(self.questionView, {
        make.top.equalTo(self);
        if ([self.questionView.text length]) {
            make.left.equalTo(self).offset(0);
            make.right.equalTo(self).offset(0);
        } else {
            make.left.equalTo(self).offset(gap);
            make.right.equalTo(self).offset(-gap);
        }
        make.height.mas_equalTo(hide ? @(0):@(kAWEPollStickerQuestionDefaultHeight));
    });
}

- (void)updateOptionsConstraints {
    [self p_updateOPT1Constraints];
    [self p_updateOPT2Constraints];
}

- (void)showDisplayMode:(BOOL)open
{
    if (open) {
        // 不作懒加载
        self.option1View.hidden = YES;
        self.option2View.hidden = YES;
        if (!self.option1DisplayView) {
            self.option1DisplayView = [[ACCPollStickerOptionView alloc] init];
            [self.option1BGView addSubview:self.option1DisplayView];
            ACCMasMaker(self.option1DisplayView, {
                make.edges.equalTo(self.option1BGView);
            });
        }
        if (!self.option2DisplayView) {
            self.option2DisplayView = [[ACCPollStickerOptionView alloc] init];
            [self.option2BGView addSubview:self.option2DisplayView];
            ACCMasMaker(self.option2DisplayView, {
                make.edges.equalTo(self.option2BGView);
            });
        }
    } else {
        self.option1View.hidden = NO;
        self.option2View.hidden = NO;
        self.option1DisplayView.hidden = YES;
        self.option2DisplayView.hidden = YES;
    }
}

#pragma mark - constraints

- (void)p_makeSubViewConstraints {
    
    ACCMasUpdate(self.questionView, {
        make.left.equalTo(self).offset(0);
        make.right.equalTo(self).offset(0);
        make.top.equalTo(self);
        make.height.mas_greaterThanOrEqualTo(@(kAWEPollStickerQuestionDefaultHeight));
    });
    
    //option2 - bottom = self.bottom
    ACCMasUpdate(self.option2BGView, {
        make.size.mas_equalTo(CGSizeMake(kAWEPollStickerOPTBGWidth, 44));
        make.centerX.equalTo(self);
        make.bottom.equalTo(self).offset(0);
    });
    ACCMasUpdate(self.option2View, {
        make.centerX.centerY.equalTo(self.option2BGView);
        make.size.mas_equalTo(CGSizeMake(kAWEPollStickerOPTWidth, 32));
    });
    
    //option1
    ACCMasUpdate(self.option1BGView, {
        make.size.mas_equalTo(CGSizeMake(kAWEPollStickerOPTBGWidth, 44));
        make.centerX.equalTo(self);
        make.bottom.equalTo(self.option2BGView.mas_top).offset(-8);
    });
    ACCMasUpdate(self.option1View, {
        make.centerX.centerY.equalTo(self.option1BGView);
        make.size.mas_equalTo(CGSizeMake(kAWEPollStickerOPTWidth, 32));
    });
}

- (void)p_updateOPT1Constraints {
    if ([self.option1View.text length]) {
        self.option1View.textAlignment = NSTextAlignmentCenter;
    } else {
        self.option1View.textAlignment = NSTextAlignmentLeft;
    }
    
    CGFloat width = kAWEPollStickerOPTWidth;
    if (![self.option1View.text length]) {
        if (self.opt1PlaceHolderWidth) {
            width = self.opt1PlaceHolderWidth + self.option1View.textContainerInset.left + self.option1View.textContainerInset.right;
        }
        if (width > kAWEPollStickerOPTWidth) {
            width = kAWEPollStickerOPTWidth;
        }
    }
    
    ACCMasUpdate(self.option1View, {
        make.centerX.centerY.equalTo(self.option1BGView);
        make.size.mas_equalTo(CGSizeMake(width, 32));
    });
}

- (void)p_updateOPT2Constraints {
    if ([self.option2View.text length]) {
        self.option2View.textAlignment = NSTextAlignmentCenter;
    } else {
        self.option2View.textAlignment = NSTextAlignmentLeft;
    }
    
    CGFloat width = kAWEPollStickerOPTWidth;
    if (![self.option2View.text length]) {
        if (self.opt2PlaceHolderWidth) {
            width = self.opt2PlaceHolderWidth + self.option2View.textContainerInset.left + self.option2View.textContainerInset.right;
        }
        if (width > kAWEPollStickerOPTWidth) {
            width = kAWEPollStickerOPTWidth;
        }
    }
    ACCMasUpdate(self.option2View, {
        make.centerX.centerY.equalTo(self.option2BGView);
        make.size.mas_equalTo(CGSizeMake(width, 32));
    });
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]){
        if (textView == self.option1View) {
            if (![self.option1View.text length]) {
                self.option1View.text = [self.option1View.attributedPlaceholder string];
                [self p_updateOPT1Constraints];
            }
            
            self.currentEditType = AWEPollStickerEditTypeOPT2;
            [self.option2View becomeFirstResponder];
        } else if (textView == self.option2View) {
            if (![self.option2View.text length]) {
                self.option2View.text = [self.option2View.attributedPlaceholder string];
                [self p_updateOPT2Constraints];
            }
            // 先修改状态，再关键盘
            if (self.finishEditBlock) {
                self.finishEditBlock();
            }
            [self.option2View resignFirstResponder];
        }
        return NO;
    }
    
    if (textView == self.option1View || textView == self.option2View) {
        NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
        CGFloat textHeight = CGRectGetHeight(UIEdgeInsetsInsetRect(textView.frame, textView.textContainerInset));
        CGSize boundingRect = [self sizeOfString:newText constrainedToHeight:textHeight font:textView.font];
        if (boundingRect.width <= kAWEPollStickerOPTWidth) {
            return YES;
        } else {//fix ios8 backspace bug https://stackoverflow.com/questions/1977934/detect-backspace-in-empty-uitextfield
            if ([text length] == 0 && range.length > 0) {
                return YES;
            } else {
                return NO;
            }
        }
    }
    
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if (![self.questionView.text length]) {
        [self displayQuestionPlaceHolder:YES];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (textView == self.option1View) {
        if (![self.option1View.text length]) {
            [self p_updateOPT1Constraints];
        }
    } else if (textView == self.option2View) {//end editting
        if (![self.option2View.text length]) {
            [self p_updateOPT2Constraints];
        }
        
        self.currentEditType = AWEPollStickerEditTypeNone;
        [self displayQuestionPlaceHolder:NO];
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (textView == self.option1View) {
        [self p_updateOPT1Constraints];
    } else if (textView == self.option2View) {
        [self p_updateOPT2Constraints];
    }
}

#pragma mark - utils

- (CGFloat)p_questionPlaceHolderGap {
    CGFloat gap = 0;
    CGFloat compensation = 8.f;
    if ((self.placeHolderWidth + self.questionView.textContainerInset.left + self.questionView.textContainerInset.right) < (kAWEPollStickerWitdth - compensation)) {
        gap = (kAWEPollStickerWitdth - (self.placeHolderWidth + self.questionView.textContainerInset.left + self.questionView.textContainerInset.right) - compensation)/2.f;
    }
    if (self.placeHolderFont.pointSize != self.questionView.font.pointSize) {
        gap = gap/2.f;
    }
    return gap;
}

-(CGSize)sizeOfString:(NSString *)string constrainedToWidth:(double)width font:(UIFont *)font
{
    return  [string boundingRectWithSize:CGSizeMake(width, DBL_MAX)
                                 options:NSStringDrawingUsesLineFragmentOrigin
                              attributes:@{NSFontAttributeName:font}
                                 context:nil].size;
}

-(CGSize)sizeOfString:(NSString *)string constrainedToHeight:(double)height font:(UIFont *)font
{
    return  [string boundingRectWithSize:CGSizeMake(DBL_MAX, height)
                                 options:NSStringDrawingUsesLineFragmentOrigin
                              attributes:@{NSFontAttributeName:font}
                                 context:nil].size;
}


- (void)addShadowToView:(UIView *)view
            shadowLayer:(CALayer *)shadowLayer
            withOpacity:(CGFloat)shadowOpacity
           shadowRadius:(CGFloat)shadowRadius
        andCornerRadius:(CGFloat)cornerRadius
{
    //////// shadow /////////
    shadowLayer.frame = view.layer.frame;
    shadowLayer.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.24].CGColor;
    shadowLayer.shadowOffset = CGSizeMake(0, 0);//这个跟shadowRadius配合使用
    shadowLayer.shadowOpacity = shadowOpacity;
    shadowLayer.shadowRadius = shadowRadius;
    
    //path
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat width = shadowLayer.bounds.size.width;
    CGFloat height = shadowLayer.bounds.size.height;
    CGFloat x = shadowLayer.bounds.origin.x;
    CGFloat y = shadowLayer.bounds.origin.y;
    
    CGPoint topLeft      = shadowLayer.bounds.origin;
    CGPoint topRight     = CGPointMake(x + width, y);
    CGPoint bottomRight  = CGPointMake(x + width, y + height);
    CGPoint bottomLeft   = CGPointMake(x, y + height);
    
    CGFloat offset = -1.f;
    [path moveToPoint:CGPointMake(topLeft.x - offset, topLeft.y + cornerRadius)];
    [path addArcWithCenter:CGPointMake(topLeft.x + cornerRadius, topLeft.y + cornerRadius) radius:(cornerRadius + offset) startAngle:M_PI endAngle:M_PI_2 * 3 clockwise:YES];
    [path addLineToPoint:CGPointMake(topRight.x - cornerRadius, topRight.y - offset)];
    [path addArcWithCenter:CGPointMake(topRight.x - cornerRadius, topRight.y + cornerRadius) radius:(cornerRadius + offset) startAngle:M_PI_2 * 3 endAngle:M_PI * 2 clockwise:YES];
    [path addLineToPoint:CGPointMake(bottomRight.x + offset, bottomRight.y - cornerRadius)];
    [path addArcWithCenter:CGPointMake(bottomRight.x - cornerRadius, bottomRight.y - cornerRadius) radius:(cornerRadius + offset) startAngle:0 endAngle:M_PI_2 clockwise:YES];
    [path addLineToPoint:CGPointMake(bottomLeft.x + cornerRadius, bottomLeft.y + offset)];
    [path addArcWithCenter:CGPointMake(bottomLeft.x + cornerRadius, bottomLeft.y - cornerRadius) radius:(cornerRadius + offset) startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
    [path addLineToPoint:CGPointMake(topLeft.x - offset, topLeft.y + cornerRadius)];

    shadowLayer.shadowPath = path.CGPath;
    
    //////// cornerRadius /////////
    view.layer.cornerRadius = cornerRadius;
    view.layer.masksToBounds = YES;
    view.layer.shouldRasterize = YES;
    view.layer.rasterizationScale = [UIScreen mainScreen].scale;

    [view.superview.layer insertSublayer:shadowLayer below:view.layer];
}

@end
