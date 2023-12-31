//
//  ACCRecordAuthDefine.h
//  Pods
//
//  Created by liyingpeng on 2020/5/19.
//

#ifndef ACCRecordAuthDefine_h
#define ACCRecordAuthDefine_h

typedef NS_OPTIONS(NSUInteger, ACCRecordAuthComponentAuthType) {
    ACCRecordAuthComponentCameraAuthed = 1 << 0,
    ACCRecordAuthComponentCameraDenied = 1 << 1,
    ACCRecordAuthComponentCameraNotDetermined = 1 << 2,
    ACCRecordAuthComponentMicAuthed = 1 << 3,
    ACCRecordAuthComponentMicDenied = 1 << 4,
    ACCRecordAuthComponentMicNotDetermined = 1 << 5,
};

#endif /* ACCRecordAuthDefine_h */
