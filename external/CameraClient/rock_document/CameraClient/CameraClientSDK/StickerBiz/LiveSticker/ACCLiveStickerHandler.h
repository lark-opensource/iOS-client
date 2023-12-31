//
//  ACCLiveStickerHandler.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/1/4.
//

#import <Foundation/Foundation.h>
#import "ACCStickerHandler.h"
#import "ACCStickerDataProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEInteractionLiveStickerInfoModel;

@interface ACCLiveStickerHandler : ACCStickerHandler

@property (nonatomic, weak) id<ACCLiveStickerDataProvider> dataProvider;
@property (nonatomic, copy) void(^editViewOnStartEdit)(void);
@property (nonatomic, copy) void(^editViewOnFinishEdit)(void);

- (void)addLiveSticker:(AWEInteractionStickerModel *)model fromRecover:(BOOL)fromRecover fromAuto:(BOOL)fromAuto;

- (BOOL)enableLiveSticker;

- (void)changeStickerStatus:(BOOL)show;

@end

NS_ASSUME_NONNULL_END
