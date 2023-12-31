//
//  NLEResourceAV_OC+Extension.m
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/1/19.
//

#import "NLEResourceAV_OC+Extension.h"
#import "AWEAssetModel.h"
#import "ACCNLEBundleResource.h"

#import <CreationKitArch/AWEDraftUtils.h>
#import <NLEPlatform/NLEPathUtilities.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <TTVideoEditor/AVAsset+Utils.h>

static NSString *kDraftFolderKey = @"acc_ios_draftFolder";
static NSString *kDraftIsPrivateKey = @"acc_ios_isPrivate";

@implementation NLEResourceAV_OC (Extension)

+ (instancetype)videoResourceWithAsset:(AVAsset *)asset nle:(NLEInterface_OC *)nle
{
    NLEResourceAV_OC *videoResource = [[NLEResourceAV_OC alloc] init];
    [videoResource p_setupForVideoWithAsset:(AVURLAsset *)asset draftFolder:nle.draftFolder];
    nle.acc_bundleResource.videoResourceUUIDs[videoResource.UUID] = asset;
    
    return videoResource;
}

- (void)p_setupForVideoWithAsset:(AVAsset *)asset draftFolder:(NSString *)draftFolder {
    if (asset.frameImageURL) {
        // 图片资源
        self.resourceType = NLEResourceTypeImage;
        self.resourceId = [NSString stringWithFormat:@"%ld", (long)[asset hash]];
        
        UIImage *image  = [UIImage imageWithContentsOfFile:asset.frameImageURL.path];
        NSAssert(image != NULL, @"could not create image from %@", asset.frameImageURL.path);
        self.width = image.size.width;
        self.height = image.size.height;
        self.duration = asset.duration;
        if (self.duration.value <= 0) {
            self.duration = CMTimeMake(1 *USEC_PER_SEC, USEC_PER_SEC);
        }
        
        [self acc_setPrivateResouceWithURL:asset.frameImageURL
                               draftFolder:draftFolder];
    } else if ([asset isKindOfClass:[AVURLAsset class]]) {
        self.resourceType = NLEResourceTypeVideo;
        self.duration = asset.duration;
        [self acc_setPrivateResouceWithURL:((AVURLAsset *)asset).URL
                               draftFolder:draftFolder];
        
        AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        self.width = videoTrack.naturalSize.width;
        self.height = videoTrack.naturalSize.height;
    } else if ([asset isBlankVideo]) {
        // 占位视频，设置为 None
        self.resourceType = NLEResourceTypeNone;
        self.resourceId = [NSString stringWithFormat:@"%ld", (long)[asset hash]];
    }
    
    NSArray<AVAssetTrack *> *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    self.hasAudio = audioTracks.count > 0;
}

+ (instancetype)audioResourceWithAsset:(AVAsset *)asset nle:(NLEInterface_OC *)nle
{
    if (![asset isKindOfClass:[AVURLAsset class]]) {
        return nil;
    }
    
    NSURL *musicURL = ((AVURLAsset *)asset).URL;

    NLEResourceAV_OC *audioResource = [[NLEResourceAV_OC alloc] init];
    audioResource.resourceType = NLEResourceTypeAudio;
    audioResource.duration = asset.duration;
    [audioResource acc_setPrivateResouceWithURL:musicURL
                                    draftFolder:nle.draftFolder];
    
    nle.acc_bundleResource.audioResourceUUIDs[audioResource.UUID] = asset;
    return audioResource;
}

@end

@implementation NLEResourceNode_OC(ResourcePath)

- (BOOL)acc_movePrivateResouceToDraftFolder:(NSString *)draftFolder
{
    if (self.resourceFile.length == 0) {
        return NO;
    }
    
    if (!self.acc_isPrivate) {
        return NO;
    }
    
    NSURL *url = [NSURL fileURLWithPath:self.acc_path];
    NSError *error = nil;
    if (![url checkResourceIsReachableAndReturnError:&error]) {
        NSAssert(NO, @"asset [%@] is not reachable", url);
        AWELogToolError(AWELogToolTagEdit, @"[resource] url is not reachable, acc_path: %@ draftFolder:%@ resourceFile:%@, error: %@", self.acc_path, self.acc_draftFolder, self.resourceFile, error);
        return NO;
    }
    
    BOOL moved = NO;
    NSString *newPath = [NLEResourceNode_OC p_newFilePathIfNeedWithURL:url dirPath:draftFolder isMove:&moved];
    if (moved) {
        self.acc_draftFolder = draftFolder;
        [self acc_setPrivateResouceWithURL:[NSURL URLWithString:newPath] draftFolder:self.acc_draftFolder];
    }
    
    return moved;
}

- (void)acc_setPrivateResouceWithURL:(NSURL *)url draftFolder:(NSString *)draftFolder
{
    self.acc_isPrivate = YES;
    [self setAcc_path:url.absoluteURL.resourceSpecifier draftFolder:draftFolder];
}

- (void)acc_setGlobalResouceWithPath:(NSString *)path
{
    self.acc_isPrivate = NO;
    [self setAcc_path:path draftFolder:nil];
}

- (void)setAcc_path:(NSString *)path draftFolder:(NSString *)draftFolder
{
    /// 有几种格式的 path
    /// 1. /Document/xxxx 沙盒相对路径
    /// 2. /var/container/xxxx/Document/xxxxx 沙盒绝对路径
    /// 3. /var/xxxx/DCIM/xxxx 相册目录
    /// 4. file:///var/xxx/DCIM/xxx 文件 schema
    NSString *fileSchema = @"file://";
    NSString *pathWithoutSchema = [path hasPrefix:fileSchema] ? [path substringFromIndex:fileSchema.length] : path;
    
    // 特殊情况不会保存草稿，不需要使用相对路径
    if (draftFolder == nil || draftFolder.length == 0) {
        NSString *draftRoot = [AWEDraftUtils draftRootPath];
        if ([pathWithoutSchema hasPrefix:draftRoot]) {
            // 路径在草稿目录但是没有传 draftFolder 属于异常情况
            NSAssert(NO, @"draftFolder should not be nil");
        }
        self.resourceFile = path;
        return;
    }
    
    NSString *homeDir = NSHomeDirectory();
    NSAssert([draftFolder hasPrefix:homeDir], @"");
    
    NSString *draftFolderWithoutHome = [draftFolder substringFromIndex:homeDir.length];
    if ([pathWithoutSchema hasPrefix:draftFolder]) {
        // 将path改写为相对于rootPath的相对路径，格式为"./xxx"
        // 兼容冷启动后沙盒变化
        self.resourceFile = [@"." stringByAppendingString:[pathWithoutSchema substringFromIndex:draftFolder.length]];
    }
    else if ([pathWithoutSchema hasPrefix:draftFolderWithoutHome]) {
        self.resourceFile = [@"." stringByAppendingString:[pathWithoutSchema substringFromIndex:draftFolderWithoutHome.length]];
    } else {
        self.resourceFile = path;
    }
    
    self.acc_draftFolder = draftFolder;
}

- (NSString *)acc_path
{
    if ([self.resourceFile hasPrefix:@"./"]) {
        NSString *relativePath = [self.resourceFile substringFromIndex:1];
        return [self.acc_draftFolder stringByAppendingString:relativePath];
    }
    return self.resourceFile;
}

- (void)setAcc_draftFolder:(NSString *)acc_draftFolder
{
    [self setExtra:acc_draftFolder forKey:kDraftFolderKey];
}

- (BOOL)isRelatedPath:(NSString *)path
{
    if (path == nil) {
        return NO;
    }
    
    NSString *curPath = [self acc_path];
    NSString *fileSchema = @"file://";
    NSString *curPathWithoutSchema = [curPath hasPrefix:fileSchema] ? [curPath substringFromIndex:fileSchema.length] : curPath;
    NSString *pathWithoutSchema = [path hasPrefix:fileSchema] ? [path substringFromIndex:fileSchema.length] : path;
    return [curPathWithoutSchema isEqualToString:pathWithoutSchema];
}

- (NSString *)acc_draftFolder
{
    return [self getExtraForKey:kDraftFolderKey];
}

- (void)acc_fixSandboxDirWithDraftFolder:(NSString *)draftFolder
{
    NSString *homeDir = NSHomeDirectory();
    if (![self.resourceFile hasPrefix:@"./"] &&
        [self.resourceFile containsString:@"/Data/Application"]) {
        if (![self.resourceFile containsString:homeDir]) {
            NSString *newPath = [NLEPathUtilities resourcePathForFilePath:self.resourceFile];
            if (newPath.length > 0) {
                self.resourceFile = newPath;
            }
        }
    }
    
    if (self.acc_draftFolder.length > 0) {
        self.acc_draftFolder = draftFolder;
    }
}

- (void)setAcc_isPrivate:(BOOL)acc_isPrivate
{
    [self setExtra:@(acc_isPrivate).stringValue forKey:kDraftIsPrivateKey];
}

- (BOOL)acc_isPrivate
{
    return [[self getExtraForKey:kDraftIsPrivateKey] boolValue];
}

#pragma mark - Utils

+ (NSString *)p_newFilePathIfNeedWithURL:(NSURL *)url
                                 dirPath:(NSString *)dirPath
                                  isMove:(BOOL *)isMove {
    NSString *srcPath = url.path;
    
    if (dirPath.length == 0) {
        return srcPath;
    }
    
    if ([srcPath containsString:dirPath]) {
        return srcPath;
    }
    
    NSString *newFileName = [NSString stringWithFormat:@"DraftResource_%lf.%@", [[NSDate date] timeIntervalSince1970], srcPath.pathExtension];
    NSString *filePath = [dirPath stringByAppendingPathComponent:newFileName];
    NSError *error = nil;
    if ([NSFileManager.defaultManager fileExistsAtPath:filePath]) {   // rarely happen
        [NSFileManager.defaultManager removeItemAtPath:filePath error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagEdit, @"remove exist file failed: %@", error);
        }
    }
    
    [[NSFileManager defaultManager] copyItemAtURL:url toURL:[NSURL fileURLWithPath:filePath] error:&error];
    if (error) {
        AWELogToolError(AWELogToolTagEdit, @"copy file failed: %@", error);
    }
    
    if (isMove) {
        *isMove = YES;
    }
    return filePath;
}

@end
