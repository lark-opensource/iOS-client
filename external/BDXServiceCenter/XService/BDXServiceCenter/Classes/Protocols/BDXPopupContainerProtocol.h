//
//  BDXPopupContainerProtocol.h
//  Pods
//
//  Created by tianbaideng on 2021/3/15.
//

#import <BDXServiceCenter/BDXServiceCenter.h>
#import "BDXServiceProtocol.h"
#import <Foundation/Foundation.h>
#import "BDXContainerProtocol.h"
#import "BDXKitProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDXPopupCloseReason) {
    BDXPopupCloseReasonUnknown,
    BDXPopupCloseReasonByTapMask,
    BDXPopupCloseReasonByGesture,
    BDXPopupCloseReasonByJSB,
};

@protocol BDXPopupContainerProtocol <BDXContainerProtocol>

- (BOOL)close:(nullable NSDictionary *)params;
- (BOOL)close:(nullable NSDictionary *)params completion:(nullable dispatch_block_t)completion;

@end

@protocol BDXPopupContainerServiceProtocol <BDXServiceProtocol>

- (nullable id<BDXPopupContainerProtocol>)open:(NSString *_Nonnull)url context:(nullable BDXContext *)context;

@end

NS_ASSUME_NONNULL_END
