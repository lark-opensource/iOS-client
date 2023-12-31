//
//  TTPushMessageDispatcher.m
//  TTPushManager
//
//  Created by gaohaidong on 7/10/16.
//  Copyright © 2016 bytedance. All rights reserved.
//

#import "TTPushMessageDispatcher.h"

// Github: google/protobuf/issues/549
// StackOverflow: questions/15759559/variable-named-type-boolc-code-is-conflicted-with-ios-macro
// TYPE_BOOL is defined in the MacOS's ConditionalMacros.h.
#ifdef TYPE_BOOL
#undef TYPE_BOOL
#endif  // TYPE_BOOL

#import "net/tt_net/websocket/pbbp2.pb.h"
#import "TTPushManager.h"
#import "TTNetworkDefine.h"
#import "TTPushMessageBaseObject.h"
#import "TTNetworkManagerLog.h"

@interface TTPushMessageDispatcher ()

// prevent server send duplicated message
@property (atomic, assign) BOOL isTheFirstMessage;
@property (atomic, assign) uint64_t lastMsgSequenceId;

@property (atomic, strong) TTPushMessageReceiver *msgReceiver;

@property (atomic, assign) BOOL isBroadcasting;

@end

@implementation TTPushMessageDispatcher

#pragma  mark - life cycle

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.isTheFirstMessage = YES;
        self.isBroadcasting = YES;
    }
    return self;
}

#pragma mark - public functions

- (void)dispatchMessage:(const std::string &)payload {
    
    pbbp2::Frame frame;
    auto ret = frame.ParseFromString(payload);
    
    if (ret) {
        if ([self receivedDuplicatedMessage:frame]) {
            return;
        }
        self.lastMsgSequenceId = frame.seqid();
        
        // Route to specific API according to the frame type
        std::shared_ptr<std::map<std::string, std::string>> headers = nullptr;
        if (frame.headers_size() > 0) {
            headers = std::make_shared<std::map<std::string, std::string>>();
            
            for (int i = 0; i < frame.headers_size(); ++i) {
                const auto &header = frame.headers(i);
                (*headers)[header.key()] = header.value();
            }
        }
        
        int32_t ret = -1;
        if (self.msgReceiver) {

            LOGD(@"use customized message dispatcher.");
            ret = [self.msgReceiver dispatch:frame.service() method:frame.method() payloadEncoding:frame.payload_encoding() payloadType:frame.payload_type() payload:frame.payload() seqid:frame.seqid() logid:frame.logid() headers:headers];
        }
        
        if (ret < 0) {
            [self handleUnknownMessage_:frame];
        }

        if (self.isBroadcasting) {
            [self broadcastReceivingMessage_:frame];
        }
        
    } else {
        LOGW(@"%s:%s", __FUNCTION__, "Can not parse the protobuf message, skip it.");
    }
}

- (void)delegateMessage:(const std::string &)message pushManager:(TTPushManager *)pushManager {
    pbbp2::Frame frame;
    auto ret = frame.ParseFromString(message);
    if (ret) {
        if ([self receivedDuplicatedMessage:frame]) {
            return;
        }
        self.lastMsgSequenceId = frame.seqid();
        
        PushMessageBaseObject *msg = [[PushMessageBaseObject alloc] init];
        [self.class assignMessageBaseProperties_:msg frame:frame];
        [pushManager.delegate onFrontierMessageReceived:pushManager message:msg];
    } else {
        LOGW(@"%s:%s", __FUNCTION__, "Can not parse the protobuf message, skip it.");
    }
}

- (void)setCustomizedMessageReceiver:(TTPushMessageReceiver *)messageReceiver {
    self.msgReceiver = messageReceiver;
}

- (void)setBroadcastingMessage:(BOOL)value {
    self.isBroadcasting = value;
}

+ (NSData *)serializeObject:(PushMessageBaseObject *)message {
  if (message) {
    pbbp2::Frame frame;
    frame.set_seqid(message.sequenceId);
    frame.set_logid(message.logId);
    frame.set_method(message.method);
    frame.set_service(message.service);
    frame.set_payload((char*)message.payload.bytes, message.payload.length);
    frame.set_payload_type(CPPSTR(message.payloadType));
    frame.set_payload_encoding(CPPSTR(message.payloadEncoding));

    if (message.headers && message.headers.count > 0) {
      for (NSString *key in message.headers) {
        if (![key isKindOfClass:NSString.class]) {
          NSAssert(NO, @"Header key type must be NSString!");
          continue;
        }

        std::string value;

        id v = message.headers[key];
        if ([v isKindOfClass:NSString.class]) {
          value = CPPSTR(((NSString *)v));
        } else if ([v isKindOfClass:NSNumber.class]) {
          value = CPPSTR([(NSNumber *)v stringValue]);
        } else {
          NSAssert(NO, @"Header value type is wrong!");
          continue;
        }

        auto h = frame.mutable_headers()->Add();
        h->set_key(CPPSTR(key));
        h->set_value(value);
      }
    }

    std::string str;
    BOOL isSucess = frame.SerializePartialToString(&str);
    if (isSucess) {
      NSData *data = [NSData dataWithBytes:str.data() length:str.length()];
      return data;
    } else {
      LOGE(@"PB message serialization failed!");
    }
    return nil;
  } else {
    NSAssert(false, @"Message must not be nil.");
    return nil;
  }
}

#pragma mark - private functions

- (void)handleUnknownMessage_:(const pbbp2::Frame &)frame {
    PushMessageBaseObject *msg = [[PushMessageBaseObject alloc] init];
    
    [self.class assignMessageBaseProperties_:msg frame:frame];
    
    NSDictionary *userInfo = @{kTTPushManagerUnknownPushMessageUserInfoKey: msg};
    
    // NOTE! NSNotification is not in MAIN thread!
    [[NSNotificationCenter defaultCenter] postNotificationName:kTTPushManagerUnknownPushMessage object:nil userInfo:userInfo];
}

- (void)broadcastReceivingMessage_:(const pbbp2::Frame &)frame {
    PushMessageBaseObject *msg = [[PushMessageBaseObject alloc] init];

    [self.class assignMessageBaseProperties_:msg frame:frame];

    NSDictionary *userInfo = @{kTTPushManagerOnReceivingMessageUserInfoKey: msg};

    // NOTE! NSNotification is not in MAIN thread!
    [[NSNotificationCenter defaultCenter] postNotificationName:kTTPushManagerOnReceivingMessage object:nil userInfo:userInfo];
}

- (bool)receivedDuplicatedMessage:(const pbbp2::Frame &)frame {
    LOGD(@"%s: seq id = %lld, log id = %lld, service id = %d, method = %d", __FUNCTION__, frame.seqid(), frame.logid(), frame.service(), frame.method());
    if (self.isTheFirstMessage) {
        self.isTheFirstMessage = NO;
    } else {
        if (self.lastMsgSequenceId == frame.seqid()) {
            LOGW(@"%s:%s, seq_id = %lld, log_id = %lld", __FUNCTION__, "got a duplicated message, skip it.", frame.seqid(), frame.logid());
            return YES;
        }
    }
    
    return NO;
}

+ (void)assignMessageBaseProperties_:(PushMessageBaseObject *)msg frame:(const pbbp2::Frame &)frame {
  msg.sequenceId = frame.seqid();
  msg.logId = frame.logid();
  msg.method = frame.method();
  msg.service = frame.service();
  msg.payload = [[NSData alloc] initWithBytes:frame.payload().data() length:frame.payload().length()];
  msg.payloadType = @(frame.payload_type().c_str());
  msg.payloadEncoding = @(frame.payload_encoding().c_str());

  if (frame.headers_size() > 0) {
    NSMutableDictionary<NSString *, NSString *> *headers = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < frame.headers_size(); ++i) {
      const auto &header = frame.headers(i);
      if (header.has_key() && header.has_value()) {
        headers[@(header.key().c_str())] = @(header.value().c_str());
      }
    }
    msg.headers = headers;
  }

}

@end
