//
//  ACCAction.h
//  Pods
//
//  Created by leo on 2019/12/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int, ACCActionStatus) {
    ACCActionStatusPending,
    ACCActionStatusSucceeded = 1,
    ACCActionStatusFailed = 2
};

@interface ACCAction : NSObject
@property (nonatomic, assign) int type;
@property (nonatomic, readonly) ACCActionStatus status;


+ (instancetype)action;
+ (instancetype)fulfilled;
+ (instancetype)rejected;

- (ACCAction *)fulfill;
- (ACCAction *)reject;

@end


NS_ASSUME_NONNULL_END
