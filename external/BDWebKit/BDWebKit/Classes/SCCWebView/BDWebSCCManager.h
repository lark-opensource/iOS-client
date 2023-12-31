//
//  BDWebSCCManager.h
//  Pods
//
//  Created by bytedance on 6/20/22.
//
#import "BDSCCDomainListLRU.h"

#ifndef BDSCCLog
#define BDSCCLog(...) BDALOG_PROTOCOL_TAG(kLogLevelInfo, @"BDWebKitSCCLog", __VA_ARGS__);
#endif

NS_ASSUME_NONNULL_BEGIN

@interface BDWebSCCManager : NSObject

+ (instancetype)shareInstance;

@property (nullable, nonatomic, strong) NSUserDefaults *storageList;

@property (nullable, nonatomic, strong) BDSCCLRUMutableDictionary *domainList;

@property (nullable, atomic, strong) NSString *scc_hips_rule_version;

@property (nonatomic, assign) NSInteger maxWaitTime;

@property (nonatomic, assign) NSInteger maxReloadCount;

@end

NS_ASSUME_NONNULL_END
