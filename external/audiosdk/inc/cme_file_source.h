//
//  cme_file_source.h
//  mammon_engine
//
//

#ifndef mammon_engine_cme_file_source_h
#define mammon_engine_cme_file_source_h

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CMEFileSourceImpl CMEFileSource;

void mammon_file_source_create(CMEFileSource**inout_file_src, const char * path);

void mammon_file_source_destroy(CMEFileSource**inout_file_src);

bool mammon_file_source_seek(CMEFileSource *src, size_t seek_to_pos);

/**
 * @brief 从流中读取数据
 * 成功读取时，总的写入数据量是 num_frame * num_channel
 * 每次读取后，流内的位置应该向后自动增加read的量
 * @param buffer 接收数据的缓冲区
 * @param frame_num 帧数
 * @return size_t 实际读取到的帧数
 */
size_t mammon_file_source_read(CMEFileSource *src, float* buffer, size_t frame_num);

size_t mammon_file_source_getNumChannel(CMEFileSource *src);

size_t mammon_file_source_getSampleRate(CMEFileSource *src);

size_t mammon_file_source_getNumFrames(CMEFileSource *src);

size_t mammon_file_source_getNumBit(CMEFileSource *src);

/// 获得当前解码位置
size_t mammon_file_source_getPosition(CMEFileSource *src);

/// 获取文件路径
/// @return 路径字符串实际长度, 返回0表示获取失败或者inout_str空间不足
size_t mammon_file_source_getPath(CMEFileSource *src, char *inout_str, size_t max_size);

#ifdef __cplusplus
}
#endif

#endif /* mammon_engine_cme_file_source_h */
