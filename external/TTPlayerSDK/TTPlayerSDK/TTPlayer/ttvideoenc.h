#ifndef ttvideoenc_h
#define ttvideoenc_h

#include <stdlib.h>

#ifdef  __cplusplus
extern "C" {
#endif


size_t ttvideo_get_encrypt_buffer_size(size_t inLen);

/// Encode a string with a specific key and a default iv.
/// @param inLen src length
/// @param key decryption key
/// @param outBuff A result buffer, please make sure sizeof outBuff bigger than <code>ttvideo_get_encrypt_buffer_size</code>
int ttvideo_encrypt_aes_cbc_128(const uint8_t *in, const size_t inLen, const uint8_t* key, uint8_t* outBuff);

#ifdef  __cplusplus
}
#endif

#endif /* ttvideoenc_h */
