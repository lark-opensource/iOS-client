//
//  BDUGImageQRCodeAnalysisManager.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/19.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BDUGImageAnalysisResultModel : NSObject

@property (nonatomic, copy) NSString *resultString;

@end

typedef void(^BDUGImageAnalysisResultBlock)(BDUGImageAnalysisResultModel *model);

@interface BDUGImageQRCodeAnalysisManager : NSObject

+ (void)imageAnalysisRegisterWithPermissionAlert:(BOOL)permissionAlert
                                     dialogBlock:(BDUGImageAnalysisResultBlock)dialogBlock;

+ (void)imageAnalysisRegisterWithPermissionAlert:(BOOL)permissionAlert
                                notificationName:(NSString *)notificationName
                                     dialogBlock:(BDUGImageAnalysisResultBlock)dialogBlock;

@end

