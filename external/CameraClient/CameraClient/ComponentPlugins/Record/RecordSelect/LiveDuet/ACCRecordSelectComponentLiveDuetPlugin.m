//
//  ACCRecordSelectComponentLiveDuetPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by <#Bytedance#> on 2021/03/04.
//

#import "AWERepoPropModel.h"
#import "ACCRecordSelectComponentLiveDuetPlugin.h"
#import "ACCRecordSelectPropComponent.h"
#import "ACCRecordSelectPropViewModel.h"
#import <CreativeKit/ACCMacrosTool.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>

@interface ACCRecordSelectComponentLiveDuetPlugin ()

@property (nonatomic, strong, readonly) ACCRecordSelectPropComponent *hostComponent;

@end

@implementation ACCRecordSelectComponentLiveDuetPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCRecordSelectPropComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    
}

- (void)bindToComponent:(ACCRecordSelectPropComponent *)component
{
    ACCRecordSelectPropViewModel *viewModel = [component getViewModel:[ACCRecordSelectPropViewModel class]];
    @weakify(viewModel);
    [viewModel.canShowStickerPanelAtLaunch addPredicate:^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(viewModel);
        if (viewModel == nil) {
            return YES;
        }
        
        return ![ACCRecordSelectComponentLiveDuetPlugin isLiveDuetPhotoSession:viewModel.inputData.publishModel];
    } with:self];
    
    if ([ACCRecordSelectComponentLiveDuetPlugin isLiveDuetPhotoSession:viewModel.inputData.publishModel]) {
        viewModel.stickerSwitchText = @"合拍背景";
    }
}

#pragma mark - Properties

- (ACCRecordSelectPropComponent *)hostComponent
{
    return self.component;
}

+ (BOOL)isLiveDuetPhotoSession:(AWEVideoPublishViewModel *)publishModel {
    return !ACC_isEmptyString(publishModel.repoProp.liveDuetPostureImagesFolderPath);
}

@end
