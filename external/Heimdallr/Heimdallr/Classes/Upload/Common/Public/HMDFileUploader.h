//
//  HMDFileUploader.h
//  Heimdallr
//
//  Created by fengyadong on 2018/10/24.
//

#import <Foundation/Foundation.h>
#import "HMDFileUploadProtocol.h"

extern NSString * _Nonnull const kHMDFileUploadDefaultPath;

@interface HMDFileUploader : NSObject<HMDFileUploadProtocol>

+ (nonnull instancetype)sharedInstance;

@end

