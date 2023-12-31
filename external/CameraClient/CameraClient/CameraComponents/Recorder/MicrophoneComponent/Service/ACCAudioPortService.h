//
//  ACCAudioPortService.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/3.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/RACSignal.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCAudioIOPort) {
    ACCAudioIOPortBuiltin,
    ACCAudioIOPortBluetooth,
    ACCAudioIOPortWiredHeadset,
};

@protocol ACCAudioPortService <NSObject>

@property (nonatomic, assign, readonly) ACCAudioIOPort inputPort;
@property (nonatomic, assign, readonly) ACCAudioIOPort outputPort;

@property (nonatomic, strong, readonly) RACSignal<RACTwoTuple *> *IOPortChangeSignal;

@end

NS_ASSUME_NONNULL_END
