//
//  ACCCustomStickerComponentProtocol.h
//  CameraClient
//
//  Created by 卜旭阳 on 2020/6/25.
//


#import <CreationKitInfra/ACCModuleService.h>

@class IESEffectModel;

@protocol ACCCustomStickerComponentProtocol <NSObject>

- (void)selectCustomSticker:(IESEffectModel *)sticker fromTab:(NSString *)tabName completionBlock:(void(^)(void))completionBlock cancelBlock:(void(^)(void))cancelBlock;

@end
