//
//  HTSService.h
//  HTSServiceKit
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HTSServiceUnavailable <NSObject>

//@optional
// Please use onServiceInit instead of init
//- (instancetype)init NS_UNAVAILABLE;

@end

@protocol HTSService <HTSServiceUnavailable>

@optional
- (void)onServiceInit;

- (void)onServiceEnterBackground NS_DEPRECATED_IOS(1_0, 1_0, "Please use HTSModule");

- (void)onServiceEnterForeground NS_DEPRECATED_IOS(1_0, 1_0, "Please use HTSModule");

- (void)onServiceTerminate NS_DEPRECATED_IOS(1_0, 1_0, "Please use HTSModule");

- (BOOL)onServiceMemoryWarning NS_DEPRECATED_IOS(1_0, 1_0, "Please use HTSModule");

- (void)onServiceClearData NS_DEPRECATED_IOS(1_0, 1_0, "Please use HTSModule");

@end

@protocol HTSUniqService <HTSService>

+ (instancetype)sharedInstance;

@end

@protocol HTSInstService <HTSService>

@end


@interface HTSService : NSObject

@property (assign) BOOL isServiceRemoved;
@property (assign) BOOL isServicePersistent;

@end

NS_ASSUME_NONNULL_END
