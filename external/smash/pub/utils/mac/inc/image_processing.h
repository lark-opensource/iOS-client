#ifndef IMAGE_PROCESSING_H_
#define IMAGE_PROCESSING_H_

#include <mobilecv2/core.hpp>
#include <mobilecv2/imgproc.hpp>
#include "InputParameter.h"
#include "internal_smash.h"
#include "tt_common.h"

SMASH_NAMESPACE_OPEN

NAMESPACE_OPEN(utils)

class Rotator {
 public:
  explicit Rotator();

  ~Rotator();

  mobilecv2::Mat Rotate(mobilecv2::Mat &image, ScreenOrient orient);

  mobilecv2::Mat RotateV2(mobilecv2::Mat &image, ScreenOrient orient);

  void RotateBackInplace(mobilecv2::Mat &image, ScreenOrient orient);

  void RotateInPlace(
      uint8_t *data, int height, int width, int mcv_type, ScreenOrient orient);

 private:
  mobilecv2::Mat processed_;
  mobilecv2::Mat cloned_;
};

NAMESPACE_CLOSE(utils)
/**
 * @brief int8 版本的减均值操作
 *
 * @param data 输入数据地址指针
 * @param result 减完均值后的目的地址指针
 * @param count 指针的长度
 * @param mean 均值， 默认为128
 */
void SubtractMean(const uint8_t *data, int8_t *result, int count, int mean=128);


/**
 * @brief int8 版本的减均值操作, 输入为Mat图像
 *
 * @param src_mat 输入图像Mat
 * @param result 减完均值后的目的地址指针
 * @param count 指针的长度
 * @param mean 均值， 默认为128
 */
void SubtractMean(const mobilecv2::Mat &src_mat, int8_t *result, int mean=128);

/**
 * @brief int16 版本的减均值操作
 *
 * @param data 输入数据地址指针
 * @param result 减完均值后的目的地址指针
 * @param count 指针的长度
 * @param mean 均值， 默认为128
 */
void SubtractMean16(uint8_t *data, int16_t *result, int count, int mean=128);
/**
 * @brief int16 版本的减均值操作, 输入为Mat图像
 *
 * @param src_mat 输入图像Mat
 * @param result 减完均值后的目的地址指针
 * @param count 指针的长度
 * @param mean 均值， 默认为128
 */
void SubtractMean16(const mobilecv2::Mat &src_mat, int16_t *result, int mean=128);

void CropImageRegion(const mobilecv2::Mat &image,
                     const mobilecv2::Rect_<float> &rect,
                     mobilecv2::Mat &crop,
                     float scale_enlarge);

int CvtAndResize(const unsigned char *src_image_data,
                 PixelFormatType pixel_format,
                 int width,
                 int height,
                 int image_stride,
                 mobilecv2::Mat &out,
                 PixelFormatType dst_pixel_format,
                 int dst_width,
                 int dst_height,
                 int resize_method = mobilecv2::INTER_NEAREST);

int CvtAndResizeWithCache(const unsigned char *src_image_data,
                          PixelFormatType pixel_format,
                          int width,
                          int height,
                          int image_stride,
                          mobilecv2::Mat &out,
                          PixelFormatType dst_pixel_format,
                          int dst_width,
                          int dst_height,
                          int resize_method = mobilecv2::INTER_NEAREST,
                          mobilecv2::Mat *cache_mat=nullptr);

float GetRegionIOU(const mobilecv2::Rect_<float> &region1,
                   const mobilecv2::Rect_<float> &region2);

int GetNearestRegionIndex(const mobilecv2::Rect_<float> &exist_face,
                          const std::vector<mobilecv2::Rect_<float> > &faces,
                          const int max_face_num);

void ListMaxLikehoodRegions(
    const std::vector<mobilecv2::Rect_<float> > &existFaces,
    const std::vector<mobilecv2::Rect_<float> > &newFaces,
    const int max_face_num,
    std::vector<int> &excludeFaces);

void ConvertRotatedBGRImage(const mobilecv2::Mat &image,
                            const smash::InputParameter &param,
                            mobilecv2::Mat &detection_img);

bool GetOriginImage(const unsigned char *imageAddress,
                    const smash::InputParameter &param,
                    mobilecv2::Mat &image);
void ConvertToBGR(const mobilecv2::Mat &image,
                  const unsigned int pixel_format,
                  mobilecv2::Mat &bgr_img);

int GetColorConvertCode(PixelFormatType pixel_format,
                        PixelFormatType dst_pixel_format);

bool GetImage(const unsigned char* baseaddress,
              int image_width,
              int image_height,
              int image_stride,
              PixelFormatType pixelf_format,
              mobilecv2::Mat& image);

int RotateFront(const mobilecv2::Mat &src_image,
                const int rotation,
                mobilecv2::Mat &dst_image);

SMASH_NAMESPACE_CLOSE

#endif  // IMAGE_PROCESSING_H_
