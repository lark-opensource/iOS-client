//
//  ACCStickerContentProtocol.h
//  CameraClient
//
//  Created by liuqing on 2020/6/16.
//

#import "ACCStickerCopyingProtocol.h"
#import "ACCStickerContainerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerContentProtocol <ACCStickerCopyingProtocol>

@property (nonatomic, copy) void (^coordinateDidChange)(void);
@property (nonatomic, weak) id <ACCStickerContainerProtocol> stickerContainer;

@optional
// a time point to update scale change
- (void)contentDidUpdateToScale:(CGFloat)scale;

- (void)updateWithCurrentPlayerTime:(NSTimeInterval)currentPlayerTime;

@end

NS_ASSUME_NONNULL_END
