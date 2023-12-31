//
//  ACCDUXProtocl.h
//  Aweme
//
//  Created by Daniel on 2021/10/28.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

@protocol ACCDUXProtocl

- (nullable UIImage *)generateIconImage:(nullable NSString *)imageName
                              imageSize:(CGSize)imageSize
                             imageColor:(nullable UIColor *)imageColor
                                 bundle:(nullable NSBundle *)bundle;

@end

FOUNDATION_STATIC_INLINE id<ACCDUXProtocl> ACCDUX() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCDUXProtocl)];
}
