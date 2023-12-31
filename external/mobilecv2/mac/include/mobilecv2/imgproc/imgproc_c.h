/*M///////////////////////////////////////////////////////////////////////////////////////
//
//  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
//
//  By downloading, copying, installing or using the software you agree to this license.
//  If you do not agree to this license, do not download, install,
//  copy or use the software.
//
//
//                           License Agreement
//                For Open Source Computer Vision Library
//
// Copyright (C) 2000-2008, Intel Corporation, all rights reserved.
// Copyright (C) 2009, Willow Garage Inc., all rights reserved.
// Third party copyrights are property of their respective owners.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
//   * Redistribution's of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//   * Redistribution's in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//   * The name of the copyright holders may not be used to endorse or promote products
//     derived from this software without specific prior written permission.
//
// This software is provided by the copyright holders and contributors "as is" and
// any express or implied warranties, including, but not limited to, the implied
// warranties of merchantability and fitness for a particular purpose are disclaimed.
// In no event shall the Intel Corporation or contributors be liable for any direct,
// indirect, incidental, special, exemplary, or consequential damages
// (including, but not limited to, procurement of substitute goods or services;
// loss of use, data, or profits; or business interruption) however caused
// and on any theory of liability, whether in contract, strict liability,
// or tort (including negligence or otherwise) arising in any way out of
// the use of this software, even if advised of the possibility of such damage.
//
//M*/

#ifndef MOBILECV2_IMGPROC_IMGPROC_C_H
#define MOBILECV2_IMGPROC_IMGPROC_C_H

#include "mobilecv2/imgproc/types_c.h"

// #ifdef __cplusplus
// extern "C" {
// #endif

namespace mobilecv2 {

/** @addtogroup imgproc_c
@{
*/

/*********************** Background statistics accumulation *****************************/

/** @brief Adds image to accumulator
@see mobilecv2::accumulate
*/
CVAPI(void)  cvAcc( const CvArr* image, CvArr* sum,
                   const CvArr* mask CV_DEFAULT(NULL) );

/** @brief Adds squared image to accumulator
@see mobilecv2::accumulateSquare
*/
CVAPI(void)  cvSquareAcc( const CvArr* image, CvArr* sqsum,
                         const CvArr* mask CV_DEFAULT(NULL) );

/** @brief Adds a product of two images to accumulator
@see mobilecv2::accumulateProduct
*/
CVAPI(void)  cvMultiplyAcc( const CvArr* image1, const CvArr* image2, CvArr* acc,
                           const CvArr* mask CV_DEFAULT(NULL) );

/** @brief Adds image to accumulator with weights: acc = acc*(1-alpha) + image*alpha
@see mobilecv2::accumulateWeighted
*/
CVAPI(void)  cvRunningAvg( const CvArr* image, CvArr* acc, double alpha,
                          const CvArr* mask CV_DEFAULT(NULL) );

/****************************************************************************************\
*                                    Image Processing                                    *
\****************************************************************************************/

/** Copies source 2D array inside of the larger destination array and
   makes a border of the specified type (IPL_BORDER_*) around the copied area. */
CVAPI(void) cvCopyMakeBorder( const CvArr* src, CvArr* dst, CvPoint offset,
                              int bordertype, CvScalar value CV_DEFAULT(cvScalarAll(0)));

/** @brief Smooths the image in one of several ways.

@param src The source image
@param dst The destination image
@param smoothtype Type of the smoothing, see SmoothMethod_c
@param size1 The first parameter of the smoothing operation, the aperture width. Must be a
positive odd number (1, 3, 5, ...)
@param size2 The second parameter of the smoothing operation, the aperture height. Ignored by
CV_MEDIAN and CV_BILATERAL methods. In the case of simple scaled/non-scaled and Gaussian blur if
size2 is zero, it is set to size1. Otherwise it must be a positive odd number.
@param sigma1 In the case of a Gaussian parameter this parameter may specify Gaussian \f$\sigma\f$
(standard deviation). If it is zero, it is calculated from the kernel size:
\f[\sigma  = 0.3 (n/2 - 1) + 0.8  \quad   \text{where}   \quad  n= \begin{array}{l l} \mbox{\texttt{size1} for horizontal kernel} \\ \mbox{\texttt{size2} for vertical kernel} \end{array}\f]
Using standard sigma for small kernels ( \f$3\times 3\f$ to \f$7\times 7\f$ ) gives better speed. If
sigma1 is not zero, while size1 and size2 are zeros, the kernel size is calculated from the
sigma (to provide accurate enough operation).
@param sigma2 additional parameter for bilateral filtering

@see mobilecv2::GaussianBlur, mobilecv2::blur, mobilecv2::medianBlur, mobilecv2::bilateralFilter.
 */
// CVAPI(void) cvSmooth( const CvArr* src, CvArr* dst,
//                       int smoothtype CV_DEFAULT(CV_GAUSSIAN),
//                       int size1 CV_DEFAULT(3),
//                       int size2 CV_DEFAULT(0),
//                       double sigma1 CV_DEFAULT(0),
//                       double sigma2 CV_DEFAULT(0));

/** @brief Convolves an image with the kernel.

@param src input image.
@param dst output image of the same size and the same number of channels as src.
@param kernel convolution kernel (or rather a correlation kernel), a single-channel floating point
matrix; if you want to apply different kernels to different channels, split the image into
separate color planes using split and process them individually.
@param anchor anchor of the kernel that indicates the relative position of a filtered point within
the kernel; the anchor should lie within the kernel; default value (-1,-1) means that the anchor
is at the kernel center.

@see mobilecv2::filter2D
 */
// CVAPI(void) cvFilter2D( const CvArr* src, CvArr* dst, const CvMat* kernel,
//                         CvPoint anchor CV_DEFAULT(cvPoint(-1,-1)));

/** @brief Finds integral image: SUM(X,Y) = sum(x<X,y<Y)I(x,y)
@see mobilecv2::integral
*/
CVAPI(void) cvIntegral( const CvArr* image, CvArr* sum,
                       CvArr* sqsum CV_DEFAULT(NULL),
                       CvArr* tilted_sum CV_DEFAULT(NULL));

/** @brief Smoothes the input image with gaussian kernel and then down-samples it.

   dst_width = floor(src_width/2)[+1],
   dst_height = floor(src_height/2)[+1]
   @see mobilecv2::pyrDown
*/
CVAPI(void)  cvPyrDown( const CvArr* src, CvArr* dst,
                        int filter CV_DEFAULT(CV_GAUSSIAN_5x5) );

/** @brief Up-samples image and smoothes the result with gaussian kernel.

   dst_width = src_width*2,
   dst_height = src_height*2
   @see mobilecv2::pyrUp
*/
CVAPI(void)  cvPyrUp( const CvArr* src, CvArr* dst,
                      int filter CV_DEFAULT(CV_GAUSSIAN_5x5) );

/** @brief Builds pyramid for an image
@see buildPyramid
*/
CVAPI(CvMat**) cvCreatePyramid( const CvArr* img, int extra_layers, double rate,
                                const CvSize* layer_sizes CV_DEFAULT(0),
                                CvArr* bufarr CV_DEFAULT(0),
                                int calc CV_DEFAULT(1),
                                int filter CV_DEFAULT(CV_GAUSSIAN_5x5) );

/** @brief Releases pyramid */
CVAPI(void)  cvReleasePyramid( CvMat*** pyramid, int extra_layers );

/** @brief Calculates an image derivative using generalized Sobel

   (aperture_size = 1,3,5,7) or Scharr (aperture_size = -1) operator.
   Scharr can be used only for the first dx or dy derivative
@see mobilecv2::Sobel
*/
CVAPI(void) cvSobel( const CvArr* src, CvArr* dst,
                    int xorder, int yorder,
                    int aperture_size CV_DEFAULT(3));

/** @brief Calculates the image Laplacian: (d2/dx + d2/dy)I
@see mobilecv2::Laplacian
*/
CVAPI(void) cvLaplace( const CvArr* src, CvArr* dst,
                      int aperture_size CV_DEFAULT(3) );

/** @brief Converts input array pixels from one color space to another
@see mobilecv2::cvtColor
*/
CVAPI(void)  cvCvtColor( const CvArr* src, CvArr* dst, int code );


/** @brief Resizes image (input array is resized to fit the destination array)
@see mobilecv2::resize
*/
CVAPI(void)  cvResize( const CvArr* src, CvArr* dst,
                       int interpolation CV_DEFAULT( CV_INTER_LINEAR ));

/** @brief Warps image with affine transform
@note ::cvGetQuadrangleSubPix is similar to ::cvWarpAffine, but the outliers are extrapolated using
replication border mode.
@see mobilecv2::warpAffine
*/
// CVAPI(void)  cvWarpAffine( const CvArr* src, CvArr* dst, const CvMat* map_matrix,
//                            int flags CV_DEFAULT(CV_INTER_LINEAR+CV_WARP_FILL_OUTLIERS),
//                            CvScalar fillval CV_DEFAULT(cvScalarAll(0)) );

/** @brief Computes affine transform matrix for mapping src[i] to dst[i] (i=0,1,2)
@see mobilecv2::getAffineTransform
*/
// CVAPI(CvMat*) cvGetAffineTransform( const CvPoint2D32f * src,
//                                     const CvPoint2D32f * dst,
//                                     CvMat * map_matrix );

/** @brief Computes rotation_matrix matrix
@see mobilecv2::getRotationMatrix2D
*/
// CVAPI(CvMat*)  cv2DRotationMatrix( CvPoint2D32f center, double angle,
//                                    double scale, CvMat* map_matrix );

/** @brief Warps image with perspective (projective) transform
@see mobilecv2::warpPerspective
*/
// CVAPI(void)  cvWarpPerspective( const CvArr* src, CvArr* dst, const CvMat* map_matrix,
//                                 int flags CV_DEFAULT(CV_INTER_LINEAR+CV_WARP_FILL_OUTLIERS),
//                                 CvScalar fillval CV_DEFAULT(cvScalarAll(0)) );

/** @brief Computes perspective transform matrix for mapping src[i] to dst[i] (i=0,1,2,3)
@see mobilecv2::getPerspectiveTransform
*/
// CVAPI(CvMat*) cvGetPerspectiveTransform( const CvPoint2D32f* src,
//                                          const CvPoint2D32f* dst,
//                                          CvMat* map_matrix );

/** @brief Performs generic geometric transformation using the specified coordinate maps
@see mobilecv2::remap
*/
CVAPI(void)  cvRemap( const CvArr* src, CvArr* dst,
                      const CvArr* mapx, const CvArr* mapy,
                      int flags CV_DEFAULT(CV_INTER_LINEAR+CV_WARP_FILL_OUTLIERS),
                      CvScalar fillval CV_DEFAULT(cvScalarAll(0)) );

/** @brief Converts mapx & mapy from floating-point to integer formats for cvRemap
@see mobilecv2::convertMaps
*/
// CVAPI(void)  cvConvertMaps( const CvArr* mapx, const CvArr* mapy,
//                             CvArr* mapxy, CvArr* mapalpha );

/** @brief Performs forward or inverse log-polar image transform
@see mobilecv2::logPolar
*/
// CVAPI(void)  cvLogPolar( const CvArr* src, CvArr* dst,
//                          CvPoint2D32f center, double M,
//                          int flags CV_DEFAULT(CV_INTER_LINEAR+CV_WARP_FILL_OUTLIERS));

/** Performs forward or inverse linear-polar image transform
@see mobilecv2::linearPolar
*/
// CVAPI(void)  cvLinearPolar( const CvArr* src, CvArr* dst,
//                          CvPoint2D32f center, double maxRadius,
//                          int flags CV_DEFAULT(CV_INTER_LINEAR+CV_WARP_FILL_OUTLIERS));

/** @brief Transforms the input image to compensate lens distortion
@see mobilecv2::undistort
*/
CVAPI(void) cvUndistort2( const CvArr* src, CvArr* dst,
                          const CvMat* camera_matrix,
                          const CvMat* distortion_coeffs,
                          const CvMat* new_camera_matrix CV_DEFAULT(0) );

/** @brief Computes transformation map from intrinsic camera parameters
   that can used by cvRemap
*/
CVAPI(void) cvInitUndistortMap( const CvMat* camera_matrix,
                                const CvMat* distortion_coeffs,
                                CvArr* mapx, CvArr* mapy );

/** @brief Computes undistortion+rectification map for a head of stereo camera
@see mobilecv2::initUndistortRectifyMap
*/
CVAPI(void) cvInitUndistortRectifyMap( const CvMat* camera_matrix,
                                       const CvMat* dist_coeffs,
                                       const CvMat *R, const CvMat* new_camera_matrix,
                                       CvArr* mapx, CvArr* mapy );

/** @brief Computes the original (undistorted) feature coordinates
   from the observed (distorted) coordinates
@see mobilecv2::undistortPoints
*/
CVAPI(void) cvUndistortPoints( const CvMat* src, CvMat* dst,
                               const CvMat* camera_matrix,
                               const CvMat* dist_coeffs,
                               const CvMat* R CV_DEFAULT(0),
                               const CvMat* P CV_DEFAULT(0));

/** @brief Returns a structuring element of the specified size and shape for morphological operations.

@note the created structuring element IplConvKernel\* element must be released in the end using
`cvReleaseStructuringElement(&element)`.

@param cols Width of the structuring element
@param rows Height of the structuring element
@param anchor_x x-coordinate of the anchor
@param anchor_y y-coordinate of the anchor
@param shape element shape that could be one of the mobilecv2::MorphShapes_c
@param values integer array of cols*rows elements that specifies the custom shape of the
structuring element, when shape=CV_SHAPE_CUSTOM.

@see mobilecv2::getStructuringElement
 */
 CVAPI(IplConvKernel*)  cvCreateStructuringElementEx(
            int cols, int  rows, int  anchor_x, int  anchor_y,
            int shape, int* values CV_DEFAULT(NULL) );

/** @brief releases structuring element
@see cvCreateStructuringElementEx
*/
CVAPI(void)  cvReleaseStructuringElement( IplConvKernel** element );

/** @brief erodes input image (applies minimum filter) one or more times.
   If element pointer is NULL, 3x3 rectangular element is used
@see mobilecv2::erode
*/
CVAPI(void)  cvErode( const CvArr* src, CvArr* dst,
                      IplConvKernel* element CV_DEFAULT(NULL),
                      int iterations CV_DEFAULT(1) );

/** @brief dilates input image (applies maximum filter) one or more times.

   If element pointer is NULL, 3x3 rectangular element is used
@see mobilecv2::dilate
*/
CVAPI(void)  cvDilate( const CvArr* src, CvArr* dst,
                       IplConvKernel* element CV_DEFAULT(NULL),
                       int iterations CV_DEFAULT(1) );

/** @brief Performs complex morphological transformation
@see mobilecv2::morphologyEx
*/
CVAPI(void)  cvMorphologyEx( const CvArr* src, CvArr* dst,
                             CvArr* temp, IplConvKernel* element,
                             int operation, int iterations CV_DEFAULT(1) );

/** @brief Calculates all spatial and central moments up to the 3rd order
@see mobilecv2::moments
*/
CVAPI(void) cvMoments( const CvArr* arr, CvMoments* moments, int binary CV_DEFAULT(0));

/** @brief Retrieve spatial moments */
CVAPI(double)  cvGetSpatialMoment( CvMoments* moments, int x_order, int y_order );
/** @brief Retrieve central moments */
CVAPI(double)  cvGetCentralMoment( CvMoments* moments, int x_order, int y_order );
/** @brief Retrieve normalized central moments */
CVAPI(double)  cvGetNormalizedCentralMoment( CvMoments* moments,
                                             int x_order, int y_order );

/** @brief Calculates 7 Hu's invariants from precalculated spatial and central moments
@see mobilecv2::HuMoments
*/
CVAPI(void) cvGetHuMoments( CvMoments*  moments, CvHuMoments*  hu_moments );

/*********************************** data sampling **************************************/

/** @brief Fetches pixels that belong to the specified line segment and stores them to the buffer.

   Returns the number of retrieved points.
@see mobilecv2::LineSegmentDetector
*/
CVAPI(int)  cvSampleLine( const CvArr* image, CvPoint pt1, CvPoint pt2, void* buffer,
                          int connectivity CV_DEFAULT(8));

/** @brief Retrieves the rectangular image region with specified center from the input array.

 dst(x,y) <- src(x + center.x - dst_width/2, y + center.y - dst_height/2).
 Values of pixels with fractional coordinates are retrieved using bilinear interpolation
@see mobilecv2::getRectSubPix
*/
CVAPI(void)  cvGetRectSubPix( const CvArr* src, CvArr* dst, CvPoint2D32f center );


/** @brief Retrieves quadrangle from the input array.

    matrixarr = ( a11  a12 | b1 )   dst(x,y) <- src(A[x y]' + b)
                ( a21  a22 | b2 )   (bilinear interpolation is used to retrieve pixels
                                     with fractional coordinates)
@see cvWarpAffine
*/
CVAPI(void)  cvGetQuadrangleSubPix( const CvArr* src, CvArr* dst,
                                    const CvMat* map_matrix );

/** @brief Measures similarity between template and overlapped windows in the source image
   and fills the resultant image with the measurements
@see mobilecv2::matchTemplate
*/
CVAPI(void)  cvMatchTemplate( const CvArr* image, const CvArr* templ,
                              CvArr* result, int method );

/****************************************************************************************\
*                              Contours retrieving                                       *
\****************************************************************************************/

/** @brief Retrieves outer and optionally inner boundaries of white (non-zero) connected
   components in the black (zero) background
@see mobilecv2::findContours, cvStartFindContours, cvFindNextContour, cvSubstituteContour, cvEndFindContours
*/
CVAPI(int)  cvFindContours( CvArr* image, CvMemStorage* storage, CvSeq** first_contour,
                            int header_size CV_DEFAULT(sizeof(CvContour)),
                            int mode CV_DEFAULT(CV_RETR_LIST),
                            int method CV_DEFAULT(CV_CHAIN_APPROX_SIMPLE),
                            CvPoint offset CV_DEFAULT(cvPoint(0,0)));

/** @brief Initializes contour retrieving process.

   Calls cvStartFindContours.
   Calls cvFindNextContour until null pointer is returned
   or some other condition becomes true.
   Calls cvEndFindContours at the end.
@see cvFindContours
*/
CVAPI(CvContourScanner)  cvStartFindContours( CvArr* image, CvMemStorage* storage,
                            int header_size CV_DEFAULT(sizeof(CvContour)),
                            int mode CV_DEFAULT(CV_RETR_LIST),
                            int method CV_DEFAULT(CV_CHAIN_APPROX_SIMPLE),
                            CvPoint offset CV_DEFAULT(cvPoint(0,0)));

/** @brief Retrieves next contour
@see cvFindContours
*/
CVAPI(CvSeq*)  cvFindNextContour( CvContourScanner scanner );


/** @brief Substitutes the last retrieved contour with the new one

   (if the substitutor is null, the last retrieved contour is removed from the tree)
@see cvFindContours
*/
CVAPI(void)   cvSubstituteContour( CvContourScanner scanner, CvSeq* new_contour );


/** @brief Releases contour scanner and returns pointer to the first outer contour
@see cvFindContours
*/
CVAPI(CvSeq*)  cvEndFindContours( CvContourScanner* scanner );

/** @brief Approximates Freeman chain(s) with a polygonal curve.

This is a standalone contour approximation routine, not represented in the new interface. When
cvFindContours retrieves contours as Freeman chains, it calls the function to get approximated
contours, represented as polygons.

@param src_seq Pointer to the approximated Freeman chain that can refer to other chains.
@param storage Storage location for the resulting polylines.
@param method Approximation method (see the description of the function :ocvFindContours ).
@param parameter Method parameter (not used now).
@param minimal_perimeter Approximates only those contours whose perimeters are not less than
minimal_perimeter . Other chains are removed from the resulting structure.
@param recursive Recursion flag. If it is non-zero, the function approximates all chains that can
be obtained from chain by using the h_next or v_next links. Otherwise, the single input chain is
approximated.
@see cvStartReadChainPoints, cvReadChainPoint
 */
CVAPI(CvSeq*) cvApproxChains( CvSeq* src_seq, CvMemStorage* storage,
                            int method CV_DEFAULT(CV_CHAIN_APPROX_SIMPLE),
                            double parameter CV_DEFAULT(0),
                            int  minimal_perimeter CV_DEFAULT(0),
                            int  recursive CV_DEFAULT(0));

/** @brief Initializes Freeman chain reader.

   The reader is used to iteratively get coordinates of all the chain points.
   If the Freeman codes should be read as is, a simple sequence reader should be used
@see cvApproxChains
*/
CVAPI(void) cvStartReadChainPoints( CvChain* chain, CvChainPtReader* reader );

/** @brief Retrieves the next chain point
@see cvApproxChains
*/
CVAPI(CvPoint) cvReadChainPoint( CvChainPtReader* reader );


/****************************************************************************************\
*                            Contour Processing and Shape Analysis                       *
\****************************************************************************************/

/** @brief Approximates a single polygonal curve (contour) or
   a tree of polygonal curves (contours)
@see mobilecv2::approxPolyDP
*/
CVAPI(CvSeq*)  cvApproxPoly( const void* src_seq,
                             int header_size, CvMemStorage* storage,
                             int method, double eps,
                             int recursive CV_DEFAULT(0));

/** @brief Calculates perimeter of a contour or length of a part of contour
@see mobilecv2::arcLength
*/
CVAPI(double)  cvArcLength( const void* curve,
                            CvSlice slice CV_DEFAULT(CV_WHOLE_SEQ),
                            int is_closed CV_DEFAULT(-1));

/** same as cvArcLength for closed contour
*/
CV_INLINE double cvContourPerimeter( const void* contour )
{
    return cvArcLength( contour, CV_WHOLE_SEQ, 1 );
}


/** @brief Calculates contour bounding rectangle (update=1) or
   just retrieves pre-calculated rectangle (update=0)
@see mobilecv2::boundingRect
*/
CVAPI(CvRect)  cvBoundingRect( CvArr* points, int update CV_DEFAULT(0) );

/** @brief Calculates area of a contour or contour segment
@see mobilecv2::contourArea
*/
CVAPI(double)  cvContourArea( const CvArr* contour,
                              CvSlice slice CV_DEFAULT(CV_WHOLE_SEQ),
                              int oriented CV_DEFAULT(0));

/** @brief Finds minimum area rotated rectangle bounding a set of points
@see mobilecv2::minAreaRect
*/
CVAPI(CvBox2D)  cvMinAreaRect2( const CvArr* points,
                                CvMemStorage* storage CV_DEFAULT(NULL));

/** @brief Finds minimum enclosing circle for a set of points
@see mobilecv2::minEnclosingCircle
*/
CVAPI(int)  cvMinEnclosingCircle( const CvArr* points,
                                  CvPoint2D32f* center, float* radius );

/** @brief Compares two contours by matching their moments
@see mobilecv2::matchShapes
*/
CVAPI(double)  cvMatchShapes( const void* object1, const void* object2,
                              int method, double parameter CV_DEFAULT(0));

/** @brief Calculates exact convex hull of 2d point set
@see mobilecv2::convexHull
*/
CVAPI(CvSeq*) cvConvexHull2( const CvArr* input,
                             void* hull_storage CV_DEFAULT(NULL),
                             int orientation CV_DEFAULT(CV_CLOCKWISE),
                             int return_points CV_DEFAULT(0));

/** @brief Checks whether the contour is convex or not (returns 1 if convex, 0 if not)
@see mobilecv2::isContourConvex
*/
CVAPI(int)  cvCheckContourConvexity( const CvArr* contour );


/** @brief Finds convexity defects for the contour
@see mobilecv2::convexityDefects
*/
CVAPI(CvSeq*)  cvConvexityDefects( const CvArr* contour, const CvArr* convexhull,
                                   CvMemStorage* storage CV_DEFAULT(NULL));

/** @brief Fits ellipse into a set of 2d points
@see mobilecv2::fitEllipse
*/
CVAPI(CvBox2D) cvFitEllipse2( const CvArr* points );

/** @brief Finds minimum rectangle containing two given rectangles */
CVAPI(CvRect)  cvMaxRect( const CvRect* rect1, const CvRect* rect2 );

/** @brief Finds coordinates of the box vertices */
CVAPI(void) cvBoxPoints( CvBox2D box, CvPoint2D32f pt[4] );

/** @brief Initializes sequence header for a matrix (column or row vector) of points

   a wrapper for cvMakeSeqHeaderForArray (it does not initialize bounding rectangle!!!) */
CVAPI(CvSeq*) cvPointSeqFromMat( int seq_kind, const CvArr* mat,
                                 CvContour* contour_header,
                                 CvSeqBlock* block );

/** @brief Checks whether the point is inside polygon, outside, on an edge (at a vertex).

   Returns positive, negative or zero value, correspondingly.
   Optionally, measures a signed distance between
   the point and the nearest polygon edge (measure_dist=1)
@see mobilecv2::pointPolygonTest
*/
CVAPI(double) cvPointPolygonTest( const CvArr* contour,
                                  CvPoint2D32f pt, int measure_dist );

/****************************************************************************************\
*                                  Histogram functions                                   *
\****************************************************************************************/

/** @brief Creates a histogram.

The function creates a histogram of the specified size and returns a pointer to the created
histogram. If the array ranges is 0, the histogram bin ranges must be specified later via the
function cvSetHistBinRanges. Though cvCalcHist and cvCalcBackProject may process 8-bit images
without setting bin ranges, they assume they are equally spaced in 0 to 255 bins.

@param dims Number of histogram dimensions.
@param sizes Array of the histogram dimension sizes.
@param type Histogram representation format. CV_HIST_ARRAY means that the histogram data is
represented as a multi-dimensional dense array CvMatND. CV_HIST_SPARSE means that histogram data
is represented as a multi-dimensional sparse array CvSparseMat.
@param ranges Array of ranges for the histogram bins. Its meaning depends on the uniform parameter
value. The ranges are used when the histogram is calculated or backprojected to determine which
histogram bin corresponds to which value/tuple of values from the input image(s).
@param uniform Uniformity flag. If not zero, the histogram has evenly spaced bins and for every
\f$0<=i<cDims\f$ ranges[i] is an array of two numbers: lower and upper boundaries for the i-th
histogram dimension. The whole range [lower,upper] is then split into dims[i] equal parts to
determine the i-th input tuple value ranges for every histogram bin. And if uniform=0 , then the
i-th element of the ranges array contains dims[i]+1 elements: \f$\texttt{lower}_0,
\texttt{upper}_0, \texttt{lower}_1, \texttt{upper}_1 = \texttt{lower}_2,
...
\texttt{upper}_{dims[i]-1}\f$ where \f$\texttt{lower}_j\f$ and \f$\texttt{upper}_j\f$ are lower
and upper boundaries of the i-th input tuple value for the j-th bin, respectively. In either
case, the input values that are beyond the specified range for a histogram bin are not counted
by cvCalcHist and filled with 0 by cvCalcBackProject.
 */
CVAPI(CvHistogram*)  cvCreateHist( int dims, int* sizes, int type,
                                   float** ranges CV_DEFAULT(NULL),
                                   int uniform CV_DEFAULT(1));

/** @brief Sets the bounds of the histogram bins.

This is a standalone function for setting bin ranges in the histogram. For a more detailed
description of the parameters ranges and uniform, see the :ocvCalcHist function that can initialize
the ranges as well. Ranges for the histogram bins must be set before the histogram is calculated or
the backproject of the histogram is calculated.

@param hist Histogram.
@param ranges Array of bin ranges arrays. See :ocvCreateHist for details.
@param uniform Uniformity flag. See :ocvCreateHist for details.
 */
CVAPI(void)  cvSetHistBinRanges( CvHistogram* hist, float** ranges,
                                int uniform CV_DEFAULT(1));

/** @brief Makes a histogram out of an array.

The function initializes the histogram, whose header and bins are allocated by the user.
cvReleaseHist does not need to be called afterwards. Only dense histograms can be initialized this
way. The function returns hist.

@param dims Number of the histogram dimensions.
@param sizes Array of the histogram dimension sizes.
@param hist Histogram header initialized by the function.
@param data Array used to store histogram bins.
@param ranges Histogram bin ranges. See cvCreateHist for details.
@param uniform Uniformity flag. See cvCreateHist for details.
 */
CVAPI(CvHistogram*)  cvMakeHistHeaderForArray(
                            int  dims, int* sizes, CvHistogram* hist,
                            float* data, float** ranges CV_DEFAULT(NULL),
                            int uniform CV_DEFAULT(1));

/** @brief Releases the histogram.

The function releases the histogram (header and the data). The pointer to the histogram is cleared
by the function. If \*hist pointer is already NULL, the function does nothing.

@param hist Double pointer to the released histogram.
 */
CVAPI(void)  cvReleaseHist( CvHistogram** hist );

/** @brief Clears the histogram.

The function sets all of the histogram bins to 0 in case of a dense histogram and removes all
histogram bins in case of a sparse array.

@param hist Histogram.
 */
CVAPI(void)  cvClearHist( CvHistogram* hist );

/** @brief Finds the minimum and maximum histogram bins.

The function finds the minimum and maximum histogram bins and their positions. All of output
arguments are optional. Among several extremas with the same value the ones with the minimum index
(in the lexicographical order) are returned. In case of several maximums or minimums, the earliest
in the lexicographical order (extrema locations) is returned.

@param hist Histogram.
@param min_value Pointer to the minimum value of the histogram.
@param max_value Pointer to the maximum value of the histogram.
@param min_idx Pointer to the array of coordinates for the minimum.
@param max_idx Pointer to the array of coordinates for the maximum.
 */
CVAPI(void)  cvGetMinMaxHistValue( const CvHistogram* hist,
                                   float* min_value, float* max_value,
                                   int* min_idx CV_DEFAULT(NULL),
                                   int* max_idx CV_DEFAULT(NULL));


/** @brief Normalizes the histogram.

The function normalizes the histogram bins by scaling them so that the sum of the bins becomes equal
to factor.

@param hist Pointer to the histogram.
@param factor Normalization factor.
 */
CVAPI(void)  cvNormalizeHist( CvHistogram* hist, double factor );


/** @brief Thresholds the histogram.

The function clears histogram bins that are below the specified threshold.

@param hist Pointer to the histogram.
@param threshold Threshold level.
 */
CVAPI(void)  cvThreshHist( CvHistogram* hist, double threshold );


/** Compares two histogram */
CVAPI(double)  cvCompareHist( const CvHistogram* hist1,
                              const CvHistogram* hist2,
                              int method);

/** @brief Copies a histogram.

The function makes a copy of the histogram. If the second histogram pointer \*dst is NULL, a new
histogram of the same size as src is created. Otherwise, both histograms must have equal types and
sizes. Then the function copies the bin values of the source histogram to the destination histogram
and sets the same bin value ranges as in src.

@param src Source histogram.
@param dst Pointer to the destination histogram.
 */
CVAPI(void)  cvCopyHist( const CvHistogram* src, CvHistogram** dst );


/** @brief Calculates bayesian probabilistic histograms
   (each or src and dst is an array of _number_ histograms */
CVAPI(void)  cvCalcBayesianProb( CvHistogram** src, int number,
                                CvHistogram** dst);

/** @brief Calculates array histogram
@see mobilecv2::calcHist
*/
CVAPI(void)  cvCalcArrHist( CvArr** arr, CvHistogram* hist,
                            int accumulate CV_DEFAULT(0),
                            const CvArr* mask CV_DEFAULT(NULL) );

/** @overload */
CV_INLINE  void  cvCalcHist( IplImage** image, CvHistogram* hist,
                             int accumulate CV_DEFAULT(0),
                             const CvArr* mask CV_DEFAULT(NULL) )
{
    cvCalcArrHist( (CvArr**)image, hist, accumulate, mask );
}

/** @brief Calculates back project
@see cvCalcBackProject, mobilecv2::calcBackProject
*/
CVAPI(void)  cvCalcArrBackProject( CvArr** image, CvArr* dst,
                                   const CvHistogram* hist );

#define  cvCalcBackProject(image, dst, hist) cvCalcArrBackProject((CvArr**)image, dst, hist)


/** @brief Locates a template within an image by using a histogram comparison.

The function calculates the back projection by comparing histograms of the source image patches with
the given histogram. The function is similar to matchTemplate, but instead of comparing the raster
patch with all its possible positions within the search window, the function CalcBackProjectPatch
compares histograms. See the algorithm diagram below:

![image](pics/backprojectpatch.png)

@param image Source images (though, you may pass CvMat\*\* as well).
@param dst Destination image.
@param range
@param hist Histogram.
@param method Comparison method passed to cvCompareHist (see the function description).
@param factor Normalization factor for histograms that affects the normalization scale of the
destination image. Pass 1 if not sure.

@see cvCalcBackProjectPatch
 */
CVAPI(void)  cvCalcArrBackProjectPatch( CvArr** image, CvArr* dst, CvSize range,
                                        CvHistogram* hist, int method,
                                        double factor );

#define  cvCalcBackProjectPatch( image, dst, range, hist, method, factor ) \
     cvCalcArrBackProjectPatch( (CvArr**)image, dst, range, hist, method, factor )


/** @brief Divides one histogram by another.

The function calculates the object probability density from two histograms as:

\f[\texttt{disthist} (I)= \forkthree{0}{if \(\texttt{hist1}(I)=0\)}{\texttt{scale}}{if \(\texttt{hist1}(I) \ne 0\) and \(\texttt{hist2}(I) > \texttt{hist1}(I)\)}{\frac{\texttt{hist2}(I) \cdot \texttt{scale}}{\texttt{hist1}(I)}}{if \(\texttt{hist1}(I) \ne 0\) and \(\texttt{hist2}(I) \le \texttt{hist1}(I)\)}\f]

@param hist1 First histogram (the divisor).
@param hist2 Second histogram.
@param dst_hist Destination histogram.
@param scale Scale factor for the destination histogram.
 */
CVAPI(void)  cvCalcProbDensity( const CvHistogram* hist1, const CvHistogram* hist2,
                                CvHistogram* dst_hist, double scale CV_DEFAULT(255) );

/** @brief equalizes histogram of 8-bit single-channel image
@see mobilecv2::equalizeHist
*/
CVAPI(void)  cvEqualizeHist( const CvArr* src, CvArr* dst );


/** @brief Applies distance transform to binary image
@see mobilecv2::distanceTransform
*/
CVAPI(void)  cvDistTransform( const CvArr* src, CvArr* dst,
                              int distance_type CV_DEFAULT(CV_DIST_L2),
                              int mask_size CV_DEFAULT(3),
                              const float* mask CV_DEFAULT(NULL),
                              CvArr* labels CV_DEFAULT(NULL),
                              int labelType CV_DEFAULT(CV_DIST_LABEL_CCOMP));


/** @brief Applies fixed-level threshold to grayscale image.

   This is a basic operation applied before retrieving contours
@see mobilecv2::threshold
*/
CVAPI(double)  cvThreshold( const CvArr*  src, CvArr*  dst,
                            double  threshold, double  max_value,
                            int threshold_type );

/** @brief Applies adaptive threshold to grayscale image.

   The two parameters for methods CV_ADAPTIVE_THRESH_MEAN_C and
   CV_ADAPTIVE_THRESH_GAUSSIAN_C are:
   neighborhood size (3, 5, 7 etc.),
   and a constant subtracted from mean (...,-3,-2,-1,0,1,2,3,...)
@see mobilecv2::adaptiveThreshold
*/
CVAPI(void)  cvAdaptiveThreshold( const CvArr* src, CvArr* dst, double max_value,
                                  int adaptive_method CV_DEFAULT(CV_ADAPTIVE_THRESH_MEAN_C),
                                  int threshold_type CV_DEFAULT(CV_THRESH_BINARY),
                                  int block_size CV_DEFAULT(3),
                                  double param1 CV_DEFAULT(5));

/** @brief Fills the connected component until the color difference gets large enough
@see mobilecv2::floodFill
*/
CVAPI(void)  cvFloodFill( CvArr* image, CvPoint seed_point,
                          CvScalar new_val, CvScalar lo_diff CV_DEFAULT(cvScalarAll(0)),
                          CvScalar up_diff CV_DEFAULT(cvScalarAll(0)),
                          CvConnectedComp* comp CV_DEFAULT(NULL),
                          int flags CV_DEFAULT(4),
                          CvArr* mask CV_DEFAULT(NULL));

/****************************************************************************************\
*                                  Feature detection                                     *
\****************************************************************************************/

/** @brief Runs canny edge detector
@see mobilecv2::Canny
*/
CVAPI(void)  cvCanny( const CvArr* image, CvArr* edges, double threshold1,
                       double threshold2, int  aperture_size CV_DEFAULT(3) );

/** @brief Calculates constraint image for corner detection

   Dx^2 * Dyy + Dxx * Dy^2 - 2 * Dx * Dy * Dxy.
   Applying threshold to the result gives coordinates of corners
@see mobilecv2::preCornerDetect
*/
CVAPI(void) cvPreCornerDetect( const CvArr* image, CvArr* corners,
                               int aperture_size CV_DEFAULT(3) );

/** @brief Calculates eigen values and vectors of 2x2
   gradient covariation matrix at every image pixel
@see mobilecv2::cornerEigenValsAndVecs
*/
CVAPI(void)  cvCornerEigenValsAndVecs( const CvArr* image, CvArr* eigenvv,
                                       int block_size, int aperture_size CV_DEFAULT(3) );

/** @brief Calculates minimal eigenvalue for 2x2 gradient covariation matrix at
   every image pixel
@see mobilecv2::cornerMinEigenVal
*/
CVAPI(void)  cvCornerMinEigenVal( const CvArr* image, CvArr* eigenval,
                                  int block_size, int aperture_size CV_DEFAULT(3) );

/** @brief Harris corner detector:

   Calculates det(M) - k*(trace(M)^2), where M is 2x2 gradient covariation matrix for each pixel
@see mobilecv2::cornerHarris
*/
CVAPI(void)  cvCornerHarris( const CvArr* image, CvArr* harris_response,
                             int block_size, int aperture_size CV_DEFAULT(3),
                             double k CV_DEFAULT(0.04) );

/** @brief Adjust corner position using some sort of gradient search
@see mobilecv2::cornerSubPix
*/
CVAPI(void)  cvFindCornerSubPix( const CvArr* image, CvPoint2D32f* corners,
                                 int count, CvSize win, CvSize zero_zone,
                                 CvTermCriteria  criteria );

/** @brief Finds a sparse set of points within the selected region
   that seem to be easy to track
@see mobilecv2::goodFeaturesToTrack
*/
CVAPI(void)  cvGoodFeaturesToTrack( const CvArr* image, CvArr* eig_image,
                                    CvArr* temp_image, CvPoint2D32f* corners,
                                    int* corner_count, double  quality_level,
                                    double  min_distance,
                                    const CvArr* mask CV_DEFAULT(NULL),
                                    int block_size CV_DEFAULT(3),
                                    int use_harris CV_DEFAULT(0),
                                    double k CV_DEFAULT(0.04) );

/** @brief Fits a line into set of 2d or 3d points in a robust way (M-estimator technique)
@see mobilecv2::fitLine
*/
CVAPI(void)  cvFitLine( const CvArr* points, int dist_type, double param,
                        double reps, double aeps, float* line );

/****************************************************************************************\
*                                     Drawing                                            *
\****************************************************************************************/
// Draw related functions have been removed.

#define CV_RGB( r, g, b )  cvScalar( (b), (g), (r), 0 )
#define CV_FILLED -1

#define CV_AA 16

/** @brief Draws contour outlines or filled interiors on the image
@see cv::drawContours
*/
CVAPI(void)  cvDrawContours( CvArr *img, CvSeq* contour,
                             CvScalar external_color, CvScalar hole_color,
                             int max_level, int thickness CV_DEFAULT(1),
                             int line_type CV_DEFAULT(8),
                             CvPoint offset CV_DEFAULT(cvPoint(0,0)));

}

// #ifdef __cplusplus
// }
// #endif

#endif
