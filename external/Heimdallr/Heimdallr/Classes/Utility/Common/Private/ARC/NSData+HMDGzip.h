//
//  NSData+HMDGzip.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (HMDGzip)
- (NSData * _Nullable)hmd_gzipDeflate;
@end

NS_ASSUME_NONNULL_END
