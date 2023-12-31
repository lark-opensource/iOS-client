//
//  BDPTrackerEvent.h
//  Timor
//
//  Created by 维旭光 on 2018/12/9.
//

#import <Foundation/Foundation.h>

@interface BDPTrackerTimingEvent : NSObject

@property (nonatomic, assign) NSUInteger startTime; // 单位ms
@property (nonatomic, assign) NSUInteger duration; // 单位ms

- (void)start; // init会调用start
- (void)stop;
- (void)reset;
- (void)reStart;
- (BOOL)isStart;

@end


@interface BDPTrackerPageEvent : BDPTrackerTimingEvent

@property (nonatomic, copy) NSString *pagePath;
@property (nonatomic, assign) BOOL hasWebview;

- (instancetype)initWithPath:(NSString *)pagePath hasWebview:(BOOL)hasWebview;

@end

