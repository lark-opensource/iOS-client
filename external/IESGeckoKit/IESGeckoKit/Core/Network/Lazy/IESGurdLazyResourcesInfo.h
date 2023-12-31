#import <Foundation/Foundation.h>

#import "IESGeckoDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdLazyResourcesInfo : NSObject

@property (nonatomic, assign) IESGurdLazyResourceStatus status;

@property (nonatomic, assign) uint64_t packageSize;

@property (nonatomic, assign) uint64_t packageID;

@end

NS_ASSUME_NONNULL_END
