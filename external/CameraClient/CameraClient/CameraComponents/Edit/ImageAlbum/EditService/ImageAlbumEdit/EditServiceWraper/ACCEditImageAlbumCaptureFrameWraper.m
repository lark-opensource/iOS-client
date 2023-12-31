//
//  ACCEditImageAlbumCaptureFrameWraper.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/1/12.
//

#import "ACCEditImageAlbumCaptureFrameWraper.h"
#import "ACCImageAlbumEditorSession.h"
#import "ACCImageAlbumEditorMacro.h"
#import <CreativeKit/ACCMacros.h>

@interface ACCEditImageAlbumCaptureFrameWraper() <ACCEditBuildListener>

@property (nonatomic, weak) id<ACCImageAlbumEditorSessionProtocol> player;

@end


@implementation ACCEditImageAlbumCaptureFrameWraper

#pragma Mark - ACCEditBuildListener
- (void)setEditSessionProvider:(id<ACCEditSessionProvider>)editSessionProvider
{
    [editSessionProvider addEditSessionListener:self];
}

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editSession
{
    self.player = editSession.imageEditSession;
}

#pragma Mark - ACCEditCaptureFrameProtocol
- (UIImage *)capturePreviewUIImage
{
    return [self.player capturePreviewUIImage];
}

#pragma Mark - image album edit
- (void)getProcessedPreviewImageAtIndex:(NSInteger)index
                          preferredSize:(CGSize)size
                            compeletion:(void (^_Nullable)(UIImage *_Nullable image, NSInteger index))compeletion
{
    [self.player getProcessedPreviewImageAtIndex:index preferredSize:size compeletion:compeletion];
}

- (void)getSourcePreviewImageAtIndex:(NSInteger)index
                       preferredSize:(CGSize)size
                         compeletion:(void (^_Nullable)(UIImage *_Nullable image, NSInteger index))compeletion
{
    [self.player getSourcePreviewImageAtIndex:index preferredSize:size compeletion:compeletion];
}

#pragma Mark - unsupported
- (void)processImageWithCompleteBlock:(void (^_Nonnull)(UIImage *_Nonnull outputImage, NSError *error))block
{
    ACCImageEditModeAssertUnsupportFeature;
    [self getProcessedPreviewImageAtIndex:0 preferredSize:CGSizeZero compeletion:^(UIImage * _Nullable image, NSInteger index) {
        ACCBLOCK_INVOKE(block, image, nil);
    }];
}

- (void)getProcessedPreviewImageAtTime:(NSTimeInterval)atTime
                         preferredSize:(CGSize)size
                           compeletion:(void (^_Nullable)(UIImage *_Nullable image, NSTimeInterval atTime))compeletion
{
    ACCImageEditModeAssertUnsupportFeature;
    [self getProcessedPreviewImageAtTime:atTime preferredSize:size isLastImage:YES compeletion:compeletion];
}

- (void)getProcessedPreviewImageAtTime:(NSTimeInterval)atTime
                         preferredSize:(CGSize)size
                           isLastImage:(BOOL)isLastImage
                           compeletion:(void (^_Nullable)(UIImage *_Nullable image, NSTimeInterval atTime))compeletion
{
    ACCImageEditModeAssertUnsupportFeature;
    [self getProcessedPreviewImageAtIndex:(int)atTime preferredSize:size compeletion:^(UIImage * _Nullable image, NSInteger index) {
        ACCBLOCK_INVOKE(compeletion, image, (NSTimeInterval)index);
    }];
}

- (void)getSourcePreviewImageAtTime:(NSTimeInterval)atTime
                      preferredSize:(CGSize)size
                        compeletion:(void (^_Nullable)(UIImage *_Nullable image, NSTimeInterval atTime))compeletion
{
    ACCImageEditModeAssertUnsupportFeature;
    [self getSourcePreviewImageAtTime:atTime preferredSize:size isLastImage:YES compeletion:compeletion];
}

- (void)getSourcePreviewImageAtTime:(NSTimeInterval)atTime
                      preferredSize:(CGSize)size
                        isLastImage:(BOOL)isLastImage
                        compeletion:(void (^_Nullable)(UIImage *_Nullable image, NSTimeInterval atTime))compeletion
{
    ACCImageEditModeAssertUnsupportFeature;
    [self getSourcePreviewImageAtIndex:(int)atTime preferredSize:size compeletion:^(UIImage * _Nullable image, NSInteger index) {
        ACCBLOCK_INVOKE(compeletion, image, (NSTimeInterval)index);
    }];
}

- (void)beginImageAlbumPreviewTaskExportItemRetainAndReuse
{
    [self.player beginImageAlbumPreviewTaskExportItemRetainAndReuse];
}

- (void)endImageAlbumPreviewTaskExportItemRetainAndReuse
{
    [self.player endImageAlbumPreviewTaskExportItemRetainAndReuse];
}

@end
