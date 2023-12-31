//
//  ACCTextModeService.h
//  CameraClient-Pods-AwemeCore
//
//  Created by liujinze on 2021/11/4.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCRACWrapper.h>

@protocol ACCTextModeService <NSObject>

@property (nonatomic, strong, readonly, nonnull) RACSignal *textModeVCDidAppearSignal;

@end
