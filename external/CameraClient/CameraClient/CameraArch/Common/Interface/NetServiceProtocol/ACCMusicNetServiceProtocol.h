//
//  ACCMusicServiceProtocol.h
//  Pods
//
//  Created by wishes on 2019/12/4.
//

#ifndef ACCMusicServiceProtocol_h
#define ACCMusicServiceProtocol_h

#import <CreativeKit/ACCMacros.h>
#import <Mantle/Mantle.h>

#import <CreationKitArch/ACCAwemeModelProtocol.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>

@class AWEResourceUploadParametersResponseModel;
@class ACCMusicCollectListsResponseModel;
@class ACCPropRecommendMusicReponseModel;
@class ACCVideoMusicListResponse;

#import <CreationKitInfra/ACCModuleService.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const ACCMusicCacheStickerMusicManager = @"AWEStickerMusicManager";
static NSString *const ACCStatusMusicCacheKeyPrefix = @"statusMusicCacheKey";
static NSString *const ACCMVMusicCacheKeyPrefix = @"mvMusicCacheKey";
static NSString *const kAWEAIMusicRecommendDefaultMusicCacheKey = @"kAWEAIMusicRecommendDefaultMusicCacheKey";

typedef void (^ACCVideoMusicInfoListCompletion)(ACCVideoMusicListResponse *_Nullable response, NSError * _Nullable error);

typedef void (^ACCVideoMusicInfoListLoadMoreCompletion)(ACCVideoMusicListResponse *_Nullable response, NSNumber *hasMore, NSNumber *cursor, NSError * _Nullable error);

typedef void (^ACCFetchRecommendMusicsCompletion)(NSArray <id<ACCMusicModelProtocol>> * _Nullable musicList, NSError * _Nullable error);

typedef void (^ACCFetchAIFramesUploadAuthkeyCompletion)(AWEResourceUploadParametersResponseModel * _Nullable response, NSError * _Nullable error);

typedef void (^ACCMusicDataBlock)(id<ACCMusicModelProtocol> _Nullable model, NSError *_Nullable error);

typedef void (^ACCMusicCollectListsResponseBlock)(ACCMusicCollectListsResponseModel *_Nullable model, NSError * _Nullable error);

typedef void (^ACCNetServiceCompletionBlock)(id _Nullable model, NSError * _Nullable error);

typedef void (^ACCPhotoMovieMusicListResponseBlock)(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList);


@protocol ACCMusicNetServiceProtocol <NSObject>

#pragma mark - cache music model

- (nullable id<ACCMusicModelProtocol>)fetchCachedMusicWithID:(nullable NSString *)musicID cacheKey:(nonnull NSString *)key;

- (nullable NSArray<id<ACCMusicModelProtocol>> *)fetchCachedMusicListWithCacheKey:(nonnull NSString *)key;


- (BOOL)cacheMusicModel:(nullable id<ACCMusicModelProtocol>)music cacheKey:(nonnull NSString *)key;

- (void)cacheMusicList:(nullable NSArray<id<ACCMusicModelProtocol>> *)music cacheKey:(nonnull NSString *)key;

#pragma mark - fetch music list

/*
*  请求AI配乐默认的音乐列表
*  @param urlGroup 请求的url数组
*/
- (void)fetchDefaultMusicListWithURLGoup:(nullable NSArray<NSString *> *)urlGroup callback:(nullable ACCFetchRecommendMusicsCompletion)completion;

/*
*  获取AI配乐上传视频帧需要的auth key
*/
- (void)fetchAIFramesUploadAuthkeyWithCallback:(nullable ACCFetchAIFramesUploadAuthkeyCompletion)completion;

/*
*  获取推荐的AI配乐列表
*  @param uri 压缩的视频帧的本地地址
*/
- (void)requestAIRecommendMusicListWithZipURI:(nullable NSString *)uri
                                        count:(nullable NSNumber *)count
                                  otherParams:(nullable NSDictionary *)para
                                   completion:(nullable ACCVideoMusicInfoListCompletion)completion;

/*
*  同上，获取推荐的AI配乐列表，支持返回cursor
*  @param uri 压缩的视频帧的本地地址
*/
- (void)requestAIRecommendMusicListWithZipURI:(nullable NSString *)uri
                                        count:(nullable NSNumber *)count
                                  otherParams:(nullable NSDictionary *)para
                                   loadMoreCompletion:(nullable ACCVideoMusicInfoListLoadMoreCompletion)completion;

/*
*  获取照片电影的音乐列表
*/
- (void)requestMusicForPhotoMovieWithCursor:(nullable NSNumber *)cursor
                                      count:(nullable NSNumber *)count
                                 completion:(nullable ACCVideoMusicInfoListCompletion)completion;

/*
* 根据scene类型获取音乐列表
* @param scene eg status
* @param region 地区
*/
- (void)requestWithScene:(nonnull NSString *)scene
                  cursor:(NSNumber * _Nullable)cursor
                  region:(NSString * _Nullable)region
                   count:(NSNumber * _Nullable)count
              completion:(nullable ACCVideoMusicInfoListCompletion)completion;

/*
* 根据分类请求音乐列表
* @param mcId 分类id
*/
- (void)requestWithMusicClassId:(nullable NSString *)mcId
                         cursor:(nullable NSNumber *)cursor
                          count:(nullable NSNumber *)count
                     completion:(nullable ACCVideoMusicInfoListCompletion)completion;

- (void)requestWithMusicClassId:(nullable NSString *)mcId
                         cursor:(nullable NSNumber *)cursor
                          count:(nullable NSNumber *)count
                    noDuplicate:(nullable NSNumber *)noDuplicate
                     completion:(nullable ACCVideoMusicInfoListCompletion)completion;

- (void)requestWithMusicClassId:(nullable NSString *)mcId
                         cursor:(nullable NSNumber *)cursor
                          count:(nullable NSNumber *)count
                    noDuplicate:(nullable NSNumber *)noDuplicate
                    otherParams:(nullable NSDictionary *)para
                     completion:(nullable ACCVideoMusicInfoListCompletion)completion;

/*
* 获取音乐分类列表
*/
- (void)requestWithCursor:(nullable NSNumber *)cursor
                    count:(nullable NSNumber *)count
               completion:(nullable ACCVideoMusicInfoListCompletion)completion;


- (void)requestMusicItemWithID:(nonnull NSString *)itemID
                    completion:(nonnull ACCMusicDataBlock)block;

@optional
/**
 * 获取收藏的音乐列表
 */
- (void)requestCollectingMusicsWithCursor:(nonnull NSNumber *)cursor
                                    count:(nonnull NSNumber *)count
                               completion:(nullable ACCMusicCollectListsResponseBlock)block;

- (void)requestCollectingMusicsWithCursor:(nonnull NSNumber *)cursor
                                    count:(nonnull NSNumber *)count
                             forLongVideo:(BOOL)forLongVideo
                               completion:(nullable ACCMusicCollectListsResponseBlock)block;

- (void)fetchMusicListWithURL:(NSString *)urlStr
                       params:(NSDictionary *)params
                   completion:(void(^)(ACCPropRecommendMusicReponseModel *model, NSError *error))completion;

- (void)fetchMusicListForPhotoMovieWithCompletion:(nullable ACCPhotoMovieMusicListResponseBlock)block;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCMusicServiceProtocol_h */
