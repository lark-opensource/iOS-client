//
//  ACCNLEEditCaptureFrameWrapper.m
//  CameraClient-Pods-Aweme
//
//  Created by HuangHongsen on 2021/4/28.
//

#import "ACCNLEEditCaptureFrameWrapper.h"
#import <NLEPlatform/NLEInterface.h>
#import <NLEPlatform/NLECaptureOutput.h>

@interface ACCNLEEditCaptureFrameWrapper()<ACCEditBuildListener>

@property (nonatomic, weak) NLEInterface_OC *nle;

@end

@implementation ACCNLEEditCaptureFrameWrapper

- (void)setEditSessionProvider:(nonnull id<ACCEditSessionProvider>)editSessionProvider {
    [editSessionProvider addEditSessionListener:self];
}

- (UIImage *)capturePreviewUIImage {
    return [[self.nle captureOutput] capturePreviewUIImage];
}

- (void)getProcessedPreviewImageAtTime:(NSTimeInterval)atTime preferredSize:(CGSize)size compeletion:(void (^ _Nullable)(UIImage * _Nullable, NSTimeInterval))compeletion {
    [[self.nle captureOutput] getProcessedPreviewImageAtTime:atTime preferredSize:size isLastImage:YES compeletion:compeletion];
}

- (void)getSourcePreviewImageAtIndex:(NSInteger)index preferredSize:(CGSize)size compeletion:(void (^ _Nullable)(UIImage * _Nullable, NSInteger))compeletion {
}

- (void)getSourcePreviewImageAtTime:(NSTimeInterval)atTime preferredSize:(CGSize)size compeletion:(void (^ _Nullable)(UIImage * _Nullable, NSTimeInterval))compeletion {
    
    [[self.nle captureOutput] getSourcePreviewImageAtTime:atTime preferredSize:size isLastImage:YES compeletion:compeletion];
}

- (void)processImageWithCompleteBlock:(void (^ _Nonnull)(UIImage * _Nonnull, NSError * _Nullable))block {
    [[self.nle captureOutput] processImageWithCompleteBlock:block];
}

#pragma mark - Image Album editor

- (void)endImageAlbumPreviewTaskExportItemRetainAndReuse {
}

- (void)getProcessedPreviewImageAtIndex:(NSInteger)index preferredSize:(CGSize)size compeletion:(void (^ _Nullable)(UIImage * _Nullable, NSInteger))compeletion {
}

- (void)beginImageAlbumPreviewTaskExportItemRetainAndReuse {
}

#pragma mark - ACCEditBuildListener

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editorSession {}

- (void)onNLEEditorInit:(NLEInterface_OC *)editor {
    self.nle = editor;
}


@end
