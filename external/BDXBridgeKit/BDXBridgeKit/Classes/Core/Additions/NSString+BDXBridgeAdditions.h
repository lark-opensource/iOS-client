//
//  NSString+BDXBridgeAdditions.h
//  BDXBridgeKit-Pods-Aweme
//
//  Created by Lizhen Hu on 2021/3/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (BDXBridgePath)

- (NSString *)bdx_stringByStrippingSandboxPath;
- (NSString *)bdx_stringByAppendingSandboxPath;

@end

NS_ASSUME_NONNULL_END
