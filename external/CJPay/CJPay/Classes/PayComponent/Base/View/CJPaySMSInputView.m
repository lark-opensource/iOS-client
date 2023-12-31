//
//  CJPaySMSInputView.m
//  CJPay
//
//  Created by wangxinhua on 2020/8/27.
//

#import "CJPaySMSInputView.h"
#import "CJPayUIMacro.h"

@interface CJPaySMSInputView()

@property (nonatomic, copy) NSArray<UIView *> *lineViews;
@property (nonatomic, copy) NSString *inputStr;
@property (nonatomic, assign) CGFloat itemW;
@property (nonatomic, strong) UIView *responseClickView;
@property (nonatomic, strong) NSTimer *delayCallTimer;


@end

@implementation CJPaySMSInputView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.sep = 16;
        self.backgroundColor = UIColor.clearColor;
        [self p_buildLineViews];
        self.inputStr = @"";
        
        self.responseClickView = [[UIView alloc] init];
        [self addSubview:self.responseClickView];
        [self.responseClickView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputContentChange:) name:UITextFieldTextDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)tapAction {
    [self becomeFirstResponder];
}

- (NSInteger)inputFieldCount {
    if (_inputFieldCount > 0) {
        return _inputFieldCount;
    }
    return 6;
}

- (UITextField *)textField {
    if (!_textField) {
        _textField = [UITextField new];
        _textField.textColor = UIColor.clearColor;
        _textField.tintColor = UIColor.clearColor;
        _textField.keyboardType = UIKeyboardTypeNumberPad;
        // 快速输入短信验证码
        if (@available(iOS 12.0, *)) {
            _textField.textContentType =  UITextContentTypeOneTimeCode;
        }
        // 去掉键盘上的toolbar
        if (@available(iOS  9.0, *)) {
            UITextInputAssistantItem* item = [_textField inputAssistantItem];
            item.leadingBarButtonGroups = @[];
            item.trailingBarButtonGroups = @[];
        }
        [self addSubview:_textField];
    }
    return _textField;
}

- (void)p_buildLineViews {
    if (self.inputFieldCount < 1) {
        return;
    }
    self.textField.frame = self.bounds;
    if (self.inputFieldCount > self.lineViews.count) {
        NSMutableArray *newLineViews = [NSMutableArray arrayWithArray:self.lineViews];
        for(int i = 0; i < self.inputFieldCount - self.lineViews.count; i++) {
            UIView *newV = [UIView new];
            [newLineViews addObject:newV];
            newV.backgroundColor = [UIColor cj_e8e8e8ff];
            [self addSubview:newV];
        }
        self.lineViews = [newLineViews copy];
    }
    [self bringSubviewToFront:self.responseClickView];
}

- (CGFloat )itemW {
    CGFloat iW = (self.cj_width - self.sep * (self.inputFieldCount - 1)) / self.inputFieldCount;
    return iW;
}

- (void)setInputStr:(NSString *)inputStr {
    NSUInteger oldLength = _inputStr.length;
    NSUInteger newLength = inputStr.length;
    self.textField.text = inputStr;
    if ([_inputStr isEqualToString:inputStr]) {
        return;
    }
    _inputStr = inputStr;
    [self setNeedsDisplay];
    [self.lineViews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.backgroundColor = [UIColor cj_e8e8e8ff];
    }];
    [self.lineViews cj_objectAtIndex:inputStr.length].backgroundColor = [UIColor cj_222222ff];
    
    // 通知代理
    if (self.inputStr.length >= self.inputFieldCount) {
        if (self.smsInputDelegate && [self.smsInputDelegate respondsToSelector:@selector(didFinishInputSMS:)]) {
            [self p_triggerDelayFinish:inputStr];
        }
    }
    if (oldLength == self.inputFieldCount && newLength < self.inputFieldCount && newLength != 0) {
        if (self.smsInputDelegate && [self.smsInputDelegate respondsToSelector:@selector(didDeleteLastSMS)]) {
            [self.smsInputDelegate didDeleteLastSMS];
        }
    }
}

- (void)p_triggerDelayFinish:(NSString *)str {
    if (self.delayCallTimer) {
        [self.delayCallTimer invalidate];
    }
    self.delayCallTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:0.3] interval:1 target:[BTDWeakProxy proxyWithTarget:self] selector:@selector(p_sendFinishMsg:) userInfo:str repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.delayCallTimer forMode:NSRunLoopCommonModes];
}

- (void)p_sendFinishMsg:(NSTimer *)timer {
    NSString *dataStr = (NSString *)timer.userInfo;
    if (self.smsInputDelegate && [self.smsInputDelegate respondsToSelector:@selector(didFinishInputSMS:)]) {
        [self.smsInputDelegate didFinishInputSMS:dataStr];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.responseClickView.frame = self.bounds;
    int i = 0;
    for (UIView *lineV in self.lineViews) {
        lineV.frame = CGRectMake(i * (self.itemW + self.sep), self.cj_height - CJ_PIXEL_WIDTH, self.itemW, CJ_PIXEL_WIDTH);
        i++;
    }
    [self setNeedsDisplay]; // 考虑是否有效率问题
}

- (BOOL)isFirstResponder {
    return [self.textField isFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [self.textField becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    [super resignFirstResponder];
    return [self.textField resignFirstResponder];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    for (int i = 0; i < self.inputStr.length; ++i) {
        NSString * string = [self.inputStr substringWithRange:NSMakeRange(i, 1)];
        
        CGSize size = [string boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:0 attributes:@{NSFontAttributeName : self.font ?: [UIFont cj_fontOfSize:28]} context:nil].size;
        
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc]init];
        style.alignment = NSTextAlignmentCenter;
        
        CGRect rect = CGRectMake(i * self.itemW + i * self.sep, self.cj_height * 0.5 - size.height * 0.5, self.itemW, self.cj_height);
        
        [string drawInRect:rect withAttributes:@{NSFontAttributeName : self.font ?: [UIFont cj_fontOfSize:28],NSParagraphStyleAttributeName:style}];
    }
}

#pragma mark UITextFieldContentDidChange

- (void)inputContentChange:(NSNotification *)noti {
    if (![noti.object isKindOfClass:[UITextField class]]) {
        return;
    }
    UITextField *curTf = (UITextField *)noti.object;
    if (curTf != self.textField) {
        return;
    }
    NSString *content = [curTf.text stringByReplacingOccurrencesOfString:@" " withString:@""];

    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    
    NSString *res = [[content componentsSeparatedByCharactersInSet:set.invertedSet] componentsJoinedByString:@""];
    self.inputStr = [res substringToIndex:MIN(res.length, self.inputFieldCount)];
}

// 对外API
- (NSString *)getText {
    return self.inputStr;
}

- (void)clearText {
    self.inputStr = @"";
}

@end

