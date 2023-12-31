//
//  ACCWishStickerServiceProtocol.h
//  Aweme
//
//  Created by 卜旭阳 on 2021/11/4.
//

#import <CreationKitInfra/ACCRACWrapper.h>

@class ACCTextStickerView;

@protocol ACCWishStickerServiceProtocol <NSObject>

@property (nonatomic, strong, readonly, nullable) RACSignal<NSString *> *addWishTextStickerSignal;
@property (nonatomic, strong, readonly, nullable) RACSignal<ACCTextStickerView *> *replaceWishTextStickerSignal;

@end
