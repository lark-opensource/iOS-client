//
//  BDTrackerProtocol+ET.h
//  BDTrackerProtocol
//
//  Created by bob on 2020/12/17.
//

#import "BDTrackerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTrackerProtocol (ET)

/**
 for ET to bind did and appid
 */
+ (void)loginETWithScheme:(NSString *)scheme;

@end

NS_ASSUME_NONNULL_END
