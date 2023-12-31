//
//  HMDCDGenerator.h
//  Heimdallr
//
//  Created by maniackk on 2020/11/4.
//

#import <Foundation/Foundation.h>
#import "HeimdallrModule.h"

@class HMDCDUploader;

@interface HMDCDGenerator : HeimdallrModule

+ (instancetype _Nullable)sharedGenerator;

#pragma mark - Deprecated Attribute

@property (nonatomic, strong, readonly, nullable) HMDCDUploader *uploader DEPRECATED_ATTRIBUTE;

@end

