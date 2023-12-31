//
//  FaceVerifyModule.h
//  Pods
//
//  Created by yanxin on 2020/9/1.
//


@interface FaceVerifyModule : NSObject

- (int)verify:(NSData *)faceData
     oriPhoto:(NSData *)oriData;

@end
