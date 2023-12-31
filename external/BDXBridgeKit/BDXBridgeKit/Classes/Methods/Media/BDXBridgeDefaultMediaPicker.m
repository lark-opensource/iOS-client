//
//  BDXBridgeDefaultMediaPicker.m
//  BDXBridgeKit-Pods-Aweme
//
//  Created by li keliang on 2021/3/25.
//

#import "BDXBridgeDefaultMediaPicker.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeServiceManager.h"
#import "BDXBridgeChooseMediaMethod.h"
#import "BDXBridgeServiceDefinitions.h"
#import "NSString+BDXBridgeAdditions.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <Photos/PHImageManager.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface BDXBridgeDefaultMediaPicker ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, nullable) BDXBridgeChooseMediaMethodParamModel *params;
@property (nonatomic, nullable) BDXBridgeChooseMediaCompletionHandler completionHandler;
@property (nonatomic, weak, nullable) UIImagePickerController *imagePicker;

@end

@implementation BDXBridgeDefaultMediaPicker

#pragma mark - BDXBridgeChooseMediaPicker

- (BOOL)supportedWithParamModel:(BDXBridgeChooseMediaMethodParamModel *)paramModel
{
    return YES;
}

- (UIViewController *)mediaPickerWithParamModel:(BDXBridgeChooseMediaMethodParamModel *)paramModel completionHandler:(BDXBridgeChooseMediaCompletionHandler)completionHandler
{
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if (paramModel.sourceType == BDXBridgeMediaSourceTypeAlbum) {
        sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    if (sourceType == UIImagePickerControllerSourceTypeCamera && [self isCameraDenied]) {
        NSString *message = [NSString stringWithFormat:@"Cannot access camera. Please go to Settings > Privacy and grant the permission for %@.", [UIApplication btd_appDisplayName]];
        
        UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"tip" message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertView addAction:[UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeUnauthorizedAccess message:@"The access to camera is unauthorized."]);
        }]];
        
        [alertView addAction:[UIAlertAction actionWithTitle:@"go_to_settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeUnauthorizedAccess message:@"The access to camera is unauthorized."]);
        }]];

        [[BTDResponder topViewController] presentViewController:alertView animated:YES completion:nil];
        return nil;
    } else {
        BDXBridgeMediaType  mediaTypes = paramModel.mediaTypes;
        BDXBridgeCameraType cameraType = paramModel.cameraType;
        
        NSMutableArray<NSString *> *mappedMediaTypes = [NSMutableArray array];
        if (mediaTypes & BDXBridgeMediaTypeImage) {
            [mappedMediaTypes addObject:(NSString *)kUTTypeImage];
        }
        if (mediaTypes & BDXBridgeMediaTypeVideo) {
            [mappedMediaTypes addObject:(NSString *)kUTTypeVideo];
            [mappedMediaTypes addObject:(NSString *)kUTTypeMovie];
        }
        
        if (mappedMediaTypes.count == 0) {
            [self finishWithResultModel:nil status:[BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"Unknown media types: %@.", @(mediaTypes)]];
            return nil;
        }
        
        UIImagePickerControllerCameraDevice cameraDevice;
        switch (cameraType) {
            case BDXBridgeCameraTypeFront:
                cameraDevice = UIImagePickerControllerCameraDeviceFront;
                break;
            case BDXBridgeCameraTypeBack:
                cameraDevice = UIImagePickerControllerCameraDeviceRear;
                break;
            default:
                [self finishWithResultModel:nil status:[BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"Unknown camera type: %@.", @(cameraType)]];
                return nil;
        }
        
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.sourceType = sourceType;
        imagePicker.allowsEditing = NO;
        
        id<BDXBridgeMediaServiceProtocol> mediaService = bdx_get_service(BDXBridgeMediaServiceProtocol);
        if ([mediaService respondsToSelector:@selector(barTintColor)]) {
            imagePicker.navigationBar.barTintColor = [mediaService barTintColor];
        }
        if ([mediaService respondsToSelector:@selector(tintColor)]) {
            imagePicker.navigationBar.tintColor = [mediaService tintColor];
        }
        
        imagePicker.mediaTypes = [mappedMediaTypes copy];
        if (sourceType == UIImagePickerControllerSourceTypeCamera) {
            imagePicker.cameraDevice = cameraDevice;
        }
        if (mediaTypes & BDXBridgeMediaTypeVideo) {
            imagePicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
        }
        imagePicker.delegate = self;
        
        self.imagePicker = imagePicker;
        self.completionHandler = completionHandler;
        
        return imagePicker;
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self finishWithResultModel:nil status:[BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeOperationCancelled message:@"The user has cancelled the operation."]];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info
{
    BDXBridgeChooseMediaMethodResultTempFileModel *tempFileModel = [BDXBridgeChooseMediaMethodResultTempFileModel new];
    
    // Get media type
    CFStringRef mediaType = (__bridge CFStringRef)info[UIImagePickerControllerMediaType];
    if (UTTypeConformsTo(mediaType, kUTTypeMovie)) {
        NSURL *mediaURL = info[UIImagePickerControllerMediaURL];
        if (!mediaURL) {
            return [self finishWithResultModel:nil status:[BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidResult message:@"The video URL is nil when taking from camera."]];
        }

        tempFileModel.mediaType = BDXBridgeMediaTypeVideo;
        
        // Get file path
        tempFileModel.tempFilePath = [mediaURL.path bdx_stringByStrippingSandboxPath];
        
        // Get file size
        NSError *error = nil;
        NSDictionary<NSURLResourceKey, id> *resourceValues = [mediaURL resourceValuesForKeys:@[NSURLFileSizeKey] error:&error];
        if (error) {
            bdx_invoke_block(self.completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidResult message:error.localizedDescription]);
            return;
        }
        tempFileModel.size = resourceValues[NSURLFileSizeKey];
        
        // Save to photo album if needed
        if (self.params.saveToPhotoAlbum) {
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(mediaURL.path)) {
                UISaveVideoAtPathToSavedPhotosAlbum(mediaURL.path, nil, nil, nil);
            } else {
                return [self finishWithResultModel:nil status:[BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidResult message:@"Failed to save the video to photo album."]];
            }
        }
    } else if (UTTypeConformsTo(mediaType, kUTTypeImage)) {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        if (!image) {
            return [self finishWithResultModel:nil status:[BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidResult message:@"The image is nil when taking from camera."]];
        }

        tempFileModel.mediaType = BDXBridgeMediaTypeImage;
        
        // Save to disk
        NSData *imageData = [self imageDataForImage:image];
        if (!imageData) {
            return [self finishWithResultModel:nil status:[BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidResult message:@"Failed to convert to JPEG."]];
        }
        NSString *filePath = [self writeImageDataToDisk:imageData];
        if (!filePath) {
            return [self finishWithResultModel:nil status:[BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidResult message:@"Failed to save JPEG to disk."]];
        }
        tempFileModel.tempFilePath = [filePath bdx_stringByStrippingSandboxPath];
        tempFileModel.size = @(imageData.length);
        if (self.params.needBinaryData) {
            NSMutableArray *binaryData = @[].mutableCopy;
            Byte *byteArray = (Byte *)[imageData bytes];
            for (int i = 0; i < [imageData length]; i ++) {
                [binaryData btd_addObject:@(byteArray[i])];
            }
            tempFileModel.binaryData = binaryData.copy;
        }
        
        // Save to photo album if needed
        if (self.params.saveToPhotoAlbum) {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        }
    } else {
        bdx_invoke_block(self.completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidResult message:@"Unknown media type: %@.", mediaType]);
        return;
    }
    
    BDXBridgeChooseMediaMethodResultModel *resultModel = [BDXBridgeChooseMediaMethodResultModel new];
    resultModel.tempFiles = @[tempFileModel];
    [self finishWithResultModel:resultModel status:nil];
}

#pragma mark - Helpers

- (BOOL)isCameraDenied
{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    return (status == AVAuthorizationStatusRestricted || status == AVAuthorizationStatusDenied);
}

- (NSData *)imageDataForImage:(UIImage *)image
{
    if (!self.params.compressImage) {
        return UIImagePNGRepresentation(image);
    }
    if (!(self.params.needBinaryData && (self.params.compressWidth > 0) && (self.params.compressHeight > 0))) {
        return UIImageJPEGRepresentation(image, 0.8);
    }
    
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    CGFloat wScale = imageWidth / self.params.compressWidth.floatValue;
    CGFloat hScale = imageHeight / self.params.compressHeight.floatValue;
    
    CGSize newSize = image.size;
    BOOL needRedraw = NO;
    if (wScale > hScale && wScale > 1) {
        newSize.width = self.params.compressWidth.floatValue;
        newSize.height = imageHeight / wScale;
        needRedraw = YES;
    } else if (hScale > wScale && hScale > 1) {
        newSize.width = imageWidth / hScale;
        newSize.height = self.params.compressHeight.floatValue;
        needRedraw = YES;
    }
    
    if (needRedraw) {
        UIGraphicsBeginImageContext(newSize);
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return UIImageJPEGRepresentation(image, 1);
}

- (NSString *)writeImageDataToDisk:(NSData *)imageData
{
    NSString *fileName = [NSString stringWithFormat:@"%@.%@", [[NSUUID UUID] UUIDString], self.params.compressImage ? @"JPEG" : @"PNG"];
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    return [imageData writeToURL:fileURL atomically:YES] ? filePath : nil;
}

- (void)finishWithResultModel:(BDXBridgeChooseMediaMethodResultModel *)resultModel status:(BDXBridgeStatus *)status
{
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
    
    bdx_invoke_block(self.completionHandler, resultModel, status);
    self.completionHandler = nil;
}

@end
