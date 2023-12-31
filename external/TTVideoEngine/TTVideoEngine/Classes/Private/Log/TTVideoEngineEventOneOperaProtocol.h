//
//  TTVideoEngineEventOneOperaProtocol.h
//  Pods
//
//  Created by chibaowang on 2020/1/2.
//

#ifndef TTVideoEngineEventOneOperaProtocol_h
#define TTVideoEngineEventOneOperaProtocol_h

#import "TTVideoEngineEventBase.h"
#import "TTVideoEngineEventLoggerProtocol.h"

//const for end type
static const NSString* OPERA_END_TYPE_SEEK = @"seek";
static const NSString* OPERA_END_TYPE_SWITCH = @"switch";
static const NSString* OPERA_END_TYPE_EXIT = @"exit";
static const NSString* OPERA_END_TYPE_WAIT = @"wait";
static const NSString* OPERA_END_TYPE_ERROR = @"error";

//const for opera type
static const NSString* OPERA_TYPE_SEEK = @"seek";
static const NSString* OPERA_TYPE_SWITCH = @"switch";

//const for report control
static const NSInteger OPERA_REPORT_SEEK = 0x0001;
static const NSInteger OPERA_REPORT_SWITCH = 0x0002;


@protocol TTVideoEngineEventOneOperaProtocol <NSObject>

@required
@property (nonatomic, weak) id<TTVideoEngineEventLoggerDelegate> delegate;
//By default, opera events are not reported
@property (nonatomic, assign) NSInteger reportLevel;

- (instancetype)initWithEventBase:(TTVideoEngineEventBase*)base;

- (void)moviePlayRetryWithError:(NSError *)error strategy:(TTVideoEngineRetryStrategy)strategy apiver:(TTVideoEnginePlayAPIVersion)apiver;

- (void)seekToTime:(NSTimeInterval)fromPos toPos:(NSTimeInterval)toPos;

- (NSDictionary *)endSeek:(NSString*)reason isSeekInCache:(NSInteger)isSeekInCache;

@end

#endif /* TTVideoEngineEventOneOperaProtocol_h */
