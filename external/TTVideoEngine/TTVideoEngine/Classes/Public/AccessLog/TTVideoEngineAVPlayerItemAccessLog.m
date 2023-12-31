//
//  TTAVPlayerItemAccessLog.m
//  Article
//
//  Created by panxiang on 16/10/26.
//
//

#import "TTVideoEngineAVPlayerItemAccessLog.h"

@interface TTVideoEngineAVPlayerItemAccessLog ()
@property (nonatomic) NSMutableArray *eventArray;
@end

@implementation TTVideoEngineAVPlayerItemAccessLog
- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)addEvent:(TTVideoEngineAVPlayerItemAccessLogEvent *)event
{
    @synchronized (self) {
        if (!self.eventArray) {
            self.eventArray = [NSMutableArray array];
        }
        if (![self.eventArray containsObject:event] && event != nil) {
            [self.eventArray insertObject:event atIndex:0];
        }
    }
}

- (NSArray<TTVideoEngineAVPlayerItemAccessLogEvent *> *)events {
    if (self.accessLog) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.accessLog.events.count];
        for (AVPlayerItemAccessLogEvent *logEvent in self.accessLog.events) {
            TTVideoEngineAVPlayerItemAccessLogEvent *event = [[TTVideoEngineAVPlayerItemAccessLogEvent alloc] init];
            event.URI = logEvent.URI;
            event.serverAddress = logEvent.serverAddress;
            event.durationWatched = logEvent.durationWatched;
            [array addObject:event];
        }
        return array;
    } else {
        NSArray *temEvents = nil;
        @synchronized (self) {
            temEvents = self.eventArray.copy;
        }
        return temEvents;
    }

    return nil;
}

- (void)clearEvent
{
    @synchronized (self) {
        [_eventArray removeAllObjects];
    }
}
@end
