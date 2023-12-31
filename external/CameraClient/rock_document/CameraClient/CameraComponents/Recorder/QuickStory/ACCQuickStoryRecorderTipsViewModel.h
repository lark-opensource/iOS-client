//
//  ACCQuickStoryRecorderTipsViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2020/11/19.
//

#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCQuickStoryRecorderTipsViewModel : ACCRecorderViewModel

@property (nonatomic, copy, readonly) NSString *showingTips;
@property (nonatomic, strong, readonly) RACSignal *switchLengthViewShowIfNeededSignal;

// nil means not showing successfully
- (nullable NSNumber *)showRecordHintLabel:(NSString *)text exclusive:(BOOL)exclusive;
- (nullable NSNumber *)showRecordHintLabel:(NSString *)text;

- (void)hideRecordHintLabelWithToken:(nullable NSNumber *)token;
- (void)hideRecordHintLabel;
- (void)shouldShowSwitchLengthView:(BOOL)show;

@end

NS_ASSUME_NONNULL_END
