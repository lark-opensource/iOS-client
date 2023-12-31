//
//	AWECloudCommandMultiData.h
// 	Heimdallr
// 	
// 	Created by Hayden on 2020/10/9. 
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWECloudCommandMultiData : NSObject

@property (nonatomic, copy) NSString *mimeType;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, copy) NSString *fileType;  // 目前支持json, log, xml, text

@end

NS_ASSUME_NONNULL_END
