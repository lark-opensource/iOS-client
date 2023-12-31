//
//  TTDownloadTracker.h
//  TTNetworkDownloader
//
//  Created by Nami on 2020/3/4.
//

#import <Foundation/Foundation.h>
#import "TTDownloadTrackModel.h"
#import "TTDownloadMetaData.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TTDownloadEvent) {
    TTDownloadEventCreate,
    TTDownloadEventFirstStart,
    TTDownloadEventStart,
    TTDownloadEventPause,
    TTDownloadEventCancel,
    TTDownloadEventFinish,
    TTDownloadEventFailed,
    TTDownloadEventUncompleted,
};

@interface TTDownloadTracker : NSObject

@property (nonatomic, copy) TTDownloadEventBlock eventBlock;

+ (instancetype)sharedInstance;

- (void)sendFinishEventWithModel:(TTDownloadTrackModel *)model;

- (void)sendCancelEventWithModel:(TTDownloadTrackModel *)model;

- (void)sendFailEventWithModel:(TTDownloadTrackModel *)model failCode:(NSInteger)code failMsg:(NSString *)msg;

- (void)sendUncompleteEventWithModel:(TTDownloadTrackModel *)model;

- (void)sendEvent:(TTDownloadEvent)event eventModel:(TTDownloadTrackModel *)model;

@end

NS_ASSUME_NONNULL_END
