//
//  ACCFlowerService.h
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/11/12.
//

#import <Foundation/Foundation.h>

@class RACSignal, ACCRecordViewControllerInputData, ACCFlowerPanelEffectModel;
@protocol ACCFlowerService, ACCRecorderViewContainer;


@protocol ACCFlowerServiceSubscriber <NSObject>

@optional
- (void)flowerServiceWillEnterFlowerMode:(nullable id<ACCFlowerService>)service;
- (void)flowerServiceDidEnterFlowerMode:(nullable id<ACCFlowerService>)service;
- (void)flowerServiceDidLeaveFlowerMode:(nullable id<ACCFlowerService>)service;

- (void)flowerServiceDidChangeFromItem:(nullable ACCFlowerPanelEffectModel *)prevItem toItem:(nullable ACCFlowerPanelEffectModel *)item;

- (void)flowerServiceDidOpenTaskPanel:(nullable id<ACCFlowerService>)service;
- (void)flowerServiceDidCloseTaskPanel:(nullable id<ACCFlowerService>)service;

// 这些奇怪的方法，放在这里兼容吧
- (BOOL)flowerService:(id<ACCFlowerService>)flowerService JSBDidRequestApplyPropWithID:(NSString *)propID;
- (void)flowerServiceDidReceivePrefetchRequest:(id<ACCFlowerService>)flowerService;

@end


@protocol ACCFlowerService <NSObject>

@property (nonatomic, strong, readonly, nullable) ACCRecordViewControllerInputData *inputData;
@property (nonatomic, weak, nullable) id<ACCRecorderViewContainer> viewContainer;

@property (nonatomic, assign) BOOL inFlowerPropMode;
@property (nonatomic, strong, readonly, nullable) ACCFlowerPanelEffectModel *currentItem;
@property (nonatomic, assign, readonly) BOOL isShowingPhotoProp;
@property (nonatomic, assign, readonly) BOOL isCurrentScanProp;

- (void)updateCurrentItem:(nullable ACCFlowerPanelEffectModel *)item;

- (void)addSubscriber:(nullable id<ACCFlowerServiceSubscriber>)subscriber;
- (void)removeSubscriber:(nullable id<ACCFlowerServiceSubscriber>)subscriber;

@property (nonatomic, assign, readonly) BOOL isShowingLynxWindow;
- (void)broadcastDidOpenTaskPanelMsg;
- (void)broadcastDidCloseTaskPanelMsg;


- (BOOL)JSBDidRequestApplyPropWithID:(nullable NSString *)propID;
- (void)prefetchFlowerPanelData;



@end
