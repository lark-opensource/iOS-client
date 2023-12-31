//
//  AWEInteractionEditTagStickerModel.h
//  CameraClient-Pods-AwemeCore
//
//  Created by 卜旭阳 on 2021/10/6.
//

#import <CreationkitArch/AWEInteractionStickerModel.h>
#import "ACCEditTagsDefine.h"

typedef NS_ENUM(NSInteger, ACCEditTagOrientation) {
    ACCEditTagOrientationLeft = 0,
    ACCEditTagOrientationRight = 1
};

@interface AWEInteractionEditTagUserTagModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, nullable, strong) NSString *userID;
@property (nonatomic, nullable, copy) NSString *secUID;

@end

@interface AWEInteractionEditTagCustomTagModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, nullable, strong) NSString *name;

@end

@interface AWEInteractionEditTagPOITagModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, nullable, strong) NSString *POIID;

@end

@interface AWEInteractionEditTagGoodsTagModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, nullable, strong) NSString *productID;
@property (nonatomic, nullable, strong) NSString *schema;

@end

@interface AWEInteractionEditTagBrandTagModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, nullable, strong) NSString *brandID;
@property (nonatomic, nullable, strong) NSString *schema;

@end

@interface AWEInteractionEditTagStickerInfoModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) ACCEditTagType type;
@property (nonatomic, copy, nullable) NSString *text;
@property (nonatomic, assign) ACCEditTagOrientation orientation;

@property (nonatomic, strong, nullable) AWEInteractionEditTagCustomTagModel *customTag;
@property (nonatomic, strong, nullable) AWEInteractionEditTagUserTagModel *userTag;
@property (nonatomic, strong, nullable) AWEInteractionEditTagPOITagModel *POITag;
@property (nonatomic, strong, nullable) AWEInteractionEditTagGoodsTagModel *goodsTag;
@property (nonatomic, strong, nullable) AWEInteractionEditTagBrandTagModel *brandTag;

- (nullable NSString *)tagId;
- (nullable NSString *)tagType;
- (BOOL)interactional;

@end

@interface AWEInteractionEditTagStickerModel : AWEInteractionStickerModel

@property (nonatomic, strong, nullable) AWEInteractionEditTagStickerInfoModel *editTagInfo;

@end
