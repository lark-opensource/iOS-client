//
//  NSData+VECompression.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/5/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (VECompresion)

- (NSData *)vecompress_gzip:(NSError **)error;;

- (NSData *)vecompress_ungzip:(NSError **)error;

- (BOOL)vecompress_isGzipData;

@end

NS_ASSUME_NONNULL_END
