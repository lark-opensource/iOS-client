//
//  ACCPublishInteractionModel.h
//  CameraClient
//
//  Created by chengfei xiao on 2019/12/30.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEInteractionStickerModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCPublishInteractionModel : NSObject<NSCopying>

@property (nonatomic, strong) NSMutableArray <AWEInteractionStickerModel *> * interactionModelArray;// multiple video segment
@property (nonatomic, strong) NSMutableArray <AWEInteractionStickerLocationModel *> *currentSectionLocations;

@end

NS_ASSUME_NONNULL_END
