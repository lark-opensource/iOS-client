//
//  HMDCrashLoadModel.h
//  Heimdallr
//
//  Created by sunrunwang on 2024/08/08.
//

#import <Foundation/Foundation.h>
#import "HMDCrashThreadInfo.h"
#import "HMDCrashHeaderInfo.h"
#import "HMDCrashEnvironmentBinaryImages.h"

@interface HMDCrashLoadModel : NSObject

@property(direct, nonatomic, nullable) HMDImageOpaqueLoader *imageLoader;
@property(direct, nonatomic, nullable) HMDCrashHeaderInfo *headerInfo;
@property(direct, nonatomic, nullable) NSArray<HMDCrashThreadInfo *> *threads;

// Async stack backtrace for crash thread
@property(direct, nonatomic, nullable) HMDCrashThreadInfo *asyncRecord;
@property(direct, nonatomic, nullable) NSArray<NSString *> *queueNames;
@property(direct, nonatomic, nullable) NSArray<NSString *> *threadNames;

// CrashLog
@property(direct, nonatomic, nullable) NSString *crashLog;

// CrashDataDict
@property(direct, nonatomic, nullable) NSDictionary *dataDict;

// MultipartData
@property(direct, nonatomic, nullable) NSData *multipartData;

// gzipData
@property(direct, nonatomic, nullable) NSData *gzipData;

// successFlag
@property(direct, nonatomic) BOOL successFlag;

+ (instancetype _Nonnull)model;

@end
