//
//  BDPAuthModule.h
//  Timor
//
//  Created by yin on 2020/4/2.
//

#import <OPFoundation/BDPAuthModuleProtocol.h>

@interface BDPAuthModule : NSObject <BDPAuthModuleProtocol>

@end

@interface BDPAuthModuleControllerProvider: NSObject<BDPAuthorizationDelegate>

@property (nonatomic, weak, nullable) UIViewController *controller;

@end
