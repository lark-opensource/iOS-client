//
//  ACCBaseInformationStickerDataManager.m
//  AWEStudio
//
//  Created by guochenxiang on 2018/9/20.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "ACCBaseInformationStickerDataManager.h"
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreationKitArch/ACCStudioServiceProtocol.h>
#import <HTSServiceKit/HTSMessageCenter.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreativeKit/ACCMacros.h>


@interface ACCBaseInformationStickerDataManager ()

@property (nonatomic, copy, readwrite) NSArray<IESCategoryModel *> *stickerCategories;
@property (nonatomic, copy, readwrite) NSArray<IESEffectModel *> *stickerEffects;

@property (nonatomic, assign) BOOL isRequestOnAir;
@property (nonatomic, assign) BOOL isLoginStateChange;
@property (nonatomic, strong) NSMutableArray *comletionArray;

@end

@implementation ACCBaseInformationStickerDataManager

- (instancetype)init
{
    if (self = [super init]) {
        _isRequestOnAir = NO;
        _comletionArray = @[].mutableCopy;
        
        [IESAutoInline(ACCBaseServiceProvider(), ACCStudioServiceProtocol) preloadInitializationEffectPlatformManager];
        REGISTER_MESSAGE(ACCUserServiceMessage, self);
    }
    return self;
}

- (void)dealloc {
    UNREGISTER_MESSAGE(ACCUserServiceMessage, self);
}

- (void)downloadStickersWithCompletion:(void(^)(BOOL downloadSuccess))completion
{
    if (completion) {
        [self.comletionArray addObject:completion];
    }
    
    if (self.isRequestOnAir) {
        return;
    }
    
    void(^completionWrapper)(BOOL downloadSuccess) = ^(BOOL downloadSuccess) {
        NSArray *completionArray = self.comletionArray.copy;
        [completionArray enumerateObjectsUsingBlock:^(void(^obj)(BOOL downloadSuccess), NSUInteger idx, BOOL * _Nonnull stop) {
            ACCBLOCK_INVOKE(obj, downloadSuccess);
        }];
        
        [self.comletionArray removeAllObjects];
        self.isRequestOnAir = NO;
    };
    
    NSString *panel = self.pannelName;
    @weakify(self);
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    [EffectPlatform checkEffectUpdateWithPanel:panel effectTestStatusType:(NSInteger)ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        @strongify(self);
        IESEffectPlatformResponseModel *response = [EffectPlatform cachedEffectsOfPanel:panel];
        if (!needUpdate && response.effects.count && !self.isLoginStateChange) {
            [self.logger logPannelUpdateFailed:panel updateDuration:CFAbsoluteTimeGetCurrent() - startTime];
            self.stickerCategories = response.categories;
            self.stickerEffects = response.effects;
            self.requestID = response.requestID;
            ACCBLOCK_INVOKE(completionWrapper, YES);
        } else {
            self.isRequestOnAir = YES;
            if (self.isLoginStateChange) {
                self.isLoginStateChange = NO;
            }
            [EffectPlatform downloadEffectListWithPanel:panel effectTestStatusType:(NSInteger)ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
                @strongify(self);
                self.requestID = response.requestID;
                BOOL success = !error && response.effects.count > 0;
                
                [self.logger logPannelUpdateFinished:panel needUpdate:YES updateDuration:CFAbsoluteTimeGetCurrent() - startTime success:success error:error];

                if (success) {
                    self.stickerCategories = response.categories;
                    self.stickerEffects = response.effects;
                    ACCBLOCK_INVOKE(completionWrapper, YES);
                } else {
                    ACCBLOCK_INVOKE(completionWrapper, NO);
                }
            }];
        }
    }];
}

- (void)didFinishLogin {
    self.isLoginStateChange = YES;
}

- (void)didFinishLogout {
    self.isLoginStateChange = YES;
}

@end
