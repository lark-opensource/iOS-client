//
//  TTURLTracker.h
//  Titan
//
//  Created by yin on 2017/5/11.
//  Copyright © 2017年 toutiao. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TTAdSplashURLTrackerModel;

@interface TTAdSplashURLTracker : NSObject

+ (instancetype)shareURLTracker;

- (void)trackURLs:(NSArray *)URLs model:(TTAdSplashURLTrackerModel*)trackModel;

@end

static inline void ttAdSplashTrackURLsModel(NSArray *URLs, TTAdSplashURLTrackerModel* trackModel) {
    [[TTAdSplashURLTracker shareURLTracker] trackURLs:URLs model:trackModel];
}


@interface TTAdSplashURLTrackerModel : NSObject

@property (nonatomic, copy, readonly) NSString *adId;
@property (nonatomic, copy, readonly) NSString *logExtra;
@property (nonatomic, copy, readonly) NSString *trackLabel;
@property (nonatomic, assign, readonly) NSTimeInterval expireTime;    //广告过期时间

- (instancetype)initWithAdId:(NSString*)adId
                    logExtra:(NSString*)logExtra
                  trackLabel:(NSString *)trackLabel
                  expireTime:(NSTimeInterval)expireTime;

@end
