//
//  BDPPermissionController.h
//  Timor
//
//  Created by CsoWhy on 2018/4/23.
//

#import "BDPBaseViewController.h"
#import <OPPluginManagerAdapter/BDPJSBridge.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPAuthorization.h>

@interface BDPPermissionController : BDPBaseViewController

- (instancetype)initWithAuthProvider:(BDPAuthorization *)provider;
- (instancetype)initWithCallback:(BDPJSBridgeCallback)callback authProvider:(BDPAuthorization *)provider;

@end
