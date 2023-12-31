//
//  DVENLEInterfaceWrapper.h
//  NLEEditor
//
//  Created by bytedance on 2021/9/16.
//

#import <Foundation/Foundation.h>
#import "DVENLEInterfaceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class NLEInterface_OC;

@interface DVENLEInterfaceWrapper : NSObject <DVENLEInterfaceProtocol>

- (instancetype)initWithNLEInterface:(NLEInterface_OC *)nle;

@end

NS_ASSUME_NONNULL_END
