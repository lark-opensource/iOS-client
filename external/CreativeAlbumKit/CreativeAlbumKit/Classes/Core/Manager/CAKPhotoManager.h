//
//  CAKPhotoManager.h
//  CameraClient
//
//  Created by lixingdong on 2020/7/8.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "CAKAlbumAssetModel.h"

typedef NS_ENUM(NSUInteger, AWEAuthorizationStatus) {
    AWEAuthorizationStatusNotDetermined = PHAuthorizationStatusNotDetermined,
    AWEAuthorizationStatusRestricted = PHAuthorizationStatusRestricted,
    AWEAuthorizationStatusDenied = PHAuthorizationStatusDenied,
    AWEAuthorizationStatusAuthorized = PHAuthorizationStatusAuthorized,
    AWEAuthorizationStatusLimited API_AVAILABLE(ios(14)) = PHAuthorizationStatusLimited,
};

typedef NS_ENUM(NSUInteger, AWEGetResourceType) {
    AWEGetResourceTypeImage,
    AWEGetResourceTypeVideo,
    AWEGetResourceTypeImageAndVideo,
};

typedef NS_ENUM(NSInteger, CAKAlbumAssetSortStyle) {
    CAKAlbumAssetSortStyleDefault = 0,//sort by create date
    CAKAlbumAssetSortStyleRecent = 1,//sort by recent
};

FOUNDATION_EXPORT NSString * _Nonnull const kCAKFetchedAssetsCountKey_IMG;
FOUNDATION_EXPORT NSString * _Nonnull const kCAKFetchedAssetsCountKey_Video;

@interface CAKPhotoManager : NSObject

+ (void)setEnableAlbumLoadOpt:(BOOL)enableAlbumLoadOpt;
+ (BOOL)enableAlbumLoadOpt;

#pragma mark - auth

+ (AWEAuthorizationStatus)authorizationStatus;
+ (void)authorizationStatusWithCompletion:(void (^ _Nullable)(AWEAuthorizationStatus status))completion; //异步获取权限状态
+ (void)requestAuthorizationWithCompletionOnMainQueue:(void(^ _Nullable)(AWEAuthorizationStatus status))handler;
+ (void)requestAuthorizationWithActionBlock:(void (^ _Nullable)(void))actionBlock denyBlock:(void (^ _Nullable)(void))denyBlock allowLimited:(BOOL)allowLimited;

#pragma mark - get albums

+ (void)getAllAlbumsForMVWithType:(AWEGetResourceType)type completion:(void (^ _Nullable)(NSArray<CAKAlbumModel *> * _Nullable))completion;
+ (void)getAllAlbumsWithType:(AWEGetResourceType)type completion:(void (^ _Nullable)(NSArray<CAKAlbumModel *> * _Nullable))completion;

/**
 * @brief get latest assets
 * @param type Type of resource to get
 * @param latestCount Get the number of assets
 * @param sortStyle How to define the latest
 */

+ (void)getLatestAssetCount:(NSUInteger)latestCount
                  sortStyle:(CAKAlbumAssetSortStyle)sortStyle
                       type:(AWEGetResourceType)type
                 completion:(void (^) (NSArray<CAKAlbumAssetModel *> * _Nullable latestAssets))completion;

+ (void)getLatestAssetWithType:(AWEGetResourceType)type
                    completion:(void (^ _Nullable) (CAKAlbumAssetModel * _Nullable latestAssetModel))completion;

/**
 @brief Deprecated method, use assign sortStyle instead
 */

+ (void)getLatestAssetCount:(NSUInteger)latestCount
                       type:(AWEGetResourceType)type
                 completion:(void (^ _Nullable) (NSArray<CAKAlbumAssetModel *> * _Nullable latestAssets))completion;

#pragma mark - get assets

+ (void)getAssetsFromFetchResult:(PHFetchResult * _Nullable)result
                     filterBlock:(BOOL (^ _Nullable)(PHAsset * _Nullable))filterBlock
                      completion:(void (^ _Nullable)(NSArray<CAKAlbumAssetModel *> * _Nullable assetModelArray, PHFetchResult * _Nullable result))completion;

+ (void)getAssetsWithAlbum:(CAKAlbumModel * _Nullable)album
                      type:(AWEGetResourceType)type
               filterBlock:(BOOL (^ _Nullable) (PHAsset * _Nullable))filterBlock
                completion:(void (^ _Nullable) (NSArray<CAKAlbumAssetModel *> * _Nullable, PHFetchResult * _Nullable))completion;

+ (void)getAllAlbumsWithType:(AWEGetResourceType)type
                   ascending:(BOOL)ascending
              assetAscending:(BOOL)assetAscending
                  completion:(void (^ _Nullable)(NSArray<CAKAlbumModel *> * _Nullable))completion;

+ (void)getAssetsWithIdentifiers:(NSArray<NSString *> * _Nullable)identifiers
                      completion:(void (^ _Nullable) (NSArray<CAKAlbumAssetModel *> * _Nullable))completion;

+ (void)getAVAssetsWithAssets:(NSArray<CAKAlbumAssetModel *> * _Nullable)assets completion:(void (^ _Nullable)(NSArray<CAKAlbumAssetModel *> * _Nullable))completion;

+ (void)getAVAssetWithPHAsset:(PHAsset * _Nullable)phAsset options:(PHVideoRequestOptions * _Nullable)options completion:(void (^ _Nullable)(AVAsset *_Nullable asset, AVAudioMix *_Nullable audioMix, NSDictionary *_Nullable info))completion;

//获取图片或视频
+ (void)getAssetsWithType:(AWEGetResourceType)type
              filterBlock:(BOOL (^ _Nullable) (PHAsset * _Nullable phAsset))filterBlock
               completion:(void (^ _Nullable) (NSArray<CAKAlbumAssetModel *> * _Nullable assetModelArray, PHFetchResult * _Nullable result))completion;

+ (void)getAssetsWithType:(AWEGetResourceType)type
              filterBlock:(BOOL (^ _Nullable ) (PHAsset * _Nullable))filterBlock
                ascending:(BOOL)ascending
               completion:(void (^ _Nullable) (NSArray<CAKAlbumAssetModel *> * _Nullable assetModelArray, PHFetchResult * _Nullable result))completion;

+ (void)getAssetsWithType:(AWEGetResourceType)type
              filterBlock:(BOOL (^) (PHAsset * _Nullable))filterBlock
                sortStyle:(CAKAlbumAssetSortStyle)sortStyle
                ascending:(BOOL)ascending
               completion:(void (^ _Nullable) (NSArray<CAKAlbumAssetModel *> * _Nullable assetModelArray, PHFetchResult * _Nullable result))completion;

/**
@brief Deprecated method, use assign sortStyle instead
*/

+ (void)getAllAssetsWithType:(AWEGetResourceType)type
                   ascending:(BOOL)ascending
                  completion:(void (^ _Nullable)(PHFetchResult * _Nullable))completion;

/**
 * @brief Get assets from specified collection
 * @param type Type of resource to get
 * @param ascending The order of sort
 * @param sortStyle How to define the latest
 * @param completion The PHFetchResult callback block
 */

+ (void)getAllAssetsWithType:(AWEGetResourceType)type
                   sortStyle:(CAKAlbumAssetSortStyle)sortStyle
                   ascending:(BOOL)ascending
                  completion:(void (^ _Nullable)(PHFetchResult * _Nullable))completion;

+ (void)getAllAssetsAndResultWithType:(AWEGetResourceType)type
                            sortStyle:(CAKAlbumAssetSortStyle)sortStyle
                            ascending:(BOOL)ascending
                           completion:(void (^ _Nullable) (NSArray<CAKAlbumAssetModel *> * _Nullable assetModelArray, PHFetchResult * _Nullable result))completion;

/**
 * @brief Get assets from specified collection
 * @param type Type of resource to get
 * @param ascending The order of sort
 * @param sortStyle How to define the latest
 */

+ (PHFetchResult *_Nullable)getAssetsFromCollection:(PHAssetCollection * _Nullable)collection
                                          sortStyle:(CAKAlbumAssetSortStyle)sortStyle
                                           withType:(AWEGetResourceType)type
                                          ascending:(BOOL)ascending;
/**
 @brief Deprecated method, use assign sortStyle instead
 */
+ (PHFetchResult * _Nullable)getAssetsFromCollection:(PHAssetCollection * _Nullable)collection
                                  withType:(AWEGetResourceType)type
                                 ascending:(BOOL)ascending;

//获取UIImage
//图片尺寸根据asset计算
+ (int32_t)getUIImageWithPHAsset:(PHAsset * _Nullable)asset
            networkAccessAllowed:(BOOL)networkAccessAllowed
                 progressHandler:(void (^ _Nullable)(CGFloat progress, NSError * _Nullable error, BOOL * _Nullable stop, NSDictionary * _Nullable info))progressHandler
                      completion:(void (^ _Nullable)(UIImage * _Nullable photo, NSDictionary * _Nullable info, BOOL isDegraded))completion;

+ (int32_t)getUIImageWithPHAsset:(PHAsset * _Nullable)asset
                       imageSize:(CGSize)imageSize
                     contentMode:(PHImageContentMode)contentMode
            networkAccessAllowed:(BOOL)networkAccessAllowed
                 progressHandler:(void (^ _Nullable)(CGFloat progress, NSError * _Nullable error, BOOL * _Nullable stop, NSDictionary * _Nullable info))progressHandler
                      completion:(void (^ _Nullable)(UIImage * _Nullable photo, NSDictionary * _Nullable info, BOOL isDegraded))completion;

+ (int32_t)getUIImageWithPHAsset:(PHAsset * _Nullable)asset
                       imageSize:(CGSize)imageSize
            networkAccessAllowed:(BOOL)networkAccessAllowed
                 progressHandler:(void (^ _Nullable)(CGFloat progress, NSError * _Nullable error, BOOL * _Nullable stop, NSDictionary * _Nullable info))progressHandler
                      completion:(void (^ _Nullable)(UIImage * _Nullable photo, NSDictionary * _Nullable info, BOOL isDegraded))completion;

+ (int32_t)getUIImageWithPHAsset:(PHAsset * _Nullable)asset
                      targetSize:(CGSize)targetSize
                     contentMode:(PHImageContentMode)contentMode
                         options:(PHImageRequestOptions * _Nullable)options
                   resultHandler:(void (^ _Nullable)(UIImage *_Nullable result, NSDictionary *_Nullable info))resultHandler;

//获取image data
+ (void)getPhotoDataWithAsset:(PHAsset * _Nullable)asset version:(PHImageRequestOptionsVersion)version completion:(void (^ _Nullable)(NSData * _Nullable _Nullabledata, NSDictionary * _Nullable info, BOOL isInCloud))completion;
+ (void)getOriginalPhotoDataWithAsset:(PHAsset * _Nullable)asset completion:(void (^ _Nullable)(NSData * _Nullable data, NSDictionary * _Nullable info, BOOL isInCloud))completion;
+ (void)getOriginalPhotoDataFromICloudWithAsset:(PHAsset * _Nullable)asset
                                progressHandler:(void (^ _Nullable)(CGFloat progress, NSError * _Nullable error, BOOL * _Nullable stop, NSDictionary * _Nullable info))progressHandler
                                     completion:(void (^ _Nullable)(NSData * _Nullable data, NSDictionary * _Nullable info))completion;

//icloud
+ (void)getPhotoDataFromICloudWithAsset:(PHAsset * _Nullable)asset
                        progressHandler:(void (^ _Nullable)(CGFloat progress, NSError * _Nullable error, BOOL * _Nullable stop, NSDictionary * _Nullable info))progressHandler
                             completion:(void (^ _Nullable)(NSData * _Nullable data, NSDictionary * _Nullable info))completion;

+ (void)getUIImageFromICloudWithPHAsset:(PHAsset * _Nullable)asset
                        progressHandler:(void (^ _Nullable)(CGFloat progress, NSError * _Nullable error, BOOL * _Nullable stop, NSDictionary * _Nullable info))progressHandler
                             completion:(void (^ _Nullable)(UIImage * _Nullable photo, NSDictionary * _Nullable info, BOOL isDegraded))completion;

+ (void)getUIImageFromICloudWithPHAsset:(PHAsset * _Nullable)asset
                              imageSize:(CGSize)imageSize
                        progressHandler:(void (^ _Nullable)(CGFloat progress, NSError * _Nullable error, BOOL * _Nullable stop, NSDictionary * _Nullable info))progressHandler
                             completion:(void (^ _Nullable)(UIImage * _Nullable photo, NSDictionary * _Nullable info, BOOL isDegraded))completion;
//获取视频avasset
+ (void)fetchVideoAsset:(CAKAlbumAssetModel * _Nullable)assetModel completion:(void (^ _Nullable)(CAKAlbumAssetModel * _Nullable model, BOOL isICloud))completion;

//获取图片字节数
+ (void)getPhotosBytesWithArray:(NSArray<CAKAlbumAssetModel *> * _Nullable)photos completion:(void (^ _Nullable)(NSString * _Nullable totalBytes))completion;

//取消request
+ (void)cancelImageRequest:(int32_t)requestID;

+ (CAKAlbumAssetModel * _Nullable)assetModelWithPHAsset:(PHAsset * _Nullable)asset;

//process
+ (CGSize)sizeFor1080P:(PHAsset * _Nullable)phAsset;
+ (UIImage * _Nullable)processImageTo1080P:(UIImage * _Nullable)sourceImage;
+ (UIImage * _Nullable)processImageWithBlackEdgeWithOutputSize:(CGSize)outputSize sourceImage:(UIImage * _Nullable)sourceImage;

//根据info获取相册中video的url
+ (NSURL *_Nullable)privateVideoURLWithInfo:(NSDictionary * _Nullable)info;
+ (NSString *_Nullable)getMD5withPath:(NSString * _Nullable)filePath usedBytes:(NSInteger)usedBytes;

+ (NSString * _Nullable)timeStringWithDuration:(NSTimeInterval)duration;

+ (void)getURLFromAVAsset:(AVAsset * _Nullable)avAsset completion:(void (^ _Nullable)(NSURL * _Nullable url))completion;


//ACCDeviceAuth

+ (BOOL)isiOS14PhotoNotDetermined;

+ (BOOL)isiOS14PhotoLimited;

+ (PHAssetCollection *_Nullable)getCamraRoolAssetCollection;

@end
