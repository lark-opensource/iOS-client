#ifndef _SMASH_COLORPARSEAPI_H_
#define _SMASH_COLORPARSEAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus
    
#ifdef MODULE_HANDLE
#undef MODULE_HANDLE
#endif
#define MODULE_HANDLE ColorParseHandle
    
#define NUM_COLOR_CLASSES 12
    typedef void* MODULE_HANDLE;
    
    // 模型参数类型
    // TODO: 根据实际情况修改
    typedef enum ColorParseParamType {
        kColorParseEdgeMode=0,           // 系统生成变量， demo演示，实际没用到
        ColorCountThreshold = 1,         //颜色像素数目阈值,默认为5000,如果输入尺寸变化，该阈值应该同比例改变
        GrayCountOffset = 2,             //灰色像素数目阈值增加值,默认为0，即灰色阈值为5000+0,此值也可以为负数
        LightCountThreshold = 3,         //图像明暗阈值,默认为100
        PurpleCountThreshold = 4,        // 紫色像素树木阈值，默认为1500
    } ColorParseParamType;
    
    // 模型枚举，有些模块可能有多个模型
    // TODO: 根据实际情况更改
    typedef enum ColorParseModelType {
        kColorParseModel1=1,
        kXmlModel,
    }ColorParseModelType;
    
    
    typedef struct ColorParseArgs {
        ModuleBaseArgs base;
        // 此处可以添加额外的算法参数
    } ColorParseArgs;
    
    typedef struct ColorCategoryItem {
        float value;
        bool satisfied;
    } ColorCategoryItem;
    
    typedef struct ColorParseRet {
        ColorCategoryItem items[NUM_COLOR_CLASSES];
    } ColorParseRet;
    
    typedef enum {
        HighKey = 0,
        LowKey,
        WarmTone,
        CoolTone,
        Red,
        Yellow,
        Green,
        Blue,
        Purple,
        Black,
        White,
        Gray,
    } ColorType;
    
    // 创建句柄
    AILAB_EXPORT int ColorParse_CreateHandle(void** out);
    
    // 加载模型（从文件系统中加载）
    AILAB_EXPORT int ColorParse_LoadModel(void* handle,
                                          ColorParseModelType type,
                                          const char* model_path);
    
    // 加载模型（从内存中加载，Android 推荐使用该接口）
    AILAB_EXPORT int ColorParse_LoadModelFromBuff(void* handle,
                                                  ColorParseModelType type,
                                                  const char* mem_model,
                                                  int model_size);
    
    // 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
    // 接口进行更换
    AILAB_EXPORT int ColorParse_SetParamF(void* handle,
                                          ColorParseParamType type,
                                          float value);
    
    // 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
    // 接口进行更换
    AILAB_EXPORT int ColorParse_SetParamS(void* handle,
                                          ColorParseParamType type,
                                          char* value);
    
    // 算法主调用接口
    AILAB_EXPORT int ColorParse_DO(void* handle, ColorParseArgs* args, ColorParseRet* ret);
    
    // 销毁句柄
    AILAB_EXPORT int ColorParse_ReleaseHandle(void* handle);
    
    // 打印该模块的参数，用于调试
    AILAB_EXPORT int ColorParse_DbgPretty(void* handle);
    
    ////////////////////////////////////////////
    // 如果需要添加新接口，需要找工程组的同学 review 下
    ////////////////////////////////////////////
    
#ifdef __cplusplus
}
#endif  // __cplusplus

#endif  // _SMASH_COLORPARSEAPI_H_
