//
//  ACCMusicCollectionFeedManager.m
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/4.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "ACCMusicCollectionFeedManager.h"
#import "AWEMusicCollectionData.h"
#import "ACCMusicCollectionFeedNetworkManager.h"
#import "ACCMusicCollectListsResponseModel.h"
#import "ACCVideoMusicProtocol.h"
#import <CreationKitInfra/ACCConfigManager.h>
#import "ACCConfigKeyDefines.h"

#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>


@interface ACCMusicCollectionFeedManager ()

@property (nonatomic, assign, readwrite) BOOL hasMoreDiscover;
@property (nonatomic, assign, readwrite) BOOL hasMoreFavourite;
// Fetching Management
@property (nonatomic, assign) BOOL isFetchingFavouriteList;
@property (nonatomic, assign) BOOL isFetchingInitialDiscoverList;
@property (nonatomic, assign) BOOL isFetchingMoreDiscoverList;
@property (nonatomic, assign) BOOL isFetchingMoreFMData;

@property (nonatomic, strong) NSNumber *discoverCursor;
@property (nonatomic, strong) NSNumber *favouriteCursor;

@property (nonatomic, assign) BOOL hasFetchedInitialPickData;
@property (nonatomic, assign) BOOL hasFetchedInitialDiscoverData;

@property (nonatomic, copy) ACCMusicCollectionFeedManagerCompletion initialFetchCompletion;
@property (nonatomic, strong) NSError *initialFetchDiscoverError;
@property (nonatomic, strong) NSError *initialFetchPickError;

@property (nonatomic, copy, readwrite) NSArray<id<ACCBannerModelProtocol>> *placeholderBannerList;

@end

@implementation ACCMusicCollectionFeedManager

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始的时候，默认有更多发现与收藏
        _hasMoreDiscover = YES;
        _hasMoreFavourite = YES;
    }
    return self;
}

#pragma mark - Public

// 初始Fetch数据 0: 发现列表  1: 收藏列表
- (void)fetchDataWithType:(ACCSelectMusicTabType)type
           pickCompletion:(ACCMusicCollectionFeedManagerCompletion)pickCompletion
               completion:(ACCMusicCollectionFeedManagerCompletion)completion
{
    [self p_fetchDataWithType:type pickCompletion:pickCompletion completion:completion];
}
    
- (void)p_fetchDataWithType:(ACCSelectMusicTabType)type
             pickCompletion:(ACCMusicCollectionFeedManagerCompletion)pickCompletion
                 completion:(ACCMusicCollectionFeedManagerCompletion)completion
{
    if (type == 0) {
        if (self.isFetchingInitialDiscoverList) {
            return;
        }
        NSError *error = self.initialFetchPickError ?: self.initialFetchDiscoverError ?: nil;
        // 如果已经fetch过数据，并且没有error, 则不需要再fetch了
        if (self.hasFetchedInitialPickData && self.hasFetchedInitialDiscoverData && !error) {
            ACCBLOCK_INVOKE(completion, self.discoverList, nil);
            return;
        } else if (error) {
            // 如果是error存在的情况下，这个方法被调用，那应该是因为网络请求失败需要重新请求，这个时候需要把标识位清掉
            self.hasFetchedInitialPickData = NO;
            self.hasFetchedInitialDiscoverData = NO;
            [self.discoverList removeAllObjects];
        }
        self.isFetchingInitialDiscoverList = YES;
        @weakify(self)
        self.initialFetchCompletion = ^(NSArray<AWEMusicCollectionData *> *list, NSError *error) {
            @strongify(self)
            self.isFetchingInitialDiscoverList = NO;
            ACCBLOCK_INVOKE(completion, list, error);
        };
        // 获取pick data
        [self p_fetchPickData:pickCompletion];
        // 获取discover data
        CFTimeInterval startTime = CACurrentMediaTime();
        [self p_loadDiscoverWithCursor:nil count:nil completion:^(NSArray<AWEMusicCollectionData *> *list, NSError *error) {
            NSString *scene = type == 0 ? @"discover" : @"favorite";
            NSInteger duration = (CACurrentMediaTime() - startTime) * 1000;
            NSInteger success = list && !error;
            [ACCTracker() trackEvent:@"tool_performance_api"
                              params:@{
                                  @"api_type":@"music_list",
                                  @"duration":@(duration),
                                  @"status":@(success?0:1),
                                  @"error_domain":error.domain?:@"",
                                  @"error_code":@(error.code),
                                  @"scene":scene?:@"",
                              }];
        }];
    } else {
        [self p_loadFavouriteWithCursor:nil count:nil completion:completion];
    }
}
// 加载更多数据 0: 发现列表  1: 收藏列表
- (void)loadMoreWithType:(ACCSelectMusicTabType)type completion:(ACCMusicCollectionFeedManagerCompletion)completion
{
    [self p_loadMoreWithType:type completion:completion];
}

- (void)p_loadMoreWithType:(ACCSelectMusicTabType)type completion:(ACCMusicCollectionFeedManagerCompletion)completion {
    if (type == 0) {
        if (self.isFetchingMoreDiscoverList || (ACCConfigBool(kConfigBool_enable_music_selected_page_network_optims) && !self.discoverCursor)) {
            return;
        }
        self.isFetchingMoreDiscoverList = YES;
        CFTimeInterval startTime = CACurrentMediaTime();
        @weakify(self);
        [self p_loadDiscoverWithCursor:self.discoverCursor count:nil completion:^(NSArray<AWEMusicCollectionData *> *list, NSError *error) {
            @strongify(self);
            NSString *scene = type == 0 ? @"discover" : @"favorite";
            NSInteger duration = (CACurrentMediaTime() - startTime) * 1000;
            NSInteger success = list && !error;
            [ACCTracker() trackEvent:@"tool_performance_api"
                              params:@{
                                  @"api_type":@"music_list",
                                  @"duration":@(duration),
                                  @"status":@(success?0:1),
                                  @"error_domain":error.domain?:@"",
                                  @"error_code":@(error.code),
                                  @"scene":scene?:@"",
                              }];
            self.isFetchingMoreDiscoverList = NO;
            ACCBLOCK_INVOKE(completion, list, error);
        }];
    } else {
        [self p_loadFavouriteWithCursor:self.favouriteCursor count:nil completion:completion];
    }
}

- (NSArray *)placeholderBannerList {
    if (!_placeholderBannerList) {
        id<ACCBannerModelProtocol> banner = [[IESAutoInline(ACCBaseServiceProvider(), ACCMusicTransModelProtocol) bannerModelImplClass] new];
        _placeholderBannerList = @[banner,];
    }
    return _placeholderBannerList;
}

#pragma mark - Private

- (void)updateInitialFetchIfNeeded {
    if (self.hasFetchedInitialPickData && self.hasFetchedInitialDiscoverData) {
        NSError *error = self.initialFetchPickError ?: self.initialFetchDiscoverError ?: nil;
        ACCBLOCK_INVOKE(self.initialFetchCompletion, self.discoverList, error);
    }
}

- (void)p_fetchPickData:(ACCMusicCollectionFeedManagerCompletion)completion {
    
    NSString *extraMusicIds = nil;
    if (self.propBindMusicIdArray.count) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:self.propBindMusicIdArray options:NSJSONWritingPrettyPrinted error:nil];
        if (data) {
            extraMusicIds = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    
    [ACCMusicCollectionFeedNetworkManager requestMusicCollectionPickWithCursor:nil
                                                                 extraMusicIds:extraMusicIds
                                                                    recordMode:self.recordModel
                                                                 videoDuration:self.videoDuration
                                                               isCommerceMusic:self.isCommerceMusic
                                                                    completion:^(ACCMusicPickResponse * _Nullable response, NSError * _Nullable error) {
        if (response && !error && (response.musicList.count || response.categories.count)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSMutableArray<AWEMusicCollectionData *> *fetchedData = [NSMutableArray array];
                if (response.musicList.count) {
                    AWEMusicCollectionData *data;
                    if (response.musicListType == 0) { // 歌单
                        data = [[AWEMusicCollectionData alloc] initWithMusicArray:response.musicList];
                    }
                    [fetchedData acc_addObject:data];
                }
                if (response.extraMusicList.count) {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    for (id<ACCMusicModelProtocol> model in response.extraMusicList) {
                        AWEMusicCollectionData *data = [[AWEMusicCollectionData alloc] initWithMusicModel:model withType:AWEMusicCollectionDataTypeProp];
                        [array acc_addObject:data];
                    }
                    self.propBindMusicList = array;
                }
                
                if (response.categories.count) {
                    AWEMusicCollectionData *categoryData =
                            [[AWEMusicCollectionData alloc] initWithCategoryArray:response.categories];
                    [fetchedData acc_addObject:categoryData];
                }
                if (self.discoverList.count == 0) {
                    self.discoverList = fetchedData;
                } else {
                    [self.discoverList insertObjects:fetchedData
                                           atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, fetchedData.count)]];
                }
                ACCBLOCK_INVOKE(completion, self.discoverList, error);
                ACCBLOCK_INVOKE(self.bannerFetchCompletion, [response.banners copy], nil);
                self.initialFetchPickError = nil;
                if (!self.hasFetchedInitialPickData) {
                    self.hasFetchedInitialPickData = YES;
                    [self updateInitialFetchIfNeeded];
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                // 更新初始Fetch数据
                if (!self.hasFetchedInitialPickData) {
                    self.hasFetchedInitialPickData = YES;
                    self.initialFetchPickError = error;
                    [self updateInitialFetchIfNeeded];
                }
                if (error) {
                    ACCBLOCK_INVOKE(self.bannerFetchCompletion, nil, error);
                }
            });
        }
    }];
}

- (void)p_loadDiscoverWithCursor:(NSNumber *)cursor
                          count:(NSNumber *)count
                     completion:(ACCMusicCollectionFeedManagerCompletion)completion {
    [ACCMusicCollectionFeedNetworkManager requestMusicCollectionFeedWithCursor:cursor
                                                                         count:nil
                                                                    recordMode:self.recordModel
                                                                 videoDuration:self.videoDuration
                                                               isCommerceMusic:self.isCommerceMusic
                                                                    completion:^(ACCMusicCollectionFeedResponse * _Nullable response, NSError * _Nullable error) {
        if (response && !error){
            dispatch_async(dispatch_get_main_queue(), ^{
                self.initialFetchDiscoverError = nil;
                NSMutableArray<AWEMusicCollectionData *> *fetchedData = [NSMutableArray array];
                for (ACCMusicCollectionFeedModel *collectionModel in response.musicCollection) {
                    AWEMusicCollectionData *data =
                            [[AWEMusicCollectionData alloc] initWithMusicCollectionFeedModel:collectionModel];
                    [fetchedData acc_addObject:data];
                }
                // 拼接数据
                if (self.discoverList.count == 0) {
                    self.discoverList = fetchedData;
                } else {
                    [self.discoverList addObjectsFromArray:fetchedData];
                }
                // 更新Bookmark
                self.discoverCursor = response.cursor;
                self.hasMoreDiscover = response.hasMore.boolValue;
                // 更新初始Fetch数据
                if (!self.hasFetchedInitialDiscoverData) {
                    self.hasFetchedInitialDiscoverData = YES;
                    [self updateInitialFetchIfNeeded];
                }
                // Invoke completion handler
                ACCBLOCK_INVOKE(completion, self.discoverList, nil);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                // 更新初始Fetch数据
                if (!self.hasFetchedInitialDiscoverData) {
                    self.hasFetchedInitialDiscoverData = YES;
                    self.initialFetchDiscoverError = error;
                    [self updateInitialFetchIfNeeded];
                }
                // Invoke completion handler
                ACCBLOCK_INVOKE(completion, self.discoverList, error);
            });
        }
    }];
}

- (void)p_loadFavouriteWithCursor:(NSNumber *)cursor
                           count:(NSNumber *)count
                      completion:(ACCMusicCollectionFeedManagerCompletion)completion {
    if (self.isFetchingFavouriteList) {
        return;
    }
    if (![IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]) {
        self.hasMoreFavourite = NO;
        ACCBLOCK_INVOKE(completion, @[], nil);
        return;
    }
    self.isFetchingFavouriteList = YES;
    [ACCVideoMusic() requestCollectingMusicsWithCursor:cursor
                                                 count:nil
                                            completion:^(ACCMusicCollectListsResponseModel *model, NSError *error) {
        if (model && !error && [model mcList].count) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSMutableArray<AWEMusicCollectionData *> *favouriteList =
                        [NSMutableArray arrayWithCapacity:[model mcList].count];
                for (id<ACCMusicModelProtocol> musicModel in [model mcList]) {
                    AWEMusicCollectionData *data =
                            [[AWEMusicCollectionData alloc] initWithMusicModel:musicModel withType:AWEMusicCollectionDataTypeMusic];
                    [favouriteList acc_addObject:data];
                }
                if ([cursor integerValue] == 0) {
                    self.favouriteList = favouriteList;
                } else {
                    [self.favouriteList addObjectsFromArray:favouriteList];
                }
                self.favouriteCursor = [model cursor];
                self.hasMoreFavourite = [model hasMore];
                ACCBLOCK_INVOKE(completion, self.favouriteList, nil);
                self.isFetchingFavouriteList = NO;
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([cursor integerValue] == 0) {
                    self.favouriteList = [[NSMutableArray alloc] init];
                    self.favouriteCursor = nil;
                    self.hasMoreFavourite = NO;
                }
                ACCBLOCK_INVOKE(completion, self.favouriteList, error);
                self.isFetchingFavouriteList = NO;
            });
        }
    }];
}

@end
