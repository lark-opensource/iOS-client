//
//  ACCInfoStickerServiceProtocol.h
//  CameraClient
//
//  Created by HuangHongsen on 2021/1/6.
//

#ifndef ACCInfoStickerServiceProtocol_h
#define ACCInfoStickerServiceProtocol_h

#import <CreationKitInfra/ACCRACWrapper.h>
#import "ACCAddInfoStickerContext.h"

@protocol ACCInfoStickerServiceProtocol <NSObject>

// 添加信息化贴纸成功
@property (nonatomic, strong, readonly) RACSignal<ACCAddInfoStickerContext *> *addStickerFinishedSignal;

@end


#endif /* ACCInfoStickerServiceProtocol_h */
