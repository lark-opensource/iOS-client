//
//  QRCodeDecoder.h
//  LarkWeb
//
//  Created by CharlieSu on 2018/11/26.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, QRCodeScanResultType) {
    QRCodeScanResultTypeNotFound,  // 未检测到结果
    QRCodeScanResultTypeZoom,  // 需要放大
    QRCodeScanResultTypeFound, //  搜索到结果
};

typedef NS_OPTIONS(NSUInteger, QRCodeDecoderType) {
    QRCodeDecoderTypeQR = 1 << 0,
    QRCodeDecoderTypeBar = 1 << 1,
    QRCodeDecoderTypeImage = 1 << 2, //识别图片中二维码
};

@interface QRCodeScanResult: NSObject

@property(nonatomic, nullable, copy) NSString* code;
@property(nonatomic, nullable, strong) NSNumber* resizeFactor;
@property(nonatomic, assign) QRCodeScanResultType type;

@end

@interface QRCodeDecoder: NSObject

- (nonnull QRCodeScanResult*)scanImage: (nonnull UIImage*)image;
- (nonnull QRCodeScanResult*)scanVideoPixelBuffer: (nullable CVPixelBufferRef)pixelBuffer;

- (_Nullable instancetype)initWithType:(QRCodeDecoderType)type;

@end
