//
//  ACCRecordFlowComponentStickerPlugin.m
//  Indexer
//
//  Created by lixuan on 2021/11/1.
//

#import "ACCRecordFlowComponentStickerPlugin.h"
#import "ACCRecordFlowComponent.h"
#import "ACCLightningStyleRecordFlowComponent.h"
#import "ACCRecorderStickerServiceProtocol.h"
#import "ACCConfigKeyDefines.h"
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CreativeKit/ACCRecorderViewContainer.h>

@interface ACCRecordFlowComponentStickerPlugin ()

@property (nonatomic, strong, readonly) ACCRecordFlowComponent *hostComponent;
@property (nonatomic, strong) BOOL(^predicate)(id  _Nullable input, __autoreleasing id * _Nullable output);


@end

@implementation ACCRecordFlowComponentStickerPlugin

@synthesize component = _component;

+ (id)hostIdentifier
{
    return (ACCConfigBool(kConfigBool_enable_story_tab_in_recorder) && ACCConfigBool(kConfigBool_enable_lightning_style_record_button)) ? ACCLightingStyleRecordFlowComponent.class : ACCRecordFlowComponent.class;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    id<ACCRecorderStickerServiceProtocol> stickerService = IESOptionalInline(serviceProvider, ACCRecorderStickerServiceProtocol);
    @weakify(self);
    self.predicate = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        return NO;
    };
    
    [[[RACObserve(stickerService, containerInteracting) skip:1] distinctUntilChanged] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        id<ACCRecorderViewContainer> viewContainer = IESOptionalInline(serviceProvider, ACCRecorderViewContainer);
        if ([x boolValue]) {
            [self.hostComponent.shouldShowCaptureAnimationView addPredicate:self.predicate with:self];
            [viewContainer showItems:NO animated:YES];
        } else {
            [self.hostComponent.shouldShowCaptureAnimationView removePredicate:self.predicate];
            [viewContainer showItems:YES animated:YES];
        }
    }];
}

#pragma mark - Getter & Setter

- (ACCRecordFlowComponent *)hostComponent
{
    return self.component;
}
@end
