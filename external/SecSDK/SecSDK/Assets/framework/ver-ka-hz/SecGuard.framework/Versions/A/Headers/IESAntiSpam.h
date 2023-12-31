//
//  IESAntiSpam.h
//  Pods
//
//  Created by 权泉 on 2017/5/17.
//
//

#import <Foundation/Foundation.h>
#import "SGMSafeGuradProtocols.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESAntiSpam : NSObject <SGMEncrptProtocol>

+ (instancetype)new  NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
