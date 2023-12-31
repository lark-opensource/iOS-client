//
//  OPAPIConfig.m
//  Timor
//
//  Created by lixiaorui on 2020/12/25.
//

#import "OPAPIFeatureConfig.h"

@interface OPAPIFeatureConfig ()

@property (nonatomic, assign, readwrite) OPAPIFeatureCommand apiCommand;

@end

@implementation OPAPIFeatureConfig

- (instancetype)initWithCommandString:(NSString *)command {
    self = [super init];
    if (self) {
        if ([command isEqualToString:@"useOld"]) {
            self.apiCommand = OPAPIFeatureCommandUseOld;
        } else if ([command isEqualToString:@"doNotUse"]) {
            self.apiCommand = OPAPIFeatureCommandDoNotUse;
        } else if ([command isEqualToString:@"removeOld"]) {
            self.apiCommand = OPAPIFeatureCommandRemoveOld;
        } else if ([command isEqualToString:@"restore"]) {
            self.apiCommand = OPAPIFeatureCommandRestore;
        } else {
            self.apiCommand = OPAPIFeatureCommandUnknown;
        }
    }
    return self;
}

@end
