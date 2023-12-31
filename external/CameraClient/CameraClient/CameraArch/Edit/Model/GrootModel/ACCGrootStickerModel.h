//
//  ACCGrootStickerModel.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/14.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import <CreationKitInfra/ACCBaseApiModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface  ACCGrootDetailsStickerModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) BOOL isDummy;
@property (nonatomic, copy, nullable) NSString *speciesName;
@property (nonatomic, copy, nullable) NSString *commonName;
@property (nonatomic, copy, nullable) NSString *categoryName;
@property (nonatomic, copy, nullable) NSNumber *prob;
@property (nonatomic, copy, nullable) NSNumber *baikeId;
@property (nonatomic, copy, nullable) NSString *baikeHeadImage;
@property (nonatomic, copy, nullable) NSString *baikeIcon;
@property (nonatomic, copy, nullable) NSString *engName;

@end

@interface ACCGrootStickerModel : MTLModel <MTLJSONSerializing, NSCopying>

@property (nonatomic, copy, readonly) NSString *effectIdentifier;
@property (nonatomic, copy) NSNumber *hasGroot;
@property (nonatomic, copy, nullable) ACCGrootDetailsStickerModel *selectedGrootStickerModel;
@property (nonatomic, copy) NSArray<ACCGrootDetailsStickerModel *> *grootDetailStickerModels;
@property (nonatomic, assign) BOOL allowGrootResearch;
@property (nonatomic, copy, nullable) NSDictionary *extra;
@property (nonatomic, copy) NSString *effectExtraInfo;
@property (nonatomic, copy, nullable) NSDictionary *userGrootInfo;
@property (nonatomic, assign) BOOL fromRecord;

- (instancetype)initWithEffectIdentifier:(nullable NSString *)effectIdentifier;

- (void)recoverDataFromDraftJsonString:(NSString *)jsonString;
- (NSString *)draftDataJsonString;

/// filter
/// @return 最终上传给服务器的模型数据
/// @param grootModelResultString 数据库中完整的信息
+ (NSString *)grootModelResultFilterWithString:(NSString *)grootModelResultString;

@end

#pragma mark - responseModel

@interface ACCGrootCheckModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) BOOL hasGroot;
@property (nonatomic, copy, nullable) NSDictionary *extra;

@end

@interface ACCGrootListModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, nullable) NSArray<ACCGrootDetailsStickerModel *> *grootList;
@property (nonatomic, copy, nullable) NSDictionary *extra;

@end

/// Used for GetGroot API
@interface ACCGrootListModelResponse : ACCBaseApiModel

@property (nonatomic, strong, nullable) ACCGrootListModel *data;

@end

/// Used for CheckGroot API
@interface ACCGrootCheckModelResponse : ACCBaseApiModel

@property (nonatomic, strong, nullable) ACCGrootCheckModel *data;

@end

NS_ASSUME_NONNULL_END
