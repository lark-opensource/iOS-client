//
//  TSPKSignalManager.h
//  Musically
//
//  Created by ByteDance on 2022/11/8.
//

#import <Foundation/Foundation.h>
#import "TSPKAPIModel.h"

typedef NS_ENUM(NSUInteger, TSPKSignalType) {
    TSPKSignalTypeSystemMethod = 1,
    TSPKSignalTypePairMethod = 2,
    TSPKSignalTypeCustom = 3,
    TSPKSignalTypeCommon = 4,
    TSPKSignalTypeGuard = 5,
    TSPKSignalTypeSystem = 6,
    TSPKSignalTypeLog = 7
};

typedef NS_ENUM(NSUInteger, TSPKCommonSignalType) {
    TSPKCommonSignalTypeApp,
    TSPKCommonSignalTypePage
};

/// It is used to collect and store signals, will return signal flow with specific permissionType
@interface TSPKSignalManager : NSObject

+ (instancetype _Nonnull)sharedManager;

- (void)setConfig:(nonnull NSDictionary *)config;

/// add signal to manager, in order to help attribute issue
/// - Parameters:
///   - signalType: refer to TSPKSignalType
///   - permissionType: equal to dataType
///   - content: info releated to signal
+ (void)addSignalWithType:(TSPKSignalType)signalType
            permissionType:(nonnull NSString *)permissionType
                  content:(nonnull NSString *)content;

/// add signal to manager, in order to help attribute issue
/// - Parameters:
///   - signalType: refer to TSPKSignalType
///   - permissionType: equal to dataType
///   - content: info releated to signal
///   - extraInfo: info releated to signal except content
+ (void)addSignalWithType:(TSPKSignalType)signalType
           permissionType:(nonnull NSString*)permissionType
                  content:(nonnull NSString*)content
                extraInfo:(nullable NSDictionary*)extraInfo;

/// add signal to manager, in order to help attribute issue
/// - Parameters:
///   - signalType: refer to TSPKSignalType
///   - permissionType: equal to dataType
///   - content: info releated to signal
///   - instanceAddress: api instance address
+ (void)addInstanceSignalWithType:(TSPKSignalType)signalType
                   permissionType:(nonnull NSString*)permissionType
                                    content:(nonnull NSString*)content
                  instanceAddress:(nonnull NSString*)instanceAddress;

/// add common signal, eg: app life cycle, viewController life cycle
/// - Parameters:
///   - signalType: refer to TSPKSignalType
///   - content: info releated to signal
+ (void)addCommonSignalWithType:(TSPKCommonSignalType)signalType
                            content:(nonnull NSString*)content;

/// add common signal, eg: app life cycle, viewController life cycle
/// - Parameters:
///   - signalType: refer to TSPKSignalType
///   - content: info releated to signal
///   - extraInfo: info releated to signal except content
+ (void)addCommonSignalWithType:(TSPKCommonSignalType)signalType
                        content:(nonnull NSString*)content
                      extraInfo:(nullable NSDictionary*)extraInfo;

/// get signal flow with permissionType
/// - Parameter permissionType: equal to dataType
+ (nullable NSArray *)signalFlowWithPermissionType:(nonnull NSString *)permissionType;

@end
