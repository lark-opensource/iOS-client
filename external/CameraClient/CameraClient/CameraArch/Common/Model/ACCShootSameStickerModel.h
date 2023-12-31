//
//  ACCShootSameStickerModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/16.
//

#import <Mantle/MTLModel.h>
#import <Mantle/MTLJSONAdapter.h>
#import "AWEInteractionStickerModel+DAddition.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCShootSameStickerModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, assign) AWEInteractionStickerType stickerType;
@property (nonatomic, strong, nullable) AWEInteractionStickerLocationModel *locationModel;
@property (nonatomic, strong, nullable) AWEInteractionStickerLocationModel *tempLocationModel;
@property (nonatomic, copy) NSString *stickerModelStr;
@property (nonatomic, assign, getter=isDeleted) BOOL deleted;
@property (nonatomic, copy, nullable) NSDictionary *referExtraParams;

@end

NS_ASSUME_NONNULL_END
