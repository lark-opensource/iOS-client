//
//  AWEPublishFirstFrameTracker.h
//  AWEStudioService-Pods-Aweme
//
//  Created by Leon on 2021/7/12.
//

#import <Foundation/Foundation.h>
#import "AWERepoTrackModel.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const kAWEPublishEventFirstFrame;

@interface AWEPublishFirstFrameTracker : NSObject

+ (instancetype)sharedTracker;

- (void)eventBegin:(NSString *)event;

- (void)eventEnd:(NSString *)event;

- (void)finishTrackWithInputData:(AWERepoTrackModel *)trackModel;

@end

NS_ASSUME_NONNULL_END
