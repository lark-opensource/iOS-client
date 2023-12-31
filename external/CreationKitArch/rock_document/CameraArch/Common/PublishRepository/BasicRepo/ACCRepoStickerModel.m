//
//  ACCRepoStickerModel.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/21.
//

#import "ACCRepoStickerModel.h"
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import <CreationKitArch/AWEInteractionStickerModel.h>
#import <CreationKitArch/ACCPublishInteractionModel.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import "ACCVideoDataProtocol.h"
#import "AWEInfoStickerInfo.h"
#import <TTVideoEditor/IESInfoSticker.h>

NSNotificationName const ACCVideoChallengeChangeKey = @"ACCVideoChallengeChangeKey";

@implementation AWEVideoPublishViewModel (RepoSticker)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoStickerModel.class];
    return info;
}

- (ACCRepoStickerModel *)repoSticker {
    ACCRepoStickerModel *stickerModel = [self extensionModelOfClass:ACCRepoStickerModel.class];
    NSAssert(stickerModel, @"extension model should not be nil");
    return stickerModel;
}

@end


@implementation ACCRepoStickerModel
@synthesize repository;

- (instancetype)init
{
    if (self = [super init]) {
        _infoStickerArray = @[].mutableCopy;
        _textReadingAssets = @{}.mutableCopy;
        _textReadingRanges = @{}.mutableCopy;
    }
    return self;
}

#pragma mark - getter

- (ACCPublishInteractionModel *)interactionModel
{
    if (!_interactionModel) {
        _interactionModel = [[ACCPublishInteractionModel alloc] init];
    }
    return _interactionModel;
}

#pragma mark - public
 
- (NSDictionary *)textStickerTrackInfo
{
    ASSERT_IN_SUB_CLASS
    return @{};
}

- (void)removeTextReadingInCurrentVideo
{
    id<ACCVideoDataProtocol> videoData = [self.repository extensionModelOfProtocol:@protocol(ACCVideoDataProtocol)];
    NSArray<AVAsset *> *toRemoves = [self allAudioAssetsInVideoData];
    if(toRemoves.count) {
        [videoData removeAudioWithAssets:toRemoves];
        [toRemoves enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [videoData removeAudioTimeClipInfoWithAsset:obj];
        }];
    }
    [self.textReadingAssets removeAllObjects];
    [self.textReadingRanges removeAllObjects];
}

- (AVAsset *)audioAssetInVideoDataWithKey:(NSString *)key
{
    if(!key) {
        return nil;
    }
    __block AVAsset *asset = [self.textReadingAssets objectForKey:key];
    if(asset) {
        id<ACCVideoDataProtocol> videoData = [self.repository extensionModelOfProtocol:@protocol(ACCVideoDataProtocol)];
        NSAssert(videoData, @"extension model should not be nil");
        [videoData.audioAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (asset == obj) {
                *stop = YES;
                return;
            }
            if ([obj isKindOfClass:[AVURLAsset class]] && [asset isKindOfClass:[AVURLAsset class]]) {
                NSString *originPath = ((AVURLAsset *)asset).URL.path.lastPathComponent;
                NSString *currentPath = ((AVURLAsset *)obj).URL.path.lastPathComponent;
                if ([originPath isEqualToString:currentPath]) {
                    asset = obj;
                    *stop = YES;
                }
            }
        }];
    }
    return asset;
}

// the same as 'allTextReadAudioAssetsInVideoData'
- (NSArray<AVAsset *> *)allAudioAssetsInVideoData
{
    NSMutableArray *allAssets = @[].mutableCopy;
    if(self.textReadingAssets.count) {
        [self.textReadingAssets.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            AVAsset *target = [self audioAssetInVideoDataWithKey:obj];
            if(target) {
                [allAssets addObject:target];
            }
        }];
    }
    return allAssets.copy;
}

- (NSDictionary *)customStickersInfos
{
    NSMutableDictionary *dict = @{@"is_diy_prop":@(NO),@"remove_background":@(NO)}.mutableCopy;
    id<ACCVideoDataProtocol> videoData = [self.repository extensionModelOfProtocol:@protocol(ACCVideoDataProtocol)];
    NSAssert(videoData, @"extension model should not be nil");
    [videoData.infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
        BOOL isCustomSticker = [obj.userinfo[@"isCustomSticker"] boolValue];
        BOOL useRemoveBg = [obj.userinfo[@"useRemoveBg"] boolValue];
        
        if (isCustomSticker) {
            [dict setObject:@(YES) forKey:@"is_diy_prop"];
        }
        
        if (useRemoveBg) {
            [dict setObject:@(YES) forKey:@"remove_background"];
        }
    }];
    return dict.copy;
}

- (BOOL)supportMusicLyricSticker
{
    ASSERT_IN_SUB_CLASS
    return NO;
}

#pragma mark - copying

- (id)copyWithZone:(NSZone *)zone {
    ACCRepoStickerModel *model = [[[self class] alloc] init];
    model.interactionStickers = [[NSArray alloc] initWithArray:self.interactionStickers copyItems:YES];
    model.interactionModel = self.interactionModel.copy;
    model.imageText = self.imageText;
    model.imageTextFonts = self.imageTextFonts;
    model.imageTextFontEffectIds = self.imageTextFontEffectIds;
    model.pollImage = self.pollImage;
    
    model.infoStickerArray = self.infoStickerArray.mutableCopy;
    
    model.textReadingAssets = self.textReadingAssets.mutableCopy;
    model.textReadingRanges = self.textReadingRanges.mutableCopy;
    model.gestureInvalidFrameValue = [self.gestureInvalidFrameValue copy];
    return model;
}

@end

