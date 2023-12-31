//
//  CameraRecordConfig.h
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/1/19.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCBusinessConfiguration.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>

NS_ASSUME_NONNULL_BEGIN

@interface CameraRecordConfig : NSObject <ACCBusinessConfiguration>

- (instancetype)initWithInputData:(ACCRecordViewControllerInputData *)inputData;

@end

NS_ASSUME_NONNULL_END
