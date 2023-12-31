//
//  ACCEditVideoFilterService.h
//  CameraClient
//
//  Created by chengfei xiao on 2020/5/15.
//

#import "ACCEditViewModel.h"
#import "AWERecordFilterSwitchManager.h"
#import "AWEEditAndPublishViewData+Business.h"
#import <ReactiveObjC/RACSignal.h>
#import <ReactiveObjC/RACSubject.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;
@protocol ACCEditServiceProtocol;

@protocol ACCEditVideoFilterService <NSObject>
@property (nonatomic, strong, readonly) AWERecordFilterSwitchManager *filterSwitchManager;
@property (nonatomic, assign) BOOL ignoreSwitchGesture;
@property (nonatomic, strong, readonly) RACSignal *applyFilterSignal;
- (void)clearColorFilter;
@end


@interface ACCEditVideoFilterServiceImpl : NSObject <ACCEditVideoFilterService>
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) AWEVideoPublishViewModel *repository;

@property (nonatomic, copy) void(^handleClearFilterBlock)(void);

- (void)sendAppleFilterToSubscribers;

@end

NS_ASSUME_NONNULL_END
