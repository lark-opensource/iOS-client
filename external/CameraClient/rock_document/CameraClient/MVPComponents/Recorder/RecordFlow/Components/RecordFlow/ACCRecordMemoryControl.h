//
//  ACCRecordMemoryControl.h
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2021/4/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecordMemoryControl : NSObject

@property (nonatomic, weak) id recordController;
@property (nonatomic, copy) void(^cameraPureModeBlock)(BOOL pure);

@end

NS_ASSUME_NONNULL_END
