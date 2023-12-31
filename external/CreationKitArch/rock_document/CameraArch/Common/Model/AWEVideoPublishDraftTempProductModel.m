//
//  AWEVideoPublishDraftTempProductModel.m
//  CameraClient
//
//  Created by geekxing on 2020/2/25.
//

#import "AWEVideoPublishDraftTempProductModel.h"
#import <CreativeKit/ACCCacheProtocol.h>

@implementation AWEVideoPublishDraftTempProductModel

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dicM = [super dictionaryValue].mutableCopy;
    [dicM removeObjectsForKeys:@[@"clearProductBlock"]];
    return dicM.copy;
}

- (void)synchronize {
    [ACCCache() setObject:self forKey:[[self class] cacheKey:self.publishTaskId]];
}

- (void)destroy {
    [[self class] destroyWithTaskId:self.publishTaskId];
}

+ (instancetype)restoreWithTaskId:(NSString *)taskID {
    AWEVideoPublishDraftTempProductModel *model = [ACCCache() objectForKey:[self cacheKey:taskID]];
    model.uploadMediaURL = [self fixSandboxPrefixWithURL:model.uploadMediaURL];
    model.watermarkVideoURL = [self fixSandboxPrefixWithURL:model.watermarkVideoURL];
    return model;
}

+ (void)destroyWithTaskId:(NSString *)taskID {
    [ACCCache() removeObjectForKey:[self cacheKey:taskID]];
}

+ (NSString *)cacheKey:(NSString *)taskID
{
    return [NSString stringWithFormat:@"%@_%@", NSStringFromClass([self class]), taskID];
}

- (void)setUploadMediaURL:(NSURL *)uploadMediaURL {
    if (_uploadMediaURL && ![_uploadMediaURL isEqual:uploadMediaURL]) {
        [NSFileManager.defaultManager removeItemAtURL:_uploadMediaURL error:nil];
    }
    _uploadMediaURL = uploadMediaURL;
}

- (void)setWatermarkVideoURL:(NSURL *)watermarkVideoURL {
    if (_watermarkVideoURL && ![_watermarkVideoURL isEqual:watermarkVideoURL]) {
        [NSFileManager.defaultManager removeItemAtURL:_watermarkVideoURL error:nil];
    }
    _watermarkVideoURL = watermarkVideoURL;
}

+ (NSURL *)fixSandboxPrefixWithURL:(NSURL *)url {
    NSString *homeDir = NSHomeDirectory();
    if (url && ![url.path containsString:homeDir]) {
        NSString *urlStr = [url.path stringByReplacingCharactersInRange:NSMakeRange(0, homeDir.length) withString:homeDir];
        return [NSURL fileURLWithPath:urlStr];
    }
    return url;
}

@end
