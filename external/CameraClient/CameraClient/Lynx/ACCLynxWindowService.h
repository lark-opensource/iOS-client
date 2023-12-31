//
//  ACCLynxWindowService.h
//  Aweme
//
//  Created by wanghongyu on 2021/11/8.
//

#import <Foundation/Foundation.h>

@protocol ACCLynxWindowService <NSObject>

- (nullable UIView *)showSchema:(nonnull NSString*)schema
                           data:(nullable NSDictionary *)data;

- (nullable UIView *)showSchema:(nonnull NSString*)schema
                           data:(nullable NSDictionary *)data
                  dismissAction:(nullable dispatch_block_t)dismissAction;

- (nullable UIView *)showSchema:(nonnull NSString*)schema
                           data:(nullable NSDictionary *)data
                          frame:(CGRect)frame;

@end

