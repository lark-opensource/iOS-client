//
//  NSString+BDCTCrypto.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/5/17.
//

#import "NSString+BDCTCrypto.h"
#import <sstream>
#import <arkcrypto-minigame-iOS/ByteCrypto.h>

/*
*  编码
*     传入需要编码的数据地址和数据长度
*  返回:解码后的数据
*/
uint8_t *base64_encode(const uint8_t *text, size_t text_len) {
    //定义编码字典
    static uint8_t alphabet_map[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    //计算解码后的数据长度
    //由以上可知  Base64就是将3个字节的数据(24位)，拆成4个6位的数据，然后前两位补零
    //将其转化为0-63的数据  然后根据编码字典进行编码
    int encode_length = (int)(text_len / 3 * 4);
    if (text_len % 3 > 0) {
        encode_length += 4;
    }

    //为编码后数据存放地址申请内存
    uint8_t *encode = (uint8_t *)malloc(encode_length + 1);

    //编码
    size_t i, j;
    for (i = 0, j = 0; i + 3 <= text_len; i += 3) {
        encode[j++] = alphabet_map[text[i] >> 2];                                     //取出第一个字符的前6位并找出对应的结果字符
        encode[j++] = alphabet_map[((text[i] << 4) & 0x30) | (text[i + 1] >> 4)];     //将第一个字符的后2位与第二个字符的前4位进行组合并找到对应的结果字符
        encode[j++] = alphabet_map[((text[i + 1] << 2) & 0x3c) | (text[i + 2] >> 6)]; //将第二个字符的后4位与第三个字符的前2位组合并找出对应的结果字符
        encode[j++] = alphabet_map[text[i + 2] & 0x3f];                               //取出第三个字符的后6位并找出结果字符
    }

    //对于最后不够3个字节的  进行填充
    if (i < text_len) {
        size_t tail = text_len - i;
        if (tail == 1) {
            encode[j++] = alphabet_map[text[i] >> 2];
            encode[j++] = alphabet_map[(text[i] << 4) & 0x30];
            encode[j++] = '=';
            encode[j++] = '=';
        } else { //tail==2
            encode[j++] = alphabet_map[text[i] >> 2];
            encode[j++] = alphabet_map[((text[i] << 4) & 0x30) | (text[i + 1] >> 4)];
            encode[j++] = alphabet_map[(text[i + 1] << 2) & 0x3c];
            encode[j++] = '=';
        }
    }
    encode[encode_length] = '\0';
    return encode;
}

int getRawData(char *data, std::string &res, BC_KeySeed *keySeed) {
    if (!data || !keySeed)
        return -1;

    // 随机产生key
    int r = genKeySeed(keySeed);
    // 如果返回数不等于0， 出错
    if (r != 0)
        return r;

    size_t inLen = strlen(data);
    // 根据明文的长度，获得密文的长度
    size_t outLen = getEncryptBufferSize(inLen, BC_METHOD_AES_CBC_KS);
    uint8_t *outbuff = (uint8_t *)malloc(outLen);
    if (!outbuff)
        return -1;

    // 获取加密方法
    int method = getCryptoMethod();
    // 加密
    r = byteCryptoEncrypt((uint8_t *)data, strlen(data), (uint8_t *)outbuff, &outLen, keySeed, method);
    // 返回数不等于0， 出错
    if (r != 0)
        return r;
    res.assign((char *)outbuff, outLen);
    free(outbuff);
    return 0;
}


@implementation NSString (BDCTCrypto)

- (NSString *)bdct_packedData {
    char *ori_data = const_cast<char *>([self UTF8String]);
    std::string res;
    BC_KeySeed *seed = new BC_KeySeed();
    int r = getRawData(ori_data, res, seed);
    if (r != 0)
        return nullptr;

    NSMutableString *tmpResult = [[NSMutableString alloc] init];
    uint8_t *seedBase64 = base64_encode(seed->bytes, KEY_SEED_SIZE);
    int verStrLen = (int)strlen((char *)seedBase64);
    [tmpResult appendString:[NSString stringWithFormat:@"%c", verStrLen]];
    NSString *seedStr = [NSString stringWithCString:(char *)seedBase64 encoding:NSASCIIStringEncoding];
    [tmpResult appendString:seedStr];

    uint8_t *resBase64 = base64_encode((uint8_t *)res.c_str(), res.length());
    NSString *resStr = [NSString stringWithCString:(char *)resBase64 encoding:NSASCIIStringEncoding];
    [tmpResult appendString:resStr];
    return tmpResult.copy;
}

@end
