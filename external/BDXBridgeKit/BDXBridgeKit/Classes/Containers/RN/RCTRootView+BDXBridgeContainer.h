//
//  RCTRootView+BDXBridgeContainer.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/6.
//

#import <React/RCTRootView.h>
#import "BDXBridgeContainerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCTRootView (BDXBridgeContainer) <BDXBridgeContainerProtocol>

@end

NS_ASSUME_NONNULL_END
