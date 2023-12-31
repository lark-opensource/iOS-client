//
//  TTExpDiagnosisRequest.h
//  TTNetworkManager
//
//  Created by zhangzeming on 2021/6/14.
//  Copyright © 2021 bytedance. All rights reserved.
//

#ifndef TTExpDiagnosisRequest_h
#define TTExpDiagnosisRequest_h

#import "TTExpDiagnosisRequestProtocol.h"

@interface TTExpDiagnosisRequest : NSObject<TTExpDiagnosisRequestProtocol>

- (void)start;

- (void)cancel;

- (void)doExtraCommand:(NSString*)command
          extraMessage:(NSString*)extraMessage;

- (void)setUserExtraInfo:(NSString*)extraInfo;
@end


#endif /* TTExpDiagnosisRequest_h */
