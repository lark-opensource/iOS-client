//
//  LKCExceptionBase.h
//  LarkMonitor
//
//  Created by sniperj on 2019/12/31.
//

#import <Foundation/Foundation.h>
#import "LKCustomExceptionConfig.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LKCExceptionProtocol <NSObject>

@required
@property (atomic, assign, readonly) BOOL isRunning;
@property (atomic, strong, readonly) LKCustomExceptionConfig *config;
- (void)start;
- (void)end;
- (void)updateConfig:(LKCustomExceptionConfig *)config;

@end

@interface LKCExceptionBase : NSObject<LKCExceptionProtocol>

@end

NS_ASSUME_NONNULL_END
