//
//  HMDEMUploader.h
//  AWECloudCommand
//
//  Created by maniackk on 2021/6/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDEMUploader : NSObject

@property (nonatomic, copy, readonly)NSString *EMRootPath;

- (void)zipAndUploadEMData;

@end

NS_ASSUME_NONNULL_END
