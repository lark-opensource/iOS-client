//
//  ACCRepositoryWrapper.h
//  CreationKitArch-Pods-Aweme
//
//  Created by liyingpeng on 2021/4/22.
//

#import <Foundation/Foundation.h>
#import "ACCPublishRepository.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCRepositoryRegisterInfo : NSObject

@property (nonatomic, weak, readonly, nullable) ACCRepositoryRegisterInfo *childNode;
@property (nonatomic, weak, readonly, nullable) ACCRepositoryRegisterInfo *superNode;

@property (nonatomic, strong, nullable) Class classInfo;
@property (nonatomic, assign) BOOL initialWhenSetup;
- (instancetype)initWithClassInfo:(Class)classInfo;

@end

@interface ACCRepositoryWrapper : NSObject <ACCPublishRepository, NSCopying>

@property (nonatomic, strong, readonly) NSDictionary *registerNodeInfo;

- (void)insertRegisterInfo:(ACCRepositoryRegisterInfo *)registerInfo;

@end

NS_ASSUME_NONNULL_END
