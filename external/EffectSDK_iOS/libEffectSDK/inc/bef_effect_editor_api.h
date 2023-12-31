#ifndef BEF_EFFECT_EDITOR_API_H
#define BEF_EFFECT_EDITOR_API_H

#include "bef_effect_public_define.h"
#include "bef_framework_public_base_define.h"
#include "bef_effect_api.h"

/**
 * @brief   将当前激活的道具包导出到目录中
 * @param   [in] handle              Effect Handle
 * @param   [in] dstPath             导出道具包的路径，例如，/User/xxx/my_sticker/，其中my_sticker为道具目录
 * @return  成功返回                   BEF_RESULT_SUC
 *          失败返回                   参考Error Code
 */

BEF_SDK_API bef_effect_result_t
bef_effect_editor_export_active_effect(bef_effect_handle_t handle, const char* dstPath);

#endif /* BEF_EFFECT_EDITOR_API_H */



