// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_BASE_LYNXPERFORMANCE_H_
#define DARWIN_COMMON_LYNX_BASE_LYNXPERFORMANCE_H_

#import <Foundation/Foundation.h>
@class LynxConfigInfo;

// The flag to mark it's ssr hydrate perf records.
static const int kLynxPerformanceIsSrrHydrateIndex = 20220425;

@interface LynxPerformance : NSObject

@property(nonatomic, assign, readonly) BOOL hasActualFMP;
@property(nonatomic, assign, readonly) double actualFMPDuration;
@property(nonatomic, assign, readonly) double actualFirstScreenEndTimeStamp;

- (instancetype _Nonnull)initWithPerformance:(NSDictionary* _Nonnull)dic
                                         url:(NSString* _Nonnull)url
                                  configInfo:(LynxConfigInfo* _Nonnull)configInfo;

- (NSDictionary* _Nonnull)toDictionary;

+ (NSString* _Nullable)toPerfKey:(int)index;
+ (NSString* _Nullable)toPerfKey:(int)index isSsrHydrate:(BOOL)isSsrHydrate;
+ (NSString* _Nullable)toPerfStampKey:(int)index;
@end

#endif  // DARWIN_COMMON_LYNX_BASE_LYNXPERFORMANCE_H_
