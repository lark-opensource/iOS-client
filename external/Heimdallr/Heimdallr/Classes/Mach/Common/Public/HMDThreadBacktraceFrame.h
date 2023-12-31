//
//  HMDThreadBacktraceFrame.h
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/5/8.
//

#import <Foundation/Foundation.h>


@interface HMDThreadBacktraceFrame : NSObject

@property(nonatomic, assign) NSUInteger stackIndex;
@property(nonatomic, assign) uintptr_t address;

@property(nonatomic, assign) uintptr_t imageAddress;
@property(nonatomic, copy, nullable) NSString *imageName;

@property(nonatomic, assign) uintptr_t symbolAddress;
@property(nonatomic, copy, nullable) NSString *symbolName;

- (BOOL)symbolicate:(bool)needSymbolName;
- (BOOL)isAppAddress;

@end
