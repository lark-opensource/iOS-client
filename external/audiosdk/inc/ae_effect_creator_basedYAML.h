//
// Created by william on 2019-06-11.
//

#pragma once

#include "ae_effect_creator.h"

namespace mammon
{
class EffectCreatorBasedYAML
{
public:
    /**
     * 根据 yaml 字符串创建音频特效
     *
     * 输入的 yaml 字符串必须是一个map的形式，可以是一个基本的音频特效:
     *
     * case_name: basic_case
     * effect:
     *  effect_name: delay
     *  parameter:
     *   delayed_time_ms: 1.0
     *   feedback: 0.61
     *
     * 也可以是 串联 的特效：
     *
     * case_name: effect_case
     * cascade_effect:
     *  - effect:
     *      effect_name: delay
     *      parameter:
     *       delayed_time_ms: 1.0
     *       feedback: 0.61
     *  - effect:
     *      effect_name: reverb
     *      parameter:
     *       wet: -2.01
     *       dry: -19.0
     *
     * 其中 case_name 并无特殊含义，只是一个标识，create 方法没有用到 case_name 的信息
     *
     * effect 和 cascade_effect 表明音频特效的类型分别是 基本特效 和 串联特效，它们属于关键字，必须写对才能争取创建
     *
     * @param case_field_yaml_txt 创建音效的yaml配置字符串
     * @param sample_rate 传入给音效处理器的音频数据的采样率
     * @param num_channel 传入给音效处理器的音频数据的通道数
     * @return 返回创建的音效实例 若创建失败则返回一个Null实例
     */
    std::unique_ptr<mammon::Effect> create(const std::string& case_field_yaml_txt,
                                           int sample_rate, int num_channel);

    /**
     * 根据 yaml 字符串创建音频特效
     *
     * 注意这个方法与上一个 create 方法的区别: 该方法的输入只包含特效部分的描述。例如如果是一个基本特效:
     *
     * effect_name: delay
     * parameter:
     *  delayed_time_ms: 1.0
     *  feedback: 0.61
     *
     * 如果是一个 串联 特效:
     *
     * - effect:
     *     effect_name: delay
     *     parameter:
     *      delayed_time_ms: 1.0
     *      feedback: 0.61
     * - effect:
     *     effect_name: reverb
     *     parameter:
     *      wet: -12.0
     *      dry: -19.0
     *
     * 改方法要指定特效的类型，如果类型为 串联 特效，其输入应该是 sequence 的形式；如果是基本特效，其输入应该为 map 形式
     *
     * @see AudioEffectType
     *
     * @param effect_field_yaml_txt 创建音效的yaml配置字符串
     * @param effect_type 特效类型
     * @param sample_rate 传入给音效处理器的音频数据的采样率
     * @param num_channel 传入给音效处理器的音频数据的声道数
     * @return 返回创建的音效实例 若创建失败则返回一个Null实例
     */
    std::unique_ptr<mammon::Effect> create(const std::string& effect_field_yaml_txt, AudioEffectType effect_type,
                                           int sample_rate, int num_channel);

    static EffectCreatorBasedYAML& getInstance()
    {
        static EffectCreatorBasedYAML instance;
        return instance;
    }

private:
    EffectCreatorBasedYAML();

    class Impl;
    std::shared_ptr<Impl> impl_;
};

}

