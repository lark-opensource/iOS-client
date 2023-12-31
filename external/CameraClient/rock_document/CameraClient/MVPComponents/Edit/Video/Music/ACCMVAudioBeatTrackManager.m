//
//  ACCMVAudioBeatTrackManager.m
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/10/27.
//

#import "ACCMVAudioBeatTrackManager.h"
#import <EffectPlatformSDK/IESEffectModel.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddBaseApiPropertyKey.h>
#import <EffectPlatformSDK/IESEffectUtil.h>
#import <EffectPlatformSDK/IESEffectManager.h>

@interface ACCMVAudioBeatTrackManager ()

@property (nonatomic, strong) IESEffectModel *effectModel;

@end

@implementation ACCMVAudioBeatTrackManager

- (instancetype)initWithMVEffectModel:(IESEffectModel *)effectModel {
    self = [super init];
    if (self) {
        [self configAudioBeatTrackManagerWithMVEffectModel:effectModel];
    }
    return self;
}

// 配置数据
- (void)configAudioBeatTrackManagerWithMVEffectModel:(IESEffectModel *)effectModel {
    self.effectModel = effectModel;
    
    // 解析extra.json
    id extraJson = [effectModel.sdkExtra acc_jsonValueDecoded];
    NSDictionary *extra;
    if ([extraJson isKindOfClass:[NSDictionary class]]) {
        extra = extraJson;
    }
    
    BOOL isAudioBeatTrack = NO;
    if (extra) {
        isAudioBeatTrack = [[extra acc_stringValueForKey:@"mv_music_beat_tracking_offline"] boolValue];
    }
    self.isAudioBeatTrack = isAudioBeatTrack;
    
    // 非卡点类型，不继续解析
    if (!isAudioBeatTrack) return;
    
    float srcIn = 0;
    float srcOut = 0;
    float dstIn = 0;
    float dstOut = 0;
    NSString *musicFileName;
    if ([extra isKindOfClass:[NSDictionary class]]) {
        NSString *srcInStr = [extra acc_stringValueForKey:@"mv_music_src_in_time"];
        srcIn = [srcInStr floatValue];
        srcIn = MAX(0, srcIn); // 设置in边界最小值>=0
        
        NSString *srcOutStr = [extra acc_stringValueForKey:@"mv_music_src_out_time"];
        srcOut = [srcOutStr floatValue];
        srcIn = MIN(srcOut, srcIn); // 设置in边界最大值<=srcOut
        
        NSString *dstInStr = [extra acc_stringValueForKey:@"mv_music_dst_in_time"];
        dstIn = [dstInStr floatValue];
        dstIn = MAX(0, dstIn); // 设置in边界最小值>=0
        
        NSString *dstOutStr = [extra acc_stringValueForKey:@"mv_music_dst_out_time"];
        dstOut = [dstOutStr floatValue];
        dstIn = MIN(dstOut, dstIn); // 设置in边界最大值<=dstOut
        
        musicFileName = [extra acc_stringValueForKey:@"mv_music_file_path"];
    }
    
    self.srcIn = srcIn;
    self.srcOut = srcOut;
    self.dstIn = dstIn;
    self.dstOut = dstOut;
    self.musicFileName = musicFileName;
}

// 获取模板算法本地相对路径(TODO: 本来需要EffectPlatform SDK提供，本期排期跟不上，后续可以直接替换该方法)
- (NSString * _Nullable)modelRelativePathForAlgorithm {
    if (self.effectModel == nil) return nil;
    
    NSArray<NSString *> *algorithmNames = [IESEffectUtil getAlgorithmNamesFromAlgorithmRequirements:self.effectModel.algorithmRequirements];
    if (algorithmNames == nil || algorithmNames.count == 0) return nil;
    
    ieseffectmanager_resource_finder_t finder = [[IESEffectManager manager] getResourceFinder];
    NSString *algorithmName = algorithmNames[0];
    const char *modelName = [algorithmName cStringUsingEncoding:kCFStringEncodingUTF8];
    NSString *localModelPath = [NSString stringWithCString:finder(nil, nil, modelName) encoding:kCFStringEncodingUTF8];
    NSString *modelPath = [[NSURL URLWithString:localModelPath] relativePath];
    return modelPath;
}

@end
