//
//  IESThirdPartyStickerModel.h
//  AFgzipRequestSerializer
//
//  Created by jindulys on 2019/2/25.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

#import "IESThirdPartyStickerInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESThirdPartyStickerModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, readonly, copy) NSString *identifier;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *userName;
@property (nonatomic, readonly, strong) IESThirdPartyStickerInfoModel *thumbnailSticker;
@property (nonatomic, readonly, strong) IESThirdPartyStickerInfoModel *sticker;
@property (nonatomic, readonly, copy) NSString *clickURL;
@property (nonatomic, readonly, copy) NSString *extra;

@end

@interface IESThirdPartyStickerModel (EffectDownloader)

// exist when this effect is downloaded
@property (nonatomic, readonly, copy) NSString *filePath;
@property (nonatomic, readonly, assign) BOOL downloaded;

@end

NS_ASSUME_NONNULL_END
