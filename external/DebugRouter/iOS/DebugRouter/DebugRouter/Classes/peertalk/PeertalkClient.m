// Copyright 2021 The Lynx Authors. All rights reserved.

#import "PeertalkClient.h"
#import "DebugRouterLog.h"
#import "MessageTransceiver.h"
#import <Foundation/Foundation.h>

enum {
  PeertalkFrameTypeDeviceInfo = 100,
  PeertalkFrameTypeTextMessage = 101,
  PeertalkFrameTypePing = 102,
  PeertalkFrameTypePong = 103
};

typedef struct _PeertalkTextFrame {
  uint32_t length;
  uint8_t utf8text[0];
} PeertalkTextFrame;

static const int PORT = 8901;

@interface PeertalkClient () <PeertalkChannelDelegate>

{
  __weak PeertalkChannel *serverChannel_;
  __weak PeertalkChannel *peerChannel_;
}

@end

@implementation PeertalkClient

dispatch_data_t PeertalkTextDispatchDataWithString(NSString *message) {
  // Use a custom struct
  const char *utf8text = [message cStringUsingEncoding:NSUTF8StringEncoding];
  size_t length = strlen(utf8text);
  PeertalkTextFrame *textFrame =
      CFAllocatorAllocate(nil, sizeof(PeertalkTextFrame) + length, 0);
  memcpy(textFrame->utf8text, utf8text, length); // Copy bytes to utf8text array
  textFrame->length = htonl(length); // Convert integer to network byte order

  // Wrap the textFrame in a dispatch data object
  return dispatch_data_create((const void *)textFrame,
                              sizeof(PeertalkTextFrame) + length, nil, ^{
                                CFAllocatorDeallocate(nil, textFrame);
                              });
}

- (void)initServer {
  PeertalkChannel *channel = [PeertalkChannel channelWithDelegate:self];
  [self listen:channel];
}

- (void)listen:(PeertalkChannel *)channel {
  static int offset = 0;
  int port = PORT + offset;
  __weak typeof(self) _self = self;
  [channel
      listenOnPort:port
       IPv4Address:0
          callback:^(NSError *error) {
            __strong typeof(_self) strongSelf = _self;
            if (!error) {
              self.port = port;
              LLogWarn(@"[USB] listen on port %d", port);
              strongSelf->serverChannel_ = channel;
            } else {
              LLogWarn(@"[USB] Failed to listen on port %d: %@", port, error);
              offset++;
              if (offset < 20) {
                [strongSelf listen:channel];
              } else {
                LLogError(
                    @"[USB] Failed to listen, unable to support usb debugging");
              }
            }
          }];
}

- (id)init {
  self = [super init];
  if (self) {
    self.port = -1;
    [self initServer];
  }
  return self;
}

- (void)disconnect {
  [self->peerChannel_ cancel];
}

- (void)reconnect {
  [self disconnect];
  [self initServer];
}

- (void)send:(id)data {
  if (peerChannel_) {
    dispatch_data_t payload = PeertalkTextDispatchDataWithString(data);
    [peerChannel_
        sendFrameOfType:PeertalkFrameTypeTextMessage
                    tag:PeertalkFrameNoTag
            withPayload:(NSData *)payload
               callback:^(NSError *error) {
                 if (error) {
                   LLogError(@"[USB] Failed to send message: %@", error);
                 }
               }];
    LLogInfo(@"[USB] send: %@", data);
  } else {
    LLogError(@"[USB] Can not send message — not connected");
  }
}

#pragma mark - Communicating

- (void)sendDeviceInfo {
  if (!peerChannel_) {
    return;
  }

  LLogInfo(@"[USB] Sending device info over %@", peerChannel_);

  UIScreen *screen = [UIScreen mainScreen];
  CGSize screenSize = screen.bounds.size;
  NSDictionary *screenSizeDict =
      (__bridge_transfer NSDictionary *)CGSizeCreateDictionaryRepresentation(
          screenSize);
  UIDevice *device = [UIDevice currentDevice];
  NSDictionary *info = [NSDictionary
      dictionaryWithObjectsAndKeys:
          device.localizedModel, @"localizedModel",
          [NSNumber numberWithBool:device.multitaskingSupported],
          @"multitaskingSupported", device.name, @"name",
          (UIDeviceOrientationIsLandscape(device.orientation) ? @"landscape"
                                                              : @"portrait"),
          @"orientation", device.systemName, @"systemName",
          device.systemVersion, @"systemVersion", screenSizeDict, @"screenSize",
          [NSNumber numberWithDouble:screen.scale], @"screenScale", nil];
  dispatch_data_t payload = [info createReferencingDispatchData];
  [peerChannel_
      sendFrameOfType:PeertalkFrameTypeDeviceInfo
                  tag:PeertalkFrameNoTag
          withPayload:(NSData *)payload
             callback:^(NSError *error) {
               if (error) {
                 LLogError(@"[USB] Failed to send device info: %@", error);
               }
             }];
}

#pragma mark - PeertalkChannelDelegate

// Invoked to accept an incoming frame on a channel. Reply NO ignore the
// incoming frame. If not implemented by the delegate, all frames are accepted.
- (BOOL)ioFrameChannel:(PeertalkChannel *)channel
    shouldAcceptFrameOfType:(uint32_t)type
                        tag:(uint32_t)tag
                payloadSize:(uint32_t)payloadSize {
  if (channel != peerChannel_) {
    // A previous channel that has been canceled but not yet ended. Ignore.
    return NO;
  } else if (type != PeertalkFrameTypeTextMessage &&
             type != PeertalkFrameTypePing) {
    LLogInfo(@"[USB] Unexpected frame of type %u", type);
    return NO;
  } else {
    return YES;
  }
}

// Invoked when a new frame has arrived on a channel.
- (void)ioFrameChannel:(PeertalkChannel *)channel
    didReceiveFrameOfType:(uint32_t)type
                      tag:(uint32_t)tag
                  payload:(NSData *)payload {
  if (type == PeertalkFrameTypeTextMessage) {
    PeertalkTextFrame *textFrame = (PeertalkTextFrame *)payload.bytes;
    textFrame->length = ntohl(textFrame->length);
    NSString *message = [[NSString alloc] initWithBytes:textFrame->utf8text
                                                 length:textFrame->length
                                               encoding:NSUTF8StringEncoding];
    LLogInfo(@"[USB][%@]: %@", channel.userInfo, message);
    [self handleReceivedMessage:message];
  } else if (type == PeertalkFrameTypePing && peerChannel_) {
    [peerChannel_ sendFrameOfType:PeertalkFrameTypePong
                              tag:tag
                      withPayload:nil
                         callback:nil];
  }
}

// Invoked when the channel closed. If it closed because of an error, *error* is
// a non-nil NSError object.
- (void)ioFrameChannel:(PeertalkChannel *)channel
       didEndWithError:(NSError *)error {
  if (error) {
    LLogWarn(@"[USB] onFailure: %@", error);
    [self.delegate_ onFailure:self];
  } else {
    LLogWarn(@"[USB] onClosed: %@", channel.userInfo);
    [self.delegate_ onClosed:self];
  }
}

// For listening channels, this method is invoked when a new connection has been
// accepted.
- (void)ioFrameChannel:(PeertalkChannel *)channel
    didAcceptConnection:(PeertalkChannel *)otherChannel
            fromAddress:(PeertalkAddress *)address {
  LLogWarn(@"[USB] new client: %@", address);
  // Cancel any other connection. We are FIFO, so the last connection
  // established will cancel any previous connection and "take its place".
  [peerChannel_ cancel];

  // Weak pointer to current connection. Connection objects live by themselves
  // (owned by its parent dispatch queue) until they are closed.
  peerChannel_ = otherChannel;
  peerChannel_.userInfo = address;

  // Send some information about ourselves to the other end
  LLogWarn(@"[USB] onOpen");
  [self.delegate_ onOpen:self];
}

@end
