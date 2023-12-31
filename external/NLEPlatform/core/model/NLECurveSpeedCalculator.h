/**
 *
 * 此代码的核心计算逻辑来自VESDK，出处：
 * https://code.byted.org/ugc-android/ttvideoeditor/blob/develop/ttvenative/src/utils/base/TECurveSpeedUtils.h
 * https://code.byted.org/ugc-android/ttvideoeditor/blob/develop/ttvenative/src/utils/base/TECurveSpeedUtils.cpp
 *
 * 做了一些调整不会改变核心计算逻辑；
 *
 */

#pragma once

#include "NLEError.h"
#include "NLEStyle.h"
#include "NLENode.h"

#include <cmath>
#include <cstdlib>
#include <string>
#include <algorithm>
#include <sstream>
#include <vector>
#include <iterator>

namespace nle::utils {

    /**
     * 有两个概念需要明确：
     * 1. Segment Point / Trim Point : 素材时间坐标系中的锚点；
     *      比如一段视频时长10秒，PointA(0.5, 2.0) 表示播放视频的第5秒的位置时是2倍速播放；
     * 2. Sequence Point : 播放时间坐标系中的锚点；
     *      比如一段视频时长10秒，假设曲线变速导致实际播放时长变为4秒，PointA(0.5, 2.0) 表示播放到第2秒的时候是2倍速播放；
     *
     * 代码中参数缩写非常接近，请注意分辨！
     * SegmentPoint : S e g Point : SEGPoint
     * SequencePoint : S e q Point : SEQPoint
     */
    class NLE_EXPORT_CLASS NLECurveSpeedCalculator {
    public:

        /**
         * segment point -> sequence point
         */
        static std::vector<std::shared_ptr<cut::model::NLEPoint>> segmentPToSequenceP(
                std::vector<std::shared_ptr<cut::model::NLEPoint>>& seg_points);

        /**
         * construct NLECurveSpeedCalculator by sequence point vector
         */
        NLECurveSpeedCalculator(std::vector<std::shared_ptr<cut::model::NLEPoint>>& seq_points);

        /**
         * 平均速度
         */
        double getAveCurveSpeedRatio() const;

        /**
         * @param seq_duration_us 设置变速后该段素材播放时长
         */
        double getSpeedRatioBySeqDelta(cut::model::NLETime sequence_delta_us, cut::model::NLETime seq_duration_us);

        /**
         * @param seq_duration_us 设置变速后该段素材播放时长
         */
        cut::model::NLETime sequenceDelToSegmentDel(cut::model::NLETime sequence_delta_us, cut::model::NLETime seq_duration_us);

        /**
         * @param seq_duration_us 设置变速后该段素材播放时长
         */
        cut::model::NLETime segmentDelToSequenceDel(cut::model::NLETime segment_delta_us, cut::model::NLETime seq_duration_u);

        /// 生成3阶贝塞尔曲线的起始点、控制点（两个）、终点
        /// @param points 两个归一化坐标点
        static std::vector<std::shared_ptr<cut::model::NLEPoint>> generateThirdBezierPathPoints(
                std::vector<std::shared_ptr<cut::model::NLEPoint>>& points);

        /// 生成所有的贝塞尔曲线点
        /// @param points 四个贝塞尔曲线点
        static std::vector<std::shared_ptr<cut::model::NLEPoint>> generateBezierPathLookupTable(const std::vector<std::shared_ptr<cut::model::NLEPoint>>& points);

        /// 计算当前progress下的拟合贝塞尔曲线点
        /// @param points 3阶贝塞尔曲线的起始点、控制点（两个）、终点
        /// @param progress [0, 1]
        static std::vector<std::shared_ptr<cut::model::NLEPoint>> recursiveCalculateCubePoint(
                const std::vector<std::shared_ptr<cut::model::NLEPoint>>& points, float progress);


        /// 根据两个点坐标，以及这
        /// @param left std::shared_ptr<cut::model::NLEPoint>
        /// @param right std::shared_ptr<cut::model::NLEPoint>
        /// @param duration 整个贝塞尔曲线对应的x轴时长
        /// @param offset 当前要计算的点所在的x轴偏移位置
        static std::shared_ptr<cut::model::NLEPoint> getBezierPoint(
                std::shared_ptr<cut::model::NLEPoint> left,
                std::shared_ptr<cut::model::NLEPoint> right,
                cut::model::NLETime duration,
                cut::model::NLETime offset);

        /// 计算当前时间t下的拟合贝塞尔曲线点，这个是通过公式直接计算所得
        /// @param t [0, 1]
        /// @param start 起始点
        /// @param control1 控制点1
        /// @param control2 控制点2
        /// @param end 终点
        static std::shared_ptr<cut::model::NLEPoint> calculateCubePoint(
                float t,
                std::shared_ptr<cut::model::NLEPoint> start,
                std::shared_ptr<cut::model::NLEPoint> control1,
                std::shared_ptr<cut::model::NLEPoint> control2,
                std::shared_ptr<cut::model::NLEPoint> end);

        static std::pair<std::vector<std::shared_ptr<cut::model::NLEPoint>>, std::vector<std::shared_ptr<cut::model::NLEPoint>>>
               splitCurvePoints(
                std::vector<std::shared_ptr<cut::model::NLEPoint>> &points,
                cut::model::NLETime splitTime,
                cut::model::NLETime duration);

    private:

        double calculateAveCurveSpeedRatio();

        int m_iAnchorNum;
        double m_aveSpeed = 1.0f;

        const double e = 0.8f;
        const double q = 0.2951f;

        std::vector<float> m_vPointX;
        std::vector<float> m_vPointY;

    };
}
