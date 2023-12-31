//
//  ACCInfoStickerComponent.h
//  Pods
//
//  Created by chengfei xiao on 2019/10/20.
//

#import <CreativeKit/ACCFeatureComponent.h>
#import "ACCDraftResourceRecoverProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCInfoStickerViewModel;
@class ACCAddInfoStickerContext;

FOUNDATION_EXTERN CGFloat const kAWEInfoStickerTotalDuration;
FOUNDATION_EXTERN CGFloat const kAWEInfoCustomStickerDefaultLength;

@interface ACCInfoStickerComponent : ACCFeatureComponent<ACCDraftResourceRecoverProtocol>

@property (nonatomic, strong) ACCInfoStickerViewModel *viewModel;

#pragma mark - SubComponent Visible

- (void)addCustomSticker:(ACCAddInfoStickerContext *)x;
- (void)refreshCover;
- (void)cleanUpInfoStickers;

@end

NS_ASSUME_NONNULL_END
