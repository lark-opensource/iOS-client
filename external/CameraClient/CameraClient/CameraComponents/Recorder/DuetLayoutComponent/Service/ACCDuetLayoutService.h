//
//  ACCDuetLayoutService.h
//  CameraClient-Pods-Aweme
//
//  Created by Lincoln on 2020/12/9.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCDuetLayoutService;

@class ACCDuetLayoutManager, ACCDuetLayoutModel;

typedef RACTwoTuple<UIImage *, NSNumber *> *ACCDuetIconImagePack;
typedef RACTwoTuple<ACCDuetLayoutModel *, NSNumber *> *ACCDuetLayoutModelPack; //  需要手势事件传递

@protocol ACCDuetLayoutService <NSObject>

@property (nonatomic, strong, readonly) RACSignal<ACCDuetLayoutModelPack> *duetLayoutDidChangedSignal;
@property (nonatomic, strong, readonly) RACSignal<UIImage *> *updateIconSignal;
@property (nonatomic, strong, readonly) RACSignal<ACCDuetLayoutModel *> *shouldSwapCameraPositionSignal;
@property (nonatomic, strong, readonly)  RACSignal *applyDuetLayoutSignal;
@property (nonatomic, strong, readonly) RACSignal *successDownFirstLayoutResourceSignal;
@property (nonatomic, strong, readonly) RACSignal<NSNumber *> *refreshDuetLayoutsSignal;
@property (nonatomic, strong, readonly) RACSignal<ACCDuetIconImagePack> *duetIconImageReadySignal;

@property (nonatomic, strong, readonly) NSArray<ACCDuetLayoutModel *> *duetLayoutModels;
@property (nonatomic, assign, readonly) NSInteger firstTimeIndex;
@property (nonatomic, strong, readonly) ACCDuetLayoutManager *duetManager;

- (BOOL)enableDuetImportAsset;  // 合拍允许相册导入前置条件
- (BOOL)supportImportAssetDuetLayout; // 使用支持相册导入的布局，合拍&支持导入&支持的布局
- (void)handleMessageOfDuetLayoutChanged:(NSString * __nullable)duetLayout;

@end

NS_ASSUME_NONNULL_END
