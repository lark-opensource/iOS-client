//
//  CAKPhotoManager.m
//  CameraClient
//
//  Created by lixingdong on 2020/7/8.
//

#import "CAKPhotoManager.h"
#import <BDWebImage/UIImage+BDImageTransform.h>
#import <CommonCrypto/CommonDigest.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/UIImage+ACCAdditions.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreationKitInfra/ACCPathUtils.h>
#import "CAKAlbumAssetCache.h"

static CGFloat const kACCPictureMaxValue1080 = 1080;
static CGFloat const kACCPictureMaxValue1920 = 1920;

NSString * const kCAKFetchedAssetsCountKey_IMG     = @"kCAKFetchedAssetsCountKey_IMG";
NSString * const kCAKFetchedAssetsCountKey_Video   = @"kCAKFetchedAssetsCountKey_Video";

static BOOL _enableAlbumLoadOpt = NO;

#define kAWEPhotoManagerChunkSize (8 * 1024)

static NSURL *p_outputURLForPHAsset(PHAsset *asset) {
    NSString *tempDir = ACCTemporaryDirectory();
    tempDir = [tempDir stringByAppendingPathComponent:@"PHAssetImage"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:tempDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *fileName = [NSString stringWithFormat:@"tmpImage_%@.jpg", @([asset hash])];
    tempDir = [tempDir stringByAppendingPathComponent:fileName];
    return [NSURL fileURLWithPath:tempDir];
}

@interface CAKPhotoManager ()

@property (nonatomic, assign, class) BOOL enableAlbumLoadOpt;

@end

@implementation CAKPhotoManager

#pragma mark - authorization

//获取权限状态
+ (AWEAuthorizationStatus)authorizationStatus
{
    if (@available(iOS 14.0, *)) {
        return (AWEAuthorizationStatus)[PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
    } else {
        return (AWEAuthorizationStatus)[PHPhotoLibrary authorizationStatus];
    }
}

//异步获取权限状态
+ (void)authorizationStatusWithCompletion:(void (^)(AWEAuthorizationStatus status))completion
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        AWEAuthorizationStatus currentStatus = [CAKPhotoManager authorizationStatus];
        dispatch_async(dispatch_get_main_queue(), ^{
            ACCBLOCK_INVOKE(completion, currentStatus);
        });
    });
}

//主动请求权限
+ (void)requestAuthorizationWithCompletionOnMainQueue:(void(^)(AWEAuthorizationStatus status))handler
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (@available(iOS 14.0, *)) {
            [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus status) {
                AWEAuthorizationStatus aweStatus = (AWEAuthorizationStatus)status;
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(aweStatus);
                });
            }];
        } else {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                AWEAuthorizationStatus aweStatus = (AWEAuthorizationStatus)status;
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(aweStatus);
                });
            }];
        }
    });
}

+ (void)requestAuthorizationWithActionBlock:(void (^)(void))actionBlock denyBlock:(void (^)(void))denyBlock allowLimited:(BOOL)allowLimited
{
    AWEAuthorizationStatus status = [self authorizationStatus];
    if (status == AWEAuthorizationStatusAuthorized || (allowLimited && ([self isiOS14PhotoLimited] || [self isiOS14PhotoNotDetermined]))) {
        ACCBLOCK_INVOKE(actionBlock);
        return;
    }
    
    if (status == AWEAuthorizationStatusDenied || status == AWEAuthorizationStatusRestricted || [self isiOS14PhotoLimited]) {
        ACCBLOCK_INVOKE(denyBlock);
        return;
    }
    
    if (status == AWEAuthorizationStatusNotDetermined) {
        [CAKPhotoManager requestAuthorizationWithCompletionOnMainQueue:^(AWEAuthorizationStatus status) {
            if (@available(iOS 14.0, *)) {
                if (allowLimited && status == AWEAuthorizationStatusLimited) {
                    ACCBLOCK_INVOKE(actionBlock);
                    return;
                }
            }
            
            if (status == AWEAuthorizationStatusAuthorized) {
                ACCBLOCK_INVOKE(actionBlock);
            } else {
                ACCBLOCK_INVOKE(denyBlock);
            }
        }];
    }
}

#pragma mark - 获取所有图片或视频
//fetchavasset
+ (void)fetchImageAsset:(CAKAlbumAssetModel *)assetModel completion:(void (^)(CAKAlbumAssetModel *model, NSError *error))completion
{
    PHAsset *sourceAsset = assetModel.phAsset;
    CGSize imageSize = CGSizeMake(720, 1280);
    if ([UIDevice acc_isBetterThanIPhone7]) {
        imageSize = CGSizeMake(1080, 1920);
    }
    
    __block NSError *returnError = nil;
    [CAKPhotoManager getUIImageWithPHAsset:sourceAsset
                                 imageSize:imageSize
                      networkAccessAllowed:YES
                           progressHandler:^(CGFloat progress, NSError *error, BOOL *stop, NSDictionary *info) {
        returnError = error;
    }
                                completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        if (isDegraded) {
            return;
        }
        
        if (photo) {
            NSURL *imageURL = p_outputURLForPHAsset(sourceAsset);
            NSData *imageData = UIImageJPEGRepresentation(photo, 1.0f);
            if (imageData && imageURL) {
                if ([imageData acc_writeToURL:imageURL atomically:YES]) {
                    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"IESPhoto" ofType:@"bundle"];
                    NSString *backVideoPath = [bundlePath stringByAppendingPathComponent:@"blankown2.mp4"];
                    AVURLAsset *placeholderAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:backVideoPath] options:@{ AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
                    UIImage *thumbImage = photo;
                    if (thumbImage.size.width > 0 && thumbImage.size.height > 0) {
                        const CGFloat screenScale = [UIScreen mainScreen].scale;
                        CGSize thumbImageSize = CGSizeMake(48.0f * screenScale, 56.0f * screenScale);
                        thumbImage = [thumbImage bd_imageByResizeToSize:thumbImageSize contentMode:UIViewContentModeScaleAspectFill];
                    }
                    placeholderAsset.frameImageURL = imageURL;
                    placeholderAsset.thumbImage = thumbImage;
                    assetModel.avAsset = placeholderAsset;

                    ACCBLOCK_INVOKE(completion, assetModel, nil);
                    return;
                } else {
                    AWELogToolInfo(AWELogToolTagImport, @"write: imageData write to imageURL failed.");
                }
            }
        }
        
        //fetch failed
        ACCBLOCK_INVOKE(completion, assetModel, returnError);
    }];
}

+ (void)fetchVideoAsset:(CAKAlbumAssetModel *)assetModel completion:(void (^)(CAKAlbumAssetModel *model, BOOL isICloud))completion
{
    PHAsset *sourceAsset = assetModel.phAsset;
    NSURL *url = [sourceAsset valueForKey:@"ALAssetURL"];
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    if (@available(iOS 14.0, *)) {
        options.version = PHVideoRequestOptionsVersionCurrent;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[PHImageManager defaultManager] requestAVAssetForVideo:sourceAsset
                                                        options:options
                                                  resultHandler:^(AVAsset *_Nullable blockAsset, AVAudioMix *_Nullable audioMix, NSDictionary *_Nullable info) {
            acc_dispatch_main_async_safe(^{
                BOOL isICloud = [info[PHImageResultIsInCloudKey] boolValue];
                assetModel.isFromICloud = isICloud;
                
                if (isICloud && !blockAsset) {
                    ACCBLOCK_INVOKE(completion, nil, YES);
                } else if(blockAsset) {
                    assetModel.avAsset = blockAsset;
                    if (ACCSYSTEM_VERSION_LESS_THAN(@"9") && assetModel.mediaSubType == CAKAlbumAssetModelMediaSubTypeVideoHighFrameRate) {
                        AVURLAsset *urlAsset = [AVURLAsset assetWithURL:url];
                        if (urlAsset) {
                            assetModel.avAsset = urlAsset;
                        }
                    }
                    assetModel.info = info;
                    
                    AWELogToolInfo(AWELogToolTagImport, @"AIClip: [export] block asset is not nil, info: %@", info);
                    ACCBLOCK_INVOKE(completion, assetModel, NO);
                } else {
                    //fetch failed
                    
                    if (info != nil) {
                        AWELogToolInfo(AWELogToolTagImport, @"export: AIClip:info: %@", info);
                    } else {
                        AWELogToolInfo(AWELogToolTagImport, @"export: AIClip:info is nil");
                    }
                    
                    ACCBLOCK_INVOKE(completion, nil, NO);
                }
            });
        }];
    });
}

+ (void)requestAVAssetFromiCloudWithModel:(CAKAlbumAssetModel *)assetModel
                                      idx:(NSUInteger)index
                                 videoArr:(NSMutableArray<CAKAlbumAssetModel *> *)videoArray
                          assetModelArray:(NSArray<CAKAlbumAssetModel *> *)assetModelArray
                               completion:(void (^)(CAKAlbumAssetModel *fetchedAsset, NSMutableArray<CAKAlbumAssetModel *> *assetArray))completion
{
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.networkAccessAllowed = YES;

    //run animation ahead
    assetModel.didFailFetchingiCloudAsset = NO;
    assetModel.iCloudSyncProgress = 0.f;
    assetModel.canUnobserveAssetModel = NO;
    
    options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        acc_dispatch_main_async_safe(^{
            if (assetModel) {
                assetModel.iCloudSyncProgress = progress;
            }
        });
    };
    if (@available(iOS 14.0, *)) {
        options.version = PHVideoRequestOptionsVersionCurrent;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    }

    PHAsset *sourceAsset = assetModel.phAsset;
    NSURL *url = [sourceAsset valueForKey:@"ALAssetURL"];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[PHImageManager defaultManager] requestAVAssetForVideo:sourceAsset
                                                        options:options
                                                  resultHandler:^(AVAsset *_Nullable asset, AVAudioMix *_Nullable audioMix,
                                                                  NSDictionary *_Nullable info) {
                                                      acc_dispatch_main_async_safe(^{
                                                          if (asset) {
                                                              assetModel.avAsset = asset;
                                                              if (ACCSYSTEM_VERSION_LESS_THAN(@"9") && assetModel.mediaSubType == CAKAlbumAssetModelMediaSubTypeVideoHighFrameRate) {
                                                                  AVURLAsset *urlAsset = [AVURLAsset assetWithURL:url];
                                                                  if (urlAsset) {
                                                                      assetModel.avAsset = urlAsset;
                                                                  }
                                                              }
                                                              
                                                              assetModel.info = info;
                                                              if ([videoArray count] > index && assetModel) {
                                                                  [videoArray replaceObjectAtIndex:index withObject:assetModel];
                                                              }
                                                              
                                                              for (id item in videoArray) {
                                                                  if ([item isKindOfClass:[NSNumber class]]) {
                                                                      return;
                                                                  }
                                                              }
                                                              
                                                              if ([assetModelArray count]) {
                                                                  acc_dispatch_main_async_safe(^{
                                                                      ACCBLOCK_INVOKE(completion, assetModel, videoArray);
                                                                  });
                                                              }
                                                            
                                                              assetModel.canUnobserveAssetModel = YES;
                                                              assetModel.iCloudSyncProgress = 1.f;
                                                          } else {
                                                              //没有获取到照片
                                                              assetModel.didFailFetchingiCloudAsset = YES;
                                                              assetModel.iCloudSyncProgress = 0.f;
                                                              if (info != nil) {
                                                                  AWELogToolInfo(AWELogToolTagImport, @"import: [export] info: %@", info);
                                                              } else {
                                                                  AWELogToolInfo(AWELogToolTagImport, @"import: [export] info is nil");
                                                              }
                                                          }
                                                      });
                                                  }];
    });
}

+ (void)getAVAssetsWithAssets:(NSArray<CAKAlbumAssetModel *> *)assets completion:(void (^)(NSArray<CAKAlbumAssetModel *> *))completion
{
    NSMutableArray *fetchedAssets = [NSMutableArray array];
    
    for (NSInteger i = 0; i < assets.count; i++) {
        [fetchedAssets addObject:@1];
    }
    
    for (NSInteger i = 0; i < assets.count; i++) {
        CAKAlbumAssetModel *assetModel = [[assets acc_objectAtIndex:i] copy];

        PHAsset *sourceAsset = assetModel.phAsset;
        const PHAssetMediaType mediaType = sourceAsset.mediaType;
        
        @weakify(self);
        if (PHAssetMediaTypeImage == mediaType) {
            CGSize imageSize = CGSizeMake(720, 1280);
            if ([UIDevice acc_isBetterThanIPhone7]) {
                imageSize = CGSizeMake(1080, 1920);
            }
            
            
            
            [self.class fetchImageAsset:assetModel completion:^(CAKAlbumAssetModel *model, NSError *error) {
                [fetchedAssets replaceObjectAtIndex:i withObject:assetModel];
                for (id item in fetchedAssets) {
                    if ([item isKindOfClass:[NSNumber class]]) {
                        return;
                    }
                }
            
                ACCBLOCK_INVOKE(completion, fetchedAssets);
            }];
        } else if (PHAssetMediaTypeVideo == mediaType) {
            [self.class fetchVideoAsset:assetModel completion:^(CAKAlbumAssetModel *model, BOOL isICloud) {
                @strongify(self);
                if (!model && isICloud) {
                    [self.class requestAVAssetFromiCloudWithModel:assetModel idx:i videoArr:fetchedAssets assetModelArray:assets completion:^(CAKAlbumAssetModel *fetchedAsset, NSMutableArray<CAKAlbumAssetModel *> *assetArray) {
                        ACCBLOCK_INVOKE(completion, assetArray);
                    }];
                    return;
                }
                
                [fetchedAssets replaceObjectAtIndex:i withObject:assetModel];
                for (id item in fetchedAssets) {
                    if ([item isKindOfClass:[NSNumber class]]) {
                        return;
                    }
                }
                
                ACCBLOCK_INVOKE(completion, fetchedAssets);
            }];
        }
    }
}

+ (void)getAVAssetWithPHAsset:(PHAsset *)phAsset options:(PHVideoRequestOptions *)options completion:(void (^)(AVAsset * _Nullable, AVAudioMix * _Nullable, NSDictionary * _Nullable))completion
{
    [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:options resultHandler:completion];
}

+ (void)getAssetsWithAlbum:(CAKAlbumModel *)album
                      type:(AWEGetResourceType)type
               filterBlock:(BOOL (^) (PHAsset *))filterBlock
                completion:(void (^) (NSArray<CAKAlbumAssetModel *> *, PHFetchResult *))completion
{
    PHAssetMediaType mediaType = PHAssetMediaTypeImage;
    switch (type) {
        case AWEGetResourceTypeImage:
            mediaType = PHAssetMediaTypeImage;
            break;
        case AWEGetResourceTypeVideo:
            mediaType = PHAssetMediaTypeVideo;
            break;
        default:
            break;
    }
    AWELogToolInfo(AWELogToolTagImport, @"import: mediaType:%ld fetchResult:%@",(long)mediaType, album.result);
    [self getAssetsFromFetchResult:album.result filterBlock:filterBlock completion:completion];
}

#pragma mark - get latest asset

+ (void)getLatestAssetWithType:(AWEGetResourceType)type
                    completion:(void (^) (CAKAlbumAssetModel *latestAssetModel))completion
{
    [self getLatestAssetCount:1
                         type:type
                   completion:^(NSArray<CAKAlbumAssetModel *> *latestAssets) {
        ACCBLOCK_INVOKE(completion, latestAssets.firstObject);
    }];
}

+ (void)getLatestAssetCount:(NSUInteger)latestCount
                       type:(AWEGetResourceType)type
                 completion:(void (^) (NSArray<CAKAlbumAssetModel *> *latestAssets))completion
{
    [self getLatestAssetCount:latestCount
                    sortStyle:CAKAlbumAssetSortStyleDefault
                         type:type
                   completion:completion];
}

+ (void)getLatestAssetCount:(NSUInteger)latestCount
                  sortStyle:(CAKAlbumAssetSortStyle)sortStyle
                       type:(AWEGetResourceType)type
                 completion:(void (^) (NSArray<CAKAlbumAssetModel *> *latestAssets))completion
{
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    PHAssetMediaType mediaType = PHAssetMediaTypeImage;
    switch (type) {
        case AWEGetResourceTypeImage:
            mediaType = PHAssetMediaTypeImage;
            break;
        case AWEGetResourceTypeVideo:
            mediaType = PHAssetMediaTypeVideo;
            break;
        default:
            break;
    }
    
    NSString *sortDateStyle = @"creationDate";
    NSArray<NSSortDescriptor *> *sortDescriptor = @[
    [NSSortDescriptor sortDescriptorWithKey:sortDateStyle ascending:NO]
    ];
    fetchOptions.sortDescriptors = sortDescriptor;
    
    fetchOptions.fetchLimit = latestCount;
    fetchOptions.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary | PHAssetSourceTypeiTunesSynced;
    PHFetchResult<PHAsset *> *result;
    if (self.enableAlbumLoadOpt) {
        result = [PHAsset fetchAssetsWithOptions:fetchOptions];
    } else {
        if (type == AWEGetResourceTypeImageAndVideo) {
            fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld || mediaType == %ld", PHAssetMediaTypeImage, PHAssetMediaTypeVideo];
            result = [PHAsset fetchAssetsWithOptions:fetchOptions];
        } else {
            result = [PHAsset fetchAssetsWithMediaType:mediaType options:fetchOptions];
        }
    }
    AWELogToolInfo(AWELogToolTagImport, @"AWELogToolTagImport: fetchAssetsWithMediaType:%ld fetchResult count:%ld",(long)mediaType, (long)[result count]);
    if (result.count > 0) {
        [self getAssetsFromFetchResult:result filterBlock:^BOOL(PHAsset *asset) {
            return YES;
        } completion:^(NSArray<CAKAlbumAssetModel *> *assetModelArray, PHFetchResult *result) {
            ACCBLOCK_INVOKE(completion, assetModelArray);
        }];
    } else {
       [self p_getCameraRollAlbumWithType:type completion:^(CAKAlbumModel *model) {
            if (model && [model.result count]) {
                [self getAssetsFromFetchResult:model.result filterBlock:^BOOL(PHAsset * phAsset) {
                    return YES;
                } completion:^(NSArray<CAKAlbumAssetModel *> *assetModelArray, PHFetchResult *result) {
                    ACCBLOCK_INVOKE(completion, assetModelArray);
                }];
            } else {
                [self p_fetchAssetsWithType:type filterBlock:^BOOL(PHAsset *phAsset) {
                    return YES;
                } completion:^(NSArray<CAKAlbumAssetModel *> *assetModelArray, PHFetchResult *result) {
                    ACCBLOCK_INVOKE(completion, assetModelArray);
                }];
            }
        }];
    }
}

#pragma mark -

+ (void)getAssetsWithType:(AWEGetResourceType)type
              filterBlock:(BOOL (^) (PHAsset *phAsset))filterBlock
               completion:(void (^) (NSArray<CAKAlbumAssetModel *> *assetModelArray, PHFetchResult *result))completion;
{
    [self getAssetsWithType:type filterBlock:filterBlock ascending:YES completion:completion];
}

+ (void)getAssetsWithType:(AWEGetResourceType)type
              filterBlock:(BOOL (^) (PHAsset *))filterBlock
                ascending:(BOOL)ascending
               completion:(void (^)(NSArray<CAKAlbumAssetModel *> *, PHFetchResult *))completion
{
    [self getAssetsWithType:type filterBlock:filterBlock sortStyle:CAKAlbumAssetSortStyleDefault ascending:ascending completion:completion];
}

+ (void)getAssetsWithType:(AWEGetResourceType)type
              filterBlock:(BOOL (^) (PHAsset *))filterBlock
                sortStyle:(CAKAlbumAssetSortStyle)sortStyle
                ascending:(BOOL)ascending
               completion:(void (^)(NSArray<CAKAlbumAssetModel *> *, PHFetchResult *))completion
{
    [self p_getAssetsWithType:type filterBlock:filterBlock sortStyle:sortStyle ascending:ascending completion:^(NSArray<CAKAlbumAssetModel *> *assetModelArray, PHFetchResult *result) {
        ACCBLOCK_INVOKE(completion,assetModelArray,result);
        [self p_cacheFetchCountWithResult:assetModelArray type:type];
    }];
}

+ (void)getAllAssetsWithType:(AWEGetResourceType)type
                   ascending:(BOOL)ascending
                  completion:(void (^)(PHFetchResult *))completion
{
    [self p_getAllAssetsWithType:type sortStyle:CAKAlbumAssetSortStyleDefault ascending:ascending completion:^(PHFetchResult *result) {
        ACCBLOCK_INVOKE(completion, result);
        [self p_cacheFetchCountWithFetchResult:result type:type];
    }];
}

+ (void)getAllAssetsWithType:(AWEGetResourceType)type
                   sortStyle:(CAKAlbumAssetSortStyle)sortStyle
                   ascending:(BOOL)ascending
                  completion:(void (^)(PHFetchResult *))completion
{
    [self p_getAllAssetsWithType:type sortStyle:sortStyle ascending:ascending completion:^(PHFetchResult *result) {
        ACCBLOCK_INVOKE(completion, result);
        [self p_cacheFetchCountWithFetchResult:result type:type];
    }];
}

+ (void)getAllAssetsAndResultWithType:(AWEGetResourceType)type
                            sortStyle:(CAKAlbumAssetSortStyle)sortStyle
                            ascending:(BOOL)ascending
                           completion:(void (^) (NSArray<CAKAlbumAssetModel *> *assetModelArray, PHFetchResult *result))completion
{
    PHFetchResult<PHAsset *> *result = [self p_fetchPHAssetsResultWithType:type sortStyle:sortStyle ascending:ascending];
    if (result.count > 0) {
        NSMutableArray<CAKAlbumAssetModel *> *photoArr = [NSMutableArray arrayWithCapacity:result.count];
        [result enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CAKAlbumAssetModel *model = [self p_assetModelWithPHAsset:obj];
            if (model) {
                [photoArr acc_addObject:model];
            }
        }];
        ACCBLOCK_INVOKE(completion, photoArr, result);
        AWELogToolInfo(AWELogToolTagImport, @"AWELogToolTagImport: CAKAlbumAssetModel count:%lu", (unsigned long)result.count);
    } else {
        [self p_getCameraRollAlbumWithType:type completion:^(CAKAlbumModel *model) {
            if (model && [model.result count]) {
                [self getAssetsFromFetchResult:model.result filterBlock:nil completion:completion];
            } else {
                [self p_fetchAssetsWithType:type filterBlock:nil completion:completion];
            }
        }];
    }
}

#pragma mark - 相册获取
//获取相册列表-选相薄用
+ (void)getAllAlbumsForMVWithType:(AWEGetResourceType)type
                       completion:(void (^)(NSArray<CAKAlbumModel *> *))completion
{
    [self p_getAllAlbumsForMVWithType:type completion:^(NSArray<CAKAlbumModel *> *arr) {
        ACCBLOCK_INVOKE(completion,arr);
    }];
}

+ (void)getAllAlbumsWithType:(AWEGetResourceType)type
                  completion:(void (^)(NSArray<CAKAlbumModel *> *))completion
{
    [self getAllAlbumsWithType:type ascending:YES assetAscending:YES completion:completion];
}

+ (void)getAllAlbumsWithType:(AWEGetResourceType)type
                   ascending:(BOOL)ascending
              assetAscending:(BOOL)assetAscending
                  completion:(void (^)(NSArray<CAKAlbumModel *> *))completion
{
    [self p_getAllAlbumsWithType:type ascending:ascending assetAscending:assetAscending completion:^(NSArray<CAKAlbumModel *> *arr) {
        ACCBLOCK_INVOKE(completion,arr);
    }];
}

+ (void)getAssetsWithIdentifiers:(NSArray<NSString *> *)identifiers
                      completion:(void (^) (NSArray<CAKAlbumAssetModel *> *))completion
{
    if (!identifiers.count) {
        ACCBLOCK_INVOKE(completion, nil);
    }
    PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:identifiers options:nil];
    [self getAssetsFromFetchResult:result filterBlock:nil completion:^(NSArray<CAKAlbumAssetModel *> *assetModelArray, PHFetchResult *result) {
        ACCBLOCK_INVOKE(completion, assetModelArray);
    }];
}

#pragma mark - asset获取

+ (PHFetchResult *)getAssetsFromCollection:(PHAssetCollection *)collection withType:(AWEGetResourceType)type ascending:(BOOL)ascending {
    return [self getAssetsFromCollection:collection
                               sortStyle:CAKAlbumAssetSortStyleDefault
                                withType:type
                               ascending:ascending];;
}

+ (PHFetchResult *)getAssetsFromCollection:(PHAssetCollection *)collection
                                 sortStyle:(CAKAlbumAssetSortStyle)sortStyle
                                  withType:(AWEGetResourceType)type
                                 ascending:(BOOL)ascending {
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    PHAssetMediaType mediaType = PHAssetMediaTypeUnknown;
    switch (type) {
        case AWEGetResourceTypeImage:
            mediaType = PHAssetMediaTypeImage;
            break;
        case AWEGetResourceTypeVideo:
            mediaType = PHAssetMediaTypeVideo;
            break;
        default:
            break;
    }

    
    if (sortStyle != CAKAlbumAssetSortStyleRecent) {
        NSString *sortDateStyle = @"creationDate";
        NSArray<NSSortDescriptor *> *sortDescriptor = @[
            [NSSortDescriptor sortDescriptorWithKey:sortDateStyle ascending:ascending]
        ];
        fetchOptions.sortDescriptors = sortDescriptor;
    }
    
    if (mediaType != PHAssetMediaTypeUnknown) {
        fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", mediaType];
    }

    return [PHAsset fetchAssetsInAssetCollection:collection options:fetchOptions];
}

+ (void)getAssetsFromFetchResult:(PHFetchResult *)result
                     filterBlock:(BOOL (^) (PHAsset *))filterBlock
                      completion:(void (^)(NSArray<CAKAlbumAssetModel *> *assetModelArray, PHFetchResult *result))completion
{
    NSMutableArray *photoArr = [NSMutableArray array];
    [result enumerateObjectsUsingBlock:^(PHAsset *phAsset, NSUInteger idx, BOOL * _Nonnull stop) {
        CAKAlbumAssetModel *model = [self p_assetModelWithPHAsset:phAsset];
        if (model) {
            if (filterBlock) {
                if (filterBlock(model.phAsset)) {
                    [photoArr acc_addObject:model];
                }
            } else {
                [photoArr acc_addObject:model];
            }
        }
    }];
    AWELogToolInfo(AWELogToolTagImport, @"AWELogToolTagImport: CAKAlbumAssetModel count:%lu", (unsigned long)photoArr.count);
    ACCBLOCK_INVOKE(completion, photoArr, result);
}

//获取一组图片的字节数
+ (void)getPhotosBytesWithArray:(NSArray<CAKAlbumAssetModel *> *)photos completion:(void (^)(NSString *totalBytes))completion
{
    if (!photos || !photos.count) {
        if (completion) completion(@"0B");
        return;
    }
    __block NSInteger dataLength = 0;
    __block NSInteger assetCount = 0;
    for (NSInteger i = 0; i < photos.count; i++) {
        CAKAlbumAssetModel *model = photos[i];
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[PHImageManager defaultManager] requestImageDataForAsset:model.phAsset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (model.mediaType != CAKAlbumAssetModelMediaTypeVideo) {
                        dataLength += imageData.length;
                    }
                    assetCount ++;
                    if (assetCount >= photos.count) {
                        NSString *bytes = [self p_getBytesFromDataLength:dataLength];
                        ACCBLOCK_INVOKE(completion,bytes);
                    } else {
                        ACCBLOCK_INVOKE(completion,@"0B");
                    }
                });
            }];
        });
    }
}

#pragma mark - 获取UIImage

//图片尺寸根据asset计算
+ (int32_t)getUIImageWithPHAsset:(PHAsset *)asset
            networkAccessAllowed:(BOOL)networkAccessAllowed
                 progressHandler:(void (^)(CGFloat progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler
                      completion:(void (^)(UIImage *photo, NSDictionary *info, BOOL isDegraded))completion
{
    PHAsset *phAsset = asset;
    CGFloat aspectRatio = (CGFloat)phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
    CGFloat photoWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat pixelWidth = photoWidth * 2 * 1.5;
    //图片较宽
    if (aspectRatio > 1.8) {
        pixelWidth = pixelWidth * aspectRatio;
    }
    CGFloat pixelHeight = pixelWidth / aspectRatio;
    CGSize imageSize = CGSizeMake(pixelWidth, pixelHeight);
    return [self getUIImageWithPHAsset:asset imageSize:imageSize networkAccessAllowed:networkAccessAllowed progressHandler:progressHandler completion:completion];
}

+ (int32_t)getUIImageWithPHAsset:(PHAsset *)asset
                       imageSize:(CGSize)imageSize
            networkAccessAllowed:(BOOL)networkAccessAllowed
                 progressHandler:(void (^)(CGFloat progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler
                      completion:(void (^)(UIImage *photo, NSDictionary *info, BOOL isDegraded))completion
{
    return
    [self getUIImageWithPHAsset:asset
                      imageSize:imageSize
                    contentMode:PHImageContentModeAspectFill
           networkAccessAllowed:networkAccessAllowed
                progressHandler:progressHandler
                     completion:completion];
}

+ (int32_t)getUIImageWithPHAsset:(PHAsset *)asset
                       imageSize:(CGSize)imageSize
                     contentMode:(PHImageContentMode)contentMode
            networkAccessAllowed:(BOOL)networkAccessAllowed
                 progressHandler:(void (^)(CGFloat progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler
                      completion:(void (^)(UIImage *photo, NSDictionary *info, BOOL isDegraded))completion
{
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    // Need to check
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    if (@available(iOS 14.0, *)) {
        option.version = PHImageRequestOptionsVersionCurrent;
    }
    
    int32_t requestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:contentMode options:option resultHandler:^(UIImage *result, NSDictionary *info) {
        if ([info objectForKey:PHImageResultIsInCloudKey] && !result && networkAccessAllowed) {
            [self getUIImageFromICloudWithPHAsset:asset imageSize:imageSize progressHandler:progressHandler completion:completion];
            return;
        }
        
        BOOL noError = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
        if (noError) {
            if (result) {
                result = [UIImage acc_fixImgOrientation:result];
            }
            ACCBLOCK_INVOKE(completion, result, info, [[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        } else {
            AWELogToolInfo(AWELogToolTagImport, @"AWELogToolTagImport: get photo error: %@", info);
            ACCBLOCK_INVOKE(completion, nil, info, [info[PHImageResultIsDegradedKey] boolValue]);
        }
    }];
    return requestID;
}

+ (int32_t)getUIImageWithPHAsset:(PHAsset *)asset
                      targetSize:(CGSize)targetSize
                     contentMode:(PHImageContentMode)contentMode
                         options:(nullable PHImageRequestOptions *)options
                   resultHandler:(void (^)(UIImage *_Nullable result, NSDictionary *_Nullable info))resultHandler {
    return [[PHImageManager defaultManager] requestImageForAsset:asset
                                                      targetSize:targetSize
                                                     contentMode:contentMode
                                                         options:options
                                                   resultHandler:resultHandler];
}

+ (void)getPhotoDataFromICloudWithAsset:(PHAsset *)asset progressHandler:(void (^)(CGFloat, NSError *, BOOL *, NSDictionary *))progressHandler completion:(void (^)(NSData *, NSDictionary *))completion
{
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progressHandler) {
                progressHandler(progress, error, stop, info);
            }
        });
    };
    option.networkAccessAllowed = YES;
    if (@available(iOS 14.0, *)) {
        option.version = PHImageRequestOptionsVersionCurrent;
    }
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(imageData, info);
                }
            });
        }];
    });
}

+ (void)getUIImageFromICloudWithPHAsset:(PHAsset *)asset progressHandler:(void (^)(CGFloat, NSError *, BOOL *, NSDictionary *))progressHandler completion:(void (^)(UIImage *, NSDictionary *, BOOL))completion
{
    PHAsset *phAsset = asset;
    CGFloat aspectRatio = (CGFloat)phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
    CGFloat photoWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat pixelWidth = photoWidth * 2 * 1.5;
    //图片较宽
    if (aspectRatio > 1.8) {
        pixelWidth = pixelWidth * aspectRatio;
    }
    CGFloat pixelHeight = pixelWidth / aspectRatio;
    CGSize imageSize = CGSizeMake(pixelWidth, pixelHeight);
    [self getUIImageFromICloudWithPHAsset:asset imageSize:imageSize progressHandler:progressHandler completion:completion];
}

+ (void)getUIImageFromICloudWithPHAsset:(PHAsset *)asset
                              imageSize:(CGSize)imageSize
                        progressHandler:(void (^)(CGFloat progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler
                             completion:(void (^)(UIImage *photo, NSDictionary *info, BOOL isDegraded))completion
{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    if (@available(iOS 14.0, *)) {
        options.version = PHImageRequestOptionsVersionCurrent;
    }
    options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progressHandler) {
                progressHandler(progress, error, stop, info);
            }
        });
    };
    options.networkAccessAllowed = YES;
    // Need to check
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (imageData) {
                    UIImage *resultImage = [UIImage imageWithData:imageData];
                    resultImage = [UIImage acc_fixImgOrientation:resultImage];
                    resultImage = [UIImage acc_tryCompressImage:resultImage ifImageSizeLargeTargetSize:imageSize];
                    if (completion) {
                        completion(resultImage, info, NO);
                    }
                } else {
                    if (completion) {
                        completion(nil, info, NO);
                    }
                }
            });
        }];
    });
}

+ (void)getPhotoDataWithAsset:(PHAsset *)asset version:(PHImageRequestOptionsVersion)version completion:(void (^)(NSData *data, NSDictionary *info, BOOL isInCloud))completion
{
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.version = version;
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (imageData) {
                    if (completion) completion(imageData, info, NO);
                } else {
                    //图片在iCloud上
                    if ([info objectForKey:PHImageResultIsInCloudKey]) {
                        if (completion) completion(nil, info, YES);
                    } else {
                        if (completion) completion(nil, info, NO);
                    }
                }
            });
        }];
    });
}

+ (void)getOriginalPhotoDataWithAsset:(PHAsset *)asset completion:(void (^)(NSData *data, NSDictionary *info, BOOL isInCloud))completion
{
    [self getPhotoDataWithAsset:asset version:PHImageRequestOptionsVersionOriginal completion:completion];
}

+ (void)getOriginalPhotoDataFromICloudWithAsset:(PHAsset *)asset
                                progressHandler:(void (^)(CGFloat progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler
                                     completion:(void (^)(NSData *data, NSDictionary *info))completion
{
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progressHandler) {
                progressHandler(progress, error, stop, info);
            }
        });
    };
    option.networkAccessAllowed = YES;
    option.version = PHImageRequestOptionsVersionOriginal;
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(imageData, info);
                }
            });
        }];
    });
}

+ (void)getURLFromAVAsset:(AVAsset *)avAsset completion:(void (^)(NSURL *))completion
{
    if (!avAsset) {
        ACCBLOCK_INVOKE(completion, nil);
        return;
    }
    
    if ([avAsset isKindOfClass:[AVURLAsset class]]) {
        AVURLAsset *urlAsset = (AVURLAsset *)avAsset;
        ACCBLOCK_INVOKE(completion, urlAsset.URL);
        return;
    }
    
    AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:avAsset presetName:AVAssetExportPresetHighestQuality];
    NSInteger randNumber = arc4random();
    NSString *exportPath = [NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"%ldvideo.mov", randNumber]];
    NSURL *exportURL = [NSURL fileURLWithPath:exportPath];
    if (exporter) {
        exporter.outputURL = exportURL;
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        exporter.shouldOptimizeForNetworkUse = YES;
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (exporter.status == AVAssetExportSessionStatusCompleted) {
                    NSURL *url = exporter.outputURL;
                    ACCBLOCK_INVOKE(completion, url);
                } else {
                    ACCBLOCK_INVOKE(completion, nil);
                }
            });
        }];
    } else {
        ACCBLOCK_INVOKE(completion, nil);
    }
}

+ (void)cancelImageRequest:(int32_t)requestID
{
    [[PHImageManager defaultManager] cancelImageRequest:requestID];
}

+ (CAKAlbumAssetModel *)assetModelWithPHAsset:(PHAsset *)asset
{
    return [self p_assetModelWithPHAsset:asset];
}

#pragma mark - process

+ (UIImage *)processImageTo1080P:(UIImage *)sourceImage
{
    UIImage *ret = [UIImage acc_fixImgOrientation:sourceImage];
    
    if (ret.size.width > ret.size.height) {
        //图片宽的
        if (ret.size.width <= kACCPictureMaxValue1920 && ret.size.height <= kACCPictureMaxValue1080) {
            
        } else {
            CGRect rect = AVMakeRectWithAspectRatioInsideRect(ret.size, CGRectMake(0, 0, kACCPictureMaxValue1920,  kACCPictureMaxValue1080));
            CGFloat finalImageWidth = rect.size.width;
            CGFloat finalImageHeight = rect.size.height;
            ret = [UIImage acc_compressImage:ret withTargetSize:CGSizeMake(finalImageWidth, finalImageHeight)];
        }
    } else {
        //图片是高的
        if (ret.size.height <= kACCPictureMaxValue1920 && ret.size.width <= kACCPictureMaxValue1080) {
            
        } else {
            CGRect rect = AVMakeRectWithAspectRatioInsideRect(ret.size, CGRectMake(0, 0, kACCPictureMaxValue1080, kACCPictureMaxValue1920));
            CGFloat finalImageWidth = rect.size.width;
            CGFloat finalImageHeight = rect.size.height;
            ret = [UIImage acc_compressImage:ret withTargetSize:CGSizeMake(finalImageWidth, finalImageHeight)];
        }
    }
    return ret;
}

+ (CGSize)sizeFor1080P:(PHAsset *)phAsset
{
    CGSize size = CGSizeMake(phAsset.pixelWidth, phAsset.pixelHeight);
    
    if (phAsset.pixelWidth > phAsset.pixelHeight) {
        //图片宽的
        if (phAsset.pixelWidth <= kACCPictureMaxValue1920 && phAsset.pixelHeight <= kACCPictureMaxValue1080) {
            
        } else {
            CGRect rect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(phAsset.pixelWidth, phAsset.pixelHeight), CGRectMake(0, 0, kACCPictureMaxValue1920,  kACCPictureMaxValue1080));
            CGFloat finalImageWidth = rect.size.width;
            CGFloat finalImageHeight = rect.size.height;
            size = CGSizeMake(finalImageWidth, finalImageHeight);
        }
    } else {
        //图片是高的
        if (phAsset.pixelHeight <= kACCPictureMaxValue1920 && phAsset.pixelWidth <= kACCPictureMaxValue1080) {
            
        } else {
            CGRect rect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(phAsset.pixelWidth, phAsset.pixelHeight), CGRectMake(0, 0, kACCPictureMaxValue1080, kACCPictureMaxValue1920));
            CGFloat finalImageWidth = rect.size.width;
            CGFloat finalImageHeight = rect.size.height;
            size = CGSizeMake(finalImageWidth, finalImageHeight);
        }
    }
    return size;
}

+ (UIImage *)processImageWithBlackEdgeWithOutputSize:(CGSize)outputSize sourceImage:(UIImage *)sourceImage
{
    UIGraphicsBeginImageContextWithOptions(outputSize, YES, 1);
    [sourceImage bd_drawInRect:CGRectMake(0, 0, outputSize.width, outputSize.height) withContentMode:UIViewContentModeScaleAspectFit clipsToBounds:YES];
    UIImage *processedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (processedImage == nil) {
        processedImage = sourceImage;
    }
    return processedImage;
}

#pragma mark - md5

+ (NSURL *_Nullable)privateVideoURLWithInfo:(NSDictionary *)info
{
    NSArray *videoArray = [info allValues];
    NSString *videoPath = nil;
    for (NSString *string in videoArray) {
        if ([string isKindOfClass:[NSString class]] && [string containsString:@"private"]) {
            NSRange range = [string rangeOfString:@"private"];
            NSInteger index = range.length + range.location;
            videoPath = [string substringFromIndex:index];
        }
    }
    NSURL *videoURL = nil;
    if (videoPath.length && [videoPath containsString:@"DCIM"]) {
        videoURL = [NSURL fileURLWithPath:videoPath];
    }
    return videoURL;
}

//kAWEPhotoManagerChunkSize (8 * 1024)
//usedBytes必须是kAWEPhotoManagerChunkSize的整数倍//512 * 1024
+ (NSString *_Nullable)getMD5withPath:(NSString *)filePath usedBytes:(NSInteger)usedBytes
{
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if (handle == nil) {
        return nil;
    }
    
    CC_MD5_CTX md5Calculater;
    CC_MD5_Init(&md5Calculater);
    
    BOOL done = NO;
    NSInteger sum = 0;
    while (!done) {
        @autoreleasepool {
            NSData *fileData = [handle readDataOfLength:kAWEPhotoManagerChunkSize];
            CC_MD5_Update(&md5Calculater, [fileData bytes], (CC_LONG)[fileData length]);
            sum += [fileData length];
            if (sum >= usedBytes) {
                break;
            }
            if ([fileData length] == 0) {
                done = YES;
            }
        }
    }
    
    unsigned char md5Value[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(md5Value, &md5Calculater);
    
    char md5Array[2 * sizeof(md5Value) + 1];
    for (size_t i = 0; i < CC_MD5_DIGEST_LENGTH; ++i) {
        snprintf(md5Array + (2 * i), 3, "%02x", (int) (md5Value[i]));
    }
    [handle closeFile];
    
    NSString *MD5Str = [NSString stringWithFormat:@"%s", md5Array];
    return MD5Str;
}

+ (NSString *)timeStringWithDuration:(NSTimeInterval)duration
{
    NSInteger seconds = (NSInteger)round(duration);
    NSInteger second = seconds % 60;
    NSInteger minute = seconds / 60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minute, (long)second];
}

#pragma mark - private methods

+ (BOOL)p_isCameraRollAlbum:(PHAssetCollection *)collection
{
    NSString *versionStr = [[UIDevice currentDevice].systemVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    if (versionStr.length <= 1) {
        versionStr = [versionStr stringByAppendingString:@"00"];
    } else if (versionStr.length <= 2) {
        versionStr = [versionStr stringByAppendingString:@"0"];
    }
    CGFloat version = versionStr.floatValue;
    // 目前已知8.0.0 ~ 8.0.2系统，拍照后的图片会保存在最近添加中
    if (version >= 800 && version <= 802) {
        return collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumRecentlyAdded;
    } else {
        return collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary;
    }
}

+ (BOOL)p_isRecentlyDeleteAlbum:(PHAssetCollection *)collection
{
    return collection.assetCollectionSubtype == 1000000201;
}

+ (BOOL)p_isHiddenAlbum:(PHAssetCollection *)collection
{
    return collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden;

}

+ (CAKAlbumModel *)p_modelWithResult:(PHFetchResult *)result name:(NSString *)name isCameraRoll:(BOOL)isCameraRoll assetAscending:(BOOL)assetAscending
{
    return [self p_modelWithResult:result collection:nil name:name isCameraRoll:isCameraRoll assetAscending:assetAscending resouceType:AWEGetResourceTypeImageAndVideo];
}

+ (CAKAlbumModel *)p_modelWithResult:(PHFetchResult *)result collection:(PHAssetCollection *)collection name:(NSString *)name isCameraRoll:(BOOL)isCameraRoll assetAscending:(BOOL)assetAscending resouceType:(AWEGetResourceType)resouceType
{
    CAKAlbumModel *model = [[CAKAlbumModel alloc] init];
    model.result = result;
    model.assetCollection = collection;
    model.name = name;
    model.isCameraRoll = isCameraRoll;
    model.count = result.count;
    model.lastUpdateDate = [(assetAscending ? [result lastObject] :[result firstObject]) creationDate];
    model.resultKey = [CAKAlbumAssetCacheKey keyWithAscending:assetAscending type:resouceType localizedTitle:name];
    return model;
}

+ (CAKAlbumAssetModel *)p_assetModelWithPHAsset:(PHAsset *)asset
{
    if (![asset isKindOfClass:[PHAsset class]]) {
        return nil;
    }
    
    CAKAlbumAssetModel *model = [[CAKAlbumAssetModel alloc] init];
    model.mediaType = CAKAlbumAssetModelMediaTypeUnknow;
    model.mediaSubType = CAKAlbumAssetModelMediaSubTypeUnknow;
    switch (asset.mediaType) {
        case PHAssetMediaTypeVideo:
            model.mediaType = CAKAlbumAssetModelMediaTypeVideo;
            if (asset.mediaSubtypes == PHAssetMediaSubtypeVideoHighFrameRate) {
                model.mediaSubType = CAKAlbumAssetModelMediaSubTypeVideoHighFrameRate;
            }
            break;
        case PHAssetMediaTypeAudio:
            model.mediaType = CAKAlbumAssetModelMediaTypeAudio;
            break;
        case PHAssetMediaTypeImage: {
            model.mediaType = CAKAlbumAssetModelMediaTypePhoto;
            if (@available(iOS 9.1, *)) {
                if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
                    model.mediaSubType = CAKAlbumAssetModelMediaSubTypePhotoLive;
                }
                break;
            }
            if ([[asset valueForKey:@"filename"] hasSuffix:@"GIF"]) {
                model.mediaSubType = CAKAlbumAssetModelMediaSubTypePhotoGif;
            }
        }
            break;
        default:
            break;
    }

    model.selectedNum = nil;
    model.phAsset = asset;
    if (model.mediaType == CAKAlbumAssetModelMediaTypeVideo) {
        model.videoDuration = [self timeStringWithDuration:asset.duration];
    }
    return model;
}

+ (NSString *)p_getBytesFromDataLength:(NSInteger)dataLength
{
    NSString *bytes;
    if (dataLength >= 0.1 * (1024 * 1024)) {
        bytes = [NSString stringWithFormat:@"%0.1fM",dataLength/1024/1024.0];
    } else if (dataLength >= 1024) {
        bytes = [NSString stringWithFormat:@"%0.0fK",dataLength/1024.0];
    } else {
        bytes = [NSString stringWithFormat:@"%@",@(dataLength)];
    }
    return bytes;
}

+ (void)p_getAssetsWithType:(AWEGetResourceType)type
                filterBlock:(BOOL (^) (PHAsset *))filterBlock
                  sortStyle:(CAKAlbumAssetSortStyle)sortStyle
                  ascending:(BOOL)ascending
                 completion:(void (^)(NSArray<CAKAlbumAssetModel *> *, PHFetchResult *))completion
{
    PHFetchResult<PHAsset *> *result = [self p_fetchPHAssetsResultWithType:type sortStyle:sortStyle ascending:ascending];
    if (result.count > 0) {
        [self getAssetsFromFetchResult:result filterBlock:filterBlock completion:completion];
    } else {
        [self p_getCameraRollAlbumWithType:type completion:^(CAKAlbumModel *model) {
            if (model && [model.result count]) {
                [self getAssetsFromFetchResult:model.result filterBlock:filterBlock completion:completion];
            } else {
                [self p_fetchAssetsWithType:type filterBlock:filterBlock completion:completion];
            }
        }];
    }
}

+ (void)p_getAllAssetsWithType:(AWEGetResourceType)type
                     sortStyle:(CAKAlbumAssetSortStyle)sortStyle
                     ascending:(BOOL)ascending
                    completion:(void (^)(PHFetchResult *))completion
{
    PHFetchResult<PHAsset *> *result = [self p_fetchPHAssetsResultWithType:type
                                                                 sortStyle:sortStyle ascending:ascending];
    if (result.count > 0) {
        ACCBLOCK_INVOKE(completion, result);
    } else {
        [self p_getCameraRollAlbumWithType:type completion:^(CAKAlbumModel *model) {
            if (model && [model.result count]) {
                ACCBLOCK_INVOKE(completion, result);
            } else {
                [self p_fetchAssetsWithType:type filterBlock:nil completion:^(NSArray<CAKAlbumAssetModel *> *assetModelArr, PHFetchResult *result) {
                    ACCBLOCK_INVOKE(completion, result);
                }];
            }
        }];
    }
}

//new solution for fixing album assets fetch empty bug
+ (void)p_fetchAssetsWithType:(AWEGetResourceType)mediaType
                  filterBlock:(BOOL (^) (PHAsset *phAsset))filterBlock
                   completion:(void (^)(NSArray<CAKAlbumAssetModel *> *, PHFetchResult *))completion
{
    NSMutableArray *otherAlbumsAssetArray = [NSMutableArray array];//album assets except default album
    NSMutableArray *userLibraryAssetArray = [NSMutableArray array];//default album assets
    NSMutableDictionary *userLibraryIdentifiersDic = [NSMutableDictionary dictionary];//default album identifiers
    
    //fetch assets from all albums
    PHFetchResult *myPhotoStreamAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    PHFetchResult *syncedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
    PHFetchResult *sharedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumCloudShared options:nil];
    
    NSMutableArray *allAlbums = [NSMutableArray array];
    [allAlbums acc_addObject:myPhotoStreamAlbum];
    [allAlbums acc_addObject:topLevelUserCollections];
    [allAlbums acc_addObject:syncedAlbums];
    [allAlbums acc_addObject:sharedAlbums];
    [allAlbums acc_addObject:smartAlbums];
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    switch (mediaType) {
        case AWEGetResourceTypeImage:
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
            break;
        case AWEGetResourceTypeVideo:
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeVideo];
            break;
        default:
            break;
    }
    
    NSTimeInterval startFetch = CFAbsoluteTimeGetCurrent();
    PHFetchResult<PHAsset *> *defaultFetchResult;
    for (PHFetchResult *fetchResult in allAlbums) {
        for (PHAssetCollection *collection in fetchResult) {
            if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
            if (collection.estimatedAssetCount <= 0 && ![self p_isCameraRollAlbum:collection]) continue;
            if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden) continue;
            if ([self p_isRecentlyDeleteAlbum:collection] || [self p_isHiddenAlbum:collection]) continue;
            
            PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            if (assets.count) {
                if ([self p_isCameraRollAlbum:collection]) {//default album
                    defaultFetchResult = assets;
                    for (PHAsset *ass in assets) {
                        if ([ass.localIdentifier length]) {
                            if (filterBlock) {
                                if (filterBlock(ass)) {
                                    [userLibraryAssetArray acc_addObject:[self p_assetModelWithPHAsset:ass]];
                                }
                            } else {
                                [userLibraryAssetArray acc_addObject:[self p_assetModelWithPHAsset:ass]];
                            }
                        }
                    }
                } else {//other albums
                    for (PHAsset *ass in assets) {
                        if ([ass.localIdentifier length]) {
                            if (filterBlock) {
                                if (filterBlock(ass)) {
                                    [otherAlbumsAssetArray acc_addObject:[self p_assetModelWithPHAsset:ass]];
                                }
                            } else {
                                [otherAlbumsAssetArray acc_addObject:[self p_assetModelWithPHAsset:ass]];
                            }
                        }
                    }
                }
            }
        }
    }
    AWELogToolInfo(AWELogToolTagImport, @"AWELogToolTagImport: fetch assets total time %.2f type:%ld",fabs(CFAbsoluteTimeGetCurrent() - startFetch),(long)mediaType);
    
    //filter duplicate asstes in different albums
    NSMutableArray *finalArray = [NSMutableArray array];
    if ([userLibraryAssetArray count]) {
        [finalArray addObjectsFromArray:userLibraryAssetArray];
        
        //filter logic
        [userLibraryIdentifiersDic removeAllObjects];
        [userLibraryAssetArray enumerateObjectsUsingBlock:^(CAKAlbumAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.phAsset.localIdentifier length]) {
                userLibraryIdentifiersDic[obj.phAsset.localIdentifier] = obj.phAsset.localIdentifier;
            }
        }];
        
        [otherAlbumsAssetArray enumerateObjectsUsingBlock:^(CAKAlbumAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.phAsset.localIdentifier length]) {
                if (!userLibraryIdentifiersDic[obj.phAsset.localIdentifier]) {
                    [finalArray acc_addObject:obj];
                }
            }
        }];
    } else {
        [finalArray addObjectsFromArray:otherAlbumsAssetArray];
    }
    
    //remove tmp for memory
    [allAlbums removeAllObjects];
    [otherAlbumsAssetArray removeAllObjects];
    [userLibraryAssetArray removeAllObjects];
    [userLibraryIdentifiersDic removeAllObjects];
    
    AWELogToolInfo(AWELogToolTagImport, @"AWELogToolTagImport: mediaType:%ld fetchResult count:%ld",(long)mediaType, (long)[finalArray count]);
    //finally callback
    dispatch_async(dispatch_get_main_queue(), ^{
        ACCBLOCK_INVOKE(completion,finalArray,defaultFetchResult);
    });
}


+ (void)p_getAllAlbumsForMVWithType:(AWEGetResourceType)type
                         completion:(void (^)(NSArray<CAKAlbumModel *> *))completion
{
    NSMutableArray *albumArr = [NSMutableArray array];
    
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    switch (type) {
        case AWEGetResourceTypeImage:
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %@", @(PHAssetMediaTypeImage)];
            break;
        case AWEGetResourceTypeVideo:
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %@", @(PHAssetMediaTypeVideo)];
            break;
        case AWEGetResourceTypeImageAndVideo:
            if (!_enableAlbumLoadOpt) {
                option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %@ || mediaType == %@", @(PHAssetMediaTypeImage), @(PHAssetMediaTypeVideo)];
            }
            break;
    }
    
    PHFetchResult *myPhotoStreamAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    PHFetchResult *syncedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
    PHFetchResult *sharedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumCloudShared options:nil];
    NSArray *allAlbums = @[myPhotoStreamAlbum,smartAlbums,topLevelUserCollections,syncedAlbums,sharedAlbums];
    
    for (PHFetchResult *fetchResult in allAlbums) {
        for (PHAssetCollection *collection in fetchResult) {
            if (![collection isKindOfClass:[PHAssetCollection class]]) {
                continue;
            }
            
            if (collection.estimatedAssetCount <= 0 && ![self p_isCameraRollAlbum:collection]) {
                continue;
            }
            
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            if (fetchResult.count < 1 && ![self p_isCameraRollAlbum:collection]) {
                continue;
            }
            
            if ([self p_isRecentlyDeleteAlbum:collection]) {
                continue;
            }
            
            if ([self p_isHiddenAlbum:collection]) {
                continue;
            }
            
            if ([self p_isCameraRollAlbum:collection]) {
                CAKAlbumModel *albumModel = [self p_modelWithResult:fetchResult collection:collection name:collection.localizedTitle isCameraRoll:YES assetAscending:YES resouceType:type];
                albumModel.localIdentifier = collection.localIdentifier;
                [albumArr acc_insertObject:albumModel atIndex:0];
            } else {
                CAKAlbumModel *albumModel = [self p_modelWithResult:fetchResult collection:collection name:collection.localizedTitle isCameraRoll:NO assetAscending:YES resouceType:type];
                albumModel.localIdentifier = collection.localIdentifier;
                [albumArr acc_addObject:albumModel];
            }
        }
    }
    
    ACCBLOCK_INVOKE(completion, albumArr);
}

+ (PHAssetCollection *)getCamraRoolAssetCollection
{
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in smartAlbums) {
        if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
        if ([self p_isCameraRollAlbum:collection]) {
            return collection;
        }
    }
    return nil;
}

//获取相机胶卷
+ (void)p_getCameraRollAlbumWithType:(AWEGetResourceType)type completion:(void (^)(CAKAlbumModel *model))completion
{
    __block CAKAlbumModel *model = nil;
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    switch (type) {
        case AWEGetResourceTypeImage:
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %@", @(PHAssetMediaTypeImage)];
            break;
        case AWEGetResourceTypeVideo:
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %@", @(PHAssetMediaTypeVideo)];
            break;
        case AWEGetResourceTypeImageAndVideo:
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %@ || mediaType == %@", @(PHAssetMediaTypeImage), @(PHAssetMediaTypeVideo)];
            break;
    }
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in smartAlbums) {
        if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
        if (collection.estimatedAssetCount <= 0) continue;
        if ([self p_isCameraRollAlbum:collection]) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            model = [self p_modelWithResult:fetchResult name:collection.localizedTitle isCameraRoll:YES assetAscending:YES];
            model.localIdentifier = collection.localIdentifier;
            break;
        }
    }
    AWELogToolInfo(AWELogToolTagImport, @"AWELogToolTagImport: mediaType:%ld fetchResult count:%ld",(long)type, (long)[model.result count]);
    ACCBLOCK_INVOKE(completion,model);
}

+ (void)p_getAllAlbumsWithType:(AWEGetResourceType)type
                     ascending:(BOOL)ascending
                assetAscending:(BOOL)assetAscending
                    completion:(void (^)(NSArray<CAKAlbumModel *> *))completion
{
    NSMutableArray *albumArr = [NSMutableArray array];
    NSMutableArray *sortedAlbumArr = [NSMutableArray array];
    
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    switch (type) {
        case AWEGetResourceTypeImage:
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %@", @(PHAssetMediaTypeImage)];
            break;
        case AWEGetResourceTypeVideo:
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %@", @(PHAssetMediaTypeVideo)];
            break;
        case AWEGetResourceTypeImageAndVideo:
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %@ || mediaType == %@", @(PHAssetMediaTypeImage), @(PHAssetMediaTypeVideo)];
            break;
    }
    NSArray<NSSortDescriptor *> *sortDescriptor = @[
                                                    [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(creationDate)) ascending:assetAscending]
                                                    ];
    option.sortDescriptors = sortDescriptor;
    
    PHFetchResult *myPhotoStreamAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    PHFetchResult *syncedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
    PHFetchResult *sharedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumCloudShared options:nil];
    NSArray *allAlbums = @[myPhotoStreamAlbum,smartAlbums,topLevelUserCollections,syncedAlbums,sharedAlbums];
    for (PHFetchResult *fetchResult in allAlbums) {
        for (PHAssetCollection *collection in fetchResult) {
            if (![collection isKindOfClass:[PHAssetCollection class]] || [self p_isRecentlyDeleteAlbum:collection]) continue;
            if ([self p_isHiddenAlbum:collection]) continue;
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            if ([self p_isCameraRollAlbum:collection]) {
                CAKAlbumModel *albumModel = [self p_modelWithResult:fetchResult name:collection.localizedTitle isCameraRoll:YES assetAscending:assetAscending];
                albumModel.localIdentifier = collection.localIdentifier;
                [sortedAlbumArr acc_addObject:albumModel];
            } else {
                CAKAlbumModel *albumModel = [self p_modelWithResult:fetchResult name:collection.localizedTitle isCameraRoll:NO assetAscending:assetAscending];
                [albumArr acc_addObject:albumModel];
                albumModel.localIdentifier = collection.localIdentifier;
            }
        }
    }
    
    NSMutableArray *hasLastUpdateDateAlbum = [[albumArr acc_filter:(^(CAKAlbumModel *album){
        return (BOOL)(album.lastUpdateDate != nil);
    })] mutableCopy];
    
    [hasLastUpdateDateAlbum sortUsingComparator:^NSComparisonResult(CAKAlbumModel *album1, CAKAlbumModel *album2) {
        if (ascending) {
            return [album1.lastUpdateDate compare:album2.lastUpdateDate];
        } else {
            return [album2.lastUpdateDate compare:album1.lastUpdateDate];
        }
    }];
    
    [hasLastUpdateDateAlbum addObjectsFromArray:[albumArr acc_filter:(^(CAKAlbumModel *album){
        return (BOOL)(album.lastUpdateDate == nil);
    })]];
    
    [sortedAlbumArr addObjectsFromArray:[hasLastUpdateDateAlbum copy]];
    ACCBLOCK_INVOKE(completion, sortedAlbumArr);
}

+ (void)p_cacheFetchCountWithResult:(NSArray<CAKAlbumAssetModel *> *)assetModelArray type:(AWEGetResourceType)type
{
    NSString *storageKey = type == AWEGetResourceTypeImage ? kCAKFetchedAssetsCountKey_IMG : kCAKFetchedAssetsCountKey_Video;
    NSNumber *lastTimeCached = ACCDynamicCast([[NSUserDefaults standardUserDefaults] objectForKey:storageKey], NSNumber);
    BOOL shouldCache = YES;
    if (lastTimeCached && (!assetModelArray.count || lastTimeCached.integerValue == assetModelArray.count)) {
        shouldCache = NO;
    }
   
    if (shouldCache) {
        [[NSUserDefaults standardUserDefaults] setObject:@([assetModelArray count]) forKey:storageKey];
    }
}

+ (void)p_cacheFetchCountWithFetchResult:(PHFetchResult *)result type:(AWEGetResourceType)type
{
    NSString *storageKey = type == AWEGetResourceTypeImage ? kCAKFetchedAssetsCountKey_IMG : kCAKFetchedAssetsCountKey_Video;
    NSNumber *lastTimeCached = ACCDynamicCast([[NSUserDefaults standardUserDefaults] objectForKey:storageKey], NSNumber);
    BOOL shouldCache = YES;
    if (lastTimeCached && (!result.count || lastTimeCached.integerValue == result.count)) {
        shouldCache = NO;
    }
    if (shouldCache) {
        [[NSUserDefaults standardUserDefaults] setObject:@([result count]) forKey:storageKey];
    }
}

//ACCDeviceAuth

+ (BOOL)isiOS14PhotoNotDetermined
{
#ifdef __IPHONE_14_0 //xcode12
    if (@available(iOS 14.0, *)) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
        return status == PHAuthorizationStatusNotDetermined;
    }
#endif
    return NO;
}

+ (BOOL)isiOS14PhotoLimited
{
#ifdef __IPHONE_14_0 //xcode12
    if (@available(iOS 14.0, *)) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
        return status == PHAuthorizationStatusLimited;
    }
#endif
    return NO;
}

+ (void)setEnableAlbumLoadOpt:(BOOL)enableAlbumLoadOpt {
    _enableAlbumLoadOpt = enableAlbumLoadOpt;
}

+ (BOOL)enableAlbumLoadOpt {
    return _enableAlbumLoadOpt;
}

+ (PHFetchResult<PHAsset *> *)p_fetchPHAssetsResultWithType:(AWEGetResourceType)type
                                                  sortStyle:(CAKAlbumAssetSortStyle)sortStyle
                                                  ascending:(BOOL)ascending
{
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    PHAssetMediaType mediaType = PHAssetMediaTypeImage;
    switch (type) {
        case AWEGetResourceTypeImage:
            mediaType = PHAssetMediaTypeImage;
            break;
        case AWEGetResourceTypeVideo:
            mediaType = PHAssetMediaTypeVideo;
            break;
        default:
            break;
    }
    
    
    if (sortStyle != CAKAlbumAssetSortStyleRecent) {
        NSString *sortDateStyle = @"creationDate";
        NSArray<NSSortDescriptor *> *sortDescriptor = @[
            [NSSortDescriptor sortDescriptorWithKey:sortDateStyle ascending:ascending]
        ];
        fetchOptions.sortDescriptors = sortDescriptor;
    }

    fetchOptions.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary | PHAssetSourceTypeiTunesSynced;
    PHFetchResult<PHAsset *> *result;
    if (type == AWEGetResourceTypeImageAndVideo) {
        if (self.enableAlbumLoadOpt) {
            result = [PHAsset fetchAssetsWithOptions:fetchOptions];
        } else {
            fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld || mediaType == %ld", PHAssetMediaTypeImage, PHAssetMediaTypeVideo];
            result = [PHAsset fetchAssetsWithOptions:fetchOptions];
        }
    } else {
        result = [PHAsset fetchAssetsWithMediaType:mediaType options:fetchOptions];
    }
    AWELogToolInfo(AWELogToolTagImport, @"AWELogToolTagImport: fetchAssetsWithMediaType:%ld fetchResult count:%ld",(long)mediaType, (long)[result count]);
    return result;
}

@end
