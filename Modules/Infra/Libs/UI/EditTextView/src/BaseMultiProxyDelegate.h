//
//  BaseMultiProxyDelegate.h
//  EditTextView
//
//  Created by zc09v on 2020/7/1.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BaseMultiProxyDelegate : NSObject
- (instancetype)initThreadSafe;
- (void) unsafeAddDelegate:(id) delegate;
- (NSHashTable *)unsafeDelegates;
@end

NS_ASSUME_NONNULL_END
