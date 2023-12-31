/*!
 @author 庄妮
 @version 1.0 2019/04/30 Creation
 */
#ifndef __CARD_OCR_API__
#define __CARD_OCR_API__
#include "smash_module_tpl.h"
#include "tt_common.h"
#include <string>

#if defined __cplusplus
extern "C" {
#endif
typedef void* CardOCRHandle;

/**
 * @brief
 *
 */
typedef struct AILAB_EXPORT cardOCRArgs {
  ModuleBaseArgs base;
} cardOCRArgs;

/**
 * @brief 用于存储检测结果,默认一张图片只检测到一个对象
 *
 */
typedef struct AILAB_EXPORT cardBoundDetInfo {
  int bounding_box[4];           ///< 检测框像素位置
  float prob = 0;                ///< 置信度
  bool has_bank = false;         ///< 是否检测到银行卡
  bool has_identity = false;     ///< 是否检测到身份证
} cardBoundDetInfo;

/**
 * @brief 用于存储银行卡回归结果以及卡号识别结果，银行卡卡号共有4个点，从左上角按顺时针方向存储
 *
 */
typedef struct AILAB_EXPORT bankCardInfo {
  cardBoundDetInfo bound_det_res;    ///< 银行卡卡检测结果
  int bank_card_landmarks[8];        ///< 银行卡号整张卡回归框共有4个点，从左上角按顺时针方向存储
  int bank_num_landmarks[8];         ///< 银行卡号回归框共有4个点，从左上角按顺时针方向存储
  bool has_bank_info = false;        ///< 是否识别到银行卡内容
  int orient = 0;                    ///< 银行卡方向，0-正，1-旋转90度，2-旋转180度，3-旋转270度
  std::string bank_recog_res;        ///< 银行卡卡号识别结果
  std::string bank_name;             ///< 银行卡卡号对应的银行名称
  int accountNum = 0;                ///< 银行卡卡号位数
} bankCardInfo;

/**
 * @brief 用于存储身份证卡回归结果以及图片类型，身份证卡回归共有4个点，从左上角按顺时针方向存储，图片类型0代表背景，1代表身份证正面，2代表身份证反面
 *
 */
typedef struct AILAB_EXPORT identityCardBoundRegInfo {
  int landmarks[8];            ///< 身份证卡回归框4个点
  int image_class = 0;         ///< 0-背景， 1-正， 2-反
  int orient = 0;              ///< 身份证卡方向，0-正，1-旋转90度，2-旋转180度，3-旋转270度
} identityCardBoundRegInfo;

/**
 * @brief 用于存储身份证反面回归结果以及识别结果
 *
 */
typedef struct AILAB_EXPORT identityCardBackInfo {
  int police_pt[8];             ///< 身份证签发机关 4个点
  int date_pt[8];               ///< 身份证签有效期限 4个点
  bool has_date = false;        ///< 身份证是否识别到日期
  bool has_police = false;      ///< 身份证是否识别到发证机关
  std::string date_info;        ///< 有效日期识别结果
  std::string police_info;      ///< 发证机关识别结果
} identityCardBackInfo;

/**
 * @brief 用于存储身份证正面回归结果以及识别结果
 *
 */
typedef struct AILAB_EXPORT identityCardFrontInfo {
  int name_pt[8];                   ///< 身份证姓名 4个点
  int gender_pt[8];                 ///< 身份证签性别 4个点
  int nation_pt[8];                 ///< 身份证民族 4个点
  int year_pt[8];                   ///< 身份证出生年 4个点
  int month_pt[8];                  ///< 身份证出生月 4个点
  int day_pt[8];                    ///< 身份证出生日 4个点
  int address_pt[8];                ///< 身份证住址 4个点
  int num_id_pt[8];                 ///< 身份证号码 4个点

  bool has_name = false;            ///< 是否识别到姓名
  bool has_gender = false;          ///< 是否识别到性别
  bool has_nation = false;          ///< 是否识别到民族
  bool has_address = false;         ///< 是否识别到地址
  bool has_year = false;            ///< 是否识别到年
  bool has_month = false;           ///< 是否识别到月
  bool has_day = false;             ///< 是否识别到日
  bool has_num_id = false;          ///< 是否识别到身份证号

  std::string name;                 ///< 姓名识别结果
  std::string gender;               ///< 性别识别结果
  std::string nation;               ///< 民族识别结果
  std::string address;              ///< 地址识别结果
  std::string num_id;               ///< 身份证号码识别结果

  int year;                         ///< 出生年识别结果
  int month;                        ///< 出生月识别结果
  int day;                          ///< 出生日识别结果
} identityCardFrontInfo;


/**
 * @brief 用于存储银行卡的所有结果
 *
 */
typedef struct AILAB_EXPORT identityCardRet {
  cardBoundDetInfo bound_det_res;                 ///< 身份证检测结果
  identityCardBoundRegInfo identity_bound_reg;    ///< 身份证回归, 身份证正反面, 身份证方向判断结果
  identityCardBackInfo identity_back_res;         ///< 身份证背面识别结果
  identityCardFrontInfo identity_front_res;       ///< 身份证正面识别结果
} identityCardRet;

/**
 * @brief 创建handler
 *
 * @param handle 句柄指针
 * @return CardOCR_CreateHandle
 */
AILAB_EXPORT
int cardOCRCreateHandle(CardOCRHandle* handle);

/**
 * @brief 设置sdk需要加载的模型文件，model_path为模型路径
 *
 * @param handle
 * @param model_path
 * @return AILAB_EXPORT CardOCR_LoadModel
 */
AILAB_EXPORT
int cardOCRLoadModel(CardOCRHandle handle, const char* model_path);

/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param mem_model 模型内存
 * @param model_size 模型内存长度
 * @return CardOCR_LoadModelFromBuff
 */
AILAB_EXPORT int cardOCRLoadModelFromBuff(void* handle,
                                           const unsigned char* mem_model,
                                           int model_size);

/**
 * @brief 输入一张图，进行银行卡检测和识别
 *
 * @param handle 句柄
 * @param args 输出参数
 * @param bankCardRes 输出参数
 * @return AILAB_EXPORT CardOCR_DO_Bank
 */
AILAB_EXPORT
int cardOCRDoBank(CardOCRHandle handle, cardOCRArgs* args, bankCardInfo* bankCardRes);

/**
 * @brief 输入一张图，进行身份证检测和识别
 *
 * @param handle 句柄
 * @param args 输出参数
 * @param identityCardRes 输出参数
 * @return AILAB_EXPORT CardOCR_DO_Identity
 */
AILAB_EXPORT
int cardOCRDoIdentity(CardOCRHandle handle, cardOCRArgs* args, identityCardRet* identityCardRes);

/**
 * @brief 释放资源
 *
 * @param handle
 * @return void
 */
AILAB_EXPORT
void cardOCRReleaseHandle(CardOCRHandle handle);

#if defined __cplusplus
}
#endif
#endif
