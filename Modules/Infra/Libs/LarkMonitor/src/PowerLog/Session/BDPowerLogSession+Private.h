//
//  BDPowerLogSession+Private.h
//  Jato
//
//  Created by yuanzhangjing on 2022/7/26.
//

#import "BDPowerLogSession.h"

NS_ASSUME_NONNULL_BEGIN

@class BDPowerLogSession;
@class BDPowerLogInternalSession;

@protocol BDPowerLogInternalSessionDelegate <NSObject>

- (void)internalSessionDidStart:(BDPowerLogSession *)session
                internalSession:(BDPowerLogInternalSession *)internalSession;

- (void)internalSessionDidEnd:(BDPowerLogSession *)session
              internalSession:(BDPowerLogInternalSession *)internalSession;

@end

@interface BDPowerLogSession (Private)

@property (nonatomic,weak) id<BDPowerLogInternalSessionDelegate> delegate;

@property(nonatomic, copy, readwrite) BDPowerLogSessionConfig *config;

+ (instancetype)sessionWithName:(NSString *)name;

- (instancetype)initWithName:(NSString *)name;

- (void)begin;

- (void)end;

- (void)drop;

- (void)startInternalSession;

- (void)stopInternalSession;

- (long long)totalTime;

- (long long)internalSessionStartSysTime;

@end

NS_ASSUME_NONNULL_END
