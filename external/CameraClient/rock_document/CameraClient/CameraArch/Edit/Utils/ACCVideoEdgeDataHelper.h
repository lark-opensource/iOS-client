//
//  ACCVideoEdgeDataHelper.h
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2020/12/7.
//

#import <Foundation/Foundation.h>

@class IESVideoAddEdgeData, IESMMTranscoderParam, AWEVideoPublishViewModel;

@interface ACCVideoEdgeDataHelper : NSObject

+ (IESVideoAddEdgeData *)buildAddEdgeDataWithTranscoderParam:(IESMMTranscoderParam *)transParam publishModel:(AWEVideoPublishViewModel *)publishModel;

+ (NSValue *)sizeValueOfViewWithPublishModel:(AWEVideoPublishViewModel *)publishModel;

@end
