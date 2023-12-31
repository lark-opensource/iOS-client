//
//  HMDCrashLoadSync+Private.h
//  Heimdallr
//
//  Created by sunrunwang on 2024/08/08.
//

#import <Foundation/Foundation.h>
#import "HMDCrashLoadSync.h"
#import "HMDCLoadContext.h"

@interface HMDCrashLoadSync (Private)

@property(nonatomic, readwrite, nullable) NSString *mirrorPath;

@property(nonatomic, readwrite, nullable) NSString *currentDirectory;

@end
