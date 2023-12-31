//
//  BDEventForwarder.m
//  BDFlutterPluginManager
//
//  Created by 林一一 on 2019/11/6.
//

#import "BDFLEventForwarder.h"

@implementation BDFLEventForwarder {
    NSMutableDictionary *_events;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _events = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)setMessageChannel:(id)messageChannel WithName:(NSString *)name {
    [_events setValue:messageChannel forKey:name];
}

- (void)setMethodChannel:(id)methodChannel WithName:(NSString *)name {
    [_events setValue:methodChannel forKey:name];
}

- (void)setEventSink:(nullable BDFLEventSink)eventSink WithName:(NSString *)name {
    [_events setValue:eventSink forKey:name];
}

- (id<BDFLMessageChannelProtocol>)getMessageChannelWithName:(NSString *)name {
    id channel = [_events valueForKey:name];
    return (id<BDFLMessageChannelProtocol>)channel;
}

- (id<BDFLMethodChannelProtocol>)getMethodChannelWithName:(NSString *)name {
    id channel = [_events valueForKey:name];
    return (id<BDFLMethodChannelProtocol>)channel;
}

- (BDFLEventSink)getEventSinkWithName:(NSString *)name {
    id channel = [_events valueForKey:name];
    return (BDFLEventSink)channel;
}

@end
