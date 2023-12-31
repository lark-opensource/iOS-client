#ifndef BEF_AE_STYLE_API_H
#define BEF_AE_STYLE_API_H

#include "bef_effect_public_define.h"
#include "bef_framework_public_base_define.h"
#include "bef_info_sticker_public_define.h"
#include "bef_effect_api.h"

typedef void* bef_ae_style_engine_handle;
typedef void* bef_ae_style_manager_handle;
typedef void* bef_ae_style_feature_handle;
typedef void* bef_ae_style_command_handle;
typedef void* bef_ae_style_handle;

#if BEF_EFFECT_AI_LABCV_TOBSDK
static const int bef_ae_style_command_add_feature  = 1;
static const int bef_ae_style_command_del_feature  = 2;
static const int bef_ae_style_command_set_position = 3;
static const int bef_ae_style_command_set_order = 4;
static const int bef_ae_style_command_set_size  = 5;
static const int bef_ae_style_command_set_param   = 6;
static const int bef_ae_style_command_set_enabled = 7;
static const int bef_ae_style_command_set_rotation = 8;
static const int bef_ae_style_command_set_mirror = 9;

static const int bef_ae_style_command_group = 1000;
#else
const int bef_ae_style_command_add_feature  = 1;
const int bef_ae_style_command_del_feature  = 2;
const int bef_ae_style_command_set_position = 3;
const int bef_ae_style_command_set_order = 4;
const int bef_ae_style_command_set_size  = 5;
const int bef_ae_style_command_set_param   = 6;
const int bef_ae_style_command_set_enabled = 7;
const int bef_ae_style_command_set_rotation = 8;
const int bef_ae_style_command_set_mirror = 9;

const int bef_ae_style_command_group = 1000;
#endif

static const char *COMMAND_KEY_SET_CAPTURE  = "_internal_set_capture";
static const char *COMMAND_KEY_SET_ALPHA    = "_internal_alpha";
static const char *COMMAND_KEY_SET_FILTER   = "_internal_filter";
static const char *COMMAND_KEY_SET_MAKEUP   = "_internal_makeup";
static const char *COMMAND_KEY_SET_MAKEUP_COLOR = "_internal_makeup_color";
static const char *COMMAND_KEY_FEATURE_PATH = "_internal_feature_path";
static const char *COMMAND_KEY_BLEND_MODE   = "_interal_blend_mode";
static const char *COMMAND_KEY_TEXT_PARAMS   = "_interal_text_params";
static const char *COMMAND_KEY_SET_Z_VALUE   = "_internal_set_z_value";
static const char *COMMAND_KEY_ADJUST_PREFIX = "_internal_adjust_";
static const char *COMMAND_KEY_ADJUST_BRIGHTNESS = "_internal_adjust_brightness";
static const char *COMMAND_KEY_ADJUST_CONTRAST = "_internal_adjust_contrast";
static const char *COMMAND_KEY_ADJUST_SATURATION = "_internal_adjust_saturation";
static const char *COMMAND_KEY_ADJUST_SHARP = "_internal_adjust_sharp";
static const char *COMMAND_KEY_ADJUST_HIGHTLIGHT = "_internal_adjust_highlight";
static const char *COMMAND_KEY_ADJUST_SHADOW = "_internal_adjust_shadow";
static const char *COMMAND_KEY_ADJUST_TEMPERATURE = "_internal_adjust_temperature";
static const char *COMMAND_KEY_ADJUST_TONE = "_internal_adjust_tone";
static const char *COMMAND_KEY_ADJUST_GRAIN = "_internal_adjust_grain";
static const char *COMMAND_KEY_ADJUST_TEXTURE = "_internal_adjust_texture";
static const char *COMMAND_KEY_ADJUST_FADE = "_internal_adjust_fade";

static const char *STYLE_FEATURE_FACE_MESH_STICKER = "sprite3D"; //面部贴纸
static const char *STYLE_FEATURE_STICKER = "sprite2D"; //前景/跟随贴纸
static const char *STYLE_FEATURE_TEXT = "text"; //前景/跟随文字
static const char *STYLE_FEATURE_FACE_MESH_TEXT = "text3d"; //面部文字
static const char *STYLE_FEATURE_Filter = "lutFilter"; //滤镜
static const char *STYLE_FEATURE_GIF = "gif"; //gif
static const char *STYLE_FEATURE_ANIM_SEQ = "animation"; //序列帧
static const char *STYLE_FEATURE_Distortion = "faceDistortion"; //瘦脸
static const char *STYLE_FEATURE_RESHAPE = "faceReshape"; //捏脸
static const char *STYLE_FEATURE_GAN = "gan"; //风格化
static const char *STYLE_FEATURE_MAKEUP = "FaceMakeupV2"; //美妆
static const char *STYLE_FEATURE_FACE3D_MAKEUP = "3dmakeup";
static const char *STYLE_FEATURE_SPECIAL_EFFECT = "sfx"; //特效
static const char *STYLE_FEATURE_ADJUSTMENT = "adjustment"; //画面调节


static const char *STYLE_EXPORT_FACE_MESH = "facemesh"; //面部类型
static const char *STYLE_EXPORT_AMAZING = "AmazingFeature";


typedef struct CommandInfo
{
    int type;
    // ...
}CommandInfo;

#if BEF_EFFECT_AI_LABCV_TOBSDK
#if (defined(__ANDROID__) || defined(TARGET_OS_ANDROID)) && (BEF_EFFECT_ANDROID_WITH_JNI)
#include <jni.h>
BEF_SDK_API bef_effect_result_t
bef_ae_style_check_license(JNIEnv* env, jobject context, bef_ae_style_engine_handle handle, const char* licensePath);
#else
BEF_SDK_API bef_effect_result_t
bef_ae_style_check_license(bef_ae_style_engine_handle handle, const char* licensePath);
#endif
#endif

/**
 * @brief   创建AE引擎【渲染线程】
 * @param   [out] handle       引擎句柄
 * @return  成功返回            BEF_RESULT_SUC
 *          失败返回            参考Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_engine_create(bef_ae_style_engine_handle* handle, unsigned int width, unsigned int height);



/**
 * @brief   销毁AE引擎【渲染线程】
 * @param   [in] handle        引擎句柄
 * @return  成功返回             BEF_RESULT_SUC
 *          失败返回             参考Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_engine_destroy(bef_ae_style_engine_handle handle);


/**
 * @brief   创建风格管理器【渲染线程】
 * @param   [in]  AEHandle  AE引擎句柄
 * @param   [out] handle   风格管理器句柄
 * @return  成功返回            BEF_RESULT_SUC
 *          失败返回            参考Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_create_manager(bef_ae_style_engine_handle AEHandle, bef_ae_style_manager_handle* handle);



BEF_SDK_API bef_effect_result_t
bef_ae_style_init_algorithm(bef_ae_style_manager_handle manager, bef_resource_finder finder_h);

BEF_SDK_API bef_effect_result_t
bef_ae_style_set_picture_mode(bef_ae_style_manager_handle manager, bool picture_mode);

BEF_SDK_API bef_effect_result_t
bef_ae_style_set_model_picture_offset(bef_ae_style_manager_handle manager, float x1, float y1, float x2, float y2);

/**
 * @brief   将风格包加载到风格管理器中【渲染线程】
 * @param   [in] handle        风格管理器句柄
 * @param   [in] stylePackagePath    风格包的路径
 * @return  成功返回            BEF_RESULT_SUC
 *          失败返回            参考Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_load_from_path(bef_ae_style_manager_handle handle, bool needConvertPath, const char *stylePackagePath, int renderTargetWidth, int renderTargetHeight);

/**
 * @brief   在style中创建一个feature【渲染线程】
 * @param   [in] handle         风格管理器句柄
 * @param   [in] featurePath    feature的位置
 * @param   [out] featureHandle feature对应的句柄
 * @return  成功返回            BEF_RESULT_SUC
 *          失败返回            参考Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_create_feature_from_path(bef_ae_style_manager_handle handle, const char *featurePath, const char* featureType, bef_ae_style_feature_handle* featureHandle);

/**
 *  @brief  数据同步【渲染线程】
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_flush_data(bef_ae_style_manager_handle handle);

/**
 * @brief   在style中克隆一个feature【渲染线程】
 * @param   [in]  srcHandle      需要克隆的feature句柄
 * @param   [out] newHandle      新生成的feature句柄
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_clone_feature(bef_ae_style_feature_handle srcHandle, bef_ae_style_feature_handle* newHandle);


/**
 * @brief   将风格包保存到具体的目录中。
 * @param   [in] handle        风格管理器句柄
 * @param   [in] stylePackagePath    风格包的路径（如果目录为空则会在此目录下创建风格包）
 * @return  成功返回            BEF_RESULT_SUC
 *          失败返回            参考Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_save_style(bef_ae_style_manager_handle handle, const char *stylePackagePath);

/**
 * @brief   将风格包导出成AE引擎能直接读取的资源。
 * @param   [in] handle        风格管理器句柄
 * @param   [in] outputPath    导出文件的位置
 * @return  成功返回                BEF_RESULT_SUC
 *          失败返回                参考Error Code
*/
BEF_SDK_API bef_effect_result_t
bef_ae_style_export(bef_ae_style_manager_handle handle, const char *outputPath, const char* eventDiff);

BEF_SDK_API bef_effect_result_t
bef_ae_style_get_sticker_version(bef_ae_style_manager_handle handle, char **version);


/**
 * @brief 获取feature的使能状态
 * @param   [in]  handle         feature句柄
 * @param   [out] pEnable       是否使能
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_feature_get_enable(bef_ae_style_feature_handle handle, int *pEnable);

/**
 * @brief 获取feature的镜像状态
 * @param   [in]  handle         feature句柄
 * @param   [out] pMirror       是否镜像
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_feature_get_mirror(bef_ae_style_feature_handle handle, int *pMirror);

/**
 * @brief   获取风格包中的所有feature【渲染线程】
 * @param   [in]  managerHandle    风格管理器句柄
 * @param   [out] handleArray     feature句柄数组（对应的feature引用技术会+1）
 * @param   [out] handlecount     feature句柄个数
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_get_feature_list(bef_ae_style_manager_handle managerHandle, bef_ae_style_feature_handle** handleArray, unsigned int* handleCount);



/**
 * @brief   将引擎输出渲染到目标纹理上。
 * @param   [in]  handle               风格管理器句柄
 * @param   [in]  input_tex            输入纹理
 * @param   [in]  output_tex           输出纹理
 * @param   [in]  time                 时间戳 （绝对时间，用于更新动画）
 * @return  Successful return          BEF_RESULT_SUC
 *               Fail return*          reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_feature_update(bef_ae_style_manager_handle handle,
                      unsigned int input_tex,
                      unsigned int output_tex,
                      double time);


/**
 * @brief   将引擎输出渲染到目标纹理上，同时指定高宽。若高宽发生改变引擎纹理大小随之会变化。
 * @param   [in]  handle               风格管理器句柄
 * @param   [in]  input_tex             输入纹理
 * @param   [in]  output_tex           输出纹理
 * @param   [in]  width                     纹理的宽度
 * @param   [in]  height                   纹理的高度
 * @param   [in]  time                 时间戳 （绝对时间，用于更新动画）
 * @return  Successful return          BEF_RESULT_SUC
 *               Fail return*          reference Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_feature_update_with_size(bef_ae_style_manager_handle handle,
                      unsigned int input_tex,
                      unsigned int output_tex,
                      unsigned int width,
                      unsigned int height,
                      double time);


/**
 * @brief   销毁风格管理器【渲染线程】
 * @param   [in] handle       需要销毁的风格管理器句柄
 * @return  成功返回           BEF_RESULT_SUC
 *          失败返回           参考Error Code
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_destroy_manager(bef_ae_style_manager_handle handle);


/**
* @brief 销毁feature
* @param  [in]  handle      feature句柄
*/
BEF_SDK_API bef_effect_result_t
bef_ae_style_destroy_feature(bef_ae_style_feature_handle featureHandle);


/**
 * @brief   获取一个Feature在manager中的次序 【任意线程】
 * @param   [in]  featureHandle     feature句柄
 * @param   [out] order             feature的次序
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_feature_get_order(bef_ae_style_feature_handle handle, int *order);

/**
 * @brief   设置Feature参数，如旋转角度滤镜强度等 【任意线程】
 * @param   [in]  handle             feature句柄
 * @param   [out] params_json        json形式的参数
 */
BEF_SDK_API bef_effect_result_t
bef_ae_feature_get_params(bef_ae_style_feature_handle handle, char **params_json);

/**
 * @brief   获取导出参数JSON
 * @param   [in]  feature                feature 句柄
 * @param   [out] params_json        json形式的参数
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_get_export_param(bef_ae_style_feature_handle feature, char **params_json);

/**
 * @brief   设置导出参数JSON
 * @param   [in]  feature                feature 句柄
 * @param   [out] params_json        json形式的参数
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_set_export_param(bef_ae_style_feature_handle feature, char *params_json);

/**
 * @brief 获取Feature位置 【任意线程】
 * @param   [in]  handle         feature句柄
 * @param   [out] x,y            坐标参数
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_feature_get_position(bef_ae_style_feature_handle handle,
                               float *x,
                               float *y);

/**
 * @brief 获取feature的宽高信息 【任意线程】
 * @param   [out]  handle                   feature句柄
 * @param   [out]  width                     Feature的宽度
 * @param   [out]  height                   Feature的高度
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_feature_get_size(bef_ae_style_feature_handle handle,
                               float *width,
                               float *height);

BEF_SDK_API bef_effect_result_t
bef_ae_style_feature_get_snapshot(bef_ae_style_feature_handle handle,
                                  int width,
                                  int height,
                                  unsigned char* bitmap);
/**
 * @brief 获取feature的内存信息，单位为mb
 * 编辑态内存 = constMemoryEdit + (adaptMemoryEdit * 画布像素宽 * 画布像素高)
 * 预览态内存 = constMemoryPreview + (adaptMemroyPreview * 画布像素宽 * 画布像素高)
 * 加载Feature后需要至少经过一帧渲染后数据才会有效，否则所有值被设为-1且返回BEF_RESULT_FAIL
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_feature_get_memory(bef_ae_style_feature_handle handle,
                                float* constMemoryEdit,
                                float* adaptMemoryEdit,
                                float* constMemoryPreview,
                                float* adaptMemroyPreview);
/**
* @brief   获取包围盒 【任意线程】
* @param   [in]  handle  feature句柄
* @param   [out] out_box 包围盒位置
* @param   [out] out_rot 旋转角度
*/
BEF_SDK_API bef_effect_result_t
bef_ae_style_feature_get_boundingbox(bef_ae_style_feature_handle handle,
                         bef_BoundingBox_2d *out_box,
                         float* out_rot);

/**
 * @brief   创建 Command
 * @param   [in] commandType  Command类型
 * @param   [in] handle       操作对象对应的handle，目前主要是FeatureHandle
 * @param   [in] params_json  Json形式的Command参数【详见：6.Command参数说明一节】
 * @return  Command 句柄
 */
BEF_SDK_API bef_ae_style_command_handle
bef_ae_style_create_command(int commandType, bef_ae_style_handle handle, const char* params_json);


/**
 * @brief   销毁 Command
 * @param   [in] commandType    Command 句柄
 * @return  Command 句柄
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_destroy_command(bef_ae_style_command_handle cmd);

/**
 * @brief   将多个 Command 打包为一个 Group
 * @param   [in] pCmdLis   Command 句柄数组
 * @param   [in] count    风格管理器句柄
 */
BEF_SDK_API bef_ae_style_command_handle
bef_ae_style_create_command_group(bef_ae_style_command_handle* pCmdList, int count);

/**
 * @brief   执行 Command
 * @param   [in] cmd              Command 句柄
 */
BEF_SDK_API bef_effect_result_t
bef_ae_style_execute_command(bef_ae_style_command_handle cmd);


/**
 * @brief   Undo
 * @param   [in]  managerHandle    风格管理器句柄
 * @param   [out] handle           受影响的 feature 的 handle
 * @return  Undo 执行的 command 的类型
 */
BEF_SDK_API int
bef_ae_style_undo_command(bef_ae_style_manager_handle managerHandle, bef_ae_style_feature_handle* handle);

/**
 * @brief   Redo
 * @param   [in]  managerHandle    风格管理器句柄
 * @param   [out] handle           受影响的 feature 的 handle
 * @return  Redo 执行的 command 的类型
 */
BEF_SDK_API int
bef_ae_style_redo_command(bef_ae_style_manager_handle managerHandle, bef_ae_style_feature_handle* handle);


/**
* @brief   设置资源加载的根目录，每个feature都从此路径下加载。
* @param   [in]  managerHandle    风格管理器句柄
* @param   [in] rootPath                 资源根目录
*/
BEF_SDK_API int
bef_ae_style_set_feature_root_path(bef_ae_style_manager_handle handle, const char* rootPath);

BEF_SDK_API bef_effect_result_t
bef_ae_style_set_algorithm_force(bef_ae_style_manager_handle handle,unsigned int input_tex,
                                 unsigned int output_tex,
                                 unsigned int width,
                                 unsigned int height,double time, int foceDetect);





BEF_SDK_API bef_effect_result_t
bef_ae_style_set_builtIn_resource_path(bef_ae_style_manager_handle handle, const char* resourcePath);

/**
* @brief   获取开放平台需要打开的算法位。每帧在gl线程调用，只需对相机实例调用
* @param   [in]  managerHandle    风格管理器句柄
* @param   [in] req                         算法位
* @param   [in] req                         是否发生了改变，如果发生了改变需要设置到主拍上
*/
BEF_SDK_API bef_effect_result_t
bef_ae_style_get_req(bef_ae_style_manager_handle handle,bef_requirement_new *req, bool* needUpdate);


BEF_SDK_API bef_effect_result_t
bef_ae_style_set_algorithm_result(bef_ae_style_manager_handle handle,bef_algorithm_data
                             faceResult);

BEF_SDK_API bef_effect_result_t
bef_ae_style_set_text_placeholder(bef_ae_style_manager_handle handle, const char* placeholder);

BEF_SDK_API bef_effect_result_t
bef_ae_style_set_default_feature(bef_ae_style_manager_handle handle, const char* path, const char* keyValues,const char* featureType,bef_ae_style_feature_handle* featurehandle);

BEF_SDK_API bef_effect_result_t
bef_ae_style_get_total_memory(bef_ae_style_manager_handle handle, int displayWidth, int displayHeight, float* previewMemory, float* editMemory);

/**
* @brief   设置uuid生成函数，effect内部负责通过free函数释放返回的uuid字符串指针
* @param   [in]  generator   生成uuid的 函数指针
*/
BEF_SDK_API void bef_ae_style_set_uuid_generator(char* (*generator)());

/**
* @brief   获取feature uuid，不需要在gl线程执行
* @param   [in]  handle   feature句柄
* @param   [out]  id feature的uuid，外部调用者负责用free函数释放该指针内存
*/
BEF_SDK_API bef_effect_result_t
bef_ae_style_feature_get_id(bef_ae_style_feature_handle handle,
                            char** uuid);

/**
* @brief   获取feature类型，不需要在gl线程执行
* @param   [in]  handle   feature句柄
* @param   [out]  id feature的类型，外部调用者负责用free函数释放该指针内存
*/
BEF_SDK_API bef_effect_result_t
bef_ae_style_feature_get_type(bef_ae_style_feature_handle handle,
                              char** type);

/**
* @brief   对于序列帧和gif返回播放一次的时间，否则返回0。单位为毫秒。需要在gl线程执行
* @param   [in]  handle   feature句柄
* @param   [out] 播放时间
*/
BEF_SDK_API bef_effect_result_t
bef_ae_style_feature_get_duration(bef_ae_style_feature_handle handle,
                                  unsigned long* duration);
/**
* @brief   刷新事件，重置播放
*/
BEF_SDK_API bef_effect_result_t
bef_ae_style_refresh_event(bef_ae_style_manager_handle managerHandle);

/**
* @brief   设置event参数
*/
BEF_SDK_API bef_effect_result_t
bef_ae_style_set_events(bef_ae_style_manager_handle styleHandle, const char* events);

/**
* @brief   获取event参数，必须等待bef_ae_style_load_from_path执行完成调用才会有效
* events内存由外部通过free释放
*/
BEF_SDK_API bef_effect_result_t
bef_ae_style_get_events(bef_ae_style_manager_handle styleHandle, char** events);

/**
* @brief 建立style manager和effect manager的关联。外部需保证effect manager生命周期始终长于style manager
* 仅需关联相机实例的styleManager
*/
BEF_SDK_API bef_effect_result_t
bef_ae_style_connect_to_effect_manager(bef_ae_style_manager_handle styleHandle, bef_effect_handle_t effectHandle);

/**
* @brief   在不更新状态的前提下以增量的方式修改现有event的属性，不允许修改event的type属性
*/
BEF_SDK_API bef_effect_result_t
bef_ae_style_update_events(bef_ae_style_manager_handle styleHandle, const char* diffEvents);

/**
* @brief   更新所有由时间轨道驱动的图层，不需要在gl线程执行。单位毫秒
*/
BEF_SDK_API bef_effect_result_t
bef_ae_style_seek(bef_ae_style_manager_handle styleHandle, unsigned long time);

/**
* @brief 是否更新触发逻辑，默认为true，任意线程执行
*/
BEF_SDK_API bef_effect_result_t
bef_ae_style_set_event_enable(bef_ae_style_manager_handle styleHandle, bool enable);

/**
* @brief   获取feature旋转角度
*/
BEF_SDK_API bef_effect_result_t
bef_ae_style_get_rotation(bef_ae_style_feature_handle handle, int rotationAxis, float* rotation);

/**
* @brief   设置路径转换函数，输入原始路径数组，输出转换后的路径数组，输入输出一一对应
* @param   [in]  styleHandle    StyleManager句柄
* @param   [in]  pathConvertHandle  调用者句柄指针
* @param   [in]  pFun 路径转换函数指针；输入参数：存放原始路径的字符串数组，数组大小，调用者句柄指针；返回：存放转换后路径的字符串数组，由effect负责调用free释放内存
*/
BEF_SDK_API
void bef_effect_set_path_converter(bef_ae_style_manager_handle styleHandle, void* pathConvertHandle, char** (*pFun)(char**, unsigned int, void*));
#endif /* BEF_AE_STYLE_API_H */



