//
//  HMDUITrackerManagerSceneProtocol.h
//  Pods
//
//  Created by bytedance on 2021/11/22.
//

#import <Foundation/Foundation.h>

@protocol HMDUITrackerManagerSceneProtocol <NSObject>

@property (atomic, copy, readonly, nullable) NSString *scene;

@property (atomic, strong, readonly, nullable) NSNumber *sceneInPushing;

@end
