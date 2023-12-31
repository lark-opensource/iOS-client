//
//  TTVideoEnginePlayInfoSource.m
//  TTVideoEngine
//
//  Created by 黄清 on 2019/1/11.
//

#import "TTVideoEnginePlayInfoSource.h"
#import "TTVideoEngineModel.h"

@implementation TTVideoEnginePlayInfoSource

- (void)setVideoInfo:(TTVideoEngineVideoInfo *)videoInfo {
    _videoInfo = videoInfo;
    if (videoInfo.playInfo.videoInfo) {
        self.fetchData = videoInfo.playInfo.videoInfo;
    }
    if (videoInfo.vid) {
        self.videoId = videoInfo.vid;
    } else if ([videoInfo.playInfo.videoInfo getValueStr:VALUE_VIDEO_ID]) {
        self.videoId = [videoInfo.playInfo.videoInfo getValueStr:VALUE_VIDEO_ID];
    }
    
    if (videoInfo.playInfo.videoInfo.fallbackAPI) {
        self.fallbackApi = videoInfo.playInfo.videoInfo.fallbackAPI;
    }
    if (videoInfo.playInfo.videoInfo.keyseed) {
        self.keyseed = videoInfo.playInfo.videoInfo.keyseed;
    }
}

- (TTVideoEngineRetryStrategy)retryStrategyForRetryCount:(NSInteger)retryCount {
    if (self.videoInfo) {
        return TTVideoEngineRetryStrategyFetchInfo;
    } else if (self.fetchData) {
        return [super retryStrategyForRetryCount:retryCount];
    }
    //
    return TTVideoEngineRetryStrategyNone;
}

- (BOOL)preloadDataIsExpire {
    return NO;
}

- (void)fetchUrlWithApiString:(ReturnStringBlock)apiString
                         auth:(ReturnStringBlock)authString
                       params:(ReturnDictonaryBlock)params
                   apiVersion:(ReturnIntBlock)apiVersion
                       result:(FetchResult)result {
    @weakify(self);
    FetchResult temResult = ^(BOOL canFetch, TTVideoEngineModel *_Nullable videoModel, NSError *_Nullable error){
        @strongify(self);
        !result ?: result(canFetch, videoModel, error);
        if (videoModel && !error) {
            self.videoInfo = nil;
            self.fetchData = videoModel.videoInfo;
            self.videoId = [videoModel.videoInfo getValueStr:VALUE_VIDEO_ID];
        }
    };
    //
    [super fetchUrlWithApiString:apiString auth:authString params:params apiVersion:apiVersion result:temResult];
}

- (instancetype)deepCopy {
    TTVideoEnginePlayInfoSource *playInfoSource = [super deepCopy];
    if (self.videoInfo) { // assign valid data.
        playInfoSource.videoInfo = self.videoInfo;
    }
    return playInfoSource;
}

- (BOOL)isEqual:(id)object {
    BOOL result = [super isEqual:object];
    if (!result) {
        return result;
    }
    
    if (![object isKindOfClass:[self class]]) {
        result = NO;
    } else {
        TTVideoEnginePlayInfoSource *tem = (TTVideoEnginePlayInfoSource *)object;
        result = [self.videoInfo isEqual:tem.videoInfo];
    }
    return result;
}

@end
