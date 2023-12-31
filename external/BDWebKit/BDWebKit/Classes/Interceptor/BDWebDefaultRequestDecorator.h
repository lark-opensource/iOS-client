//
//  BDWebDefaultRequestDecorator.h
//  BDWebKit
//
//  Created by yuanyiyang on 2020/5/12.
//

#import <Foundation/Foundation.h>
#import "BDWebRequestDecorator.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDWebDefaultRequestDecoratorDelegate <NSObject>

@optional
- (BOOL)bdw_shouldDecorateRequest:(NSURLRequest *)request;
- (NSString *)bdw_deviceId;
- (NSString *)bdw_appId;

@end

@interface BDWebDefaultRequestDecorator : NSObject<BDWebRequestDecorator>

/// make sure delegate set on the main thread.
@property (nonatomic, class, weak) id<BDWebDefaultRequestDecoratorDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
