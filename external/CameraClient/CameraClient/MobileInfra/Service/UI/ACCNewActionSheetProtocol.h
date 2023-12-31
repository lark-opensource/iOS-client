//
//  ACCNewActionSheetProtocol.h
//  CameraClient
//
//  Created by ZZZ on 2021/3/28.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCServiceLocator.h>

// 适配有多个 ActionSheet 的场景
@protocol ACCNewActionSheetProtocol <NSObject>

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) void (^cancelHandler)(void);

- (void)addActionWithTitle:(NSString *)title handler:(void (^)(void))handler;

- (void)addActionWithTitle:(NSString *)title subtitle:(NSString *)subtitle handler:(void (^)(void))handler;

- (void)addActionWithTitle:(NSString *)title subtitle:(NSString *)subtitle highlighted:(BOOL)highlighted handler:(void (^)(void))handler;

- (void)show;

- (void)dismiss;

@end

FOUNDATION_STATIC_INLINE id<ACCNewActionSheetProtocol> ACCNewActionSheet() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCNewActionSheetProtocol)];
}
