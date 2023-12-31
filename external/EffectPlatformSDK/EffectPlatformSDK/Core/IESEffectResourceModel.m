//
//  IESEffectResourceModel.m
//  EffectPlatformSDK
//
//  Created by 赖霄冰 on 2019/8/8.
//

#import "IESEffectResourceModel.h"
#import "IESEffectDefines.h"

@implementation IESEffectResourceModel
@synthesize fileDownloadURLs = _fileDownloadURLs;

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"name" : @"name",
             @"value" : @"value",
             @"resourceURI" : @"resource_uri",
             @"fileDownloadURLs" : @"fileDownloadURLs",
             };
}

- (void)genFileDownloadURLsWithURLPrefixes:(NSArray<NSString *> *)urlPrefixes{
    if (!urlPrefixes.count || !self.resourceURI.length) return;
    if (!_fileDownloadURLs) {
        NSMutableArray *fileDownloadURLs = [NSMutableArray arrayWithCapacity:urlPrefixes.count];
        for (NSString *urlPrefix in urlPrefixes) {
            [fileDownloadURLs addObject:[urlPrefix stringByAppendingString:self.resourceURI]];
        }
        _fileDownloadURLs = fileDownloadURLs.copy;
    }
}

- (NSString *)filePath {
    NSString *filePath;
    NSString *md5 = self.resourceURI;
    if (md5.length) {
        filePath = IESComposerResourceUncompressDirWithMD5(md5);
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return filePath;
    }
    return nil;
}

@end
