//
//  EMADebuggerCommand.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/7/23.
//

#import "EMADebuggerCommand.h"
#import <ECOInfra/JSONValue+BDPExtension.h>

@interface EMADebuggerCommand()

@property (nonatomic, strong, readwrite) NSString *cmd;

@end

@implementation EMADebuggerCommand

- (instancetype)initWithCmd:(NSString *)cmd
{
    self = [super init];
    if (self) {
        self.cmd = cmd;
        _payload = @{};
    }
    return self;
}

- (NSString *)jsonMessage {
    NSMutableDictionary *dictionary = NSMutableDictionary.dictionary;
    dictionary[@"cmd"] = self.cmd;
    dictionary[@"mid"] = @(self.mid);
    dictionary[@"payload"] = self.payload;
    return dictionary.JSONRepresentation;
}

@end
