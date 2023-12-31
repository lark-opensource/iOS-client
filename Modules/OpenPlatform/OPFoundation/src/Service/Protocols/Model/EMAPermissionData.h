//
//  EMAPermissionData.h
//  Pods
//
//  Created by 武嘉晟 on 2019/4/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface EMAPermissionData : NSObject

@property (nonatomic, strong) NSString *scope;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) BOOL isGranted;
@property (nonatomic, assign) NSInteger mod; // mod 现在0是readOnly，1是readWrite
@end

NS_ASSUME_NONNULL_END
