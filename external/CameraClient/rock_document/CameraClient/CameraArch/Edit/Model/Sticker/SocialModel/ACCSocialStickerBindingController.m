//
//  ACCSocialStickerBindingController.m
//  CameraClient-Pods-Aweme
//
//  Created by qiuhang on 2020/8/13.
//

#import "ACCSocialStickerBindingController.h"
#import <CreationKitInfra/ACCMiddlemanProxy.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSTimer+ACCAdditions.h>

@interface ACCSocialStickerBindingController () <UITextFieldDelegate>

// hold some and forward all textinput's delegate methods
@property (nonatomic, strong) ACCMiddlemanProxy *middlemanProxy;
@property (nonatomic,   weak) id <ACCSocialStickerBindingDelegate> delegate;

// input component, will add textView in next feature for text sticker.
@property (nonatomic, strong) UITextField *inputTextView;
@property (nonatomic, strong) ACCSocialStickerModel *stickerModel;

// will hold or reset 0.2s after text changed
@property (nonatomic, strong) NSTimer *keywordCallbackIntervalTimer;

@end

static const NSUInteger kMaxInputLength = 20;

@implementation ACCSocialStickerBindingController

#pragma mark - life cycle
- (instancetype)initWithTextInput:(UITextField *)textInput
                     stickerModel:(ACCSocialStickerModel *)stickerModel
                         delegate:(id<ACCSocialStickerBindingDelegate>)delegate {
    
    if (self = [super init]) {
        _inputTextView = textInput;
        _stickerModel = stickerModel;
        _delegate = delegate;
        [self setup];
        [self reloadTextInput];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textInputDidChange:)
                                                     name:UITextFieldTextDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopTimer];
}

- (void)setup {
    
    self.inputTextView.delegate = nil;
    
    self.middlemanProxy = ({
        
        ACCMiddlemanProxy *proxy = [ACCMiddlemanProxy alloc];
        proxy.originalDelegate  = self.delegate;
        proxy.middlemanDelegate = self;
        proxy;
    });
    
    // relplace invocation target
    self.inputTextView.delegate = (id)self.middlemanProxy;
}

#pragma mark - update
- (void)reloadTextInput {
    
    NSString *displayText = self.stickerModel.contentString ? : @"";
    
    if (![self.inputTextView.text isEqualToString:displayText]) {
        self.inputTextView.text =  displayText;
    }
    
    [self callbackTextInputTextChangedWithReloadKeywordFlag:YES];
}

#pragma mark - text input handler
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    id originalDelegate =  self.middlemanProxy.originalDelegate;
    
    if ([originalDelegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        BOOL result =  [originalDelegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
        if (!result) {
            return NO;
        }
    }
    // will replace whitespace on text changed callback
    NSString *realReplacementString = ACCSocialStickerInputFilteredStringWithString(string);
    
    // empty string means 'delete' action, otherwise, empty realReplacementString means 'input whitespace'
    if (!ACC_isEmptyString(string) && ACC_isEmptyString(realReplacementString)) {
        // can not input whitespace
        return NO;
    }

    // case : target text'length greater than kMaxInputLength
    if (textField.text.length + realReplacementString.length - range.length > kMaxInputLength) {
        [ACCToast() show:ACCLocalizedString(@"creation_sticker_mention_disabled_toast", @"Enter up to 20 characters")];
        return NO;
    }
    
    return YES;
}

- (void)textInputDidChange:(NSNotification *)sender {
    
    if (sender.object != self.inputTextView) {
        return;
    }
    
    if ([self hasMarkedTextRange]) {
        // need update textinput's frame, and no need call back keyword change because of 'marked'
        [self callbackTextInputTextChangedWithReloadKeywordFlag:NO];
        return;
    }
    
    // PM confirmed : remove binding after edit, even if edit range is not intersectant with binding range
    [self removeBinding];
    
    // adapter for iOS 9
    BOOL didOverInputMaxLength = (self.inputTextView.text.length > kMaxInputLength);
    if (didOverInputMaxLength) {
        [ACCToast() show:ACCLocalizedString(@"creation_sticker_mention_disabled_toast", @"Enter up to 20 characters")];
    }
    
    // update data model
    NSString *toBeString = [self complianceStringWithString:self.inputTextView.text];
    self.stickerModel.contentString = toBeString;
    
    [self reloadTextInput];
}

#pragma mark - binding handler
- (NSRange)getRecalculateBindingRangeWithCurrentBindingRange:(NSRange)currentBindingRange
                                                   editRange:(NSRange)editRange
                                           replacementString:(NSString *)string {
    
    if (currentBindingRange.location == NSNotFound) {
        // no binding yet, no need update
        return currentBindingRange;
    }
    
    // case : range.length > 0 && Repalce range has Intersection range with BindingRange
    BOOL isRepalceRangeIntersectionBindingRange = (NSIntersectionRange(editRange, currentBindingRange).length > 0);
    
    // case : range.length == 0 && range.location is in BingRange
    // do not use NSLocationInRange() , because NSLocationInRange has incorrect case: 'range.location == currentBindingRange.location'
    BOOL isEditLocationInBingRange = (editRange.location > currentBindingRange.location &&
                                      editRange.location < (currentBindingRange.location + currentBindingRange.length));
    
    /// will modify in binding range, need remove current binding data
    if (isRepalceRangeIntersectionBindingRange || isEditLocationInBingRange) {
        return NSMakeRange(NSNotFound, 0);
    } else {
        // will modify in front of binding range, need move binding range
        if (currentBindingRange.location >= editRange.location) {
            NSInteger offset = string.length - editRange.length;
            return NSMakeRange(currentBindingRange.location + offset, currentBindingRange.length);
        }
    }
    // no change
    return currentBindingRange;
}

- (BOOL)bindingWithMentionModel:(ACCSocialStickeMentionBindingModel *)bindingUserModel {
    
    if (self.stickerModel.stickerType != ACCSocialStickerTypeMention) {
        NSAssert(NO, @"bad case, need check");
        return NO;
    }
    
    if(![bindingUserModel isValid]) {
        // no need reset current binding data
        return NO;
    }
    
    NSString *userName  = [self complianceStringWithString:bindingUserModel.userName];
    if (ACC_isEmptyString(userName)) {
        // no need reset current binding data
        return NO;
    }
    
    self.stickerModel.mentionBindingModel = bindingUserModel;
    [self callbackMentionBindingDataChanged];
    
    self.stickerModel.contentString = userName;
    [self reloadTextInput];

    return YES;
}

- (BOOL)bindingWithHashTagModel:(ACCSocialStickeHashTagBindingModel *)hashTagModel {
    
    if (self.stickerModel.stickerType != ACCSocialStickerTypeHashTag) {
        NSAssert(NO, @"bad case, need check");
        return NO;
    }
    
    NSString * hashTagName = [self complianceStringWithString:hashTagModel.hashTagName];
    
    if (ACC_isEmptyString(hashTagName)) {
        // no need reset current binding data
        return NO;
    }
    
    self.stickerModel.contentString = hashTagName;
    [self reloadTextInput];
    return YES;
}

#pragma mark - utilitys
+ (NSString *)complianceStringWithString:(NSString *)string {
    
    string = ACCSocialStickerInputFilteredStringWithString(string);
    
    // handle text change from social tool bar select event
    if (string.length > kMaxInputLength) {
        
        NSRange remainRange = [string rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, kMaxInputLength)];
        if (remainRange.length > kMaxInputLength) {
            remainRange = [string rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, kMaxInputLength - 1)];
        }
        string =  [string substringToIndex:MAX(1, remainRange.length)];
    }
    return string;
}

- (NSString *)complianceStringWithString:(NSString *)string {
    return [ACCSocialStickerBindingController complianceStringWithString:string];
}

- (void)removeBinding {
    
    if (![self.stickerModel hasVaildMentionBindingData]) {
        return;
    }
    self.stickerModel.mentionBindingModel = nil;
    [self callbackMentionBindingDataChanged];
}

- (NSRange)rangeFromTextRange:(UITextRange *)textRange {
    
    if (!textRange) {
        return NSMakeRange(NSNotFound, 0);
    }
    UITextPosition *beginning = self.inputTextView.beginningOfDocument;
    UITextPosition *start = textRange.start;
    UITextPosition *end = textRange.end;
    NSInteger location = [self.inputTextView offsetFromPosition:beginning toPosition:start];
    NSInteger length = [self.inputTextView offsetFromPosition:start toPosition:end];
    return NSMakeRange(location, length);
}

- (BOOL)hasMarkedTextRange {
    return self.inputTextView.markedTextRange && !self.inputTextView.markedTextRange.isEmpty;
}

- (void)callbackTextInputTextChangedWithReloadKeywordFlag:(BOOL)reloadKeywordFlag {
    
    if ([self.delegate respondsToSelector:@selector(bindingController:onTextChanged:)]) {
        [self.delegate bindingController:self onTextChanged:self.inputTextView];
    }
    
    if (reloadKeywordFlag) {
        [self handlerKeywordChangedCallback];
    }
}

- (void)handlerKeywordChangedCallback {
    
    [self stopTimer];
    
    @weakify(self);
    self.keywordCallbackIntervalTimer = [NSTimer acc_scheduledTimerWithTimeInterval:0.2 block:^(NSTimer * _Nonnull timer) {
        @strongify(self);
        [self stopTimer];
        if ([self.delegate respondsToSelector:@selector(bindingControllerOnSearchKeywordChanged:)]) {
            [self.delegate bindingControllerOnSearchKeywordChanged:self];
        }
    } repeats:NO];
}

- (void)callbackMentionBindingDataChanged {
    
    if ([self.delegate respondsToSelector:@selector(bindingControllerOnMentionBindingDataChanged:)]) {
        [self.delegate bindingControllerOnMentionBindingDataChanged:self];
    }
}

- (void)stopTimer {
    if (self.keywordCallbackIntervalTimer) {
        [self.keywordCallbackIntervalTimer invalidate];
        self.keywordCallbackIntervalTimer = nil;
    }
}


@end

