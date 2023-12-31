
// Copyright (C) 2020 Beijing Bytedance Network Technology Co., Ltd. All rights reserved.

#ifndef _LENS_BASIC_TYPE_H_
#define _LENS_BASIC_TYPE_H_

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#ifdef __cplusplus
extern "C" {
#endif

/*LensDataFormat*/
typedef enum{
    LENS_DATA_RGBA8888 = 0,
    LENS_DATA_BGRA8888,
    LENS_DATA_BGR888,
    LENS_DATA_RGB888,
    LENS_DATA_NV12,
    LENS_DATA_GRAY,
    LENS_DATA_NV21,
    LENS_DATA_YV12,
    LENS_DATA_I420,
    LENS_DATA_TEXTURE,
    LENS_TEXTURE_OES,
    LENS_TEXTURE_RGB8,
    LENS_TEXTURE_BGR8,
    LENS_TEXTURE_RGBA8,
    LENS_TEXTURE_BGRA8,
    LENS_TEXTURE_ABGR8,
    LENS_APPLE_IMG,
    LENS_DATA_RGB565,
    LENS_APPLE_TEXTURE,
    LENS_AGFX_TEXTURE,
    LENS_DATA_YUV444,
    LENS_TEXTURE_RGBA16,
    LENS_TEXTURE_BGRA16,
    LENS_TEXTURE_ABGR16,
    LENS_DATA_RGBA16,
    LENS_DATA_BGRA16,
    LENS_DATA_RGBA10,
    LENS_DATA_BGRA10,
    LENS_DATA_NV12_16,
    LENS_DATA_NV21_16,
    LENS_DATA_YV12_16,
    LENS_DATA_I420_16,
    LENS_TEXTURE_RGBA8_DX,
    LENS_TEXTURE_BGRA8_DX,
    LENS_TEXTURE_ARGB8_DX,
    LENS_TEXTURE_RGBA16_DX,
    LENS_TEXTURE_BGRA16_DX,
    LENS_TEXTURE_ARGB16_DX,
}LensDataFormat;

/*LensDataType*/
typedef enum{
    LENS_DATA_BUFFER,
    LENS_TEXTURE_1D,
    LENS_TEXTURE_2D,
    LENS_TEXTURE_EXTERNAL,
    LENS_TEXTURE_3D,
    LENS_TEXTURE_CUBE,
    LENS_TEXTURE_BUFFER,
    LENS_TEXTURE_2D_MS,
    LENS_TEXTURE_1D_ARRAY,
    LENS_TEXTURE_2D_ARRAY,
    LENS_TEXTURE_CUBE_ARRAY,
    LENS_TEXTURE_2D_MS_ARRAY
}LensDataType;

typedef enum {
    LENS_ClockwiseRotate_0 = 0,
    LENS_ClockwiseRotate_90,
    LENS_ClockwiseRotate_180,
    LENS_ClockwiseRotate_270
}LensRotateOrient;

/*Algorithm Backend type， backend类型*/
typedef enum{
    LENS_BACKEND_CPU = 0,
    LENS_BACKEND_GPU,
    LENS_BACKEND_DSP,
    LENS_BACKEND_HETEROGENE,
    LENS_BACKEND_DYNAMIC_TUNING,
    LenGrammaBlurReal,  //虚化实时处理算法
    LenGrammaBlurShoot,  //虚化拍摄算法
    LENS_BACKEND_CoreML,//apple CoreML
}LensBackendType;

typedef enum {
    LENS_NO_ERROR = 0,
    LENS_INPUT_PARM_ERROR,
    LENS_MALLOC_MEMORY_FAILED,
    LENS_FORMAT_NOT_SUPPORT,
    LENS_COMPUTE_ERROR,
    LENS_NO_EXECUTION,
    LENS_EXEXCUTION_CRASH,
    LENS_INPUT_DATA_ERROR,
    LENS_CALL_BACK_STOP,
    LENS_INVALID_HANDLE,
    LENS_ABORT_EXCEPTION,
    LENS_FORMAT_TRANS_ERROR,
    LENS_DETECT_FACE_FAILED,
    LENS_DETECT_HEAD_SEG_FAILED,
    LENS_INIT_GL_ENVIRONMENT_ERROR,
    LENS_EXCEPTION_GL_EXCEPTION,
    LENS_LOAD_MODEL_FAILED,
    LENS_PROCESS_FAILED,
    LENS_DETECT_FACE_SUCCESS,
    LENS_NOT_SUPPORT,
    LENS_ALGO_NOT_EXIST,
    LENS_INITING_WAIT,
    LENS_INIT_ERROR,
    LENS_INVALID_OUTPUT,
    LENS_GPU_ERROR
}LensCode;

typedef enum {
    LENS_POWER_LEVEL_DEFAULT = 0,
    LENS_POWER_LEVEL_LOW,
    LENS_POWER_LEVEL_NORMAL,
    LENS_POWER_LEVEL_HIGH,
    LENS_POWER_LEVEL_AUTO,
} LensPowerLevel;

/*hdr detect */
typedef struct {
    int width;
    int height;
    int *feinfo[10];
    int fecount[10];
    int scene;
    LensRotateOrient orient;
    int framesThr;
}LensHdrDetect;

//Darklight enhancement
typedef struct{
    int srcWidth;
    int srcHeight;
    bool open;
}LensDleParam;

typedef struct{
    void *rawData;
    int srcWidth;
    int srcHeight;
    LensDataFormat pixel_fmt;
    int aperture;
    float z_far;
    float z_near_;
}LenGrammaBlurParam;

//video Super Resolution
typedef enum {
    SR_R_TYPE   = 0,
    SR_A_TYPE   = 1,
    SR_G_TYPE   = 2,
    SR_N_TYPE   = 3,
    SR_R15_TYPE = 4,
    SR_U_UNKNOW,
}LensVideoAlgType;

typedef struct {
    const char* binPath;
    bool  isExtOESTexture;
    LensDataFormat pixelFmt;
    LensVideoAlgType srType;
    int maxHeight;
    int maxWidth;
    void* filterPtr;
    int filterSize;
    float thresh;
    LensPowerLevel powerLevel;
    LensBackendType backendType;
    int numThread;
    bool isMaliSync;
}LensVideoSrConfigParam;

typedef struct {
    int  width;
    int  height;
    bool open; //动态开启/关闭超分
    int  textureId;//输入纹理id
    float* stMatrix;
    //如果是oes纹理,传入SurfaceTexture获取的纹理矩阵
}LensVideoSrParam;

//video SR for iOS
typedef enum {
    DATA_Tex_Mode = 0,  //输出数据为METAL texture
    DATA_IMG_Mode,     //输出数据为CVPixelbuffer
}LensDataMode;

typedef struct {
    const char* modelData;
    int   modelDataLength;
    const char* metalPath;
    int   width;
    int   height;
    /**
     是否启用内存池.
     短视频场景建议使用内存池模式;
     */
    bool  enableMemPool;
    /*输入数据:目前暂只支持DATA_IMG_Mode模式*/
    LensDataMode inputDataMode;
    /*输出数据 */
    LensDataMode outputDataMode;

    /*消费端不需要设置; effectSDK 设置为2601.0*/
    float flat_thresh;
}LensVideoiOSSRConfig;

typedef struct {
    /**
     iOS metal 的id <MTLDevice>,如果业务不传下来，
     则lens直接使用MTLCreateSystemDefaultDevice()获取缺省device.
     */
    void  *device;
    /**
     inputDataMode 为当此数据为输入时:
        rawData[0] 为pixelbuffer, rawData[1]、rawData[2]为nil;
     当此数据为输出时:
        outputDataMode 是DATA_Tex_Mode 则rawData[0]为y_texture, rawData[1] 为uv_texture;
        outputDataMode 是DATA_IMG_Mode，rawData[2]是pixelbuffer;
     */
    void *rawData[3];
    LensDataFormat fmt;
    int   width;
    int   height;
}LensVideoiOSNNSRParam;

typedef enum {
    LENS_ASF_SCENE_MODE_LIVE_GAME = 0,
    LENS_ASF_SCENE_MODE_LIVE_PEOPLE,
    LENS_ASF_SCENE_MODE_EDIT,
    LENS_ASF_SCENE_MODE_RECORED_MAIN,
    LENS_ASF_SCENE_MODE_RECORED_FRONT,
    LENS_ASF_SCENE_MODE_RECORED_ONEKEY,
} LENS_ASF_SCENE_MODE;

typedef enum {
    LENS_ASF_DATA_TYPE_TEXTURE_RGBA = 0,
    LENS_ASF_DATA_TYPE_TEXTURE_YUV,
    LENS_ASF_DATA_TYPE_PIXELBUFFER_NV12,
    LENS_ASF_DATA_TYPE_PIXELBUFFER_RGB,
    LENS_ASF_DATA_TYPE_TEXTURE_OES
} LENS_ASF_DATA_TYPE;

typedef struct {
    LENS_ASF_SCENE_MODE       scene_mode;
    void*                     context;                  // used for iOS
    LENS_ASF_DATA_TYPE        input_type;
    LENS_ASF_DATA_TYPE        output_type;
    int                       frame_width;
    int                       frame_height;
    float                     amount;                   // default to -1
    float                     over_ratio;               // default to -1
    float                     edge_weight_gamma;        // default to -1
    int                       diff_img_smooth_enable;   // default to -1
    LensPowerLevel            power_level;              // used for QUALCOMM GPU
    void*                     reserved;
} LensASFInitParam;

typedef struct {
    LENS_ASF_SCENE_MODE       scene_mode;
    int                       frame_width;
    int                       frame_height;
    float                     amount;                   // default to -1
    float                     over_ratio;               // default to -1
    float                     edge_weight_gamma;        // default to -1
    int                       diff_img_smooth_enable;   // default to -1
    void*                     reserved;
} LensASFProperty;

typedef struct {
    float*                    stMatrix;
    bool                      open;
    void*                     reserved;
} LensASFParam;

/*LensAlgorithmType*/
typedef enum {
    LENS_ALG_ROI = 0,
    LENS_ALG_DARK_LIGHT_ENHANCEMENT,
    LENS_ALG_ONEKEY_DETECTION, 
    LENS_ALG_COREML_POSTERSR, //deprecated
    LENS_ALG_METAL_GRAMMA_BLUR, //deprecated
    LENS_ALG_VIDEO_NNSR,
    LENS_ALG_VIDEO_SR,
    LENS_ALG_VIDEO_VRSR,
    LENS_ALG_AI_INSERT_FRAME,
    LENS_ALG_DIM_LIGHT_DETECTION,
    LENS_ALG_VIDEO_DENOISE,
    LENS_ALG_VIDEO_DEBLUR,
    LENS_ALG_DEARTIFACT,
    LENS_ALG_HDRVIDEO,
    LENS_ALG_VFI,
    LENS_ALG_TAINT_SCENE_DETECT,
    LENS_ALG_VIDEO_STAB,
    LENS_ALG_IMAGE_VRSR,
    LENS_ALG_ASF,
    LENS_ALG_FACE_DETECT,
    LENS_ALG_VIDEO_ANTI_SHAKE,
    LENS_ALG_NOISE_EST,  //reversed
    LENS_ALG_VIDEO_COVER,
    LENS_ALG_BYTE_BENCH,  //deprecated
    LENS_ALG_TRANSFER_DETECT,
    LENS_ALG_IMAGE_NNSR,
    LENS_ALG_IMAGE_DENOISE,
    LENS_ALG_LUMA_DETECT,
    LENS_ALG_TTIQ,
    LENS_NIGHTENHANCE,
    LENS_ALG_FE_RESTORATION,
    LENS_ALG_VIDEO_VRSREX,
    LENS_ALG_VIDEO_HDR_LITE,
    LENS_ALG_CAPTURE_ONEKEY_DETECTION,
    LENS_ALG_VRSRCUDA,
    LENS_ALG_VIDEO_SELECT_FRAME,
    LENS_ALG_VIDA,
    LENS_ALG_VIDEO_COVER_MODULE,
    LENS_ALG_SMART_CODEC,
    LENS_ALG_GCOVER,
    LENS_ALG_SDR2HDR,
    LENS_ALG_RHYTHMIC_MOTION,
    LENS_ALG_OLD_PHOTO_RESTORATION,
    LENS_ALG_VIDEO_BOKEH,
    LENS_ALG_VIDEO_MOTION_BLUR,
    LENS_ALG_VIDA_MOBILE_MODEL,
    LENS_ALG_SHAKE_DETECTION,
    LENS_ALG_VIDEO_DEFLICKER,
    LENS_ALG_IMAGE_NNHDR,
    LENS_ALG_CINE_MOVE,
    LENS_ALG_PIC_SMARTCODEC,
    LENS_ALG_VIDEO_DENOISE_NN,
    LENS_ALG_PICTURE_BOKEH,
    LENS_ALG_VIDEO_RELIT,
    LENS_ALG_CAMERA_LOCK,
    LENS_ALG_WATERMARK,
    LENS_ALG_CAPTURE_ONEKEY_ENHANCE,
    LENS_ALG_FE_RECOGNITION,
    LENS_ALG_FE_VIDEO_RESTORATION,
    LENS_ALG_UNDISTORTION,
    LENS_ALG_VIDEO_SMART_MOTION,
    LENS_ALG_WATERMARKNN,
    LENS_ALG_ZENITH2,
}LensAlgorithmType;

//video nn sr
typedef struct {
    int   maxWidth;
    int   maxHeight;
    int   wBlocks;
    int   hBlocks;
    int   ratio;   //超分倍率，支持1X和2X
    bool  isExtOESTexture;
    const char* modlePath;
    const char* gpuModleName;
    const char* dspModleName; //bytenn dsp模型文件绝对路径
    const char* jniLibPath;   //jni库路径,app层可通过getApplicationInfo().nativeLibraryDir获取
    LensDataFormat pixel_fmt;
    LensPowerLevel powerLevel; //性能模式，可选高，中，低性能
}LensVideoNnsrConfigParam;


typedef struct {
    int   maxWidth;
    int   maxHeight;
    int   wBlocks;
    int   hBlocks;
    int   ratio;   //超分倍率，支持1X和2X
    bool  isExtOESTexture;
    const char* modelPath;
    int     modelDataLength;
    const char* gpuModleName;
    const char* dspModleName; //bytenn dsp模型文件绝对路径
    const char* jniLibPath;   //jni库路径,app层可通过getApplicationInfo().nativeLibraryDir获取
    LensDataFormat input_fmt;
    LensDataFormat output_fmt;
    LensPowerLevel powerLevel; //性能模式，可选高，中，低性能

    /**
     是否启用内存池.
     短视频场景建议使用内存池模式;
     仅video VRSR 支持纹理池
     */
    bool  enableMemPool;

    /*消费端不需要设置; effectSDK 设置为2601.0*/
    float flat_thresh;
}LensSRConfigEx;

typedef struct {
    int  width;
    int  height;
    bool open; //动态开启/关闭超分
    LensDataFormat fmt;
    void *rawData[3];
    float* stMatrix;
    //如果是oes纹理,传入SurfaceTexture获取的纹理矩阵
}LensSRParamEx;

typedef struct {
    int width;
    int height;
    int algType; // 0 or 1 for image, 2 for video
    bool isInPlace;
    const char* modelPath;
    const char* modelPath_ff; //for lab frontface model
    int fe_count;
    int *fes;
    float intensity;
    void *pdevice;
}LensHdrVideoConfigParam;

typedef struct {
    void *data;
    int size;
    void *texId;
    void *outTexId;
    int rel_width;
    int rel_height;
    bool open;
    bool cleanCache;
}LensHdrVideoFrameParam;

typedef struct {
    int detectFrequency;
    const char* modelPath;
    const char* KernelBinPath;
    LensBackendType backendType; //default LensBackendType::LENS_BACKEND_GPU;
    int numThread; //only make sense when backendType is CPU, default set 2
} TaintSceneDetectParam;

typedef struct {
    void *inBuffer;
    bool switchScene;
} TaintSceneDetectBuffer;

// video frame interp
typedef struct {
    int  width;
    int  height;
    int  strideW;
    int  strideH;
    bool open; //动态开启/关闭视频插帧
    int  textureIdP;//P输入纹理id
    int  textureIdN;//N输入纹理id
    int  flag;//帧标志，0表示第一帧，1表示第二帧，2表示不更新帧，更新timeStamp（用于两帧间插多帧的case）
    float timeStamp;//帧间插帧位置，范围[0.0,1.0]，例如：0.5表示在两帧中间插帧，0.1表示在离第一帧0.1的位置插帧
    float* stMatrix;
    float scaleX;
    float scaleY;
    //如果是oes纹理,传入SurfaceTexture获取的纹理矩阵
}LensVideoVFIParameters;

//video vfi
typedef enum {
    VFI_UM_TYPE = 0,
    VFI_DIS_TYPE,
    VFI_NN_TYPE,
    VFI_COVER_TYPE,
    VFI_UNKNOW,
}LensVideoVFIAlgType;

typedef struct {
    void* context;
    const char* KernelBinPath;
    bool  isExtOESTexture;
    LensDataFormat pixelFmt;
    LensVideoVFIAlgType vfiType;
    LensPowerLevel powerLevel;
    int inputFrameNum;
}LensVideoVFIParam;

//brief frame buffer
typedef struct {
    int32_t thr;
    int32_t width;
    int32_t height;
}LENS_DLD_Param;

//video denoise
typedef struct {
    int width;
    int height;
    bool open; //动态开启/关闭视频降噪
    int iso;
    float* stMatrix;
    void *inBuffer;
    void *outBuffer;
    void* textureIn;
    void* textureOut; // only valid when use external agfx device
    LensDataFormat dataFmt;
    LensDataType dataType;
    /// @brief valid only vdType is VD_RTVD
    /// Valid value range in 0.0 ~ 1.0, defalut value 0.0
    float currentPixelWeight;
    /// Valid value range in 0.0 ~ 1.0, defalut value 0.00038447f
    float noise;
    /// Valid value range in 1.0 ~ 26.0, defalut value 25.5
    float errorThreshold;
}LensVideoDenoiseParam;

typedef enum {
    VD_RTVD,
    VD_FSNR,
    VD_FSNR_OCL,
    VD_HQDN,
    VD_UNKNOWN
}LensVideoDenoiseAlgoType;

typedef struct {
    bool  isExtOESTexture;
    LensDataFormat pixelFmt;
    LensVideoDenoiseAlgoType vdType;
    const char* KernelBinPath;
    LensPowerLevel perf;
    void *pdevice;
    int width;
    int height;
}LensVideoDenoiseConfigParam;

// only uesed in apple with internal agfx device
typedef struct {
    void* pixelBuffer;
}LensVideoDenoiseOutParms;

//video InsertFrame
typedef  enum {
    MAG_ONE = 1,
    MAG_TWO,
    MAG_THREE,
    MAG_FOUR,
    MAG_FIVE,
    MAG_SIX,
    MAG_SEVEN,
    MAG_EIGHT
} LensInsertFrameMode;

typedef struct{
    int width;
    int height;
    const char* modlePath;
}LensVideoInsertFrameConfigParam;

typedef struct {
    int  width;
    int  height;
    int  magnification;
}LensVideoInsertFrameParam;

// deblur
typedef enum {
    DEBLUR_ALG_VIDEO,
    DEBLUR_ALG_IMAGE
}DeblurAlgType;

typedef struct{
    const char* modlePath;
    DeblurAlgType algType;
    bool zenithVideo; //true means zenith video mode
    float sharpDeblurFactor;
}LensVideoDeblurConfigParam;

typedef enum {
    ZENITH2_ALG_VIDEO,
    ZENITH2_ALG_IMAGE
}Zenith2AlgType;

typedef struct{
    const char* modleDir;
    Zenith2AlgType algType;
}LensZenith2ConfigParam;

typedef struct {
    unsigned char* data;
    int width;
    int height;
    int stride;
    LensDataFormat pixel_fmt;
}LensImage;

typedef struct{
    double mat[9];
}LensMatrix3;

typedef struct{
    LensImage image;
    LensImage* roiImages;
    LensMatrix3* warpMatrixs;
    int feCnt;
    int roiCnt;
    bool gpuIO;
}LensVideoDeblurParam;

typedef struct{
    LensImage inputImage;
    LensImage outputImage;
    int gain_size_thresh;
    float gain_1;
    float gain_2;
    LensImage* roiImages;
    LensMatrix3* warpMatrixs;
    int feCnt;
    int roiCnt;
}LensZenith2Param;

typedef  struct {
    int inputWidth;
    int inputHeight;
    const char* modelPath;
    const char* KernelBinPath;
    LensBackendType backendType;
    int numThread; //only make sense when backendType is CPU
} DeartifactParam;

typedef  struct {
    int videoStabSmoothRadius;  // [1, 100]
    float videoStabMaxCropRatio; //[0, 0.5]
    int videoStabMotionType; //{1, 2, 3}-> 1.:similarity 2:affine 3:homography
} VideoStabConfig;

typedef enum {
    STAB_FRAME_START,
    STAB_FRAME_EST,
    STAB_FRAME_WARP
}StabFrameType;

typedef  struct {
    StabFrameType frameType;
    int width;
    int height;
    int step;
    LensDataFormat fmt;
    bool open;
    int frame_idx;    // valid when frameType is STAB_FRAME_WARP, default -1
}LensVideoStabParams;

// warp matrix 3x3
typedef struct {
    float M00, M01, M02;
    float M10, M11, M12;
    float M20, M21, M22;
}StabMatrix;

typedef struct {
    StabMatrix* matrixList;
    int matrixNum;
    int real_radius;
    float real_crop_ratio;
}LensVideoStabOut;

typedef struct {
    const char *modelBuff;
    int buffLength;
    // 设置每隔多少帧进行一次人脸检测(默认值有人脸时24, 无人脸时24/3=8), 值越大,
    // cpu占用率越低, 但检测出新人脸的时间越长.
    int face_detect_interval_frames;
    int face_detect_max_face_num; //最大人脸为10.
} LENSFaceConfig;

typedef struct  {
    unsigned char* data;      ///< 图像帧数据地址
    LensDataFormat pixel_fmt;       ///< 图像格式
    int width;                 ///< 图像的宽度
    int height;                ///< 图像的高度
    int stride;                ///< 图像的步长(每行的字节数，可能存在padding)
    LensRotateOrient orient;     ///< 图像的方向
} lensFaceInputData;

typedef struct {
  int left;    ///< 矩形最左边的坐标
  int top;     ///< 矩形最上边的坐标
  int right;   ///< 矩形最右边的坐标
  int bottom;  ///< 矩形最下边的坐标
} LENSRect;

typedef struct {
  int heightPoint;    //纵坐标值
  int widthPoint;     //横坐标值
} LENSCoor;

typedef struct LENSFaceInfoBase {
    LENSRect rect;                // 代表面部的矩形区域
    float score;                // 置信度
} LENSFaceInfoBase;


#define LENS_MAX_FACE_NUM 10
// 检测结果
typedef struct LENSFaceInfo {
    LENSFaceInfoBase base_infos[LENS_MAX_FACE_NUM];  // 检测到的基本的人脸信息
  int face_count;  // 检测到的人脸数目
} LENSFaceInfo;

typedef struct{
    int srcWidth;
    int srcHeight;
    int stride;
    LensDataFormat pixel_fmt;
    LensRotateOrient orient;
}LensImageParam;

typedef enum {
    PARTITION_NONE= 0, //(w,h)
    PARTITION_WIDTH,   //(w/2,h)
    PARTITION_HEIGHT,  //(w,h/2)
    PARTITION_CENTER,  //(w/2,h/2)
}LensNNsrPartitionType;

typedef struct {
    int srcWidth;
    int srcHeight;
    int dstWidth;
    int dstHeight;
    float scale;
    LensImage* roiImages;
    LensMatrix3* warpMatrixs;
    int feCnt;
    int roiCnt;
    LensNNsrPartitionType partitionType;
    bool gpuIO;
} LensNNSrParm;

typedef struct{
    const char* modelPath;
    bool singleFrameSr;
    bool imageMode;
    bool zenithVideo; //true means zenith video mode
    float sharpSrFactor;
}LensNNSrConfigParm;

typedef struct{
    const char* modlename;
    char* modelpatch;
    float mean;//input  = (pixel - mean) / std
    float std; //output = pixel * std + mean
    int srcWidth;
    int srcHeight;
    int dstWidth;
    int dstHeight;
    int WBlocks;
    int HBlocks;
}NNSRInitParam;

typedef struct{
    void *rawData;
    int srcWidth;
    int srcHeight;
    LensDataFormat pixel_fmt;
}LenCoreMLPosterParam;

//video anti shake
typedef enum {
    LENS_VAS_V1 = 0, // 第一版本
} LENS_VAS_ALGRITHM_TYPE;

typedef struct {
    int vasSmoothRadius;    // [1, 100]
    float vasMaxCropRatio;  // [0, 0.5]
    int vasMotionType;      // {1, 2, 3} -> 1.:similarity 2:affine 3:homography
} LensVasLevel;

typedef struct {
    LENS_VAS_ALGRITHM_TYPE vasType;
    LensDataFormat fmt;  // 输入帧格式
    LensVasLevel vasLevel; // 防抖等级参数
    int vasMaxWidth; // 输入帧宽的最大值
    int vasMaxHeight; // 输入帧高的最大值
    int vasThreadNum;  // 最大线程数
} LensVasConfig;

typedef enum {
    LENS_VAS_PROCESS_EST = 0,    // 标志进行预处理
    LENS_VAS_PROCESS_WARP = 1,   // 标志进行防抖处理
    LENS_VAS_PROCESS_RESET = 2,  // 标志进行重置处理
} LENS_VAS_PROCESS_TYPE;


typedef  struct {
    LENS_VAS_PROCESS_TYPE processType;  // 处理标识
    int width;
    int height;
    int strideW;
    bool open;   // 是否打开算法
    int frameIdx;  // 帧标志
    float scaleX; // 预处理X方向的downscale
    float scaleY; // 预处理Y方向的downscale
} LensVasParams;

typedef struct {
    float M00, M01, M02;
    float M10, M11, M12;
    float M20, M21, M22;
} LensVasMatrix;

typedef struct {
    LensVasMatrix* matrixList; // warp 矩阵列表，内存在算法内部分配
    int matrixNum;   // 矩阵数量，和视频帧总数对应
    int realRadius;  // 算法中实际使用的smooth radius, 通常和用户设定的相同，用户输入超出范围或特殊case下，算法内部会做调整
    float realCropRatio; // 算法中实际使用的crop ratio
} LensVasOutput;

// 算法需要两帧同时输入
typedef  struct {
    int width;
    int height;
    int step;
    LensDataFormat fmt;
    unsigned char* refFrame;
    unsigned char* tarFrame;
    int refTextureId;
    int tarTextureId;
    bool open;
}LensNoiseEstParams;

typedef enum {
    LENS_NOISE_LOW = 0,
    LENS_NOISE_MID,
    LENS_NOISE_HIGH
}LENS_NOISE_LEVEL;

typedef struct {
    float noise_sigma;
    LENS_NOISE_LEVEL noiseLevel;
}LensNoiseEstOut;

/* OneKey */
/* OneKey scene mode */
typedef enum {
    SCENE_MODE_MOBILE_EDITOR = 0,
    SCENE_MODE_MOBILE_RECORDE,
    SCENE_MODE_MOBILE_LIVE,
    SCENE_MODE_MOBILE_RTC,
    SCENE_MODE_PC_EDITOR,
    SCENE_MODE_PC_LIVE,
    SCENE_MODE_PC_RTC,
    SCENE_MODE_TRANSCODING
}OneKeySceneStrategyMode;

typedef enum {
    SCENE_MODE_CASE_COMMON = 20001, //case1
    SCENE_MODE_CASE_WITH_NOISE,     //case2
    SCENE_MODE_CASE_ABNORMAL,       //case3
    SCENE_MODE_CASE_NIGHT           //case4
}OneKeySceneCase;

typedef enum {
    ASF_MODE_FOR_ON = 0,        //代表开启锐化
    ASF_MODE_FOR_20004_OFF,     //代表在20004夜景时关闭锐化
    ASF_MODE_FOR_NOT_20004_OFF, //代表在非20004的情况下关闭锐化
    ASF_MODE_FOR_OFF,           //代表关闭锐化
}OneKeyASFMode;

typedef enum {
    HDR_MODE_FOR_ON = 0,             //代表所有场景开启HDR
    HDR_MODE_FOR_20001_OFF,          //代表在20001时关闭HDR
    HDR_MODE_FOR_20001_OR_20003_OFF, //代表在20001或20003关闭HDR
    HDR_MODE_FOR_20004_OFF,          //代表在20004关闭HDR
    HDR_MODE_FOR_OFF,                //所有case情况关闭HDR
}OneKeyHdrMode;

typedef enum {
    RECORD_SCENE_NIGHT = 0,          //拍摄夜景模式
    RECORD_SCENE_DAY_HIGH_DYNAMIC,   //白天高动态
    RECORD_SCENE_DAY_LOW_DYNAMIC,    //白天低动态
    RECORD_SCENE_UNKNOW,             //未知
}OneKeyRecordSceneCase;

typedef enum {
    RECORD = 0,  //iOS拍摄模式，CVPixelBuffer输入输出（NV12）
    EDITOR       //iOS编辑模式，AGFXTexture输入输出（RGBA）
}AlgoScenario;

/* OneKey scene strategy config */
typedef struct {
    LensDataFormat pixelFmt;//in ios use LENS_DATA_NV12 for record with nv12 cvpixelbuffer in and out
                            //in ios use LENS_AGFX_TEXTURE for editor with rgba agfx texture in and out
    const char* KernelBinPath;
    const char* modelPath;
    const char* algParamStream;
    void *pdevice; //in ios: agfx device for editor, metal device for record
    bool disableDenoise; //true, disable denoise; false, enable denoise
    OneKeyASFMode asfMode;
    OneKeyHdrMode hdrMode;
    int width;
    int height;
    bool isExtOESTexture;
    LensPowerLevel power_level; //used for QUALCOMM GPU
    OneKeySceneCase scene_case;
    //onekey record
    bool asyncProcess;
    bool oneKeyRecordHdrV2;
    bool disableAsf;
    bool disableHdr;
    bool disableDayScene;
    bool disableNightScene;
    void *reserved;
}OneKeySceneStrategyConfig;

/*OneKey scene input data*/
typedef struct {
    LensDataFormat dataFmt;
    bool open;    //only use in android
    void *inTexture;
    void *outTexture; //ios
    int width;
    int height;
    float* stMatrix;
    //onekey record
    int faceNum;
    LENSRect *faceList;
    OneKeyRecordSceneCase recordCase;
    bool recordDenoiseOpen;//降噪动态开关
    bool isProtectFe;
    bool isFirstFrame;
    int  initDecayFrames;//过渡帧数
    void *reserved;
}OneKeySceneInput;

/*OneKey scene output data */
typedef struct {
    void *outTexture;
    void *reserved;
    void *outUVTexture; //for ios reserved;
}OneKeySceneOutput;
/* OneKey end*/

#define MAX_VIDEO_COVER_KEY_FRAME 50
#define MAX_VIDEO_TOP_COVER_NUM 3
typedef enum {
    LENS_VIDEO_COVER_RECOMMEND = 0, // output 3 frames for users
    LENS_VIDEO_COVER_REPLACE = 1,  // output 1 frame for users
}LENS_VIDEO_COVER_HANDLE_TYPE;
typedef enum {
    LENS_VC_EXTRACT_FRAME = 0,    // 进行抽帧
    LENS_VC_SELECT_COVER = 1,   // 处理关键帧，选择封面
} LENS_VIDEO_COVER_PROCESS_TYPE;

typedef struct{
    const char* modlePath;
    LENS_VIDEO_COVER_HANDLE_TYPE handle_type;
}LensVideoCoverConfig;

typedef struct {
    unsigned char *data;
    int width;
    int height;
    int stride;
    int frameIdx;
    float fps;
    LensDataFormat pixel_fmt;
    LENS_VIDEO_COVER_PROCESS_TYPE type;
    const char* title;
}LensVideoCoverInput;


typedef struct {
    int keyFrameNum;
    int keyFrameIdx[MAX_VIDEO_COVER_KEY_FRAME];
}LensVideoCoverKeyFrames;

typedef struct {
    int frameIdx;
    int hasFace;
    int hasText;
    float attentionScore;
}LensVideoTopCover;

typedef struct {
    int coverNum;
    LensVideoTopCover topCover[MAX_VIDEO_TOP_COVER_NUM];
}LensVideoCoverOutput;

//bytebench
typedef struct {
    float memory_total_size;
    float cpu_core_nums;
    float cpu_freq;
    float storage_total_internal_size;
    float storage_total_external_size;
    float memory_size_low;
    float memory_size_high;
}ByteBenchInput;

typedef struct {
    int minWidth;
    int minHeight;
    float threshold;//32.0
    int  minSceneSize;//15
    void *pdevice; //ios
}LensVideoTransferDetectConfig;

typedef struct {
    int  width;
    int  height;
    bool reset;
    void* inTexture;//输入纹理/device
}LensVideoTransferDetectParam;


typedef struct {
    int width;
    int height;
    bool useExp;
    LensDataFormat pixelFmt;  
}LensDetectInitInfo;

typedef struct {
    double dayParams[8];
    double nightParams[8];
    int lumaMaxThreshold;
    int lumaMinThreshold;
    int useDefaultParams;
    int iso;
    int iso_min;
    int iso_max;
    int exptime;
    int exptime_min;
    int exptime_max;
    double ev;
    double score;
    int luma_trigger1;
    int luma_trigger2;
    int luma_trigger3;
    int luma_trigger4;
    float luma_trigger;
    int *feinfo;
    int fecount;
}LensExpDetectInfo;

typedef struct {
    int width;
    int height;
    int iso;
    int iso_min;
    int iso_max;
    int *feinfo;
    int fecount;
    int scene;
    int scene_case;
}LensDetectInfo;

typedef struct {
    const char* model_path;
}lensTTIQConfig;

typedef struct {
    unsigned char* data;
    int            width;
    int            height;
    int            stride;
    LensDataFormat pixel_fmt;
}lensTTIQParam;

typedef enum {
    LENS_TTIQ_SCENE_PURE = 0,
    LENS_TTIQ_SCENE_NATURAL
}lensTTIQScene;

typedef struct {
    lensTTIQScene scene_type;
    float         score;
}lensTTIQOutput;


typedef struct {
    const char* vrsrModelPath; //model path for alogrithm, vrsr5x5.model
    const char* skinSegModelPath; //model path for alogrithm, tt_skin_seg_v4.0.model
    int height;
    int width;
    int inputNum;   //only support 4 or 6 now
    LensDataFormat dataFormat; //only support nv21 now
    const char* modelBuffer;//reserve var，for model buffer input
    int modelSize;//reserve var，for model buffer input
}LensShootNightEnhanceConfigParam;

typedef enum {
    LENS_FRS_SIMPLE = 0,
    LENS_FRS_CUSTOME,
}LensFeRestorationMode;

typedef struct {
  float x;    ///< 矩形最左边的坐标
  float y;     ///< 矩形最上边的坐标
  float width;   ///< 矩形最右边的坐标
  float height;  ///< 矩形最下边的坐标
} LensFeBoundingbox; // fe bounding box

typedef struct {
  float points[10];// 5 pair points with x,y
} LensFeLandMark;  //fe landmark


typedef struct{
    const char* modlePath;
    bool upScale; // output maybe upscale when face is too small
    bool totalScore; // use total score model to confirm if need restoration
    float scoreThreshLow; // default is 0.1
    float scoreThreshHigh; // default is 0.98
    float scoreThreshModel; // default is 0.7
    bool deblur; // if need deblur before restoration
}LensFeRestorationConfig;

typedef struct {
    LensImage* image;
    LensFeRestorationMode mode;
    LensFeBoundingbox* boudingBoxs;
    LensFeLandMark* landmarks;
    int fe_num;
    bool gpuIO;
    bool gpuIn;
    bool gpuOut;
}LensFeRestorationInput;

typedef struct {
    LensImage restoredImage;
    LensImage* restoredFes;
    LensMatrix3* warpMatrixs;
    int fesCnt;
    int roiCnt;
}LensFeRestorationResult;
    
typedef enum {
    LENS_IMAGE_DENOISE_SIMPLE = 0,
    LENS_IMAGE_DENOISE_CUSTOME,
}LensImageDenoiseMode;

typedef struct{
    const char* modlePath;
    float vidaThreshLowDN;
    float vidaThreshHighDN;
    float vidaThreshLowSR;
    float vidaThreshHighSR;
    float vidaThreshLowFE;
    float vidaThreshHighFE;
}LensImageDenoiseConfig;

typedef struct {
    unsigned char *data;
    int width;
    int height;
    int stride;
    LensDataFormat pixel_fmt;
    LensImageDenoiseMode mode;
    float vidaScore;
    int postType; // 0 is sr, 1 is deblur
}LensImageDenoiseInput;

typedef struct{
    LensImage image;
    LensFeBoundingbox* boundingBoxs;
    LensFeLandMark* landmarks;
    int fe_num;
}LensImageDenoiseOutput;


/* >>> start define for Video HDR Lite */
typedef enum {
    HDR_TYPE_LITE_V5 = 0,       // HDR：性能效果平衡
    HDR_TYPE_LITE_V6 = 1,       // HDR：性能最好
    HDR_TYPE_LITE_V7 = 2,       // HDR：效果最好
    HDR_TYPE_LITE_V8 = 3,       // 色彩增强
    HDR_TYPE_UNKNOW,
} LensVideoHDRAlgType;
typedef struct {
    bool        isFirstFrame;               // 是否为视频第一帧标志
    bool        isDay;                      // 是否为白天场景
    bool        isProtectFace;              // 是否需要做人脸保护
    bool        isAFS;                      // 是否需要做自适应锐化
    int         luminanceTarget;            // 亮度阈值
    float       luminanceFactor;            // 亮度系数
    float       contrast;                   // 对比度参数
    float       saturation;                 // 饱和度参数
    int         faceNum;                    // 人脸数
    LENSRect*   faceList;                   // 人脸数据
    int         faceLuminanceTarget;        // 人脸亮度阈值
    float       faceLuminanceFactor;        // 人脸亮度阈值
    float       sharpenStrength;            // 锐化参数
    float       enhanceStrength;            // 增强系数
} LensVideoHDRLiteFrameInfo;

typedef struct {
    void* context;                          // 可以设置为NULL，iOS和mac可以传入MTLDevice，Windows可以传入D3D11Device
    const char* binPath;                    // Android和Windows传入可读写目录路径；iOS和mac传入vhdr.metallib文件路径
    bool  isExtOESTexture;                  // 是否为oes纹理
    int maxHeight;                          // 可支持最大输入帧的高
    int maxWidth;                           // 可支持最大输入帧的宽
    int perNum;                             // 每多少帧做一次曲线计算
    LensVideoHDRAlgType algType;            // 子算法类型
    LensDataFormat pixelFmt;                // 输入输出数据格式
    LensPowerLevel powerLevel;              // 性能模式
    LensBackendType backendType;            // backend设置
    const char* imgLutPath;                 // 原图lut映射表文件路径，只对HDR_TYPE_LITE_V8有效
    const char* skinLutPath;                // 肤色lut映射表文件路径，只对HDR_TYPE_LITE_V8有效
    bool isNeedSkinSeg;                     // 是否需要做肤色分割，国内版本不需要，海外版本需要，只对HDR_TYPE_LITE_V8有效
    bool isCover;                           // 是否使用兜底版本，只对HDR_TYPE_LITE_V8有效
} LensVideoHDRLiteConfig;

typedef struct {
    int  width;                             // 帧的宽
    int  height;                            // 帧的高
    bool open;                              // 动态开启/关闭算法
    int  textureId;                         // 输入纹理id
    float* stMatrix;                        // 如果是oes纹理,传入SurfaceTexture获取的纹理矩阵
    LensVideoHDRLiteFrameInfo* info;        // 帧信息
    void* skinSegPtr;                       // 传入肤色分割结果，cpu buffer地址，只对HDR_TYPE_LITE_V8有效
} LensVideoHDRLiteParam;
/* <<< end define for Video HDR Lite */
typedef enum {
    LENS_VIDA_MODE_FULL,
    LENS_VIDA_MODE_SIMPLE,
    LENS_VIDA_MODE_CUSTOMIZE,
}LensVIDAMode;

typedef struct {
    const char*  model_path;
    LensVIDAMode vida_mode;
    bool zenith_video_mode;
}lensVIDAConfig;

typedef struct {
    unsigned char* data;
    int            width;
    int            height;
    int            stride;
    LensDataFormat pixel_fmt;
    int            audio_length;
}lensVIDAParam;

typedef enum {
    kVIDA_MODE,  // val LensVIDAMode
    kVIDA_ALL_MODULE,
    kVIDA_SCORE_TOTAL,
    kVIDA_PURE_BACKGROUND,
    kVIDA_BLACK_EDGE,
    kVIDA_DAY_DETECT,
    kVIDA_EXPOSURE, // is
    kVIDA_DETAIL_SCORE,
    kVIDA_DETAIL_DETECT,
    kVIDA_NOISE,
    kVIDA_CHROMA,
    kVIDA_AESTHETICS,
    kVIDA_AESTHETICS2,
    kVIDA_MULTI_FRAME,
    kVIDA_SANDWICH,
    kVIDA_FACESCORE,
    kVIDA_BLURSCORE,
    kVIDA_AESTHETICS2_CPU,
    kVIDA_BLURSCORE_CPU,
    kVIDA_MEANINGSCORE,
    kVIDA_MULTIMODAL,
    kVIDA_SCORE_TOTAL_LITE,
    kVIDA_SCORE_TOTAL_DS, //dian shang scenario
    kVIDA_FULL_REFERENCE, //vida full reference
    kVIDA_ALL_ALGO_MODULE,
}LensVIDAConfigType;

typedef struct {
    LensVIDAConfigType paramType;
    int val; // 0 is close, 1 is open
}LensVIDAConfigParam;

typedef struct {
    //overall score
    float score_total;

    // For sandwitch detection
    int is_sandwitch_video;

    // For pure background detection
    int is_pure_background; // 0--not Pure backgraound; 1-- pure backgournd image

    // For day/night detection
    int is_night;  // 0--in day; 1--in night

    // For black-edge detection
    int has_black_edge; //0--doesn't have black edge; 1--has black edge

    // For lumimance assessment
    float score_luma; // overall luminace score
    float brightness; // global luminance assessment
    float under_exposure; // assessment of under-exposure
    float over_exposure;  // assessment of over-exposure
    float contrast; // assessment of contrast

    // For detail assessment
    float score_detail; // detail score
    float texture_detail; // texture
    float edge_detail; // edge

    // For noise assessment
    float noise_sigma;
    float brightness_weight_y;
    float brightness_weight_u;
    float brightness_weight_v;
    float movement_weight_y;
    float movement_weight_u;
    float movement_weight_v;

    // For chroma assessment
    float score_saturation; // saturation score
    float saturation; // satureation assessment
    float score_cast; //color-cast score
    float cast; // color-cast assessment

    // For aesthetics assessment
    float score_aesthetics; // aesthetics score
    float score_aesthetics_v2; // aesthetics score version 2
    float score_face; //face score
    float score_blur; // blur score.
    int sandwitch_top; // sandwitch detection, top coordinate
    int sandwitch_bottom; // sandwitch detection, bottom coordinate
    int sandwitch_left; // sandwitch detection, left coordinate
    int sandwitch_right; // sandwitch detection, right coordinate
    float score_aesthetics_v2_cpu; // aesthetics score version 2
    float score_blur_cpu; // blur score.
    float score_meaning;// content meaning score
    float multi_modal; // multi modal score v1, using video & audio
    float score_total_lite; // total score lite version
    float score_total_ds; // toatal score dianshang version
    char* full_reference_result; // full reference str return
}lensVIDAOutput;


#define LENS_COVER_MODULE_FACE_DETECT 0x00001
#define LENS_COVER_MODULE_QUALITY_ANALYSIS 0x00002
#define LENS_COVER_MODULE_SIMILAR_DETECT 0x000004


#define LENS_COVER_MAX_FACE_NUM 10
#define LENS_COVER_SIMILAR_FEATURE_SIZE 64


typedef struct {
  int left;    ///< 矩形最左边的坐标
  int top;     ///< 矩形最上边的坐标
  int right;   ///< 矩形最右边的坐标
  int bottom;  ///< 矩形最下边的坐标
} LensCoverRect;

typedef struct{
  float x;  ///< 点的水平方向坐标
  float y;  ///< 点的竖直方向坐标
} LensCoverPoint;



typedef struct {
  LensCoverRect rect;                // 代表面部的矩形区域
  float score;                // 置信度
  LensCoverPoint points_array[106];  // 人脸106关键点的数组
  float visible_array[106];  // 未实现，对应点的能见度,点未被遮挡1.0,被遮挡0.0
  float yaw;       // 水平转角,真实度量的左负右正
  float pitch;     // 俯仰角,真实度量的上负下正
  float roll;      // 旋转角,真实度量的左负右正
  float eye_dist;  // 两眼间距
  int id;          // faceID:
           // 每个检测到的人脸拥有唯一的faceID.人脸跟踪丢失以后重新被检测到,会有一个新的faceID
  unsigned int action;  // 动作信息，在对应的bit上存放对应的动作信息, 1
                        // 表示动作发生，0表示不发生
  unsigned int tracking_cnt;  // 脸跟踪的帧数，用于判断是否是新出现的人脸，以及新人脸触发动作等；
} LensCoverFaceInfo;

// 检测结果
typedef struct {
  LensCoverFaceInfo base_infos
      [LENS_COVER_MAX_FACE_NUM];  // 检测到的基本的人脸信息，包含106点、动作、姿态
  int face_count;  // 检测到的人脸数目
} LensCoverFaceDetectInfo;

typedef struct{
    const char* modlePath;
    unsigned int handle_config;
}LensVideoCoverModuleConfig;

typedef struct {
    unsigned char *data;
    int width;
    int height;
    int stride;
    LensDataFormat pixel_fmt;
}LensVideoCoverModuleInput;


typedef struct {
    LensCoverFaceDetectInfo face_info;
    float quality_score;
    float similar_feature[LENS_COVER_SIMILAR_FEATURE_SIZE];
}LensVideoCoverModuleOutput;

typedef struct {
    int luma_trigger1;
    int luma_trigger2;
    int luma_trigger3;
    int luma_trigger4;

    int nr_minThres;
    int nr_maxThres;
    int nr_thres;

    float luma_trigger;
    float contrast_trigger;
    float dynamic_trigger;
}LensCaptureDetectConfigParams;

typedef struct {
    int width;
    int height;
    int iso;
    int iso_min;
    int iso_max;
    int isNight; // 0 is night, 1 is highrange, 2 is lowrange
    int needNR; // 1 stands for need nr, 0 is not needed
    int useDefaultConfig;
    int cvdetectFrames; // default is 3
    LensCaptureDetectConfigParams  params;
    const char* algParamStream;
}LensCaptureDetectParams;

typedef struct {
    int maxHeight;
    int maxWidth;
    LensDataFormat dataFormat; //only support LENS_DATA_I420 now
    unsigned char* modelBuffer; //reserve for model update
    int modelSize;  // size of modelBuffer
    float thresh; //reserve for model update
    float scale; //1.5f or 2.0f;
}LensVrsrCudaConfigParam;


typedef struct {
    int width;
    int height;
    int strideW; //reserve
    int strideH; //reserve
    unsigned char*  data;
    int type; //reserve for gpu mem
}LensVrsrCudaDataParam;


/* >>> start define for Video Select Frame */
typedef enum {
    LENS_VSF_TYPE_LOW    = 0,
    LENS_VSF_TYPE_NORMAL = 1,
    LENS_VSF_TYPE_MIDDLE = 2,
    LENS_VSF_TYPE_HIGH   = 3,
    LENS_VSF_TYPE_COVER  = 4,
    LENS_VSF_TYPE_UNKNOW = 1000,
} LensVideoSelectFrameAlgType;

typedef struct {
    int mergeNum;
} LensVideoSelectFrameAlgParam;

typedef struct {
    void* context;
    const char* binPath;
    bool isExtOESTexture;
    int maxHeight;
    int maxWidth;
    LensVideoSelectFrameAlgParam algParam;
    LensVideoSelectFrameAlgType algType;
    LensDataFormat pixelFmt;
    LensPowerLevel powerLevel;
    LensBackendType backendType;
} LensVideoSelectFrameConfig;

typedef struct {
    int  width;     // 帧的宽
    int  height;    // 帧的高
    bool open;      // 动态开启/关闭算法
    bool isFirst;   // 帧信息
    int  inputTextureId; // 输入图像纹理id
    int  maskTextureId; // mask纹理id
    float* stMatrix;// 如果是oes纹理,传入SurfaceTexture获取的纹理矩阵
} LensVideoSelectFrameParam;
/* <<< end define for Video Select Frame */

/* config for smartcodec start*/
typedef enum  {
    CQHIGH,
    CQMIDDLE,
    CQLOW,
    FASTCQHIGH,
    FASTCQMIDDLE,
    FASTCQLOW,
    MIDDLECQHIGH,
    MIDDLECQMIDDLE,
    MIDDLECQLOW,
    SLOWCQHIGH,
    SLOWCQMIDDLE,     // FOR 臻视 VIDEO ENHANCE
    SLOWCQLOW
} LensCodecQuality;

typedef enum {
    NORMAL_,
    SMARTCODEC_V1_,
    SMARTCODEC_V2_,
    DeHDRBANDING_,
    SMARTCODEC_T4_,
    SMARTCODEC_T4_B_,
    COLLECTDATA_
} LensCodecAlgorithm;

typedef enum  {
    LenNVSmartCodecVersion,
    LenNVSmartCodecLogParam,
    LenNVSmartCodecInit,
    LenNVSmartCodecCollectInfo,
    LenNVSmartCodecReconfig
} LensCodecFunc;

typedef enum {
    SLOW = 0,
    MEDIUM,
    FAST,
} SmartCodecPreset; // 注意枚举各元素的顺序必须要与java SmartCodec.Preset定义的一致

typedef enum {
    UNKNOWN = 0,
    SURFACE_RGBA,
    BUFFER_YUV,
    BUFFER_RGBA
} SmartCodecInputMode; // 注意枚举各元素的顺序必须要与java SmartCodec.InputMode定义的一致

typedef struct {
    int frame_width;
    int frame_height;
    float fps_f;
    SmartCodecPreset preset;
    SmartCodecInputMode inputMode;

    const char* model_path;
    int model_size;
    const char* codec_engine;
    LensCodecQuality codec_quality;
    float default_cq;
    int fps;
    int orginalbitrate;
    const char* jsonSettings; //for param setting with key-value pair;
                              //v1:"codecParam={\"support_resolution\":[\"720P\",\"1080P\"],\"targetvmaf\":{\"720P\": 94,\"1080P\":94},\"ratelimit\":{\"720P\":{\"low\":0.7,\"high\":1.1},\"1080P\":{\"low\":0.7,\"high\":1.1}},\"speed\":{\"720P\":{\"frame_skip_video\":6,\"predict_interval\":6},\"1080P\":{\"frame_skip_video\":6,\"predict_interval\":6}},\"need_adjustrate\":{\"system\":[\"15.4.1\"],\"adjustratio\":1.5}}"
                              //v2:"codecParam={\"support_resolution\":[\"720P\",\"1080P\"],\"targetvmaf\":{\"720P\": 94,\"1080P\":94},\"ratelimit\":{\"720P\":{\"low\":0.7,\"high\":1.1},\"1080P\":{\"low\":0.7,\"high\":1.1}},\"speed\":{\"720P\":{\"frame_skip_video\":6,\"predict_interval\":6},\"1080P\":{\"frame_skip_video\":6,\"predict_interval\":6}},\"need_adjustrate\":{\"system\":[\"15.4.1\"],\"adjustratio\":1.0},\"filter\":{\"useType\":0,\"enhRatio\":1.1},\"enable_adjust\":1,\"pre_adjust_threshold\":1.5,\"pre_adjust_factor\":2,\"pre_adjust_framenum\":5,\"glcm_advanceframe\":0}"
    LensDataFormat pixelFmt; //LENS_DATA_BGRA8888, LENS_DATA_NV12
    float default_bitrate;
    bool  isExtOESTexture;
    const char* model_p_path;
    const char* statics_path;
} LensVideoSmartCodecConfig;
typedef struct
{
    int frametype; // 0 is I, 1 is B, 2 is P
    int framesize; // codec frame size in byte
    float ptstime;
}LensVideoSmartCodecFeature; // 码流特征

typedef struct {
    // NVSmartCodecCreate
    void* avctx;
    LensCodecAlgorithm algorithmType;
    float quality;

    // NVSmartCodecLogParam
    void*encode_params;
    //NVSmartCodecCollectInfo
    void* bs;
    //NVSmartCodecInit
    const char* model_path;
    const char* codec_infos_file_name;
    const char* codec_infos_file_name_total;
    LensCodecQuality quality_level;

    //NVSmartCodecReconfig
    const void *frame;
    void* resetPar;
    int *pNeeds_reconfig;
    int *pNeeds_encode_config;
} LensVideoSmartCodecConfigV2;

typedef struct {
    uint32_t width;
    uint32_t height;
    uint32_t fps;
    float ptstime;
    float target_quality;
    uint32_t i_count;
    float i_avg_size;
    float i_satd;
    float i_avg_qp;
    float i_interMBCount;
    float i_intraMBCount;
    uint32_t p_count;
    float p_avg_size;
    float p_satd;
    float p_avg_qp;
    float p_interMBCount;
    float p_intraMBCount;
    uint32_t b_count;
    float b_avg_size;
    float b_satd;
    float b_avg_qp;
    float b_interMBCount;
    float b_intraMBCount;

    LensCodecQuality codec_quality;
    float target_vmaf;
    float bitrate;
    float psnr;

    float scene_cut;
    float cq;

    int frame_id;
    LensVideoSmartCodecFeature * pre_codec_feature; // set to nullptr for first frame
    bool useI; //指导编码器是否插入I帧
    float averageComplexity; //平均复杂度/平均调节幅度，需要上报
    float maxComplexity; //最大幅度，需要上报
    float minComplexity; //最小幅度，需要上报
    bool needIFrame;
    float* stMatrix;
    int  textureId;//输入纹理id
    int featRunType;
    float encodedFrameSizeSum;
    int encodedFrameNum;
    int version;
} LensVideoSmartCodecParam;
/* config for smartcodec end*/

typedef enum {
    LENS_ALGO_SDR2HDR,
    LENS_ALGO_HDR2SDR,
    LENS_ALGO_SDR2HDR_INV,
    LENS_ALGO_HDR2SDR_INV,
}LENS_SDR2HDR_ALGO_TYPE;

typedef enum {
    SDR2HDR_SPACE_BT_601,
    SDR2HDR_SPACE_BT_709,
    SDR2HDR_SPACE_BT_2020,
}LENS_SDR2HDR_COLOR_SPACE;

typedef enum {
    SDR2HDR_PRIMARY_BT_709,
    SDR2HDR_PRIMARY_BT_601_NTSC,
    SDR2HDR_PRIMARY_BT_601_PAL,
    SDR2HDR_PRIMARY_BT_2020,
}LENS_SDR2HDR_COLOR_PRIMARY;

typedef enum {
    SDR2HDR_TRANSFER_BT_709,
    SDR2HDR_TRANSFER_BT_601_NTSC,
    SDR2HDR_TRANSFER_BT_601_PAL,
    SDR2HDR_TRANSFER_BT_2020_PQ,
    SDR2HDR_TRANSFER_BT_2020_HLG,
}LENS_SDR2HDR_COLOR_TRANSFER_FUNC;

typedef enum {
    SDR2HDR_BIT_8,
    SDR2HDR_BIT_10,
    SDR2HDR_BIT_12
}LENS_SDR2HDR_BIT_DEPTH;

typedef enum {
    SDR2HDR_FULL_RANGE,
    SDR2HDR_LIMITED_RANGE,
}LENS_SDR2HDR_COLOR_RANGE;


typedef enum {
    SDR2HDR_HLG,
    SDR2HDR_PQ,
}LENS_SDR2HDR_HDR_TYPE;


typedef enum {
    SDR2HDR_LINEAR,
    SDR2HDR_NON_LINEAR,
}LENS_SDR2HDR_VALUE_TYPE;


typedef struct {
    const char* binPath;
    bool  isExtOESTexture;
    int maxHeight;
    int maxWidth;
    LensPowerLevel perf;
    void* context;
    // video info
    int statisticsFreq;
    float surroundNit;
    int hdrPeakLuminance;
    LENS_SDR2HDR_VALUE_TYPE outValueType;
}LensSdr2hdrConfigParams;

typedef struct {
    bool open;
    void *data;
    int width;
    int height;
    LensDataFormat inDataFmt;
    bool isFirstFrame;
    LENS_SDR2HDR_BIT_DEPTH inBitDepth;
    LENS_SDR2HDR_COLOR_SPACE inColorSpace;
    LENS_SDR2HDR_COLOR_PRIMARY inColorPrimary;
    LENS_SDR2HDR_COLOR_SPACE inTransferFunc;
    LENS_SDR2HDR_COLOR_TRANSFER_FUNC inTransferFuncNew;
    LENS_SDR2HDR_COLOR_RANGE inColorRange;

    // for output config
    LensDataFormat outDataFmt;
    LENS_SDR2HDR_BIT_DEPTH outBitDepth;
    LENS_SDR2HDR_HDR_TYPE outHdrType;
    LENS_SDR2HDR_COLOR_SPACE outColorSpace;
    LENS_SDR2HDR_COLOR_PRIMARY outColorPrimary;
    LENS_SDR2HDR_COLOR_TRANSFER_FUNC outTransferFunc;
    LENS_SDR2HDR_COLOR_RANGE outColorRange;
    LENS_SDR2HDR_ALGO_TYPE algoType;

    void *reserved;
}LensSdr2hdrInParam;

typedef struct {
    void *data;
    int width;
    int height;
    LensDataFormat dataFmt;
    LENS_SDR2HDR_BIT_DEPTH bitDepth;
    void *reserved;
}LensSdr2hdrOutParam;



/* config for gcover start*/

typedef struct {
    int width;
    int height;
    int stride;
    unsigned char* data;
    LensDataFormat fmt;
}lens_gcover_image;

typedef struct{
    int width;
    int height;
    int stride;
    unsigned char* data;
    LensDataFormat fmt;
    unsigned char* saliency;
    int* text_bbox;
    int* main_text_bbox;
    float *compo_buffer;
    float *face_bbox;
    int* sandwich_bbox;
    int* obj_bbox;
    int face_num;
    int text_num;
    int main_text_num;
    int obj_num;
    int is_sandwich;
}lens_gcover_bbox;

typedef struct {
    const char* model_path;
    int mode;

}lensGCoverConfig;

typedef struct{
    int height;
    int width;
    int face_num;
    int text_num;
    int main_text_num;
    int obj_num;
    int is_sandwich;
    unsigned char* data;
    unsigned char* saliency;
    int* text_bbox;
    int* main_text_bbox;
    int* content_box;
    float *compo_buffer;
    float *face_bbox;
    int* sandwich_bbox;
    int* obj_bbox;
}lensGCOVEROutput;

typedef struct{
    int mode;
    int get_size;
}lensGCOVEROutputMode;
/* config for gcover end*/

/* config for fes track start*/
typedef enum  {
    OPENGL = 0,
    METAL,
} LensFesTrackGpuType;

typedef struct {
    int width;
    int height;
    int feinfo[40];
    int fecount;
    int framerate;
    const char *path;
    int input_texID; //for gl
    LensFesTrackGpuType gpuType;
    float paramConfig[5];
}LensRhythmicMotionParam;

#define NN_DENOISE_MODEL_MAX_SIZE 2048
typedef enum {
    LENS_VD_DENOISE_NN,
    LENS_VD_DENOISE_CV
}LensNNDenoiseAlgoType;
typedef enum {
    LENS_VD_FRAME_IN_NORMAL = 0,
    LENS_VD_FRAME_IN_END = 1,
    LENS_VD_FRAME_OUT_NONE = 2,
    LENS_VD_FRAME_OUT_ONE = 3,
    LENS_VD_FRAME_OUT_TWO = 4,
    LENS_VD_FRAME_RESET = 5,
}LensNNDenoiseFrameType;


typedef struct {
    const char* binPath;
    const char* modelPath;
    int height;
    int width;
    void* context;
    const char* runtimeLibPath;
    LensNNDenoiseAlgoType algoType;
}LensNNDenoiseConfigParams;

typedef struct {
    bool open;
    void *data;
    int width;
    int height;
    LensDataFormat format;
    LensNNDenoiseFrameType frameType;
    float strength;
    void *reserved;
}LensNNDenoiseInParam;

typedef struct {
    void *data;
    void *data1;
    int width;
    int height;
    LensDataFormat format;
    LensNNDenoiseFrameType frameType;
    void *reserved;
}LensNNDenoiseOutParam;

/* config for fes track end*/

/* config for old photo restoration start */
typedef struct {
    const char*  model_path;
    bool IF_DeScrach;
    bool IF_Face;
    bool IF_BackGroundEnhance;
    bool IF_Color;
}LensOldPhotoRestorationConfig;

typedef struct {
    unsigned char* data;
    int            width;
    int            height;
    int            stride;
    int            upscale;
    LensDataFormat pixel_fmt;
    int            if_color;      
}LensOldPhotoRestorationParam;
/* config for old photo restoration end */
/*config fro video bokeh shart*/
typedef enum{
    CIRCLE_SHAPE = 0,
    HEART_SHAPE,
    STAR_SHAPE,
    HEXAGON_SHAPE, //unsupport now
    CHRISTMASTREE_SHAPE  //unsupport now
} HighlightShape;

typedef enum{
    FocusClose = 0,
    FocusFace,  //unsupport for picture mode
    FocusUserDefine
} FocusMode;

typedef enum{
    StyleBiotar = 0,
    StyleDistagon,
    StylePlanar,
    StyleSonnar,
    StyleCream, //奶油
    StyleCatEye,  //椭圆
    StyleSporty, //动感
    StyleRotate,  //旋焦
    StyleBubble, //泡泡
    StyleHeart, //爱心
} BokehStyle;

typedef struct {
    const char* depthModelPath;//model path to depth est
    const char* mattingModelPath;//model path to matting
    const char* binPath;//path to write cache binary of algo kernel
    LensDataFormat modelDataFmt;//bytenn model data fmt, LENS_TEXTURE_RGB8 or LENS_TEXTURE_BGR8
    LensDataFormat dataFmt;//in and out data fmt, LENS_DATA_BGRA8888 or LENS_DATA_NV12 means BGRA pixelbuffer or nv12 pixelbuffer
    bool  isExtOESTexture; //reserved for android
    int maxHeight;
    int maxWidth;
    int maxDepthHeight;
    int maxDepthWidth;
    int modelHeight; //32对齐
    int modelWidth; //32对齐
    int blurDegree; //虚化程度，取值范围0-100
    FocusMode focusMode;//reserved, 对焦方式
    LENSCoor focusCoor;//reserved, 用户自定义对焦，传入虚化中心对焦点
    int  focusDecayFrames;//对焦过渡帧数
    HighlightShape highlightShape;//光斑形状
    const char* shapeModel;//reserved, 光斑模型
    void* context; //reserved, for shared context of gl, cl or metal
    int usingMatting;// set 1 to use matting, otherwise set 0 
    int usingByteNNModel;// set 1 to use bytenn model, otherwise use smash 
    int usingOpticalflow; //reserved, use opticalflow to smooth threshold for postprocessing 
    void *reserved;
}LensVideoBokehConfigParam;

typedef struct {
    bool isFirstFrame;
    void *inData;
    void *depth; //reserved, input depth mask
    void *outData;//should be in same format as inData, if set nullptr, return one created in algo engine
    int width;
    int height;
    int depthWidth;
    int depthHeight;
    int blurDegree; //虚化程度，取值范围0-100
    FocusMode focusMode;//reserved, 对焦方式
    LENSCoor focusCoor;//reserved, 用户自定义对焦，传入虚化中心对焦点
    HighlightShape highlightShape;//光斑形状
    int usingMatting;//set 1 to use matting, otherwise set 0
    int usingOpticalflow;//reserved, use opticalflow to smooth threshold for postprocessing
    BokehStyle bokehStyle;//reserved, bokeh style
    int faceNum;
    LENSRect *faceList;
    void *reserved;
}LensVideoBokehInParam;

typedef struct {
    void *data;
    int width;
    int height;
    void *depth;
    void *refineDepth;
    void *reserved;
}LensVideoBokehOutParam;
/*config for video bokeh end*/
/*config for picture bokeh start*/
typedef struct {
    const char* depthModelPath;//model path to depth est
    const char* mattingModelPath;//model path to matting
    const char* binPath;//path to write cache binary of algo kernel
    LensDataFormat modelDataFmt;//bytenn model data fmt, LENS_TEXTURE_RGB8 or LENS_TEXTURE_BGR8
    LensDataFormat dataFmt;//in and out data fmt, only support LENS_DATA_RGBA8888
    bool  isExtOESTexture; //reserved for android
    int maxHeight;
    int maxWidth;
    int maxDepthHeight;
    int maxDepthWidth;
    int modelHeight; //32对齐
    int modelWidth; //32对齐
    FocusMode focusMode;//对焦方式
    BokehStyle bokehStyle;//bokeh style虚化样式
    HighlightShape highlightShape;//光斑形状
    const char* shapeModel;//reserved, 光斑模型，后期下发光斑配置文件
    void* context; //reserved, for shared context of gl, cl or metal
    int usingMatting;//reserved, set 1 to use matting, otherwise set 0 
    int usingOpticalflow; //reserved, use opticalflow to smooth threshold for postprocessing 
    bool realInit; //目前只在Android平台适用，初始化探测flag，为true表示正式调用初始化，为false表示判断当前机型是否支持，不做正式初始化
    void *reserved;
}LensPictureBokehConfigParam;

typedef struct {
    void *inData; // input gl texture id
    void *depth; //reserved, input depth mask 
    void *outDepth;//output depth mask
    void *outData;//output gl texture id, should be in same format as inData, if set nullptr, return inData and overwrite
    bool reuseDepthResult;
    int width;
    int height;
    int depthWidth;
    int depthHeight;
    int blurDegree; //虚化程度，取值范围0-100
    FocusMode focusMode;//对焦方式
    LENSCoor focusCoor;//用户自定义对焦，传入虚化中心对焦点，图像y,x坐标值
    BokehStyle bokehStyle;//bokeh style虚化样式
    HighlightShape highlightShape;//光斑形状，只有在StyleCream奶油样式下支持调节
    bool useMask;
    void *reserved;
}LensPictureBokehInParam;

/*config fro picture bokeh end*/

/* >>> start define for Video Motion Blur */
typedef enum {
    LENS_VMB_ALG_COVER          = 0,        // 兜底
    LENS_VMB_ALG_DIS_ONCE       = 1,        // 光流迭代一次
    LENS_VMB_ALG_DIS_TWICE      = 2,        // 光流迭代两次
    LENS_VMB_ALG_UNKNOW         = 1000,
} LensVideoMotionBlurAlgType;

typedef enum {
    LENS_VMB_MERGE_BILATERAL    = 0,        // 双向融合
    LENS_VMB_MERGE_LEAD         = 1,        // 前导融合
    LENS_VMB_MERGE_TRAIL        = 2,        // 拖影融合
    LENS_VMB_MERGE_UNKNOW       = 1000,
} LensVideoMotionBlurMergeType;

typedef struct {
    void* context;                          // 可以设置为NULL，iOS和mac可以传入MTLDevice
    const char* binPath;                    // Android和Windows传入可读写目录路径；iOS和mac传入vmb.metallib文件路径
    bool isExtOESTexture;                   // 是否为oes纹理
    int maxHeight;                          // 可支持最大输入帧的高
    int maxWidth;                           // 可支持最大输入帧的宽
    LensDataFormat pixelFmt;                // 输入数据格式
    LensPowerLevel powerLevel;              // 性能模式
    LensBackendType backendType;            // backend设置
    LensVideoMotionBlurAlgType algType;     // motionblur算法类型
    LensVideoMotionBlurMergeType mergeType; // 融合类型
    float scaleX;                           // 控制光流法处理大小X的缩小倍数，范围是[3.0,4.0]，推荐为3，用于平衡效果和性能，值越小效果越好
    float scaleY;                           // 控制光流法处理大小Y的缩小倍数，范围是[3.0,4.0]，推荐为3，用于平衡效果和性能，值越小效果越好
    int sampleNum;                          // 控制光流法采样次数，范围是[25,50]，推荐为50，用于平衡效果的性能，值越大效果越好
} LensVideoMotionBlurConfig;

typedef struct {
    int  width;             // 帧的宽
    int  height;            // 帧的高
    int  strideW;           // 帧x方向的stride值
    int  strideH;           // 帧y方向的stride值
    bool open;              // 动态开启/关闭算法
    int  inputTextureId;    // 输入帧纹理id
    bool isFirst;           // 是否为视频第一帧标志
    bool isMerge;           // 是否需要做融合操作
    bool isRandomSlide;     // 转场时是否使用替换帧
    float blurLevel;        // 模糊程度，数值越高效果越模糊，范围是[0,100]
    float mergeLevel;       // 融合程度，数值越高重影越大，范围是[0, 100]
    float* stMatrix;        // 如果是oes纹理,传入SurfaceTexture获取的纹理矩阵
} LensVideoMotionBlurParam;
/* <<< end define for Video Motion Blur */

/* config for vida mobile model start */
typedef enum{
    LENS_VIDAModelFACE,
    LENS_VIDAModelAES,
    LENS_VIDAModelSimilar,
    LENS_VIDAModelCoherence,
    LENS_VIDAModelClarity
} LensVIDAModelRunType;

typedef struct {
    const char* modelPath;
    const char* KernelBinPath;
    LensVIDAModelRunType runtype;
    LensBackendType backendType; //default LensBackendType::LENS_BACKEND_CPU;
    int numThread; //only make sense when backendType is CPU, default set 2
    float alpha;  // only for clarity model
    float beta;     // only for clarity model
    const char* tempDirPath;
} LensVIDAModelParam;

typedef struct {
    void *inBuffer; // only support uchar* rgbaBuffer
    int width;
    int height;
} LensVIDAModelBuffer;

typedef struct {
    void *inBuffer1; // only support uchar* rgbaBuffer
    int width1;
    int height1;
    void *inBuffer2; // only support uchar* rgbaBuffer
    int width2;
    int height2;
    float cnn_score;
} LensVIDAModelCoherenceBuffer;
/* config for vida mobile model start */

/* config for shake detect start */
typedef enum{
    LENS_SHAKE_DETECT_ROTATION_VECTOR, //
    LENS_SHAKE_DETECT_QUATERNION,        // w,x,y,z
    LENS_SHAKE_DETECT_ROTATION_MATRIX // only support rotation matrix now.
} LensShakeDetectionInputParamType;

typedef struct{
    int buffer_size;
    LensShakeDetectionInputParamType rotType_;
} LensShakeDetectionInitParam;

typedef struct{
    float* input; // x00, x01, ..., x22
} LensShakeDetectionBuffer;
/* config for shake detect start */

/* >>> start define for Video Deflicker */
typedef enum {
    LENS_DEFLICKER_ALG_DELAY          = 0,        // 延时模式
    LENS_DEFLICKER_ALG_FLASH          = 1,        // 荧光灯模式
    LENS_DEFLICKER_ALG_UNKNOW         = 1000,
} LensVideoDeflickerAlgType;

typedef struct {
    void* context;                          // 可以设置为NULL，iOS和mac可以传入MTLDevice
    const char* binPath;                    // Android和Windows传入可读写目录路径；iOS和mac传入deflicker.metallib文件路径
    bool isExtOESTexture;                   // 是否为oes纹理
    int maxHeight;                          // 可支持最大输入帧的高
    int maxWidth;                           // 可支持最大输入帧的宽
    LensDataFormat pixelFmt;                // 输入数据格式
    LensPowerLevel powerLevel;              // 性能模式
    LensBackendType backendType;            // backend设置
    LensVideoDeflickerAlgType algType;      // 去频闪模式
} LensVideoDeflickerConfig;

typedef struct {
    int  width;             // 帧的宽
    int  height;            // 帧的高
    int  strideW;           // 帧x方向的stride值
    int  strideH;           // 帧y方向的stride值
    bool open;              // 动态开启/关闭算法
    int  inputTextureId;    // 输入帧纹理id
    bool isFirst;           // 是否为视频第一帧标志
    float blendRate;        // 算法参数1，由客户端传入
    float kernelSize;       // 算法参数2，由客户端传入
    float* stMatrix;        // 如果是oes纹理,传入SurfaceTexture获取的纹理矩阵
} LensVideoDeflickerParam;
/* <<< end define for Video Deflicker */

typedef struct{
    const char* modlePath;
    float vidaThresh;
    float alpha;
}LensImageNNHdrConfigParam;

typedef struct {
    LensImage image;
    float score;
}LensImageNNHdrInput;;

/* >>> start define for Cinematic Movement */
typedef struct {
    void* context;                          // 可以设置为NULL，iOS和mac可以传入MTLDevice，Windows可以传入D3D11Device
    const char* kernelPath;                 // Android和Windows传入可读写目录路径；iOS和mac传入cinemove.metallib文件路径
    const char* resourcePath;               // 传入资源包路径，设置为NULL时，会转为使用下面的jsonString
    const char* jsonString;                 // 传入lens.json对应的字符串
    bool isExtOESTexture;                   // 是否为oes纹理
    int maxHeight;                          // 可支持最大输入帧的高
    int maxWidth;                           // 可支持最大输入帧的宽
    int fps;                                // 视频帧率
    LensDataFormat pixelFmt;                // 输入数据格式
    LensPowerLevel powerLevel;              // 性能模式
} LensCineMoveConfig;

typedef enum {
    LENS_CINE_MOVE_FEATURE_FACE_RECT = 0,   // 人脸框
    LENS_CINE_MOVE_FEATURE_BODY_RECT,       // 人体框
    LENS_CINE_MOVE_FEATURE_FACE_POINT,      // 人脸特征点
    LENS_CINE_MOVE_FEATURE_BODY_POINT,      // 人体特征点
    LENS_CINE_MOVE_FEATURE_MOTION_POINT,    // 运动特征点
    LENS_CINE_MOVE_FEATURE_OBJECT_POINT,    // 物体特征点
} LensCineMoveFeatureType;

typedef struct {
    LensCineMoveFeatureType featureType;
    float* featureList;
    int featureCount;
} LensCineMoveFeature;

typedef struct {
    int  width;                     // 帧的宽
    int  height;                    // 帧的高
    int  strideW;                   // 帧x方向的stride值
    int  strideH;                   // 帧y方向的stride值
    bool open;                      // 动态开启/关闭算法
    bool isFirst;                   // 是否为视频第一帧标志
    float* stMatrix;                // 如果是oes纹理,传入SurfaceTexture获取的纹理矩阵
    LensCineMoveFeature* feature;   // 特征list
    int featureCount;               // 特征数量
    const char* algExecStream;      // 算法运行时参数字符流
} LensCineMoveParam;

typedef enum {
    LENS_CINE_MOVE_OUT_FRAME = 0,   // 输出数据类型为帧
    LENS_CINE_MOVE_OUT_MATRIX,      // 输出数据类型为3x3 warp矩阵, float类型
} LensCineMoveOutputType;

typedef struct {
    LensCineMoveOutputType cmType;  // 算法输出数据类型
    void* cmParamList;              // 算法输出数据指针，设置为NULL则Lens内部申请内存，非NULL则直接往里填数据
    int cmParamNum;                 // 算法输出数据个数
} LensCineMoveOutput;
/* <<< end define for Cinematic Movement */

/* start for pic smart codec algo */
typedef struct {
    const char* modelPath;
    bool  isExtOESTexture;
    const char* jsonParams;
}LensPicSmartCodecInitParam;

typedef struct {
    uint8_t* data;
    int height, width;
    int quality;
    float firstSsim;
    unsigned int predict_y_qtable[64];   // for future extension
    unsigned int predict_uv_qtable[64];
} LensPicSmartCodecAdaJpegResult;

typedef struct {
    uint8_t* rawData;
    int height;
    int width;
    LensPicSmartCodecAdaJpegResult result;
    int outputTexture;
    LensDataFormat dataformat;
} LensPicSmartCodecAdaParam;
/* end for pic smart codec algo */

/* >>> start define for Video Relit */
typedef struct {
    void* context;                          // 可以设置为NULL，iOS和mac可以传入MTLDevice
    const char* binPath;                    // Android和Windows传入可读写目录路径；iOS和mac传入vrl.metallib文件路径
    const char* resourcePath;               // 传入资源包路径
    bool isExtOESTexture;                   // 是否为oes纹理
    int maxHeight;                          // 可支持最大输入帧的高
    int maxWidth;                           // 可支持最大输入帧的宽
    int mattingModelW;                      // 分割模型输出的宽
    int mattingModelH;                      // 分割模型输出的高
    LensDataFormat pixelFmt;                // 输入数据格式
    LensPowerLevel powerLevel;              // 性能模式
    int sceneNormalModelW;                  // 法向模型输出的宽
    int sceneNormalModelH;                  // 法向模型输出的高
    const char* depthModelPath;             // 深度模型文件路径
} LensVideoRelitConfig;

typedef struct {
    int  width;                             // 帧的宽
    int  height;                            // 帧的高
    int  strideW;                           // 帧x方向的stride值
    int  strideH;                           // 帧y方向的stride值
    bool open;                              // 动态开启/关闭算法
    bool isFirst;                           // 是否为视频第一帧标志
    float* stMatrix;                        // 如果是oes纹理,传入SurfaceTexture获取的纹理矩阵
    const char* algExecStream;              // 算法运行时参数字符流
    int faceNum;                            // 人脸个数
    LENSRect *faceList;                     // 人脸框信息数组
} LensVideoRelitParam;
/* <<< end define for Video Relit */

/* >>> start define for camera lock */
typedef struct {
    const char* resourcePath;               // 传入资源包路径
    int maxMemoryFrame;                     // 目标丢失后最大保持的帧数
    int inverseSearchFrame;                 // 反向搜索的最大帧数
    const char* cacheInfo;                  // 算法缓存信息json
} LensCameraLockConfig;

typedef enum {
    LENS_CAM_LOCK_FACE,  // 锁定人脸
    LENS_CAM_LOCK_BODY, // 锁定人体
    LENS_CAM_LOCK_LEFT_HAND, // 锁定左手
    LENS_CAM_LOCK_RIGHT_HAND  // 锁定右手
}LensCameraLockObjType;

typedef enum {
    LENS_CAM_LOCK_FACE_RECT = 0,   // 人脸框 left, top, right, bottom,
    LENS_CAM_LOCK_BODY_RECT,       // 人体框 left, top, right, bottom
    LENS_CAM_LOCK_FACE_POINT,      // 人脸特征点 x, y, size = 106
    LENS_CAM_LOCK_BODY_POINT,      // 人体特征点 x, y, size = 36
    LENS_CAM_LOCK_OBJ_RECT,        //  锁定框信息 left, top, right, bottom
    LENS_CAM_LOCK_OBJ_CROP_INFO,   //  裁切框框信息+锁定目标框, 13个float, position, scale, rotation, rect
    LENS_CAM_LOCK_HOMO_MATRIX,     //  homography x00,x01,x02, x10,x11,x12, x20,x21,x22
} LensCameraLockFeatureType;

typedef enum {
    LENS_CAM_LOCK_CHOOSE_SUBJECT,
    LENS_CAM_LOCK_LOCKING,
    LENS_CAM_LOCK_REVERSE_SEARCH
}LensCameraLockStep;

typedef enum {
    LENS_CAM_LOCK_STATE_NORMAL,
    LENS_CAM_LOCK_STATE_BRIEF_DISAPPEAR, // 目标短暂消失，重新出现导致的待选择状态
    LENS_CAM_LOCK_STATE_OVERLAP,         // 目标交叠重新进行选择
    LENS_CAM_LOCK_STATE_DISAPPEAR,       // 目标消失停止锁定
}LensCameraLockState;

typedef struct {
    LensCameraLockFeatureType featureType;
    float* featureList;
    int featureCount;
    long long int frameIndex;   // pts
} LensCameraLockFeature;

typedef struct {
    bool delBlackBorder;        // 是否去除黑边
    bool fixedAreaFactor;       // 是否固定面积占比
    float enableRotation;       // 旋转强度，0 - 1, 0 表示关闭
    float shiftThresh;          // 平移过滤阈值,0表示不做过滤，-1 表示算法内部自适应过滤
    float scaleThresh;          // 缩放过滤阈值,0表示不做过滤，-1 表示算法内部自适应过滤
    float rotateThresh;         // 旋转过滤阈值,0表示不做过滤，-1 表示算法内部自适应过滤
} LensCameraLockProperty;

typedef struct {
    int  width;                     // 帧的宽
    int  height;                    // 帧的高
    int  strideW;                   // 帧x方向的stride值
    int  strideH;                   // 帧y方向的stride值
    LensDataFormat pixelFmt;        // 输入数据格式
    bool open;                      // 动态开启/关闭算法
    bool isFirst;                   // 是否为视频第一帧标志
    LensCameraLockFeature* features;   // 输入特征list
    int featuresCount;               // 输入特征数量
    LensCameraLockObjType lockObj;   // 选择锁定的部位
    LensCameraLockFeature userLockedRect; // 用户选择的锁定部位框，反向搜索时使用
    int objectId;                    // 用户选择的目标id，如果用户没有选则设为-1
    LensCameraLockStep    step;      // 算法执行步骤，不同步骤匹配不同的输入参数
    const char* algExecStream;       // 算法运行时参数字符流，预留
} LensCameraLockParam;

typedef enum {
    LENS_CAM_LOCK_OUT_OBJ_RECT,  // 获取锁定主体框，输出为, 每帧获取一次
    LENS_CAM_LOCK_OUT_PREVIEW,   // 获取预览结果， 每帧获取一次
    LENS_CAM_LOCK_OUT_FINAL,     // 获取完整的锁定结果，所有帧执行完成后获取
    LENS_CAM_LOCK_OUT_REVERSE,     // 获取完整的锁定结果，所有帧执行完成后获取
}LensCameraLockOutputType;

typedef struct {
    LensCameraLockOutputType outputType;  // 输出类型
    LensCameraLockFeature* outputFeatures; // 输出特征信息
    int featureCount;                     // 输出特征数量
    LensCameraLockState  lockState;        // 当前锁定状态
    char* cacheInfo;                       // 输出算法缓存的json信息
    int cacheSize;                         // 算法缓存的json长度
}LensCameraLockOutput;

/* <<< end define for camera locking */

typedef enum {
    WM_EMBED = 0,
    WM_EXTRACT,
    WM_UNDEFINED
} WmWorkMode;

typedef struct {
    const char *binPath;
    bool isExtOESTexture;
    LensDataFormat pixelFmt;
    int height;
    int width;
    WmWorkMode workMode;
    const char* wmStrEmbed;
    int lenWmStr;
    void *reserved;
    const char *modelPath;
    int pFlag;
    int memFlag;
    const char *modelPathSec;
} LensWatermarkConfigParam;

typedef struct {
    void *inData;
    void *outData;
    LensCode retStatus;
    char** wmStrExtract;
    int lenWmStr;
    int numWmStr;
    void *reserved;
    int height;
    int width;
    LensDataFormat pixelFmt;
}LensWatermarkInParam;

/* start for video zenith vision algo */

typedef struct {
  float x;    ///< 矩形最左边的坐标
  float y;     ///< 矩形最上边的坐标
  float width;   ///< 矩形最右边的坐标
  float height;  ///< 矩形最下边的坐标
} FeBoundingbox; // fe bounding box

typedef struct {
  float points[10];// 5 pair points with x,y
} FeLandMark;  //fe landmark

/* start for fe_ recognition algo */
typedef struct {
    const char* modelDir;// model dir for models, fe_detect, fe_feature_extract, fe_score 
    int maxHeight;
    int maxWidth;
    int feFilterBigFePtsThreshWidth;//大人脸区域的像素大小阈值 540 * 960
    int feFilterBigFePtsThreshHeight; 
    float feFilterBigFeRatioThresh; //大人脸区域的图像占比阈值 0.8
    int feFilterLowQuatFeMosiacPtsThresh;//低质人脸区域马赛克像素阈值 10
    float feFilterLowQuatFeScoreThresh;//低质人脸分数阈值 0.01
    int feRestoreMaxFeNum;//调节单帧图像中可修复人脸的最大个数 5
    int feRestoreFrameWindowSize;//判断当前帧人像是否修复-所需的图像连续帧滑窗大小 8 
    float feRestoreFeLowScoreThresh;//判断当前帧人像是否修复-所需的人像最低分数阈值 0.04
    float feRestoreFeHighScoreThresh;//判断当前帧人像是否修复-所需的人像最高分数阈值 0.95
    int totalFrames; //当前视频总帧数
}LensVideoZenithFeRecognitionInitParam;

typedef struct {
    int frameIdx;
    LensImage* image; //data should be in BGR HWC format
    bool processLastFrame;
    bool gpuIO;
}LensVideoZenithFeRecognitionInput;

typedef struct {
    int frameIdx; 
    int feCnt;
    FeBoundingbox *feBoudingBox;
    int boudingBoxDataLength;
    FeLandMark *feLandMark;
    int feLandMarkLength;
    bool lastFrame; //true means to get last frame result for a video
}LensVideoZenithFeRecognitionResult;

/* end for fe_ recognition algo */

/* start for fe_ restoration algo */
typedef struct {
    const char* modelDir;// model dir for models, fe_restoration
    float feRestoreRatio;//fe restore ratio 0.8
    bool feRestoreVersion;//true means ch version, false means outside version
}LensVideoZenithFeRestorationInitParam;

typedef struct {
    LensVideoZenithFeRecognitionResult *feInfo; //fe info from fe recognition
    int vidaScore; //video vida score
    LensImage* image; //data should be in BGR HWC format
    bool gpuIO;
}LensVideoZenithRestorationInput;

typedef struct {
    int feCnt;
    int roiCnt;
    LensImage* restoredFesDiff;
    LensMatrix3* warpMatrixs;
}LensVideoZenithFeRestorationResult;
/* end for fe_ restoration algo */
/* end for video zenith vision algo */

/* start for undistortion algo */
typedef enum {
    DISTORTION_TYPE_FISHEYE,
    DISTORTION_TYPE_ORDINARY,
}LensCameraUndistortionType;
typedef struct {
    float intrinsic[9]; // intrinsic matrix [fx 0 cx; 0 fy cy; 0 0 1]
    float coeff[5]; // distortion coefficients [k1 k2 k3 k4] or [k1 k2 p1 p2 k3]
    LensCameraUndistortionType type;
    const char* binPath; //传入可读写路径
    bool isExtOESTexture;
}LensCameraUndistortionConfig;

typedef struct {
    void *inData;
    void *outData; // deprecated
    int width;
    int height;
    LensDataFormat pixel_fmt;
    bool open;
    float* stMatrix;  //如果是oes纹理,传入SurfaceTexture获取的纹理矩阵
    void *reserved;
}LensCameraUndistortionParm;

#ifdef __cplusplus
} // extern "C"
#endif

#endif //_LENS_BASIC_TYPE_H_
