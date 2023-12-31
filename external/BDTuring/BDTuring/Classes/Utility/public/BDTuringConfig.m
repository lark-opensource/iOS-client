//
//  BDTuringConfig.m
//  BDTuring
//
//  Created by bob on 2019/8/27.
//

#import "BDTuringConfig.h"
#import "BDTuringUtility.h"
#import "BDTuringVerifyModel.h"

@interface BDTuringConfig ()

@property (nonatomic, weak) BDTuringVerifyModel *model;

@end

@implementation BDTuringConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        self.regionType = BDTuringRegionTypeCN;
        self.channel = @"App Store";
    }
    
    return self;
}

@end
