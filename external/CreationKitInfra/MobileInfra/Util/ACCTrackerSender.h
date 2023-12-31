//
//  ACCTrackerSender.h
//  CameraClient
//
//  Created by haoyipeng on 2021/3/22.
//

#import <Foundation/Foundation.h>
@class RACSubject;

NS_ASSUME_NONNULL_BEGIN

@interface ACCTrackerSender : NSObject

- (RACSubject *)createSubject;

@end

NS_ASSUME_NONNULL_END
