#include "fkms.h"
#ifdef __cplusplus
extern "C" {
#endif
    EXPORT_API enum ERROR_TYPE new_fkms_sdk(fkms_sdk **sdk, const char *userid, const char* corpid, const char* deviceid, const char* store_path, const char* authcode, const char* sdk_config, const char* deviceOS, const char* deviceModel) {
        return ERRFAILED;
    }
    EXPORT_API enum ERROR_TYPE fkms_sdk_encrypt_data(fkms_sdk* _sdk, const char *sessionid, const char *corpid, const unsigned char* input, unsigned int len, fkms_buffer** buf) {
        return ERRFAILED;
    }
    EXPORT_API enum ERROR_TYPE fkms_sdk_decrypt_data(fkms_sdk* _sdk, const char *sessionid, const char *corpid, const unsigned char* input, unsigned int len, fkms_buffer** buf) {
        return ERRFAILED;
    }
    EXPORT_API enum ERROR_TYPE fkms_sdk_notify(fkms_sdk* _sdk, const char *notify) {
        return ERRFAILED;
    }
    EXPORT_API void fkms_sdk_stop(fkms_sdk* _sdk) {}
    EXPORT_API void fkms_sdk_finish(fkms_sdk* _sdk) {}
    EXPORT_API void fkms_sdk_wipe(fkms_sdk* _sdk) {}
    EXPORT_API void fkms_read_buffer_data(const fkms_buffer* buf, unsigned char* input, unsigned int l) {}
    EXPORT_API void fkms_free_buffer(fkms_buffer *buf) {}
    EXPORT_API unsigned int fkms_buffer_len(fkms_buffer *buf) {
        return 0;
    }
    EXPORT_API void fkms_set_log_callback(log_fn fn) {}
#ifdef __cplusplus
}
#endif
