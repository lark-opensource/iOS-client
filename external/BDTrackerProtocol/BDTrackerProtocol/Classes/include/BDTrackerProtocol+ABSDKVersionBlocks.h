//
//  BDTrackerProtocol+ABSDKVersionBlocks.h
//  BDTrackerProtocol
//
//  Created by bob on 2020/3/12.
//

#import "BDTrackerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString *_Nullable(^ProtocolABSDKVersionBlock)(void);

@interface BDTrackerProtocol (ABSDKVersionBlocks)

+ (void)addABSDKVersionBlock:(ProtocolABSDKVersionBlock)block forKey:(NSString *)key;
+ (void)removeABSDKVersionBlockForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
