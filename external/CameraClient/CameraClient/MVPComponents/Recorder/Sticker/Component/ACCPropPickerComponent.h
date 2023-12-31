//
//  ACCPropPickerComponent.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/7/12.
//

#import <CreativeKit/ACCFeatureComponent.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEStickerPickerController;
@class AWEStickerPicckerDataSource;
@class ACCGroupedPredicate;
@protocol AWEStickerPickerDataContainerProtocol;

typedef id<AWEStickerPickerDataContainerProtocol>(^AWEStickerDataContainerCreator)(AWEStickerPicckerDataSource * _Nonnull);

@interface ACCPropPickerComponent : ACCFeatureComponent

@property (nonatomic, strong, readonly) AWEStickerPickerController *stickerPickerController;
@property (nonatomic, strong, readonly) AWEStickerPicckerDataSource *stickerDataSource;
@property (nonatomic, strong, readonly) ACCGroupedPredicate *skipStickerPredicate;
@property (nonatomic, strong, readonly) ACCGroupedPredicate *skipCategoryPredicate;

- (void)addDataContainerCreateBlock:(AWEStickerDataContainerCreator _Nonnull)block;

@end

NS_ASSUME_NONNULL_END
