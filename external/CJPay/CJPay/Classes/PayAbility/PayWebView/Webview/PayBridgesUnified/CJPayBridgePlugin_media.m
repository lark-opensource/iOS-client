//
//  CJPayBridgePlugin_media.m
//  Pods
//
//  Created by 孔伊宁 on 2021/10/26.
//

#import "CJPayBridgePlugin_media.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <PhotosUI/PhotosUI.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import "CJPayAlertController.h"
#import "CJPayBridgeOCRModel.h"
#import "CJPayCardOCRUtil.h"
#import "CJPayJSONResponseSerializer.h"
#import "CJPayPrivacyMethodUtil.h"
#import "CJPaySafeManager.h"
#import "CJPaySDKJSONRequestSerializer.h"
#import "CJPaySDKMacro.h"
#import "CJPaySettingsManager.h"
#import "CJPaySaasSceneUtil.h"
#import "NSDictionary+CJPay.h"
#import "CJPayRequestParam.h"

#define KB  1024
#define MEDIA_LIMIT 1024 // 本地默认值是1M = 1024KB

@interface CJPayBridgePlugin_media()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate>

@property (nonatomic, copy) void(^failUploadBlock)(void);
@property (nonatomic, copy) void(^chooseImageCompletionBlock)(UIImage *image);
@property (nonatomic, copy) void(^chooseVideoCompletionBlock)(NSString *url);
@property (nonatomic, copy) void(^failBlock)(NSString *code);//0成功 -1取消 -2无权限 1失败 2上传了视频
@property (nonatomic, strong) NSMutableDictionary *md52PathMap; //文件名与对应的md5加密的map
@property (nonatomic, assign) BOOL isNeedClear; //是否需要清理拍照文件
@property (nonatomic, assign) CGFloat compressSize; //视频压缩大小

@end

@implementation CJPayBridgePlugin_media

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_media, chooseMedia), @"ttcjpay.chooseMedia");
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_media, uploadMedia), @"ttcjpay.uploadMedia");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)chooseMediaWithParam:(NSDictionary *)param
                    callback:(TTBridgeCallback)callback
                      engine:(id<TTBridgeEngine>)engine
                  controller:(UIViewController *)controller {
    CJPayOCRFileSourceModel *resModel = [CJPayOCRFileSourceModel new];
    CJPayOCRFileResponseModel *resFileModel = [CJPayOCRFileResponseModel new];
    [self p_initBlockWithModel:resModel fileModel:resFileModel callback:callback param:param];
    if (![param isKindOfClass:[NSDictionary class]]) {
        CJ_CALL_BLOCK(self.failBlock, @"1");
        return;
    }
    self.compressSize = [param cj_intValueForKey:@"compress_size" defaultValue:MEDIA_LIMIT];
    NSString *sourceType = [param cj_stringValueForKey:@"source_type"];
    BOOL isCamera = [sourceType isEqualToString:@"camera"];
    BOOL isVideo = [sourceType isEqualToString:@"video"];
    BOOL isAlbum = [sourceType isEqualToString:@"album"];
    
    if (isCamera || isVideo) {
        //检查相机权限
        [self p_checkCameraPermissionWithController:controller];
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            picker.delegate = self;
            picker.allowsEditing = NO;
            BOOL isBackCamera = [[param cj_stringValueForKey:@"camera_type"] isEqualToString:@"back"];
            if (isBackCamera) {
                if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
                    picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
                }
            } else {
                if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
                    picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
                }
            }
            
            if (isCamera) {
                picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
            } else {
                picker.mediaTypes = @[(NSString *)kUTTypeMovie];
                picker.videoMaximumDuration = 60.0; //设置最大录制时长为60s
            }
            picker.modalPresentationStyle = UIModalPresentationFullScreen;
            [controller presentViewController:picker animated:NO completion:nil];
        }
    } else if (isAlbum){
        if (@available(iOS 14.0, *)) {
            PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
            config.selectionLimit = 1;
            config.filter = [PHPickerFilter imagesFilter];
            PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
            picker.delegate = self;
            [controller presentViewController:picker animated:YES completion:nil];
        } else {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            picker.delegate = self;
            picker.allowsEditing = NO;
            picker.modalPresentationStyle = UIModalPresentationFullScreen;
            [controller presentViewController:picker animated:YES completion:nil];
        }
    }
}

- (void)uploadMediaWithParam:(NSDictionary *)param
                    callback:(TTBridgeCallback)callback
                      engine:(id<TTBridgeEngine>)engine
                  controller:(UIViewController *)controller {
    CJPayOCRResponseModel *resModel = [CJPayOCRResponseModel new];
    CJPayOCRUploadResponseModel *resDataModel = [CJPayOCRUploadResponseModel new];
    self.failUploadBlock = ^{
        resModel.code = @"1";
        CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toDictionary], nil);
    };
    
    if (![param isKindOfClass:[NSDictionary class]]) {
        CJ_CALL_BLOCK(self.failUploadBlock);
        return;
    }
    
    NSString *tempPath = [param cj_stringValueForKey:@"file_path"];
    tempPath = [self.md52PathMap cj_stringValueForKey:tempPath];

    NSFileManager *manager = [NSFileManager defaultManager];
    if(![manager fileExistsAtPath:tempPath]){
        CJ_CALL_BLOCK(self.failUploadBlock);
        return;
    }
    
    NSString *publicKey = [param cj_stringValueForKey:@"public_key"];
    NSString *isecKey = [param cj_stringValueForKey:@"isec_key"];

    BOOL isUploadImage = [[tempPath pathExtension] isEqualToString:@"jpg"];
    if (isUploadImage) { //图片上传
        UIImage *image = [UIImage imageWithContentsOfFile:tempPath];
        NSString *size = [param cj_stringValueForKey:@"compress_limit"];
        CJPayLogInfo(@"image size-upload: width=%f, height=%f", image.size.width, image.size.height);
        
        // 图片大小需要限定，否则加密模块会崩溃or后端无法识别
        NSInteger compressSizeLimit = [CJPaySettingsManager shared].currentSettings.uploadMediaConfig.defaultMaxSize;
        compressSizeLimit = compressSizeLimit > 0 ? compressSizeLimit : MEDIA_LIMIT;
        if (Check_ValidString(size) && [size doubleValue] / KB <= compressSizeLimit) {
            compressSizeLimit = [size doubleValue] / KB;
        }
        NSInteger fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:tempPath error:nil] fileSize] / KB; // 单位KB
        @CJWeakify(self)
        // 如果待上传的文件尺寸小于compressSize，就没有压缩的必要了，传0表示不需要压缩。
        [self p_processImage:image compressSize:(fileSize <= compressSizeLimit) ? 0 : compressSizeLimit completion:^(NSData *imgData) {
            @CJStrongify(self)
            BOOL result = [imgData writeToFile:tempPath atomically:YES];
            if (!result) {
                CJ_CALL_BLOCK(self.failBlock, @"1");
                return;
            }
            
            NSString *media = @"";
            BOOL isNeedEncrypt = Check_ValidString(publicKey) || Check_ValidString(isecKey);
            NSNumber *engimaVersion;
            if (isNeedEncrypt && imgData) { //图片加密
                media = [CJPaySafeManager encryptMediaData:imgData tfccCert:publicKey iSecCert:isecKey engimaVersion:&engimaVersion];
            }
            
            NSDictionary *requestParams = @{
                @"media" : Check_ValidString(media) ? media : CJString([imgData base64EncodedStringWithOptions:0]),
                @"public_key" : CJString(publicKey),
                @"params" : CJString([param cj_stringValueForKey:@"params"]),
                @"enigma_version": engimaVersion ?: @(0),
            };
            
            NSString *url = [param cj_stringValueForKey:@"url"];
            NSDictionary *header = [self p_createUploadRequestHeader:param];
            
            [[TTNetworkManager shareInstance] requestForJSONWithResponse:url
                                                                  params:requestParams
                                                                  method:@"POST"
                                                        needCommonParams:NO
                                                             headerField:header
                                                       requestSerializer:[CJPaySDKJSONRequestSerializer class]
                                                      responseSerializer:[CJPayJSONResponseSerializer class]
                                                              autoResume:YES
                                                                callback:^(NSError *error, id obj, TTHttpResponse *response) {
                resModel.code = @"0";
                resDataModel.httpCode = response.statusCode;
                resDataModel.header = response.allHeaderFields;
                resDataModel.response = obj;
                resModel.data = resDataModel;
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toDictionary], nil);
            }];
        }];
    } else { //视频上传
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *videoData = [NSData dataWithContentsOfFile:tempPath];
            NSDictionary *header = [self p_createUploadRequestHeader:param];
            NSDictionary *requestParams = @{
                @"media" : CJString([videoData base64EncodedStringWithOptions:0]),
                @"public_key" : @"",
                @"params" : CJString([param cj_stringValueForKey:@"params"])
            };
            NSString *url = [param cj_stringValueForKey:@"url"];
            [[TTNetworkManager shareInstance] requestForJSONWithResponse:url
                                                                  params:requestParams
                                                                  method:@"POST"
                                                        needCommonParams:NO
                                                             headerField:header
                                                       requestSerializer:[CJPaySDKJSONRequestSerializer class]
                                                      responseSerializer:[CJPayJSONResponseSerializer class]
                                                              autoResume:YES
                                                                callback:^(NSError *error, id obj, TTHttpResponse *response) {
                resModel.code = @"0";
                resDataModel.httpCode = response.statusCode;
                resDataModel.header = response.allHeaderFields;
                resDataModel.response = obj;
                resModel.data = resDataModel;
                dispatch_async(dispatch_get_main_queue(), ^{
                    CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toDictionary], nil);
                });
            }];
        });
    }
}

- (NSDictionary *)p_createUploadRequestHeader:(NSDictionary *)param {
    
    NSMutableDictionary *header = [NSMutableDictionary new];
    NSDictionary *originHeader = [param cj_dictionaryValueForKey:@"header"];
    if (Check_ValidDictionary(originHeader)) {
        [header addEntriesFromDictionary:originHeader];
    }
    // Saas场景需增加accessToken
    if ([[param cj_stringValueForKey:CJPaySaasKey] isEqualToString:@"1"]) {
        NSString *accessToken = [CJPayRequestParam accessToken];
        if (!Check_ValidString(accessToken)) {
            CJPayLogAssert(YES, @"Saas场景无法取到accessToken，uploadMedia URL：%@", CJString([param cj_stringValueForKey:@"url"]));
        }
        [header cj_setObject:CJString(accessToken) forKey:@"bd-ticket-guard-target"];//增加开放平台证书
        NSString *bearerAccessToken = [NSString stringWithFormat:@"Bearer %@", CJString(accessToken)]; //用户鉴权信息为Bearer XXX
        [header cj_setObject:CJString(bearerAccessToken) forKey:@"authorization"];
    }
    
    return [header copy];
}

- (void)dealloc {
    if (!self.isNeedClear){
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ocrPhoto"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = NO;
        BOOL existed = [fileManager fileExistsAtPath:tempPath isDirectory:&isDir];
        if (isDir && existed) {
            [fileManager removeItemAtPath:tempPath error:nil];
        }
    });
}

#pragma mark private methods

- (void)p_initBlockWithModel:(CJPayOCRFileSourceModel *)resModel
                   fileModel:(CJPayOCRFileResponseModel *)resFileModel
                    callback:(TTBridgeCallback)callback
                       param:(NSDictionary *)param {
    @CJWeakify(self)
    self.chooseImageCompletionBlock = ^(UIImage *image) {
        CJPayLogInfo(@"image size: width: %f, height:%f", image.size.width, image.size.height);
        @CJStrongify(self)
        NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ocrPhoto"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = NO;
        BOOL existed = [fileManager fileExistsAtPath:tempPath isDirectory:&isDir];
        if (!(isDir && existed)) {
            [fileManager createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        NSString *filename = [NSString stringWithFormat:@"%@.jpg", [NSString stringWithFormat:@"%.0lf", [[NSDate date] timeIntervalSince1970]]];
        tempPath = [tempPath stringByAppendingPathComponent:filename];
        NSString *md5Str = [tempPath cj_md5String];
        [self.md52PathMap cj_setObject:tempPath forKey:[tempPath cj_md5String]];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BOOL result = [UIImageJPEGRepresentation(image, 1.0) writeToFile:tempPath atomically:YES];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!result) {
                    CJ_CALL_BLOCK(self.failBlock, @"1");
                    CJPayLogInfo(@"图片写入文件失败，path = %@", tempPath);
                    return;
                }
                
                self.isNeedClear = YES;
                NSFileManager *manager = [NSFileManager defaultManager];
                NSInteger dataSize = 0;
                if ([manager fileExistsAtPath:tempPath]) {
                    dataSize = [[manager attributesOfItemAtPath:tempPath error:nil] fileSize];
                }
                
                resModel.code = @"0";
                resFileModel.mediaType = @"image";
                resFileModel.metaFilePrefix = @"data:image/jpeg;base64,";
                resFileModel.size = [NSString stringWithFormat:@"%ld", dataSize]; // 这里size传的是压缩前的
                resFileModel.filePath = md5Str;
                [self p_processImage:image compressSize:(dataSize < self.compressSize) ? 0 : self.compressSize completion:^(NSData *imageData) {
                    resFileModel.metaFile = [imageData base64EncodedStringWithOptions:0];
                    resModel.data = resFileModel;
                    CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toDictionary], nil);
                }];
            });
        });
    };
    self.failBlock = ^(NSString *code) {
        resModel.code = code;
        CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toDictionary], nil);
    };
    self.chooseVideoCompletionBlock = ^(NSString *path) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @CJStrongify(self)
            self.isNeedClear = YES;
            resModel.code = @"0";
            resFileModel.mediaType = @"video";
            NSData *data = [NSData dataWithContentsOfFile:path];
            CGFloat dataSize = [[NSData dataWithContentsOfFile:path] length];
            resFileModel.size = [NSString stringWithFormat:@"%f", dataSize];
            NSString *md5Str = [path cj_md5String];
            [self.md52PathMap cj_setObject:path forKey:md5Str];
            resFileModel.filePath = md5Str;
            resFileModel.metaFile = [data base64EncodedStringWithOptions:0];
            resModel.data = resFileModel;
            dispatch_async(dispatch_get_main_queue(), ^{
                CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, [resModel toDictionary], nil);
            });
        });
    };
}

// compress_size为0或缺省时不压缩
- (void)p_processImage:(UIImage *)image compressSize:(CGFloat)compressSize completion:(void(^)(NSData *imageData))completion {
    if (compressSize != 0) {
        CJPayLogInfo(@"图片压缩, compressSize = %@", @(compressSize));
        [CJPayCardOCRUtil compressWithImageV2:image size:compressSize completionBlock:^(NSData * _Nonnull imageData) {
            CJPayLogInfo(@"图片压缩后 size = %@ KB", @(imageData.length / KB));
            CJ_CALL_BLOCK(completion, imageData);
        }];
    } else {
        NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
        CJPayLogInfo(@"图片未压缩 size = %@ KB", @(imageData.length / KB));
        CJ_CALL_BLOCK(completion, imageData);
    }
}

- (void)p_checkCameraPermissionWithController:(UIViewController *)controller  {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusAuthorized) {
        //权限已获取
    } else if (authStatus == AVAuthorizationStatusNotDetermined) { //首次授权
        @CJWeakify(self)
        // 调用相机敏感方法，需走BPEA鉴权
        [CJPayPrivacyMethodUtil requestAccessForMediaType:AVMediaTypeVideo
                                               withPolicy:@"bpea-caijing_jsb_request_camera_permission"
                                            bridgeCommand:nil
                                        completionHandler:^(BOOL granted, NSError * _Nullable error) {
            
            @CJStrongify(self)
            if (error || !granted) {
                if (error) {
                    CJPayLogError(@"error in bpea-caijing_jsb_request_camera_permission");
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [controller dismissViewControllerAnimated:NO completion:nil];
                });
                CJ_CALL_BLOCK(self.failBlock, @"-2");
                return;
            }
        }];
    } else {
        CJPayAlertController *requestAuthAlert = [CJPayAlertController alertControllerWithTitle:CJPayLocalizedStr(@"请在设置中打开相机权限") message:@"" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:CJPayLocalizedStr(@"取消") style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:CJPayLocalizedStr(@"去设置") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            // 调用AppJump敏感方法，需走BPEA鉴权
            [CJPayPrivacyMethodUtil applicationOpenUrl:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                            withPolicy:@"bpea-caijing_jsb_media_available_goto_setting"
                                         bridgeCommand:nil
                                               options:@{}
                                     completionHandler:^(BOOL success, NSError * _Nullable error) {
                if (error) {
                    CJPayLogError(@"error in bpea-caijing_jsb_media_available_goto_setting");
                }
            }];
        }];
        [requestAuthAlert addAction:cancelAction];
        [requestAuthAlert addAction:confirmAction];
        [controller presentViewController:requestAuthAlert animated:YES completion:nil];
        CJ_CALL_BLOCK(self.failBlock, @"-2");
        return;
    }
}

#pragma mark PHPickerController delegate
//选择图片完成(从相册完成)，将照片保存到本地应用tmp目录
- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results  API_AVAILABLE(ios(14)){
    [picker  dismissViewControllerAnimated:YES completion:nil];
    if (!Check_ValidArray(results)) {
        CJ_CALL_BLOCK(self.failBlock, @"-1");
        return;
    }
    
    for (PHPickerResult *result in results) {
        [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(__kindof id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error) {
            if ([object isKindOfClass:[UIImage class]]) {
                CJ_CALL_BLOCK(self.chooseImageCompletionBlock, object);
            } else {
                CJPayLogInfo(@"选择的图片不是 UIImage");
            }
        }];
    }
}

#pragma mark UIImagePickerController delegate
//选择图片完成(从相册或者拍照完成)，将照片保存到本地应用tmp目录
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(nonnull NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker  dismissViewControllerAnimated:YES completion:nil];
    NSString *mediaType = [info valueForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage] && [[info objectForKey:UIImagePickerControllerOriginalImage] isKindOfClass:[UIImage class]]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        CJ_CALL_BLOCK(self.chooseImageCompletionBlock, image);
    } else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
            NSData *videoData = [NSData dataWithContentsOfURL:url];
            CGFloat size = [videoData length] / KB;
            //文件小于要求压缩大小or不要求压缩，则直接上传视频本体
            if (self.compressSize > size || self.compressSize == 0) {
                CJPayLogError(@"视频不压缩 compressSize = %@, url = %@, size = %@", @(self.compressSize), url.absoluteString, @(size));
                CJ_CALL_BLOCK(self.chooseVideoCompletionBlock, [url path]);
            } else {
                [self p_processVideoCompressWithUrl:url];
            }
        });
    } else {
        CJ_CALL_BLOCK(self.failBlock, @"2");
    }
}

//取消选择照片(拍照)
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
    CJ_CALL_BLOCK(self.failBlock, @"-1");
}

#pragma mark video compress
- (void)p_processVideoCompressWithUrl:(NSURL *)url {
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    session.shouldOptimizeForNetworkUse = YES;
    
    NSString *outputURL = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ocrPhoto"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL existed = [fileManager fileExistsAtPath:outputURL isDirectory:&isDir];
    if (!(isDir && existed)) {
        [fileManager createDirectoryAtPath:outputURL withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *filename = [NSString stringWithFormat:@"%@.mp4", [NSString stringWithFormat:@"%.0lf", [[NSDate date] timeIntervalSince1970]]];
    outputURL = [outputURL stringByAppendingPathComponent:filename];
    session.outputURL = [NSURL fileURLWithPath:outputURL];
    session.outputFileType = AVFileTypeMPEG4;
    [session exportAsynchronouslyWithCompletionHandler:^{
        AVAssetExportSessionStatus sessionStatus = session.status;
        switch (sessionStatus) {
            case AVAssetExportSessionStatusFailed:
                CJPayLogError(@"视频压缩失败 url = %@, error = %@", url.absoluteString, session.error);
                CJ_CALL_BLOCK(self.failBlock, @"1");
                break;
            case AVAssetExportSessionStatusCompleted:
            {
                CJ_CALL_BLOCK(self.chooseVideoCompletionBlock, outputURL);
                NSData *videoData = [NSData dataWithContentsOfURL:session.outputURL];
                CGFloat size = [videoData length] / KB;
                CJPayLogError(@"视频压缩成功 url = %@, size = %@", url.absoluteString, @(size));
            }
                break;
            default:
                CJPayLogError(@"视频压缩失败 url = %@, error = %@", url.absoluteString, session.error);
                CJ_CALL_BLOCK(self.failBlock, @"1");
                break;
        }
    }];
}


#pragma mark lazy init
- (NSMutableDictionary *)md52PathMap {
    if (!_md52PathMap) {
        _md52PathMap = [NSMutableDictionary new];
    }
    return _md52PathMap;
}

@end
