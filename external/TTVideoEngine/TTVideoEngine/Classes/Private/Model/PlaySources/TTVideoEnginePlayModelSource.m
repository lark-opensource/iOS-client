//
//  TTVideoEnginePlayModelSource.m
//  TTVideoEngine
//
//  Created by 黄清 on 2019/5/9.
//

#import "TTVideoEnginePlayModelSource.h"

@implementation TTVideoEnginePlayModelSource

- (void)setVideoModel:(TTVideoEngineModel *)videoModel {
    _videoModel = videoModel;
    if (videoModel.videoInfo) {
        self.fetchData = videoModel.videoInfo;
    }
    if ([videoModel.videoInfo getValueStr:VALUE_VIDEO_ID]) {
        self.videoId = [videoModel.videoInfo getValueStr:VALUE_VIDEO_ID];
    }
    if (videoModel.videoInfo.fallbackAPI) {
        self.fallbackApi = videoModel.videoInfo.fallbackAPI;
    }
    if (videoModel.videoInfo.keyseed) {
        self.keyseed = videoModel.videoInfo.keyseed;
    }
}

- (TTVideoEngineRetryStrategy)retryStrategyForRetryCount:(NSInteger)retryCount {
    if (self.videoModel) {
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
            self.videoModel = nil;
            self.fetchData = videoModel.videoInfo;
            self.videoId = [videoModel.videoInfo getValueStr:VALUE_VIDEO_ID];
        }
    };
    //
    [super fetchUrlWithApiString:apiString auth:authString params:params apiVersion:apiVersion result:temResult];
}

- (instancetype)deepCopy {
    TTVideoEnginePlayModelSource *playInfoSource = [super deepCopy];
    if (self.videoModel) { // assign valid data.
        playInfoSource.videoModel = self.videoModel;
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
        TTVideoEnginePlayModelSource *tem = (TTVideoEnginePlayModelSource *)object;
        result = [self.videoModel isEqual:tem.videoModel];
    }
    return result;
}

- (NSArray *)subtitleInfos {
    return self.videoModel.videoInfo.subtitleInfos;
}

- (BOOL)hasEmbeddedSubtitle {
    return self.videoModel.videoInfo.hasEmbeddedSubtitle;
}

@end
