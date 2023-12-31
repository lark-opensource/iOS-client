//
// Created by admin on 2020/7/27.
//

#ifndef AE_AUTO_VOLUME_API_H
#define AE_AUTO_VOLUME_API_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * App冷启动后，观看第一条视频的推荐音量键值
 *
 * @param data 设备在特定时间段内（比如10-12点），对应音量键值的历史数据。
 *             iOS设备输入范围：0-16
 *
 * @param num 历史数据的长度
 *
 * @return 推荐的音量键值，浮点数
 *         小于0表示无法预测
 */
float mammon_auto_volume(float* data, int num);

#ifdef __cplusplus
}
#endif

#endif  // AE_AUTO_VOLUME_API_H
