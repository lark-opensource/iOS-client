//
//  BDPowerLogSession.h
//  Jato
//
//  Created by yuanzhangjing on 2022/7/26.
//

#import <Foundation/Foundation.h>
#import "BDPowerLogSessionConfig.h"
NS_ASSUME_NONNULL_BEGIN

@interface BDPowerLogSession : NSObject

@property(nonatomic, copy, readonly) NSString *sessionName;

@property(nonatomic, assign) BOOL autoUpload; //default YES

@property(nonatomic, assign) BOOL uploadWhenAppStateChanged; //default YES

@property(nonatomic, assign) BOOL ignoreBackground; //default NO

@property(nonatomic, assign) BOOL uploadWithExtraData; //default NO

@property(nonatomic, copy, readonly) BDPowerLogSessionConfig *config;

@property(atomic, copy) void(^logInfoCallback)(NSDictionary *logInfo,NSDictionary *extra);

- (void)addCustomFilter:(NSDictionary *)filter;

- (void)removeCustomFilter:(NSString *)key;

- (void)addCustomEvent:(NSDictionary *)event;

- (void)beginEvent:(NSString *)event params:(NSDictionary * _Nullable)params;

- (void)endEvent:(NSString *)event params:(NSDictionary * _Nullable)params;

- (void)addEvent:(NSString *)eventName params:(NSDictionary * _Nullable)params;

@end

NS_ASSUME_NONNULL_END
