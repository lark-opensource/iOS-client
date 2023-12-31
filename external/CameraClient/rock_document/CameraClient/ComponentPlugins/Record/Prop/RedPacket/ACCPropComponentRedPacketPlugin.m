//
//  ACCPropComponentRedPacketPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by <#Bytedance#> on 2021/03/05.
//

#import "AWERepoContextModel.h"
#import "ACCPropComponentRedPacketPlugin.h"
#import "ACCPropComponentV2.h"
#import "ACCPropViewModel.h"
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import "IESEffectModel+ACCRedpacket.h"
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import <CameraClient/AWEVideoFragmentInfo.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>

@interface ACCPropComponentRedPacketPlugin ()

@property (nonatomic, strong, readonly) ACCPropComponentV2 *hostComponent;

@end

@implementation ACCPropComponentRedPacketPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCPropComponentV2 class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    
}

#pragma mark - Properties

- (void)bindToComponent:(ACCPropComponentV2 *)component
{
    ACCPropViewModel *viewModel = [component getViewModel:[ACCPropViewModel class]];
    @weakify(viewModel);
    [viewModel.shouldFilterProp addPredicate:^BOOL(IESEffectModel * _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(viewModel);
        if (viewModel == nil) {
            return YES;
        }
        AWEVideoPublishViewModel *publishViewModel = viewModel.inputData.publishModel;
        // TC
        return ((publishViewModel.repoReshoot.isReshoot ||
                publishViewModel.repoDuet.isDuet ||
                publishViewModel.repoContext.isIMRecord) && [input acc_isTC21Redpacket]);
    } with:self];
    
    [viewModel.isSpecialPropForVideoGuide addPredicate:^BOOL(IESEffectModel * _Nullable input, NSNumber *__autoreleasing * _Nullable output) {
        if (input.acc_isTC21Redpacket) {
            @strongify(viewModel);
            if (viewModel == nil) {
                return NO;
            }
            BOOL hasShowRedPacket = [ACCCache() boolForKey:@"acc_published_tc21_redpacket"];
            AWELogToolInfo(AWELogToolTagNone, @"hasShowRedPacket=%d|effectid=%@|", hasShowRedPacket, input.effectIdentifier);
            if (!hasShowRedPacket) {
                for (AWEVideoFragmentInfo *info in viewModel.inputData.publishModel.repoVideoInfo.fragmentInfo.copy) {
                    // 判断之前的片段是否也有红包视频
                    if (!hasShowRedPacket && info.hasRedpacketSticker) {
                        hasShowRedPacket = YES;
                        break;
                    }
                }
            }
            if (output != NULL) {
                *output = @(!hasShowRedPacket);
            }
            
            return YES;
        }
        return NO;
    } with:self];
}

- (ACCPropComponentV2 *)hostComponent
{
    return self.component;
}

@end
