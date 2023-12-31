//
//  BDPowerLogManager.h
//  Jato
//
//  Created by yuanzhangjing on 2022/7/25.
//

#import <Foundation/Foundation.h>
#import "BDPowerLogSession.h"
#import "BDPowerLogConfig.h"
#import "BDPowerLogManagerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPowerLogManager : NSObject

@property (nonatomic,class,weak) id<BDPowerLogManagerDelegate> delegate;

@property (atomic,class,copy) BDPowerLogConfig *config;

+ (BOOL)isRunning;

+ (void)start;

+ (void)stop;

//event

+ (void)beginEvent:(NSString *)event params:(NSDictionary * _Nullable)params; //for default session

+ (void)endEvent:(NSString *)event params:(NSDictionary * _Nullable)params; //for default session

+ (void)addEvent:(NSString *)event params:(NSDictionary * _Nullable)params; //for default session

//session

+ (BDPowerLogSession *)beginSession:(NSString *)name;

+ (BDPowerLogSession *)beginSession:(NSString *)name config:(BDPowerLogSessionConfig *)config;

+ (void)endSession:(BDPowerLogSession *)session;

+ (void)dropSession:(BDPowerLogSession *)session;

@end

NS_ASSUME_NONNULL_END
