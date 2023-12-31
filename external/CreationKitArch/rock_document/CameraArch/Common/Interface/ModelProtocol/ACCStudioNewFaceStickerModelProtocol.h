//
//  ACCStudioNewFaceStickerModelProtocol.h
//  CameraClient
//
//  Created by guoshuai on 2021/1/10.
//

#ifndef ACCStudioNewFaceStickerModelProtocol_h
#define ACCStudioNewFaceStickerModelProtocol_h

#import "ACCCommerceStickerDetailModelProtocol.h"

@protocol ACCStudioNewFaceStickerModelProtocol <NSObject>

@property (nonatomic, strong) id<ACCCommerceStickerDetailModelProtocol> commerceStickerModel;

@end

#endif /* ACCStudioNewFaceStickerModelProtocol_h */
