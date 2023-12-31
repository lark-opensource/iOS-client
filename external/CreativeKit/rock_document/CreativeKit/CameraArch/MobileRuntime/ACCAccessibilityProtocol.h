//
//  ACCAccessibilityProtocol.h
//  CreativeKit-Pods-Aweme
//
//  Created by Daniel on 2021/7/12.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - ACCAccessibilityProtocol

@protocol ACCAccessibilityProtocol <NSObject>

@optional

/// Check if VoiceOver is running.
- (BOOL)isVoiceOverOn;

/// Set accessibilityLabel and accesibilityTraits for a given object, will set target's isAccessibilityElement to YES.
/// @param target target
/// @param traits accessibilityTraits UIAccessibilityTraits
/// @param label accessibilityLabel (NSString *)
- (void)enableAccessibility:(NSObject *)target
                     traits:(UIAccessibilityTraits)traits
                      label:(nullable NSString *)label;

/// Set target's isAccessibilityElement
/// @param target target
/// @param isAccessibilityElement BOOL
- (void)setAccessibilityProperty:(NSObject *)target
          isAccessibilityElement:(BOOL)isAccessibilityElement;

/// Set target's isAccessibilityElement
/// @param target target
/// @param accessibilityValue BOOL
- (void)setAccessibilityProperty:(NSObject *)target
              accessibilityValue:(nullable NSString *)accessibilityValue;

/// Set target's accessibilityViewIsModal
/// @param target target
/// @param accessibilityViewIsModal BOOL
- (void)setAccessibilityProperty:(NSObject *)target
        accessibilityViewIsModal:(BOOL)accessibilityViewIsModal;

- (void)postAccessibilityNotification:(UIAccessibilityNotifications)notification
                             argument:(__nullable id)argument;

@end

#pragma mark - Dependency Injection

FOUNDATION_STATIC_INLINE id<ACCAccessibilityProtocol> ACCAccessibility() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCAccessibilityProtocol)];
}

NS_ASSUME_NONNULL_END
