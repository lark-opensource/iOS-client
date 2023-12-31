//
//  AWEAlbumFaceCache.m
//  AWEStudio
//
//  Created by liubing on 2018/5/25.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWEAlbumFaceCache.h"

@implementation AWEAlbumFaceCache

+ (NSString *)imageCachePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    
    return [documentsDirectory stringByAppendingPathComponent:@"AlbumFaceCache"];
}

+ (void)removeAllDetectResults
{
    /// Remove DB
    NSString *dbName = @"face_detect_info_cache";
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:[dbName stringByAppendingPathExtension:@"db"]];
    [[NSFileManager defaultManager] removeItemAtPath:dbPath error:NULL];
    /// Remove ImageCache
    [[NSFileManager defaultManager] removeItemAtPath:[self imageCachePath] error:NULL];
}
@end

