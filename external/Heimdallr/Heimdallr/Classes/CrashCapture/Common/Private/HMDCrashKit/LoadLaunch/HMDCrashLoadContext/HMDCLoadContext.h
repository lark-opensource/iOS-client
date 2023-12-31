//
//  HMDCLoadContext.h
//  Heimdallr
//
//  Created by sunrunwang on 2024/08/08.
//

#import <Foundation/Foundation.h>

#import "HMDCrashLoadMeta.h"
#import "HMDCrashLoadModel.h"
#import "HMDCrashLoadReport.h"
#import "HMDCrashLoadOption.h"
#import "HMDCrashLoadOption+Private.h"
#import "HMDCrashLoadBackgroundSession.h"

NS_ASSUME_NONNULL_BEGIN

@class HMDCrashLoadBackgroundSession;

@interface HMDCLoadContext : NSObject

#pragma mark - Option

@property(direct, nonatomic, nonnull, readonly) HMDCLoadOptionRef option;

#pragma mark - Prepared

@property(direct, nonatomic, nullable) NSFileManager *manager;

#pragma mark - Directory

@property(direct, nonatomic, nullable) NSString * trackerLastTime;
@property(direct, nonatomic, nullable) NSString * trackerActive;
@property(direct, nonatomic, nullable) NSString * trackerProcessing;

@property(direct, nonatomic, nullable) NSString * loadSafeGuard;
@property(direct, nonatomic, nullable) NSString * loadPending;
@property(direct, nonatomic, nullable) NSString * loadProcessing;
@property(direct, nonatomic, nullable) NSString * loadPrepared;
@property(direct, nonatomic, nullable) NSString * loadMirror;

@property(direct, nonatomic, nullable) NSString * currentDirectory;

#pragma mark - Process

@property(direct, nonatomic, nullable) HMDCrashLoadMeta  * meta;
@property(direct, nonatomic, nullable) HMDCrashLoadModel * model;
@property(direct, nonatomic, nullable) NSString * processPath;
@property(direct, nonatomic, nullable) NSString * processUUID;

#pragma mark - Upload
@property(direct, nonatomic, nullable) HMDCrashLoadBackgroundSession * session;
@property(direct, nonatomic, nullable) NSURL    * uploadingURL;
@property(direct, nonatomic, nullable) NSString * uploadingPath;
@property(direct, nonatomic, nullable) NSString * uploadingName;

#pragma mark - Report

@property(direct, nonatomic, nullable) HMDCrashLoadReport * report;

#pragma mark - Initialization

+ (instancetype _Nullable)contextWithOption:(HMDCLoadOptionRef)option;
- (instancetype _Nullable)init NS_UNAVAILABLE;
- (instancetype _Nullable)initWithOption:(HMDCLoadOptionRef)option
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
