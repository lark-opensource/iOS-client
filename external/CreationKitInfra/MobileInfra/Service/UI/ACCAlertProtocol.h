//
//  ACCAlertProtocol.h
//  CameraClient
//
//  Created by lxp on 2019/11/18.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCServiceLocator.h>

// Diffent kind of Action button style, can use this to determine the button display style
typedef NS_ENUM(NSInteger, ACCUIAlertActionStyle) {
    ACCUIAlertActionStyleDefault = 0,
    ACCUIAlertActionStyleCancel,
    ACCUIAlertActionStyleAction,
    ACCUIAlertActionStyleDestructive,
    ACCUIAlertActionStyleRecommended,
};

@protocol ACCUIAlertActionProtocol <NSObject>

/// Convenient method to get a instance that comform the ACCUIAlertActionProtocol.
/// @param title Title for the action button
/// @param style Style of the action button
/// @param handler Block for the action button, if the button clicked, the block will perform
+ (instancetype)actionWithTitle:(NSString *)title
                          style:(ACCUIAlertActionStyle)style
                        handler:(void (^ _Nullable)(void))handler;

@end

//                                 An example for alert view
//                          +-----------------------------------+
//                          |                                   |
//                          |                                   |
//                          |                                   |
//                          |            header image           |
//                          |                                   |
//                          |                                   |
//                          |                                   |
//                          +-----------------------------------+
//                          |                                   |
//                          |              title                |
//                          |                                   |
//                          +-----------------------------------+
//                          |                                   |
//                          |                                   |
//                          |              message              |
//                          |                                   |
//                          |                                   |
//                          +-----------------------------------+
//                          |                                   |
//                          |                                   |
//                          |               text                |
//                          |                                   |
//                          |                                   |
//                          +-----------------------------------+
//                          |                                   |
//                          |           action Buttons          |
//                          |                                   |
//                          +-----------------------------------+
//
@protocol ACCUIAlertViewProtocol <NSObject>

// Header image for the Alert View
@property (nonatomic, strong, nullable) UIImage *headerImage;
// Title for the Alert View
@property (nonatomic, copy, nullable) NSString *title;
// Message for the Alert View
@property (nonatomic, copy, nullable) NSString *message;
// Attributed Message for the Alert View
@property (nonatomic, copy, nullable) NSAttributedString *attributedMessage;

// Text View that display the extra text
@property (nonatomic, strong, readonly) UITextView *descriptionTextView;
// Should dismiss AlertView when tap blank area
@property (nonatomic, assign) BOOL dismissWhenTappedInBlankArea;
// The default button horizontal, which can be set to vertical, when the action button count greater than 3, the property must always return YES.
@property (nonatomic, assign) BOOL isButtonAlignedVertically;

/// Init a AlertView instance for max to two style
/// @param useModernStyle You can use this paremeter to determine which style you should init.
- (instancetype)initWithModernStyle:(BOOL)useModernStyle;

/// Add Action to the AlertView instance.
/// @param action action instance, the instance should comform to `ACCUIAlertActionProtocol`
- (void)addAction:(id<ACCUIAlertActionProtocol>)action;

/// Show the AlertView, you should implemete this method to show the AlertView instance on screen.
- (void)show;

- (void)dismiss:(BOOL)animated;

- (void)dismissSelfDefineAlert; // 直接调用AlertView的dismiss动画，不会调用findCancelActionAndExecute方法

@end

@protocol ACCAlertProtocol <NSObject>

/// Show UIAlertController instance with or without animation
/// @param alertController UIAlertController instance
/// @param animated Should UIAlertController instance be showed with animation
- (void)showAlertController:(UIAlertController *)alertController animated:(BOOL)animated;

/// UIAlertController instance with or without animation, this method can use show UIAlertController for iPad, as this method will provide the fromeView.
/// @param alertController UIAlertController instance
/// @param view which view will dispaly the UIAlertController instance
- (void)showAlertController:(UIAlertController *)alertController fromView:(UIView *)view;


/// Show AlertView, in this method implementation, you can provide you custom AlertView implementation.
/// Recommend to use the class show instance that comform the `ACCUIAlertViewProtocol`, then you can use this to show AlertView for two buttons conveniently.
/// @param title Title of the AlertView
/// @param description Description of the AlertView
/// @param image Image showed on the AlertView
/// @param actionButtonTitle Title for the action button
/// @param cancelButtonTitle Title for the cancel button
/// @param actionBlock Block for the action button, if the action button clicked, the block will perform
/// @param cancelBlock Block for the cancel button, if the cancel button clicked, the block will perform
- (void)showAlertWithTitle:(NSString *)title
               description:(NSString *)description
                     image:(nullable UIImage *)image
         actionButtonTitle:(NSString *)actionButtonTitle
         cancelButtonTitle:(NSString *)cancelButtonTitle
               actionBlock:(void (^_Nullable)(void))actionBlock
               cancelBlock:(void (^_Nullable)(void))cancelBlock;

@optional

/// Get a instance that comform the ACCUIAlertViewProtocol, you can then modify some properties as you need.
- (id<ACCUIAlertViewProtocol>)alertView;

/// Get a instance that comform the ACCUIAlertActionProtocol.
/// You can provide the title of the instance, the style of the action button and the action handler for the action button.
/// @param title Title for the action button
/// @param style Style of the action button
/// @param handler Block for the action button, if the button clicked, the block will perform
- (id<ACCUIAlertActionProtocol>)alertActionWithTitle:(NSString *)title
                                               style:(ACCUIAlertActionStyle)style
                                             handler:(void (^ _Nullable)(void))handler;

@end

FOUNDATION_STATIC_INLINE id<ACCAlertProtocol> ACCAlert() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCAlertProtocol)];
}
