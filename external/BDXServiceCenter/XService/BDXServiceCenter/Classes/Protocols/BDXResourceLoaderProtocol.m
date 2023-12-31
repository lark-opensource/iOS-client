//
//  BDXResourceLoaderProtocol.m
//  Bullet
//
//  Created by David on 2021/3/23.
//

#import "BDXResourceLoaderProtocol.h"

#pragma mark-- BDXResourceLoaderConfig

@implementation BDXResourceLoaderConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.gurdDownloadPrority = 2;
    }
    return self;
}

@end

#pragma mark-- BDXResourceLoaderProcessorConfig

@implementation BDXResourceLoaderProcessorConfig

@end

#pragma mark-- BDXResourceLoaderTaskConfig

@implementation BDXResourceLoaderTaskConfig

@end
