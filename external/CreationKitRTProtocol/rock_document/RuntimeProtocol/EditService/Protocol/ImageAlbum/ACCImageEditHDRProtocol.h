//
//  ACCImageEditHDRProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/1/8.
//

#import <Foundation/Foundation.h>
#import "ACCEditWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCImageEditHDRProtocol <ACCEditWrapper>

- (void)setupLensHDRModelWithFilePath:(NSString *)filePath;

- (void)setHDREnable:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END
