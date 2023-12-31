//
//  ACCTextViewProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yuanchang on 2020/9/10.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSRange(^accExceptionRangeBlock)(void);

@protocol ACCTextViewProtocol <NSObject>

@property (nonatomic, copy) accExceptionRangeBlock exceptionRange;

- (UITextView *)textView;

@end

FOUNDATION_STATIC_INLINE id<ACCTextViewProtocol> ACCTextView() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCTextViewProtocol)];
}

NS_ASSUME_NONNULL_END
