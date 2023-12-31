//
//  BDALogEnv.h
//  BDALog
//
//  Created by kilroy on 2021/11/22.
//

#ifndef BDALogEnv_h
#define BDALogEnv_h

#include <string>

/**
 * 自定义初始化alog，设置App独立密钥加密alog文件，此方法自动获取沙盒内appID
 * alog_dir 对于默认实例，是完整的log文件存储路径；对于自定义实例，存储路径在默认实例路径下，实例名称作为目录名。
 * prefix log文件文件名前缀
 * maxsize 文件缓存最大值 e.g 50M = 50 *1024 *1024（byte）
 * expiry_time 文件有效期 e.g.七天 = 7 *24 *60 *60(s)
 * pub_key App自定义密钥，密钥由服务端生成，请勿随意指定，详情请见 https://bytedance.feishu.cn/docs/doccnerTgSVSdBcWnNCWfNoP4Oc
 * app_id 宿主的appID
 */

struct BDAlogInitParameter {
    char* alog_dir;
    char* prefix;
    long long max_size = 50 *1024 *1024;
    double expiry_time = 7 * 24 *60 *60;
    char* pub_key;
    char* app_id;
};

#endif /* BDALogEnv_h */
