//
//  BDBDConfiguration.m
//  BDDynamically
//
//  Created by zuopengliu on 3/6/2018.
//

#import "BDBDConfiguration.h"


#pragma mark - BDBDConfiguration

@interface BDBDConfiguration ()
@property (nonatomic, copy, readwrite) NSString *deviceId;
@property (nonatomic, copy, readwrite) NSString *installId;
@end

@implementation BDBDConfiguration

- (instancetype)init
{
    if ((self = [super init])) {
        _distArea = kBDDYCDeployAreaCN;
        _enableEnterForegroundRequest = YES;
    }
    return self;
}

@end
