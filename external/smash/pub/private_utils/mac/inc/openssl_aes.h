#ifndef openssl_aes_hpp
#define openssl_aes_hpp

namespace smash {
int AES_EncryptWrapper(const unsigned char *input, const unsigned int inputSize, const unsigned char* key,const unsigned int keySize, unsigned char **output, unsigned int* outputSize);
int AES_DecryptWrapper(const unsigned char *input, const unsigned int inputSize, const unsigned char* key,const unsigned int keySize, unsigned char **output, unsigned int* outputSize);

}  // namespace smash
#endif /* openssl_aes_hpp */
