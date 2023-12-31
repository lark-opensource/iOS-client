//
//  ACCLocalAudioDataController.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/7/2.
//

#import "ACCLocalAudioDataController.h"
#import "AWEAssetModel.h"
#import "ACCEditVideoDataFactory.h"
#import "ACCAudioExport.h"
#import "AWEMusicCollectionData.h"
#import "ACCEditVideoDataDowngrading.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>

#import <MediaPlayer/MediaPlayer.h>

static NSString * const KACCLocalAudioResourceDomain = @"ACCLocalAudioDir";
NSErrorDomain const ACCLocalAudioErrorDomain = @"ACCLocalAudioErrorDomain";

typedef NS_ENUM(NSUInteger, ACCLocalAudioErrorCode) {
    ACCLocalAudioErrorCodeEmptyAudioURL,
};

@implementation ACCLocalAudioMusicDataConfigModel : NSObject
@end

@interface ACCLocalAudioDataController ()

@property (nonatomic, strong) ACCAudioExport *audioExporter;
@property (nonatomic,   copy) ACCExportLocalAudioCompletion exportCompletion;

@end

@implementation ACCLocalAudioDataController

#pragma mark - public

- (void)exportLocalAudioWithAssetModel:(AWEAssetModel *)assetModel completion:(ACCExportLocalAudioCompletion)completion
{
    self.exportCompletion = completion;
    
    NSString *tempDraftPath = [self localMusicFolderPath];
    ACCVEVideoData *videoData = acc_videodata_make_ve([ACCEditVideoDataFactory videoDataWithVideoAsset:assetModel.avAsset cacheDirPath:tempDraftPath]);
    
    UIView *view = [UIApplication sharedApplication].keyWindow;
    UIView<ACCProcessViewProtcol> *loadingView = [ACCLoading() showProgressOnView:view title:@"正在提取音频" animated:YES type:ACCProgressLoadingViewTypeProgress];
    [self performSelector:@selector(updateProcessWithView:) withObject:loadingView afterDelay:(5.0/83.0)];
    @weakify(loadingView);
    @weakify(self);
    loadingView.cancelable = YES;
    loadingView.cancelBlock = ^{
        @strongify(self);
        [self.audioExporter cancelAudioExport];
        self.exportCompletion = nil;
        @strongify(loadingView);
        [loadingView dismissWithAnimated:YES];
    };
    [self.audioExporter exportAllAudioSoundInVideoData:videoData completion:^(NSURL * _Nullable url, NSError * _Nullable error) {
        @strongify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(loadingView);
            loadingView.progress = 1;
            [loadingView dismissWithAnimated:YES];
            @strongify(self);
            if (error) {
                ACCBLOCK_INVOKE(self.exportCompletion, nil, error);
            } else {
                [self p_saveLocalAudioWithURL:url];
            }
        });
    }];
}

- (NSArray<AWEMusicCollectionData *> *)getCurrentLocalAudioFileSortedList
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *rootPath = [self localMusicFolderPath];
    NSError *err = nil;
    NSArray<NSString *> *pathsArr = [fileManager contentsOfDirectoryAtPath:rootPath error:&err];
    if (err) {
        AWELogToolError(AWELogToolTagMusic, @"Local audio read file error! %@", err);
    }
    NSMutableArray<NSString *> *filtedArr = [NSMutableArray array];
    // 根据后缀过滤音频文件
    [pathsArr enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *fileExtention = [obj pathExtension];
        if ([fileExtention isEqualToString:@"mp3"] || [fileExtention isEqualToString:@"m4a"]) {
            [filtedArr addObject:[rootPath stringByAppendingPathComponent:obj]];
        }
    }];
    
    // 按创建时间排序
    NSArray<NSString *> *sortedPaths = [filtedArr sortedArrayUsingComparator:^(NSString *firstPath, NSString *secondPath) {
        // 获取文件信息
        NSDictionary *firstFileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:firstPath error:nil];
        NSDictionary *secondFileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:secondPath error:nil];
        id firstData = [firstFileInfo objectForKey:NSFileCreationDate];
        id secondData = [secondFileInfo objectForKey:NSFileCreationDate];
        return [secondData compare:firstData];// 降序
    }];
    
    NSMutableArray<AWEMusicCollectionData *> *localAudioDataArray = [NSMutableArray array];
    @weakify(self);
    [sortedPaths enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        NSString *fileName = [[obj lastPathComponent] stringByDeletingPathExtension];
        NSURL *fileURL = [NSURL fileURLWithPath:obj];
        ACCLocalAudioMusicDataConfigModel *configModel = [[ACCLocalAudioMusicDataConfigModel alloc] init];
        configModel.localMusicURL = fileURL;
        configModel.musicName = fileName;
        configModel.isFromiTunes = NO;
        
        AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:fileURL
                                                     options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)
                                 }];
        configModel.assetDuration = CMTimeGetSeconds(audioAsset.duration);
        
        id<ACCMusicModelProtocol> localMusicModel = [self createMusicModelWithLocalAudioConfigModel:configModel];
        AWEMusicCollectionData *musicCollectionData = [[AWEMusicCollectionData alloc] initWithMusicModel:localMusicModel withType:AWEMusicCollectionDataTypeLocalMusicListSection];
        [localAudioDataArray addObject:musicCollectionData];
    }];
    [localAudioDataArray addObjectsFromArray:[self p_getCurrentiTunesMusicList]];
    return localAudioDataArray;
}

- (void)renameSingleLocalAudioWithAudio:(id<ACCMusicModelProtocol>)audio newName:(NSString *)newName
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *beforePath = audio.loaclAssetUrl.path;
    newName = [newName stringByAppendingPathExtension:[beforePath pathExtension]];
    NSString *afterPath = [[self localMusicFolderPath] stringByAppendingPathComponent:newName];
    if ([fileManager fileExistsAtPath:beforePath]) {
        if (![fileManager fileExistsAtPath:afterPath]) {
            NSError *error = nil;
            [fileManager moveItemAtPath:beforePath toPath:afterPath error:&error];
            if (error) {
                AWELogToolError(AWELogToolTagMusic, @"Local audio rename failed!");
            }
        } else {
            AWELogToolError(AWELogToolTagMusic, @"Local audio name has already existed!");
        }
    }
}

- (void)deleteSingleLocalAudio:(id<ACCMusicModelProtocol>)localMusic
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *localMusicPath = localMusic.loaclAssetUrl.path;
    if ([fileManager fileExistsAtPath:localMusicPath]) {
        NSError *error = nil;
        [fileManager removeItemAtPath:localMusicPath error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagMusic, @"Delete local audio failed! error: %@", error);
        }
    } else {
        AWELogToolError(AWELogToolTagMusic, @"Delete failed. Local audio not existed!");
    }
}

+ (void)clearLocalAudioCache
{
    // pm要求不清理本地提取音频，只清理iTunes缓存
    NSString *rootPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:KACCLocalAudioResourceDomain];
    NSString *path = [rootPath stringByAppendingPathComponent:@"iTunesMusicCache"];
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    for (NSString *content in contents) {
        NSString *filePath = [path stringByAppendingPathComponent:content];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
    }
}

#pragma mark - loading

- (void)updateProcessWithView:(UIView<ACCProcessViewProtcol> *)loadingView{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (loadingView.progress > 0.83) {
            return;
        } else {
            loadingView.progress = loadingView.progress + 0.01;
            [self performSelector:@selector(updateProcessWithView:) withObject:loadingView afterDelay:(5.0/83.0)];
        }
    });
}

#pragma mark - private

- (void)p_saveLocalAudioWithURL:(NSURL *)audioURL
{
    [self p_createLocalAudioDirIfNotExist:[self localMusicFolderPath]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:audioURL.path]) {
        AWELogToolError(AWELogToolTagMusic, @"Export local audio failed! AudioURL not existed: %@", audioURL.path);
        NSError *error = [NSError errorWithDomain:ACCLocalAudioErrorDomain code:ACCLocalAudioErrorCodeEmptyAudioURL userInfo:nil];
        ACCBLOCK_INVOKE(self.exportCompletion, nil, error);
        return;
    }
    
    NSString *fileExtension = [audioURL.path pathExtension];
    NSString *localAudioName = [self p_generateLocalAudioNameWithExtention:fileExtension];
    NSString *desPath = [localAudioName stringByAppendingPathExtension:fileExtension];
    desPath = [[self localMusicFolderPath] stringByAppendingPathComponent:desPath];
    
    if ([fileManager fileExistsAtPath:desPath]) {
        AWELogToolError(AWELogToolTagMusic, @"Export local audio failed! Existed a same file: %@", desPath);
    } else {
        NSError *fileError = nil;
        [fileManager copyItemAtPath:audioURL.path
                             toPath:desPath
                              error:&fileError];
        if (fileError) {
            AWELogToolError(AWELogToolTagMusic, @"Local audio copy failed, error: %@", fileError);
        }
    }
    
    NSURL *localMusicURL = [NSURL fileURLWithPath:desPath];
    ACCLocalAudioMusicDataConfigModel *configModel = [[ACCLocalAudioMusicDataConfigModel alloc] init];
    configModel.localMusicURL = localMusicURL;
    configModel.musicName = localAudioName;
    
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:audioURL
                                                 options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)
                             }];
    configModel.assetDuration = CMTimeGetSeconds(audioAsset.duration);
    
    id<ACCMusicModelProtocol> localMusicModel = [self createMusicModelWithLocalAudioConfigModel:configModel];
    AWEMusicCollectionData *musicCollectionData = [[AWEMusicCollectionData alloc] initWithMusicModel:localMusicModel withType:AWEMusicCollectionDataTypeLocalMusicListSection];
    ACCBLOCK_INVOKE(self.exportCompletion, musicCollectionData, nil);
}

- (NSArray<AWEMusicCollectionData *> *)p_getCurrentiTunesMusicList
{
    NSMutableArray *sectionData = [NSMutableArray array];
    // 请求媒体资料库权限
    if (@available(iOS 9.3, *)) {
        MPMediaLibraryAuthorizationStatus authStatus = [MPMediaLibrary authorizationStatus];
        if (authStatus == MPMediaLibraryAuthorizationStatusAuthorized) {
            MPMediaQuery *query = [[MPMediaQuery alloc] init];
            // 创建读取条件
            MPMediaPropertyPredicate *albumNamePredicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInt:MPMediaTypeMusic] forProperty:MPMediaItemPropertyMediaType];
            [query addFilterPredicate:albumNamePredicate];
            // 从队列中获取条件的数组集合
            NSArray *itemsFromGenericQuery = [query items];
            // 遍历解析数据
            for (MPMediaItem *music in itemsFromGenericQuery) {
                if ([music valueForProperty:MPMediaItemPropertyAssetURL]) {
                    AWEMusicCollectionData *singleData = [self p_generateCollectionDataWithMediaItem:music];
                    [sectionData acc_addObject:singleData];
                }
            }
        }
    }
    return sectionData;
}

- (AWEMusicCollectionData *)p_generateCollectionDataWithMediaItem:(MPMediaItem *)music
{
    // 歌名
    NSString *musicName = [music valueForProperty:MPMediaItemPropertyTitle];
    // 歌曲路径
    NSURL *fileURL = [music valueForProperty:MPMediaItemPropertyAssetURL];
    // 歌手名字
    NSString *singer = [music valueForProperty:MPMediaItemPropertyArtist];
    if(ACC_isEmptyString(singer))
    {
        singer = @"未知歌手";
    }
    fileURL = [self p_saveiTunesMusicCacheWithURL:fileURL musicName:[musicName stringByAppendingFormat:@"-%@", singer]];
    // 歌曲时长（单位：秒）
    NSTimeInterval duration = [[music valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
    // 过滤20min以上音频
    if (duration > 20.0 * 60.0) {
        return nil;
    }
    // 歌曲插图（没有就返回 nil）
    MPMediaItemArtwork *artwork = [music valueForProperty:MPMediaItemPropertyArtwork];
    UIImage *musicCover = [artwork imageWithSize:CGSizeMake(50, 50)];
    
    ACCLocalAudioMusicDataConfigModel *configModel = [[ACCLocalAudioMusicDataConfigModel alloc] init];
    configModel.localMusicURL = fileURL;
    configModel.musicName = musicName;
    configModel.singerName = singer;
    if (musicCover) {
        configModel.localMusicCoverURL = [self p_saveiTunesMusicCoverWithName:[musicName stringByAppendingFormat:@"-%@", singer] iTunesCover:musicCover];
    }
    configModel.assetDuration = duration;
    configModel.isFromiTunes = YES;
    
    id<ACCMusicModelProtocol> localMusicModel = [self createMusicModelWithLocalAudioConfigModel:configModel];
    AWEMusicCollectionData *musicCollectionData = [[AWEMusicCollectionData alloc] initWithMusicModel:localMusicModel withType:AWEMusicCollectionDataTypeLocalMusicListSection];
    return musicCollectionData;
}

- (NSURL *)p_saveiTunesMusicCoverWithName:(NSString *)iTunesMusicName iTunesCover:(UIImage *)iTunesCover
{
    NSString *imageDirPath = [[self localMusicFolderPath] stringByAppendingPathComponent:@"iTunesMusicCover"];
    [self p_createLocalAudioDirIfNotExist:imageDirPath];
    
    iTunesMusicName = [iTunesMusicName stringByAppendingPathExtension:@"png"];
    NSString *imageDesPath = [imageDirPath stringByAppendingPathComponent:iTunesMusicName];
    NSURL *imageDesURL = [NSURL fileURLWithPath:imageDesPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:imageDesPath]) {
        NSData *data = UIImagePNGRepresentation(iTunesCover);
        [data acc_writeToFile:imageDesPath atomically:YES];
    }
    return imageDesURL;
}

- (NSURL *)p_saveiTunesMusicCacheWithURL:(NSURL *)musicURL musicName:(NSString *)musicName
{
    NSString *musicCachePath = [[self localMusicFolderPath] stringByAppendingPathComponent:@"iTunesMusicCache"];
    [self p_createLocalAudioDirIfNotExist:musicCachePath];
    
    musicName = [musicCachePath stringByAppendingPathComponent:musicName];
    NSString *fileType = [[[[musicURL absoluteString] componentsSeparatedByString:@"?"] acc_objectAtIndex:0] pathExtension];
    NSString *finalPath = [musicName stringByAppendingPathExtension:fileType];
    NSURL *finalURL = [NSURL fileURLWithPath:finalPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:finalPath]) {
        AVURLAsset *audioAsset = [AVURLAsset assetWithURL:musicURL];
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:audioAsset presetName:AVAssetExportPresetPassthrough];
        exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        NSString *extension = [exportSession.outputFileType pathExtension];
        NSString *cacheDesPath = [musicName stringByAppendingPathExtension:extension];
        NSURL *cacheDesURL = [NSURL fileURLWithPath:cacheDesPath];
        exportSession.shouldOptimizeForNetworkUse = true;
        exportSession.outputURL = cacheDesURL;
                
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            if (exportSession.status == AVAssetExportSessionStatusCompleted){
                NSError *error = nil;
                [[NSFileManager defaultManager] moveItemAtPath:cacheDesURL.path toPath:finalPath error:&error];
                if (!error) {
                    [[NSFileManager defaultManager] removeItemAtPath:cacheDesURL.path error:&error];
                }
                if (error) {
                    AWELogToolError(AWELogToolTagMusic, @"Local iTunes audio export failed, error: %@", error);
                }
            } else if (exportSession.error) {
                AWELogToolError(AWELogToolTagMusic, @"Local iTunes audio export failed, error: %@", exportSession.error);
            }
        }];
    }
    return finalURL;
}

- (void)p_createLocalAudioDirIfNotExist:(NSString *)dirPath
{
    BOOL dir = NO;
    BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&dir];
    
    // 文件夹已被创建，返回
    if (dir && fileExist) {
        return;
    }
    
    // 存在与文件夹同名文件，先删除
    if (fileExist && !dir) {
        AWELogToolError(AWELogToolTagMusic, @"ACCLocalAudioDir has existed as a file. Try to resolve the conflict of two targets");
        NSError *err = nil;
        [[NSFileManager defaultManager] removeItemAtPath:dirPath error:&err];
        if (err != nil) {
            AWELogToolError(AWELogToolTagMusic, @"ACCLocalAudioDir has existed as a file. Failed to remove it. errorCode = %@, errorDesc = %@", @(err.code) , err.localizedDescription ? : @"");
        } else {
            AWELogToolInfo(AWELogToolTagMusic, @"Remove ACCLocalAudioDir file (path = %@) succeed.", dirPath ? : @"");
        }
    }
    
    // 创建文件夹
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (error != nil) {
        AWELogToolError(AWELogToolTagMusic, @"ACCLocalAudioDir creation failed with errorDesc = %@, errorCode = %@", error.localizedDescription ? : @"", @(error.code));
    } else {
        AWELogToolError(AWELogToolTagMusic, @"ACCLocalAudioDir creation succeed.");
    }
}

- (NSString *)p_generateLocalAudioNameWithExtention:(NSString *)fileExtention
{
    // 命名格式：提取音乐20210322-1
    NSString *audioBaseName = @"提取音频";
    NSString *dateStr = [[self dateFormatter] stringFromDate:[NSDate date]];
    NSString *audioName = [audioBaseName stringByAppendingString:dateStr];
    NSString *finalAudioName = audioName;
    if (ACC_isEmptyString(fileExtention)) {
        fileExtention = @"mp3";
    }
    NSInteger appendCount = 1;
    finalAudioName = [audioName stringByAppendingFormat:@"-%ld", (long)appendCount];
    NSString *desFilePath = [finalAudioName stringByAppendingPathExtension:fileExtention];
    desFilePath = [[self localMusicFolderPath] stringByAppendingPathComponent:desFilePath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    while ([fileManager fileExistsAtPath:desFilePath]) {
        appendCount++;
        finalAudioName = [audioName stringByAppendingFormat:@"-%ld", (long)appendCount];
        desFilePath = [finalAudioName stringByAppendingPathExtension:fileExtention];
        desFilePath = [[self localMusicFolderPath] stringByAppendingPathComponent:desFilePath];
    }
    
    return finalAudioName;
}

- (id<ACCMusicModelProtocol>)createMusicModelWithLocalAudioConfigModel:(ACCLocalAudioMusicDataConfigModel *)configModel
{
    NSMutableDictionary *music = [NSMutableDictionary dictionary];
    if ([[NSFileManager defaultManager] fileExistsAtPath:configModel.localMusicURL.path] || configModel.isFromiTunes) {
        music[@"title"] = configModel.musicName;
        music[@"author"] = configModel.singerName;
        
        if (configModel.localMusicCoverURL) {
            NSMutableDictionary *coverURLDic = [NSMutableDictionary dictionary];
            NSMutableArray *urlArr = [NSMutableArray array];
            [urlArr acc_addObject:configModel.localMusicCoverURL];
            coverURLDic[@"url_list"] = urlArr;
            music[@"cover_thumb"] = [coverURLDic acc_safeJsonObject];
        }
        
        NSMutableDictionary *playURLDic = [NSMutableDictionary dictionary];
        playURLDic[@"uri"] = configModel.localMusicURL;
        NSMutableArray *urlArray = [NSMutableArray array];
        [urlArray acc_addObject:configModel.localMusicURL];
        playURLDic[@"url_list"] = urlArray;
        music[@"play_url"] = [playURLDic acc_safeJsonObject];
        
        NSArray *jsonKeyArray = @[@"duration",@"shoot_duration",@"audition_duration"];
        for (NSString *key in jsonKeyArray) {
            music[key] = @(configModel.assetDuration);
        }
        music[@"video_duration"] = @(6000);
    }
    
    id<ACCMusicModelProtocol> localMusicModel = [IESAutoInline(ACCBaseServiceProvider(), ACCModelFactoryServiceProtocol) createMusicModelWithJsonDictionary:music];
    localMusicModel.loaclAssetUrl = configModel.localMusicURL;
    localMusicModel.originLocalAssetUrl = configModel.localMusicURL;
    localMusicModel.isFromiTunes = configModel.isFromiTunes;
    localMusicModel.isLocalScannedMedia = YES;
    return localMusicModel;
}

- (NSString *)localMusicFolderPath {
     return [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:KACCLocalAudioResourceDomain];
}

#pragma mark - getter

- (ACCAudioExport *)audioExporter
{
    if (!_audioExporter) {
        _audioExporter = [[ACCAudioExport alloc] init];
    }
    return _audioExporter;
}

- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"zh-CN"]];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT+0800"]];
        [_dateFormatter setDateFormat:@"yyyyMMdd"];
    });
    
    return _dateFormatter;
}

@end
