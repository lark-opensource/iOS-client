//
//  BDXBridgeResponder.h
//  BDXBridgeKit-Pods-Aweme
//
//  Created by Lizhen Hu on 2021/3/22.
//

#import <Foundation/Foundation.h>
#import "BDXBridgeServiceManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDXBridgeContainerProtocol;

@interface BDXBridgeResponder : NSObject

+ (void)closeContainer:(id<BDXBridgeContainerProtocol>)container animated:(BOOL)animated completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
