//
//  HMDExcludeModuleHelper.h
//  Heimdallr
//
//  Created by sunrunwang on 2019/4/16.
//
// thread-safe : YES
// self-contained : YES
// After added dependency call this method there is NO need to keep this class

#import <Foundation/Foundation.h>
#import "HMDExcludeModule.h"

typedef void (^HMDExcludeModuleCallback)(void);

typedef enum : NSUInteger {
    HMDExcludeModuleDependencyFinish,
    HMDExcludeModuleDependencySuccess,
    HMDExcludeModuleDependencyFailure,
} HMDExcludeModuleDependency;

NS_ASSUME_NONNULL_BEGIN

@interface HMDExcludeModuleHelper : NSObject

/// Pass nil means disable that kindof callback
/// one or no callback will eventually be called
- (instancetype)initWithSuccess:(HMDExcludeModuleCallback _Nullable)successCallback
                        failure:(HMDExcludeModuleCallback _Nullable)failureCallback
                        timeout:(HMDExcludeModuleCallback _Nullable)timeoutCallback;

/// If not class at runtime this contribute to success callback
/// If this class does not conforms to protocol HMDExcludeModule
/// In DEBUG Assert raised, In RELEASE ignore this class, this contribute to success callback
- (void)addRuntimeClassName:(NSString *)className forDependency:(HMDExcludeModuleDependency)dependency;

/// If this class does not conforms to protocol HMDExcludeModule
/// In DEBUG Assert raised, In RELEASE ignore this class, this contribute to success callback
- (void)addClass:(Class<HMDExcludeModule>)aClass forDependency:(HMDExcludeModuleDependency)dependency;

/// After added dependency call this method
/// This method should not called for twice
/// there is no need to retain HMDExcludeModuleHelper after this method, HMDExcludeModuleHelper will retain itself during detection and auto release itself after detection
- (void)startDetection;

/// After detection end, verify module's detection result with className. Return YES when className is valid, NO if className is invalid
/// - Parameters:
///   - className: moudle class name
///   - res_output: *res_out = YES when detected, NO means not detected
+ (BOOL)verifyExcludeModuleResultWithRuntimeClassName:(NSString* _Nullable)className
                                                  res:(BOOL* _Nonnull) res_output DEPRECATED_ATTRIBUTE;

+ (id<HMDExcludeModule> _Nullable)excludeModuleForRuntimeClassName:(NSString *)className;

/// Only setted before startDetection is accepted
@property(atomic, assign, readwrite) NSTimeInterval timeout;

@property(atomic, assign, readonly, getter=isStarted) BOOL started;

@property(atomic, assign, readonly, getter=isFinshed) BOOL finished;

@end

NS_ASSUME_NONNULL_END
