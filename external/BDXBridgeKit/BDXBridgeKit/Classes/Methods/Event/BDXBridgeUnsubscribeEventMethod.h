//
//  BDXBridgeUnsubscribeEventMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/9/8.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeUnsubscribeEventMethod : BDXBridgeMethod

@end

@interface BDXBridgeUnsubscribeEventMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *eventName;

@end

NS_ASSUME_NONNULL_END
