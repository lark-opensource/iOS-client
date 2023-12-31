//
//  ACCEditSpecialEffectServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2020/12/31.
//

#import <Foundation/Foundation.h>

#ifndef ACCEditSpecialEffectServiceProtocol_h
#define ACCEditSpecialEffectServiceProtocol_h

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditSpecialEffectServiceProtocol <NSObject>

@property (nonatomic, strong, readonly) RACSignal *willDismissVCSignal;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCEditSpecialEffectServiceProtocol_h */
