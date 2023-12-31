//
//  IESEffectResourceModel.h
//  EffectPlatformSDK
//
//  Created by 赖霄冰 on 2019/8/8.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectResourceModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *value;
@property (nonatomic, readonly, copy) NSString *resourceURI;
@property (nonatomic, readonly, copy) NSArray<NSString *> *fileDownloadURLs;
@property (nonatomic, readonly, copy) NSString *filePath;

- (void)genFileDownloadURLsWithURLPrefixes:(NSArray<NSString *> *)urlPrefixes;

@end

NS_ASSUME_NONNULL_END
