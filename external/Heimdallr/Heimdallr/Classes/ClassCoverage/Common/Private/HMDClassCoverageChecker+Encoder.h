//
//  HMDClassCoverageChecker+Encoder.h
//  Heimdallr-30fca18e
//
//  Created by kilroy on 2020/6/14.
//

#import "HMDClassCoverageChecker.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDClassCoverageChecker (Encoder)

//将数据进行编码
+ (NSData * _Nullable)encodeIntoPBDataWithDict:(NSDictionary *)dic;

@end

NS_ASSUME_NONNULL_END
