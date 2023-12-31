//
//  ACCCustomStickerViewModel.h
//  Pods
//
//  Created by liyingpeng on 2020/7/30.
//

#import "ACCEditViewModel.h"
#import "ACCCustomStickerServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCCustomStickerViewModel : ACCEditViewModel<ACCCustomStickerServiceProtocol>

- (void)addCustomSticker:(IESEffectModel *)sticker path:(NSString *)path tabName:(NSString *)tabName completion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
