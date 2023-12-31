//
//  AWERepoMusicSearchModel.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/8/13.
//

#import <CreationKitArch/ACCRepoMusicModel.h>

NS_ASSUME_NONNULL_BEGIN

// 记录上一次被使用的音乐搜索结果信息
@interface AWERepoMusicSearchModel : NSObject<NSCopying>

@property (nonatomic, copy) NSString *searchMusicId;
@property (nonatomic, copy) NSString *searchId;
@property (nonatomic, copy) NSString *searchResultId;
@property (nonatomic, copy) NSString *listItemId;
@property (nonatomic, copy) NSString *tokenType;

@end

@interface AWEVideoPublishViewModel (RepoMusicSearch)
 
@property (nonatomic, strong, readonly) AWERepoMusicSearchModel *repoMusicSearch;
 
@end

NS_ASSUME_NONNULL_END
