//
//  BEFInterfaceCommon.h
//  effect-ocInterface
//
//  Created by bytedance on 2020/8/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// TouchData
typedef NS_ENUM(NSUInteger, BEFInterfaceCommonTouchStatus) {
    BEFInterfaceCommonTouchStatusBegin = 0,
    BEFInterfaceCommonTouchStatusMove,
    BEFInterfaceCommonTouchStatusEnd,
    BEFInterfaceCommonTouchStatusCancel,
};

@interface BEFInterfaceCommonTouchData : NSObject
@property(nonatomic, assign) NSUInteger identify;
@property(nonatomic, assign) BEFInterfaceCommonTouchStatus actionType;
@property(nonatomic, assign) CGPoint pos;
@property(nonatomic, assign) CGFloat pressureForce;
@property(nonatomic, assign) CGFloat majorRadius;
@property(nonatomic, assign) NSTimeInterval timestamp;
- (instancetype)initWithTouch:(UITouch*)touch;
@end


@interface BEFInterfaceCommonMessageObject : NSObject
@property unsigned int msgid;
@property long arg1;
@property long arg2;
@property(nonatomic, strong) NSString* arg3;
@end

NS_ASSUME_NONNULL_END
