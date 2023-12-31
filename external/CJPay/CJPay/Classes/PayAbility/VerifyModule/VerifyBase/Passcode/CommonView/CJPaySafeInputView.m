//
//  CJPaySafeInputView.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/16.
//

#import "CJPaySafeInputView.h"
#import "CJPayUIMacro.h"
#import "CJPaySafeKeyboard.h"
#import "CJPayCurrentTheme.h"
#import <ByteDanceKit/NSArray+BTDAdditions.h>


@interface CJPaySafeInputView ()

@property (nonatomic, assign) CGFloat singleItemWidth;
@property (nonatomic, strong) NSMutableArray *dotsViewArray;
@property (nonatomic, strong) CAShapeLayer *cursorLayer;
@property (nonatomic, assign) BOOL needDelay;
@property (nonatomic, assign) BOOL isDenoise;
@property (nonatomic, strong) CJPaySafeInputViewStyleModel *styleModel;

#pragma mark DeleteIfAllDenoise
@property (nonatomic, strong) NSMutableArray *linesViewArray;

#pragma mark Denoise
@property (nonatomic, strong) NSMutableArray<UIView *> *boxViewArray;

@end

@implementation CJPaySafeInputViewStyleModel

@end

@implementation CJPaySafeInputView

- (instancetype)init {
    return [self initWithKeyboard:YES];
}

- (instancetype)initWithKeyboard:(BOOL)needKeyboard {
    self = [super initWithKeyboard:needKeyboard];
    if (self) {
        _isDenoise = NO;
        [self p_setupUI];
    }
    return self;
}

- (instancetype)initWithKeyboardForDenoise:(BOOL)needKeyboard {
    return [self initWithKeyboardForDenoise:needKeyboard denoiseStyle:CJPayViewTypeDenoise];
}

- (instancetype)initWithKeyboardForDenoise:(BOOL)needKeyboard denoiseStyle:(CJPayViewType)viewStyle {
    self = [super initWithKeyboardForDenoise:needKeyboard denoiseStyle:viewStyle];
    if (self) {
        _isDenoise = YES;
        [self p_setupUIForDenoise];
    }
    return self;
}

- (instancetype)initWithInputViewStyleModel:(CJPaySafeInputViewStyleModel *)model {
    if (model.isDenoise) {
        self = [super initWithKeyboardForDenoise:model.needKeyboard denoiseStyle:model.viewStyle];
        _styleModel = model;
        [self p_setupUIForDenoise];
    } else {
        self = [super initWithKeyboard:model.needKeyboard];
        [self p_setupUI];
    }
    _isDenoise = model.isDenoise;
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.contentText.length > 0) {
        [self setDotsVisible:self.contentText.length - 1];
    }
    if (!self.isDenoise) {
        if (self.bounds.size.width != 0 && self.singleItemWidth != self.bounds.size.width * 1.0f / self.numCount ) {
            self.singleItemWidth = self.bounds.size.width * 1.0f / self.numCount;
            [self p_layoutUI];
        }
    }
}

- (void)setContentText:(NSMutableString *)contentText{
    [super setContentText:contentText];
    [self setText:@""];
    [self setDotsVisible:self.contentText.length-1];
}

#pragma mark responder
- (BOOL)becomeFirstResponder {
    if ([self.safeInputDelegate respondsToSelector:@selector(inputViewShouldBecomeFirstResponder:)]) {
        if (![self.safeInputDelegate inputViewShouldBecomeFirstResponder:self]) {
            return NO;
        }
    }

    return [super becomeFirstResponder];
}

-(BOOL)resignFirstResponder {
    if ([self.safeInputDelegate respondsToSelector:@selector(inputViewShouldResignFirstResponder:)]) {
        if (![self.safeInputDelegate inputViewShouldResignFirstResponder:self]) {
            return NO;
        }
    }

    return [super resignFirstResponder];
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (![self isFirstResponder]) {
        [self becomeFirstResponder];
    }
}

- (BOOL)hasText
{
    return self.contentText.length > 0;
}

#pragma mark override super
- (void)inputNumber:(NSInteger)number{
    self.hasInputHistory = YES;
    if (self.mineSecureTextEntry && self.mineSecureSupportShortShow && self.contentText.length < self.numCount) {
        self.needDelay = YES;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayRefresh) object:nil];
        [self performSelector:@selector(delayRefresh) withObject:nil afterDelay:1];
    }
    if (self.contentText.length == self.numCount) {
        return;
    } else {
        [super inputNumber:number];
        if ([self.safeInputDelegate respondsToSelector:@selector(inputView:textDidChangeWithCurrentInput:)]) {
            [self.safeInputDelegate inputView:self textDidChangeWithCurrentInput:self.contentText];
        }
    }
    if (self.contentText.length == self.numCount) {
        [self setNeedsDisplay];
        if (self.safeInputDelegate && [self.safeInputDelegate respondsToSelector:@selector(inputView:completeInputWithCurrentInput:)]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.safeInputDelegate inputView:self completeInputWithCurrentInput:self.contentText];
            });
        }
    }
}

- (void)deleteBackWord {
    [super deleteBackWord];
    [self.dotsViewArray[self.contentText.length] setHidden:YES];
    if ([self.safeInputDelegate respondsToSelector:@selector(inputView:textDidChangeWithCurrentInput:)]) {
        [self.safeInputDelegate inputView:self textDidChangeWithCurrentInput:self.contentText];
    }
}

- (void)clearInput {
    [super clearInput];
    [self setDotsViewAllHidden];
    if ([self.safeInputDelegate respondsToSelector:@selector(inputView:textDidChangeWithCurrentInput:)]) {
        [self.safeInputDelegate inputView:self textDidChangeWithCurrentInput:self.contentText];
    }
}

- (void)delayRefresh {
    self.needDelay = NO;
    if (self.contentText.length<=self.numCount) {
        [self setDotsVisible:self.contentText.length-1];
    }
}


- (void)setDotsViewAllHidden {
    for (UIView *view in self.dotsViewArray) {
        [view setHidden:YES];
    }
}

- (void)setDotsVisible:(NSInteger)index {
    for (int i = 0; i <= index; i++) {
        [[self.dotsViewArray btd_objectAtIndex:i] setHidden:NO];
    }
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point{
    UITextPosition *beginning = self.beginningOfDocument;
    UITextPosition *end = [self positionFromPosition:beginning offset:self.text.length];
    return end;
}

#pragma mark - Getter


- (NSString *)accessibilityLabel {
    return [NSString stringWithFormat:@"密码框,共%ld位,已输入%ld位.",(long)self.numCount,(long)self.contentText.length];
}

- (NSString *)accessibilityHint {
    return @"";
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitStaticText;
}

#pragma mark - Private Method

#pragma mark Denoise

- (void)p_setupUIForDenoise {
    self.backgroundColor = [UIColor whiteColor];
    self.textColor = [UIColor blackColor];
    self.font = [UIFont cj_fontOfSize:14];
    self.contentText = [NSMutableString stringWithFormat:@""];
    self.numCount = self.numCount == 0 ? 6 : self.numCount;
    self.mineSecureTextEntry = YES;//默认是黑球样式
    self.tintColor = [UIColor clearColor];//隐藏光标
    _dotsViewArray = [NSMutableArray arrayWithCapacity:self.numCount];
    _boxViewArray = [NSMutableArray arrayWithCapacity:self.numCount];
    for (int i=0; i < self.numCount; i++) {
        
        UIView *boxView = [UIView new];
        boxView.backgroundColor = [UIColor cj_colorWithHexString:@"F1F1F2"];
        boxView.layer.cornerRadius = 4;
        [_boxViewArray btd_addObject:boxView];
        
        UIView *dotView = [UIView new];
        dotView.backgroundColor = [UIColor blackColor];
        dotView.layer.cornerRadius = 6;
        dotView.hidden = YES;
        [_dotsViewArray btd_addObject:dotView];
        
        [boxView addSubview:dotView];
        CJPayMasMaker(dotView, {
            make.centerY.equalTo(boxView);
            make.centerX.equalTo(boxView);
            make.height.mas_offset(12);
            make.width.mas_offset(12);
        });
        
        [self addSubview:boxView];
    }
    
    
    CGFloat fixedSpacing = self.styleModel.fixedSpacing > 0 ? self.styleModel.fixedSpacing: 8;
    [self.boxViewArray mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:fixedSpacing leadSpacing:0 tailSpacing:0];
    
    CJPayMasArrayMaker(self.boxViewArray, {
        make.top.bottom.equalTo(self);
    });
    
}

#pragma mark DeleteIfAllDenoise

- (void)p_layoutUI {
    for (int i=0; i < self.numCount; i++) {
        if(i!=0){
            CJPayMasReMaker([self.linesViewArray btd_objectAtIndex:i-1], {
                make.top.equalTo(self).offset(1);
                make.bottom.equalTo(self).offset(-1);
                make.width.mas_equalTo(1);
                make.left.equalTo(self).mas_offset(i*self.singleItemWidth);
            });
        }
        CJPayMasReMaker([self.dotsViewArray btd_objectAtIndex:i], {
            make.centerY.equalTo(self);
            make.left.equalTo(self).mas_offset(self.singleItemWidth/2+i*self.singleItemWidth-6);
            make.height.mas_offset(12);
            make.width.mas_offset(12);
        });
    }
}

- (void)p_setupUI {
    self.backgroundColor = [UIColor whiteColor];
    self.textColor = [UIColor blackColor];
    self.font = [UIFont cj_fontOfSize:14];
    self.contentText = [NSMutableString stringWithFormat:@""];
    self.numCount = self.numCount == 0 ? 6 : self.numCount;
    self.mineSecureTextEntry = YES;//默认是黑球样式
    self.clipsToBounds = YES;
    self.layer.cornerRadius = 4;
    self.layer.borderWidth = 1;
    self.layer.borderColor = [UIColor cj_161823WithAlpha:0.12].CGColor;
    self.tintColor = [UIColor clearColor];
    _dotsViewArray = [NSMutableArray arrayWithCapacity:self.numCount];
    _linesViewArray = [NSMutableArray arrayWithCapacity:self.numCount];
    for (int i=0; i < self.numCount; i++) {
        if(i!=0) {
            UIView *line = [UIView new];
            line.backgroundColor = [UIColor cj_161823WithAlpha:0.12];
            [self addSubview:line];
            [_linesViewArray btd_addObject:line];
        }
        UIView *dotView = [UIView new];
        dotView.backgroundColor = [UIColor blackColor];
        dotView.layer.cornerRadius = 6;
        dotView.hidden = YES;
        [self addSubview:dotView];
        [_dotsViewArray btd_addObject:dotView];
    }
}

@end
