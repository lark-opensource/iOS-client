//
//  BDABTestExperimentItemModel.h
//  ABSDKDemo
//
//  Created by bytedance on 2018/7/24.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BDABTestExperimentItemModel : NSObject

@property (nonatomic, strong, readonly) id val;
@property (nonatomic, strong, readonly) NSNumber *vid;

- (instancetype)initWithVal:(id)val vid:(NSNumber *)vid;

@end
