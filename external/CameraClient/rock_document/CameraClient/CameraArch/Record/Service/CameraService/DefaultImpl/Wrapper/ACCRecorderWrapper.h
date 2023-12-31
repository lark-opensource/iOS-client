//
//  ACCRecorderWrapper.h
//  Pods
//
//  Created by liyingpeng on 2020/5/28.
//

#import <Foundation/Foundation.h>
#import "ACCRecorderProtocolD.h"
#import "ACCRecorderRedPacketProtocol.h"
#import "ACCRecorderLivePhotoProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecorderWrapper : NSObject <ACCRecorderProtocolD, ACCRecorderRedPacketProtocol, ACCRecorderLivePhotoProtocol>

@end

NS_ASSUME_NONNULL_END
