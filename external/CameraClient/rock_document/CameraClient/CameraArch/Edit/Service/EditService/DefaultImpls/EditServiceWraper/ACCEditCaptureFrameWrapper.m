//
//  ACCEditCaptureFrameWrapper.m
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2020/12/2.
//

#import "ACCEditCaptureFrameWrapper.h"
#import <TTVideoEditor/VEEditorSession+CaptureFrame.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCEditCaptureFrameWrapper() <ACCEditBuildListener>

@property (nonatomic, weak) VEEditorSession *player;

@end

@implementation ACCEditCaptureFrameWrapper

- (void)setEditSessionProvider:(id<ACCEditSessionProvider>)editSessionProvider
{
    [editSessionProvider addEditSessionListener:self];
}

#pragma mark - ACCEditBuildListener

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editSession
{
    self.player = editSession.videoEditSession;
}

- (void)getProcessedPreviewImageAtTime:(NSTimeInterval)atTime preferredSize:(CGSize)size compeletion:(void (^)(UIImage * _Nullable, NSTimeInterval))compeletion
{
    [self getProcessedPreviewImageAtTime:atTime preferredSize:size isLastImage:YES compeletion:compeletion];
}

- (void)getProcessedPreviewImageAtTime:(NSTimeInterval)atTime preferredSize:(CGSize)size isLastImage:(BOOL)isLastImage compeletion:(void (^)(UIImage * _Nullable, NSTimeInterval))compeletion
{
    [self.player getProcessedPreviewImageAtTime:atTime preferredSize:size isLastImage:isLastImage compeletion:compeletion];
}

- (UIImage *)capturePreviewUIImage
{
    return [self.player capturePreviewUIImage];
}

- (void)getSourcePreviewImageAtTime:(NSTimeInterval)atTime preferredSize:(CGSize)size compeletion:(void (^)(UIImage * _Nullable, NSTimeInterval))compeletion
{
    [self getSourcePreviewImageAtTime:atTime preferredSize:size isLastImage:YES compeletion:compeletion];
}

- (void)getSourcePreviewImageAtTime:(NSTimeInterval)atTime preferredSize:(CGSize)size isLastImage:(BOOL)isLastImage compeletion:(void (^)(UIImage * _Nullable, NSTimeInterval))compeletion
{
    [self.player getSourcePreviewImageAtTime:atTime preferredSize:size isLastImage:isLastImage compeletion:compeletion];
}

- (void)processImageWithCompleteBlock:(void (^)(UIImage * _Nonnull, NSError * _Nonnull))block
{
    [self.player processImageWithCompleteBlock:block];
}

#pragma mark - unsupport image edit mode
- (void)getSourcePreviewImageAtIndex:(NSInteger)index preferredSize:(CGSize)size compeletion:(void (^)(UIImage * _Nullable, NSInteger))compeletion
{
    NSAssert(NO, @"unsupported for video edit");
    [self getSourcePreviewImageAtTime:(NSTimeInterval)index preferredSize:size compeletion:^(UIImage * _Nullable image, NSTimeInterval atTime) {
        ACCBLOCK_INVOKE(compeletion, image, (NSInteger)atTime);
    }];
}

- (void)getProcessedPreviewImageAtIndex:(NSInteger)index preferredSize:(CGSize)size compeletion:(void (^)(UIImage * _Nullable, NSInteger))compeletion
{
    NSAssert(NO, @"unsupported for video edit");
    [self getProcessedPreviewImageAtTime:(NSTimeInterval)index preferredSize:size compeletion:^(UIImage * _Nullable image, NSTimeInterval atTime) {
        ACCBLOCK_INVOKE(compeletion, image, (NSInteger)atTime);
    }];
}

- (void)beginImageAlbumPreviewTaskExportItemRetainAndReuse
{
    NSAssert(NO, @"unsupported for video edit");
}

- (void)endImageAlbumPreviewTaskExportItemRetainAndReuse
{
    NSAssert(NO, @"unsupported for video edit");
}

@end
