//
//  NSData+ETag.h
//  IESGeckoKit
//
//  Created by li keliang on 2018/10/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (ETag)

- (NSString *)ies_eTag;

- (NSString *)ies_md5String;

@end

NS_ASSUME_NONNULL_END
