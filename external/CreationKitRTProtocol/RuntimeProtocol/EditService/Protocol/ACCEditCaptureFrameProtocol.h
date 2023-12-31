//
//  ACCEditCaptureFrameProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2020/12/2.
//

#import <Foundation/Foundation.h>
#import "ACCEditWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditCaptureFrameProtocol <ACCEditWrapper>

#pragma Mark - comm edit
- (UIImage *)capturePreviewUIImage;

#pragma Mark - photo edit
- (void)processImageWithCompleteBlock:(void (^_Nonnull)(UIImage *_Nonnull outputImage, NSError *_Nullable error))block;

#pragma Mark - video edit
- (void)getProcessedPreviewImageAtTime:(NSTimeInterval)atTime
                         preferredSize:(CGSize)size
                           compeletion:(void (^_Nullable)(UIImage *_Nullable image, NSTimeInterval atTime))compeletion;

- (void)getSourcePreviewImageAtTime:(NSTimeInterval)atTime
                      preferredSize:(CGSize)size
                        compeletion:(void (^_Nullable)(UIImage *_Nullable image, NSTimeInterval atTime))compeletion;


#pragma Mark - image album edit
///@ todo @ Qiuhang these follow-up will package the inputdata and callback's outputdata to share with the video. Now let's start another one
- (void)getProcessedPreviewImageAtIndex:(NSInteger)index
                          preferredSize:(CGSize)size
                            compeletion:(void (^_Nullable)(UIImage *_Nullable image, NSInteger index))compeletion;

- (void)getSourcePreviewImageAtIndex:(NSInteger)index
                       preferredSize:(CGSize)size
                         compeletion:(void (^_Nullable)(UIImage *_Nullable image, NSInteger index))compeletion;

/// Holding the exported items of the atlas temporarily is suitable for scenes that need to be exported frequently, such as selecting cover pages. In this way, you don't need to export new and dealloc instances frequently
/// It needs to be called in pairs to avoid holding after exiting the scene
- (void)beginImageAlbumPreviewTaskExportItemRetainAndReuse;
- (void)endImageAlbumPreviewTaskExportItemRetainAndReuse;

@end

NS_ASSUME_NONNULL_END
