//
//  SDWebImageManager+Monitor.h
//  BDWebImage
//
//  Created by Lin Yong on 2019/4/10.
//

#import <Foundation/Foundation.h>
#import <SDWebImage/SDWebImageManager.h>
#import "BDImageMonitor.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDWebImageManager(Monitor)

+ (BDImageMonitor *)monitor;

@end

NS_ASSUME_NONNULL_END
