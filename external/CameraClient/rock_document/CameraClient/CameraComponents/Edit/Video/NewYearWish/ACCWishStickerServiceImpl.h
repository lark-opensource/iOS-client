//
//  ACCWishStickerServiceImpl.h
//  Aweme
//
//  Created by 卜旭阳 on 2021/11/4.
//

#import <Foundation/Foundation.h>
#import "ACCWishStickerServiceProtocol.h"

@interface ACCWishStickerServiceImpl : NSObject<ACCWishStickerServiceProtocol>

@property (nonatomic, strong, nullable) RACSubject<NSString *> *addWishTextStickerSubject;
@property (nonatomic, strong, nullable) RACSubject<ACCTextStickerView *> *replaceWishTextStickerSubject;

- (void)addTextSticker:(nullable NSString *)text;

- (void)didEndEditTextView:(ACCTextStickerView *)textView;

@end
