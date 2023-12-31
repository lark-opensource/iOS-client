#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "NSData+ZstdCompression.h"
#import "ZstdCompression.h"
#import "ZstdCompressor.h"
#import "NSData+ZstdDecompression.h"
#import "ZstdDecompression.h"
#import "ZstdDecompressor.h"
#import "ZstdKitDecompress.h"
#import "zdict.h"
#import "zstd.h"
#import "zstd_errors.h"

FOUNDATION_EXPORT double ZstdDecompressKitVersionNumber;
FOUNDATION_EXPORT const unsigned char ZstdDecompressKitVersionString[];
