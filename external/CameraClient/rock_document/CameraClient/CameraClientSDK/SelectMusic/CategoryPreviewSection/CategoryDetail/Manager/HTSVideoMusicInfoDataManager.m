//
//  HTSVideoMusicDataManager.m
//  Pods
//
//  Created by 何海 on 16/8/16.
//
//

#import "HTSVideoMusicInfoDataManager.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCNetServiceProtocol.h>
#import "ACCCommerceServiceProtocol.h"


@implementation HTSVideoMusicInfoDataManager

+ (void)requestWithCursor:(NSNumber *)cursor
                    count:(NSNumber *)count
               isCommerce:(BOOL)isCommerce
               recordMode:(ACCServerRecordMode)recordMode
            videoDuration:(NSTimeInterval)duration
               completion:(AWEVideoMusicInfoListCompletion)completion
{
    if (!completion) {
       return;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    if (cursor) {
       params[@"cursor"] = cursor;
    }
    if (count) {
       params[@"count"] = count;
    }
    if (recordMode > 0) {
        params[@"shoot_mode"] = @(recordMode);
    }
    if (duration > 0) {
        params[@"video_duration"] = @(duration);
    }
    
    NSString *URL = [NSString stringWithFormat:@"%@/aweme/v1/music/collection/",[ACCNetService() defaultDomain]];
    if (isCommerce) {
        URL = [NSString stringWithFormat:@"%@/aweme/v1/commerce/music/collection/", [ACCNetService() defaultDomain]];
    }
    
    [ACCNetService() requestWithModel:^(ACCRequestModel * _Nullable requestModel) {
        requestModel.requestType = ACCRequestTypeGET;
        requestModel.urlString = URL;
        requestModel.params = params;
        requestModel.objectClass = ACCVideoMusicListResponse.class;
    } completion:completion];
}


+ (void)requestWithMusicClassId:(NSString *_Nullable)mcId
                         cursor:(NSNumber *_Nullable)cursor
                          count:(NSNumber *_Nullable)count
                     isCommerce:(BOOL)isCommerce
                     completion:(AWEVideoMusicInfoListCompletion _Nullable)completion
{
    [self requestWithMusicClassId:mcId cursor:cursor count:count isCommerce:isCommerce recordMode:0 videoDuration:0 completion:completion];
}

+ (void)requestWithMusicClassId:(NSString *_Nullable)mcId
                         cursor:(NSNumber *_Nullable)cursor
                          count:(NSNumber *_Nullable)count
                     isCommerce:(BOOL)isCommerce
                     recordMode:(ACCServerRecordMode)recordMode
                  videoDuration:(NSTimeInterval)duration
                     completion:(AWEVideoMusicInfoListCompletion _Nullable)completion
{
    if (!completion) {
        ACCBLOCK_INVOKE(completion,nil,nil);
       return;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:3];
    if (mcId) {
       params[@"mc_id"] = mcId;
    }
    if (cursor) {
       params[@"cursor"] = cursor;
    }
    if (count) {
       params[@"count"] = count;
    }
    if (recordMode > 0) {
        params[@"shoot_mode"] = @(recordMode);
    }
    if (duration > 0) {
        params[@"video_duration"] = @(duration);
    }
    
    NSString *URL = [NSString stringWithFormat:@"%@/aweme/v1/hot/music/",[ACCNetService() defaultDomain]];
    if (mcId) {
        URL = [NSString stringWithFormat:@"%@/aweme/v1/music/list/", [ACCNetService() defaultDomain]];
        if (isCommerce) {
            URL = [NSString stringWithFormat:@"%@/aweme/v1/commerce/music/list/", [ACCNetService() defaultDomain]];
        }
    }
    
    [ACCNetService() requestWithModel:^(ACCRequestModel * _Nullable requestModel) {
        requestModel.requestType = ACCRequestTypeGET;
        requestModel.urlString = URL;
        requestModel.params = params;
        requestModel.objectClass = ACCVideoMusicListResponse.class;
    } completion:^(id  _Nullable model, NSError * _Nullable error) {
        ACCBLOCK_INVOKE(completion,model,error);
    }];
}

+ (void)requestMusicTitlesWithClassId:(NSString *_Nullable)mcId
                               cursor:(NSNumber *_Nullable)cursor
                                count:(NSNumber *_Nullable)count
                                level:(NSNumber *_Nullable)level
                           isCommerce:(BOOL)isCommerce
                           completion:(AWETabTitleListCompletion _Nullable)completion
{
    if (!completion) {
        return;
    }
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (mcId) {
       params[@"mc_id"] = mcId;
    }
    if (cursor != nil) {
       params[@"cursor"] = cursor;
    }
    if (count != nil) {
       params[@"count"] = count;
    }
    if (level != nil) {
        params[@"level"] = level;
    }
    NSString *URL = [NSString stringWithFormat:@"%@/aweme/v1/hot/music/",[ACCNetService() defaultDomain]];
    if (mcId) {
        URL = [NSString stringWithFormat:@"%@/aweme/v1/music/list/", [ACCNetService() defaultDomain]];
        if (isCommerce) {
            URL = [NSString stringWithFormat:@"%@/aweme/v1/commerce/music/list/", [ACCNetService() defaultDomain]];
        }
    }
    
    [ACCNetService() requestWithModel:^(ACCRequestModel * _Nullable requestModel) {
        requestModel.requestType = ACCRequestTypeGET;
        requestModel.urlString = URL;
        requestModel.params = params;
        requestModel.objectClass = ACCMusicCollectionFeedResponse.class;
    } completion:^(id  _Nullable model, NSError * _Nullable error) {
        ACCBLOCK_INVOKE(completion,model,error);
    }];
}

+ (void)requestMusicForPhotoMovieWithCursor:(NSNumber *)cursor count:(NSNumber *)count completion:(AWEVideoMusicInfoListCompletion)completion
{
    if (!completion) {
       return;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    if (cursor) {
       params[@"cursor"] = cursor;
    }
    if (count) {
       params[@"count"] = count;
    }
    NSString *URL = [NSString stringWithFormat:@"%@/aweme/v1/music/choices/",[ACCNetService() defaultDomain]];
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) shouldUseCommerceMusic]) {
        URL = [NSString stringWithFormat:@"%@/aweme/v1/commerce/music/choices/", [ACCNetService() defaultDomain]];
    }
    
    [ACCNetService() requestWithModel:^(ACCRequestModel * _Nullable requestModel) {
        requestModel.requestType = ACCRequestTypeGET;
        requestModel.params = params;
        requestModel.urlString = URL;
        requestModel.objectClass = ACCVideoMusicListResponse.class;
    } completion:completion];
}

@end
