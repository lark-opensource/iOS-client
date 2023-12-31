//
//  AMGIbrDefine.h
//  amazing_engine
//
//  Created by xuhantong on 2021/12/2.
//
#ifndef bef_effect_ibr_define_h
#define bef_effect_ibr_define_h

#define DECODE_RESULT_ERROR 0   // return error
#define DECODE_RESULT_SUCCESS 1 // return successfully

typedef void* ibr_decoder_handle;

typedef struct
{
    int img_width;
    int img_height;
    int img_channel;
} ibr_decoder_params;

/**
 * create decoder
 * @param data_dir the ibr data package directory path
 * @param length  length of directory path
 * return ibr_decoder_handle, NULL for creating failed.
 */
typedef ibr_decoder_handle (*ibr_decoder_create)(const char* data_dir, int length);

/**
 * query decoder params
 * @param handle ibr decoder handle
 * @param params  query result
 * return int, 0 for query failed, 1 for query successfully.
 */
typedef int (*ibr_decoder_query)(ibr_decoder_handle handle, ibr_decoder_params* params);

/**
 * decode one image synchronously
 * @param handle ibr decoder handle
 * @param lon image longtitude position
 * @param lat image latitude position
 * @param img_data decode result data(yuv420)
 */
typedef int (*ibr_decoder_decode)(ibr_decoder_handle handle, short lon, short lat, unsigned char* img_data);

/**
 * release decoder handle
 * @param handle ibr decoder handle
 */
typedef int (*ibr_decoder_release)(ibr_decoder_handle handle);

typedef struct
{
    ibr_decoder_create createHandle;
    ibr_decoder_query queryParams;
    ibr_decoder_decode decodeImage;
    ibr_decoder_release releaseHandle;
} ibr_decoder_methods;
#endif /* bef_effect_ibr_define_h */
