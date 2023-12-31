//
//  ACCMessageFilterable.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/7/18.
//

#ifndef ACCMessageFilterable_h
#define ACCMessageFilterable_h

@protocol ACCMessageFilterDelegate <NSObject>

-(BOOL)shouldTransferMessage:(nullable IESMMEffectMessage *)message;

@end

@protocol ACCMessageFilterable

@optional
@property (nonatomic, weak, nullable)  id<ACCMessageFilterDelegate> messageFilter;

@end



#endif /* ACCMessageFilterable_h */
