//
//  HMDProtectCatch.h
//  Heimdallr
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDProtectCatch : NSObject

+ (instancetype)sharedInstance;

- (void)registCallback:(void(^)(NSException *, NSDictionary *))callback;

- (void)catchMethodsWithNames:(NSArray<NSString *> *)names;

@end

NS_ASSUME_NONNULL_END
