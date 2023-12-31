//
//  ACCSwitchProtocol.h
//  Aweme
//
//  Created by Shichen Peng on 2021/10/29.
//

#ifndef ACCSwitchProtocol_h
#define ACCSwitchProtocol_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CreativeKit/ACCServiceLocator.h>

//用户选择前是否进行切换的回调block
typedef void(^ACCSwitchEnsureBlock)(BOOL ensure);
//需要用户选择后再进行切换的调用block
typedef void(^ACCSwitchChooseBlock)(BOOL willOn, ACCSwitchEnsureBlock switchEnsureBlock);


@protocol ACCSwitchProtocol <NSObject>

@property (nonatomic, copy, nullable) ACCSwitchChooseBlock chooseBeforeStatusChangeBlock;
@property (nonatomic, copy, nullable) void (^switchStatusChangedBlock)(BOOL isOn);
@property (nonatomic, assign) BOOL shouldChooseBeforeChange;
@property (nonatomic, assign) BOOL changeBlockNeedAnimation;

- (void)updateStatus;

- (void)setEnabled:(BOOL)enabled disableOpacity:(CGFloat)opacity;

- (UISwitch *)content;

@end


FOUNDATION_STATIC_INLINE id<ACCSwitchProtocol> ACCSwitch() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCSwitchProtocol)];
}
#endif /* ACCSwitchProtocol_h */
