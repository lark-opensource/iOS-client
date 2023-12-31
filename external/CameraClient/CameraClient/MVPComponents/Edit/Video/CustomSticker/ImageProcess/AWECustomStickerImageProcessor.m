//
//  AWECustomStickerImageProcessor.m
//  CameraClient
//
//  Created by 卜旭阳 on 2020/6/19.
//

#import "AWECustomStickerImageProcessor.h"
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <ByteDanceKit/NSData+BTDAdditions.h>
#import <ByteDanceKit/UIImage+BTDAdditions.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AVFoundation/AVMediaFormat.h>
#import <YYImage/YYImage.h>
#import "AWECustomPhotoStickerEditConfig.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import "AWECustomStickerLimitConfig.h"
#import "AWEVideoEditDefine.h"
#import <BDWebImage/BDImage.h>
#import <CreationKitInfra/ACCLogHelper.h>

NSString *const AWECustomStickerFileSuffixComponent = @"component_custom_upload_sticker";

@interface AWECustomStickerImageProcessor()

@end

@implementation AWECustomStickerImageProcessor

+ (BOOL)supportCustomStickerForDataUTI:(NSString *)uti isImageAlbumEdit:(BOOL)isImageAlbumEdit
{
    if(!uti || !uti.length) return NO;
    if (@available(iOS 9.1, *)) {
        if([uti isEqualToString:(id)kUTTypeLivePhoto]) return YES;
    }
    if (@available(iOS 11.0, *)) {
        if([uti isEqualToString:AVFileTypeHEIC] || [uti isEqualToString:(id)AVFileTypeHEIF] || [uti isEqualToString:AVFileTypeAVCI]) return YES;
    }
    
    if (isImageAlbumEdit && [uti isEqualToString:(id)kUTTypeGIF]) {
        return NO;
    }
    
    return [uti isEqualToString:(id)kUTTypeJPEG] || [uti isEqualToString:(id)kUTTypePNG] || [uti isEqualToString:(id)kUTTypeGIF] || [uti isEqualToString:(id)kUTTypeJPEG2000] || [uti isEqualToString:(id)kUTTypeTIFF] || [uti isEqualToString:(id)kUTTypeAppleICNS] || [uti isEqualToString:(id)kUTTypeBMP] || [uti isEqualToString:(id)kUTTypeICO];
}

+ (void)compressInputStickerOriginData:(NSData *)originData isGIF:(BOOL)isGIF limitConfig:(AWECustomStickerLimitConfig *)limitConfig completionBlock:(void(^)(BOOL, YYImage *, UIImage *))completionBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        YYImage *animatedImage = nil;
        UIImage *inputImage = nil;
        if(isGIF) {
            animatedImage = [YYImage imageWithData:originData];
        } else {
            inputImage = [UIImage imageWithData:originData];
            inputImage = [UIImage btd_fixImgOrientation:inputImage];
            inputImage = [UIImage btd_tryCompressImage:inputImage ifImageSizeLargeTargetSize:CGSizeMake(limitConfig.uploadWidthLimit, limitConfig.uploadHeightLimit)];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            ACCBLOCK_INVOKE(completionBlock,animatedImage && inputImage,animatedImage,inputImage);
        });
    });
}

+ (id)requestProcessedStickerImage:(UIImage *)inputImage completion:(void(^)( BOOL , AWECustomPhotoStickerClipedInfo *, UIImage *, NSError *))completionBlock
{
    //Reduce data cost and server will return PNG no matter the upload format
    NSData *inputData = UIImageJPEGRepresentation(inputImage, 0.9);
    return [ACCNetService() uploadWithModel:^(ACCRequestModel * _Nullable requestModel) {
        NSString *url = [NSString stringWithFormat:@"%@/media/api/pic/iss", ACCEffectRequestDomain];
        NSDictionary *parameter = @{@"key":inputData.btd_md5String?:@""};
        requestModel.requestType = ACCRequestTypePOST;
        requestModel.urlString = url;
        requestModel.params = parameter;
        requestModel.timeout = 5.f;
        requestModel.bodyBlock = ^(id<TTMultipartFormData> formData) {
            [formData appendPartWithFileData:inputData name:@"file" fileName:@"file" mimeType:@"image/png"];
        };
    } progress:nil completion:^(id  _Nullable model, NSError * _Nullable error) {
        NSDictionary *dict = (NSDictionary *)model;
        AWECustomPhotoStickerClipedInfo *info = nil;
        UIImage *processedImage = nil;
        BOOL success = NO;
        if([dict isKindOfClass:NSDictionary.class] && !error) {
            NSDictionary *data = dict[@"data"];
            info = [MTLJSONAdapter modelOfClass:AWECustomPhotoStickerClipedInfo.class fromJSONDictionary:data error:&error];
            if([info clipInfoValid]) {
                success = YES;
                NSData *processedData = [[NSData alloc] initWithBase64EncodedString:info.content options:NSUTF8StringEncoding];
                processedImage = [UIImage imageWithData:processedData];
            }
        }
        ACCBLOCK_INVOKE(completionBlock,success,info,processedImage,error);
    }];
}

+ (void)saveAndSampleStickerImage:(UIImage *)outputImage usePNG:(BOOL)usePNG filePrefix:(NSString *)filePrefix completionBlock:(void(^)(BOOL, NSString *, NSArray *))completionBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *writeError = nil;
        NSData *resultData = nil;
        NSString *suffix = @"";
        
        BOOL isGIF = [outputImage isKindOfClass:YYImage.class];
        YYImage *animatedImage = nil;
        
        if(isGIF) {
            animatedImage = (YYImage *)outputImage;
            if(animatedImage.animatedImageData && [animatedImage animatedImageFrameCount] > 1) {
                resultData = animatedImage.animatedImageData;
                suffix = @"gif";
            } else {
                resultData = [AWECustomStickerImageProcessor extractInputDataFromImage:animatedImage usePNG:usePNG];
                suffix = @"png";
            }
        } else {
            resultData = [AWECustomStickerImageProcessor extractInputDataFromImage:outputImage usePNG:usePNG];
            suffix = @"png";
        }
        NSString *mainFilePath = [NSString stringWithFormat:@"%@.%@",filePrefix,suffix];
        BOOL OK = [resultData acc_writeToFile:mainFilePath options:NSDataWritingAtomic error:&writeError];
        //extract frames
        NSMutableArray *extractFrames = [NSMutableArray new];
        if(OK && !writeError) {
            if(isGIF && [animatedImage animatedImageFrameCount] > 1) {
                YYImage *animatedImage = (YYImage *)outputImage;
                CGFloat duration = 0;
                CGFloat step = 0;
                for(int i = 0 ; i < animatedImage.animatedImageFrameCount ; i++)
                {
                    NSTimeInterval frameDur = [animatedImage animatedImageDurationAtIndex:i];
                    if(i == 0 || (duration <= step && duration+frameDur >= step)) {
                        @autoreleasepool {
                            UIImage *frameImg = [animatedImage animatedImageFrameAtIndex:i];
                            NSData *frameData = UIImageJPEGRepresentation(frameImg, 0.9);
                            NSString *filePath = [NSString stringWithFormat:@"%@_%d.%@",filePrefix,i,@"jpeg"];
                            OK = [frameData acc_writeToFile:filePath options:NSDataWritingAtomic error:&writeError];
                            if(!OK || writeError) {
                                break;
                            } else {
                                [extractFrames addObject:filePath];
                            }
                        }
                        step += 2;
                    }
                    duration += frameDur;
                }
            } else if(mainFilePath) {
                [extractFrames addObject:mainFilePath];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL success = OK && !writeError;
            ACCBLOCK_INVOKE(completionBlock,success,mainFilePath,extractFrames.copy);
        });
    });
}

+ (NSArray<NSString *> *)regenerateTheCustomImageForPath:(NSString *)imagePath;
{
    NSMutableArray<NSString *> *customUploadPaths = [NSMutableArray array];
    BDImage *customImage = [BDImage imageWithContentsOfFile:imagePath];
    if (customImage == nil) {
        return nil;
    } else {
        if (customImage.isAnimateImage) {
            NSString *filePrefix = [imagePath stringByDeletingPathExtension];
            CGFloat duration = 0;
            CGFloat step = 0;
            for(int i = 0 ; i < customImage.frameCount ; i++) {
                BDAnimateImageFrame *imageFrame = [customImage frameAtIndex:i];
                if(i == 0 || (duration <= step && duration + imageFrame.delay >= step)) {
                    @autoreleasepool {
                        NSData *frameData = UIImageJPEGRepresentation(imageFrame.image, 0.9);
                        NSString *filePath = [NSString stringWithFormat:@"%@_%d.%@", filePrefix, i, @"jpeg"];
                        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                            [customUploadPaths addObject:filePath];
                        } else {
                            NSError *writeError = nil;
                            BOOL OK = [frameData acc_writeToFile:filePath options:NSDataWritingAtomic error:&writeError];
                            if(!OK || writeError != nil) {
                                AWELogToolError2(@"CustomSticker", AWELogToolTagDraft, @"Write Custom Sticker Upload Image: %@ Error: %@", filePath, writeError);
                                writeError = nil;
                                continue;
                            } else {
                                [customUploadPaths addObject:filePath];
                            }
                        }
                    }
                    step += 2;
                }
                duration += imageFrame.delay;
            }
        } else {
            [customUploadPaths addObject:imagePath];
        }
        
        return customUploadPaths;
    }
}

#pragma mark - private
//processedImage won't be very big
+ (NSData *)extractInputDataFromImage:(UIImage *)image usePNG:(BOOL)usePNG
{
    if(usePNG) {
        return UIImagePNGRepresentation(image);
    } else {
        return UIImageJPEGRepresentation(image, 0.9);
    }
}

@end
