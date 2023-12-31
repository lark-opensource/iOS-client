//
//  OPBridgeRegisterOpt.h
//  TTMicroApp
//
//  Created by baojianjun on 2023/6/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OPBridgeRegisterOpt : NSObject

+ (BOOL)bridgeRegisterOptDisable;

+ (void)updateBridgeRegisterState;

@end

NS_ASSUME_NONNULL_END
