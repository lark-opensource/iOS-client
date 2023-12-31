//
//  ACCTextStickerServiceProtocol.h
//  Aweme
//
//  Created by 卜旭阳 on 2021/11/4.
//

#import <CreationKitInfra/ACCRACWrapper.h>

@class ACCTextStickerView;

@protocol ACCTextStickerServiceProtocol <NSObject>

@property (nonatomic, strong, readonly, nullable) RACSignal<ACCTextStickerView *> *startEditTextStickerSignal;
@property (nonatomic, strong, readonly, nullable) RACSignal<ACCTextStickerView *> *endEditTextStickerSignal;

@end
