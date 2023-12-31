//
//  RtcCrypting.h
//  ByteViewRtcBridge
//
//  Created by kiri on 2023/6/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RtcCrypting <NSObject>

/**
 * @type api
 * @region 加密
 * @brief 自定义加密。  <br>
 *        使用设定的自定义加密方式，对编码后传输前的音视频帧数据进行加密。<br>
 *        暂不支持对原始音视频帧进行加密。
 * @param data 原始音视频帧数据
 * @param length 原始音视频帧数据的长度
 * @param buf 可供写入的加密后数据缓冲区
 * @param buf_len 可供写入的加密后数据缓冲区大小
 * @return 加密后的数据  <br>
 *        + ≥ 0：加密后实际写入缓冲区的数据大小  <br>
 *        + 0：丢弃该帧  <br>
 * @note <br>
 *        + 使用此接口进行自定义加密前，你必须先设置自定义加密方式，参看 `setCustomizeEncryptHandler`。
 *        + 使用 onDecryptData{@link #onDecryptData} 对已加密的音视频帧数据进行解密。
 *        + 返回的数据大小应控制在原始数据的 90% ~ 120% 范围以内，不然将被丢弃。
 */
- (unsigned int)encrypt:(const unsigned char *)data length:(unsigned int)length buf:(unsigned char *)buf buf_len:(unsigned int)buf_len;

/**
 * @type api
 * @region 加密
 * @brief 自定义解密。  <br>
 *        对自定义加密后的音视频帧数据进行解密。
 * @param data 原始音视频帧数据
 * @param length 原始音视频帧数据的长度
 * @param buf 可供写入的加密后数据缓冲区
 * @param buf_len 可供写入的加密后数据缓冲区大小
 * @return 加密后的数据  <br>
 *        + ≥ 0：加密后实际写入缓冲区的数据大小  <br>
 *        + 0：丢弃该帧  <br>
 * @note <br>
 *        + 使用此接口进行解密前，你必须先设定解密方式，参看 `setCustomizeEncryptHandler`。
 *        + 返回的数据大小应控制在原始数据的 90% ~ 120% 范围以内，不然将被丢弃。
 */
- (unsigned int)decrypt:(const unsigned char *)data length:(unsigned int)length buf:(unsigned char *)buf buf_len:(unsigned int)buf_len;

@end

NS_ASSUME_NONNULL_END
