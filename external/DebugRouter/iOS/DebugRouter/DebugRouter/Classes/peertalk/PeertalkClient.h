// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef PeertalkClient_h
#define PeertalkClient_h

#import "MessageTransceiver.h"
#import "PeertalkChannel.h"

@interface PeertalkClient : MessageTransceiver

@property(nonatomic, readwrite) int port;

- (id)init;
- (void)disconnect;
- (void)reconnect;
- (void)send:(id)data;
@end

#endif /* PeertalkClient_h */
