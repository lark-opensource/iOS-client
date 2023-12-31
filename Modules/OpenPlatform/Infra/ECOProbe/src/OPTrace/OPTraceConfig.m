//
//  OPTraceConfig.m
//  LarkOPInterface
//
//  Created by changrong on 2020/9/14.
//

#import "OPTraceConfig.h"

@interface OPTraceConfig()
@property (nonatomic, copy, readwrite) GenerateNewTrace generator;
@property (nonatomic, copy, readwrite) NSString *prefix;
@end

@implementation OPTraceConfig

- (instancetype)initWithPrefix:(NSString *)prefix
                     generator:(GenerateNewTrace)generator {
    self = [super init];
    if (self) {
        self.prefix = prefix;
        self.generator = generator;
    }
    return self;
}
@end
