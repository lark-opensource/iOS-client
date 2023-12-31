//
//  BDPPluginNetworkImpl.h
//  Timor
//
//  Created by yinyuan on 2018/12/18.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPNetworkPluginDelegate.h>

@interface BDPPluginNetworkImpl : NSObject<BDPNetworkPluginDelegate>

+ (BOOL)networkPluginBugfixFGDisabled;

+ (void)refreshNetworkPluginBugfixFGOnce;

@end
