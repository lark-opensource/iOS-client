//
//  ACCNewYearWishStickerHandler.h
//  Aweme
//
//  Created by 卜旭阳 on 2021/11/1.
//

#import "ACCStickerHandler.h"

@class ACCRepoActivityModel, AWEVideoPublishViewModel;
@class ACCTextStickerView;
@protocol ACCEditTransitionServiceProtocol, ACCEditAudioEffectProtocol;

@protocol ACCNewYearWishStickerHandlerDelegate <NSObject>

- (void)addTextSticker:(NSString *)text;
- (void)editStatusChanged:(BOOL)enter;
- (void)editWishTextDidChanged:(ACCTextStickerView *)editView;
- (NSDictionary *)commonTrackParams;

@end

@interface ACCNewYearWishStickerHandler : ACCStickerHandler

@property (nonatomic, weak, nullable) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, weak, nullable) id<ACCNewYearWishStickerHandlerDelegate> delegate;
@property (nonatomic, weak, nullable) id<ACCEditAudioEffectProtocol> audioService;

@property (nonatomic, weak, nullable) AWEVideoPublishViewModel *publishModel;

- (void)autoAddStickerAndGuide;

- (void)startEditTextStickerView:(ACCTextStickerView *)stickerView;
- (void)endEditTextStickerView:(ACCTextStickerView *)stickerView;

- (void)startEditWishModule;
- (void)startEditWishText;

@end
