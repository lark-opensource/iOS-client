//
//  HMDNetworkUploadModel.h
//  Heimdallr
//
//  Created by fengyadong on 2021/5/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDNetworkUploadModel : NSObject

@property (nonatomic, copy) NSString *uploadURL;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *headerField;
@property (nonatomic, assign) BOOL isManualTriggered;

@end

NS_ASSUME_NONNULL_END
