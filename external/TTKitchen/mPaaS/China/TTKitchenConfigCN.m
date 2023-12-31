//
//  TTKitchenConfigCN.m
//  BDStartUp
//
//  Created by bob on 2020/4/1.
//

#import "TTKitchenConfigCN.h"
#import "TTKitchenStartUpTask.h"
#import <BDStartUp/BDStartUpGaia.h>

BDAppCNConfigFunction() {
    [TTKitchenStartUpTask sharedInstance].settingsHost = @"https://is.snssdk.com";
}

@implementation TTKitchenConfigCN

@end
