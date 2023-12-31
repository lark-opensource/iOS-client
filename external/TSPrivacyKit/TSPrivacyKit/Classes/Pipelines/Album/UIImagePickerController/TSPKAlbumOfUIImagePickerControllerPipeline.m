//
//  TSPKAlbumOfUIImagePickerControllerPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKAlbumOfUIImagePickerControllerPipeline.h"
#import "TSPKFishhookUtils.h"
#import <UIkit/UIImagePickerController.h>
#include <BDFishhook/BDFishhook.h>
#import "NSObject+TSAddition.h"
#import "TSPKPipelineSwizzleUtil.h"

static NSString *const uiImageWriteToSavedPhotosAlbum = @"UIImageWriteToSavedPhotosAlbum";

static void (*tspk_old_UIImageWriteToSavedPhotosAlbum)(UIImage *image, id completionTarget, SEL completionSelector, void *contextInfo) = UIImageWriteToSavedPhotosAlbum;

static void tspk_new_UIImageWriteToSavedPhotosAlbum(UIImage *image, id completionTarget, SEL completionSelector, void *contextInfo)
{
    @autoreleasepool {
        TSPKHandleResult *result = [TSPKAlbumOfUIImagePickerControllerPipeline handleAPIAccess:uiImageWriteToSavedPhotosAlbum];
        if (result.action == TSPKResultActionFuse) {
            return;
        } else {
            return tspk_old_UIImageWriteToSavedPhotosAlbum(image, completionTarget, completionSelector, contextInfo);
        }
    }
}


static NSString *const uiSaveVideoAtPathToSavedPhotosAlbum = @"UISaveVideoAtPathToSavedPhotosAlbum";

static void (*tspk_old_UISaveVideoAtPathToSavedPhotosAlbum)(NSString *videoPath, __nullable id completionTarget, __nullable SEL completionSelector, void * __nullable contextInfo) = UISaveVideoAtPathToSavedPhotosAlbum;


static void tspk_new_UISaveVideoAtPathToSavedPhotosAlbum(NSString *videoPath, __nullable id completionTarget, __nullable SEL completionSelector, void * __nullable contextInfo)
{
    @autoreleasepool {
        TSPKHandleResult *result = [TSPKAlbumOfUIImagePickerControllerPipeline handleAPIAccess:uiSaveVideoAtPathToSavedPhotosAlbum];
        if (result.action == TSPKResultActionFuse) {
            return;
        } else {
            return tspk_old_UISaveVideoAtPathToSavedPhotosAlbum(videoPath, completionTarget, completionSelector, contextInfo);
        }
    }
}

@implementation UIImagePickerController (TSPrivacykitAlbum)

+ (void)tspk_album_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKAlbumOfUIImagePickerControllerPipeline class] clazz:self];
}

- (UIImagePickerController *)tspk_album_init {
    TSPKHandleResult *result = [TSPKAlbumOfUIImagePickerControllerPipeline handleAPIAccess:NSStringFromSelector(@selector(init)) className:[TSPKAlbumOfUIImagePickerControllerPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else {
        return [self tspk_album_init];
    }
}
@end


@implementation TSPKAlbumOfUIImagePickerControllerPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineAlbumOfUIImagePickerController;
}

+ (NSString *)dataType {
    return TSPKDataTypeAlbum;
}

+ (BOOL)isEntryDefaultEnable
{
    return NO;
}

+ (NSArray<NSString *> * _Nullable) stubbedCAPIs
{
    return @[uiImageWriteToSavedPhotosAlbum, uiSaveVideoAtPathToSavedPhotosAlbum];
}

+ (NSString *)stubbedClass
{
    return @"UIImagePickerController";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(init))
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct bd_rebinding saveImage;
        saveImage.name = [uiImageWriteToSavedPhotosAlbum UTF8String];
        saveImage.replacement = tspk_new_UIImageWriteToSavedPhotosAlbum;
        saveImage.replaced = (void *)&tspk_old_UIImageWriteToSavedPhotosAlbum;
        
        struct bd_rebinding saveVideo;
        saveVideo.name = [uiSaveVideoAtPathToSavedPhotosAlbum UTF8String];
        saveVideo.replacement = tspk_new_UISaveVideoAtPathToSavedPhotosAlbum;
        saveVideo.replaced = (void *)&tspk_old_UISaveVideoAtPathToSavedPhotosAlbum;
        
        struct bd_rebinding rebs[]={saveImage, saveVideo};
        tspk_rebind_symbols(rebs, 2);
        
        [UIImagePickerController tspk_album_preload];
    });
}

- (BOOL)deferPreload {
    return YES;
}

@end
