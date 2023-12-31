//
//  BDPKeyboardManager.m
//  Timor
//
//  Created by 王浩宇 on 2018/12/19.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "BDPKeyboardManager.h"

@implementation BDPKeyboardManager

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
+ (instancetype)sharedManager
{
    static BDPKeyboardManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[BDPKeyboardManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addKeyboardObserve];
    }
    return self;
}

#pragma mark - Notification Observer
/*-----------------------------------------------*/
//         Notification Observer - 通知
/*-----------------------------------------------*/
- (void)addKeyboardObserve
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    self.keyboardFrame = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.keyboardShow = YES;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.keyboardShow = NO;
}

- (void)keyboardWillChange:(NSNotification *)notification
{
    self.keyboardFrame = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
}

@end
