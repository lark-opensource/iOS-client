//
//  TSPKSignalManager+pair.h
//  Musically
//
//  Created by ByteDance on 2022/11/17.
//

#import "TSPKSignalManager.h"


@interface TSPKSignalManager (pair)

/// add signal to manager, in order to help attribute issue eg: system api video open
/// - Parameters:
///   - usageType: pair api usage type, refer to TSPKAPIUsageType, only use start/stop/dealloc
///   - permissionType: equal to dataType
///   - content: info releated to signal
///   - instanceAddress: api instance address
+ (void)addPairSignalWithAPIUsageType:(TSPKAPIUsageType)usageType
                       permissionType:(nonnull NSString*)permissionType
                              content:(nonnull NSString*)content
                      instanceAddress:(nonnull NSString*)instanceAddress;


/// add signal to manager, in order to help attribute issue eg: system api video open
/// - Parameters:
///   - usageType: pair api usage type, refer to TSPKAPIUsageType, only use start/stop/dealloc
///   - permissionType: equal to dataType
///   - content: info releated to signal
///   - instance: api instance address
///   - extraInfo: ---
+ (void)addPairSignalWithAPIUsageType:(TSPKAPIUsageType)usageType
                       permissionType:(nonnull NSString*)permissionType
                              content:(nonnull NSString*)content
                             instance:(nonnull NSString*)instance
                            extraInfo:(nullable NSDictionary*)extraInfo;


/// get pair signal flow, start_time, end_time
/// - Parameters:
///   - permissionType: equal to dataType
///   - instanceAddress: api instance address
+ (nullable NSDictionary *)signalInfoWithPermissionType:(nonnull NSString *)permissionType
                                        instanceAddress:(nonnull NSString *)instanceAddress;

/// get pair signal flow, start_time, end_time
/// - Parameters:
///   - permissionType: equal to dataType
///   - instanceAddress: api instance address
///   - needFormatTime: need format time
+ (nullable NSDictionary *)signalInfoWithPermissionType:(nonnull NSString *)permissionType
                                        instanceAddress:(nonnull NSString *)instanceAddress
                                         needFormatTime:(BOOL)needFormatTime;

/// get pair signal flow, signal_start_time, signal_end_time without instance address
/// - Parameter permissionType: equal to dataType
+ (nullable NSDictionary *)pairSignalInfoWithPermissionType:(nonnull NSString *)permissionType;


/// get pair signal flow, signal_start_time, signal_end_time without instance address
/// - Parameters:
///   - permissionType: equal to dataType
///   - needFormatTime: need format time
+ (nullable NSDictionary *)pairSignalInfoWithPermissionType:(nonnull NSString *)permissionType
                                             needFormatTime:(BOOL)needFormatTime;

@end

