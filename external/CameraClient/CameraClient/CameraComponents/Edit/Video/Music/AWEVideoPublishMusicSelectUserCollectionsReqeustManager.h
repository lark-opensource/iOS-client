//
//  AWEVideoPublishMusicSelectUserCollectionsReqeustManager.h
//  Pods
//
//  Created by resober on 2019/5/24.
//

#import <CreationKitArch/ACCMusicModelProtocol.h>
#import "ACCMusicCollectListsResponseModel.h"

NS_ASSUME_NONNULL_BEGIN
typedef void(^AWEVideoPublishMusicSelectUserCollectionsReqeustManagerCompletion)(BOOL success, ACCMusicCollectListsResponseModel *rspModel);

@interface AWEVideoPublishMusicSelectUserCollectionsReqeustManager : NSObject
/// 请求用户收藏的音乐时，每页的数量，default 12.
@property (nonatomic, assign) NSUInteger musicCntPerPage;
/// 当前请求用户收藏的音乐的游标
@property (nonatomic, assign) NSUInteger curr;
/// 是否还有更多的数据
@property (nonatomic, assign) BOOL hasMore;
/// 当前是否正在请求网络处理
@property (nonatomic, assign, readonly) BOOL isProcessing;

/**
 获取当前(curr)页面对应的用户收藏数据
 如果成功，++curr
 如果失败，curr保持不变
 @param completion 完成回调
 */
- (void)fetchCurrPageModelsWithCompletion:(AWEVideoPublishMusicSelectUserCollectionsReqeustManagerCompletion)completion;

/**
 重置请求参数 curr = 0，pageCnt = 1, musicCntPerPage = 12
 */
- (void)resetRequestParams;
@end
NS_ASSUME_NONNULL_END
