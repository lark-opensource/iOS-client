//
//  HTSVideoMusicDataManager.h
//  Pods
//
//  Created by 何海 on 16/8/16.
//
//

#import "ACCVideoMusicListResponse.h"
#import "ACCMusicCollectionFeedResponse.h"

#import <CreationKitInfra/ACCModuleService.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^AWEVideoMusicInfoListCompletion)(ACCVideoMusicListResponse * _Nullable response, NSError * _Nullable error);
typedef void (^AWETabTitleListCompletion)(ACCMusicCollectionFeedResponse * _Nullable response, NSError * _Nullable error);

@interface HTSVideoMusicInfoDataManager : NSObject

+ (void)requestWithCursor:(nullable NSNumber *)cursor
                    count:(nullable NSNumber *)count
               isCommerce:(BOOL)isCommerce
               recordMode:(ACCServerRecordMode)recordMode
            videoDuration:(NSTimeInterval)duration
               completion:(AWEVideoMusicInfoListCompletion)completion;

+ (void)requestWithMusicClassId:(NSString *_Nullable)mcId
                         cursor:(NSNumber *_Nullable)cursor
                          count:(NSNumber *_Nullable)count
                     isCommerce:(BOOL)isCommerce
                     completion:(AWEVideoMusicInfoListCompletion _Nullable)completion;

+ (void)requestWithMusicClassId:(NSString *_Nullable)mcId
                         cursor:(NSNumber *_Nullable)cursor
                          count:(NSNumber *_Nullable)count
                     isCommerce:(BOOL)isCommerce
                     recordMode:(ACCServerRecordMode)recordMode
                  videoDuration:(NSTimeInterval)duration
                     completion:(AWEVideoMusicInfoListCompletion _Nullable)completion;


+ (void)requestMusicForPhotoMovieWithCursor:(NSNumber *_Nullable)cursor count:(NSNumber *_Nullable)count completion:(AWEVideoMusicInfoListCompletion _Nullable)completion;

/**
 Request tab titles for second hierarchical music list.
 @params:mcId        category id
 @params:cursor    cursor for the list
 @params:count      count for the list
 @params:level      level for the music category, 0-normal , 1-parent, 2-child
 @params:isCommerce commercial music
 */
+ (void)requestMusicTitlesWithClassId:(NSString *_Nullable)mcId
                               cursor:(NSNumber *_Nullable)cursor
                                count:(NSNumber *_Nullable)count
                                level:(NSNumber *_Nullable)level
                           isCommerce:(BOOL)isCommerce
                           completion:(AWETabTitleListCompletion _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
