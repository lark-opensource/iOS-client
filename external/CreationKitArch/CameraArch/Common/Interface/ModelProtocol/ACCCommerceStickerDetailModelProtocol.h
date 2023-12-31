//
//  ACCCommerceStickerDetailModelProtocol.h
//  CameraClient
//
//  Created by guoshuai on 2021/1/11.
//

#ifndef ACCCommerceStickerDetailModelProtocol_h
#define ACCCommerceStickerDetailModelProtocol_h

#import "ACCURLModelProtocol.h"

@protocol ACCCommerceStickerDetailModelProtocol <NSObject>

@property (nonatomic, copy) NSString *screenDesc;
@property (nonatomic, assign) NSInteger expireTime; // Expiration time of business stickers

@property (nonatomic, strong) id<ACCURLModelProtocol> screenIconURL; // The icon shown on the photo page

@end

#endif /* ACCCommerceStickerDetailModelProtocol_h */
