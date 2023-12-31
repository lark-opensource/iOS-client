//
//  NLECurveTransUtil.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/3/4.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/VECurveTransUtils.h>
#import <TTVideoEditor/IESMMCurveSource.h>
#import "NLESequenceNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLECurveTransUtil : NSObject

+ (IESMMCurveSource *)generateCurveSpeedSource:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

+ (NSArray<NSNumber *> *)transferVideoPointXtoPlayerPoint:(std::vector<std::shared_ptr<cut::model::NLEPoint>> &)curvePoints;

+ (NSArray<NSNumber *> *)xCoordinateOfPoints:(std::vector<std::shared_ptr<cut::model::NLEPoint>> &)points;

+ (NSArray<NSNumber *> *)yCoordinateOfPoints:(std::vector<std::shared_ptr<cut::model::NLEPoint>> &)points;

+ (CGFloat)culculateAverageCurveSpeedRatioWithPointX:(NSArray<NSNumber *> *)pointX
                                              PointY:(NSArray<NSNumber *> *)pointY;

@end

NS_ASSUME_NONNULL_END
