//
//  ACCSpeedControlViewModel.h
//  Pods
//
//  Created by liyingpeng on 2020/6/23.
//

#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CreationKitArch/HTSVideoDefines.h>
#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCGroupedPredicate;

typedef BOOL(^ACCSpeedControlShouldShowPredicate)(void);

@interface ACCSpeedControlViewModel : ACCRecorderViewModel

@property (nonatomic, assign) BOOL speedControlButtonSelected;
@property (nonatomic, strong, readonly) ACCGroupedPredicate *barItemShowPredicate;
//@property (nonatomic, strong, readonly) RACSignal *speedControlViewShowIfNeededSignal;

- (BOOL)defalutEnableSpeedControl;
//- (void)shouldShowSpeedControl:(BOOL)show;
- (void)addShouldShowPrediacte:(ACCSpeedControlShouldShowPredicate)predicate forHost:(id)host;
- (void)removeShouldShowPredicate:(ACCSpeedControlShouldShowPredicate)predicate;

- (nullable NSEnumerator<ACCSpeedControlShouldShowPredicate> *)predicateEnumerator;

@end

NS_ASSUME_NONNULL_END
