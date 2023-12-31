//
//  ACCMaskWindowProtocol.h
//  CameraClient
//
//  Created by zhuopeijin on 2021/11/3.
//

#import <Foundation/Foundation.h>

#ifndef ACCMaskWindowProtocol_h
#define ACCMaskWindowProtocol_h

@protocol ACCMaskWindowProtocol <NSObject>

// rounded corner
- (void)showWindowRoundedCorner;
- (void)hideWindowRoundedCorner;

@end

#endif /* ACCMaskWindowProtocol_h */
