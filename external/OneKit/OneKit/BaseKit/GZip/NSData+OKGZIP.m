//
//  NSData+OKGZIP.m
//  OneKit
//
//  Created by bob on 2020/6/12.
//

#import "NSData+OKGZIP.h"
#import <zlib.h>

static const int kGodzippaChunkSize = 1024;
static const int kGodzippaDefaultMemoryLevel = 8;
static const int kGodzippaDefaultWindowBits = 15;
static const int kGodzippaDefaultWindowBitsWithGZipHeader = 16 + kGodzippaDefaultWindowBits;
static NSString * const GodzippaZlibErrorDomain = @"com.godzippa.zlib.error";

@implementation NSData (OKGZIP)


- (NSData *)ok_dataByGZipCompressingWithError:(NSError * __autoreleasing *)error {
    return [self ok_dataByGZipCompressingAtLevel:Z_DEFAULT_COMPRESSION
                                       windowSize:kGodzippaDefaultWindowBitsWithGZipHeader
                                      memoryLevel:kGodzippaDefaultMemoryLevel
                                         strategy:Z_DEFAULT_STRATEGY
                                            error:error];
}

- (NSData *)ok_dataByGZipCompressingAtLevel:(int)level
                                  windowSize:(int)windowBits
                                 memoryLevel:(int)memLevel
                                    strategy:(int)strategy
                                       error:(NSError * __autoreleasing *)error {
    if ([self length] == 0) {
        return self;
    }

    z_stream zStream;
    bzero(&zStream, sizeof(z_stream));

    zStream.zalloc = Z_NULL;
    zStream.zfree = Z_NULL;
    zStream.opaque = Z_NULL;
    zStream.next_in = (Bytef *)[self bytes];
    zStream.avail_in = (unsigned int)[self length];
    zStream.total_out = 0;

    OSStatus status;
    if ((status = deflateInit2(&zStream, level, Z_DEFLATED, windowBits, memLevel, strategy)) != Z_OK) {
        if (error) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Failed deflateInit", nil) forKey:NSLocalizedDescriptionKey];
            *error = [[NSError alloc] initWithDomain:GodzippaZlibErrorDomain
                                                code:status
                                            userInfo:userInfo];
        }

        return nil;
    }

    NSMutableData *compressedData = [NSMutableData dataWithLength:kGodzippaChunkSize];

    do {
        if ((status == Z_BUF_ERROR) || (zStream.total_out == [compressedData length])) {
            [compressedData increaseLengthBy:kGodzippaChunkSize];
        }

        zStream.next_out = (Bytef*)[compressedData mutableBytes] + zStream.total_out;
        zStream.avail_out = (unsigned int)([compressedData length] - zStream.total_out);

        status = deflate(&zStream, Z_FINISH);
    } while ((status == Z_OK) || (status == Z_BUF_ERROR));

    deflateEnd(&zStream);

    if ((status != Z_OK) && (status != Z_STREAM_END)) {
        if (error) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Error deflating payload", nil) forKey:NSLocalizedDescriptionKey];
            *error = [[NSError alloc] initWithDomain:GodzippaZlibErrorDomain
                                                code:status
                                            userInfo:userInfo];
        }

        return nil;
    }

    [compressedData setLength:zStream.total_out];

    return compressedData;
}

- (BOOL)ok_isGzipCompressedData {
    if (self.length < 3) {
        return NO;
    }

    NSData *subdata = [self subdataWithRange:NSMakeRange(0, 3)];
    const Byte *bytes = (const Byte *)subdata.bytes;
    return bytes[0] == 0x1f && bytes[1] == 0x8b && bytes[2] == 0x08;
}


- (NSData *)ok_dataByGZipDecompressingDataWithError:(NSError * __autoreleasing *)error {
    return [self ok_dataByGZipDecompressingDataWithWindowSize:kGodzippaDefaultWindowBitsWithGZipHeader
                                                         error:error];
}

- (NSData *)ok_dataByGZipDecompressingDataWithWindowSize:(int)windowBits
                                                    error:(NSError * __autoreleasing *)error {
    if ([self length] == 0) {
        return self;
    }

    z_stream zStream;
    bzero(&zStream, sizeof(z_stream));

    zStream.zalloc = Z_NULL;
    zStream.zfree = Z_NULL;
    zStream.opaque = Z_NULL;
    zStream.avail_in = (unsigned int)[self length];
    zStream.next_in = (Byte *)[self bytes];

    OSStatus status;
    if ((status = inflateInit2(&zStream, windowBits)) != Z_OK) {
        if (error) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Failed inflateInit", nil) forKey:NSLocalizedDescriptionKey];
            *error = [[NSError alloc] initWithDomain:GodzippaZlibErrorDomain code:status userInfo:userInfo];
        }

        return nil;
    }

    const NSUInteger estimatedLength = (NSUInteger)((double)[self length] * 1.5);
    size_t bufferLength = sizeof(unsigned char) * estimatedLength;
    unsigned char *buffer = malloc(bufferLength);
    if (buffer == NULL) {
        return nil;
    }
    
    do {
        if ((status == Z_BUF_ERROR) || (zStream.total_out == bufferLength)) {
            /* Buffer长度超过预估长度800倍（实际数据长度1000倍）的数据认为是OOM，不再继续
             * 数据大小   buffer大小上限
             *  1KB       1000KB   (~1MB)
             *  10KB      10000KB  (~10MB)
             *  100KB     100000KB (~100MB)
             *  1MB       1000MB   (~1GB)
             * SDK数据大小参考:
             *   AppLog logSettings接口响应大小: 801B(解压缩前) 230+2950B(解压缩后)
             */
            if (bufferLength > estimatedLength * 800) {
                free(buffer);
                return nil;
            }
            bufferLength += estimatedLength;
            unsigned char *buffer_bak = buffer;
            buffer = realloc(buffer, bufferLength);
            if (!buffer) {
                free(buffer_bak);
                return nil;
            }
        }

        zStream.next_out = (Bytef*)buffer + zStream.total_out;
        zStream.avail_out = (unsigned int)(bufferLength - zStream.total_out);

        status = inflate(&zStream, Z_FINISH);
    } while ((status == Z_OK) || (status == Z_BUF_ERROR));

    inflateEnd(&zStream);

    if ((status != Z_OK) && (status != Z_STREAM_END)) {
        if (error) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Error inflating payload", nil) forKey:NSLocalizedDescriptionKey];
            *error = [[NSError alloc] initWithDomain:GodzippaZlibErrorDomain code:status userInfo:userInfo];
        }

        return nil;
    }
    
    bufferLength = zStream.total_out;
    unsigned char *buffer_bak = buffer;
    buffer = realloc(buffer, bufferLength);
    if (!buffer) {
        free(buffer_bak);
        return nil;
    }
    
    NSMutableData *decompressedData = [[NSMutableData alloc] initWithBytesNoCopy:buffer length:bufferLength];
    return decompressedData;
}

@end
