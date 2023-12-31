//
//  HMDModuleProtocol.h
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 5/6/2022.
//

#import <Foundation/Foundation.h>

@class HMDHeimdallrConfig;
@class HMSearchParam;

@protocol HMDModuleProtocol <NSObject>
@required
- (void)setupModuleConfig;
- (void)updateModuleConfig:(HMDHeimdallrConfig *_Nullable)config;
@end


@protocol HMDMigrateProtocol <NSObject>
@required
- (void)migrateForward;
- (void)migrateBack;
@end

@protocol HMDExternalSearchProtocol <NSObject>
- (nullable NSArray *)getDataWithParam:(HMSearchParam *_Nonnull)param;
- (void)removeDataWithParam:(HMSearchParam *_Nonnull)param;
@end
