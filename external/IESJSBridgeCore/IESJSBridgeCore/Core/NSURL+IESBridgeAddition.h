//
//  NSURL+IESBridgeAddition.h
//  IESWebKit
//
//  Created by Lizhen Hu on 2019/7/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (IESBridgeAddition)

- (BOOL)jsb_isMatchedInBridgeSchemes;

@end

NS_ASSUME_NONNULL_END
