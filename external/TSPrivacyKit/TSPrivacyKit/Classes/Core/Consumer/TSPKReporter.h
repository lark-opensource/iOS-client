//
//  TSPKReporter.h
//  MT-Test
//
//  Created by admin on 2021/12/7.
//

#import <Foundation/Foundation.h>
#import "TSPKBaseEvent.h"

@protocol TSPKConsumer;

typedef BOOL (^TSPKCustomCanReportBuilder)(TSPKBaseEvent *_Nullable event);

@interface TSPKReporter : NSObject

+ (instancetype _Nonnull)sharedReporter;

- (void)registerCustomCanReportBuilder:(TSPKCustomCanReportBuilder _Nullable)builder;

- (void)addConsumer:(nullable id<TSPKConsumer>)consumer;

- (void)report:(nullable TSPKBaseEvent *)event;

@end
