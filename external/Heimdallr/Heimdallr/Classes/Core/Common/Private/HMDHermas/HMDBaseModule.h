//
//  HMDBaseModule.h
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 6/6/2022.
//

#import <Foundation/Foundation.h>
#import "HMDModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class HMModuleConfig;
@class HMDHeimdallrConfig;
@class HMDStoreCondition;
@protocol HMDStoreIMP;

@interface HMDBaseModule : NSObject<HMDMigrateProtocol, HMDExternalSearchProtocol>

@property (nonatomic, strong) HMModuleConfig *config;

@property (nonatomic, strong) HMDHeimdallrConfig *heimdallrConfig;

@property (nonatomic, strong) id<HMDStoreIMP> database;

@property (nonatomic, strong) NSMutableArray *operationRecords;

@property (nonatomic, strong, nullable) NSArray<HMDStoreCondition *> *debugRealCondition;

@property (nonatomic, assign) NSInteger recordThreadShareMask;

- (void)reportHeimdallrNeedUploadedData;

@end

NS_ASSUME_NONNULL_END
