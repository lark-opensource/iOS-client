//
//  ACCRecordDeleteTrackSender.h
//  CameraClient
//
//  Created by haoyipeng on 2022/2/17.
//

#import <Foundation/Foundation.h>
#import "ACCRecordDeleteTrackSenderProtocol.h"

@interface ACCRecordDeleteTrackSender : NSObject <ACCRecordDeleteTrackSenderProtocol>

- (void)sendDeleteButtonClickedSignal;
- (void)sendDeleteConfirmAlertShowSignal;
- (void)sendDeleteConfirmAlertActionSignal:(ACCRecordDeleteActionType)actionType;

@end
