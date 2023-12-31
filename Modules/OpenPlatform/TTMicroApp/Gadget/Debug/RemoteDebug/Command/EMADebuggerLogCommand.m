//
//  EMADebuggerLogCommand.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/7/23.
//

#import "EMADebuggerLogCommand.h"

@implementation EMADebuggerLogCommand

- (instancetype)init
{
    self = [super initWithCmd:@"log"];
    if (self) {
    
    }
    return self;
}

- (NSDictionary *)payload {
    NSMutableDictionary *dictionary = NSMutableDictionary.dictionary;
    dictionary[@"timestamp"] = self.timestamp;
    dictionary[@"layer"] = @"app";
    dictionary[@"level"] = self.level;
    dictionary[@"appId"] = self.appId;
    dictionary[@"tag"] = self.tag;
    dictionary[@"content"] = self.content;
    dictionary[@"appName"] = self.appName;
    return dictionary.copy;
}

@end
