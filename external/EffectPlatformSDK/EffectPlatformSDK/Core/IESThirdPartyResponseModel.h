//
//  IESThirdPartyResponseModel.h
//  EffectPlatformSDK
//
//  Created by jindulys on 2019/2/26.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

#import "IESThirdPartyStickerModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESThirdPartyResponseModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, readonly, copy) NSString *searchTips;
@property (nonatomic, readonly, assign) NSInteger cursor;
@property (nonatomic, readonly, assign) BOOL hasMore;
@property (nonatomic, readonly, copy) NSArray<IESThirdPartyStickerModel *> *stickerList;
@property (nonatomic, readonly, strong) IESThirdPartyResponseModel *gifsResponseModel;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, copy) NSString *requestID;

- (void)appendAndUpdateDataWithResponseModel:(IESThirdPartyResponseModel *)model;

@end

NS_ASSUME_NONNULL_END
