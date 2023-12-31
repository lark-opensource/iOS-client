//
//  ACCFilterState.h
//  CameraClient
//
//  Created by 郝一鹏 on 2020/1/13.
//

#import <CameraClient/ACCState.h>
#import "ACCFilterDefine.h"
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCFilterState : MTLModel

@property (nonatomic, strong) ACCFilterModel *filterModel;

@end

NS_ASSUME_NONNULL_END
