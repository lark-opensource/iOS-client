//
//  ACCRecordPropCheckerComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/7/29.
//

#import "ACCRecordPropCheckerComponent.h"
#import "ACCRecordPropService.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "ACCPropViewModel.h"
#import "ACCRecordViewControllerInputData.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import "ACCRecordFlowService.h"
#import <CreativeKit/ACCMonitorToolProtocol.h>
#import "ACCMonitorToolDefines.h"

@interface ACCRecordPropCheckerComponent () <ACCRecordPropServiceSubscriber, ACCRecordSwitchModeServiceSubscriber, ACCRecordFlowServiceSubscriber>

@property (nonatomic, strong) id<ACCRecordPropService> propService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) ACCPropViewModel *viewModel;
@property (nonatomic, assign) BOOL changeByUser;
@property (nonatomic, assign) BOOL isOuter;
@property (nonatomic, strong) NSString *currentEffectIdentifier;

@end

@implementation ACCRecordPropCheckerComponent
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.propService addSubscriber:self];
    [self.switchModeService addSubscriber:self];
}

- (void)switchModeServiceWillChangeToMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    if (!mode.isVideo && !mode.isPhoto) {

    }
}

- (void)propServiceWillApplyProp:(IESEffectModel *)prop propSource:(ACCPropSource)propSource changeReason:(ACCRecordPropChangeReason)changeReason
{
    AWELogToolInfo2(@"Prop Checker", AWELogToolTagCommercialCheck, @"prop change to: %@, source: %@, by reason: %@", prop.effectIdentifier, [self sourceToString:propSource], [self reasonToString:changeReason]);
    if (changeReason == ACCRecordPropChangeReasonOuter) {
        self.isOuter = YES;
    } else if (changeReason == ACCRecordPropChangeReasonUserSelect ||
        changeReason == ACCRecordPropChangeReasonUserSelectColletion ||
        changeReason == ACCRecordPropChangeReasonUserCancel ||
        changeReason == ACCRecordPropChangeReasonKaraokeCancel ||
        changeReason == ACCRecordPropChangeReasonDuetPluginByUser ||
        changeReason == ACCRecordPropChangeReasonThemeRecord ||
        changeReason == ACCRecordPropChangeReasonScanCancel) {
        self.changeByUser = YES;
        self.isOuter = NO;
    } else {
        // ignore ACCPropSourceReset and ACCPropSourceRecognition
        if (propSource == ACCPropSourceReset || propSource == ACCPropSourceRecognition || propSource == ACCPropSourceFlower) {
            self.changeByUser = YES;
            self.isOuter = NO;
            self.currentEffectIdentifier = prop.effectIdentifier;
        }
        if (propSource == ACCPropSourceKeepWhenEdit) {
            self.changeByUser = NO;
            self.isOuter = NO;
            self.currentEffectIdentifier = prop.effectIdentifier;
        }
        if (self.isOuter && ![self.currentEffectIdentifier isEqual:prop.effectIdentifier]) {
            // warning, prop changed unexpectedly
            AWELogToolWarn2(@"Prop Checker", AWELogToolTagCommercialCheck, @"May be not as expected, prop change to: %@, by reason: %@", prop.effectIdentifier, [self reasonToString:changeReason]);
            NSMutableDictionary *extra = [@{@"msg": [NSString stringWithFormat:@"outer prop changed from id:%@ to id:%@", self.currentEffectIdentifier, prop.effectIdentifier], @"changeReason": [self reasonToString:changeReason], @"source": @(propSource)} mutableCopy];
            extra[ACCMonitorToolBusinessTypeKey] = @(ACCMonitorToolBusinessTypeProp);
            [ACCMonitorTool() showWithTitle:@"Prop Checker Warning"
                                      error:[NSError errorWithDomain:@"com.aweme.propcheck" code:-1 userInfo:extra]
                                      extra:extra
                                      owner:@"yangguocheng"
                                    options:ACCMonitorToolOptionModelAlert | ACCMonitorToolOptionUploadAlog | ACCMonitorToolOptionReportToQiaoFu | ACCMonitorToolOptionReportOnline];
        }
        if (![self.currentEffectIdentifier isEqual:prop.effectIdentifier]) {
            self.changeByUser = NO;
            self.isOuter = NO;
        }
    }
    self.currentEffectIdentifier = prop.effectIdentifier;
}

- (NSString *)reasonToString:(ACCRecordPropChangeReason)reason
{
    NSString *reasonString = @"unkown";
    switch (reason) {
        case ACCRecordPropChangeReasonOuter:
            reasonString = @"ACCRecordPropChangeReasonOuter";
            break;
        case ACCRecordPropChangeReasonUserSelect:
            reasonString = @"ACCRecordPropChangeReasonUserSelect";
            break;
        case ACCRecordPropChangeReasonUserSelectColletion:
            reasonString = @"ACCRecordPropChangeReasonUserSelectColletion";
            break;
        case ACCRecordPropChangeReasonAutoSuggestion:
            reasonString = @"ACCRecordPropChangeReasonAutoSuggestion";
            break;
        case ACCRecordPropChangeReasonUserCancel:
            reasonString = @"ACCRecordPropChangeReasonUserCancel";
            break;
        case ACCRecordPropChangeReasonKaraokeCancel:
            reasonString = @"ACCRecordPropChangeReasonKaraokeCancel";
            break;
        case ACCRecordPropChangeReasonSwitchMode:
            reasonString = @"ACCRecordPropChangeReasonSwitchMode";
            break;
        case ACCRecordPropChangeReasonRedpacketIntercept:
            reasonString = @"ACCRecordPropChangeReasonRedpacketIntercept";
            break;
        case ACCRecordPropChangeReasonMultiSegCancel:
            reasonString = @"ACCRecordPropChangeReasonMultiSegCancel";
            break;
        case ACCRecordPropChangeReasonDuetPluginByUser:
            reasonString = @"ACCRecordPropChangeReasonExitGame";
            break;
        case ACCRecordPropChangeReasonExitGame:
            reasonString = @"ACCRecordPropChangeReasonExitGame";
            break;
        case ACCRecordPropChangeReasonThemeRecord:
            reasonString = @"ACCRecordPropChangeReasonThemeRecord";
            break;
        default:
            break;
    }
    return reasonString;
}

- (NSString *)sourceToString:(ACCPropSource)source
{
    NSString *sourceString = @"unknow";
    
    switch (source) {
        case ACCPropSourceClassic:
            sourceString = @"ACCPropSourceClassic";
            break;
        case ACCPropSourceCollection:
            sourceString = @"ACCPropSourceCollection";
            break;
        case ACCPropSourceLocalProp:
            sourceString = @"ACCPropSourceLocalProp";
            break;
        case ACCPropSourceExposed:
            sourceString = @"ACCPropSourceExposed";
            break;
        case ACCPropSourceReset:
            sourceString = @"ACCPropSourceReset";
            break;
        case ACCPropSourceKeepWhenEdit:
            sourceString = @"ACCPropSourceKeepWhenEdit";
            break;
        case ACCPropSourceRecognition:
            sourceString = @"ACCPropSourceRecognition";
            break;
        case ACCPropSourceLiteTheme:
            sourceString = @"ACCPropSourceLiteTheme";
            break;
        case ACCPropSourceFlower:
            sourceString = @"ACCPropSourceFlower";
        default:
            break;
    }
    
    return sourceString;
}

- (ACCPropViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self getViewModel:[ACCPropViewModel class]];
    }
    return _viewModel;
}

@end
