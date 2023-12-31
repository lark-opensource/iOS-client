//
//  ACCASSMusicBannerView.h
//  AWEStudio
//
//  Created by 旭旭 on 2018/8/31.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "ACCMusicTransModelProtocol.h"
#import "ACCSelectMusicViewControllerProtocol.h"
#import "HTSVideoAudioSupplier.h"

#import <CreationKitInfra/ACCModuleService.h>

@interface ACCASSMusicBannerView : UIView<HTSVideoAudioSupplier>

@property (nonatomic, assign) NSTimeInterval autoLoopDuration;
@property (nonatomic, copy) NSArray<id<ACCBannerModelProtocol>> *bannerList;
@property (nonatomic, assign) BOOL didRecieveAutualData;
@property (nonatomic, assign) BOOL canSelected;
@property (nonatomic, assign) BOOL canAutoLoop;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, copy) NSString *previousPage;
@property (nonatomic, assign) BOOL shouldHideCellMoreButton;
@property (nonatomic, assign) ACCServerRecordMode recordMode;
@property (nonatomic, assign) NSTimeInterval videoDuration;
@property (nonatomic, strong) id<ACCTransitionViewControllerProtocol> transitionDelegate;

- (void)refresh;
- (void)startCarousel;
- (void)stopCarousel;

@end
