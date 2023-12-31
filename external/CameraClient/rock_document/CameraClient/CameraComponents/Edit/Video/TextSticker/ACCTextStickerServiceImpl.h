//
//  ACCTextStickerServiceImpl.h
//  Aweme
//
//  Created by 卜旭阳 on 2021/11/4.
//

#import <Foundation/Foundation.h>
#import "ACCTextStickerServiceProtocol.h"

@interface ACCTextStickerServiceImpl : NSObject<ACCTextStickerServiceProtocol>

@property (nonatomic, strong, nullable) RACSubject<ACCTextStickerView *> *startEditTextStickerSubject;
@property (nonatomic, strong, nullable) RACSubject<ACCTextStickerView *> *endEditTextStickerSubject;

- (void)startEditTextStickerView:(ACCTextStickerView *)stickerView;
- (void)endEditTextStickerView:(ACCTextStickerView *)stickerView;

@end
