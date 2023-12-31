//
//  VCNetSpeedPredictor.m
//  abrmodule
//
//  Created by guikunzhi on 2020/3/30.
//  Copyright © 2020 gkz. All rights reserved.
//

#import "VCDefaultNetworkSpeedPredictor.h"
#include "abrHECNetSpeedPredictor.h"
#include "abrHANetSpeedPredictor.h"
#include "abrANetSpeedPredictor.h"
#include "abrLSTMNetSpeedPredictor.h"
#include "abrKFNetSpeedPredictor.h"
#include "abrACNetSpeedPredictor.h"
#include "VCNetworkSpeedUtils.h"

USING_NETWORKPREDICT_NAMESPACE
@interface VCDefaultNetworkSpeedPredictor()

@property (nonatomic, assign) INetworkSpeedPredictor *predictor;

@end

@implementation VCDefaultNetworkSpeedPredictor

- (instancetype)initWithAlgoType:(NetworkPredictAlgoType)algoType {
    if (self = [super init]) {
        _predictor = nullptr;
        switch (algoType) {
            case 0:
                _predictor = new abrHECNetSpeedPredictor();
                break;
            case 1:
                _predictor = new abrHANetSpeedPredictor();
                break;
            case 2:
                _predictor = new abrANetSpeedPredictor();
                break;
            case 3:
                _predictor = new abrLSTMNetSpeedPredictor();
                break;
            case 4:
                _predictor = new abrKFNetSpeedPredictor();
                break;
            case 7:
                _predictor = new abrACNetSpeedPredictor();
                break;
            default:
                _predictor = new abrHECNetSpeedPredictor();
                break;
        };
    }
    return self;
}

- (void)dealloc {
    if (_predictor) {
        delete _predictor;
        _predictor = nullptr;
    }
}

- (float)getPredictSpeed:(int)mediaType {
    if (!self.predictor) {
        return -1;
    }
    return self.predictor->getPredictSpeed(mediaType);
}

- (float)getLastPredictConfidence {
    if (!self.predictor) {
        return -1;
    }
    return self.predictor->getLastPredictConfidence();
}

- (NSDictionary<NSString *, NSString *> *)getDownloadSpeed:(int)mediaType {
    if (!self.predictor) {
        return nil;
    }
    NSMutableDictionary *dictObj = [NSMutableDictionary dictionary];
    std::map<std::string, std::string> map= self.predictor->getDownloadSpeed(mediaType);
    std::map<std::string, std::string>::iterator it = map.begin();
    while (it != map.end()) {
        NSString *key = [NSString stringWithCString:it->first.c_str() encoding:[NSString defaultCStringEncoding]];
        NSString *value = [NSString stringWithCString:it->second.c_str() encoding:[NSString defaultCStringEncoding]];
        if (key && value) {
            dictObj[key] = value;
        } else {
            LOGD("VCNetworkSpeedPredictor error key or value is null");
        }
        it++;
    }
    return dictObj;
}

- (float)getAverageDownLoadSpeed:(int)media_type speedType:(int)speed_type trigger:(bool)trigger {
    if (!self.predictor) {
        return -1;
    }
    return self.predictor->getAverageDownloadSpeed(media_type, speed_type, trigger);
}

- (void)update:(nonnull NSObject<IVCNetworkSpeedRecord> *)speedRecord streamInfo:(nonnull NSDictionary *)streamInfoDic {
    if (!self.predictor) {
        return;
    }
    std::shared_ptr<SpeedRecordOld> record = std::make_shared<SpeedRecordOld>();
    record->streamId = convertString([speedRecord getStreamId]);
    record->bytes = [speedRecord getBytes];
    record->time = [speedRecord getTime];
    record->timestamp = [speedRecord getTimestamp];
    record->trackType = [speedRecord getTrackType];
    record->rtt = [speedRecord getRtt];
    record->lastDataRecv = [speedRecord getLastRecvDate];
    
    std::map<std::string, int> mediaInfo;
    for (NSString *key in streamInfoDic) {
        int value = [streamInfoDic[key] intValue];
        mediaInfo[convertString(key)] = value;
    }
    self.predictor->updateOldWithStreamId(record, mediaInfo);
}

@end
