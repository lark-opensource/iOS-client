#pragma once

#if defined(WIN32)
#define EXPORT_API __declspec( dllexport )
#else
#define EXPORT_API __attribute__ ((visibility("default")))
#endif
enum ERROR_TYPE {
    ERRNONE                  = 0,
    ERRFAILED                = 1,
    ERRNOTSUPPORT            = 2,
    /** 密文使用的密钥版本太旧，需要请求对应版本的密钥 */
    ERRNOKEY                 = 3,
    /** 需要独立验证 */
    ERRVERIFY                = 4,
    /** config过期，需要重新下载 */
    ERRCONFIGINVALID         = 5,
    /** 需要oauthcode */
    ERRNEEDOAUTH             = 6,
    /** sdktoken失效(需要重新激活) */
    ERRTOKENINVALID          = 7,
    /** 验证码过期(需要重发验证码) */
    ERRCAPTCHAEXPIRE         = 8,
    /** 验证码Token失效(需要重新激活) */
    ERRCAPTCHATOKENINVALID   = 9,
    /** 无需激活 */
    ERRNONEEDACTIVATE        = 10,
    /** 企业微信用户验证错误 */
    ERRUSERINVALID           = 11,
    /** 企业已完全关闭SDK加解密服务 */
    ERRENCRYPSERVICECLOSED   = 12,
    /** 企业处于半关闭状态，禁止新用户激活，停止使用加密服务 */
    ERRENCRYPSERVICEHALFCLOSED = 13,
    /* ……为更方便支持扩展，SDK可以透传Server的错误码，包括但不局限于此枚举中。 */
};
enum FILE_BUFFER_TAG {
    /** 表示此段是文件头 */
    FILEHEADER      = 0,
    /** 文件中间段 */
    FILEMIDDLE,
    /** 此数据段是文件尾 */
    FILEEND,
    /** 此数据段包含整个文件 */
    FILEINALL,
};
enum VerifyType {
    TYPE_NONE = 0,
    TYPE_EMAIL = 1,
    TYPE_PHONE = 2
};

typedef enum __INITSTATE {
    STATE_INIT = -1,
    STATE_SUCCESS = 0,
    STATE_VERITY = 1,
    STATE_FAILED = 2,
} InitState;

typedef enum {
    INFO = 1,
    ERROR = 2
} SDKLOGLEVEL;

typedef struct {} fkms_sdk;
typedef void* fkms_buffer;
typedef void(*log_fn)(SDKLOGLEVEL level, const char* log);
#ifdef __cplusplus
extern "C" {
#endif
    EXPORT_API enum ERROR_TYPE new_fkms_sdk(fkms_sdk **sdk, const char *userid, const char* corpid, const char* deviceid, const char* store_path, const char* authcode, const char* sdk_config, const char* deviceOS, const char* deviceModel);
    EXPORT_API enum ERROR_TYPE fkms_sdk_encrypt_data(fkms_sdk* _sdk, const char *sessionid, const char *corpid, const unsigned char* input, unsigned int len, fkms_buffer** buf);
    EXPORT_API enum ERROR_TYPE fkms_sdk_decrypt_data(fkms_sdk* _sdk, const char *sessionid, const char *corpid, const unsigned char* input, unsigned int len, fkms_buffer** buf);
    EXPORT_API enum ERROR_TYPE fkms_sdk_notify(fkms_sdk* _sdk, const char *notify);
    EXPORT_API void fkms_sdk_stop(fkms_sdk* _sdk);
    EXPORT_API void fkms_sdk_finish(fkms_sdk* _sdk);
    EXPORT_API void fkms_sdk_wipe(fkms_sdk* _sdk);
    EXPORT_API void fkms_read_buffer_data(const fkms_buffer* buf, unsigned char* input, unsigned int l);
    EXPORT_API void fkms_free_buffer(fkms_buffer *buf);
    EXPORT_API unsigned int fkms_buffer_len(fkms_buffer *buf);
    EXPORT_API void fkms_set_log_callback(log_fn fn);
#ifdef __cplusplus
}
#endif
