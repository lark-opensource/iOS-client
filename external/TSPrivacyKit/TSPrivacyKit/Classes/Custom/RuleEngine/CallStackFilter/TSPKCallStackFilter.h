//
//  TSPKCallStackFilter.h
//  BDAlogProtocol
//
//  Created by bytedance on 2022/7/21.
//

#import <Foundation/Foundation.h>

@interface TSPKCallStackFilter : NSObject

+ (nonnull instancetype)shared;

- (void)updateWithConfigs:(nonnull NSDictionary *)configs;

/// allow YES  not allow NO
- (BOOL)checkAllowCallWithDataType:(nonnull NSString *)dataType;

@end
