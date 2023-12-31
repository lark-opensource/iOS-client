//
//  ACCStickerDeleteViewProtocol.h
//  CameraClient
//
//  Created by yangguocheng on 2021/4/22.
//

#ifndef ACCStickerDeleteViewProtocol_h
#define ACCStickerDeleteViewProtocol_h

@protocol ACCStickerDeleteViewProtocol <NSObject>

- (void)stopAnimation;
- (void)startAnimation;
+ (CGRect)handleFrame;
+ (CGFloat)recommendTopWithAdjustment:(BOOL)needToAdjust;
- (void)onDeleteActived;
- (void)onDeleteInActived;

@end

#endif /* ACCStickerDeleteViewProtocol_h */
