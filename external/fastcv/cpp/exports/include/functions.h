#ifndef FASTCV_FUNCTIONS_H
#define FASTCV_FUNCTIONS_H
#include <vector>
#include "mat.h"
#include "types.hpp"

#if defined(WIN32) || defined(_WIN64)
#include <iostream>
#elif __linux__
#include <string.h>
#include <memory>
#endif

namespace FASTCV {
namespace EXPORTS {
    /**
     * verify gpu available on current platform
     * @param mode, is gpu backend mode(OCL, METAL, OGL, CUDA).
    */

    CV_EXPORTS bool verifyGPUAvailable(FASTCVGPUBackend mode);
    /**
     * verify gpu cl and gl mem share available on current platform
     * @param mode, is gpu backend mode(OCL, METAL, OGL, CUDA).
    */

    CV_EXPORTS bool verifyGLMemShareAvailable(FASTCVGPUBackend mode);
    /**
     * Calculates an affine transform from three pairs of the corresponding points.
     * 
     * @param src, it is 2x3 Matrix
     * @param dst, it is 2x3 Matrix
     * src and dst can not be same, inplace mode is not supported now.
    */ 
    CV_EXPORTS Mat getAffineTransform(const Point2f src[], const Point2f dst[]);

    /**
     * Applies an affine transformation.
     * 
     * @param src is input image on CPU.
     * @param dst output image that has the size dsize and the same type as src.
     * @param M 2x3 transformation matrix.
     * @param dsize size of the output image.
     * @param flags combination of interpolation methods (see #InterpolationFlags) and the optional
     * @param borderMode pixel extrapolation method (see #BorderTypes); when
     * borderMode=#BORDER_TRANSPARENT, it means that the pixels in the destination image corresponding to
     * the "outliers" in the source image are not modified by the function.
     * @param borderValue value used in case of a constant border; by default, it is 0.
     * src and dst can not be same, inplace mode is not supported now.
    */
    CV_EXPORTS void warpAffine(const Mat &src, Mat &dst, const Mat &M, Size dsize,
                    int flags = InterpolationFlags::INTER_LINEAR,
                    int borderMode = BORDER_CONSTANT,
                    const Scalar& borderValue = Scalar());

    /**
     * Applies an affine transformation on GPU, Params is same to CPU warpAffine.
    */
    CV_EXPORTS void warpAffine(const UMat &src, UMat &dst, const Mat &M, Size dsize,
                    int flags = INTER_LINEAR, int borderMode = BORDER_CONSTANT,
                    const Scalar& borderValue = Scalar());

    /**
     * Applies an affine transformation and convert u8 to float.
     * 
     * @param src is input image on CPU.
     * @param dst output image that has the size dsize and the same type as src.
     * @param M 2x3 transformation matrix.
     * @param dsize size of the output image.
     * @param flags combination of interpolation methods (see #InterpolationFlags) and the optional
     * @param borderMode pixel extrapolation method (see #BorderTypes); when
     *  borderMode=#BORDER_TRANSPARENT, it means that the pixels in the destination image corresponding to
     * the "outliers" in the source image are not modified by the function.
     * @param borderValue value used in case of a constant border; by default, it is 0.
     * @param alpha	optional scale factor, by default, it is 1.
     * @param beta	optional delta added to the scaled values, by default, it is 0.
     * src and dst can not be same, inplace mode is not supported now.
    */
    CV_EXPORTS void warpAffineConvertTo(const UMat &src, UMat &dst, const Mat &M, Size dsize,
                    double alpha = 1.0, double beta = 0.0, int flags = INTER_LINEAR, int borderMode = BORDER_CONSTANT,
                    const Scalar& borderValue = Scalar());

    /**
     * Calculates a perspective transform from four pairs of the corresponding points.
     * 
     * @param src Coordinates of quadrangle vertices in the source image.
     * @param dst Coordinates of the corresponding quadrangle vertices in the destination image.
     * @param solveMethod method is DECOMP_LU default and only  support.
     * src and dst can not be same, inplace mode is not supported now.
    */
    CV_EXPORTS Mat getPerspectiveTransform(const Point2f src[], const Point2f dst[], int solveMethod = DECOMP_LU);    

    /**
     * Applies a perspective transformation on CPU.
     * 
     * @param src input image.
     * @param dst output image that has the size dsize and the same type as src .
     * @param M 3x3 transformation matrix.
     * @param dsize size of the output image.
     * @param borderMode pixel extrapolation method (see #BorderTypes); when
     *  borderMode=#BORDER_TRANSPARENT, it means that the pixels in the destination image corresponding to
     * the "outliers" in the source image are not modified by the function.
     * @param borderValue value used in case of a constant border; by default, it is 0.
     * src and dst can not be same, inplace mode is not supported now.
    */
    CV_EXPORTS void warpPerspective(const Mat &src, Mat &dst,
                         const Mat &M, Size dsize,
                         int flags = INTER_LINEAR,
                         int borderMode = BORDER_CONSTANT,
                         const Scalar& borderValue = Scalar());  


    /**
     * Applies an perspective transformation on GPU, Params is same to CPU warpPerspective.
     * src and dst can not be same, inplace mode is not supported now.
    */
    CV_EXPORTS void warpPerspective(const UMat &src, UMat &dst,
                         const Mat &M, Size dsize,
                         int flags = INTER_LINEAR,
                         int borderMode = BORDER_CONSTANT,
                         const Scalar& borderValue = Scalar());                           
    /**
     * Resizes an image.
     * 
     * @param src input image.
     * @param dst output image; it has the size dsize (when it is non-zero) or the size computed from
     * src.size(), fx, and fy; the type of dst is the same as of src.
     * @param dsize output image size; if it equals zero, it is computed as:{dsize = Size(round(fx*src.cols), round(fy*src.rows))}
     * Either dsize or both fx and fy must be non-zero.
     * @param fx scale factor along the horizontal axis; when it equals 0, it is computed as
     * @param fy fy scale factor along the vertical axis; when it equals 0, it is computed as
     * @param interpolation interpolation method, now nearest and linear are supported only
     * src and dst can not be same, inplace mode is not supported now.
    */
    CV_EXPORTS void resize(const Mat &src, Mat &dst,
                Size dsize, double fx = 0, double fy = 0,
                int interpolation = INTER_LINEAR );
    /**
     * Applies an Resize on GPU, Params is same to CPU resize.
    */
    CV_EXPORTS void resize(const UMat &src, UMat &dst,
                Size dsize, double fx = 0, double fy = 0,
                int interpolation = INTER_LINEAR );


    /** Blurs an image using a Gaussian filter on CPU.
     * @param ksize Gaussian kernel size. ksize.width and ksize.height can differ but they both must be
     *  positive and odd. Or, they can be zero's and then they are computed from sigma.
     * @param sigmaX Gaussian kernel standard deviation in X direction.
     * @param sigmaY Gaussian kernel standard deviation in Y direction; if sigmaY is zero, it is set to be
     * equal to sigmaX, if both sigmas are zeros, they are computed from ksize.width and ksize.height,
     * respectively (see #getGaussianKernel for details); to fully control the result regardless of
     * possible future modifications of all this semantics, it is recommended to specify all of ksize,
     * sigmaX, and sigmaY.
     * @param borderType pixel extrapolation method, see #BorderTypes. #BORDER_WRAP is not supported.
     * src and dst can not be same, inplace mode is not supported now.
    */
    CV_EXPORTS void GaussianBlur(const Mat &src, Mat &dst, Size ksize,
                      double sigmaX, double sigmaY = 0,
                      int borderType = BORDER_REPLICATE );

    /**
    * Blurs an image using a Gaussian filter on GPU, Params is same to CPU.
    */
    CV_EXPORTS void GaussianBlur(const UMat &src, UMat &dst, Size ksize,
                      double sigmaX, double sigmaY = 0,
                      int borderType = BORDER_REPLICATE );

    /**
     *  Rotate image on CPU
     *  @param rotateCode type is RotateFlags, can rotate image 90, 180, 270 degree
     *  src and dst can not be same, inplace mode is not supported now.
    */
    CV_EXPORTS void rotate(const Mat &src, Mat &dst, int rotateCode);

    /**
    * Rotate image on GPU
    */
    CV_EXPORTS void rotate(const UMat &src, UMat &dst, int rotateCode);

    /*
    * read png and write png, now only support CV_8UC4
    */
    CV_EXPORTS void imread(const std::string & filename, Mat &mat);

    CV_EXPORTS void imwrite( const std::string& filename, Mat &mat);

    CV_EXPORTS void imread(const std::string & filename, UMat &umat);

    CV_EXPORTS void imwrite( const std::string& filename, UMat &umat);
    
    /** Make border for an image on CPU.
     * @param top the top pixels
     * @param bottom the bottom pixels
     * @param left the left pixels
     * @param right the right pixels. Parameter specifying how many pixels in each direction from the source image rectangle
     * to extrapolate. For example, top=1, bottom=1, left=1, right=1 mean that 1 pixel-wide border needs to be built.
     * @param borderType pixel extrapolation method, see #BorderTypes. Only support BORDER_CONSTANT or BORDER_REFLECT for now.
     * @param value Border value if borderType==BORDER_CONSTANT .
    */

    CV_EXPORTS void copyMakeBorder(const Mat &src, Mat &dst, int top, int bottom, int left, int right, int borderType,
                               const Scalar& value = Scalar());

    /**
     * Make border for an image on GPU. Params is same to CPU.
    */
    CV_EXPORTS void copyMakeBorder(const UMat &src, UMat &dst, int top, int bottom, int left, int right, int borderType,
                                   const Scalar& value = Scalar());

    /**
    * Transposes an image on CPU.
    */
    CV_EXPORTS void transpose(const Mat &src, Mat &dst);

    /**
    * Transposes an image on GPU.
    */
    CV_EXPORTS void transpose(const UMat &src, UMat &dst);
    
    /**
    * Flips an Image around vertical, horizontal, or both axes on CPU.
    * @param flipCode a flag to specify how to flip the array; 0 means flipping around the x-axis and positive value (for example, 1) means
    * flipping around y-axis. Negative value (for example, -1) means flipping around both axes.
    */
    CV_EXPORTS void flip(const Mat &src, Mat &dst, int flipCode);
    
    /**
    * Flips an Image on GPU. Params is same to CPU.
    */
    CV_EXPORTS void flip(const UMat &src, UMat &dst, int flipCode);
    
    /**
    * Returns a structuring element of the specified size and shape for morphological operations.
    * @param shape Element shape that could be one of #MorphShapes(MORPH_RECT, MORPH_CROSS or MORPH_ELLIPSE)
    * @param ksize Size of the structuring element.
    * @param anchor Anchor position within the element. The default value (-1, -1) means that the anchor is at the center.
    */
    CV_EXPORTS Mat getStructuringElement(int shape, Size ksize, Point anchor = Point(-1,-1));

    /**
    * Dilates an image by using a specific structuring element on CPU.
    * @param kernel structuring element used for dilation. Kernel can be created using #getStructuringElement. 
    * Only support odd kernel size for now, for example 3x3, 5x5, 7x7 and so on.
    * @param anchor position of the anchor within the element; default value (-1, -1) means that the anchor is at the element center.
    * Position of the anchor only support (-1, -1) for now.
    * @param iterations number of times dilation is applied.
    * @param borderType pixel extrapolation method, see #BorderTypes
    * @param borderValue border value in case of a constant border
    */
    CV_EXPORTS void dilate(const Mat &src, Mat &dst, Mat &kernel, Point anchor = Point(-1,-1), int iterations = 1, int borderType = BORDER_CONSTANT, const Scalar& borderValue = Scalar::all(0));
    
    /**
    * Dilates an image by using a specific structuring element on GPU. Params is same to CPU.
    */
    CV_EXPORTS void dilate(const UMat &src, UMat &dst, Mat &kernel, Point anchor = Point(-1,-1), int iterations = 1, int borderType = BORDER_CONSTANT, const Scalar& borderValue = Scalar::all(0));

    /**
    * Erodes an image by using a specific structuring element on GPU. Params is same to CPU.
    * @param kernel structuring element used for dilation. Kernel can be created using #getStructuringElement. 
    * Only support odd kernel size for now, for example 3x3, 5x5, 7x7 and so on.
    * @param anchor position of the anchor within the element; default value (-1, -1) means that the anchor is at the element center.
    * Position of the anchor only support (-1, -1) for now.
    * @param iterations number of times dilation is applied.
    * @param borderType pixel extrapolation method, see #BorderTypes
    * @param borderValue border value in case of a constant border
    */
    CV_EXPORTS void erode(const Mat &src, Mat &dst, Mat &kernel, Point anchor = Point(-1,-1), int iterations = 1,
                          int borderType = BORDER_CONSTANT, const Scalar& borderValue = Scalar::all(0));

    /**
    * Erodes an image by using a specific structuring element on GPU. Params is same to CPU.
    */
    CV_EXPORTS void erode(const UMat &src, UMat &dst, Mat &kernel, Point anchor = Point(-1,-1), int iterations = 1,
                      int borderType = BORDER_CONSTANT, const Scalar& borderValue = Scalar::all(0));

    /**
    * Calculates the subtract mean value of src image on CPU.
    * @param val the pointer of mean value 
    * @param valType mean value type. valType only support S8 or S16 for now.
    * dst(i, j) = src(i, j) - (*val)
    */
    CV_EXPORTS void subtract_mean(Mat &src, const void *val, Mat &dst, int valType = -1);

    /**
    * Calculates the subtract mean value of src image on GPU.
    */
    CV_EXPORTS void subtract_mean(const UMat &src, const void *val, UMat &dst, int valtype = -1);

    /**
    * Calculates the exponent of every element of the src image on CPU.
    * dst(i, j) = e^(src(i, j)). The element type of src and dst is float.
    */
    CV_EXPORTS void expf(const Mat &src, Mat &dst);

    /**
    * Calculates the exponent of every element of the src image on GPU.
    * dst(i, j) = e^(src(i, j)). The element type of src and dst is float.
    */
    CV_EXPORTS void expf(const UMat &src, UMat &dst);

    /**
    * Converts an image from one color space to another on CPU.
    * @param code color space conversion code (see #ColorConversionCodes).
    * @param dstCn number of channels in the destination image; if the parameter is 0, the number of the
    * channels is derived automatically from src and code.
    */
    CV_EXPORTS void cvtColor(const Mat &src, Mat &dst, int code, int dstCn = 0);

    /**
    * Converts an image from one color space to another on GPU. Params is same to CPU.
    */ 
    CV_EXPORTS void cvtColor(const UMat &src, UMat &dst, int code, int dstCn = 0);

    /**
    * Converts an image from one color space to another on CPU. This function only supports YUV NV12 to BGR conversion as of now.
    *  @param inputs  input image, the inputs color space can be YUV NV12. In this case, inputs size is 2. inputs[0] is Y plane and inputs[1] is UV plane.
    *  @param outputs output image, outputs size is 1, outputs[0] is BGR.
    */
    CV_EXPORTS void cvtColor(std::vector<Mat*> inputs,  std::vector<Mat*> outputs, int code, int dstCn = 0);

    /**
    * Converts an image from one color space to another on GPU. This function only supports YUV NV12 to BGR conversion as of now.
    * Params is same to CPU.
    */
    CV_EXPORTS void cvtColor(std::vector<UMat*> inputs,  std::vector<UMat*> outputs, int code, int dstCn = 0);
    
    /**
    * Alpha Blend an image on CPU,
    * alphaVal = alphamask(i, j).w / 255.0f, alphaVal, 0.0 <= alphaVal  <= 1.0f
    * dst(i, j) = alphamask(i, j) * alphaVal + src(i, j) * (1.0 -alphaVal)
    * src0/src1/dst type must be U8
    */
    CV_EXPORTS void alphaBlend(const Mat &src, const Mat &alphamask, Mat &dst, const int left, const int top, const int cropW, const int cropH);
    /**
    * Alpha Blend an image on GPU. Params is same to CPU.
    */
    CV_EXPORTS void alphaBlend(const UMat &src, const UMat &alphamask, UMat &dst, const int left, const int top, const int cropW, const int cropH);

    /**
    * Alpha Blend an image on CPU. 
    * alphaVal = alpha(i, j).x, alphaVal, 0.0 <= alphaVal  <= 1.0f
    * dst(i, j) = src1(i, j) * alphaVal + src0(i, j) * (1.0 -alphaVal)
    */
    CV_EXPORTS void alphaBlend(const Mat &src0, const Mat &src1, const Mat &alpha, Mat &dst);
    /**
    * Alpha Blend an image on GPU. Params is same to CPU.
    */
    CV_EXPORTS void alphaBlend(const UMat &src0, const UMat &src1, const UMat &alpha, UMat &dst);

    /**
    * combine four images to an image on GPU.
    * orderFlag = 0, src0 -> src1 -> src2 -> src3, interweave
    * orderFlag = 1, src3 -> src2 -> src1 -> src0, interweave
    */
    CV_EXPORTS void combineAndConvertTo(const UMat &src0, const UMat &src1, const UMat &src2, const UMat &src3,
        UMat &dst, const int orderFlag = 0);

    /*
    *  Dense optical flow 
    */
    class DISOpticalFlow {
    private:
        void* internal_;
    public: 
        DISOpticalFlow();
        ~DISOpticalFlow();
        enum {
            PRESET_ULTRAFAST,
            PRESET_FAST,
            PRESET_MEDIUM,
        };
    public:
        /**
        * Creates an instance of DISOpticalFlow
        * @param preset one of PRESET_ULTRAFAST, PRESET_FAST and PRESET_MEDIUM
        * @param threadNum cpu thread number to run DISOpticalFlow on cpu
        * Only support PRESET_ULTRAFAST for now.
        */
        CV_EXPORTS static std::shared_ptr<DISOpticalFlow> create(int preset = PRESET_ULTRAFAST, int threadNum = 2);
    public:
        /**
        * Calculates an optical flow on CPU.
        * @param src1 first 8-bit single-channel input image.
        * @param src2 second input image of the same size and the same type as prev.
        * @param flow computed flow image that has the same size as prev and type CV_32FC2.
        */
        CV_EXPORTS void calc(const Mat& src1, const Mat& src2, Mat& flow);

        /**
        * Calculates an optical flow on GPU. Params is same to CPU.
        */
        CV_EXPORTS void calc(const UMat& src1, const UMat& src2, UMat& flow);
#ifdef __ANDROID__
        /**
        * Calculates an optical flow on CPU.
        * @param boostCpu boost cpu frequency or not.
        */        
        CV_EXPORTS void calc(const Mat& src1, const Mat& src2, Mat& flow, bool boostCpu);
#endif
    };

    /**
    * copy an image roi on CPU. 
    */
    CV_EXPORTS void copyROI(const Mat &src, Mat &dstROI, int left, int top, int roiWidth = 0, int roiHeight = 0);
    /**
    * copy an image roi on GPU. Params is same to CPU.
    */
    CV_EXPORTS void copyROI(const UMat &src, UMat &dstROI, int left, int top, int roiWidth = 0, int roiHeight = 0);

    /**
     * get fastcv version
    */

    CV_EXPORTS const char* getFastcvVersion();

    /**
     * exposure compensate an image on CPU.
     * @param inputs input   y and uv.
     * @param outputs output y and uv.
     * @param hdrintensity hdr intensity.
     * @param lowHighFlag exposure enhance or decrease flag. If lowHighFlag set 0 decrease exposure; else if lowHighFlag set 1 enhance exposure.
    */
    CV_EXPORTS void expose(std::vector<Mat*> inputs,  std::vector<Mat*> outputs, int hdrintensity, int lowHighFlag);

    /**
    * exposure compensate an image on GPU. Params is same to CPU.
    */
    CV_EXPORTS void expose(std::vector<UMat*> inputs,  std::vector<UMat*> outputs, int hdrintensity, int lowHighFlag);

    /**
     * down sample blend an image on CPU.
     * @param inputs alpha, beta, gauss_pyrid, y and uv 
     * @param outputs output y and uv.
     * @param downSampleSize downsample size, set 2 or 3.
    */
    CV_EXPORTS void alphaBetaDownsampleBlend(std::vector<Mat*> inputs,  std::vector<Mat*> outputs, const int downSampleSize);

    /**
     * down sample blend an image on GPU.
    */
    CV_EXPORTS void alphaBetaDownsampleBlend(std::vector<UMat*> inputs,  std::vector<UMat*> outputs, const int downSampleSize);

    /**
     * @brief 
     * 
     */
    CV_EXPORTS void *createGpuMarkerEvent(const GPUContext *pCtx);

    /**
     * @brief 
     * 
     */
    CV_EXPORTS void releaseGpuMarkerEvent(const GPUContext *pCtx, void * event);

    /**
     * @brief 
     * 
     */
    CV_EXPORTS void waitForGpuMarkerEvent(const GPUContext *pCtx, void * event);

    /**
     * @brief 
     * 
     */
    CV_EXPORTS void boxFilter(const Mat &src, Mat &dst, int ddepth, Size ksize,
                      Point anchor = Point(-1,-1), bool normalize = true, int borderType = BORDER_DEFAULT );
    /**
     * @brief 
     * 
     */
    CV_EXPORTS void boxFilter(const UMat &src, UMat &dst, int ddepth, Size ksize,
                     Point anchor = Point(-1,-1), bool normalize = true, int borderType = BORDER_DEFAULT );

    /**
     * Applies an Sobel on GPU, Params is same to CPU Sobel.
    */
    CV_EXPORTS void sobel(const UMat &src, UMat &dst,
                 int dx, int dy, int ksize = 3);
    /**
    * Calculates the add value of src image on CPU.
    */
    CV_EXPORTS void add(Mat &src1, Mat &src2, Mat &dst, int valType);

    /**
    * Calculates the add value of src image on GPU.
    */
    CV_EXPORTS void add(const UMat &src1, const UMat &src2, UMat &dst, int valType);

    /**
    * Calculates the absdiff mean value of src image on CPU.
    * dst(i, j) = |src1(i, j) - src2(i, j)|
    */
    CV_EXPORTS void absdiff(Mat &src1, Mat &src2, Mat &dst, int valType);

    /**
    * Calculates the absdiff mean value of src image on GPU.
    */
    CV_EXPORTS void absdiff(const UMat &src1, const UMat &src2, UMat &dst, int valType);

    /**
    * Calculates the bitwise_and value of src image on CPU.
    * dst(i, j) = src1(i, j) & src2(i, j)
    */
    CV_EXPORTS void bitwise_and(Mat &src1, Mat &src2, Mat &dst, Mat &mask, int valType);

    /**
    * Calculates the bitwise_and value of src image on GPU.
    */
    CV_EXPORTS void bitwise_and(const UMat &src1, const UMat &src2, UMat &dst, int valType);

    /**
     * image convert from u8/float32 to float32/u8
     * multiply by alpha, add beta
     * dst = src * alpha + beta
     */
    CV_EXPORTS void ConvertTo(const UMat &src0, const UMat &src1, float alpha, float beta);

    /**
    * Calculates the bitwise_and value of src image on GPU.
    */
    CV_EXPORTS void calcHist(const UMat &src, UMat &mask, UMat &hist);

    /**
    *Normalizes the src mat on CPU.
    */
    CV_EXPORTS void normalize(const Mat &src, Mat &dst, double alpha, double beta, int norm_type = NORM_MINMAX , int dtype = -1);

    /**
    *Normalizes the src umat on GPU.
    */
    CV_EXPORTS void normalize(const UMat &src, UMat &dst, double alpha, double beta, int norm_type = NORM_MINMAX , int dtype = -1);
    /*
    *  Init Gpu Configurations
    */
    CV_EXPORTS void initContext(GPUContext &ctx, FASTCVGPUBackend gpuType, const char *path, bool autosync = true);

    /**
    * Divides a multi-channel mat into several single-channel mats on CPU.
    * @param input  multi-channel mat.
    * @param outputs single-channel mats, the size of std::vector<Mat*> must match input channels.
    */
    CV_EXPORTS void split(const Mat& input,  std::vector<Mat*> outputs);
     /**
    * Divides a multi-channel mat into several single-channel mats on GPU. Params is same to CPU.
    */   
    CV_EXPORTS void split(const UMat& input, std::vector<UMat*> outputs);


    /**
    * Creates one multi-channel mat out of several single-channel mats on CPU.
    * @param inputs mats to be merged;
    * @param output a multi-channel mat. The number of output channels will be the std::vector<Mat*> size.
    */
    CV_EXPORTS void merge(std::vector<Mat*> inputs,  Mat& output);
    /**
    * Creates one multi-channel mat out of several single-channel mats on GPU. Params is same to CPU.
    */
    CV_EXPORTS void merge(std::vector<UMat*> inputs,  UMat& output);


    /*
    *  sync gpu
    */
   CV_EXPORTS void synchronize(GPUContext *ctx);
    /**
    * Applies a fixed-level threshold to each array element on CPU.
    * @param thresh threshold value.
    * @param maxval maximum value to use with the #THRESH_BINARY and #THRESH_BINARY_INV thresholding types.
    * @param threshType thresholding type (see #ThresholdTypes).
    */
    CV_EXPORTS double threshold(const Mat& input, Mat &output, double thresh, double maxval, int threshType);

    /**
    * Applies a fixed-level threshold to each array element on GPU. Params is same to CPU.
    */
    CV_EXPORTS double threshold(const UMat& input, UMat &output, double thresh, double maxval, int threshType);
	
    /**
     * verify gpu dx texture and gl mem share available on current platform
     * @param mode  gpu backend mode(OCL, METAL, OGL, CUDA).
     * @param pd3dDevice ID3D11Device pointer
     * @param d3dVersion d3d version (see #FASTCVD3DVersion), only support d3d11 for now.
    */
    CV_EXPORTS bool verifyDXMemShareAvailable(FASTCVGPUBackend mode, void* pd3dDevice, FASTCVD3DVersion d3dVersion);

    
    /**
    *  downscale with Antialiasing and sharpen
    * @param input:
    * @param output:
    * @param sharpRatio: should be in range(0.25, 0.6), default is 0.35,
    * @param aaRatio: should be in range(1.0, 2.0), default is 1.25,
    */
    CV_EXPORTS void downScale(const UMat &src, UMat &dst, float sharpRatio = 0.35, float aaRatio = 1.25);

    /**
    * Performs a forward or inverse discrete Cosine transform (DCT) of a 1D or 2D floating-point mat on CPU.
    * @param input input floating-point mat.
    * @param output output mat of the same size and type as input.
    * @param flags transformation flags, only support forward dct(flags = 0) for now.
    */
    CV_EXPORTS void dct(const Mat& input, Mat &output, int flags = 0);

    /**
    * Performs a forward discrete Cosine transform (DCT) of a 1D or 2D floating-point mat on GPU. Params is same to CPU.
    */
    CV_EXPORTS void dct(const UMat& input, UMat &output, int flags = 0);

    /** Draws a text string.
    * The function putText renders the specified text string in the image.
    * @param img Image.
    * @param text Text string to be drawn.
    * @param org Bottom-left corner of the text string in the image.
    * @param fontFace Font type, see #HersheyFonts.
    * @param fontScale Font scale factor that is multiplied by the font-specific base size.
    * @param color Text color.
    * @param thickness Thickness of the lines used to draw a text.
    * @param lineType Line type. See #LineTypes
    * @param bottomLeftOrigin When true, the image data origin is at the bottom-left corner. Otherwise,
    * it is at the top-left corner.
    */
    CV_EXPORTS void putText(const Mat& img, std::string& text, Point org,  int fontFace, double fontScale, Scalar color, 
        int thickness = 1, int lineType = LINE_8, bool bottomLeftOrigin = false);

    /**
     * @brief set callback for log refloatation
    */
    CV_EXPORTS void setLogCallBack(PtrLogCallbackFunc logCallback);

    /**
    * Performs a inverse discrete Cosine transform (IDCT) of a 1D or 2D floating-point mat on CPU.
    * @param input input floating-point mat.
    * @param output output mat of the same size and type as input.
    * @param flags transformation flags, only support inverse dct(flags = 0) for now.
    */    
    CV_EXPORTS void idct(const Mat& input, Mat &output, int flags = 0);
    
    /**
    * Performs a inverse discrete Cosine transform (IDCT) of a 1D or 2D floating-point mat on GPU. Params is same to CPU.
    */    
    CV_EXPORTS void idct(const UMat& input, UMat &output, int flags = 0);

    /**
     * @brief perform discrete wavelet transform
     * @param input input floating-point mat.
    * @param output output mat vector.
    * @param flags transform flags, only support haar(flags==0) for now
     */
    CV_EXPORTS void dwt(const Mat& input, std::vector<Mat*> output, int flags = 0);
    
    /**
    * Performs discrete wavelet transform on gpu
    */  
    CV_EXPORTS void dwt(const UMat& input, std::vector<UMat*> output, int flags = 0);

    /**
     * @brief perform inverse discrete wavelet transform
     * @param flag transform flags, only support haar(flags==0) for now
     */
    CV_EXPORTS void idwt(const std::vector<Mat*> input, Mat& output, int flags = 0);

    /**
    * Performs inverse discrete wavelet transform on gpu
    */ 
    CV_EXPORTS void idwt(const std::vector<UMat*> input, UMat& output, int flags = 0);

    /**
     * @brief Get Current FastCL Running Status
     */
    CV_EXPORTS FastCVCode getGPUContextStatus(GPUContext *ctx);

    /**
     * @brief Op configuration when init engine
     * 
     */
    CV_EXPORTS void setOpEnableConfig(GPUContext *context, OpClass opclass, int opflag);

    /**
     * @brief load egl library with library path
     * @param path angle egl library path
     */
    CV_EXPORTS void loadEGLLibrary(const char* path);

    /**
     * @brief load egl library with callback function
     * @param loadProc angle egl library load callback function
     */
    CV_EXPORTS void loadEGL(fastcv_get_proc_func loadProc);

    /**
     * @brief unload egl library
     */
    CV_EXPORTS void unloadEGLLibrary();

    /**
     * @brief load gles library with library path
     * @param path angle gles library path
     */
    CV_EXPORTS void loadGLESLibrary(const char* path);

    /**
     * @brief load gles library with callback function
     * @param loadProc angle gles library load callback function
     */
    CV_EXPORTS void loadGLES(fastcv_get_proc_func loadProc);

    /**
     * @brief unload gles library
     */
    CV_EXPORTS void unloadGLESLibrary();

} // namespace FASTCV
}

#endif
