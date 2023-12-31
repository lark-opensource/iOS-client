// Copyright 2019 The Vmsdk Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^JSModuleCallbackBlock)(id result);
typedef void (^JSModulePromiseResolveBlock)(id result);
typedef void (^JSModulePromiseRejectBlock)(NSString *code, NSString *message);

@protocol JSModule <NSObject>

/*! Module Name. */
@property(nonatomic, readonly, copy, class) NSString *name;

/*! Module methods look up table. The keys are JS method names, while values are
Objective C selectors.
///    - (NSDictionary<NSString *,NSString *> *)methodLookup {
///      return @{
///        @"voidFunc" : NSStringFromSelector(@selector(voidFunc)),
///        @"getNumber" : NSStringFromSelector(@selector(getNumber:)),
///      };
///    } */
@property(nonatomic, readonly, copy, class) NSDictionary<NSString *, NSString *> *methodLookup;

@optional
@property(nonatomic, readonly, copy, class) NSDictionary *attributeLookup;

@optional
- (instancetype)init;
- (instancetype)initWithParam:(id)param;

@end

NS_ASSUME_NONNULL_END
