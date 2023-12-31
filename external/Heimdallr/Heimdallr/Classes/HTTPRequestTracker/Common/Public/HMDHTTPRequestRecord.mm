//
//  HMDHTTPRequestRecord.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/21.
//

#import "HMDHTTPRequestRecord.h"
#import <objc/runtime.h>

@implementation HMDHTTPRequestRecord
- (id)copyWithZone:(NSZone *)zone{
    HMDHTTPRequestRecord *model = [[[self class] allocWithZone:zone] init];
    
    model.error = self.error;
    model.request = self.request;
    model.response = self.response;
    model.responseData = self.responseData;
    model.startTime = self.startTime;
    model.endtime = self.endtime;
    model.dataLength = self.dataLength;
    model.connetType = self.connetType;
    model.logType = self.logType;
    model.dnsTime = self.dnsTime;
    model.connectTime = self.connectTime;
    model.sslTime = self.sslTime;
    model.sendTime = self.sendTime;
    model.waitTime = self.waitTime;
    model.receiveTime = self.receiveTime;
    model.isCached = self.isCached;
    model.isFromProxy = self.isFromProxy;
    model.protocolName = self.protocolName;
    model.isSocketReused = self.isSocketReused;
    model.scene = self.scene;
    model.format = self.format;
    model.isForeground = self.isForeground;
    model.redirectCount = self.redirectCount;
    model.redirectList = self.redirectList;
    model.sessionConnectReuse = self.sessionConnectReuse;
    model.sdkAid = self.sdkAid;
    model.enableUpload = self.enableUpload;
    model.aid = self.aid;
    model.hit_rule_tags = self.hit_rule_tags;
    model.tcpTime = self.tcpTime;
    model.requestSendTime = self.requestSendTime;
    model.responseRecTime = self.responseRecTime;
    model.baseApiAll = self.baseApiAll;
    model.netLogType = self.netLogType;
    model.injectTracelog = self.injectTracelog;
    model.requestScene = self.requestScene;
    model.requestBodyStreamLength = self.requestBodyStreamLength;

    return model;
}
@end
