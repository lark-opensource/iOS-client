//
//  ACCAwemeModelProtocolD.h
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2021/9/26.
//

#import <Foundation/Foundation.h>

#import <CreationKitArch/ACCAwemeModelProtocol.h>
#import "ACCUserModelProtocolD.h"

@protocol ACCAwemeModelProtocolD <ACCAwemeModelProtocol>

@property (nonatomic, strong, nonnull) id<ACCUserModelProtocolD> author;
@property (nonatomic, strong, readonly, nonnull) id<ACCAwemeModelProtocolD> realItem;
@property (nonatomic, assign) NSInteger duetCount;

@end
