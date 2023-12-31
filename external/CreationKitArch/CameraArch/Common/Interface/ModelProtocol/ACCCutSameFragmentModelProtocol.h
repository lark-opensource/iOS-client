//
//  ACCCutSameFragmentModelProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/1/2.
//

#ifndef ACCCutSameFragmentModelProtocol_h
#define ACCCutSameFragmentModelProtocol_h

typedef NS_ENUM(NSUInteger, ACCTemplateCartoonType) {
    ACCTemplateCartoonTypeNone      = 0,
    ACCTemplateCartoonTypeJpPhoto   = 1,
    ACCTemplateCartoonTypeHkPhoto   = 2,
    ACCTemplateCartoonTypeTcPhoto   = 4,
    ACCTemplateCartoonTypeJzPhoto   = 8
};

@protocol ACCCutSameFragmentModelProtocol <NSObject>

@property (nonatomic, copy) NSNumber *videoWidth;
@property (nonatomic, copy) NSNumber *videoHeight;
@property (nonatomic, copy) NSNumber *duration;
@property (nonatomic, copy) NSString *materialId; // fragment_id | payload_id

@property (nonatomic, assign) BOOL needReverse;

@property (nonatomic, assign, readonly) ACCTemplateCartoonType accCartoonType;

@optional

@property (nonatomic, copy) NSString *gameplayAlgorithm;

@end

#endif /* ACCCutSameFragmentModelProtocol_h */
