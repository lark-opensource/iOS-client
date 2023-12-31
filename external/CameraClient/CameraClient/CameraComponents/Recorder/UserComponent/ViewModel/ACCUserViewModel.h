//
//  ACCUserViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/12/17.
//

#import <CreationKitArch/ACCRecorderViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCUserViewModel : ACCRecorderViewModel

- (void)trackPrivacy:(BOOL)privacy propId:(NSString * _Nullable)propId;

@end

NS_ASSUME_NONNULL_END
