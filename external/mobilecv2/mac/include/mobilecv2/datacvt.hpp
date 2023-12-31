#ifndef _MOBILECV2_DATACVT_HPP_
#define _MOBILECV2_DATACVT_HPP_

#include "mobilecv2/core.hpp"

namespace mobilecv2 {

    /**
     * convert float type data to uint8 type data with saturate[0, 255], mean can't equal 0.
     * this is not a normal convert, only convert as image data type uint8.
     * outData = mobilecv2::saturate_cast<uchar>((inData * mean) + mean);
     * @param inData
     * @param outData
     * @param len
     * @param mean, should not equal 0
     */
    CV_EXPORTS_W void cvtFloatToUint8(const float *inData, uint8_t *outData, int len, float mean);

    /**
     * convert int16 type data to uint8 type data with saturate[0, 255].
     * this is not a normal convert, only convert as image data type uint8.
     * outData = mobilecv2::saturate_cast<uchar>(inData * 128 / powf(2, fl) + 128);
     * @param inData
     * @param outData
     * @param len
     * @param fl
     */
    CV_EXPORTS_W void cvtInt16ToUint8(const int16_t *inData, uint8_t *outData, int len, int fl);

    /**
     * convert int16 type data to uint8 type data with saturate[0, 255].
     * this is not a normal convert, only convert as image data type uint8.
     * outData = mobilecv2::saturate_cast<uchar>(inData * 128 / powf(2, fl) + 128);
     * @param inData
     * @param outData
     * @param len
     * @param fl
     */
    CV_EXPORTS_W void cvtInt8ToUint8(const int8_t *inData, uint8_t *outData, int len, int fl);

    /**
     * uint8 type data substract mean to float type data.
     * outData = (inData - mean) / mean;
     * @param inData
     * @param outData
     * @param len
     * @param mean, should not equal 0
     */
    CV_EXPORTS_W void subMeanUint8ToFloat(uint8_t *inData, float *outData, int len, float mean);

    /**
     * uint8 type data substract mean to int8 type data.
     * outData = inData - mean;
     * @param data
     * @param result
     * @param len
     * @param mean
     */
    CV_EXPORTS_W void subMeanUint8ToInt8(const uint8_t *inData, int8_t *outData, int len, int mean);

    /**
     * uint8 type data substract mean to int8 type data.
     * outData = inData - mean;
     * @param data
     * @param result
     * @param len
     * @param mean
     */
    CV_EXPORTS_W void subMeanUint8ToInt16(uint8_t *inData, int16_t *outData, int len, int mean);

    CV_EXPORTS_W int checkAVX2Support();

} // mobilecv2
#endif
