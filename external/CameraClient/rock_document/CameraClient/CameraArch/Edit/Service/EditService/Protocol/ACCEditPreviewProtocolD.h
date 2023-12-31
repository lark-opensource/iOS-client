//
//  ACCEditPreviewProtocolD.h
//  CameraClient
//
//  Created by yangying on 2021/6/21.
//

#ifndef ACCEditPreviewProtocolD_h
#define ACCEditPreviewProtocolD_h

#import "ACCEditVideoDataProtocol.h"
#import <CreationKitRTProtocol/ACCEditPreviewProtocol.h>

@class ACCEditMVModel;

@protocol ACCEditPreviewMessageProtocolD <ACCEditPreviewMessageProtocol>

@optional
- (void)updateVideoDataBegin:(ACCEditVideoData * _Nullable)videoData
                  updateType:(VEVideoDataUpdateType)updateType
                  multiTrack:(BOOL)multiTrack;

- (void)updateVideoDataFinished:(ACCEditVideoData *)videoData
                     updateType:(VEVideoDataUpdateType)updateType
                     multiTrack:(BOOL)multiTrack;

@end

@protocol ACCEditPreviewProtocolD <ACCEditPreviewProtocol>

- (void)updateVideoData:(ACCEditVideoData * _Nullable)videoData
             updateType:(VEVideoDataUpdateType)updateType
          completeBlock:(void(^ _Nullable)(NSError* error))completeBlock;

- (void)updateVideoData:(ACCEditVideoData *_Nonnull)videoData mvModel:(ACCEditMVModel *_Nonnull)mvModel completeBlock:(void (^_Nullable)(NSError *_Nullable error))completeBlock;

@end

#endif /* ACCEditPreviewProtocolD_h */
