//
//  ACCSearchStickerServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/2/18.
//

#ifndef ACCSearchStickerServiceProtocol_h
#define ACCSearchStickerServiceProtocol_h

#import <CreationKitInfra/ACCRACWrapper.h>

@protocol ACCSearchStickerServiceProtocol <NSObject>

@property (nonatomic, strong, readonly) RACSignal *addSearchedStickerSignal;
@property (nonatomic, strong, readonly) RACSignal *configPannelStatusSignal;

@end

#endif /* ACCSearchStickerServiceProtocol_h */
