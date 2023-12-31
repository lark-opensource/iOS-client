//
//  BDAutoTrackPageLeave.h
//  RangersAppLog
//
//  Created by bytedance on 2022/4/9.
//

#import <Foundation/Foundation.h>

@interface BDAutoTrackPageLeave : NSObject

@property (nonatomic, assign) BOOL enabled;


+ (instancetype)shared;

- (void)enterPage:(UIViewController *)vc;

- (void)leavePage:(UIViewController *)vc;


@end
