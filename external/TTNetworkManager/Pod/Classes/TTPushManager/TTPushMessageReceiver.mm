//
//  TTPushMessageReceiver.m
//  TTPushManager
//
//  Created by gaohaidong on 1/17/17.
//  Copyright © 2017 bytedance. All rights reserved.
//

#import "TTPushMessageReceiver.hpp"
#import "TTNetworkManagerLog.h"

@implementation TTPushMessageReceiver

- (int32_t)dispatch:(const int32_t)service
             method:(const int32_t)method
    payloadEncoding:(const std::string &)payloadEncoding
        payloadType:(const std::string &)payloadType
            payload:(const std::string &)payload
              seqid:(const uint64_t)seqid
              logid:(const uint64_t)logid
            headers:(std::shared_ptr<std::map<std::string, std::string>>)headers {
    
    NSAssert(false, @"Should not call this, please implement it in sub class!");
    LOGE(@"Should not call this, please implement it in sub class!");
    return -1;
}

@end
