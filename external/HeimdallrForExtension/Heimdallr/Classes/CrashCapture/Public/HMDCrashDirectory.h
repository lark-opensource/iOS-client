//
//  HMDCrashDirectory.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/9.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HMDCrashDirectory : NSObject

+ (void)setup;

@end

@interface HMDCrashDirectory (Path)

@property(class, readonly, atomic, nullable) NSString *UUID;

@property(class, readonly, atomic, nullable) NSString *baseDirectory;

@property(class, readonly, atomic, nullable) NSString *preparedDirectory;

@property(class, readonly, atomic, nullable) NSString *processingDirectory;

@property(class, readonly, atomic, nullable) NSString *activeDirectory;

@property(class, readonly, atomic, nullable) NSString *currentDirectory;

@property(class, readonly, atomic, nullable) NSString *eventDirectory;

+ (BOOL)checkAndMarkLaunchState;

+ (void)removeLaunchState;

@end
