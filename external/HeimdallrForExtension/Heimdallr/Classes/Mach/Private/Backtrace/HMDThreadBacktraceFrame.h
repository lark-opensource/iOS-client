//
//  HMDThreadBacktraceFrame.h
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/5/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDThreadBacktraceFrame : NSObject

@property(nonatomic, assign) NSUInteger stackIndex;
@property(nonatomic, assign) uintptr_t address;

@property(nonatomic, assign) uintptr_t imageAddress;
@property(nonatomic, copy) NSString *imageName;

@property(nonatomic, assign) uintptr_t symbolAddress;
@property(nonatomic, copy) NSString *symbolName;

- (BOOL)symbolicate:(bool)needSymbolName;
- (BOOL)isAppAddress;

@end

NS_ASSUME_NONNULL_END
