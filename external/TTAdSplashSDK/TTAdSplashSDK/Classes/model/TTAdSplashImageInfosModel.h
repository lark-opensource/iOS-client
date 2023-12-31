//
//  TTAdSplashImageInfosModel
//  Article
//
//  Created by Zhang Leonardo on 12-12-5.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#define TTAdSplashImageInfosModelURL @"url"
#define TTAdSplashImageInfosModelHeader @"header"


/**
 *  图片的类型
 */
typedef NS_ENUM(NSUInteger, TTAdSplashImageType)
{
    /**
     *  未指定（默认）
     */
    TTAdSplashImageTypeNotAssign = 0,
    /**
     *  小图
     */
    TTAdSplashImageTypeThumb = 1,
    /**
     *  中图
     */
    TTAdSplashImageTypeMiddle = 2,
    /**
     *  大图
     */
    TTAdSplashImageTypeLarge = 3,
};

typedef NS_ENUM(NSUInteger, TTAdSplashImageFileType)
{
    TTAdSplashImageFileTypeNotAssign = 0,
    TTAdSplashImageFileTypeJPEG = 1,
    TTAdSplashImageFileTypeGIF = 2,
    TTAdSplashImageFileTypeBMP = 3,
    TTAdSplashImageFileTypePNG = 4,
};

@interface TTAdSplashImageInfosModel : NSObject<NSCoding>

@property (nonatomic, copy) NSString *URI;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, strong) NSArray *urlWithHeader;
@property (nonatomic, strong) NSDictionary *userInfo;    //内存存储，不序列化
@property (nonatomic, assign) TTAdSplashImageType imageType;      //图片类型，内存存储，不序列化，默认TTAdSplashImageTypeNotAssign

@property (nonatomic, assign) TTAdSplashImageFileType imageFileType; //目前只对thumbImage有效，该property指的是其对应的largeImage的filetype

@property (nonatomic, copy) NSString *uriOriginal;  //用于下发非加密的数据

@property (nonatomic, copy) NSArray *urlListOriginal;  //用于下发非加密的数据
/**
 *  added 5.2.1: 用于图片点击对应的schema url
 */
@property (nonatomic, copy) NSString *openURL;

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;

/**
 *  构造一个只有一个url的Model。URI同URL。width,height都为0
 *
 *  @param URL 图片的URL
 *
 *  @return 如果URL不为nil，将返回一个只有一个URL的Model，否则返回nil
 */
- (instancetype)initWithURL:(NSString *)URL;

/**
 *  返回第index位置的url
 *
 *  @param index urlWithHeader的index
 *
 *  @return 如果有index位置的URL，将返回该URL（NSString）；如果没有， 将返回nil
 */
- (NSString *)urlStringAtIndex:(NSUInteger)index;

/**
 *  返回非加密图片第index位置的url
 *
 *  @param index _urlListOriginal的index
 *
 *  @return 如果有index位置的URL，将返回该URL（NSString）；如果没有， 将返回nil
 */
- (NSString *)originalUrlStringAtIndex:(NSUInteger)index;


///put it here for a while may be deleted later-- nick
- (instancetype)initWithURL:(NSString *)URL withHeader:(NSDictionary *)header;


+ (BOOL)isImageInfosModel:(TTAdSplashImageInfosModel *)model1 equalesToModel:(TTAdSplashImageInfosModel *)model2;

- (BOOL)isValidModel;

@end
