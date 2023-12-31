//
//  ACCTapicEngineProtocol.h
//  Aweme
//
//  Created by Shichen Peng on 2021/9/29.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

#ifndef ACCTapicEngineProtocol_h
#define ACCTapicEngineProtocol_h

typedef NS_ENUM(NSInteger, ACCHapticType) {
    ACCHapticTypeSuccess = 0,
    ACCHapticTypeWarning,
    ACCHapticTypeError,
    ACCHapticTypeImpactHeavy,
    ACCHapticTypeImpactMedium,
    ACCHapticTypeImpactLight,
    ACCHapticTypeImpactRigid,
    ACCHapticTypeImpactSoft,
    ACCHapticTypeSelected,
    ACCHapticTypeLightSuccess
};

@protocol ACCTapicEngineProtocol <NSObject>

- (void)triggerWithType:(ACCHapticType)type;

@end

FOUNDATION_STATIC_INLINE id<ACCTapicEngineProtocol> ACCTapicEngine() {
    return [ACCBaseContainer() resolveObject:@protocol(ACCTapicEngineProtocol)];
}

#endif /* ACCTapicEngineProtocol_h */
