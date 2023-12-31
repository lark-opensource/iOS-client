//
//  LKCException.h
//  LarkMonitor
//
//  Created by sniperj on 2020/1/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LKCustomExceptionConfig;
@interface LKCException : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, copy, readonly) NSArray<LKCustomExceptionConfig *> *modules;
- (void)setupCustomExceptionWithConfig:(NSDictionary *)config;
- (void)stopCustomException;

@end

NS_ASSUME_NONNULL_END
