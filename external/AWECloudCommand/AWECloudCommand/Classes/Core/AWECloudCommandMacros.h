//
//  AWECloudCommandMacros.h
//  Pods
//
//  Created by Stan Shan on 2018/8/27.
//

#import <Foundation/Foundation.h>
#import "AWECloudCommandModel.h"

static NSString *const kAWECloudCommandSDKVersion = @"1.0.7";

#define AWESAFEBLOCK_INVOKE(block, ...) block ? block(__VA_ARGS__) : nil

#define AWE_REGISTER_CLOUD_COMMAND(command_name) \
+ (void)load { AWECloudCommandRegisterCommand(command_name, self); }
