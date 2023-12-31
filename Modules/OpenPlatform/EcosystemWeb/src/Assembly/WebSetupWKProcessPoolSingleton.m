//
//  WebSetupWKProcessPoolSingleton.m
//  EcosystemWeb
//
//  Created by 新竹路车神 on 2022/1/25.
//

#import "WebSetupWKProcessPoolSingleton.h"
#import <EcosystemWeb/EcosystemWeb-Swift.h>
#import <LKLoadable/Loadable.h>

LoadableMainFuncBegin(webSetupWKProcessPoolSingleton)
[WKProcessPoolSingletonTool singleton];
LoadableMainFuncEnd(webSetupWKProcessPoolSingleton)

@implementation WebSetupWKProcessPoolSingleton

@end
