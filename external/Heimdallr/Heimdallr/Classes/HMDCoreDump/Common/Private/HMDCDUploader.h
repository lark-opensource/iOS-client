//
//  HMDCDUploader.h
//  Heimdallr
//
//  Created by maniackk on 2020/11/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDCDUploader : NSObject

@property (nonatomic, copy, readonly) NSString *coredumpRootPath;
@property (nonatomic, copy, readonly) NSString *coredumpPath;
@property (nonatomic, assign) NSUInteger maxCDZipFileSizeMB;

- (void)zipAndUploadCoreDump;

@end

NS_ASSUME_NONNULL_END
