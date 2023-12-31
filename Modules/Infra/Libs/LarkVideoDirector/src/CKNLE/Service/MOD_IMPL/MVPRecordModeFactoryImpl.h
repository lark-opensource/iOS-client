//
//  MVPRecordModeFactoryImpl.h
//  MVP
//
//  Created by liyingpeng on 2020/12/30.
//

#import <UIKit/UIKit.h>
#import <CameraClient/ACCRecordModeFactory.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

@interface MVPRecordModeFactoryImpl : NSObject <ACCRecordModeFactory>

@property (nonatomic, weak) AWEVideoPublishViewModel *repository;

@end

NS_ASSUME_NONNULL_END
