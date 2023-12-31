//
//  EMADebuggerMetaCommand.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/7/29.
//

#import "EMADebuggerMetaCommand.h"

@implementation EMADebuggerMetaCommand

- (instancetype)init
{
    self = [super initWithCmd:@"set_connection_meta_info"];
    if (self) {

    }
    return self;
}

- (NSDictionary *)payload {
    NSMutableDictionary *dictionary = NSMutableDictionary.dictionary;
    dictionary[@"phoneBrand"] = self.phoneBrand;
    dictionary[@"appName"] = self.appName;
    dictionary[@"appId"] = self.appId;
    return dictionary.copy;
}

@end
