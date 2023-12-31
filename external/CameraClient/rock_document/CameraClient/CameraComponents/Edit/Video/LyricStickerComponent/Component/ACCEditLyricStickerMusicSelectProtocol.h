//
//  ACCEditLyricStickerMusicSelectProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/11/19.
//

#import <Foundation/Foundation.h>
#import <CameraClient/ACCCameraClient.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

@protocol ACCEditLyricStickerMusicSelectPageProtocol <NSObject>
@property (nonatomic, copy) void (^dismissHandler)(void);
@property (nonatomic, copy) void (^completion)(id<ACCMusicModelProtocol> music, NSError *error);
@property (nonatomic, copy) void (^didClipRange)(HTSAudioRange range, NSInteger repeatCount);
@property (nonatomic, copy) void (^suggestSelectedChangeBlock)(BOOL selected);
@property (nonatomic, copy) NSString *pageSource;

- (void)showOnViewController:(UIViewController * _Nullable)parentViewController startOffset:(CGFloat)offset completion:(void (^ _Nullable)(void))completion;

@end



@protocol ACCEditLyricStickerMusicSelectProtocol <NSObject>

- (id<ACCEditLyricStickerMusicSelectPageProtocol>)createWithRepository:(AWEVideoPublishViewModel * _Nullable)repository;

@end


NS_ASSUME_NONNULL_END
