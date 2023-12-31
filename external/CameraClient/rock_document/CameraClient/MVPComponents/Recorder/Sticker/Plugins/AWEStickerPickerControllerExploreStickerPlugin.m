//
//  AWEStickerPickerControllerExploretickerPlugin.m
//  Indexer
//
//  Created by wanghongyu on 2021/9/6.
//

#import "AWEStickerPickerControllerExploreStickerPlugin.h"
#import <CameraClient/AWEStickerPickerController.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreativeKit/ACCCacheProtocol.h>

#import "AWEStickerPickerExploreView.h"
#import "ACCPropExploreService.h"
#import "ACCBubbleProtocol.h"
#import "ACCPropViewModel.h"
#import "ACCPropExploreExperimentalControl.h"

NSString* const AWEStickerPickerExploreViewShowTimes = @"AWEStickerPickerExploreViewShowTimes";

@interface AWEStickerPickerControllerExploreStickerPlugin ()

@property (nonatomic, weak) ACCPropViewModel *viewModel;
@property (nonatomic, strong) AWEStickerPickerExploreView *exploreView;
@property (nonatomic, weak) AWEStickerPickerController *pickController;
@property (nonatomic, weak) id<ACCPropExploreService> propExploreService;

@end

@implementation AWEStickerPickerControllerExploreStickerPlugin

- (instancetype)initWithServiceProvider:(id<IESServiceProvider>)serviceProvider
                              viewModel:(ACCPropViewModel *)viewModel {
    self = [super init];
    if (self) {
        _viewModel = viewModel;
        _propExploreService = IESAutoInline(serviceProvider, ACCPropExploreService);
    }
    return self;
}

- (void)controllerViewDidLoad:(AWEStickerPickerController *)controller {
    self.pickController = controller;
    if (nil == self.exploreView) {
        self.exploreView = [[AWEStickerPickerExploreView alloc] init];
        [self.exploreView.exploreButton addTarget:self action:@selector(p_onExploreBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self.layoutManager addExploreView:self.exploreView];
    }
}

- (void)controller:(AWEStickerPickerController *)controller didShowOnView:(UIView *)view {
    [self p_showBubble];
}

- (void)p_showBubble {
    if (![[ACCPropExploreExperimentalControl sharedInstance] hiddenSearchEntry]) {
        return;
    }
    
    NSInteger times = [[ACCCache() objectForKey:AWEStickerPickerExploreViewShowTimes] intValue];
    if (times < 1) {
        [ACCBubble() showBubble:@"道具搜索移到这里了"
                        forView:self.exploreView
                     fromAnchor:CGPointMake(0, 0)
               anchorAdjustment:CGPointMake(0, 0)
               cornerAdjustment:CGPointMake(30, 0)
                      fixedSize:CGSizeZero
                    inDirection:ACCBubbleDirectionUp
                        bgStyle:ACCBubbleBGStyleDark
                     completion:nil];
        [ACCCache() setInteger:++times forKey:AWEStickerPickerExploreViewShowTimes];
    }
}

- (void)p_onExploreBtnClicked {
    [self.propExploreService showExplorePage];
    [ACCTracker() trackEvent:@"prop_explore" params:@{
        @"enter_from":@"video_shoot_page",
        @"shoot_way":self.viewModel.repository.repoTrack.referString ?: @"",
        @"creation_id":self.viewModel.repository.repoContext.createId ?: @"",
    }];
}


@end
