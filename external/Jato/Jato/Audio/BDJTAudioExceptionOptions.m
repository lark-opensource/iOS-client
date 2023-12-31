//
//  BDJAudioExceptionOptions.m
//  Jato
//
//  Created by yuanzhangjing on 2021/12/2.
//

#import "BDJTAudioExceptionOptions.h"

@implementation BDJTAudioExceptionOptions

- (instancetype)init {
    if (self = [super init]) {
        self.fixAll = YES;
        self.fixType = BDJTAudioFixTypeDisposeDelay;
    }
    return self;
}

@end
