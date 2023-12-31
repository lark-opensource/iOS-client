//
//  ACCKaraokeEditServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/3/28.
//

#ifndef ACCKaraokeEditServiceProtocol_h
#define ACCKaraokeEditServiceProtocol_h

#import <CreationKitInfra/ACCRACWrapper.h>

@protocol ACCMusicModelProtocol;

@protocol ACCKaraokeEditServiceProtocol <NSObject>

@property (nonatomic, strong, readonly) RACSignal<id<ACCMusicModelProtocol>> *didSelectMusicSignal;

@end
#endif /* ACCKaraokeEditServiceProtocol_h */
