//
//  IESInfoStickerResponseModel.h
//  EffectPlatformSDK-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/2/17.
//
#import <Mantle/Mantle.h>
#import "IESInfoStickerModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESInfoStickerResponseModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, readonly, strong) NSNumber *cursor;
@property (nonatomic, readonly, assign) BOOL hasMore;
@property (atomic, readonly, copy) NSArray<IESInfoStickerModel *> *stickerList;
@property (nonatomic, readonly, copy) NSString *title;

- (void)appendAndUpdateDataWithResponseModel:(IESInfoStickerResponseModel *)model;

@end

NS_ASSUME_NONNULL_END
