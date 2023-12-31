//
//  LVDraftPayloadTypeHelper.h
//  longVideo
//
//  Created by xiongzhuang on 2019/7/19.
//

#import <Foundation/Foundation.h>
#import "LVModelType.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVDraftPayloadTypeHelper : NSObject


+ (LVPayloadRealType)payloadTypeFromString:(NSString *)typeString;

+ (NSString *)stringFromPayloadType:(LVPayloadRealType)type;

/**
 获取type对应素材文件后缀名称

 @param type 素材类型
 @return 文件后缀名称
 */
+ (NSString * _Nonnull)fileSuffixOfType:(LVPayloadRealType)type;


/**
 获取type对应素材文件存储父路径
 
 @param type 素材类型
 @return 文件后缀名称
 */
+ (NSString * _Nonnull)folderNameOfType:(LVPayloadRealType)type;

/**
获取panel对应素材文件存储父路径

@param panel 面板
@return 文件后缀名称
*/
+ (NSString * _Nonnull)folderNameOfPanel:(NSString *)panel;

/**
资源标志路径

@param isRevered 是否倒放资源
@param audioStrong 是否降噪
@return 资源标志路径
*/
+ (NSString * _Nonnull)specificPathWithIsRevered:(BOOL)isRevered isAudioStrong:(BOOL)audioStrong;

/**
 资源路径

 @param type 类型
 @param payloadID 资源ID
 @param isRevered 是否倒放资源
 @param audioStrong 是否降噪
 @param pathExtension 文件后缀
 @return 资源路径
 */
+ (NSString * _Nonnull)pathOfType:(LVPayloadRealType)type resourceID:(NSString *)resourceID isRevered:(BOOL)isRevered isAudioStrong:(BOOL)audioStrong pathExtension:(NSString *)pathExtension;

/**
 降噪音频资源路径
 
 @param type 类型
 @param payloadID 资源ID
  */
+ (NSString * _Nonnull)pathForAudioStrongOfType:(LVPayloadRealType)type resourceID:(NSString *)resourceID;

/**
 资源路径

 @param type 类型
 @param payloadID 资源ID
 @return 资源路径
 */
+ (NSString * _Nonnull)pathOfType:(LVPayloadRealType)type resourceID:(NSString *)resourceID;

/**
玩法资源路径

@param type 类型
@param tag 特殊标记
@param payloadID 资源ID
@return 资源路径
*/
+ (NSString * _Nonnull)pathForGameplayOfType:(LVPayloadRealType)type specificTag:(NSString *)tag resourceID:(NSString *)resourceID;

@end

NS_ASSUME_NONNULL_END
