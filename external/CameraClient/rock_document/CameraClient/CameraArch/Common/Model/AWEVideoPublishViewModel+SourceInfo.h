//
//  AWEVideoPublishViewModel+SourceInfo.h
//  AWEUserProfile-Pods-Aweme
//
//  Created by Yunxiang on 2020/8/22.
//

#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEVideoPublishViewModel (SourceInfo)

- (BOOL)videoUploadAddSourceInfoForItem:(AVMetadataItem *)item withKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
