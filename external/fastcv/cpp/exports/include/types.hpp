#ifndef FASTCV_TYPES_HPP
#define FASTCV_TYPES_HPP

#include <algorithm>
#include <limits.h>
#include <float.h>
#ifdef _WIN32
#include <functional>
#endif

#ifndef CV_EXPORTS
# if (defined WIN32 || defined _WIN64 || defined WINCE || defined __CYGWIN__) 
#   define CV_EXPORTS __declspec(dllexport)
# else
#   define CV_EXPORTS __attribute__ ((visibility ("default")))
# endif
#endif

namespace FASTCV {
namespace EXPORTS {
typedef unsigned char uchar;
typedef signed   char schar;

typedef unsigned short ushort;

typedef void (*fastcv_generic_proc)();
typedef fastcv_generic_proc (*fastcv_get_proc_func)(const char*);

template<typename _Tp, typename _Tp_src> static inline _Tp saturate_cast(_Tp_src v)  { return _Tp(v); }

#define CV_CN_MAX     512
#define CV_CN_SHIFT   3
#define CV_DEPTH_MAX  (1 << CV_CN_SHIFT)

#define CV_8U   0
#define CV_8S   1
#define CV_16U  2
#define CV_16S  3
#define CV_32S  4
#define CV_32F  5
#define CV_64F  6
#define CV_16F  7

#define CV_MAT_DEPTH_MASK       (CV_DEPTH_MAX - 1)
#define CV_MAT_DEPTH(flags)     ((flags) & CV_MAT_DEPTH_MASK)

#define CV_MAKETYPE(depth,cn) (CV_MAT_DEPTH(depth) + (((cn)-1) << CV_CN_SHIFT))
#define CV_MAKE_TYPE CV_MAKETYPE

#define CV_8UC1 CV_MAKETYPE(CV_8U,1)
#define CV_8UC2 CV_MAKETYPE(CV_8U,2)
#define CV_8UC3 CV_MAKETYPE(CV_8U,3)
#define CV_8UC4 CV_MAKETYPE(CV_8U,4)
#define CV_8UC(n) CV_MAKETYPE(CV_8U,(n))

#define CV_8SC1 CV_MAKETYPE(CV_8S,1)
#define CV_8SC2 CV_MAKETYPE(CV_8S,2)
#define CV_8SC3 CV_MAKETYPE(CV_8S,3)
#define CV_8SC4 CV_MAKETYPE(CV_8S,4)
#define CV_8SC(n) CV_MAKETYPE(CV_8S,(n))

#define CV_16UC1 CV_MAKETYPE(CV_16U,1)
#define CV_16UC2 CV_MAKETYPE(CV_16U,2)
#define CV_16UC3 CV_MAKETYPE(CV_16U,3)
#define CV_16UC4 CV_MAKETYPE(CV_16U,4)
#define CV_16UC(n) CV_MAKETYPE(CV_16U,(n))

#define CV_16SC1 CV_MAKETYPE(CV_16S,1)
#define CV_16SC2 CV_MAKETYPE(CV_16S,2)
#define CV_16SC3 CV_MAKETYPE(CV_16S,3)
#define CV_16SC4 CV_MAKETYPE(CV_16S,4)
#define CV_16SC(n) CV_MAKETYPE(CV_16S,(n))

#define CV_32SC1 CV_MAKETYPE(CV_32S,1)
#define CV_32SC2 CV_MAKETYPE(CV_32S,2)
#define CV_32SC3 CV_MAKETYPE(CV_32S,3)
#define CV_32SC4 CV_MAKETYPE(CV_32S,4)
#define CV_32SC(n) CV_MAKETYPE(CV_32S,(n))

#define CV_32FC1 CV_MAKETYPE(CV_32F,1)
#define CV_32FC2 CV_MAKETYPE(CV_32F,2)
#define CV_32FC3 CV_MAKETYPE(CV_32F,3)
#define CV_32FC4 CV_MAKETYPE(CV_32F,4)
#define CV_32FC(n) CV_MAKETYPE(CV_32F,(n))

#define CV_64FC1 CV_MAKETYPE(CV_64F,1)
#define CV_64FC2 CV_MAKETYPE(CV_64F,2)
#define CV_64FC3 CV_MAKETYPE(CV_64F,3)
#define CV_64FC4 CV_MAKETYPE(CV_64F,4)
#define CV_64FC(n) CV_MAKETYPE(CV_64F,(n))

#define CV_16FC1 CV_MAKETYPE(CV_16F,1)
#define CV_16FC2 CV_MAKETYPE(CV_16F,2)
#define CV_16FC3 CV_MAKETYPE(CV_16F,3)
#define CV_16FC4 CV_MAKETYPE(CV_16F,4)
#define CV_16FC(n) CV_MAKETYPE(CV_16F,(n))


// cvdef.h:

#define CV_MAT_CN_MASK          ((CV_CN_MAX - 1) << CV_CN_SHIFT)
#define CV_MAT_CN(flags)        ((((flags) & CV_MAT_CN_MASK) >> CV_CN_SHIFT) + 1)
#define CV_MAT_TYPE_MASK        (CV_DEPTH_MAX*CV_CN_MAX - 1)
#define CV_MAT_TYPE(flags)      ((flags) & CV_MAT_TYPE_MASK)
#define CV_MAT_CONT_FLAG_SHIFT  14
#define CV_MAT_CONT_FLAG        (1 << CV_MAT_CONT_FLAG_SHIFT)
#define CV_IS_MAT_CONT(flags)   ((flags) & CV_MAT_CONT_FLAG)
#define CV_IS_CONT_MAT          CV_IS_MAT_CONT
#define CV_SUBMAT_FLAG_SHIFT    15
#define CV_SUBMAT_FLAG          (1 << CV_SUBMAT_FLAG_SHIFT)
#define CV_IS_SUBMAT(flags)     ((flags) & CV_MAT_SUBMAT_FLAG)

///** Size of each channel item,
//   0x8442211 = 1000 0100 0100 0010 0010 0001 0001 ~ array of sizeof(arr_type_elem) */
//#define CV_ELEM_SIZE1(type) \
//    ((((sizeof(size_t)<<28)|0x8442211) >> CV_MAT_DEPTH(type)*4) & 15)

#define CV_MAT_TYPE(flags)      ((flags) & CV_MAT_TYPE_MASK)

/** 0x3a50 = 11 10 10 01 01 00 00 ~ array of log2(sizeof(arr_type_elem)) */
#define CV_ELEM_SIZE(type) \
    (CV_MAT_CN(type) << ((((sizeof(size_t)/4+1)*16384|0x3a50) >> CV_MAT_DEPTH(type)*2) & 3))

class CV_EXPORTS Range {
public:
    Range();
    Range(int _start, int _end);
    int size() const;
    bool empty() const;
    static Range all();

    int start, end;
};

template<typename _Tp> class CV_EXPORTS Point_ {
public:
    typedef _Tp value_type;

    //! default constructor
    Point_();
    Point_(_Tp _x, _Tp _y);
    Point_(const Point_& pt);
    Point_(Point_&& pt);

    Point_& operator = (const Point_& pt);
    Point_& operator = (Point_&& pt);
    //! conversion to another data type
    template<typename _Tp2> operator Point_<_Tp2>() const;

    _Tp x; //!< x coordinate of the point
    _Tp y; //!< y coordinate of the point
};

typedef Point_<int> Point2i;
typedef Point_<float> Point2f;
typedef Point_<double> Point2d;
typedef Point2i Point;

template<typename _Tp> class CV_EXPORTS Size_ {
public:
    typedef _Tp value_type;

    //! default constructor
    Size_();
    Size_(_Tp _width, _Tp _height);
    Size_(const Size_& sz);
    Size_(Size_&& sz);
    Size_(const Point_<_Tp>& pt);

    Size_& operator = (const Size_& sz);
    Size_& operator = (Size_&& sz);
    //! the area (width*height)
    _Tp area() const;
    //! aspect ratio (width/height)
    double aspectRatio() const;
    //! true if empty
    bool empty() const;

    //! conversion of another data type.
    template<typename _Tp2> operator Size_<_Tp2>() const;

    _Tp width; //!< the width
    _Tp height; //!< the height
};

typedef Size_<int> Size2i;
typedef Size_<float> Size2f;
typedef Size_<double> Size2d;
typedef Size2i Size;

template<typename _Tp> class CV_EXPORTS Rect_ {
public:
    typedef _Tp value_type;

    //! default constructor
    Rect_();
    Rect_(_Tp _x, _Tp _y, _Tp _width, _Tp _height);
    Rect_(const Rect_& r);
    Rect_(Rect_&& r);

    Rect_& operator = ( const Rect_& r );
    Rect_& operator = ( Rect_&& r );
    //! the top-left corner
    Point_<_Tp> tl() const;
    //! the bottom-right corner
    Point_<_Tp> br() const;

    //! size (width, height) of the rectangle
    Size_<_Tp> size() const;
    //! area (width*height) of the rectangle
    _Tp area() const;
    //! true if empty
    bool empty() const;

    //! conversion to another data type
    template<typename _Tp2> operator Rect_<_Tp2>() const;

    _Tp x; //!< x coordinate of the top-left corner
    _Tp y; //!< y coordinate of the top-left corner
    _Tp width; //!< width of the rectangle
    _Tp height; //!< height of the rectangle
};

typedef Rect_<int> Rect2i;
typedef Rect_<float> Rect2f;
typedef Rect_<double> Rect2d;
typedef Rect2i Rect;

enum BorderTypes {
    BORDER_CONSTANT    = 0, //!< `iiiiii|abcdefgh|iiiiiii`  with some specified `i`
    BORDER_REPLICATE   = 1, //!< `aaaaaa|abcdefgh|hhhhhhh`
    BORDER_REFLECT     = 2, //!< `fedcba|abcdefgh|hgfedcb`
    BORDER_WRAP        = 3, //!< `cdefgh|abcdefgh|abcdefg`
    BORDER_REFLECT_101 = 4, //!< `gfedcb|abcdefgh|gfedcba`
    BORDER_TRANSPARENT = 5, //!< `uvwxyz|abcdefgh|ijklmno`

    BORDER_REFLECT101  = BORDER_REFLECT_101, //!< same as BORDER_REFLECT_101
    BORDER_DEFAULT     = BORDER_REFLECT_101, //!< same as BORDER_REFLECT_101
    BORDER_ISOLATED    = 16 //!< do not look outside of ROI
};

enum InterpolationFlags{
    /** nearest neighbor interpolation */
    INTER_NEAREST        = 0,
    /** bilinear interpolation */
    INTER_LINEAR         = 1,
    /** bicubic interpolation */
    INTER_CUBIC          = 2,
    /** resampling using pixel area relation. It may be a preferred method for image decimation, as
    it gives moire'-free results. But when the image is zoomed, it is similar to the INTER_NEAREST
    method. */
    INTER_AREA           = 3,
    /** Lanczos interpolation over 8x8 neighborhood */
    INTER_LANCZOS4       = 4,
    /** Bit exact bilinear interpolation */
    INTER_LINEAR_EXACT = 5,
    /** Bit exact nearest neighbor interpolation. This will produce same results as
    the nearest neighbor method in PIL, scikit-image or Matlab. */
    INTER_NEAREST_EXACT  = 6,
    /** mask for interpolation codes */
    INTER_MAX            = 7,
    /** flag, fills all of the destination image pixels. If some of them correspond to outliers in the
    source image, they are set to zero */
    WARP_FILL_OUTLIERS   = 8,
    /** flag, inverse transformation

    For example, #linearPolar or #logPolar transforms:
    - flag is __not__ set: \f$dst( \rho , \phi ) = src(x,y)\f$
    - flag is set: \f$dst(x,y) = src( \rho , \phi )\f$
    */
    WARP_INVERSE_MAP     = 16,

    /*INTER_LANCZOS4 and Flip y*/
    INTER_LANCZOS4_FLIP_Y = 32,
    INTER_LANCZOS4_OES = 33,

    INTER_PILLOW_LINEAR = 64,
};

template<typename _Tp> class CV_EXPORTS Scalar_ {
public:
    //! default constructor
    Scalar_();
    Scalar_(_Tp v0, _Tp v1, _Tp v2=0, _Tp v3=0);
    Scalar_(_Tp v0);

    Scalar_(const Scalar_& s);
    Scalar_(Scalar_&& s);

    Scalar_& operator=(const Scalar_& s);
    Scalar_& operator=(Scalar_&& s);

    //! returns a scalar with all elements set to v0
    static Scalar_<_Tp> all(_Tp v0);

    //! conversion to another data type
    template<typename T2> operator Scalar_<T2>() const;

    //! per-element product
    Scalar_<_Tp> mul(const Scalar_<_Tp>& a, double scale=1) const;

    //! returns (v0, -v1, -v2, -v3)
    Scalar_<_Tp> conj() const;

    //! returns true iff v1 == v2 == v3 == 0
    bool isReal() const;

    //index should be less then 4
    _Tp at(int index) const;
private:
    _Tp val[4];    
};

typedef Scalar_<double> Scalar;

/////////////Scalar///////////////////
template<typename _Tp> 
inline Scalar_<_Tp>::Scalar_() {
    this->val[0] = this->val[1] = this->val[2] = this->val[3] = 0;
}

template<typename _Tp> 
inline Scalar_<_Tp>::Scalar_(_Tp v0, _Tp v1, _Tp v2, _Tp v3) {
    this->val[0] = v0;
    this->val[1] = v1;
    this->val[2] = v2;
    this->val[3] = v3;
}

template<typename _Tp> 
inline Scalar_<_Tp>::Scalar_(Scalar_<_Tp>&& s) {
    this->val[0] = std::move(s.val[0]);
    this->val[1] = std::move(s.val[1]);
    this->val[2] = std::move(s.val[2]);
    this->val[3] = std::move(s.val[3]);
}

template<typename _Tp> 
inline Scalar_<_Tp>& Scalar_<_Tp>::operator=(const Scalar_<_Tp>& s) {
    this->val[0] = s.val[0];
    this->val[1] = s.val[1];
    this->val[2] = s.val[2];
    this->val[3] = s.val[3];
    return *this;
}

template<typename _Tp> 
inline Scalar_<_Tp>& Scalar_<_Tp>::operator=(Scalar_<_Tp>&& s) {
    this->val[0] = std::move(s.val[0]);
    this->val[1] = std::move(s.val[1]);
    this->val[2] = std::move(s.val[2]);
    this->val[3] = std::move(s.val[3]);
    return *this;
}

template<typename _Tp> 
inline Scalar_<_Tp>::Scalar_(_Tp v0) {
    this->val[0] = v0;
    this->val[1] = this->val[2] = this->val[3] = 0;
}

template<typename _Tp> 
inline Scalar_<_Tp>::Scalar_(const Scalar_& s) {
    this->val[0] = s.val[0];
    this->val[1] = s.val[1];
    this->val[2] = s.val[2];
    this->val[3] = s.val[3];
}

template<typename _Tp> 
inline Scalar_<_Tp> Scalar_<_Tp>::all(_Tp v0) {
    return Scalar_<_Tp>(v0, v0, v0, v0);
}

template<typename _Tp> 
inline Scalar_<_Tp> Scalar_<_Tp>::mul(const Scalar_<_Tp>& a, double scale ) const {
    return Scalar_<_Tp>(saturate_cast<_Tp>(this->val[0] * a.val[0] * scale),
                        saturate_cast<_Tp>(this->val[1] * a.val[1] * scale),
                        saturate_cast<_Tp>(this->val[2] * a.val[2] * scale),
                        saturate_cast<_Tp>(this->val[3] * a.val[3] * scale));
}

template<typename _Tp> 
inline Scalar_<_Tp> Scalar_<_Tp>::conj() const {
    return Scalar_<_Tp>(saturate_cast<_Tp>( this->val[0]),
                        saturate_cast<_Tp>(-this->val[1]),
                        saturate_cast<_Tp>(-this->val[2]),
                        saturate_cast<_Tp>(-this->val[3]));
}

template<typename _Tp> 
inline bool Scalar_<_Tp>::isReal() const {
    return this->val[1] == 0 && this->val[2] == 0 && this->val[3] == 0;
}


template<typename _Tp> template<typename T2> 
inline Scalar_<_Tp>::operator Scalar_<T2>() const {
    return Scalar_<T2>(saturate_cast<T2>(this->val[0]),
                       saturate_cast<T2>(this->val[1]),
                       saturate_cast<T2>(this->val[2]),
                       saturate_cast<T2>(this->val[3]));
}  

template<typename _Tp>
inline _Tp Scalar_<_Tp>::at(int index) const {
    if (index < 4) {
        return (this->val[index]);
    }
    return 0.0;
}
////////////Size/////////////////
template<typename _Tp> 
inline Size_<_Tp>::Size_() : width(0), height(0) {}

template<typename _Tp> 
inline Size_<_Tp>::Size_(_Tp _width, _Tp _height) : width(_width), height(_height) {}

template<typename _Tp> 
inline Size_<_Tp>::Size_(const Size_& sz) : width(sz.width), height(sz.height) {}

template<typename _Tp> 
inline Size_<_Tp>::Size_(Size_&& sz) : width(std::move(sz.width)), height(std::move(sz.height)) {}

template<typename _Tp> 
inline Size_<_Tp>::Size_(const Point_<_Tp>& pt) : width(pt.x), height(pt.y) {}

template<typename _Tp> template<typename _Tp2> 
inline Size_<_Tp>::operator Size_<_Tp2>() const {
    return Size_<_Tp2>(saturate_cast<_Tp2>(width), saturate_cast<_Tp2>(height));
}

template<typename _Tp> 
inline Size_<_Tp>& Size_<_Tp>::operator = (const Size_<_Tp>& sz) {
    width = sz.width; height = sz.height;
    return *this;
}

template<typename _Tp> 
inline Size_<_Tp>& Size_<_Tp>::operator = (Size_<_Tp>&& sz) {
    width = std::move(sz.width); height = std::move(sz.height);
    return *this;
}

template<typename _Tp> 
inline _Tp Size_<_Tp>::area() const {
    const _Tp result = width * height;
    // CV_DbgAssert(!std::numeric_limits<_Tp>::is_integer
    //     || width == 0 || result / width == height); // make sure the result fits in the return value
    return result;
}

template<typename _Tp> 
inline double Size_<_Tp>::aspectRatio() const {
    return width / static_cast<double>(height);
}

template<typename _Tp> 
inline bool Size_<_Tp>::empty() const {
    return width <= 0 || height <= 0;
}

//////////Point////////////////

template<typename _Tp> 
inline Point_<_Tp>::Point_() : x(0), y(0) {}

template<typename _Tp> 
inline Point_<_Tp>::Point_(_Tp _x, _Tp _y) : x(_x), y(_y) {}

template<typename _Tp> 
inline Point_<_Tp>::Point_(const Point_& pt) : x(pt.x), y(pt.y) {}

template<typename _Tp> 
inline Point_<_Tp>::Point_(Point_&& pt) : x(std::move(pt.x)), y(std::move(pt.y)) {}

template<typename _Tp> 
inline Point_<_Tp>& Point_<_Tp>::operator = (const Point_& pt) {
    x = pt.x; y = pt.y;
    return *this;
}

template<typename _Tp> 
inline Point_<_Tp>& Point_<_Tp>::operator = (Point_&& pt)  {
    x = std::move(pt.x); y = std::move(pt.y);
    return *this;
}

template<typename _Tp> template<typename _Tp2> 
inline Point_<_Tp>::operator Point_<_Tp2>() const {
    return Point_<_Tp2>(saturate_cast<_Tp2>(x), saturate_cast<_Tp2>(y));
}

//////////Rect/////////////////////////

template<typename _Tp> 
inline Rect_<_Tp>::Rect_() : x(0), y(0), width(0), height(0) {}

template<typename _Tp> 
inline Rect_<_Tp>::Rect_(_Tp _x, _Tp _y, _Tp _width, _Tp _height) : x(_x), y(_y), width(_width), height(_height) {}

template<typename _Tp> 
inline Rect_<_Tp>::Rect_(const Rect_<_Tp>& r) : x(r.x), y(r.y), width(r.width), height(r.height) {}

template<typename _Tp> 
inline Rect_<_Tp>::Rect_(Rect_<_Tp>&& r) : x(std::move(r.x)), y(std::move(r.y)), width(std::move(r.width)), height(std::move(r.height)) {}

template<typename _Tp> 
inline Rect_<_Tp>& Rect_<_Tp>::operator = ( const Rect_<_Tp>& r ) {
    x = r.x;
    y = r.y;
    width = r.width;
    height = r.height;
    return *this;
}

template<typename _Tp> 
inline Rect_<_Tp>& Rect_<_Tp>::operator = ( Rect_<_Tp>&& r ) {
    x = std::move(r.x);
    y = std::move(r.y);
    width = std::move(r.width);
    height = std::move(r.height);
    return *this;
}

template<typename _Tp> 
inline Point_<_Tp> Rect_<_Tp>::tl() const {
    return Point_<_Tp>(x,y);
}

template<typename _Tp> 
inline Point_<_Tp> Rect_<_Tp>::br() const {
    return Point_<_Tp>(x + width, y + height);
}

template<typename _Tp> 
inline Size_<_Tp> Rect_<_Tp>::size() const {
    return Size_<_Tp>(width, height);
}

template<typename _Tp> 
inline _Tp Rect_<_Tp>::area() const {
    const _Tp result = width * height;
    // CV_DbgAssert(!std::numeric_limits<_Tp>::is_integer
    //     || width == 0 || result / width == height); // make sure the result fits in the return value
    return result;
}

template<typename _Tp> inline
bool Rect_<_Tp>::empty() const {
    return width <= 0 || height <= 0;
}

template<typename _Tp> template<typename _Tp2> 
inline Rect_<_Tp>::operator Rect_<_Tp2>() const {
    return Rect_<_Tp2>(saturate_cast<_Tp2>(x), saturate_cast<_Tp2>(y), saturate_cast<_Tp2>(width), saturate_cast<_Tp2>(height));
}

inline Range::Range(): start(0), end(0) {
}

inline Range::Range(int _start, int _end) : start(_start), end(_end) {
}

inline int Range::size() const {
    return end - start;
}

inline bool Range::empty() const {
    return start == end;
}

inline Range Range::all() {
    return Range(INT_MIN, INT_MAX);
}

static inline bool operator == (const Range& r1, const Range& r2) {
    return r1.start == r2.start && r1.end == r2.end;
}

static inline bool operator != (const Range& r1, const Range& r2) {
    return !(r1 == r2);
}

static inline bool operator !(const Range& r) {
    return r.start == r.end;
}

static inline Range operator & (const Range& r1, const Range& r2) {
#ifndef _WIN32
    Range r(std::max(r1.start, r2.start), std::min(r1.end, r2.end));
    r.end = std::max(r.end, r.start);
    return r;
#else
    Range r((std::max)(r1.start, r2.start), (std::min)(r1.end, r2.end));
    r.end = (std::max)(r.end, r.start);
    return r;
#endif

}

static inline Range& operator &= (Range& r1, const Range& r2) {
    r1 = r1 & r2;
    return r1;
}

static inline Range operator + (const Range& r1, int delta) {
    return Range(r1.start + delta, r1.end + delta);
}

static inline Range operator + (int delta, const Range& r1) {
    return Range(r1.start + delta, r1.end + delta);
}

static inline Range operator - (const Range& r1, int delta) {
    return r1 + (-delta);
}

enum RotateFlags {
    ROTATE_90_CLOCKWISE = 0, //!<Rotate 90 degrees clockwise
    ROTATE_180 = 1, //!<Rotate 180 degrees clockwise
    ROTATE_90_COUNTERCLOCKWISE = 2, //!<Rotate 270 degrees clockwise
};

enum MorphShapes {
    MORPH_RECT    = 0, //!< a rectangular structuring element:  \f[E_{ij}=1\f]
    MORPH_CROSS   = 1, //!< a cross-shaped structuring element:
                    //!< \f[E_{ij} = \begin{cases} 1 & \texttt{if } {i=\texttt{anchor.y } {or } {j=\texttt{anchor.x}}} \\0 & \texttt{otherwise} \end{cases}\f]
    MORPH_ELLIPSE = 2 //!< an elliptic structuring element, that is, a filled ellipse inscribed
                    //!< into the rectangle Rect(0, 0, esize.width, 0.esize.height)
};

enum FASTCVGPUBackend {
    GPU_DEFAULT = -1,
    GPU_OCL = 0,
    GPU_METAL,
    GPU_OGL,
    GPU_CUDA,
};

/** the color conversion codes
 */
enum ColorConversionCodes {
    COLOR_BGR2BGRA     = 0, //!< add alpha channel to RGB or BGR image
    COLOR_RGB2RGBA     = COLOR_BGR2BGRA,

    COLOR_BGRA2BGR     = 1, //!< remove alpha channel from RGB or BGR image
    COLOR_RGBA2RGB     = COLOR_BGRA2BGR,

    COLOR_BGR2RGBA     = 2, //!< convert between RGB and BGR color spaces (with or without alpha channel)
    COLOR_RGB2BGRA     = COLOR_BGR2RGBA,

    COLOR_RGBA2BGR     = 3,
    COLOR_BGRA2RGB     = COLOR_RGBA2BGR,

    COLOR_BGR2RGB      = 4,
    COLOR_RGB2BGR      = COLOR_BGR2RGB,

    COLOR_BGRA2RGBA    = 5,
    COLOR_RGBA2BGRA    = COLOR_BGRA2RGBA,

    COLOR_BGR2GRAY     = 6, //!< convert between RGB/BGR and grayscale, @ref color_convert_rgb_gray "color conversions"
    COLOR_RGB2GRAY     = 7,
    COLOR_GRAY2BGR     = 8,
    COLOR_GRAY2RGB     = COLOR_GRAY2BGR,
    COLOR_GRAY2BGRA    = 9,
    COLOR_GRAY2RGBA    = COLOR_GRAY2BGRA,
    COLOR_BGRA2GRAY    = 10,
    COLOR_RGBA2GRAY    = 11,

    COLOR_BGR2BGR565   = 12, //!< convert between RGB/BGR and BGR565 (16-bit images)
    COLOR_RGB2BGR565   = 13,
    COLOR_BGR5652BGR   = 14,
    COLOR_BGR5652RGB   = 15,
    COLOR_BGRA2BGR565  = 16,
    COLOR_RGBA2BGR565  = 17,
    COLOR_BGR5652BGRA  = 18,
    COLOR_BGR5652RGBA  = 19,

    COLOR_GRAY2BGR565  = 20, //!< convert between grayscale to BGR565 (16-bit images)
    COLOR_BGR5652GRAY  = 21,

    COLOR_BGR2BGR555   = 22,  //!< convert between RGB/BGR and BGR555 (16-bit images)
    COLOR_RGB2BGR555   = 23,
    COLOR_BGR5552BGR   = 24,
    COLOR_BGR5552RGB   = 25,
    COLOR_BGRA2BGR555  = 26,
    COLOR_RGBA2BGR555  = 27,
    COLOR_BGR5552BGRA  = 28,
    COLOR_BGR5552RGBA  = 29,

    COLOR_GRAY2BGR555  = 30, //!< convert between grayscale and BGR555 (16-bit images)
    COLOR_BGR5552GRAY  = 31,

    COLOR_BGR2XYZ      = 32, //!< convert RGB/BGR to CIE XYZ, @ref color_convert_rgb_xyz "color conversions"
    COLOR_RGB2XYZ      = 33,
    COLOR_XYZ2BGR      = 34,
    COLOR_XYZ2RGB      = 35,

    COLOR_BGR2YCrCb    = 36, //!< convert RGB/BGR to luma-chroma (aka YCC), @ref color_convert_rgb_ycrcb "color conversions"
    COLOR_RGB2YCrCb    = 37,
    COLOR_YCrCb2BGR    = 38,
    COLOR_YCrCb2RGB    = 39,

    COLOR_BGR2HSV      = 40, //!< convert RGB/BGR to HSV (hue saturation value) with H range 0..180 if 8 bit image, @ref color_convert_rgb_hsv "color conversions"
    COLOR_RGB2HSV      = 41,

    COLOR_BGR2Lab      = 44, //!< convert RGB/BGR to CIE Lab, @ref color_convert_rgb_lab "color conversions"
    COLOR_RGB2Lab      = 45,

    COLOR_BGR2Luv      = 50, //!< convert RGB/BGR to CIE Luv, @ref color_convert_rgb_luv "color conversions"
    COLOR_RGB2Luv      = 51,
    COLOR_BGR2HLS      = 52, //!< convert RGB/BGR to HLS (hue lightness saturation) with H range 0..180 if 8 bit image, @ref color_convert_rgb_hls "color conversions"
    COLOR_RGB2HLS      = 53,

    COLOR_HSV2BGR      = 54, //!< backward conversions HSV to RGB/BGR with H range 0..180 if 8 bit image
    COLOR_HSV2RGB      = 55,

    COLOR_Lab2BGR      = 56,
    COLOR_Lab2RGB      = 57,
    COLOR_Luv2BGR      = 58,
    COLOR_Luv2RGB      = 59,
    COLOR_HLS2BGR      = 60, //!< backward conversions HLS to RGB/BGR with H range 0..180 if 8 bit image
    COLOR_HLS2RGB      = 61,

    COLOR_BGR2HSV_FULL = 66, //!< convert RGB/BGR to HSV (hue saturation value) with H range 0..255 if 8 bit image, @ref color_convert_rgb_hsv "color conversions"
    COLOR_RGB2HSV_FULL = 67,
    COLOR_BGR2HLS_FULL = 68, //!< convert RGB/BGR to HLS (hue lightness saturation) with H range 0..255 if 8 bit image, @ref color_convert_rgb_hls "color conversions"
    COLOR_RGB2HLS_FULL = 69,

    COLOR_HSV2BGR_FULL = 70, //!< backward conversions HSV to RGB/BGR with H range 0..255 if 8 bit image
    COLOR_HSV2RGB_FULL = 71,
    COLOR_HLS2BGR_FULL = 72, //!< backward conversions HLS to RGB/BGR with H range 0..255 if 8 bit image
    COLOR_HLS2RGB_FULL = 73,

    COLOR_LBGR2Lab     = 74,
    COLOR_LRGB2Lab     = 75,
    COLOR_LBGR2Luv     = 76,
    COLOR_LRGB2Luv     = 77,

    COLOR_Lab2LBGR     = 78,
    COLOR_Lab2LRGB     = 79,
    COLOR_Luv2LBGR     = 80,
    COLOR_Luv2LRGB     = 81,

    COLOR_BGR2YUV      = 82, //!< convert between RGB/BGR and YUV
    COLOR_RGB2YUV      = 83,
    COLOR_YUV2BGR      = 84,
    COLOR_YUV2RGB      = 85,

    //! YUV 4:2:0 family to RGB
    COLOR_YUV2RGB_NV12  = 90,
    COLOR_YUV2BGR_NV12  = 91,
    COLOR_YUV2RGB_NV21  = 92,
    COLOR_YUV2BGR_NV21  = 93,
    COLOR_YUV420sp2RGB  = COLOR_YUV2RGB_NV21,
    COLOR_YUV420sp2BGR  = COLOR_YUV2BGR_NV21,

    COLOR_YUV2RGBA_NV12 = 94,
    COLOR_YUV2BGRA_NV12 = 95,
    COLOR_YUV2RGBA_NV21 = 96,
    COLOR_YUV2BGRA_NV21 = 97,
    COLOR_YUV420sp2RGBA = COLOR_YUV2RGBA_NV21,
    COLOR_YUV420sp2BGRA = COLOR_YUV2BGRA_NV21,

    COLOR_YUV2RGB_YV12  = 98,
    COLOR_YUV2BGR_YV12  = 99,
    COLOR_YUV2RGB_IYUV  = 100,
    COLOR_YUV2BGR_IYUV  = 101,
    COLOR_YUV2RGB_I420  = COLOR_YUV2RGB_IYUV,
    COLOR_YUV2BGR_I420  = COLOR_YUV2BGR_IYUV,
    COLOR_YUV420p2RGB   = COLOR_YUV2RGB_YV12,
    COLOR_YUV420p2BGR   = COLOR_YUV2BGR_YV12,

    COLOR_YUV2RGBA_YV12 = 102,
    COLOR_YUV2BGRA_YV12 = 103,
    COLOR_YUV2RGBA_IYUV = 104,
    COLOR_YUV2BGRA_IYUV = 105,
    COLOR_YUV2RGBA_I420 = COLOR_YUV2RGBA_IYUV,
    COLOR_YUV2BGRA_I420 = COLOR_YUV2BGRA_IYUV,
    COLOR_YUV420p2RGBA  = COLOR_YUV2RGBA_YV12,
    COLOR_YUV420p2BGRA  = COLOR_YUV2BGRA_YV12,

    COLOR_YUV2GRAY_420  = 106,
    COLOR_YUV2GRAY_NV21 = COLOR_YUV2GRAY_420,
    COLOR_YUV2GRAY_NV12 = COLOR_YUV2GRAY_420,
    COLOR_YUV2GRAY_YV12 = COLOR_YUV2GRAY_420,
    COLOR_YUV2GRAY_IYUV = COLOR_YUV2GRAY_420,
    COLOR_YUV2GRAY_I420 = COLOR_YUV2GRAY_420,
    COLOR_YUV420sp2GRAY = COLOR_YUV2GRAY_420,
    COLOR_YUV420p2GRAY  = COLOR_YUV2GRAY_420,

    //! YUV 4:2:2 family to RGB
    COLOR_YUV2RGB_UYVY = 107,
    COLOR_YUV2BGR_UYVY = 108,
    //COLOR_YUV2RGB_VYUY = 109,
    //COLOR_YUV2BGR_VYUY = 110,
    COLOR_YUV2RGB_Y422 = COLOR_YUV2RGB_UYVY,
    COLOR_YUV2BGR_Y422 = COLOR_YUV2BGR_UYVY,
    COLOR_YUV2RGB_UYNV = COLOR_YUV2RGB_UYVY,
    COLOR_YUV2BGR_UYNV = COLOR_YUV2BGR_UYVY,

    COLOR_YUV2RGBA_UYVY = 111,
    COLOR_YUV2BGRA_UYVY = 112,
    //COLOR_YUV2RGBA_VYUY = 113,
    //COLOR_YUV2BGRA_VYUY = 114,
    COLOR_YUV2RGBA_Y422 = COLOR_YUV2RGBA_UYVY,
    COLOR_YUV2BGRA_Y422 = COLOR_YUV2BGRA_UYVY,
    COLOR_YUV2RGBA_UYNV = COLOR_YUV2RGBA_UYVY,
    COLOR_YUV2BGRA_UYNV = COLOR_YUV2BGRA_UYVY,

    COLOR_YUV2RGB_YUY2 = 115,
    COLOR_YUV2BGR_YUY2 = 116,
    COLOR_YUV2RGB_YVYU = 117,
    COLOR_YUV2BGR_YVYU = 118,
    COLOR_YUV2RGB_YUYV = COLOR_YUV2RGB_YUY2,
    COLOR_YUV2BGR_YUYV = COLOR_YUV2BGR_YUY2,
    COLOR_YUV2RGB_YUNV = COLOR_YUV2RGB_YUY2,
    COLOR_YUV2BGR_YUNV = COLOR_YUV2BGR_YUY2,

    COLOR_YUV2RGBA_YUY2 = 119,
    COLOR_YUV2BGRA_YUY2 = 120,
    COLOR_YUV2RGBA_YVYU = 121,
    COLOR_YUV2BGRA_YVYU = 122,
    COLOR_YUV2RGBA_YUYV = COLOR_YUV2RGBA_YUY2,
    COLOR_YUV2BGRA_YUYV = COLOR_YUV2BGRA_YUY2,
    COLOR_YUV2RGBA_YUNV = COLOR_YUV2RGBA_YUY2,
    COLOR_YUV2BGRA_YUNV = COLOR_YUV2BGRA_YUY2,

    COLOR_YUV2GRAY_UYVY = 123,
    COLOR_YUV2GRAY_YUY2 = 124,
    //CV_YUV2GRAY_VYUY    = CV_YUV2GRAY_UYVY,
    COLOR_YUV2GRAY_Y422 = COLOR_YUV2GRAY_UYVY,
    COLOR_YUV2GRAY_UYNV = COLOR_YUV2GRAY_UYVY,
    COLOR_YUV2GRAY_YVYU = COLOR_YUV2GRAY_YUY2,
    COLOR_YUV2GRAY_YUYV = COLOR_YUV2GRAY_YUY2,
    COLOR_YUV2GRAY_YUNV = COLOR_YUV2GRAY_YUY2,

    //! alpha premultiplication
    COLOR_RGBA2mRGBA    = 125,
    COLOR_mRGBA2RGBA    = 126,

    //! RGB to YUV 4:2:0 family
    COLOR_RGB2YUV_I420  = 127,
    COLOR_BGR2YUV_I420  = 128,
    COLOR_RGB2YUV_IYUV  = COLOR_RGB2YUV_I420,
    COLOR_BGR2YUV_IYUV  = COLOR_BGR2YUV_I420,

    COLOR_RGBA2YUV_I420 = 129,
    COLOR_BGRA2YUV_I420 = 130,
    COLOR_RGBA2YUV_IYUV = COLOR_RGBA2YUV_I420,
    COLOR_BGRA2YUV_IYUV = COLOR_BGRA2YUV_I420,
    COLOR_RGB2YUV_YV12  = 131,
    COLOR_BGR2YUV_YV12  = 132,
    COLOR_RGBA2YUV_YV12 = 133,
    COLOR_BGRA2YUV_YV12 = 134,

    //! Demosaicing
    COLOR_BayerBG2BGR = 46,
    COLOR_BayerGB2BGR = 47,
    COLOR_BayerRG2BGR = 48,
    COLOR_BayerGR2BGR = 49,

    COLOR_BayerBG2RGB = COLOR_BayerRG2BGR,
    COLOR_BayerGB2RGB = COLOR_BayerGR2BGR,
    COLOR_BayerRG2RGB = COLOR_BayerBG2BGR,
    COLOR_BayerGR2RGB = COLOR_BayerGB2BGR,

    COLOR_BayerBG2GRAY = 86,
    COLOR_BayerGB2GRAY = 87,
    COLOR_BayerRG2GRAY = 88,
    COLOR_BayerGR2GRAY = 89,

    //! Demosaicing using Variable Number of Gradients
    COLOR_BayerBG2BGR_VNG = 62,
    COLOR_BayerGB2BGR_VNG = 63,
    COLOR_BayerRG2BGR_VNG = 64,
    COLOR_BayerGR2BGR_VNG = 65,

    COLOR_BayerBG2RGB_VNG = COLOR_BayerRG2BGR_VNG,
    COLOR_BayerGB2RGB_VNG = COLOR_BayerGR2BGR_VNG,
    COLOR_BayerRG2RGB_VNG = COLOR_BayerBG2BGR_VNG,
    COLOR_BayerGR2RGB_VNG = COLOR_BayerGB2BGR_VNG,

    //! Edge-Aware Demosaicing
    COLOR_BayerBG2BGR_EA  = 135,
    COLOR_BayerGB2BGR_EA  = 136,
    COLOR_BayerRG2BGR_EA  = 137,
    COLOR_BayerGR2BGR_EA  = 138,

    COLOR_BayerBG2RGB_EA  = COLOR_BayerRG2BGR_EA,
    COLOR_BayerGB2RGB_EA  = COLOR_BayerGR2BGR_EA,
    COLOR_BayerRG2RGB_EA  = COLOR_BayerBG2BGR_EA,
    COLOR_BayerGR2RGB_EA  = COLOR_BayerGB2BGR_EA,

    //! Demosaicing with alpha channel
    COLOR_BayerBG2BGRA = 139,
    COLOR_BayerGB2BGRA = 140,
    COLOR_BayerRG2BGRA = 141,
    COLOR_BayerGR2BGRA = 142,

    COLOR_BayerBG2RGBA = COLOR_BayerRG2BGRA,
    COLOR_BayerGB2RGBA = COLOR_BayerGR2BGRA,
    COLOR_BayerRG2RGBA = COLOR_BayerBG2BGRA,
    COLOR_BayerGR2RGBA = COLOR_BayerGB2BGRA,

    //YCbCrformat is 4: 2 : 0
    COLOR_BGRA2YCbCr    = 143, //!< convert RGBA/BGRA to luma-chroma (aka YCC), @ref color_convert_rgb_ycrcb "color conversions"
    COLOR_RGBA2YCbCr    = 144,
    COLOR_YCbCr2BGRA    = 145,
    COLOR_YCbCr2RGBA    = 146,
    COLOR_BGRA2YCbCr_nv12 = 147, //NV12：YYYYYYYY UVUV

    COLOR_RGBA2YUV      = 148,
    COLOR_YUV2RGBA      = 149,
    COLOR_COLORCVT_MAX  = 150,
    COLOR_RGBA2YUV_NV12 = 151,
    COLOR_BGRA2YCbCr_nv12_709 = 152,
    COLOR_BGRA2YCbCr_nv12_601 = 153,
};

enum NormTypes {
    NORM_INF       = 1,
    NORM_L1        = 2,
    NORM_L2        = 4,
    NORM_L2SQR     = 5,
    NORM_HAMMING   = 6,
    NORM_HAMMING2  = 7,
    NORM_TYPE_MASK = 7, 
    NORM_RELATIVE  = 8, 
    NORM_MINMAX    = 32
};

/** Threshold types */
enum ThresholdTypes {
    THRESH_BINARY     = 0, //!< \f[\texttt{dst} (x,y) =  \fork{\texttt{maxval}}{if \(\texttt{src}(x,y) > \texttt{thresh}\)}{0}{otherwise}\f]
    THRESH_BINARY_INV = 1, //!< \f[\texttt{dst} (x,y) =  \fork{0}{if \(\texttt{src}(x,y) > \texttt{thresh}\)}{\texttt{maxval}}{otherwise}\f]
    THRESH_TRUNC      = 2, //!< \f[\texttt{dst} (x,y) =  \fork{\texttt{threshold}}{if \(\texttt{src}(x,y) > \texttt{thresh}\)}{\texttt{src}(x,y)}{otherwise}\f]
    THRESH_TOZERO     = 3, //!< \f[\texttt{dst} (x,y) =  \fork{\texttt{src}(x,y)}{if \(\texttt{src}(x,y) > \texttt{thresh}\)}{0}{otherwise}\f]
    THRESH_TOZERO_INV = 4, //!< \f[\texttt{dst} (x,y) =  \fork{0}{if \(\texttt{src}(x,y) > \texttt{thresh}\)}{\texttt{src}(x,y)}{otherwise}\f]
    THRESH_MASK       = 7,
    THRESH_OTSU       = 8, //!< flag, use Otsu algorithm to choose the optimal threshold value
    THRESH_TRIANGLE   = 16 //!< flag, use Triangle algorithm to choose the optimal threshold value
};

enum FASTCVD3DVersion{
    D3D_VERSION_11  = 0,
    D3D_VERSION_12,
}; 

template<typename _Tp> static inline
bool operator != (const Point_<_Tp>& a, const Point_<_Tp>& b)
{
    return a.x != b.x || a.y != b.y;
}

template<typename _Tp> static inline
Point_<_Tp>& operator += (Point_<_Tp>& a, const Point_<_Tp>& b)
{
    a.x += b.x;
    a.y += b.y;
    return a;
}

template<typename _Tp> static inline
Point_<_Tp>& operator -= (Point_<_Tp>& a, const Point_<_Tp>& b)
{
    a.x -= b.x;
    a.y -= b.y;
    return a;
}

template<typename _Tp> static inline
Point_<_Tp> operator + (const Point_<_Tp>& a, const Point_<_Tp>& b)
{
    return Point_<_Tp>( saturate_cast<_Tp>(a.x + b.x), saturate_cast<_Tp>(a.y + b.y) );
}

template<typename _Tp> static inline
Point_<_Tp> operator - (const Point_<_Tp>& a, const Point_<_Tp>& b)
{
    return Point_<_Tp>( saturate_cast<_Tp>(a.x - b.x), saturate_cast<_Tp>(a.y - b.y) );
}


/** types of line
*/
enum LineTypes {
    FILLED  = -1,
    LINE_4  = 4, //!< 4-connected line
    LINE_8  = 8, //!< 8-connected line
    LINE_AA = 16 //!< antialiased line
};

enum HersheyFonts {
    FONT_HERSHEY_SIMPLEX        = 0, //!< normal size sans-serif font
    FONT_HERSHEY_PLAIN          = 1, //!< small size sans-serif font
    FONT_HERSHEY_DUPLEX         = 2, //!< normal size sans-serif font (more complex than FONT_HERSHEY_SIMPLEX)
    FONT_HERSHEY_COMPLEX        = 3, //!< normal size serif font
    FONT_HERSHEY_TRIPLEX        = 4, //!< normal size serif font (more complex than FONT_HERSHEY_COMPLEX)
    FONT_HERSHEY_COMPLEX_SMALL  = 5, //!< smaller version of FONT_HERSHEY_COMPLEX
    FONT_HERSHEY_SCRIPT_SIMPLEX = 6, //!< hand-writing style font
    FONT_HERSHEY_SCRIPT_COMPLEX = 7, //!< more complex variant of FONT_HERSHEY_SCRIPT_SIMPLEX
    FONT_ITALIC                 = 16 //!< flag for italic font
};

typedef std::function<void(int,const char*,const char*)> PtrLogCallbackFunc;

enum DftFlags {
    /** performs an inverse 1D or 2D transform instead of the default forward
        transform. */
    DFT_INVERSE        = 1,
    /** scales the result: divide it by the number of array elements. Normally, it is
        combined with DFT_INVERSE. */
    DFT_SCALE          = 2,
    /** performs a forward or inverse transform of every individual row of the input
        matrix; this flag enables you to transform multiple vectors simultaneously and can be used to
        decrease the overhead (which is sometimes several times larger than the processing itself) to
        perform 3D and higher-dimensional transformations and so forth.*/
    DFT_ROWS           = 4,
    /** performs a forward transformation of 1D or 2D real array; the result,
        though being a complex array, has complex-conjugate symmetry (*CCS*, see the function
        description below for details), and such an array can be packed into a real array of the same
        size as input, which is the fastest option and which is what the function does by default;
        however, you may wish to get a full complex array (for simpler spectrum analysis, and so on) -
        pass the flag to enable the function to produce a full-size complex output array. */
    DFT_COMPLEX_OUTPUT = 16,
    /** performs an inverse transformation of a 1D or 2D complex array; the
        result is normally a complex array of the same size, however, if the input array has
        conjugate-complex symmetry (for example, it is a result of forward transformation with
        DFT_COMPLEX_OUTPUT flag), the output is a real array; while the function itself does not
        check whether the input is symmetrical or not, you can pass the flag and then the function
        will assume the symmetry and produce the real output array (note that when the input is packed
        into a real array and inverse transformation is executed, the function treats the input as a
        packed complex-conjugate symmetrical array, and the output will also be a real array). */
    DFT_REAL_OUTPUT    = 32,
    /** specifies that input is complex input. If this flag is set, the input must have 2 channels.
        On the other hand, for backwards compatibility reason, if input has 2 channels, input is
        already considered complex. */
    DFT_COMPLEX_INPUT  = 64,
    /** performs an inverse 1D or 2D transform instead of the default forward transform. */
    DCT_INVERSE        = DFT_INVERSE,
    /** performs a forward or inverse transform of every individual row of the input
        matrix. This flag enables you to transform multiple vectors simultaneously and can be used to
        decrease the overhead (which is sometimes several times larger than the processing itself) to
        perform 3D and higher-dimensional transforms and so forth.*/
    DCT_ROWS           = DFT_ROWS,
    DCT_FORWARD_4x4    = 128,
    DCT_INVERSE_4x4    = 129,
};

enum FastCVCode{
    FASTCV_NO_ERROR = 0,
    FASTCV_NOT_SUPPORT,
    FASTCV_MALLOC_FAILED,
    FASTCV_INIT_ERROR,
    FASTCV_EXEC_ERROR,
    FASTCV_INVLID_PARAM,
    FASTCV_BUILD_OP_FAILED,
    FASTCV_BUILD_NOT_INITED,
};

typedef std::function<void(int,const char*,const char*)> PtrLogCallbackFunc; 
/*
*  GPU Ops Configuration
*/
enum OpClass {
    OP_RESIZE_BIT = 0,   // resize related
    OP_MORPH_BIT = 1,  // morph related
    OP_OPTICALFLOW_BIT = 2, // optical flow related
    OP_IMAGE_COPY_BIT = 3,
    OP_IMAGE_WARP_BIT = 4,
};
/*
*   resize ops config bit pos
*/
#define OP_RESIZE_LANCZOS_BIT 0
#define OP_RESIZE_LANCZOS_OES_BIT 1
}
}
#endif
