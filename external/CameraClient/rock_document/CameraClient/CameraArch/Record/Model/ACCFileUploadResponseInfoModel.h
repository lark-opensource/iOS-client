//
//  ACCFileUploadResponseInfoModel.h
//  CameraClient-Pods-Aweme
//
//  Created by qiyang on 2021/2/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCFileUploadResponseInfoModel : NSObject

@property (nonatomic, copy) NSString *materialId;
@property (nonatomic, copy) NSString *tosKey;
@property (nonatomic, copy) NSString *coverURI;
@property (nonatomic, copy) NSDictionary *videoMediaInfo;

@end

NS_ASSUME_NONNULL_END
