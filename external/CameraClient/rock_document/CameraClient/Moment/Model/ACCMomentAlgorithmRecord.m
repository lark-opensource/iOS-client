//
//  ACCMomentAlgorithmRecord.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/11/17.
//

#import "ACCMomentAlgorithmRecord.h"

@implementation ACCMomentAlgorithmRecord

- (instancetype)initWithOriginModel:(IESAlgorithmRecord *)originModel
{
    self = [super init];
    
    if (self) {
        _name = [originModel.name copy];
        _version = [originModel.version copy];
        _modelMD5 = [originModel.modelMD5 copy];
    }
    
    return self;
}

@end
