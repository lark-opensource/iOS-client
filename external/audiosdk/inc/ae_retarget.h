#pragma once

#ifndef AUDIO_EFFECT_AE_RETARGET_H
#define AUDIO_EFFECT_AE_RETARGET_H
#include <memory>
#include <string>

namespace mammon {
class Retarget {
public:
    class Impl;
    typedef void (*Callback_OnProgress)(float progress, void* pUser);
    typedef void (*Callback_OnFinish)(bool success, void* pUser);
    typedef void (*Callback_OnCancelled)(void* pUser);
    /**
         * @brief callback is only used for event notification. Do not call the interface of this class in callback
         * function, otherwise unpredictable problems may occur
         *
         */
    class Callback {
    public:
        /**
             * @brief triggered when the current processing progress is refreshed
             *
             * @param progress current progress, in the range of 0.0 ~ 1.0
             * @return void
             */
        virtual void onProgress(float progress) = 0;

        /**
             * @brief triggered after processing
             *
             * @param success is it successful
             * @return void
             */
        virtual void onFinish(bool success) = 0;

        /**
             * @brief triggered after user manually cancels
             *
             * @return void
             */
        virtual void onCancelled() = 0;
    };

    Retarget();
    virtual ~Retarget();

    /**
         * @brief set the path to the input audio file
         *
         * @param in_path the path to the audio file
         * @return void
         */
    void setInPath(const std::string& in_path);

    /**
         * @brief set the output audio file path, currently only support wav, m4a, aac file name suffix
         *
         * @param out_path the path of the output audio file
         * @return void
         */
    void setOutPath(const std::string& out_path);

    /**
         * @brief set the path of music analysis information file
         *
         * @param in_loop_info_path the path to the music analysis information file
         * @return void
         */
    void setLoopInfoPath(const std::string& in_loop_info_path);

    /**
         * @brief set the target time to extend
         *
         * @param target_sec target time in seconds
         * @return void
         */
    void setTargetTime(float target_sec);

    /**
         * @brief set the selection time of the input audio
         *
         * @param start_sec the starting time in seconds
         * @param end_sec the end time in seconds
         * @return void
         */
    void setRangeTime(float start_sec, float end_sec = -1);

    /**
         * @brief set the business side
         *
         * @param business the business side (player; lv;)
         * @return void
         */
    void setBusiness(const std::string business);

    /**
         * @brief set whether has beginning of the original audio in output file
         *
         * @param original_beginning true or false
         * @return void
         */
    void setOriginalBeginning(bool original_beginning);

    /**
         * @brief set callback to get progress and result in asynchronous mode.
         * the caller holds the ownership of the callback to ensure that its life cycle is longer than that of the
         * process function or the object of this class.
         *
         * @param callback callback interface class
         * @return void
         */
    void setCallback(Callback* callback);
    void setCallback(Callback_OnProgress callback_progress, Callback_OnCancelled callback_cancled,
                     Callback_OnFinish callback_finish, void* pUser);
    /**
     * @brief set loop limit cnt when loop audio
     * @param num_loop_limit  loop limits number,when exceed this number,retarted while stop an restrict time
     * @return void
     */
    void setLoopNumLimit(int num_loop_limit);
    /**
     * @brief set process mode
     *
     * @param mode
     *      0: in audio ,out audio
     *      1: in audio ,out spliceInfo.json only
     *      2: in audio ,and spliceInfo.json ,out audio according by loopinfo.json
     */
    void setProcessMode(int mode);

    /**
     * @brief get arrangement splice info by loopinfo.json
     *
     * @return json str with audio arrangement info
     */
    std::string getSliceInofs();
    /**
     * @brief set arrangement splice info ,used to gen retarget audio
     *
     * @param slice_json_str json str with audio arrangement infos
     */
    int setSliceInofs(const std::string& slice_json_str);
    /**
         * @brief start processing
         *
         * @param async asynchronous processing switch
         * @return int
         * @retval
         * 0 : in asynchrionous mode, the thread is started successfully; in synchronous mode, the processing is
         * successful else : asynchronous mode indicates that a task is running; synchronous mode indicates that the
         * extension fails
         */
    int process(bool async = true);

    /**
         * @brief check whether it is being processed in asynchronous mode
         *
         * @return bool
         * @retval
         * true : processing
         * false : free
         */
    bool isProcessing();

    /**
         * @brief manual cancellation in asynchronous mode
         *
         * @return void
         */
    void cancel();

    /**
         * @brief waiting for the processing thread to complete in asynchronous mode
         *
         * @return void
         */
    void wait();

private:
    std::shared_ptr<Impl> impl_;
};

}  // namespace mammon

#endif