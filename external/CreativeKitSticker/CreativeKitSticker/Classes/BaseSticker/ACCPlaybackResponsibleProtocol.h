//
//  ACCPlaybackResponsibleProtocol.h
//  CameraClient
//
//  Created by Yangguocheng on 2020/6/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCPlaybackResponsibleProtocol <NSObject>

- (void)updateWithCurrentPlayerTime:(NSTimeInterval)currentPlayerTime;

@end

NS_ASSUME_NONNULL_END
