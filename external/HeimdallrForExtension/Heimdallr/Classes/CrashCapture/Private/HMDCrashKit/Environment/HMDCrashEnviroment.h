//
//  HMDCrashEnviroment.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/9.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#import <Foundation/Foundation.h>
#if !SIMPLIFYEXTENSION
#import "HMDCrashMetaData.h"
#endif

@interface HMDCrashEnviroment : NSObject

+ (void)setup;

+ (int)image_fd;

#if !SIMPLIFYEXTENSION
+ (HMDCrashMetaData *)currentMetaData;
#endif

@end
