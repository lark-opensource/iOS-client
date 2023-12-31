
#import<Foundation/Foundation.h>

#define BEF_RESULT_SUCCESS                       0  // return successfully
#define BEF_RESULT_FAILURE                     -1  // internal error

/**
 * @brief get effect_sdk version
 * @param version the version will be stored
 * @param size size of the first param
 * @return int
 * @retval 0 success
 * @retval -1 failed
 */
 extern "C" int bef_effect_get_sdk_version(char* version, const int size);
 