//
//  ACCWishStickerServiceImpl.m
//  Aweme
//
//  Created by 卜旭阳 on 2021/11/4.
//

#import "ACCWishStickerServiceImpl.h"

@implementation ACCWishStickerServiceImpl

@synthesize addWishTextStickerSignal;
@synthesize replaceWishTextStickerSignal;

- (void)dealloc
{
    [self.addWishTextStickerSubject sendCompleted];
    [self.replaceWishTextStickerSubject sendCompleted];
}

- (RACSignal<NSString *> *)addWishTextStickerSignal
{
    return self.addWishTextStickerSubject;
}

- (RACSubject<NSString *> *)addWishTextStickerSubject
{
    if (!_addWishTextStickerSubject) {
        _addWishTextStickerSubject = [RACSubject<NSString *> subject];
    }
    return _addWishTextStickerSubject;
}

- (RACSignal<ACCTextStickerView *> *)replaceWishTextStickerSignal
{
    return self.replaceWishTextStickerSubject;
}

- (RACSubject<ACCTextStickerView *> *)replaceWishTextStickerSubject
{
    if (!_replaceWishTextStickerSubject) {
        _replaceWishTextStickerSubject = [RACSubject<ACCTextStickerView *> subject];
    }
    return _replaceWishTextStickerSubject;
}

- (void)addTextSticker:(NSString *)text
{
    [self.addWishTextStickerSubject sendNext:text];
}

- (void)didEndEditTextView:(ACCTextStickerView *)textView
{
    [self.replaceWishTextStickerSubject sendNext:textView];
}

@end
