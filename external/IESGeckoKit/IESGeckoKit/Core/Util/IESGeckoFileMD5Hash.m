/*
 *  IESFileMD5Hash.m
 *
 *  Copyright © 2010-2014 Joel Lopes Da Silva. All rights reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#import "IESGeckoFileMD5Hash.h"

#include <CommonCrypto/CommonDigest.h>
#include <CoreFoundation/CoreFoundation.h>
#include <stdint.h>
#include <stdio.h>
#import "NSError+IESGurdKit.h"

// Constants
static const size_t IESFileMD5HashDefaultChunkSizeForReadingData = 4096;

// Function pointer types for functions used in the computation 
// of a cryptographic hash.
typedef int (*IESFileMD5HashInitFunction)   (uint8_t *hashObjectPointer[]);
typedef int (*IESFileMD5HashUpdateFunction) (uint8_t *hashObjectPointer[], const void *data, CC_LONG len);
typedef int (*IESFileMD5HashFinalFunction)  (unsigned char *md, uint8_t *hashObjectPointer[]);

// Structure used to describe a hash computation context.
typedef struct _IESFileMD5HashComputationContext {
    IESFileMD5HashInitFunction initFunction;
    IESFileMD5HashUpdateFunction updateFunction;
    IESFileMD5HashFinalFunction finalFunction;
    size_t digestLength;
    uint8_t **hashObjectPointer;
} IESFileMD5HashComputationContext;

#define IESFileMD5HashComputationContextInitialize(context, hashAlgorithmName)                    \
CC_##hashAlgorithmName##_CTX hashObjectFor##hashAlgorithmName;                          \
context.initFunction      = (IESFileMD5HashInitFunction)&CC_##hashAlgorithmName##_Init;       \
context.updateFunction    = (IESFileMD5HashUpdateFunction)&CC_##hashAlgorithmName##_Update;   \
context.finalFunction     = (IESFileMD5HashFinalFunction)&CC_##hashAlgorithmName##_Final;     \
context.digestLength      = CC_##hashAlgorithmName##_DIGEST_LENGTH;                     \
context.hashObjectPointer = (uint8_t **)&hashObjectFor##hashAlgorithmName


@implementation IESGurdFileMD5Hash

+ (NSString *)hashOfFileAtPath:(NSString *)filePath
        withComputationContext:(IESFileMD5HashComputationContext *)context
                         error:(NSError **)error
{
    NSString *result = nil;
    CFURLRef fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)filePath, kCFURLPOSIXPathStyle, (Boolean)false);
    if (!fileURL) {
        *error = [NSError ies_errorWithCode:IESGurdSyncStatusFileHashFailed
                                description:@"Create File URL for hash failed"];
        return nil;
    }
    
    CFReadStreamRef readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault, fileURL);
    if (!readStream) {
        *error = [NSError ies_errorWithCode:IESGurdSyncStatusFileHashFailed
                                description:@"Create file readStream failed"];
        if (fileURL)    CFRelease(fileURL);
        return nil;
    }
    
    BOOL open = (BOOL)CFReadStreamOpen(readStream);
    if (!open) {
        *error = [NSError ies_errorWithCode:IESGurdSyncStatusFileHashFailed
                                description:@"Open file readStream failed"];
        if (fileURL)    CFRelease(fileURL);
        if (readStream) CFRelease(readStream);
        return nil;
    }
    
    // Use default value for the chunk size for reading data.
    const size_t chunkSizeForReadingData = IESFileMD5HashDefaultChunkSizeForReadingData;
    
    // Initialize the hash object
    (*context->initFunction)(context->hashObjectPointer);
    
    // Feed the data to the hash object.
    BOOL hasMoreData = YES;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream, (UInt8 *)buffer, (CFIndex)sizeof(buffer));
        if (readBytesCount == -1) {
            break;
        } else if (readBytesCount == 0) {
            hasMoreData = NO;
        } else {
            (*context->updateFunction)(context->hashObjectPointer, (const void *)buffer, (CC_LONG)readBytesCount);
        }
    }
    
    // Compute the hash digest
    unsigned char digest[context->digestLength];
    (*context->finalFunction)(digest, context->hashObjectPointer);
    
    // Close the read stream.
    CFReadStreamClose(readStream);
    
    // Proceed if the read operation succeeded.
    if (!hasMoreData) {
        char hash[2 * sizeof(digest) + 1];
        for (size_t i = 0; i < sizeof(digest); ++i) {
            snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
        }
        result = [NSString stringWithUTF8String:hash];
    } else {
        *error = [NSError ies_errorWithCode:IESGurdSyncStatusFileHashFailed
                                description:@"File readStream reads failed"];
    }
    if (readStream) CFRelease(readStream);
    if (fileURL)    CFRelease(fileURL);
    return result;
}

+ (NSString *)md5HashOfFileAtPath:(NSString *)filePath error:(NSError *__autoreleasing  _Nullable * _Nullable)error
{
    IESFileMD5HashComputationContext context;
    IESFileMD5HashComputationContextInitialize(context, MD5);
    NSError *hashError = nil;
    NSString *md5 = [self hashOfFileAtPath:filePath withComputationContext:&context error:&hashError];
    if (error && hashError) {
        *error = hashError;
    }
    return md5;
}

+ (NSString *)sha1HashOfFileAtPath:(NSString *)filePath
{
    IESFileMD5HashComputationContext context;
    IESFileMD5HashComputationContextInitialize(context, SHA1);
    return [self hashOfFileAtPath:filePath withComputationContext:&context error:nil];
}

+ (NSString *)sha512HashOfFileAtPath:(NSString *)filePath
{
    IESFileMD5HashComputationContext context;
    IESFileMD5HashComputationContextInitialize(context, SHA512);
    return [self hashOfFileAtPath:filePath withComputationContext:&context error:nil];
}

@end
