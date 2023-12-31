//
// Created by LIJING on 2022/11/23.
//

#pragma once
#ifndef SAMI_CORE_AE_TTS_MANAGER_H
#define SAMI_CORE_AE_TTS_MANAGER_H

#include <memory>
#include <string>
#include <vector>
#include <functional>
#include "ae_defs.h"

namespace mammon {

class FileSource;

class MAMMON_EXPORT TTSManager {
public:
    /*
     * @brief 状态码
     *
     **/
    typedef enum {
        TTSStatus_OK = 0,
        TTSStatus_Failed,
        TTSStatus_Pending,
        TTSStatus_Processing,
        TTSStatus_NotFound,
    } TTSStatus;

    /*
     * @brief token 类型
     *
     **/
    typedef enum tokenType {
        TTSTokenType_TO_B = 0,
        TTSTokenType_TO_C_D,
        TTSTokenType_TO_B_MIXED
    } TTSTokenType;

    /*
     * @brief 文本类型，支持纯文本或SSML格式
     *
     **/
    typedef enum textType {
        TTSTextType_Text = 0,
        TTSTextType_SSML }
    TTSTextType;

    /*
     * @brief 输出音频编码格式
     *
     **/
    typedef enum ttsAudioFormat {
        TTSAudioFormat_MP3 = 0,
        TTSAudioFormat_WAV,
        TTSAudioFormat_AAC,
    } TTSAudioFormat;

    /*
     * @brief 输出音频格式
     *
     **/
    typedef enum ttsDataFormat {
        TTSDataFormat_AudioBuffer = 0,      ///< 保存音频内存
        TTSDataFormat_SaveToFile,           ///< 保存到文件
        TTSDataFormat_FileSource,           ///< 返回filesource
    } TTSDataFormat;

    /*
     * @brief 鉴权参数
     *
     **/
    typedef struct {
        TTSTokenType tokenType;
        std::string url;
        std::string appKey;
        std::string token;
    } TTSAuthParam;

    /*
     * @brief 消息通知回调
     *
     * @param 参数分别为taskId，状态码，以及其他信息
     *
     **/
    using MessageCallback = std::function<void(int, TTSStatus, void*)>;

    /*
     * @brief TTS请求结构体
     *
     **/
    typedef struct requestParam {
        std::string speaker;                                   ///< 发音人
        std::string text;                                      ///< 发音文本
        TTSTextType textType;                                  ///< 文本类型
        TTSAudioFormat audioFormat = TTSAudioFormat_MP3;       ///< 输出音频编码格式,默认为MP3
        TTSDataFormat dataFormat = TTSDataFormat_AudioBuffer;  ///< 输出格式，默认为TTSDataFormat_AudioData
        int sampleRate = 24000;                                ///< 采样率，默认24000，可选[8000,16000,22050,24000,32000,44100,48000]
        int speechRate = 0;                                    ///< 语速，取值范围[-50,100]，对应倍率 (100 + speechRate) / 100
        int pitchRate = 0;                                     ///< 音调，取值范围[-12,12]，默认值为0
        bool enableTimestamp = false;                          ///< 是否选择同时返回字与音素时间戳
        std::string saveFilePath;                              ///< 保存文件路径，dataFormat为TTSDataFormat_SaveToFile时必填
        MessageCallback messageCallback;                       ///< 消息通知回调
    } TTSRequestParam;

    /*
     * @brief 请求状态码
     *
     **/
    typedef enum {
        TTSRequestStatus_OK = 0,        ///< 已加入任务队列
        TTSRequestStatus_Failed,        ///< 未加入任务队列
        TTSRequestStatus_ParamError,    ///< 参数错误
        TTSRequestStatus_Busy,          ///< 队列已满，暂时无法接入
    } TTSRequestStatus;

    /*
     * @brief 字时间戳信息
     * 默认时间单位为秒
     **/
    typedef struct {
        std::string word;
        float start_time;
        float end_time;
    } TTSWord;

    /*
     * @brief 音素时间戳信息
     * 默认时间单位为秒
     **/
    typedef struct {
        std::string phone;
        float start_time;
        float end_time;
    } TTSPhone;

    /*
     * @brief TTS结果
     *
     **/
    typedef struct ttsDataResult {
        TTSStatus status;
        float duration;
        std::vector<TTSPhone> phonemes;
        std::vector<TTSWord> words;
        std::string audioData;
        std::shared_ptr<FileSource> fileSource;  ///< TTSDataFormat_FileSource
        std::string filePath;
        TTSDataFormat dataFormat;
    } TTSDataResult;

    using TTSResult = std::tuple<std::unique_ptr<TTSDataResult>, TTSStatus>;

    TTSManager(const TTSManager&) = delete;
    TTSManager& operator=(const TTSManager&) = delete;

    explicit TTSManager(unsigned int maxWorkerCount = 1, unsigned int maxQueueLength = 3);
    ~TTSManager();

    /*
     * @brief 鉴权接口，请求TTS前需要先进行鉴权操作
     *
     * */
    void setAuthInfo(const TTSAuthParam& param);

    /*
     * @brief 开启一个TTS请求
     *
     * @return TTSRequestStatus
     * */
    TTSRequestStatus request(const TTSRequestParam& param, int& taskId);

    /*
     * @brief 获取TTS请求结果
     *
     * @param taskId, request返回的taskId
     *
     * @return TTSResult
     * */
    TTSResult getTTSResult(int taskId);

protected:
    class Impl;
    std::shared_ptr<Impl> impl_;
};

} // namespace mammon

#endif  //SAMI_CORE_AE_TTS_MANAGER_H
