//
//  TSPKReporter.m
//  MT-Test
//
//  Created by admin on 2021/12/7.
//

#import "TSPKReporter.h"
#import "TSPKOfflineToolConsumerProxy.h"
#import "TSPKUploadEventConsumerProxy.h"
#import "TSPKStatisticConsumerProxy.h"
#import "TSPKStatisticEvent.h"
#import "TSPKUtils.h"
#import "TSPKLock.h"


@interface TSPKReporter()

@property (nonatomic, copy) TSPKCustomCanReportBuilder customCanReportBuilder;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray <id<TSPKConsumer>>*> *consumerDict;
@property (nonatomic, strong) id<TSPKLock> lock;

@end

@implementation TSPKReporter

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = [TSPKLockFactory getLock];
        _consumerDict = [NSMutableDictionary dictionary];
        [self addConsumer:[TSPKOfflineToolConsumerProxy sharedConsumer]]; // must put in first
        [self addConsumer:[TSPKUploadEventConsumerProxy sharedConsumer]];
        [self addConsumer:[TSPKStatisticConsumerProxy sharedConsumer]];
    }
    return self;
}

- (void)registerCustomCanReportBuilder:(TSPKCustomCanReportBuilder)builder {
    self.customCanReportBuilder = builder;
}

- (void)addConsumer:(id<TSPKConsumer>)consumer {
    if (consumer) {
        [_lock lock];
        if (self.consumerDict[consumer.tag] == nil) {
            self.consumerDict[consumer.tag] = [NSMutableArray array];
        }
        [self.consumerDict[consumer.tag] addObject:consumer];
        [_lock unlock];
    }
}

+ (instancetype)sharedReporter
{
    static TSPKReporter *reporter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        reporter = [[TSPKReporter alloc] init];
    });
    return reporter;
}

- (void)report:(TSPKBaseEvent *)event {
    if (self.customCanReportBuilder && !self.customCanReportBuilder(event)) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.lock lock];
        for (id<TSPKConsumer> consumer in self.consumerDict[event.tag]) {
            [consumer consume:event];
        }
        [self.lock unlock];
    });
}

@end
