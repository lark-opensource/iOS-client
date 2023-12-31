//
//  ACCStickerEditContentProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/9/29.
//

#import <CreativeKitSticker/ACCStickerContentProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerEditContentProtocol <ACCStickerContentProtocol>

@required
@property (nonatomic, assign, getter = isTransparent) BOOL transparent;
@property (nonatomic, assign) NSInteger stickerId;

@optional

// Stickers that interact with vesdk need to implement this method.
// currently, infosticker, modernPoi and lyricSticker has implemented.
- (NSString *)stickerViewIdentifier;
// Some sticker show need change when bubble
- (void)bubbleChanged:(BOOL)show;
@property (nonatomic, copy) void (^triggerDragDeleteCallback)(void);

@end

NS_ASSUME_NONNULL_END
