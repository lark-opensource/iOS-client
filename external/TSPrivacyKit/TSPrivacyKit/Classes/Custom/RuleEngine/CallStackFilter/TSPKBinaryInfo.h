//
//  TSPKBinaryInfo.h
//  BDAlogProtocol
//
//  Created by bytedance on 2022/7/21.
//

#import <Foundation/Foundation.h>

@interface TSPKBinaryInfo : NSObject

+ (nullable instancetype)sharedInstance;

- (BOOL)fixSortedRules:(nullable NSArray *)rules;

- (NSUInteger)slideOfMachName:(nullable NSString *)machName;

@end
