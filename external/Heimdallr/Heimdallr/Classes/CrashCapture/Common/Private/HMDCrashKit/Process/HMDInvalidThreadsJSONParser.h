//
//  HMDInvalidThreadsJSONParser.h
//  Heimdallr
//
//  Created by xuminghao.eric on 2019/11/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDInvalidThreadsJSONParser : NSObject

- (NSDictionary *)parseInvalidThreadsJSONWithFile:(NSString *)jsonFilePath;

- (nullable NSDictionary *)parseInvalidThreadsJSONWithString:(NSString *)jsonString;

@end

NS_ASSUME_NONNULL_END
