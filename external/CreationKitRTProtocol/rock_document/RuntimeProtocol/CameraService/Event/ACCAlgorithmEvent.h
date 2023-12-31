//
//  ACCAlgorithmEvent.h
//  Pods
//
//  Created by liyingpeng on 2020/6/4.
//

#ifndef ACCAlgorithmEvent_h
#define ACCAlgorithmEvent_h
#import <TTVideoEditor/IESMMAlgorithmResultData.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCAlgorithmEvent <NSObject>

@optional

- (void)onDetectMaleChanged:(BOOL)hasDetectMale;
- (void)onExternalAlgorithmCallback:(NSArray<IESMMAlgorithmResultData *> *)result type:(IESMMAlgorithm)type;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCAlgorithmEvent_h */
