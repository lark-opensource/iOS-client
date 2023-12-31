//
//  BDUGAlbumImageAnalysts.m
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/19.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import "BDUGAlbumImageAnalysts.h"
#import <Photos/Photos.h>
#import "BDUGAlbumImageCacheManager.h"
#import "BDUGShareEvent.h"
#import "BDUGShareSettingsUtil.h"

//每次读取的图片数量
static NSInteger const kDefaultMaxReadImageCount = 5;

@interface BDUGAlbumImageAnalysts ()

@property (nonatomic, strong) BDUGAlbumImageCacheManager *cacheManager;

@property (nonatomic, assign) BOOL analysisActivated;

@property(nonatomic, strong) dispatch_queue_t imageReaderQueue;

@end

@implementation BDUGAlbumImageAnalysts

+ (instancetype)sharedManager {
    static BDUGAlbumImageAnalysts *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[BDUGAlbumImageAnalysts alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _analysisActivated = NO;
        _maxReadImageCount = kDefaultMaxReadImageCount;
    }
    return self;
}

- (void)activateAlbumImageAnalystsWithPermissionAlert:(BOOL)permission
                                     notificationName:(NSString *)notificationName
{
    [[BDUGShareSettingsUtil sharedInstance] settingsWithKey:kBDUGShareSettingsKeyAlbumParse handler:^(BOOL settingStatus) {
        if (settingStatus) {
            [self performAlbumImageAnalystsWithPermissionAlert:permission notificationName:notificationName];
        } else {
            [BDUGLogger logMessage:@"相册解析setting关闭" withLevType:BDUGLoggerInfoType];
        }
    }];
}

- (void)performAlbumImageAnalystsWithPermissionAlert:(BOOL)permission
                                    notificationName:(NSString *)notificationName
{
    if (self.analysisActivated) {
        //只激活一次。
        return;
    }
    self.analysisActivated = YES;
    //如果业务方允许弹出alert，则弹窗。
    PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
    [BDUGShareEventManager event:kShareAuthorizeRequest params:@{
        @"had_authorize" : (authStatus == PHAuthorizationStatusAuthorized ? @(1) : @(0)),
    }];
    switch (authStatus) {
        case PHAuthorizationStatusNotDetermined: {
            if (permission) {
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *showSuccess = @"cancel";
                        if (status == PHAuthorizationStatusAuthorized) {
                            [self addNotificationWithNotificationName:notificationName];
                            showSuccess = @"submit";
                        }
                        [BDUGShareEventManager event:kShareAuthorizeClick params:@{
                                                                        @"is_first_request" : @"yes",
                                                                        @"click_result" : showSuccess,
                                                                        }];
                    });
                }];
                [BDUGShareEventManager event:kShareAuthorizeShow params:@{
                    @"is_first_request" : @"yes",
                }];
            }
        }
        case PHAuthorizationStatusRestricted:
        case PHAuthorizationStatusDenied: {
            //do nothing
        }
            break;
        case PHAuthorizationStatusAuthorized: {
            [self addNotificationWithNotificationName:notificationName];
        }
            break;
        default:
            break;
    }
}

- (void)addNotificationWithNotificationName:(NSString *)notificationName
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *notiName = notificationName;
        if (notiName.length == 0) {
            notiName = UIApplicationWillEnterForegroundNotification;
        }
        //监听应用进入前台。
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForeground) name:notiName object:nil];
        [self appEnterForeground];
    });
}

- (void)appEnterForeground {
    if (self.imageShouldAnalysisBlock && !self.imageShouldAnalysisBlock()) {
        //实现了should回调并且返回了no，则不进行口令识别。
        return ;
    }
    PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
    if (authStatus == PHAuthorizationStatusAuthorized) {
        [self asyncReadImageFromAlbum];
    } else {
        //没权限，不返回了直接。
    }
    [BDUGShareEventManager event:kShareAuthorizeRequest params:@{
        @"had_authorize" : (authStatus == PHAuthorizationStatusAuthorized ? @(1) : @(0)),
    }];
}

- (void)asyncReadImageFromAlbum
{
    dispatch_async(self.imageReaderQueue, ^{
        if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
            //再次校验相册权限，增加容错。
            return ;
        }
        //读相册，
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        PHFetchResult *allPhotos = [PHAsset fetchAssetsWithOptions:options];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleImageResult:allPhotos];
        });
    });
}

- (void)handleImageResult:(PHFetchResult *)allPhotos
{
    if (![NSThread isMainThread]) {
        NSAssert(0, @"这里预期是在主线程");
        return;
    }
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.resizeMode = PHImageRequestOptionsResizeModeNone;
    // 同步获得图片, 只会返回1张图片
    requestOptions.synchronous = YES;
    NSInteger imageCount = MIN(self.maxReadImageCount, allPhotos.count);
    PHImageManager *imageManager = [PHImageManager defaultManager];
    
    __block BOOL hasReadMark = NO;
    for (NSInteger i = 0; i < imageCount; i++) {
        if (hasReadMark) {
            break;
        }
        PHAsset *asset = [allPhotos objectAtIndex:i];
        
        //内部有对NSMutableArray的数组读操作，需要放在主线程。
        BDUGAlbumImageCacheStatus status = [self.cacheManager cacheStatusWithLocalIdentifier:asset.localIdentifier];
        if (status == BDUGAlbumImageCacheStatusHitValid) {
            //缓存命中，且有有效信息，直接结束图片读取。
            break;
        } else if (status == BDUGAlbumImageCacheStatusHitExit) {
            //缓存命中，但是没有有效信息，继续遍历。
            continue;
        } else if (status == BDUGAlbumImageCacheStatusMiss) {
            //接着往下走。
        }
        
        dispatch_async(self.imageReaderQueue, ^{
            [imageManager requestImageDataForAsset:asset options:requestOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                if (hasReadMark || !imageData) {
                    return ;
                }
                dispatch_async(self.imageReaderQueue, ^{
                    UIImage *image;
                    @try {
                        image = [UIImage imageWithData:imageData];
                    } @catch (NSException *exception) {
                        image = nil;
                    }
                    if (!image) {
                        return;
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //todo:kBDUGShareSettingsKeyHiddenmarkParse 这个可以加在register阶段。
                        [self parseImage:image useDelegate:self.imageHiddenMarkDelegate settingsKey:kBDUGShareSettingsKeyHiddenmarkParse hasReadMark:&hasReadMark completion:^(BOOL succeed) {
                            if (!succeed) {
                                [self parseImage:image useDelegate:self.imageQRCodeDelegate settingsKey:kBDUGShareSettingsKeyQRCodeParse hasReadMark:&hasReadMark completion:^(BOOL succeed) {
                                    if (succeed) {
                                        hasReadMark = YES;
                                    }
                                    [self.cacheManager addCacheWithLocalIdentifier:asset.localIdentifier infoValid:succeed];
                                }];
                            } else {
                                hasReadMark = YES;
                                [self.cacheManager addCacheWithLocalIdentifier:asset.localIdentifier infoValid:succeed];
                            }
                        }];
                    });
                });
            }];
        });
    }
}

- (void)parseImage:(UIImage *)image useDelegate:(id <BDUGAlbumImageAnalystsDelegate>)delegate settingsKey:(NSString *)settingsKey hasReadMark:(BOOL *)hasReadMark completion:(void(^)(BOOL succeed))completion
{
    //使用delegate解析image
    [self delegateAvailable:delegate settingsKey:settingsKey completion:^(BOOL succeed) {
        if (succeed) {
            [delegate analysisShareInfo:image hasReadMark:hasReadMark completion:^(BOOL analysisSucceed) {
                !completion ?: completion(analysisSucceed);
            }];
        } else {
            !completion ?: completion(NO);
        }
    }];
}

- (void)delegateAvailable:(id <BDUGAlbumImageAnalystsDelegate>)delegate settingsKey:(NSString *)settingsKey completion:(void(^)(BOOL succeed))completion
{
    //判断delegate是否可用
    BOOL deleagteSetted = delegate && [delegate respondsToSelector:@selector(analysisShareInfo:hasReadMark:completion:)];
    [[BDUGShareSettingsUtil sharedInstance] settingsWithKey:settingsKey handler:^(BOOL settingStatus) {
        !completion ?: completion(deleagteSetted && settingStatus);
    }];
}

#pragma mark - image cache

- (void)markAlbumImageIdentifier:(NSString *)imageIdentifier valid:(BOOL)valid
{
    [self.cacheManager addCacheWithLocalIdentifier:imageIdentifier infoValid:valid];
}

+ (void)cleanCache {
    [[BDUGAlbumImageAnalysts sharedManager].cacheManager cleanCache];
}

#pragma mark - set

- (void)setMaxReadImageCount:(NSInteger)maxReadImageCount {
    _maxReadImageCount = maxReadImageCount;
    //不触发懒加载
    _cacheManager.cacheLength = maxReadImageCount;
}

#pragma mark - get

- (BDUGAlbumImageCacheManager *)cacheManager
{
    if (!_cacheManager) {
        _cacheManager = [[BDUGAlbumImageCacheManager alloc] init];
        _cacheManager.cacheLength = self.maxReadImageCount;
    }
    return _cacheManager;
}

- (dispatch_queue_t)imageReaderQueue
{
    if (!_imageReaderQueue) {
        //串行读取队列。
        _imageReaderQueue = dispatch_queue_create("com.bdug.dispatch.queue.imagereader", DISPATCH_QUEUE_SERIAL);
    }
    return _imageReaderQueue;
}

@end
