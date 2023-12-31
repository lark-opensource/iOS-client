//
//  ACCRecordTapGestureRecognizer.h
//  CameraClient
//
//  Created by Shichen Peng on 2021/8/10.
//

#ifndef ACCRecordTapGestureRecognizer_h
#define ACCRecordTapGestureRecognizer_h

#import <UIKit/UITapGestureRecognizer.h>

@interface ACCRecordTapGestureRecognizer : UITapGestureRecognizer
- (void)setIntervalBetweenTaps:(NSTimeInterval)intervalTime;

@end

#endif /* ACCRecordTapGestureRecognizer_h */
