//
//  RecorderServiceContainer.h
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/1/18.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "LVDCameraServiceInterface.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kLVDCacheUserDefaultsSuiteName;

@interface LVDCameraService : NSObject<LVDCameraServiceProtocol>

@end

NS_ASSUME_NONNULL_END
