//
//  BDDYCZipArchive.m
//  BDDynamically
//
//  Created by zuopengliu on 15/3/2018.
//

#import "BDDYCZipArchive.h"
#import "BDDYCSecurity.h"
#import "BDDYCZipArchiveProtocol.h"
#import "BDDYCErrCode.h"
#import "BDDYCMacros.h"
//#import "Class_Protocol_Map.h"

#if __has_include(<ZipArchive/ZipArchive.h>)
#import <ZipArchive/ZipArchive.h>
#define ENABLED_ZipArchive 1
#endif

#if __has_include(<SSZipArchive/SSZipArchive.h>)
#import <SSZipArchive/SSZipArchive.h>
#define ENABLED_SSZipArchive 1
#elif __has_include("SSZipArchive.h")
#import "SSZipArchive.h"
#define ENABLED_SSZipArchive 1
#endif

#if __has_include("BDDSSZipArchive.h")
#import "BDDSSZipArchive.h"
#define ENABLED_BDDYC_SSZipArchive 1
#endif

#import <BDAlogProtocol/BDAlogProtocol.h>
#import "BDDYCDevice.h"
#import "BDDYCMonitor.h"

OBJC_EXTERN NSString *const kBDDYCQuaterbackEncryptedTime;
OBJC_EXTERN NSString *const kBDDYCModuleConfigEncrpt;
static Class BDDYCGetZipArchive(Class zipper)
{
    if (zipper) return zipper;
    
#if ENABLED_SSZipArchive
    return (Class)[SSZipArchive class];
#endif
    
#if ENABLED_ZipArchive
    return (Class)[ZipArchive class];
#endif
    
#if ENABLED_BDDYC_SSZipArchive
    return (Class)[BDDSSZipArchive class];
#endif
    
    return nil;
}


@implementation BDDYCZipArchive

+ (BOOL)unzipFileAtPath:(NSString *)path
          toDestination:(NSString *)destination
             completion:(void (^_Nullable)(NSArray<NSString *> * _Nullable filePaths, NSError * _Nullable error))completionHandler {
    return [self unzipFileAtPath:path toDestination:destination privateKey:@"eThWmZq4t7w!z%C*F-JaNcRfUjXn2r5u8x/A?D(G+KbPeSgVkYp3s6v9y$B&E)H@McQfTjWmZq4t7w!z%C*F-JaNdRgUkXp2s5u8x/A?D(G+KbPeShVmYq3t6w9y$B&E" completion:^(NSArray<NSString *> * _Nullable filePaths, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(filePaths,error);
        }
    }];
}

//+ (BOOL)needDe

+ (BOOL)unzipFileAtPath:(NSString *)path
          toDestination:(NSString *)destination
             privateKey:(NSString *)privateKey // 对称加密私钥
             completion:(void (^)(NSArray<NSString *> *filePaths, NSError *error))completionHandler
{
    NSParameterAssert(path && destination);
    
    Class unzipClass = BDDYCGetZipArchive(nil);
    BDDYCNSAssert(unzipClass, @"zip archive class is empty !!!");
    
    if (!unzipClass || !path || !destination || !unzipClass) {
        NSError *otherError = [NSError errorWithDomain:BDDYCErrorDomain
                                                  code:BDDYCErrCodeUnzipConditionNotOK
                                              userInfo:@{NSLocalizedDescriptionKey: @"Doesn't meet condition, (zipfile or destination or unzip class is nil)"}];
        !completionHandler ? : completionHandler(nil, otherError);
        return NO;
    }
    
    if ([(id)unzipClass respondsToSelector:@selector(unzipFileAtPath:toDestination:progressHandler:completionHandler:)]) {
        
#if ENABLE_SSZIPARCHIVE_LIB == 1

        NSMutableArray *mutableFilePaths = [NSMutableArray array];
        __block NSError *unzipError;
        [[NSFileManager defaultManager] removeItemAtPath:destination error:nil];
        BOOL success = [(id<BDDYCZipArchive>)unzipClass unzipFileAtPath:path toDestination:destination progressHandler:^(NSString *entry, struct unz_file_info_s zipInfo, long entryNumber, long total) {
            NSString *filepath = [destination stringByAppendingPathComponent:entry];
            if (filepath) [mutableFilePaths addObject:filepath];
        } completionHandler:^(NSString *path, BOOL succeeded, NSError *error) {
            unzipError = error;
        }];
        
        if (success) {
            if (privateKey) {
                NSMutableArray *newFilePaths = [NSMutableArray new];
                for (NSString *filepath in [mutableFilePaths copy]) {
                    NSInteger fileType = [BDDYCDevice moduleFileTypeForFile:filepath];
                    switch (fileType) {
                        case BDDYCModuleFileTypeBitcode:
                            {
                                BOOL encrypted = YES;
                                for (NSString *subfilePath in [mutableFilePaths copy]) {
                                    if ([BDDYCDevice moduleFileTypeForFile:subfilePath] == BDDYCModuleFileTypePlist) {
                                        NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:subfilePath];
                                        encrypted = [[data objectForKey:kBDDYCModuleConfigEncrpt] boolValue];
                                    }
                                }

                                if (encrypted) {
                                    // 对称解密
                                    CFTimeInterval start = CACurrentMediaTime();
                                    NSData *de_data = [BDDYCSecurity AESDecryptData:[NSData dataWithContentsOfFile:filepath] keyString:privateKey ivString:nil];
                                    BOOL success = [de_data writeToFile:filepath atomically:YES];
                                    CFTimeInterval end = CACurrentMediaTime();
                                    [BDDYCMonitorGet() event:kBDDYCQuaterbackEncryptedTime label:@"label" durations:(end - start)*1000 needAggregate:YES];

                                    if (success && de_data) {
                                        [newFilePaths addObject:filepath];
                                    } else {
                                        BDALOG_PROTOCOL_INFO_TAG(@"BDDQuaterback", @"%@: encrypt (key: %@) file : %@ fail", @"bd.dyc.zip.error", privateKey, filepath);
                                        NSError *encryptionError = [NSError errorWithDomain:BDDYCErrorDomain
                                                                                       code:BDDYCErrCodeEncryptFileFail
                                                                                   userInfo:@{NSLocalizedDescriptionKey: @"encrypt file fails"}];
                                        if (encryptionError) unzipError = encryptionError;
                                        // remove file
                                        [[NSFileManager defaultManager] removeItemAtPath:filepath error:NULL];
                                    }
                                }
                            }
                            break;
                            case BDDYCModuleFileTypePlist:
                        {
                            [newFilePaths addObject:filepath];
                        }
                            break;
                            case BDDYCModuleFileTypeSignature:
                        {
                            [newFilePaths addObject:filepath];
                        }
                                break;
                        default:
                            break;
                    }
                }
                
                mutableFilePaths = newFilePaths;
            }
        } else {
            NSError *error = [NSError errorWithDomain:BDDYCErrorDomain
                                                 code:BDDYCErrCodeUnzipFailed
                                             userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"unzip file to dir: %@ failure", destination]}];
            unzipError = error;
        }
        
        !completionHandler ? : completionHandler([mutableFilePaths count] > 0 ? mutableFilePaths : nil, unzipError);
        
        return YES;
        
#endif
        
    } else {
        
        // temporary directories
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *tmpDirectory = NSTemporaryDirectory();
        if (![tmpDirectory hasSuffix:@"/"]) tmpDirectory = [tmpDirectory stringByAppendingString:@"/"];
        NSString *unzipTmpDirectory = [NSString stringWithFormat:@"%@_module_alpha_%@_unzip_%d", tmpDirectory, appVersion, arc4random()];
        
        id<BDDYCZipArchive> zipArchive = [unzipClass new];
        if (![(id)zipArchive respondsToSelector:@selector(UnzipOpenFile:)] ||
            ![(id)zipArchive respondsToSelector:@selector(UnzipFileTo:overWrite:)] ||
            ![(id)zipArchive respondsToSelector:@selector(unzippedFiles)]) {
            BDDYCNSAssert(NO, @"<ZipArchive.h> header not exists !!!");
            NSError *error = [NSError errorWithDomain:BDDYCErrorDomain
                                                 code:BDDYCErrCodeUnzipFailed
                                             userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"unzip file to dir: %@ failure", destination]}];
            !completionHandler ? : completionHandler(nil, error);
            return NO;
        }
        
        [zipArchive UnzipOpenFile:path];
        BOOL unzipSuccess = [zipArchive UnzipFileTo:unzipTmpDirectory overWrite:YES];
        if (!unzipSuccess) {
            NSError *error = [NSError errorWithDomain:BDDYCErrorDomain
                                                 code:BDDYCErrCodeUnzipFailed
                                             userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"unzip file to dir: %@ failure", destination]}];
            !completionHandler ? : completionHandler(nil, error);
            return NO;
        }
            
        // copy to target directory (decrypt)
        NSError *unzipError;
        NSMutableArray<NSString*> *mutableFilePaths = [NSMutableArray array];
        for (NSString *filePath in zipArchive.unzippedFiles) {
            NSString *filename = [filePath lastPathComponent];
            
            // if (![[filename pathExtension] isEqualToString:@"js"]) continue;
            if ([filename rangeOfString:@"__MACOSX"].location != NSNotFound) continue;
            
            NSString *newFilePath = [destination stringByAppendingPathComponent:filename];
            NSData *fileData = [NSData dataWithContentsOfFile:filePath];
            if (privateKey) {
                // encrypt data
                NSData *encryptedFileData = [BDDYCSecurity AESEncryptData:fileData
                                                                keyString:privateKey
                                                                 ivString:nil];
                if (fileData && !encryptedFileData) {
                    NSLog(@"%@: encrypt (key: %@) file : %@ fail", BDDYCErrorDomain, privateKey, newFilePath);
                    NSError *encryptionError = [NSError errorWithDomain:BDDYCErrorDomain
                                                                   code:BDDYCErrCodeEncryptFileFail
                                                               userInfo:@{NSLocalizedDescriptionKey: @"encrypt file fails"}];
                    if (encryptionError) unzipError = encryptionError;
                }
                fileData = encryptedFileData;
            }
            
            BOOL success = [fileData writeToFile:newFilePath atomically:YES];
            if (success && fileData) {
                [mutableFilePaths addObject:newFilePath];
                continue;
            }
            
            NSLog(@"%@: write file from: %@ to: %@ fail", BDDYCErrorDomain, filePath, newFilePath);
            NSError *writeError = [NSError errorWithDomain:BDDYCErrorDomain
                                                      code:BDDYCErrCodeWriteFileFail
                                                  userInfo:@{NSLocalizedDescriptionKey: @"write file fails"}];
            if (writeError) unzipError = writeError;
        }
        
        // clear temporary files
        [[NSFileManager defaultManager] removeItemAtPath:unzipTmpDirectory error:nil];
        
        !completionHandler ? : completionHandler(mutableFilePaths.count > 0 ? [mutableFilePaths copy] : nil, unzipError);
        
        return YES;
    }
    
//    NSError *otherError = [NSError errorWithDomain:BDDYCErrorDomain
//                                              code:BDDYCErrCodeUnzipFailed
//                                          userInfo:@{NSLocalizedDescriptionKey: @"unzip file doesn't meet condition"}];
//    !completionHandler ? : completionHandler(nil, otherError);
    
    return NO;
}

@end
