//
//  RCTRootView+BDXBridgeContainer.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/6.
//

#import "RCTRootView+BDXBridgeContainer.h"
#import "NSObject+BDXBridgeContainer.h"

@implementation RCTRootView (BDXBridgeContainer)

- (BDXBridgeEngineType)bdx_engineType
{
    return BDXBridgeEngineTypeRN;
}

@end
