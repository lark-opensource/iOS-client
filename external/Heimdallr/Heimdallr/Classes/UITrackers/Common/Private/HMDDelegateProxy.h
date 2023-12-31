//
//  HMDDelegateProxy.h
//  Heimdallr
//
//  Created by 谢俊逸 on 25/1/2018.
//

#import <Foundation/Foundation.h>
#import "HMDUITrackableContext.h"

@interface HMDDelegateProxy : NSProxy
@property (nonatomic, weak, readonly) id _Nullable target;
@property (nonatomic, unsafe_unretained, readonly) id<HMDUITrackable> _Nullable consignor;
+ (instancetype _Nullable )proxyWithTarget:(id _Nullable )target consignor:(id _Nullable )consignor;
- (instancetype _Nullable )initWithTarget:(id _Nullable )target consignor:(id _Nonnull )consignor;
@end
