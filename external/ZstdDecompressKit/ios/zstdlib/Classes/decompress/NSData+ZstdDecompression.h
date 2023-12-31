//
//  NSData+ZstdCompression.h
//  zstandardlib
//
//  Created by JinyDu on 2021/6/22.
//  Copyright © 2021 JinyDu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (ZstdDecompression)


- (nullable NSData*)zstd_decompress;

- (NSData *_Nullable)zstd_decompressWithDict:(NSData *_Nonnull)dict;
- (BOOL)zstd_decompressToFileName:(NSString *_Nullable)outputFileName;


@end
