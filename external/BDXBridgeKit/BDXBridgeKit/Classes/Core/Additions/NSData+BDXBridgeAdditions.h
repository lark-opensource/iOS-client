//
//  NSData+BDXBridgeAdditions.h
//  BDXBridgeKit-Pods-Aweme
//
//  Created by Lizhen Hu on 2021/3/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (BDXBridgeAdditions)

@property (nonatomic, copy, readonly) NSString *bdx_mimeType;

@end

NS_ASSUME_NONNULL_END
