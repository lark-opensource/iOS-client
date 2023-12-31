//
//  ACCRecordSelectPropViewModel.h
//  CameraClient
//
//  Created by chengfei xiao on 2020/4/9.
//

#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCRecordSelectPropDisplayType) {
    ACCRecordSelectPropDisplayTypeDefault = 0,
    ACCRecordSelectPropDisplayTypeShow,
    ACCRecordSelectPropDisplayTypeHidden,
    ACCRecordSelectPropDisplayTypeFadeHidden,
    ACCRecordSelectPropDisplayTypeFadeShow
};

typedef BOOL(^ACCSelectPropPredicate)(void);

@protocol ACCRecordSelectPropProvideProtocol <NSObject>
@property (nonatomic, strong, readonly) RACSignal *clickSelectPropBtnSignal;
@property (nonatomic, assign) ACCRecordSelectPropDisplayType selectPropDisplayType;
@end

@interface ACCRecordSelectPropViewModel : ACCRecorderViewModel <ACCRecordSelectPropProvideProtocol>

@property (nonatomic, copy) BOOL (^needHideUploadLabelBlock)(void);

- (void)sendSignalAfterClickSelectPropBtn;

- (void)configStickerBtnWithURLArray:(NSArray <NSString *> *)urlArray
                               index:(NSInteger)index
                          completion:(void(^)(UIImage *image))completion;

#pragma mark - Configuration

@property (nonatomic, strong, readonly) ACCGroupedPredicate *canShowUploadVideoLabel;
@property (nonatomic, nullable) NSString *stickerSwitchText;

@property (nonatomic, strong, readonly) ACCGroupedPredicate *canShowStickerPanelAtLaunch;

@end

NS_ASSUME_NONNULL_END
