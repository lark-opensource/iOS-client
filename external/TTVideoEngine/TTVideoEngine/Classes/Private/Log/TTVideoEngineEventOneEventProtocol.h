//
//  TTVideoEngineEventOneEventProtocol.h
//  Pods
//
//  Created by chibaowang on 2020/1/2.
//

#ifndef TTVideoEngineEventOneEventProtocol_h
#define TTVideoEngineEventOneEventProtocol_h

#import "TTVideoEngineEventBase.h"
#import "TTVideoEngineEventLoggerProtocol.h"

//const for end type
static NSString* const EVENT_END_TYPE_SEEK = @"seek";
static NSString* const EVENT_END_TYPE_SWITCH = @"switch";
static NSString* const EVENT_END_TYPE_EXIT = @"exit";
static NSString* const EVENT_END_TYPE_WAIT = @"wait";
static NSString* const EVENT_END_TYPE_ERROR = @"error";

static NSInteger const VIDEO_ONEEVENT_KEY_CROSSTALK_COUNT = 1;

@protocol TTVideoEngineEventOneEventProtocol <NSObject>

@required
@property (nonatomic, weak) id<TTVideoEngineEventLoggerDelegate> delegate;

- (instancetype)initWithEventBase:(TTVideoEngineEventBase*)base;

- (void)moviePreStall:(NSInteger)reason;

- (void)movieShouldRetry;

- (void)showedFirstFrame;

- (void)seekHappend;

- (void)movieStalled:(NSInteger)curPos;

- (NSDictionary *)movieStallEnd:(NSString*)reason;

- (long long)getAccuCostTime;

- (NSInteger) getMovieStalledReason;

- (void)onAVBadInterlaced;

- (void)setValue:(id) value WithKey:(NSInteger) key;

@end

#endif /* TTVideoEngineEventOneEventProtocol_h */
