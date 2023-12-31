//
//  ACCNLEEditStickerWrapper.h
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/1/24.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCEditStickerProtocol.h>
#import "ACCEditVideoDataProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCNLEEditStickerWrapper : NSObject <ACCEditStickerProtocol>

- (void)syncInfoStickerUpdatedWithVideoData:(ACCEditVideoData *)videoData;
- (void)syncEditPageWithBlock:(NS_NOESCAPE dispatch_block_t _Nullable)block;

@end

NS_ASSUME_NONNULL_END
