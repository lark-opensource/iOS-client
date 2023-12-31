//
//  common_typedefs.h
//  smash_algo-private_utils
//
//  Created by liqing on 2020/9/10.
//

#ifndef common_typedefs_h
#define common_typedefs_h

#include <mobilecv2/core/core.hpp>
#include <string>
#include <vector>
#include "internal_smash.h"

SMASH_NAMESPACE_OPEN
NAMESPACE_OPEN(private_utils)

#define Point2D(T) mobilecv2::Point_<T>
#define Point2DArray(T) std::vector<Point2D(T)>
#define Segment2D(T) std::pair<Point2D(T), Point2D(T)>

//// type define
typedef std::vector<int> IArray;
typedef std::vector<float> FArray;
typedef std::vector<double> DArray;

typedef Point2D(int) IPoint;
typedef Point2D(float) FPoint;
typedef Point2D(double) DPoint;

typedef Point2DArray(int) IPointArray;
typedef Point2DArray(float) FPointArray;
typedef Point2DArray(double) DPointArray;

typedef Segment2D(int) ISegment;
typedef Segment2D(float) FSegment;
typedef Segment2D(double) DSegment;

typedef mobilecv2::Size ISize;
typedef mobilecv2::Size_<float> FSize;
typedef mobilecv2::Size_<double> DSize;

typedef mobilecv2::Scalar Scalar;

typedef mobilecv2::Rect IRect;
typedef mobilecv2::Rect_<float> FRect;
typedef mobilecv2::Rect_<double> DRect;
typedef mobilecv2::RotatedRect RotatedRect;

typedef std::vector<IRect> IRectArray;
typedef std::vector<FRect> FRectArray;
typedef std::vector<DRect> DRectArray;
typedef std::vector<RotatedRect> RotatedRectArray;

typedef mobilecv2::Mat Mat;
typedef const mobilecv2::Mat& IMat;
typedef mobilecv2::Mat& OMat;
typedef mobilecv2::Mat& IOMat;
typedef std::vector<Mat> MatArray;

typedef mobilecv2::InputArray InputArray;
typedef mobilecv2::OutputArray OutputArray;
typedef mobilecv2::InputOutputArray InputOutputArray;

typedef uchar* LUT1D;
typedef uchar (*LUT2D)[256];
typedef mobilecv2::Mat_<uchar> LUT1DMat;
typedef mobilecv2::Mat_<uchar> LUT2DMat;

typedef std::string String;
typedef std::vector<std::string> StringArray;

typedef mobilecv2::Range IRange;

NAMESPACE_CLOSE(private_utils)
SMASH_NAMESPACE_CLOSE

#endif /* common_typedefs_h */
