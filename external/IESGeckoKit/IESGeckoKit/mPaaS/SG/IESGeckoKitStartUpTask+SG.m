//
//  IESGeckoKitStartUpTask+SG.m
//  IESGeckoKit
//
//  Created by bob on 2020/5/9.
//

#import "IESGeckoKitStartUpTask+SG.h"
#import <BDStartUp/BDStartUpGaia.h>
#import <IESGeckoKit/IESGurdConfig.h>

BDAppI18NConfigFunction() {
    [IESGurdConfig setPlatformDomainType:IESGurdPlatformDomainTypeSG];
    [IESGeckoKitStartUpTask sharedInstance];
}

@implementation IESGeckoKitStartUpTask (SG)

@end

