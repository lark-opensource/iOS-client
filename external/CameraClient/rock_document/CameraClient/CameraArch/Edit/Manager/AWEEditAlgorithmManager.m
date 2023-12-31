//
//  AWEEditAlgorithmManager.m
//  CameraClient-Pods-Aweme
//
//  Created by HuangHongsen on 2021/8/16.
//

#import "AWEEditAlgorithmManager.h"

#import "ACCMainServiceProtocol.h"
#import "ACCConfigKeyDefines.h"
#import "ACCMainServiceProtocol.h"
#import <CreationKitArch/ACCUserServiceProtocol.h>

#import <CreativeKit/ACCMacros.h>
#import <NLEPlatform/NLEInterface.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <EffectPlatformSDK/IESEffectManager.h>
#import <CreationKitInfra/ACCLogHelper.h>

#import <TTVideoEditor/VEAlgorithmSession.h>
#import <TTVideoEditor/VEAlgorithmSessionConfig.h>
#import "AWEEditAlgorithmManager.h"

static const NSInteger kAWEEditAlgorithmErrorAlgorithmRunning = -1001;
static const NSInteger kAWEEditAlgorithmErrorFailedToDownloadModel = -1002;

static AWEEditAlgorithmManager *sharedInstance;

@interface AWEEditAlgorithmManager()

@property (nonatomic, strong) VEAlgorithmSession *algorithmSession;

@property (nonatomic, assign) BOOL algorithmRunning;
@end

@implementation AWEEditAlgorithmManager

#pragma mark - Public APIs

+ (instancetype)sharedManager
{
    if (!sharedInstance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedInstance = [[AWEEditAlgorithmManager alloc] init];
        });
    }
    return sharedInstance;
}

- (BOOL)useBachToRecommend
{
    return self.recommendStrategy & AWEAIRecommendStrategyBachVector;
}

- (AWEAIRecommendStrategy)recommendStrategy
{
    if (![self shouldExtractFrames]) {
        return AWEAIRecommendStrategyNone;
    }
    ACCAIRecommendType recommendType = ACCConfigEnum(kConfigBool_edit_page_use_bach_ai_recommend, ACCAIRecommendType);
    if (recommendType == ACCAIRecommendTypeDefault) {
        if ([self shouldUploadFramesForRecommendation]) {
            return AWEAIRecommendStrategyUploadFrames;
        } else {
            return AWEAIRecommendStrategyNone;
        }
    } else if (recommendType == ACCAIRecommendTypeServerFirst) {
        if ([self shouldUploadFramesForRecommendation]) {
            return AWEAIRecommendStrategyUploadFrames;
        } else {
            return AWEAIRecommendStrategyBachVector;
        }
    } else if (recommendType == ACCAIRecommendTypeBachFirst) {
        AWEAIRecommendStrategy strategy = AWEAIRecommendStrategyBachVector;
        if ([self shouldUploadFramesForRecommendation]) {
            strategy |= AWEAIRecommendStrategyUploadFrames;
        }
        return strategy;
    }
    return AWEAIRecommendStrategyNone;
}


- (void)runAlgorithmOfType:(ACCEditImageAlgorithmType)type
            withImagePaths:(NSArray<NSString *> *)imagePaths
                completion:(void (^)(NSArray<NSNumber *> *, NSError *))completion
{
    if (self.algorithmRunning) {
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:kAWEEditAlgorithmErrorAlgorithmRunning userInfo:nil];
        ACCBLOCK_INVOKE(completion, nil, error);
        return ;
    }
    self.algorithmRunning = YES;
    @weakify(self)
    [self chekAndDownloadAlgorithmModelWithCompletion:^(BOOL success, NSError *error){
        @strongify(self)
        if (!success) {
            self.algorithmRunning = NO;
            ACCBLOCK_INVOKE(completion, nil, error);
            return ;
        } else {
            NSMutableArray *resultList = [NSMutableArray array];
            [self runAlgorithmOfType:type
                          imagePaths:imagePaths
                          resultList:resultList
                        currentIndex:0
                          completion:completion];
        }
    }];
}

#pragma mark - Private helper

- (void)chekAndDownloadAlgorithmModelWithCompletion:(void (^)(BOOL, NSError *))completion
{
    if ([[IESEffectManager manager] isAlgorithmDownloaded:[self modelNames]]) {
        ACCBLOCK_INVOKE(completion, YES, nil);
    } else {
        [EffectPlatform fetchResourcesWithRequirements:@[] modelNames:@{
            @"bach_smart_hashtag" : [self modelNames]} completion:^(BOOL success, NSError * _Nonnull error) {
            if (error || !success) {
                AWELogToolError(AWELogToolTagEffectPlatform, @"Effect Platfrom Download Algorithm Model Error: %@", error);
                NSError *downloadError = [NSError errorWithDomain:NSCocoaErrorDomain code:kAWEEditAlgorithmErrorFailedToDownloadModel userInfo:nil];
                ACCBLOCK_INVOKE(completion, NO, downloadError);
            } else {
                ACCBLOCK_INVOKE(completion, YES, nil);
            }
        }];
    }
}

- (NSArray *)modelNames
{
    return @[@"tt_smart_soundtrack", @"tt_hashtag"];
}

#pragma mark - Private helper

- (VECommonImageAlgorithmType)veAlgorithmTypeFromACCAlgorithmType:(ACCEditImageAlgorithmType)accAlgorithmType
{
    switch (accAlgorithmType) {
        case ACCEditImageAlgorithmTypeSmartHashtag:
            return VECommonImageAlgorithmType_Hashtag;
        case ACCEditImageAlgorithmTypeSmartSoundTrack:
            return VECommonImageAlgorithmType_SmartSoundtrack;
        default:
            return VECommonImageAlgorithmType_SmartSoundtrack;
    }
}

- (void)runAlgorithmOfType:(ACCEditImageAlgorithmType)type
                imagePaths:(NSArray<NSString *> *)imagePaths
                resultList:(NSMutableArray *)resultList
              currentIndex:(NSInteger)currentIndex
                completion:(void (^)(NSArray<NSNumber *> *, NSError *))completion
{
    if (currentIndex >= [imagePaths count]) {
        self.algorithmRunning = NO;
        NSArray<NSNumber *> *result = [self generateResultWithList:resultList];
        ACCBLOCK_INVOKE(completion,result, nil);
        return;
    }
    NSString *imagePath = imagePaths[currentIndex];
    VEAlgorithmSessionConfig *config = [[VEAlgorithmSessionConfig alloc] init];
    config.type = VEAlgorithmSessionType_CommonImage;
    VEAlgorithmSessionParamsBachCommonImage *params = [VEAlgorithmSessionParamsBachCommonImage new];
    params.imagePath = imagePath;
    params.resource_finder_t = [IESMMParamModule getResourceFinder];
    params.imageAlgorithmType = [self veAlgorithmTypeFromACCAlgorithmType:type];
    config.params = params;
    // 3.初始化 algorithmSession
        NSError *error = nil;
    self.algorithmSession = [[VEAlgorithmSession alloc] initWithConfig:config error:&error];
    if (self.algorithmSession == nil || error) {
        ACCLog(@"Algorithm: algorithm session creation fails - error: %@", error.userInfo);
        ACCBLOCK_INVOKE(completion, nil, error);
        return;
    }
    @weakify(self);
    [self.algorithmSession startWithCompletion:^(VEAlgorithmSessionResult * _Nonnull result) {
        @strongify(self);
        // 5.算法处理完成[按对应的接口Type结果进行解析]
        if (result.error == nil && result.type == VEAlgorithmSessionType_CommonImage && [result isKindOfClass:[VEAlgorithmSessionResultCommonImage class]]) {
            NSArray *commonImageInfo = ((VEAlgorithmSessionResultCommonImage *)result).commonImageInfo;
            if (commonImageInfo) {
                [resultList addObject:commonImageInfo];
            }
            [self runAlgorithmOfType:type imagePaths:imagePaths resultList:resultList currentIndex:currentIndex+1 completion:completion];
        } else {
            NSArray<NSNumber *> *resultArray = [self generateResultWithList:resultList];
            ACCBLOCK_INVOKE(completion, resultArray, result.error);
            self.algorithmRunning = NO;
        }
    }];
}

- (NSArray<NSNumber *> *)generateResultWithList:(NSArray *)list
{
    NSInteger count = -1;
    for (NSObject *obj in list) {
        if (![obj isKindOfClass:[NSArray class]]) {
            return nil;
        }
        NSArray *array = (NSArray *)obj;
        if (count < 0) {
            count = [array count];
        } else {
            if ([array count] != count) {
                return nil;
            }
        }
    }
    if (count < 0) {
        return nil;
    }
    NSMutableArray *result = [NSMutableArray array];
    for (NSInteger index = 0; index < count; index++) {
        float sum = 0.f;
        for (NSArray *row in list) {
            sum += [row[index] doubleValue];
        }
        [result addObject:@(sum / [list count ])];
    }
    return [result copy];
}

/**
 * 是否应该上传帧用于推荐智能配乐，智能封面，hashtag，小游戏锚点，标题，位置信息等。
 * 基于合规原则，如果用户没有开启预发布开关，不允许在发布之前上传内容。
 * 详见：https://bytedance.feishu.cn/docs/doccneqqafp6k1aTPuLknB9HiSd
 * @return should upload frames for music, cover, hashtag, game, title, poi recommendation.
 */
- (BOOL)shouldUploadFramesForRecommendation
{
    if (![self shouldExtractFrames]) {
        return NO;
    }

    // 使用“用户预发布开关”控制是否上传帧推荐；
    return [IESAutoInline(ACCBaseServiceProvider(), ACCMainServiceProtocol) isUserPreuploadEnabled];
}

- (BOOL)shouldExtractFrames
{
    /// 开启拍摄后登录模式禁止抽帧
    return [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin];
}

@end
