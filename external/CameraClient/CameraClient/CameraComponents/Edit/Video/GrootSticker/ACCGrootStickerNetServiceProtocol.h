//
//  ACCGrootStickerNetServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/25.
//

#import <Foundation/Foundation.h>
#import <CameraClient/ACCGrootStickerModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCGrootStickerNetServiceProtocol <NSObject>

/*
*  获取生物识别一级模型
*/
- (void)requestCheckGrootRecognitionWith:(NSString *_Nonnull)zipUri creationId:(NSString *_Nonnull)creationId cameraDirection:(NSString *_Nullable)cameraDirection completion:(nonnull void(^)(ACCGrootCheckModel * _Nullable model, NSError * _Nullable error))completion;
 
/*
*  获取生物识二级级模型
*/
- (void)requestFetchGrootRecognitionListWith:(NSString *_Nonnull)zipUri creationId:(NSString *_Nonnull)creationId cameraDirection:(NSString *_Nullable)cameraDirection completion:(nonnull void(^)(ACCGrootListModel * _Nullable model, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
