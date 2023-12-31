//
//  ACCRecognitionEnumerate.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/16.
//

#ifndef ACCRecognitionEnumerate_h
#define ACCRecognitionEnumerate_h


typedef NS_ENUM(NSUInteger, ACCRecognitionMsgType) {
    ACCRecognitionMsgTypeSendRequestForParameters = 1,
    ACCRecognitionMsgTypeReceiveRequestParameters = 2,
    ACCRecognitionMsgTypeSendPropInformation = 3,
    ACCRecognitionMsgTypeQueryPropInformation = 4,
    ACCRecognitionMsgTypeSpeciesPanelNeedShow = 5,
    ACCRecognitionMsgTypeSpeciesPanelDidShow = 6,
    ACCRecognitionMsgTypeSpeciesPanelDidHide = 7,
    ACCRecognitionMsgTypeLimitOperationScope = 8,
    ACCRecognitionMsgTypeDragStateDidChanged = 9,
    ACCRecognitionMsgTypeQueryPropCoordinates = 10,
    ACCRecognitionMsgTypeReceivePropCoordinates = 11
};

typedef NS_ENUM(NSUInteger, ACCRecognitionMsg) {
    ACCRecognitionMsgRecognizedSpecies = 0x00003001
};


typedef NS_ENUM(NSUInteger, ACCRecognitionState) {
    ACCRecognitionStateNormal,
    ACCRecognitionStateRecognizing,
    ACCRecognitionStateRecognized,
    ACCRecognitionStateRecognizeFailed,
    ACCRecognitionStateRecognizeNoNetwork,
    ACCRecognitionStateRecognizeRecover,
};

/**
 *  识别结果
 */
typedef NS_ENUM(NSUInteger, ACCRecognitionDetectResult) {
    ACCRecognitionDetectResultNone = 0,
    ACCRecognitionDetectResultQRCode = 1, // 识别到内容是二维码，从本地bach道具取最终结果
    ACCRecognitionDetectResultSmartScan = 2 // 识别到内容是（花草、动物、道具推荐），从云端返回的 response 取最终结果
};

typedef NS_OPTIONS(NSUInteger, ACCRecognitionDetectMode) {
    ACCRecognitionDetectModeNone = 0,
    ACCRecognitionDetectModeCategory = 1 << 1, // 识别花草（category 命名不太对，这里和 ACCRecognitionFunctionCategory 保持一致）
    ACCRecognitionDetectModeScene = 1 << 2, // 通过场景推荐道具
    ACCRecognitionDetectModeAnimal = 1 << 3, // 识别动物+花草
};

typedef NS_OPTIONS(NSUInteger, ACCRecognitionBubble) {
    /// 1 times
    ACCRecognitionBubbleLongPress = 1 << 0,
    ACCRecognitionBubbleRightItem = 1 << 1,
    ACCRecognitionBubblePrivacy = 1 << 2,

    /// 3 times
    ACCRecognitionBubblePropHint  = 1 << 10,
    /// setting config, default 3 times
    ACCRecognitionBubbleFlower    = 1 << 11,
};

typedef NS_ENUM(NSUInteger, ACCRecognitionThreashold) {
    ACCRecognitionThreasholdClarityFail,
    ACCRecognitionThreasholdClarityIeal,
    ACCRecognitionThreasholdFlower,
};

typedef NS_ENUM(NSUInteger, ACCRecognitionRecorderState) {
    ACCRecognitionRecorderStateNormal = 0,
    ACCRecognitionRecorderStatePausing,
    ACCRecognitionRecorderStateRecording,
    ACCRecognitionRecorderStateFinished,
};

typedef void(^ACCRecognitionBlock)(id model, NSError *error);
typedef BOOL(^ACCRecognitionFilterBlock)(id model);

#define RECOG_LOG(fmt, ...) AWEMacroLogToolInfo2(@"recognition", (AWELogToolTag)(1 << 22), fmt, ##__VA_ARGS__);
#define RECOG_ERR(fmt, ...) AWEMacroLogToolError2(@"recognition", (AWELogToolTag)(1 << 22), fmt, ##__VA_ARGS__);

#endif /* ACCRecognitionEnumerate_h */
