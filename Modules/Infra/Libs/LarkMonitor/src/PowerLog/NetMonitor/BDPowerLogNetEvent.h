//
//  BDPowerLogNetEvent.h
//  LarkMonitor
//
//  Created by ByteDance on 2022/9/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPowerLogNetEvent : NSObject

@property (nonatomic, assign) BOOL isPush;

@property (nonatomic, assign) BOOL isHeartBeat;

@property (nonatomic, assign) long long startTime;

@property (nonatomic, assign) long long endTime;

@property (nonatomic, assign) long long sysTime;

@property (nonatomic, assign) long long sendBytes;

@property (nonatomic, assign) long long recvBytes;

@property (nonatomic, copy) NSString *info;

@end

NS_ASSUME_NONNULL_END
