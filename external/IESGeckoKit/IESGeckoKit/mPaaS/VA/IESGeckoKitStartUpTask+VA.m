//
//  IESGeckoKitStartUpTask+VA.m
//  IESGeckoKit
//
//  Created by bob on 2020/5/9.
//

#import "IESGeckoKitStartUpTask+VA.h"
#import <BDStartUp/BDStartUpGaia.h>
#import <IESGeckoKit/IESGurdConfig.h>

BDAppI18NConfigFunction() {
    [IESGurdConfig setPlatformDomainType:IESGurdPlatformDomainTypeVA];
    [IESGeckoKitStartUpTask sharedInstance];
}

@implementation IESGeckoKitStartUpTask (VA)

@end

