//
//  ACCLiveServiceProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/9/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCLiveServiceProtocol <NSObject>

- (BOOL)canBeLivePodcast;

- (BOOL)hasCreatedLiveRoom;

@end

NS_ASSUME_NONNULL_END
