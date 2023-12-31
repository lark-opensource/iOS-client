//
//  ACCRecommendMusicRequestManager.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/7/8.
//

#import <Foundation/Foundation.h>
#import "ACCMusicCollectListsResponseModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>


NS_ASSUME_NONNULL_BEGIN

@interface ACCRecommendMusicRequestManager : NSObject

- (instancetype)initWithPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel;

- (void)resetRequestParams;


- (BOOL)canUseLoadMore; // 是否支持loadmore加载音乐
- (BOOL)useHotMusic;  // 是否可以使用热门推荐音乐或AI抽帧推荐配乐
- (BOOL)usedNewClipForMultiUploadVideosFetchHotMusic;

- (BOOL)autoDegradedSelectHotMusicDataSourceSuccess:(BOOL)degradation;  // 更新降级使用热门音乐状态，返回是否允许降级使用热门音乐
 
@property (nonatomic, assign, readonly) BOOL autoDegradeSelectHotMusic;
@property (nonatomic, assign, readonly) BOOL hotMusicHasMore;
@property (nonatomic, strong, readonly) NSNumber *hotMusicCursor;
@property (nonatomic, assign, readonly) BOOL hotMusicIsProcessing;
@property (nonatomic, assign, readonly) BOOL hotMusicFirstLoading;

- (void)fetchInfiniteHotMusic:(void (^)(void))fetchResultBlock;

@property (nonatomic, assign, readonly) BOOL aiMusicIsProcessing;
@property (nonatomic, assign, readonly) BOOL aiMusicHasMore;
@property (nonatomic, strong, readonly) NSNumber *aiMusicCursor;

- (void)fetchInfiniteAIRecommendMusicWithURI:(nullable NSString *)zipUri isCommercialScene:(BOOL)isCommercialScene fetchResultBlock:(nullable void (^)(void))fetchResultBlock;

- (BOOL)shouldUseMusicDataFromHost;
- (BOOL)usedDefaultMusicList; // 是否正在使用兜底的推荐音乐

@end

NS_ASSUME_NONNULL_END
