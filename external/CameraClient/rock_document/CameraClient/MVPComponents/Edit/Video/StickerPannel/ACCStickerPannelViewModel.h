//
//  ACCStickerPannelViewModel.h
//  Pods
//
//  Created by liyingpeng on 2020/7/30.
//

#import "ACCEditViewModel.h"
#import "ACCStickerPanelServiceProtocol.h"
#import "ACCStickerSelectionContext.h"

@interface ACCStickerPannelViewModel : NSObject<ACCStickerPanelServiceProtocol>

@property (nonatomic, copy, nullable) void(^dismissPanelBlock)(ACCStickerSelectionContext *_Nullable ctx, BOOL animated);
@property (nonatomic, copy) void(^configureGestureWithView)(UIView *view);

- (BOOL)handleSelectSticker:(IESEffectModel *)sticker fromTab:(NSString *)tabName;
- (BOOL)handleSelectThirdPartySticker:(IESThirdPartyStickerModel *)sticker;

- (void)willShowStickerPanel;
- (void)willDismissStickerPanel:(ACCStickerSelectionContext *)selectedSticker;
- (void)didDismissStickerPanelWithSelectedSticker:(ACCStickerSelectionContext *)selectedSticker;

@end
