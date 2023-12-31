//
//  RtcSdkCryptor.m
//  ByteViewRtcBridge
//
//  Created by kiri on 2023/6/2.
//

#import "RtcSdkCryptor.h"
#include <VolcEngineRTC/native/rtc/meeting_rtc_engine_interface.h>
#include <VolcEngineRTC/native/rtc/bytertc_media_defines.h>

class MyRtcEncryptHandler: public bytertc::IEncryptHandler {
public:
    unsigned int onEncryptData(const unsigned char* data, unsigned int length, unsigned char* buf, unsigned int buf_len) {
        if (this->handler == NULL) return 0;
        return [this->handler encrypt:data length:length buf:buf buf_len:buf_len];
    }

    unsigned int onDecryptData(const unsigned char* data, unsigned int length, unsigned char* buf, unsigned int buf_len) {
        if (this->handler == NULL) return 0;
        return [this->handler decrypt:data length:length buf:buf buf_len:buf_len];
    }

    void setHandler(id<RtcCrypting> handler) {
        this->handler = handler;
    }

private:
    id<RtcCrypting> handler;
};

@interface RtcSdkCryptor() {
    @private MyRtcEncryptHandler *cppHandler;
}

@property (nonatomic, strong) id<RtcCrypting> cryptor;

@end

@implementation RtcSdkCryptor

- (instancetype)initWithCryptor:(id<RtcCrypting>)cryptor {
    if (self = [super init]) {
        self.cryptor = cryptor;
        self->cppHandler = new MyRtcEncryptHandler();
        self->cppHandler->setHandler(cryptor);
    }
    return self;
}

- (void)dealloc {
    if (self->cppHandler != NULL) {
        delete self->cppHandler;
        self->cppHandler = NULL;
    }
}

- (void)setToEngine:(ByteRtcMeetingEngineKit *)engine {
    bytertc::IMeetingRtcEngine* nativeHandle = (bytertc::IMeetingRtcEngine*)engine.getNativeHandle;
    nativeHandle->setCustomizeEncryptHandler(self->cppHandler);
}

- (void)removeFromEngine:(ByteRtcMeetingEngineKit *)engine {
    bytertc::IMeetingRtcEngine* nativeHandle = (bytertc::IMeetingRtcEngine*)engine.getNativeHandle;
    nativeHandle->setCustomizeEncryptHandler(NULL);
}

@end
