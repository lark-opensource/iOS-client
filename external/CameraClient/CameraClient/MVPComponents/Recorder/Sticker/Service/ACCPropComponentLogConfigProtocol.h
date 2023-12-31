//
//  ACCPropComponentLogConfigProtocol.h
//  CameraClient
//
//  Created by jindulys on 2020/5/8.
//

@protocol ACCPropComponentLogConfigProtocol <NSObject>

// Log time used for applying a sticker.
- (void)logStickerApplyTime:(CFAbsoluteTime)applytime;

@end
