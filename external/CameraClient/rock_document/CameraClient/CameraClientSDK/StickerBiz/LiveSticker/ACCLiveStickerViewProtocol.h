//
//  ACCLiveStickerViewProtocol.h
//  CameraClient-Pods-Aweme
//
// Created by Bu Xuyang on 2021 / 1 / 10
//

#ifndef ACCLiveStickerViewProtocol_h
#define ACCLiveStickerViewProtocol_h
#import "ACCStickerContentDisplayProtocol.h"

@class AWEInteractionStickerModel, AWEInteractionLiveStickerInfoModel;

@protocol ACCLiveStickerViewProtocol <ACCStickerContentDisplayProtocol>

@property (nonatomic, strong) AWEInteractionStickerModel *stickerModel;

@property (nonatomic, copy) dispatch_block_t clickOnToSeeBtn;

- (void)configWithInfo:(AWEInteractionLiveStickerInfoModel *)liveInfo;

- (CGSize)liveStickerSize;

- (CGRect)wantToSeeBtnFrame;

@end

#endif /* ACCLiveStickerViewProtocol_h */
