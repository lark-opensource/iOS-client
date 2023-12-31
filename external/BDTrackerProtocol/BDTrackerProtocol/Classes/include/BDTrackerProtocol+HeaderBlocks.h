//
//  BDTrackerProtocol+HeaderBlocks.h
//  BDTrackerProtocol
//
//  Created by bob on 2020/11/22.
//

#import "BDTrackerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSDictionary<NSString*, NSString*> *_Nullable(^BDTrackerHeaderBlock)(void);


@interface BDTrackerProtocol (HeaderBlocks)

+ (void)addHTTPHeaderBlock:(BDTrackerHeaderBlock)block forKey:(NSString *)key;
+ (void)removeHTTPHeaderBlockForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
