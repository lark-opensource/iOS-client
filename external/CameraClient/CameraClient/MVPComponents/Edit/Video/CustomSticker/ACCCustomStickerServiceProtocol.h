//
//  ACCCustomStickerService.h
//  CameraClient
//
//  Created by HuangHongsen on 2021/1/6.
//

#ifndef ACCCustomStickerService_h
#define ACCCustomStickerService_h

#import <CreationKitInfra/ACCRACWrapper.h>
@protocol ACCCustomStickerServiceProtocol<NSObject>
@property (nonatomic, strong, readonly) RACSignal *addCustomStickerSignal;
@end

#endif /* ACCCustomStickerService_h */
