//
//  BDPChooseVideoModel.m
//  Timor
//
//  Created by zhysan on 2020/11/8.
//

#import "BDPChooseVideoModel.h"

@implementation BDPChooseVideoParam

- (nullable instancetype)initWithMaxDuration:(NSTimeInterval)maxDuration sourceType:(BDPVideoSourceType)sourceType fromController:(UIViewController *)fromController compressed:(BOOL)compressed outputFilePathWithoutExtention:(NSString *)outputFilePathWithoutExtention {
    if (!fromController || !outputFilePathWithoutExtention.length) {
        NSAssert(NO, @"from vc and path cannot be nil!");
        return nil;
    }
    self = [super init];
    if (self) {
        _maxDuration = maxDuration;
        _sourceType = sourceType;
        _fromController = fromController;
        _compressed = compressed;
        _outputFilePathWithoutExtention = outputFilePathWithoutExtention;
    }
    return self;
}

@end

@implementation BDPChooseVideoResult

+ (instancetype)resultWithCode:(BDPChooseVideoResultCode)code {
    BDPChooseVideoResult *ret = [[BDPChooseVideoResult alloc] init];
    ret.code = code;
    return ret;
}

@end
