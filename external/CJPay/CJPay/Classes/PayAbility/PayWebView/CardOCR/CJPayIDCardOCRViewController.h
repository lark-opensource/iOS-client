//
//  CJPayIDCardOCRViewController.h
//  CJPay
//
//  Created by youerwei on 2022/6/21.
//

#import "CJPayCardOCRViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayIDCardOCRScanStatus) {
    CJPayIDCardOCRScanStatusProfileSide = 0,
    CJPayIDCardOCRScanStatusEmblemSide
};

@interface CJPayIDCardOCRViewController : CJPayCardOCRViewController

// 图片压缩大小
@property (nonatomic, assign) NSUInteger compressSize;

@property (nonatomic, assign) BOOL isFxjCustomize;
@property (nonatomic, copy) NSString *frontRequestUrl;
@property (nonatomic, copy) NSString *backRequestUrl;
@property (nonatomic, copy) NSString *isecKey;

// 埋点
@property (nonatomic, assign) NSUInteger infoStauts;
@property (nonatomic, copy) NSString *idVerifySouce;
@property (nonatomic, copy) NSDictionary *extParams;

@end

NS_ASSUME_NONNULL_END
