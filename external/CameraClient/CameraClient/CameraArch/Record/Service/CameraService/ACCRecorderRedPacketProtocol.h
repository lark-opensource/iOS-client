//
//  ACCRecorderRedPacketProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/4/20.
//

#ifndef ACCRecorderRedPacketProtocol_h
#define ACCRecorderRedPacketProtocol_h

@class VEPathBuffer;

@protocol ACCRecorderRedPacketProtocol<NSObject>

- (void)enableTC21RedpackageRecord:(BOOL)enable;
- (void)getTC21RedpakageTracker:(NSString *)key
               queryPathHandler:(void (^)(VEPathBuffer *pathBuffer,
                                          double baseTime,
                                          double firstTriggerTime,
                                          double totalTriggerTime))queryPathHandler;

@end

#endif /* ACCRecorderRedPacketProtocol_h */
