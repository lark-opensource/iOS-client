//
//  ACCMusicCollectionFeedNetworkManager.m
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/5.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "ACCMusicCollectionFeedNetworkManager.h"

#import <CreativeKit/ACCNetServiceProtocol.h>


@implementation ACCMusicCollectionFeedNetworkManager

+ (void)requestMusicCollectionFeedWithCursor:(NSNumber *_Nullable)cursor
                                       count:(NSNumber *_Nullable)count
                                  recordMode:(ACCServerRecordMode)recordMode
                               videoDuration:(NSTimeInterval)duration
                             isCommerceMusic:(BOOL)isCommerceMusic
                                  completion:(AWEMusicCollectionFeedFetchCompletion _Nullable)completion
{
    if (!completion) {
        return;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    if (cursor != nil) {
        params[@"cursor"] = cursor;
    }
    if (count != nil) {
        params[@"count"] = count;
    }
    if (recordMode > 0) {
        params[@"shoot_mode"] = @(recordMode);
    }
    if (duration > 0) {
        params[@"video_duration"] = @(duration);
    }
    NSString *URLPath = [self musicCollectionFeedURLString:isCommerceMusic];
    [ACCNetService() requestWithModel:^(ACCRequestModel * _Nullable requestModel) {
        requestModel.requestType = ACCRequestTypeGET;
        requestModel.params = params;
        requestModel.urlString = URLPath;
        requestModel.objectClass = [ACCMusicCollectionFeedResponse class];
    } completion:^(ACCMusicCollectionFeedResponse * _Nullable model, NSError * _Nullable error) {
        if (completion) {
            completion(model, error);
        }
    }];
}

+ (void)requestMusicCollectionPickWithCursor:(NSNumber *_Nullable)cursor
                               extraMusicIds:(NSString *)extraMusicIds
                                  recordMode:(ACCServerRecordMode)recordMode
                               videoDuration:(NSTimeInterval)duration
                             isCommerceMusic:(BOOL)isCommerceMusic
                                  completion:(AWEMusicCollectionPickFetchCompletion _Nullable)completion {
    if (!completion) {
        return;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    params[@"radio_cursor"] = cursor ?: @(0);
    params[@"extra_music_ids"] = extraMusicIds;
    params[@"is_commerce_music"] = isCommerceMusic ? @"true" : @"false";
    if (recordMode > 0) {
        params[@"shoot_mode"] = @(recordMode);
    }
    if (duration > 0) {
        params[@"video_duration"] = @(duration);
    }
    NSString *URLPath = [self musicCollectionPickURLString:isCommerceMusic];
    
    [ACCNetService() requestWithModel:^(ACCRequestModel * _Nullable requestModel) {
        requestModel.requestType = ACCRequestTypeGET;
        requestModel.params = params;
        requestModel.urlString = URLPath;
        requestModel.objectClass = [ACCMusicPickResponse class];
    } completion:^(ACCMusicPickResponse *  _Nullable model, NSError * _Nullable error) {
        if (completion) {
            completion(model, error);
        }
    }];
}

+ (NSString *)musicCollectionFeedURLString:(BOOL)isCommerceMusic
{
    NSString *URLPath = [NSString stringWithFormat:@"%@/aweme/v1/music/collection/feed/", [ACCNetService() defaultDomain]];
    
    return URLPath;
}

+ (NSString *)musicCollectionPickURLString:(BOOL)isCommerceMusic
{
    NSString *URLPath = [NSString stringWithFormat:@"%@/aweme/v1/music/pick/", [ACCNetService() defaultDomain]];
    
    return URLPath;
}

@end
