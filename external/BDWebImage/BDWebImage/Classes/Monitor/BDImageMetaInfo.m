//
//  BDImageMetaInfo.m
//  BDWebImage
//
//  Created by wby on 2021/9/13.
//

#import "BDImageMetaInfo.h"
#import "BDWebImageRequest.h"
#import "BDImageLargeSizeMonitor.h"
#import "BDImageDecoderFactory.h"

@implementation BDImageMetaInfo

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.webURL = @"";
  }
  return self;
}

- (instancetype)initWithRequest:(BDWebImageRequest *)request data:(NSData *)data{
    self = [super init];
    if (self) {
        self.fileSize = data.length;
        self.webURL = request.currentRequestURL.absoluteString;
        self.requestView = request.largeImageMonitor.requestView;
        [self memoryCostInfo:data];
    }
    return self;
}

- (void)memoryCostInfo:(NSData *)data{
    if (data.length == 0) {
        return;
    }
    BDImageCodeType type = BDImageCodeTypeUnknown;
    Class decoderClass = [BDImageDecoderFactory decoderForImageData:data type:&type];
    if (!decoderClass) {
        return;
    }
    id<BDImageDecoder> decoder = [[decoderClass alloc] initWithData:data];
    self.width = decoder.originSize.width;
    self.height = decoder.originSize.height;
    self.memoryFootprint = _width * _height * decoder.imageCount * 4;
}

@end
