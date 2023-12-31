//
//  ACCMusicCollectionFeedManager.h
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/4.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "ACCMusicTransModelProtocol.h"
#import <CreationKitInfra/ACCModuleService.h>
#import "ACCSelectMusicTabProtocol.h"


@class AWEMusicCollectionData;

typedef void(^ACCMusicCollectionFeedManagerCompletion)(NSArray<AWEMusicCollectionData *> *list, NSError *error);
typedef void(^ACCMusicCollectionFeedManagerBannerFetchCompletion)(NSArray<id<ACCBannerModelProtocol>> *banners, NSError *error);

@interface ACCMusicCollectionFeedManager : NSObject

@property (nonatomic, assign, readonly) BOOL hasMoreDiscover;
@property (nonatomic, assign, readonly) BOOL hasMoreFavourite;
@property (nonatomic, strong) NSMutableArray<AWEMusicCollectionData *> *discoverList;
@property (nonatomic, strong) NSMutableArray<AWEMusicCollectionData *> *favouriteList;
@property (nonatomic, strong) NSMutableArray<AWEMusicCollectionData *> *propBindMusicList;
@property (nonatomic) NSMutableArray<AWEMusicCollectionData *> *challengeList;
@property (nonatomic, copy) ACCMusicCollectionFeedManagerBannerFetchCompletion bannerFetchCompletion;
@property (nonatomic, copy, readonly) NSArray<id<ACCBannerModelProtocol>> *placeholderBannerList;
@property (nonatomic, strong) NSArray *propBindMusicIdArray;
@property (nonatomic, assign) BOOL isCommerceMusic;     // 是否是商业化挑战+绑定音乐
@property (nonatomic, assign) ACCServerRecordMode recordModel;
@property (nonatomic, assign) NSTimeInterval videoDuration;

// TODO(liyansong): Banner数据

// 初始Fetch数据 0: 发现列表  1: 收藏列表
- (void)fetchDataWithType:(ACCSelectMusicTabType)type pickCompletion:(ACCMusicCollectionFeedManagerCompletion)pickCompletion completion:(ACCMusicCollectionFeedManagerCompletion)completion;
// 加载更多数据 0: 发现列表  1: 收藏列表
- (void)loadMoreWithType:(ACCSelectMusicTabType)type completion:(ACCMusicCollectionFeedManagerCompletion)completion;

@end
