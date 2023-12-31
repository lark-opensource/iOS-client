//
//  IESLiveResourceBundle+File.h
//  IESLiveResourcesButler
//
//  Created by lishuangyang on 2019/5/28.
//

#import "IESLiveResouceBundle.h"

@interface IESLiveResouceBundle (File)

- (NSString * (^)(NSString *key))filePath;

- (NSString * (^)(NSString *key, NSString *folder))filePathInfolder;

- (NSString * (^)(NSString *key))bundlePath;

@end

