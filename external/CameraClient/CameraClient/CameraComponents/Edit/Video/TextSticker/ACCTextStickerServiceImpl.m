//
//  ACCTextStickerServiceImpl.m
//  Aweme
//
//  Created by 卜旭阳 on 2021/11/4.
//

#import "ACCTextStickerServiceImpl.h"

@implementation ACCTextStickerServiceImpl

@synthesize startEditTextStickerSignal;
@synthesize endEditTextStickerSignal;

- (void)dealloc
{
    [self.startEditTextStickerSubject sendCompleted];
    [self.endEditTextStickerSubject sendCompleted];
}

- (RACSignal<ACCTextStickerView *> *)startEditTextStickerSignal
{
    return self.startEditTextStickerSubject;
}

- (RACSubject<ACCTextStickerView *> *)startEditTextStickerSubject
{
    if (!_startEditTextStickerSubject) {
        _startEditTextStickerSubject = [RACSubject<ACCTextStickerView *> subject];
    }
    return _startEditTextStickerSubject;
}

- (RACSignal<ACCTextStickerView *> *)endEditTextStickerSignal
{
    return self.endEditTextStickerSubject;
}

- (RACSubject<ACCTextStickerView *> *)endEditTextStickerSubject
{
    if (!_endEditTextStickerSubject) {
        _endEditTextStickerSubject = [RACSubject<ACCTextStickerView *> subject];
    }
    return _endEditTextStickerSubject;
}

- (void)startEditTextStickerView:(ACCTextStickerView *)stickerView
{
    [self.startEditTextStickerSubject sendNext:stickerView];
}

- (void)endEditTextStickerView:(ACCTextStickerView *)stickerView
{
    [self.endEditTextStickerSubject sendNext:stickerView];
}

@end
