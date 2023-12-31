//
//  ACCStickerSearchViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/2/18.
//

#import "ACCEditViewModel.h"
#import "ACCSearchStickerServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class IESInfoStickerModel;

@interface ACCStickerSearchViewModel : NSObject<ACCSearchStickerServiceProtocol>

- (void)addSearchSticker:(IESInfoStickerModel *)sticker path:(NSString *)path completion:(nullable void(^)(void))completionBlock;

- (void)configPannlStatus:(BOOL)show;

@end

NS_ASSUME_NONNULL_END
