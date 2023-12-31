//
//  ACCLiveStickerServiceProtocol.h
//  CameraClient
//
//  Created by raomengyun on 2021/1/29.
//

#ifndef ACCLiveStickerServiceProtocol_h
#define ACCLiveStickerServiceProtocol_h

#import <CreationKitInfra/ACCRACWrapper.h>

@protocol ACCLiveStickerServiceProtocol <NSObject>

@property (nonatomic, strong, readonly) RACSignal<NSNumber *> *toggleEditingViewSignal;

@end

#endif /* ACCLiveStickerServiceProtocol_h */
