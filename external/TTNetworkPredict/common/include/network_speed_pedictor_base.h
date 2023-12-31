//
//  network_speed_pedictor_base.hpp
//  networkPredictModule
//
//  Created by shen chen on 2020/7/9.
//

#ifndef network_speed_pedictor_base_H
#define network_speed_pedictor_base_H

#include <stdint.h>
#include <cstring>

#define NETWORKPREDICT_NAMESPACE_BEGIN namespace com{ namespace bytedance{ namespace vcloud{ namespace networkPredict{

#define NETWORKPREDICT_NAMESPACE_END   }}}}

#define USING_NETWORKPREDICT_NAMESPACE using namespace com::bytedance::vcloud::networkPredict;

#define LOG_VERBOSE 0
#define LOG_DEBUG   1
#define LOG_INFO    2
#define LOG_WARN    3
#define LOG_ERROR   4
#define LOG_FATAL   5

#ifdef __cplusplus
extern "C" {
#endif

void network_predict_set_logger_level(int level);
void network_predict_logger_nprintf(int level,const char* tag,const char* file,const char* fun,int line,const char* format,...);

#ifdef __cplusplus
}
#endif

#define LOG_TAG "networkPredictmodule"

#define __FILENAME__ (strrchr(__FILE__,'/')?strrchr(__FILE__,'/')+1:__FILE__)

#define LOGD(...) network_predict_logger_nprintf(LOG_DEBUG,LOG_TAG,__FILENAME__,__FUNCTION__,__LINE__,__VA_ARGS__)

#define LOGE(...) network_predict_logger_nprintf(LOG_ERROR,LOG_TAG,__FILENAME__,__FUNCTION__,__LINE__,__VA_ARGS__)

#endif /* network_speed_pedictor_base_hpp */
