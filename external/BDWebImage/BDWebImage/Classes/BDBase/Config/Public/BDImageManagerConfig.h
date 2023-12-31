//
//  BDImageManagerConfig.h
//  BDWebImageToB
//
//  Created by 陈奕 on 2020/6/17.
//

#import <Foundation/Foundation.h>
#if __has_include("BDWebImage.h")
#import "BDWebImage.h"
#else
#import "BDWebImageToB.h"
#endif
#import "BDWebImageStartUpConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDImageManagerConfig : NSObject

@property (nonatomic, copy) BDWebImageStartUpConfig *startUpConfig;

@property (nonatomic, assign) NSInteger monitorRate;

@property (nonatomic, assign) NSInteger errorMonitorRate;

@property (nonatomic, copy) NSArray<NSString *> *addedComponents;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *verifyErr;

// 对只读的文件设置成readonly，检查一下其他的属性有没有事只读的。
@property (nonatomic, copy, readonly) NSString *settingStr;
@property (nonatomic, copy, readonly) NSString *authCodesStr;

@property (nonatomic, assign) BOOL enabledHttpDNS;
@property (nonatomic, assign) BOOL enabledH2;
@property (nonatomic, copy) NSString *httpDNSAuthKey; // 云控下发的密钥
@property (nonatomic, copy) NSString *httpDNSAuthId;  // 云控下发的id
@property (nonatomic, copy) NSDictionary *TTNetDataDic;

@property (nonatomic, assign) BOOL enabledSR;

// 自适应策略
@property (nonatomic, copy) NSArray<NSString *> *animatedAdpativePolicies;  // 动图自适应策略，以后用
@property (nonatomic, copy) NSArray<NSString *> *staticAdpativePolicies;    // 静图自适应策略

+ (BDImageManagerConfig *)sharedInstance;

- (void)startFetchConfig;

@end

NS_ASSUME_NONNULL_END
