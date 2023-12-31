//
//  ACCRecordCompletePauseStateHandler.h
//  CameraClient-Pods-AwemeLiteCore
//
//  Created by Fengfanhua.byte on 2021/10/28.
//

#import <Foundation/Foundation.h>

@protocol ACCRecordCompletePauseStateHandler <NSObject>

- (BOOL)shouldCompleteWhenPause;

@end
