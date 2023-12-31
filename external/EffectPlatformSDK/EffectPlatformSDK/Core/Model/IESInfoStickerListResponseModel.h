//
//  IESInfoStickerListResponseModel.h
//  EffectPlatformSDK
//
//  Created by pengzhenhuan on 2021/2/22.
//
#import <Mantle/Mantle.h>
#import "IESInfoStickerModel.h"
#import "IESInfoStickerCategoryModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESInfoStickerListResponseModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString *version;
@property (nonatomic, copy, readonly) NSString *panelName;
@property (nonatomic, strong, readonly) NSArray<IESInfoStickerModel *> *stickerList;
@property (nonatomic, strong, readonly) NSArray<IESInfoStickerModel *> *collectionStickerList;
@property (nonatomic, strong, readonly) NSArray<IESInfoStickerCategoryModel *> *categoryList;
@property (nonatomic, copy, readonly) NSString *frontInfoStickerID;
@property (nonatomic, copy, readonly) NSString *rearInfoStickerID;
@property (nonatomic, copy, readonly) NSArray<NSString *> *urlPrefix;

- (void)preProcessEffects;

@end

NS_ASSUME_NONNULL_END
