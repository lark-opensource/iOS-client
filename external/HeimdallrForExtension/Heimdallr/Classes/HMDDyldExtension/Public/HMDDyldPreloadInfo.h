//
//  HMDDyldPreloadInfo.h
//  Pods
//
//  Created by APM on 2022/10/18.
//

@interface HMDDyldPreloadInfo : NSObject

@property (nonatomic, copy, nullable) NSError *error;

- (nonnull instancetype) initWithError:(NSError *_Nullable) error;

@end

