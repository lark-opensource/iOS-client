//
//  ACCMusicCollectionFeedNetworkManager.h
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/5.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "ACCMusicCollectionFeedResponse.h"
#import <CreationKitInfra/ACCModuleService.h>
#import "ACCMusicPickResponse.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^AWEMusicCollectionFeedFetchCompletion)(ACCMusicCollectionFeedResponse * _Nullable response, NSError * _Nullable error);
typedef void (^AWEMusicCollectionPickFetchCompletion)(ACCMusicPickResponse * _Nullable response, NSError * _Nullable error);

@interface ACCMusicCollectionFeedNetworkManager : NSObject

+ (void)requestMusicCollectionFeedWithCursor:(NSNumber *_Nullable)cursor
                                       count:(NSNumber *_Nullable)count
                                  recordMode:(ACCServerRecordMode)recordMode
                               videoDuration:(NSTimeInterval)duration
                             isCommerceMusic:(BOOL)isCommerceMusic
                                  completion:(AWEMusicCollectionFeedFetchCompletion _Nullable)completion;

/**
  Pick接口。 当cursor为0/nil时，表示拉取正常的，会返回banner_list, mc_list, music_list。
  当cursor为非0时，表示拉取电台的后续数据。只会返回music_list
  @param cursor 游标
  @param completion 完成后的回调
  */
+ (void)requestMusicCollectionPickWithCursor:(NSNumber *_Nullable)cursor
                               extraMusicIds:(NSString *)extraMusicIds
                                  recordMode:(ACCServerRecordMode)recordMode
                               videoDuration:(NSTimeInterval)duration
                             isCommerceMusic:(BOOL)isCommerceMusic
                                  completion:(AWEMusicCollectionPickFetchCompletion _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
