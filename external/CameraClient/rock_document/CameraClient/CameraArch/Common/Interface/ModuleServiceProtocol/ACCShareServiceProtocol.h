//
//  ACCShareServiceProtocol.h
//  Indexer
//
//  Created by xiafeiyu on 11/9/21.
//

#import <Foundation/Foundation.h>

#import <CreativeKit/ACCServiceLocator.h>

@protocol ACCShareServiceProtocol <NSObject>

- (UIImage *)rebrandUserQRCodeImageWithContext:(nullable id)context
                                   qrCodeImage:(nullable UIImage *)qrCodeImage
                                 templateModel:(nullable id)templateModel;

- (id)shareContextWithUser:(nullable id)userModel;

@end

FOUNDATION_STATIC_INLINE id<ACCShareServiceProtocol> ACCShareService() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCShareServiceProtocol)];
}
