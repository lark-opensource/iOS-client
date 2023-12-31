//
//  HMDImageLog.h
//  Heimdallr
//
//  Created by 谢俊逸 on 12/3/2018.
//

#import <Foundation/Foundation.h>
#import <mach/machine.h>
@class HMDBinaryImage;

@interface HMDImageLog : NSObject

//these method is inefficient and will be deprecated in a future version.

//Please use binaryImagesLogStr in HMDBinaryImage.h instead
+ (NSString * _Nullable)imageLogStringWithImageInfo:(HMDBinaryImage * _Nullable)info;
+ (NSString * _Nonnull)binaryImagesLogStr;

/*!
    @method binaryImagesLogStrWithValidImages:includePossibleJailbreakImage:
    @abstract generate binaryImageLog
    cached response, and client.
    @param imageSet The must included images name @[ NSString ]
    @param jailbreakIncluded should we include possible jailbreak lib
    @return the Log string If possible
    @discussion underline using lsdr decide whether it is jailbreak possible. Please use binaryImagesLogStrWithMustIncludeImagesNames: instead
*/

+ (NSString * _Nonnull)binaryImagesLogStrWithMustIncludeImagesNames:(NSMutableSet<NSString*>* _Nonnull)imageSet
                                     includePossibleJailbreakImage:(BOOL)jailbreakIncluded;
@end
