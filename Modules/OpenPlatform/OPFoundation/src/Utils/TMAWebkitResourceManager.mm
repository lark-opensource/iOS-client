//
//  TMAWebkitResourceManager.m
//  WebkitResource
//
//  Created by 殷源 on 2018/9/20.
//  Copyright © 2018 britayin. All rights reserved.
//

#import "TMAWebkitResourceManager.h"
#include <CommonCrypto/CommonDigest.h>
#include <LarkStorage/LarkStorage-Swift.h>

static NSString * const saltFileName = @"salt";
static NSString * const versionDirectoryPrefix = @"Version ";
static NSString * const recordsDirectoryName = @"Records";
static NSString * const blobSuffix = @"-blob";

static NSString * const kResourceType = @"Resource";    //now only suport "Resource" type

static uint8_t HEADER_PNG[4] = {0x89, 0x50, 0x4E, 0x47};
static uint8_t HEADER_JPEG[3] = {0xFF, 0xD8, 0xFF};
static uint8_t HEADER_GIF[4] = {0x47, 0x49, 0x46, 0x38};
static uint8_t HEADER_TIFF[4] = {0x49, 0x49, 0x2A, 0x00};
static uint8_t HEADER_WEBP[4] = {'R', 'I', 'F', 'I'};

@interface TMAResourceSHA1 : NSObject

@end

@implementation TMAResourceSHA1
{
    CC_SHA1_CTX m_context;
}

- (instancetype)init {
    if (self = [super init]) {
        CC_SHA1_Init(&m_context);
    }
    return self;
}

- (void)addBytes:(const uint8_t*)input length:(size_t)length {
    CC_SHA1_Update(&m_context, input, (unsigned int)length);
}

- (NSString *)hashAsString {
    uint8_t hash[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1_Final(hash, &m_context);

    NSMutableString *outputStr = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for(int i=0; i<CC_SHA1_DIGEST_LENGTH; i++) {
        [outputStr appendFormat:@"%02x", hash[i]];
    }
    return outputStr.uppercaseString;
}


@end

@interface TMAWebkitResourceManager ()

@property (nonatomic, strong) NSString *cachedOrigin;
@property (nonatomic, strong) NSData *cachedSaltData;
@property (nonatomic, strong) NSString *cachedResourcesDirectoryPath;

@end

@implementation TMAWebkitResourceManager

+ (instancetype)defaultManager {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (NSString *)resourcePathForURL:(NSURL *)url pageURL:(NSURL *)pageURL {

    if (!url) {
        return nil;
    }

    if (NSString *resourcePath = [self checkResourceExists:self.cachedOrigin resourceType:kResourceType url:url saltData:self.cachedSaltData resourcesDirectoryPath:self.cachedResourcesDirectoryPath]) {
        return resourcePath;
    }

    NSArray *subpaths = [self subpaths];

    //list all origins
    NSMutableArray *urls = [NSMutableArray array];
    if (pageURL) {
        [urls addObject:pageURL];
    }
    [urls addObject:url];
    NSArray *origins = [self originsForURLs:urls];

    for (NSString *pathName in subpaths) {
        if (NSString *resource = [self resourceInSubpath:pathName origins:origins url:url]) {
            return resource;
        }
    }
    return nil;
}

- (NSString *)resourceInSubpath:(NSString *)subpath origins:(NSArray *)origins url:(NSURL *)url{
    NSString *networkCachePath = [self networkCachePath];
    NSString *path = [networkCachePath stringByAppendingPathComponent:subpath];
    NSString *saltPath = [path stringByAppendingPathComponent:saltFileName];

    if(![NSFileManager.defaultManager fileExistsAtPath:saltPath]) {
        return nil;
    }

    NSString *recordsDirectoryPath = [path stringByAppendingPathComponent:recordsDirectoryName];
    if(![NSFileManager.defaultManager fileExistsAtPath:recordsDirectoryPath]) {
        return nil;
    }

    NSData *saltData = [NSData lss_dataWithContentsOfFile:saltPath error: nil];
    if (!saltData) {
        return nil;
    }

    for (NSString *origin in origins) {
        NSString *originHash = [self hashWithSalt:saltData appendParams:@[origin]];
        if (!originHash) {
            return nil;
        }
        NSString *originDirectoryPath = [recordsDirectoryPath stringByAppendingPathComponent:originHash];
        if(![NSFileManager.defaultManager fileExistsAtPath:originDirectoryPath]) {
            return nil;
        }
        NSString *resourcesDirectoryPath = [originDirectoryPath stringByAppendingPathComponent:kResourceType];

        if (NSString *resourcePath = [self checkResourceExists:origin resourceType:kResourceType url:url saltData:saltData resourcesDirectoryPath:resourcesDirectoryPath]) {
            return resourcePath;
        }
    }
    return nil;
}

- (NSString *)networkCachePath {
    // lint:disable:next lark_storage_check
    NSString *appDataPath = NSHomeDirectory();
#if !(TARGET_IPHONE_SIMULATOR)
    // 在真机的情况下
    NSString *networkCachePath = [appDataPath stringByAppendingPathComponent:@"Library/Caches/WebKit/NetworkCache"];
#else
    // 在模拟器情况下
    NSString *networkCachePath = [appDataPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Library/Caches/%@/WebKit/NetworkCache", NSBundle.mainBundle.bundleIdentifier]];
#endif

    return networkCachePath;
}

- (NSArray *)subpaths {
    NSError *error;
    NSArray *subpaths = [NSFileManager.defaultManager contentsOfDirectoryAtPath:self.networkCachePath error:&error];
    if (error) {
        return nil;
    }

    //BEGINSWITH versionDirectoryPrefix = @"Version ";
    subpaths = [subpaths filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF  BEGINSWITH %@", versionDirectoryPrefix]];

    //sorted by version number
    subpaths = [subpaths sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSInteger version1 = [self versionFromPath:obj1];
        NSInteger version2 = [self versionFromPath:obj2];
        if (version1 > version2) {
            return NSOrderedAscending;
        }else if (version1 < version2) {
            return NSOrderedDescending;
        }else {
            return NSOrderedSame;
        }
    }];

    return subpaths;
}

- (NSString *)checkResourceExists:(NSString *)origin resourceType:(NSString *)resourceType url:(NSURL *)url saltData:(NSData *)saltData resourcesDirectoryPath:(NSString *)resourcesDirectoryPath{
    if (!origin || !saltData || !resourcesDirectoryPath) {
        return nil;
    }

    NSString *resourceNameHash = [self hashWithSalt:saltData appendParams:@[origin, resourceType, url.absoluteString]];
    if (!resourceNameHash) {
        return nil;
    }
    // check -blob suffix file first
    BOOL resourcePathValid = NO;
    NSString *resourcePath = [resourcesDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", resourceNameHash, blobSuffix]];
    if([NSFileManager.defaultManager fileExistsAtPath:resourcePath]) {
        resourcePathValid = YES;
    }else {
        resourcePath = [resourcesDirectoryPath stringByAppendingPathComponent:resourceNameHash];
        if([NSFileManager.defaultManager fileExistsAtPath:resourcePath]) {
            resourcePathValid = YES;
        }
    }
    if (resourcePathValid) {
        self.cachedOrigin = origin;
        self.cachedSaltData = saltData;
        self.cachedResourcesDirectoryPath = resourcesDirectoryPath;
        return resourcePath;
    }
    return nil;
}

- (UIImage *)imageResourceForURL:(NSURL *)url pageURL:(NSURL *)pageURL{
    NSString *path = [self resourcePathForURL:url pageURL:pageURL];
    UIImage *image = nil;
    if ([path hasSuffix:blobSuffix]) {
        // For the blob file, tray reading directly
        // lint:disable:next lark_storage_check
        image = [UIImage imageWithContentsOfFile:path];
    }
    if (!image) {
        unsigned long long fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:path error:nil].fileSize;
        // Limit the file size to 2MB
        if (fileSize < 1024*1024*2) {
            // Remove the header added by Webkit before the cache file
            NSData *data = [NSData lss_dataWithContentsOfFile:path error:nil];
            // limit max check length 5000
            for (NSUInteger i = 0; i < data.length && i < 5000; i++) {
                uint8_t c;
                [data getBytes:&c range:NSMakeRange(i, 1)];
                if ([self matchImage:c from:i data:data]) {
                    NSData *imageData = [data subdataWithRange:NSMakeRange(i, data.length-i)];
                    image = [UIImage imageWithData:imageData];
                    break;
                }
            }
        }
    }
    return image;
}

- (BOOL)matchImage:(uint8_t)c from:(NSUInteger)i data:(NSData *)data{
    BOOL match = NO;
    if (c == HEADER_PNG[0]) {
        match = [self matchImageData:HEADER_PNG length:4 from:i data:data];
    }else if (c == HEADER_JPEG[0]) {
        match = [self matchImageData:HEADER_JPEG length:3 from:i data:data];
    }else if (c == HEADER_GIF[0]) {
        match = [self matchImageData:HEADER_GIF length:4 from:i data:data];
    }else if (c == HEADER_TIFF[0]) {
        match = [self matchImageData:HEADER_TIFF length:4 from:i data:data];
    }else if (c == HEADER_WEBP[0]) {
        match = [self matchImageData:HEADER_WEBP length:4 from:i data:data];
    }
    return match;
}

- (BOOL)matchImageData:(uint8_t *)match length:(int)length from:(NSUInteger)from data:(NSData *)data {
    for (int i = 0; i < length; i++) {
        uint8_t match_c = match[i];
        if (from+i >= data.length) {
            return NO;
        }
        uint8_t c;
        [data getBytes:&c range:NSMakeRange(from+i, 1)];
        if (match_c != c) {
            return NO;
        }
    }
    return YES;
}

- (NSString *)hashWithSalt:(NSData *)salt appendParams:(NSArray<NSString *> *)params {

    TMAResourceSHA1 *sha1 = [[TMAResourceSHA1 alloc] init];

    if (salt) {
        [sha1 addBytes:(const uint8_t *)salt.bytes length:salt.length];
    }

    for (NSString *param in params) {
        const char *cstr = [param cStringUsingEncoding:NSUTF8StringEncoding];
        const uint8_t nullByte = 0;
        [sha1 addBytes:(const uint8_t *)cstr length:param.length];
        [sha1 addBytes:&nullByte length:1];
    }

    return sha1.hashAsString;
}

- (NSInteger)versionFromPath:(NSString *)path {
    if (!path) {
        return 0;
    }
    NSString *name = [path lastPathComponent];
    NSString *version = [name substringFromIndex:versionDirectoryPrefix.length];
    return version.integerValue;
}

- (NSArray *)originsForURLs:(NSArray<NSURL *> *)urls {
    NSMutableArray *origins = [NSMutableArray array];
    for (NSURL *url in urls) {
        NSString *host = url.host;
        if (host == nil) {
            [origins addObject:@""];
            continue;
        }
        NSArray *listItems = [host componentsSeparatedByString:@"."];

        NSMutableString *origin = [NSMutableString string];
        [listItems enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx == listItems.count-1) {
                [origin insertString:obj atIndex:0];
            }else{
                [origin insertString:@"." atIndex:0];
                [origin insertString:obj atIndex:0];

                BOOL repeat = NO;
                for (NSString *t_origin in origins) {
                    if ([t_origin isEqualToString:origin]) {
                        repeat = YES;
                        break;
                    }
                }
                if(!repeat) [origins addObject:origin.copy];
            }
        }];
    }

    return origins;
}

@end
