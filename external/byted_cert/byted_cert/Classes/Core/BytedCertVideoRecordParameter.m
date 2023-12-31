//
//  BytedCertVideoRecordParameter.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/18.
//

#import "BytedCertVideoRecordParameter.h"


@implementation BytedCertVideoRecordParameter

- (instancetype)init {
    self = [super init];
    if (self) {
        _msPerWord = 500;
    }
    return self;
}

- (double)totalReadDurationInSeconds {
    return self.readText.length * self.msPerWord / 1000.0;
}

@end
