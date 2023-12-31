//
//  LVDraftVideoMaskPayload.h
//  LVTemplate
//
//  Created by xiongzhuang on 2020/2/7.
//

#import "LVDraftPayload.h"
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN


/**
蒙版资源类型

- LVDraftVideoMaskPayloadResourceTypeNone: 无
- LVDraftVideoMaskPayloadResourceTypeLine: 线性
- LVDraftVideoMaskPayloadResourceTypeMirror: 镜面
- LVDraftVideoMaskPayloadResourceTypeCircle: 圆
- LVDraftVideoMaskPayloadResourceTypeRectangle: 矩形
- LVDraftVideoMaskPayloadResourceTypeGeometricShape: 矢量图形
*/
typedef NS_ENUM(NSUInteger, LVDraftVideoMaskPayloadResourceType) {
    LVDraftVideoMaskPayloadResourceTypeNone = 1,
    LVDraftVideoMaskPayloadResourceTypeLine,
    LVDraftVideoMaskPayloadResourceTypeMirror,
    LVDraftVideoMaskPayloadResourceTypeCircle,
    LVDraftVideoMaskPayloadResourceTypeRectangle,
    LVDraftVideoMaskPayloadResourceTypeGeometricShape
};

@interface LVVideoMaskConfig (Interface)<LVCopying>

/**
mask的中心点坐标
*/
@property (nonatomic, assign) CGPoint center;

/**
羽化值
*/
@property (nonatomic, assign) CGFloat eclosion;


/**
蒙版适配矢量图的宽高比得到的宽、高
*/
- (CGSize)aspectSizeWith:(CGSize)videoSize;

- (instancetype)initWithBorderSize:(CGSize)borderSize;

@end



/**
蒙版素材（视频蒙版）解析模型
*/
@interface LVDraftVideoMaskPayload (Interface)

/**
 文件路径，注意：这个路径应该是草稿目录下的相对路径
 */
@property (nonatomic, copy, nonnull) NSString *relativePath;

/**
资源蒙版的类型
*/
@property (nonatomic, assign) LVDraftVideoMaskPayloadResourceType resourceType;


/**
 初始化特效
 
 @param type 素材类型
 @param resourceID 特效资源ID
 @param path 特效路径
 @param name 特效名称
 @param resourceType 蒙版的类型
 @param platformSupport 平台支持
 @param resourceMD5 资源的MD5值
 @return 特效实例
 */
- (instancetype)initWithType:(LVPayloadRealType)type
                  resourceID:(NSString *)resourceID
                    rootPath:(NSString *)rootPath
                        path:(NSString *)path
                        name:(NSString *)name
                resourceType:(LVDraftVideoMaskPayloadResourceType)resourceType
             platformSupport:(LVMutablePayloadPlatformSupport)platformSupport
                 resourceMD5:(NSString *)resourceMD5;

/**
 资源绝对路径
 */
- (NSString *)absolutePath;

@end

NS_ASSUME_NONNULL_END
