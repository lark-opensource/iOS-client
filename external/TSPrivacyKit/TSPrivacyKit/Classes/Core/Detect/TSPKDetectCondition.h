//
//  TSPKDetectCondition.h
//  TSPrivacyKit
//
//  Created by PengYan on 2020/10/12.
//

#import <Foundation/Foundation.h>


@interface TSPKDetectCondition : NSObject

// If there is a status change in [currentTime - timeGapToCancelDetect, currentTime), detect should be cancelled.
// Works in instance level.
@property (nonatomic) NSTimeInterval timeGapToCancelDetect;

// If there is a status change in [currentTime - timeGapToIgnoreStatus, currentTime), status should be ignored.
@property (nonatomic) NSTimeInterval timeGapToIgnoreStatus;

@end

