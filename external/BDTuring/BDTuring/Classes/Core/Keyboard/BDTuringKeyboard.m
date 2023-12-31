//
//  BDTuringKeyboard.m
//  BDTuring
//
//  Created by bob on 2019/12/17.
//

#import "BDTuringKeyboard.h"

__attribute__((constructor)) void bdturing_keyboard_handler() {
    [BDTuringKeyboard sharedKeyboard];
}

@interface BDTuringKeyboard ()

@end

@implementation BDTuringKeyboard

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedKeyboard {
    static BDTuringKeyboard *keyboard = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keyboard = [self new];
    });

    return keyboard;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.keyboardTop = 10000;
        self.keyboardIsShow = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onKeyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onKeyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }

    return self;
}

- (void)onKeyboardWillShow:(NSNotification *)noti {
    self.keyboardIsShow = YES;
    CGRect frame = [noti.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardTop = CGRectGetMinY(frame);
    self.keyboardTop = keyboardTop;
    if ([self.delegate respondsToSelector:@selector(onKeyboardWillShow:)]) {
        [self.delegate onKeyboardWillShow:keyboardTop];
    }
}

- (void)onKeyboardWillHide:(NSNotification *)noti {
    self.keyboardIsShow = NO;
    CGRect frame = [noti.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardTop = CGRectGetMinY(frame);
    self.keyboardTop = keyboardTop;
    if ([self.delegate respondsToSelector:@selector(onKeyboardWillHide:)]) {
        [self.delegate onKeyboardWillHide:keyboardTop];
    }
}

@end
