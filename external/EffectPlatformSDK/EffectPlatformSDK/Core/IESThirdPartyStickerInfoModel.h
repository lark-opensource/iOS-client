//
//  ISEThirdPartyStickerInfoModel.h
//  EffectPlatformSDK
//
//  Created by jindulys on 2019/2/25.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESThirdPartyStickerInfoModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, readonly, copy) NSString *url;
@property (nonatomic, readonly, copy) NSString *width;
@property (nonatomic, readonly, copy) NSString *height;
@property (nonatomic, readonly, copy) NSString *size;

@end

NS_ASSUME_NONNULL_END
