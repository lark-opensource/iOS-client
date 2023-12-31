//
//  ACCVideoModelProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/12/29.
//

#ifndef ACCVideoModelProtocol_h
#define ACCVideoModelProtocol_h

#import "ACCURLModelProtocol.h"

@protocol ACCVideoModelProtocol <NSObject>

@property (nonatomic, strong) id<ACCURLModelProtocol> playURL;
@property (nonatomic, strong) id<ACCURLModelProtocol> coverURL;

// readonly property need to be trans to getter, or the mantle will crash due to readonly defined in protocol not have a ivar
- (id<ACCURLModelProtocol>)dynamicCover;
- (NSNumber *)height;
- (NSNumber *)width;

@end

#endif /* ACCVideoModelProtocol_h */
