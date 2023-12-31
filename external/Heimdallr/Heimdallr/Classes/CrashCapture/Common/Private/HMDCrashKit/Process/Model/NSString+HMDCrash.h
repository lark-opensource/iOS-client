//
//  NSString+HMDCrash.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/9/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (HMDCrash)

- (NSString * _Nullable)hmdcrash_stringWithHex;

- (NSString * _Nullable)hmdcrash_cxxDemangledString;

@end

NS_ASSUME_NONNULL_END
