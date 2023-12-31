//
//  AWEInteractionPOIStickerModel.h
//  CameraClient-Pods-CameraClient
//
//  Created by yangying on 2021/3/22.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import <CameraClient/AWEInteractionStickerModel+DAddition.h>

static const NSInteger AWEInteractionStickerTypePOI = 1; //POI贴纸

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;
@interface AWEInteractionModernPOIStickerInfoModel : MTLModel<MTLJSONSerializing>
@property (nonatomic, assign) NSUInteger currentEffectIndex;
@property (nonatomic, copy, nullable)   NSArray<IESEffectModel *> *effects;
@property (nonatomic, copy, nullable)   NSString *currentPath;

@property (nonatomic, assign) NSUInteger loadingEffectIndex;
@end

@interface AWEInteractionPOIStickerModel : AWEInteractionStickerModel

@property (nonatomic, strong) NSDictionary *poiInfo;
@property (nonatomic, strong, nullable) NSDictionary *poiStyleInfo;

@end

NS_ASSUME_NONNULL_END
