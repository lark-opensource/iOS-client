#ifndef FASTCV_MAT_H
#define FASTCV_MAT_H

#include <stddef.h>
#include <atomic>
#include "types.hpp"
#include <utility>

namespace FASTCV {
namespace EXPORTS {

enum DecompTypes {
    DECOMP_LU       = 0,
    DECOMP_SVD      = 1,
    DECOMP_EIG      = 2,
    DECOMP_CHOLESKY = 3,
    DECOMP_QR       = 4,
    DECOMP_NORMAL   = 16
};

struct CV_EXPORTS MatStep {
    MatStep();
    explicit MatStep(size_t s);
    const size_t& operator[](int i) const;
    size_t& operator[](int i);
    operator size_t() const;
    MatStep& operator = (size_t s);

    size_t* p;
    size_t buf[2];
protected:
    MatStep& operator = (const MatStep&);
};

class UMat;

class CV_EXPORTS Mat {
public:
    Mat();
    Mat(const Mat& m);
    Mat(int rows, int cols, int type, void* data = nullptr);
    Mat(Mat&& m);
    Mat(const Mat& m, const Rect& roi);
    Mat& operator = (Mat&& m);
    Mat& operator = (const Mat& m);

    void AllocateLike(const Mat &m);
    void convertTo(Mat &m, int rtype, double alpha=1, double beta=0) const;

    int type() const;
    int depth() const;
    int channels() const;
    bool empty() const;
    size_t total() const;
    size_t elemSize() const;
    size_t elemSize1() const;
    // uchar* ptr(int i0=0);
    /** @overload */
    void* ptr(int i0=0) const;
    void* ptr(int row, int col);
    // template<typename _Tp> _Tp* ptr(int i0=0);
    // template<typename _Tp> _Tp* ptr(int row, int col);
    // template<typename _Tp> _Tp& at(int i0=0);
    // template<typename _Tp> _Tp& at(int row, int col);
    
    Mat operator+(const Mat &m);
    Mat operator-(const Mat &m);
    Mat operator*(const Mat &m);

    friend Mat operator+(const Mat &m1, const Mat &m2);
    friend Mat operator-(const Mat &m1, const Mat &m2);
    friend Mat operator*(const Mat &m1, const Mat &m2);

    explicit Mat(const UMat& m);

    //Mat operator()( const Rect& roi ) const;

    Mat inv(int method = DECOMP_LU) const;

    static Mat zeros(int rows, int cols, int type);

    static Mat ones(int rows, int cols, int type);

    ~Mat();
    Mat(int rows, int cols, int type, int stride, void* data = nullptr);
public:
    int dims_;
    int rows_, cols_;
    int type_;
    MatStep step_;
    void* internal_; // for internal use, you can use ptr() to stands for it. 
};

enum UMatUsageFlags {
    USAGE_DEFAULT = -1,
    USAGE_ALLOCATE_SHARED_MEMORY = 0, 
    USAGE_ALLOCATE_DEVICE_MEMORY,
    USAGE_ALLOCATE_SHARED_MEMORY_CVBUF,
};

enum AccessFlag { 
    ACCESS_READ= 1<<24, 
    ACCESS_WRITE= 1<<25,
    ACCESS_RW= 3<<24, 
    ACCESS_MASK= ACCESS_RW, 
    ACCESS_FAST= 1<<26 
};

struct OpSupportBits {
    unsigned int cls;
    unsigned long long flags;
    void* reserved;
};

struct GPUContext {
    void *context;
    void *cmdQueue;
    void *internal;
    FASTCVGPUBackend gpuType;
    OpSupportBits opConfig;
    bool autoSync;
    const char *path;
    void *ext;
};

enum NNDeviceIOType {
    GL_TEX = 0,
    CL_IMG = 1,
    CL_BUF,
    MTL_TEX,
};

class CV_EXPORTS UMat {
public:
#ifdef __APPLE__
    UMat(int rows, int cols, int type, GPUContext *context, void *pdata = nullptr, UMatUsageFlags usageFlags = USAGE_ALLOCATE_DEVICE_MEMORY, NNDeviceIOType ioType = MTL_TEX);
#else
    UMat(int rows, int cols, int type, GPUContext *context, void *pdata = nullptr, UMatUsageFlags usageFlags = USAGE_ALLOCATE_DEVICE_MEMORY, NNDeviceIOType ioType = CL_IMG);
#endif
    UMat(const UMat& m);
    UMat(UMat&& m);
#ifdef __APPLE__
    UMat(Mat &m, GPUContext *context, NNDeviceIOType ioType = MTL_TEX);
#else
    UMat(Mat &m, GPUContext *context, NNDeviceIOType ioType = CL_IMG);
#endif
    UMat(const UMat& m, const Rect& roi);
    UMat& operator = (UMat&& m);

    ~UMat();
    UMat& operator = (const UMat& m);
    void AllocateLike(const UMat &m);
    
    void convertTo(UMat &m, int rtype, double alpha=1, double beta=0 ) const;
    
    void getMat(Mat &m);

    void *getGPUmem();

    /**
     * if no ops used and only use gl_cl_share feature, when texture update, please using this api.
    */
    void syncFromSharedMem();

    void syncToSharedMem();
    
    void copyMat(const Mat &m);
    
    void copyUMat(const UMat& m, const Rect& roi);
    
    NNDeviceIOType getDeviceIOType();

    GPUContext *getGPUContext() const;

    UMat operator+(const UMat &m);
    UMat operator-(const UMat &m);
    UMat operator*(const UMat &m);

    friend UMat operator+(const UMat &m1, const UMat &m2);
    friend UMat operator-(const UMat &m1, const UMat &m2);
    friend UMat operator*(const UMat &m1, const UMat &m2);

    int type() const;
    int depth() const;
    int channels() const;
    size_t elemSize() const;
    size_t elemSize1() const;
    bool empty() const;
    size_t total() const;
    void getTexID(void* texID) const;  //for gl only
    //UMat operator()( const Rect& roi ) const;

    void syncFromTexID(void* texID); //for gl only
    void syncToTexID(void* texID);   //for gl only

    void LockMemObject();
    void UnlockMemObject();
private:
    GPUContext *context_;
public:
    int dims_;
    int rows_, cols_;
    int type_;
    int flags_;
    bool autoSync_;
    MatStep step_;
    NNDeviceIOType ioType_;
    void* internal_;
};

}
}
#endif
