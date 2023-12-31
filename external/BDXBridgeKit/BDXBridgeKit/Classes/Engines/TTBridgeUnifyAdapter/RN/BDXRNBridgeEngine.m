//
//  BDXRNBridgeEngine.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/9.
//

#import "BDXRNBridgeEngine.h"

@implementation BDXRNBridgeEngine

RCT_EXPORT_MODULE(BDXRNBridge);

- (NSArray<NSString *> *)supportedEvents
{
    return [super supportedEvents];
}

@end
