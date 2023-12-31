//
//  TTVideoEngineEventOneOutSyncProtocol.h
//  Pods
//
//  Created by chibaowang on 2021/5/25.
//

#ifndef TTVideoEngineEventOneOutSyncProtocol_h
#define TTVideoEngineEventOneOutSyncProtocol_h

#import "TTVideoEngineEventBase.h"
#import "TTVideoEngineEventLoggerProtocol.h"

static NSInteger const VIDEO_OUTSYNC_KEY_PAUSE_TIME = 1;
static NSInteger const VIDEO_OUTSYNC_KEY_CROSSTALK_COUNT = 2;

@protocol TTVideoEngineEventOneOutSyncProtocol <NSObject>

@required
@property (nonatomic, weak) id<TTVideoEngineEventLoggerDelegate> delegate;
@property (nonatomic, assign) NSInteger avOutsyncCount;

- (instancetype)initWithEventBase:(TTVideoEngineEventBase*)base;

- (void)avOutsyncStart:(NSInteger) pts vt:(long long)vt lastSeekT:(UInt64)lastSeekT lastRebufT:(UInt64)lastRebufT;

- (NSDictionary *)avOutsyncEnd:(NSInteger) pts endType:(NSString*)endType;

- (void)setEnableMDL:(NSInteger) enable;

- (void)avOutsyncStartCallback;

- (void)avOutsyncEndCallback;

- (void)setValue:(id) value WithKey:(NSInteger) key;

- (void)onAVBadInterlaced;

@end

#endif /* TTVideoEngineEventOneOutSyncProtocol_h */
