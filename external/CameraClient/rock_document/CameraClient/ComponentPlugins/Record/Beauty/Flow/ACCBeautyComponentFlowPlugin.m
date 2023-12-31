//
//  ACCBeautyComponentFlowPlugin.m
//  CameraClient-Pods-Aweme
//
//  Created by machao on 2021/5/27.
//

#import "ACCBeautyComponentFlowPlugin.h"
#import <CreationKitComponents/ACCBeautyFeatureComponent.h>
#import <CreationKitComponents/ACCBeautyService.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import "ACCRecordFlowService.h"
#import <CameraClient/AWEVideoFragmentInfo.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import "ACCBeautyBuildInDataSourceImpl.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitComponents/ACCFilterService.h>
#import <CreationKitComponents/ACCBeautyTrackerSender.h>

@interface ACCBeautyComponentFlowPlugin ()<ACCRecordFlowServiceSubscriber>

@property (nonatomic, strong, readonly) ACCBeautyFeatureComponent *hostComponent;

@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCBeautyService> beautyService;
@property (nonatomic, strong) id<ACCFilterService> filterService;
@end

@implementation ACCBeautyComponentFlowPlugin
@synthesize component = _component;

IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, beautyService, ACCBeautyService)
IESAutoInject(self.serviceProvider, filterService, ACCFilterService)

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCBeautyFeatureComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    id<ACCRecordFlowService> flowService = IESAutoInline(serviceProvider, ACCRecordFlowService);
    [flowService addSubscriber:self];
}

#pragma mark - ACCRecordFlowServiceSubscriber

- (void)flowServiceDidAddFragment:(AWEVideoFragmentInfo *)fragment {
    fragment.cameraPosition = [self.cameraService.cameraControl currentCameraPosition];
    [self fillBeautifyInfoForFragmentInfo:fragment];
}

- (void)flowServiceDidAddPictureToVideo:(AWEPictureToVideoInfo *)pictureToVideo {
    //@description: fillBeautifyInfoForFragmentInfo中的逻辑耦合过重，为了不修改其中的逻辑，
    //              此处使用一个空AWEVideoFragmentInfo去填充美颜需要上报的数据
    AWEVideoFragmentInfo *info = [[AWEVideoFragmentInfo alloc] initWithSourceType:AWEVideoFragmentSourceTypeRecord];
    
    [self fillBeautifyInfoForFragmentInfo:info];
    
    pictureToVideo.beautifyUsed = info.beautifyUsed;
    pictureToVideo.composerBeautifyUsed = info.composerBeautifyUsed;
    pictureToVideo.composerBeautifyInfo = info.composerBeautifyInfo;
    pictureToVideo.composerBeautifyEffectInfo = info.composerBeautifyEffectInfo;
}

- (void)fillBeautifyInfoForFragmentInfo:(AWEVideoFragmentInfo *)info
{
    // 保存Composer美颜信息, 只在使用了Composer的情况下才保存
    BOOL isUsingLocalBeautyResource = [self.beautyService isUsingLocalBeautyResource];
    NSMutableArray *composerBeautifyInfo = [[NSMutableArray alloc] init];
    NSMutableArray *composerBeautifyEffectInfo = [[NSMutableArray alloc] init];
    __block BOOL composerBeautifyUsed = NO; // 使用开关的情况下，表示用户是否打开了美颜开关；使用滑竿的情况下，表示用户是否调节了滑竿位置
    __block BOOL shouldAddToComposerBeautifyInfo = NO;
    NSArray *currentcategories = self.hostComponent.beautyPanel.composerVM.filteredCategories;
    
    // 根据新需求修改了beautifyEffectInfo的上报，保留了之前beautifyInfo的上报，只对beautifyEffectInfo的上报做了修改
    [currentcategories enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary *beautifyEffectInfo = [[NSMutableDictionary alloc] init];
        if ([obj isKindOfClass:[AWEComposerBeautyEffectCategoryWrapper class]]) {
            AWEComposerBeautyEffectCategoryWrapper *categoryWrapper = (AWEComposerBeautyEffectCategoryWrapper *)obj;
            if ([categoryWrapper.categoryName isEqualToString:@"美颜"]) {// 美颜这类美化如果美颜开关被关闭则上报无，否则上报所有美颜效果
                NSString *key = [self.hostComponent.beautyPanel.composerVM.effectViewModel.cacheObj.cacheKeysObj.categorySwitchOnKey stringByAppendingString:categoryWrapper.category.categoryIdentifier];
                id number = [ACCCache() objectForKey:key];
                if (![number boolValue]) {
                    [beautifyEffectInfo setValue:@0 ? : @"" forKey:@"id"];
                    [beautifyEffectInfo setValue:@0 forKey:@"strength"];
                    [beautifyEffectInfo setValue:@"无" forKey:@"effect_name"];
                    [beautifyEffectInfo setValue:@"" forKey:@"md5"];
                    [beautifyEffectInfo setValue:@0 forKey:@"is_valid"];
                    [composerBeautifyEffectInfo acc_addObject:beautifyEffectInfo.copy];
                } else {
                    for (AWEComposerBeautyEffectWrapper *effect in categoryWrapper.effects) {
                        if (effect.childEffects.count > 0) {
                            for (AWEComposerBeautyEffectWrapper *effectChild in effect.childEffects){
                                [beautifyEffectInfo setValue:effectChild.effect.effectIdentifier ? : @"" forKey:@"id"];
                                [beautifyEffectInfo setValue:@(round(effectChild.currentRatio * 100)) forKey:@"strength"];
                                [beautifyEffectInfo setValue:effectChild.effect.effectName ? : @"" forKey:@"effect_name"];
                                [beautifyEffectInfo setValue:effectChild.effect.md5 ? : @"" forKey:@"md5"];
                                [beautifyEffectInfo setValue:@(effectChild.available) forKey:@"is_valid"];
                                [composerBeautifyEffectInfo acc_addObject:beautifyEffectInfo.copy];
                            }
                        } else {
                            [beautifyEffectInfo setValue:effect.effect.effectIdentifier ? : @"" forKey:@"id"];
                            [beautifyEffectInfo setValue:@(round(effect.currentRatio * 100)) forKey:@"strength"];
                            [beautifyEffectInfo setValue:effect.effect.effectName ? : @"" forKey:@"effect_name"];
                            [beautifyEffectInfo setValue:effect.effect.md5 ? : @"" forKey:@"md5"];
                            [beautifyEffectInfo setValue:@(effect.available) forKey:@"is_valid"];
                            [composerBeautifyEffectInfo acc_addObject:beautifyEffectInfo.copy];
                        }
                    }
                }
            } else if ([categoryWrapper.categoryName isEqualToString:@"风格妆"]) {// 风格妆这类美化互斥，直接上报选中的风格妆效果
                AWEComposerBeautyEffectWrapper *effect = categoryWrapper.selectedEffect;
                [beautifyEffectInfo setValue:effect.effect.effectIdentifier ? : @"" forKey:@"id"];
                [beautifyEffectInfo setValue:@(round(effect.currentRatio * 100)) forKey:@"strength"];
                [beautifyEffectInfo setValue:effect.effect.effectName ? : @"" forKey:@"effect_name"];
                [beautifyEffectInfo setValue:effect.effect.md5 ? : @"" forKey:@"md5"];
                [beautifyEffectInfo setValue:@(effect.available) forKey:@"is_valid"];
                [composerBeautifyEffectInfo acc_addObject:beautifyEffectInfo.copy];
            } else if ([categoryWrapper.categoryName isEqualToString:@"美体"]) {// 美体类美颜如果手动选择无则上报无，其他情况正常上报除了无之外的所有美体效果
                if (categoryWrapper.userSelectedEffect.isNone) {
                    [beautifyEffectInfo setValue:categoryWrapper.userSelectedEffect.effect.effectIdentifier ? : @"" forKey:@"id"];
                    [beautifyEffectInfo setValue:@(round(categoryWrapper.userSelectedEffect.currentRatio * 100)) forKey:@"strength"];
                    [beautifyEffectInfo setValue:categoryWrapper.userSelectedEffect.effect.effectName ? : @"" forKey:@"effect_name"];
                    [beautifyEffectInfo setValue:categoryWrapper.userSelectedEffect.effect.md5 ? : @"" forKey:@"md5"];
                    [beautifyEffectInfo setValue:@(categoryWrapper.userSelectedEffect.available) forKey:@"is_valid"];
                    [composerBeautifyEffectInfo acc_addObject:beautifyEffectInfo.copy];
                } else {
                    for (AWEComposerBeautyEffectWrapper *effect in categoryWrapper.effects) {
                        if (!effect.isNone) {
                            if (effect.childEffects.count > 0) {
                                for (AWEComposerBeautyEffectWrapper *effectChild in effect.childEffects){
                                    [beautifyEffectInfo setValue:effectChild.effect.effectIdentifier ? : @"" forKey:@"id"];
                                    [beautifyEffectInfo setValue:@(round(effectChild.currentRatio * 100)) forKey:@"strength"];
                                    [beautifyEffectInfo setValue:effectChild.effect.effectName ? : @"" forKey:@"effect_name"];
                                    [beautifyEffectInfo setValue:effectChild.effect.md5 ? : @"" forKey:@"md5"];
                                    [beautifyEffectInfo setValue:@(effectChild.available) forKey:@"is_valid"];
                                    [composerBeautifyEffectInfo acc_addObject:beautifyEffectInfo.copy];
                                }
                            } else {
                                [beautifyEffectInfo setValue:effect.effect.effectIdentifier ? : @"" forKey:@"id"];
                                [beautifyEffectInfo setValue:@(round(effect.currentRatio * 100)) forKey:@"strength"];
                                [beautifyEffectInfo setValue:effect.effect.effectName ? : @"" forKey:@"effect_name"];
                                [beautifyEffectInfo setValue:effect.effect.md5 ? : @"" forKey:@"md5"];
                                [beautifyEffectInfo setValue:@(effect.available) forKey:@"is_valid"];
                                [composerBeautifyEffectInfo acc_addObject:beautifyEffectInfo.copy];
                            }
                        }
                    }
                }
            }
        }
    }];
    
    NSArray *currentEffects = self.composerEffectObj.currentEffects;
    [currentEffects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary *beautifyInfo = [[NSMutableDictionary alloc] init];
        shouldAddToComposerBeautifyInfo = NO;
        if ([obj isKindOfClass:[AWEComposerBeautyEffectWrapper class]]) {
            AWEComposerBeautyEffectWrapper *effectWrapper =(AWEComposerBeautyEffectWrapper *)obj;
            if ([effectWrapper isEffectSet]) {
                effectWrapper = effectWrapper.appliedChildEffect;
            }
            if (effectWrapper && !effectWrapper.isNone) {
                float ratio = effectWrapper.currentRatio;
                
                if (isUsingLocalBeautyResource) {
                    // upload three local beauty intensity
                    float intensity = [effectWrapper.items.firstObject effectValueForRatio:ratio];
                    if ([effectWrapper.effect.effectIdentifier isEqualToString:ACCBeautyBuildInSmoothKey]) {
                        info.smooth = intensity;
                    } else if ([effectWrapper.effect.effectIdentifier isEqualToString:ACCBeautyBuildInFaceLiftKey]) {
                        info.reshape = intensity;
                    } else if ([effectWrapper.effect.effectIdentifier isEqualToString:ACCBeautyBuildInBigEyeKey]) {
                        info.eye = intensity;
                    }
                }
                
                NSMutableArray *beautifyInfoItems = [[NSMutableArray alloc] init];
                [effectWrapper.items enumerateObjectsUsingBlock:^(AWEComposerBeautyEffectItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
                    if (!ACC_FLOAT_EQUAL_TO(ratio * [obj maxValue], [obj defaultValue])) {
                        // 如果有一个小项不等于默认值，认为用户使用了Composer美颜
                        composerBeautifyUsed = YES;
                    }
                    [item setValue:[NSString stringWithFormat:@"%@", @((NSInteger)round(ratio * 100))] forKey:@"value"];
                    [item setValue:obj.tag forKey:@"tag"];
                    [beautifyInfoItems acc_addObject:item];
                }];
                if (beautifyInfoItems.count > 0) {
                    shouldAddToComposerBeautifyInfo = YES;
                }
                [beautifyInfo setValue:effectWrapper.effect.effectIdentifier forKey:@"id"];
                [beautifyInfo setValue:beautifyInfoItems forKey:@"tags"];
            }
        }
        if (shouldAddToComposerBeautifyInfo) {
            [composerBeautifyInfo addObject:beautifyInfo];
        }
    }];
        
    if (isUsingLocalBeautyResource) {
        info.beautifyUsed = composerBeautifyUsed;
    } else {
        info.composerBeautifyUsed = composerBeautifyUsed;
        
        NSError *error = nil;
        if ([NSJSONSerialization isValidJSONObject:composerBeautifyInfo]) {
            NSData *arrJsonData = [NSJSONSerialization dataWithJSONObject:composerBeautifyInfo options:kNilOptions error:&error];
            if (arrJsonData && !error) {
                info.composerBeautifyInfo = [[NSString alloc] initWithData:arrJsonData encoding:NSUTF8StringEncoding];
            }
            if (error) {
                AWELogToolError(AWELogToolTagRecord, @"composer beauty info json serialize error :%@", error);
            }
        }
        if (composerBeautifyEffectInfo && [NSJSONSerialization isValidJSONObject:composerBeautifyEffectInfo]) {
            error = nil;
            NSData *arrJsonData = [NSJSONSerialization dataWithJSONObject:composerBeautifyEffectInfo options:kNilOptions error:&error];
            if (error) {
                AWELogToolError(AWELogToolTagRecord, @"composer beauty effect info json serialize error :%@", error);
            }
            if (arrJsonData && !error) {
                info.composerBeautifyEffectInfo = [[NSString alloc] initWithData:arrJsonData encoding:NSUTF8StringEncoding];
            }
        }
    }
}

- (void)flowServiceDidCompleteRecord {

    [self.hostComponent.trackSender sendFlowServiceDidCompleteRecordSignal];
}

- (void)flowServiceTurnOffPureMode
{
    [self.hostComponent applyEffectsWhenTurnOffPureMode];
}

#pragma mark - getter
- (AWEComposerBeautyEffectViewModel *)composerEffectObj
{
    return self.beautyService.effectViewModel;
}

- (ACCBeautyFeatureComponent *)hostComponent {
    return self.component;
}
@end
