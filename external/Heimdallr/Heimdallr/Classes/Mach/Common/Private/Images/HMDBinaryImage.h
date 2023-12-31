//
//  HMDBinaryImage.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/25.
//

#import <Foundation/Foundation.h>


@interface HMDBinaryImage : NSObject

typedef void(^HMDBinaryImageBlock)(HMDBinaryImage * _Nonnull image);
typedef void(^HMDBinaryImageStrLogBlock)(NSString * _Nonnull log);

@property(nonatomic, assign) uint64_t address;
@property(nonatomic, assign) uint64_t textSize;     // 这个是 "TEXT" 的大小，不是 "TEXT.text"
@property(nonatomic, assign) uint64_t vm_slide;     // 这个是 随机偏移量大小，对外导出要用到
@property(nonatomic, assign) BOOL isExecutable;
@property(nonatomic, copy) NSString * _Nullable name;
@property(nonatomic, copy) NSString * _Nullable uuid;
@property(nonatomic, assign) int cpuType;
@property(nonatomic, assign) int cpuSubType;
@property(nonatomic, copy) NSString * _Nullable path;
@property(nonatomic, assign) BOOL isFromAPP;


/*!
    @method linkedBinaryImages:
    @abstract get image info array, convert c link list to OC array.
    @return null if error, otherwise all binary image info.
    @discussion hmd get image info by _dyld_register_func_for_add_image and save as c link list, this func convert c link list to OC array.
    This method is inefficient and will be deprecated in a future version.
*/
+ (NSArray<HMDBinaryImage *> *_Nullable)linkedBinaryImages;

/*!
    @method findSharedCacheImages:
    @abstract find shared cache in linked binary images
    @param images where to find images
    @return null if error, otherwise the sharedImages
    @discussion the ideal behind the method is that, it tries to locate images with same vm_slides.
    if you want to get all sharedImages, use findSharedCacheImages.
*/
+ (NSSet<HMDBinaryImage *> * _Nullable)findSharedCacheImages:(NSArray<HMDBinaryImage *> * _Nonnull)images;


/*!
    @method updateSharedLinkedBinaryImagesIfNeed:
    @abstract Optimize time consumption through a shared image.
    @discussion only update the shared image when the image info changes.
*/
+ (void)updateSharedLinkedBinaryImagesIfNeed;

+ (void)enumerateImagesUsingBlock:(HMDBinaryImageBlock _Nullable )block;

+ (NSSet<HMDBinaryImage *> * _Nullable)findSharedCacheImages;

/*!
    @method binaryImagesLogStr:
    @abstract get a formatted image list log.
    @return null if error, otherwise new image list log.
    @discussion reformat a new log, which will be time-consuming, it is recommended to use getSharedBinaryImagesLogStrUsingCallback
*/
+ (NSString * _Nonnull)binaryImagesLogStr;

/*!
    @method binaryImagesLogStrWithValidImages:includePossibleJailbreakImage:
    @abstract generate binaryImageLog
    cached response, and client.
    @param imageSet The must included images name @[ NSString ]
    @param needJailbreakIncluded should we include possible jailbreak lib
    @return the Log string If possible
    @discussion underline using lsdr decide whether it is jailbreak possible.
*/
+ (NSString * _Nonnull)binaryImagesLogStrWithMustIncludeImagesNames:(NSMutableSet<NSString*>* _Nonnull)imageSet
                             includePossibleJailbreakImage:(BOOL)needJailbreakIncluded;

+ (void)getSharedBinaryImagesLogStrUsingCallback:(HMDBinaryImageStrLogBlock _Nullable )block;

@end
