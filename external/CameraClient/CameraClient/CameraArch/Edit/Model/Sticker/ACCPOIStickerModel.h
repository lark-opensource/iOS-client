//
//  ACCPOIStickerModel.h
//  CameraClient
//
//  Created by liuqing on 2020/6/17.
//

#import <Foundation/Foundation.h>
#import "AWEInteractionPOIStickerModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCPOIStickerModel : NSObject

@property (nonatomic, copy) NSString *effectIdentifier;
@property (nonatomic, copy) NSString *poiID;
@property (nonatomic, copy) NSString *poiName;
@property (nonatomic, copy) NSArray<NSString *> *styleEffectIds;
@property (nonatomic, strong) AWEInteractionModernPOIStickerInfoModel *styleInfos;
@property (nonatomic, strong, null_resettable) AWEInteractionPOIStickerModel *interactionStickerInfo;

@end

NS_ASSUME_NONNULL_END
