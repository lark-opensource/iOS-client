//
//  BDPBasePluginDelegate.h
//  Pods
//
//  Created by MacPu on 2018/11/3.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#ifndef BDPBasePluginDelegate_h
#define BDPBasePluginDelegate_h

#import <UIKit/UIKit.h>

@protocol BDPBasePluginDelegate <NSObject>

+ (id<BDPBasePluginDelegate>)sharedPlugin;

@end

#endif /* BDPBasePluginDelegate_h */
