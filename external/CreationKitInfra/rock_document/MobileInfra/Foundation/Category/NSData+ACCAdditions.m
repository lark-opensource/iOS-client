//
//  NSData+ACCAdditions.m
//  CameraClient
//
//  Created by Liu Deping on 2019/12/4.
//

#import "NSData+ACCAdditions.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

#import "ACCLogProtocol.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#include <sys/types.h>
#include <sys/stat.h>

NSString *const ACCDataWriteErrorStepKey = @"step";

@implementation NSData (ACCAdditions)

- (NSString *)acc_md5String
{
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(self.bytes, (CC_LONG)self.length, result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

- (id)acc_jsonValueDecoded
{
    NSError *error = nil;
    return [self acc_jsonValueDecoded:&error];
}

- (id)acc_jsonValueDecoded:(NSError *__autoreleasing *)error
{
    id value = [NSJSONSerialization JSONObjectWithData:self options:kNilOptions error:error];
    return value;
}

- (NSArray *)acc_jsonArray {
    id value = [self acc_jsonValueDecoded];
    if ([value isKindOfClass:[NSArray class]]) {
        return value;
    }
    return nil;
}

- (NSDictionary *)acc_jsonDictionary {
    id value = [self acc_jsonValueDecoded];
    if ([value isKindOfClass:[NSDictionary class]]) {
        return value;
    }
    return nil;
}

- (NSArray *)acc_jsonArray:(NSError * _Nullable __autoreleasing *)error
{
    id value = [self acc_jsonValueDecoded:error];
    if ([value isKindOfClass:[NSArray class]]) {
        return value;
    }
    return nil;
}

- (NSDictionary *)acc_jsonDictionary:(NSError * _Nullable __autoreleasing *)error
{
    id value = [self acc_jsonValueDecoded:error];
    if ([value isKindOfClass:[NSDictionary class]]) {
        return value;
    }
    return nil;
}


#pragma mark - write

- (BOOL)acc_writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile
{
    NSError *error = nil;
    return [self acc_writeToFile:path options: useAuxiliaryFile ? NSDataWritingAtomic : 0 error:&error];
}

- (BOOL)acc_writeToFile:(NSString *)path options:(NSDataWritingOptions)writeOptionsMask error:(NSError **)errorPtr
{
    if (!path || path.length == 0) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:@{NSLocalizedDescriptionKey: @"Write to file path does not exist."}];
        }
        return NO;
    } else {
        NSError *error = nil;
        BOOL writeSuccess = [self writeToFile:path options:writeOptionsMask error:&error];
        if (!writeSuccess && error) {
            writeSuccess = [self acc_handleWriteUnknownError:&error filePath:path fileURL:nil];
        }
        if (errorPtr) {
            *errorPtr = error;
        }
        return writeSuccess;
    }
}

- (BOOL)acc_writeToURL:(NSURL *)url atomically:(BOOL)atomically
{
    NSError *error = nil;
    return [self acc_writeToURL:url options:atomically ? NSDataWritingAtomic : 0 error:&error];
}

- (BOOL)acc_writeToURL:(NSURL *)url options:(NSDataWritingOptions)writeOptionsMask error:(NSError **)errorPtr
{
    NSError *error;
    BOOL writeSuccess = [self writeToURL:url options:writeOptionsMask error:&error];
    if (!writeSuccess && error) {
        writeSuccess = [self acc_handleWriteUnknownError:&error filePath:nil fileURL:url];
    }
    if (errorPtr) {
        *errorPtr = error;
    }
    return writeSuccess;
}

#pragma mark - private

- (BOOL)acc_handleWriteUnknownError:(NSError **)error filePath:(NSString *)path fileURL:(NSURL *)pathUrl
{
    // NSFileWriteUnknownError = 512, Write error (reason unknown)
    NSError *writeError;
    if (error) {
        writeError = *error;
    }
    if ([writeError.domain isEqual:NSCocoaErrorDomain] && writeError.code == NSFileWriteUnknownError) {
        NSMutableDictionary *extraData = [@{} mutableCopy];
        NSInteger monitorStatus = 1;
        
        // stage:1, try to write data to file
        NSNumber *writeStatus = @(0);
        if (path) {
            if ([self writeToFile:path options:0 error:nil]) { // No temporary file, nonatomic
                writeStatus = @(1);
            } else if ([self writeToFile:path options:NSDataWritingFileProtectionNone error:nil]) { // No protection file
                writeStatus = @(2);
            } else if ([self writeToFile:path options:NSDataWritingAtomic error:nil]) {
                writeStatus = @(3);
            } else if ([self writeToFile:path atomically:YES]) {
                writeStatus = @(4);
            } else if ([self writeToFile:path atomically:NO]) {
                writeStatus = @(5);
            }
        } else if (pathUrl) {
            if ([self writeToURL:pathUrl options:0 error:nil]) {
                writeStatus = @(6);
            } else if ([self writeToURL:pathUrl options:NSDataWritingFileProtectionNone error:nil]) {
                writeStatus = @(7);
            } else if ([self writeToURL:pathUrl options:NSDataWritingAtomic error:nil]) {
                writeStatus = @(8);
            } else if ([self writeToURL:pathUrl atomically:YES]) {
                writeStatus = @(9);
            } else if ([self writeToURL:pathUrl atomically:NO]) {
                writeStatus = @(10);
            }
        }
        
        extraData[@"dataWriteStatus"] = writeStatus;
        BOOL handleErrorSuccess = writeStatus.integerValue != 0;
        if (handleErrorSuccess) { // write file success
            *error = nil;
            monitorStatus = 0;
        }
        
        AWELogToolError2(@"write", AWELogToolTagTracker, @"NSData write file status:%@", writeStatus);
        [ACCMonitor() trackService:@"studio_data_write_file" status:monitorStatus extra:extraData];
        [ACCTracker() trackEvent:@"studio_data_write_file" params:extraData needStagingFlag:NO];
        return handleErrorSuccess;
    } else {
        // handle other errors
        return NO;
    }
}

- (NSString *)acc_toHex {
    static const char hexdigits[] = "0123456789ABCDEF";
    const unsigned char *bytes = self.bytes;
    char *strbuf = (char *)malloc(self.length * 2 + 1);
    char *hex = strbuf;
    NSString *hexBytes = nil;
    
    for (int i = 0; i < self.length; ++i) {
        const unsigned char c = *bytes++;
        *hex++ = hexdigits[(c >> 4) & 0xF];
        *hex++ = hexdigits[(c ) & 0xF];
    }
    *hex = 0;
    hexBytes = [NSString stringWithUTF8String:strbuf];
    free(strbuf);
    return [hexBytes lowercaseString];
}

+ (NSData *)acc_dataFromHEXString:(NSString *)command
{
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < [command length] / 2; i++) {
        byte_chars[0] = [command characterAtIndex:i * 2];
        byte_chars[1] = [command characterAtIndex:i * 2 + 1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    return commandToSend;
}

@end

