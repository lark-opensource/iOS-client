//
//  ACCLocalAudioDataController.h
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/7/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEAssetModel;
@class AWEMusicCollectionData;
@protocol ACCMusicModelProtocol;

typedef void(^ACCExportLocalAudioCompletion)(AWEMusicCollectionData * _Nullable collectionData, NSError * _Nullable error);

@interface ACCLocalAudioMusicDataConfigModel : NSObject
@property (nonatomic,   copy) NSString *musicName;
@property (nonatomic,   copy) NSString *singerName;
@property (nonatomic, strong) NSURL *localMusicURL;
@property (nonatomic, strong) NSURL *localMusicCoverURL;
@property (nonatomic, assign) NSTimeInterval assetDuration;
@property (nonatomic, assign) BOOL isFromiTunes;
@end

@interface ACCLocalAudioDataController : NSObject
/**
 * @brief 导出、保存相册视频的音频
 */
- (void)exportLocalAudioWithAssetModel:(AWEAssetModel *)assetModel completion:(nullable ACCExportLocalAudioCompletion)completion;

/**
 * @brief 获取当前本地音频列表(创建时间倒序)
 */
- (NSArray<AWEMusicCollectionData *> *)getCurrentLocalAudioFileSortedList;

/**
 * @brief 重命名提取音频
 */
- (void)renameSingleLocalAudioWithAudio:(id<ACCMusicModelProtocol> )audio newName:(NSString *)newName;

/**
 * @brief 删除单条提取音频
 */
- (void)deleteSingleLocalAudio:(id<ACCMusicModelProtocol>)localMusic;

/**
 * @brief 清理iTunes本地缓存
 */
+ (void)clearLocalAudioCache;

@end

NS_ASSUME_NONNULL_END
