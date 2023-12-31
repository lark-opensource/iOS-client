//
// Created by manjia on 2020/11/22.
//
#pragma once
using namespace std;

namespace mammonengine {

#define AudioStatusCodeGeneralStart 0
#define AudioStatusCodeBackendCodeStart 20

enum class AudioStatusCode {
    kUnknown = AudioStatusCodeGeneralStart,
    kOk,
    kBackendNonsupportSampleRate = AudioStatusCodeBackendCodeStart,
    kBackendNonsupportChannel,
    kBackendNoSetFrameSize,
    kBackendCreateError,
    kBackendNonsupportLowLatency
};

class AudioStatus {
public:
    AudioStatus() {
        code_ = AudioStatusCode::kUnknown;
        msg_ = "kUnknown";
    };

    AudioStatus(AudioStatusCode code, string msg) {
        code_ = code;
        msg_ = msg;
    };

    string getMsg() const {
        return msg_;
    };

    AudioStatusCode getCode() {
        return code_;
    };

    bool OK() const {
        if (code_ == AudioStatusCode::kOk) {
            return true;
        }
        return false;
    }

    void updateStatus(AudioStatusCode code, string msg) {
        code_ = code;
        msg_ = msg;
    }

private:
    AudioStatusCode code_;
    string msg_;
};

}
