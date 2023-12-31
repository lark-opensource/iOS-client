//
//  ACCStickerContentDisplayProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/3/9.
//

#ifndef ACCStickerContentDisplayProtocol_h
#define ACCStickerContentDisplayProtocol_h

@class AWEInteractionStickerModel;

@protocol ACCStickerContentDisplayProtocol

@optional

- (nullable instancetype)initWithStickerModel:(nullable AWEInteractionStickerModel *)model;

@end

#endif /* ACCStickerContentDisplayProtocol_h */
