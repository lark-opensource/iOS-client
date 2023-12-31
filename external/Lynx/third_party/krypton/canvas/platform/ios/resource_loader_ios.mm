// Copyright 2021 The Lynx Authors. All rights reserved.

#import <Accelerate/Accelerate.h>
#import "KryptonLoaderService.h"

#include "canvas/base/data_holder.h"
#include "canvas/base/log.h"
#include "canvas/util/utils.h"
#include "resource_loader_ios.h"
#include "shell/ios/js_proxy_darwin.h"

@interface KryptonStreamLoadDelegateImpl : NSObject <KryptonStreamLoadDelegate>
@property(nonatomic) lynx::canvas::StreamLoadDataCallback callback;
@end

@implementation KryptonStreamLoadDelegateImpl
- (void)onStart:(NSInteger)contentLength {
  if (!_callback) {
    return;
  }
  if (contentLength < 0) {
    _callback(lynx::canvas::STREAM_LOAD_START, nullptr);
    return;
  }

  auto start_data = std::make_unique<lynx::canvas::RawData>();
  start_data->length = contentLength;
  _callback(lynx::canvas::STREAM_LOAD_START, std::move(start_data));
}

- (void)onData:(NSData*)data {
  if (!_callback || !data) {
    return;
  }

  auto raw_data = std::make_unique<lynx::canvas::RawData>();
  raw_data->length = [data length];
  raw_data->data = std::unique_ptr<lynx::canvas::DataHolder>(
      lynx::canvas::DataHolder::MakeWithCopy([data bytes], [data length]));
  _callback(lynx::canvas::STREAM_LOAD_DATA, std::move(raw_data));
}

- (void)onEnd {
  if (_callback) {
    _callback(lynx::canvas::STREAM_LOAD_SUCCESS_END, nullptr);
    _callback = nullptr;
  }
}

- (void)onError:(NSString*)msg {
  KRYPTON_LOGI("LynxResourceLoadDelegateImpl error ") << [msg UTF8String];

  if (_callback) {
    _callback(lynx::canvas::STREAM_LOAD_ERROR_END, nullptr);
    _callback = nullptr;
  }
}

@end

namespace lynx {
namespace canvas {

static std::unique_ptr<Bitmap> DecodeCGImageToBitmapBufferFor32BitFormat(CGImageRef ref) {
  if (!ref) {
    return nullptr;
  }

  size_t width = CGImageGetWidth(ref);
  size_t height = CGImageGetHeight(ref);
  if (width == 0 || height == 0) {
    return nullptr;
  }

  CGContextRef context = NULL;
  do {
    CGBitmapInfo contextBitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    context = CGBitmapContextCreate(NULL, width, height, 8, width * 4,
                                    CGColorSpaceCreateDeviceRGB(), contextBitmapInfo);
    if (!context) {
      break;
    }

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), ref);
    size_t bpr = CGBitmapContextGetBytesPerRow(context);
    size_t length = height * bpr;
    void* data = CGBitmapContextGetData(context);
    if (length == 0 || !data) {
      break;
    }

    auto holder =
        DataHolder::MakeWithReleaseProc(data, length, context, [](const void* ptr, void* ctx) {
          CGContextRef cgCtx = static_cast<CGContextRef>(ctx);
          CFRelease(cgCtx);
        });
    auto res = std::make_unique<Bitmap>(width, height, GL_RGBA, GL_UNSIGNED_BYTE, std::move(holder),
                                        1, true);

    return res;
  } while (0);

  if (context) {
    CFRelease(context);
  }
  return nullptr;
}

static void DecodeDataToBitmapBufferFor32BitFormat(
    const std::string& path, NSData* data, std::function<void(std::unique_ptr<Bitmap>)> callback,
    id<KryptonLoaderService> loader) {
  UIImage* image = [UIImage imageWithData:data];
  if (!image) {
    // try to decode image by external decoder.
    if ([loader respondsToSelector:@selector(loadImageData:)]) {
      image = [loader loadImageData:data];
    }
  }
  auto res = DecodeCGImageToBitmapBufferFor32BitFormat(image.CGImage);
  if (!res) {
    KRYPTON_LOGI("decode image failed! ") << "data length: " << [data length] << " path: " << path;
    callback(nullptr);
    return;
  }
  if (!path.empty() && [loader respondsToSelector:@selector(reportLoaderTrackEvent:format:data:)]) {
    NSString* image_url = [NSString
        stringWithFormat:@"canvas: %@", [NSString stringWithCString:path.c_str()
                                                           encoding:NSUTF8StringEncoding]];
    NSDictionary* reportData = @{
      @"image_url" : image_url ?: @"",
      @"memoryCost" : @(res->BytesPerRow() * res->Height()),
    };
    [loader reportLoaderTrackEvent:@"image_request" format:@"image info: %@" data:reportData];
  }

  callback(std::move(res));
}

void ResourceLoaderIOS::LoadData(const std::string& path, LoadRawDataCallback callback) {
  InternalLoad(path, [callback](NSData* data) {
    if (!data) {
      callback(nullptr);
      return;
    }

    auto raw_data = std::make_unique<RawData>();
    raw_data->data =
        std::unique_ptr<DataHolder>(DataHolder::MakeWithCopy([data bytes], [data length]));
    raw_data->length = [data length];
    callback(std::move(raw_data));
  });
}

void ResourceLoaderIOS::LoadBitmap(const std::string& path, LoadBitmapCallback callback) {
  id<KryptonLoaderService> loader = [app_ getService:@protocol(KryptonLoaderService)];
  InternalLoad(path, [path, callback, loader](NSData* data) {
    if (!data) {
      callback(nullptr);
      return;
    }

    DecodeDataToBitmapBufferFor32BitFormat(path, data, callback, loader);
  });
}

void ResourceLoaderIOS::StreamLoadData(const std::string& path, StreamLoadDataCallback callback) {
  InternalLoad(
      path,
      [callback](NSData* data) {
        if (!data) {
          callback(STREAM_LOAD_START, nullptr);
          callback(STREAM_LOAD_ERROR_END, nullptr);
          return;
        }

        auto start_data = std::make_unique<RawData>();
        start_data->length = [data length];
        callback(STREAM_LOAD_START, std::move(start_data));

        auto raw_data = std::make_unique<RawData>();
        raw_data->length = [data length];
        raw_data->data =
            std::unique_ptr<DataHolder>(DataHolder::MakeWithCopy([data bytes], [data length]));
        callback(STREAM_LOAD_DATA, std::move(raw_data));

        callback(STREAM_LOAD_SUCCESS_END, nullptr);
      },
      callback);
}

std::unique_ptr<Bitmap> ResourceLoaderIOS::DecodeDataURLSync(const std::string& data_url) {
  NSString* url = [NSString stringWithCString:data_url.c_str() encoding:NSUTF8StringEncoding];
  NSString* log_url = [url description];
  if (log_url.length > 40) {
    log_url = [log_url substringToIndex:40];
  }
  KRYPTON_LOGI("decode dataurl ") << ([log_url UTF8String] ?: "");

  NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
  if (!data) {
    KRYPTON_LOGE("decode dataurl failed ");
    return nullptr;
  }

  UIImage* image = [UIImage imageWithData:data];
  return DecodeCGImageToBitmapBufferFor32BitFormat(image.CGImage);
}

static dispatch_block_t LoadDataFallback(NSURL* url, std::function<void(NSData*)> callback) {
  NSString* log_url = [url description];
  if (log_url.length > 40) {
    log_url = [log_url substringToIndex:40];
  }
  KRYPTON_LOGI("load data fallback ") << ([log_url UTF8String] ?: "");
  NSURLSessionDataTask* task = [NSURLSession.sharedSession
        dataTaskWithURL:url
      completionHandler:^(NSData* received, NSURLResponse* response, NSError* error) {
        KRYPTON_LOGI("load data fallback complete");
        if (error) {
          callback(nullptr);
        } else {
          callback(received);
        }
      }];
  [task resume];
  return ^{
    [task cancel];
  };
}

std::unique_ptr<RawData> ResourceLoaderIOS::EncodeBitmap(const Bitmap& bitmap, ImageType type,
                                                         double encoderOptions) {
  CGDataProviderRef data =
      CGDataProviderCreateWithData(nullptr, bitmap.Pixels(), bitmap.PixelsLen(), nullptr);
  CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
  CGImageRef image = CGImageCreate(bitmap.Width(), bitmap.Height(), 8, 32, bitmap.BytesPerRow(),
                                   rgb, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                   data, nullptr, false, kCGRenderingIntentDefault);

  CFMutableDataRef output = CFDataCreateMutable(nullptr, 0);
  CFStringRef uti;
  if (type == ImageType::PNG) {
    uti = CFSTR("public.png");
  } else {
    uti = CFSTR("public.jpeg");
  }  /// TODO: support other image type

  CGImageDestinationRef dest = CGImageDestinationCreateWithData(output, uti, 1, nullptr);
  CGImageDestinationAddImage(dest, image, nullptr);
  CGImageDestinationFinalize(dest);
  CFRelease(dest);
  CGImageRelease(image);
  CGColorSpaceRelease(rgb);
  CGDataProviderRelease(data);

  auto bytes = CFDataGetBytePtr(output);
  size_t length = CFDataGetLength(output);
  auto raw_data = std::make_unique<RawData>();
  raw_data->data = DataHolder::MakeWithReleaseProc(bytes, length, output,
                                                   [](const void* data_ptr, void* context) {
                                                     if (context) {
                                                       CFRelease(context);
                                                     }
                                                   });
  raw_data->length = length;

  return raw_data;
};

void ResourceLoaderIOS::InternalLoad(const std::string& path, std::function<void(NSData*)> callback,
                                     StreamLoadDataCallback stream_load_callback) {
  if (path.empty()) {
    KRYPTON_LOGI("internalLoad failed! path empty ");
    callback(nullptr);
    return;
  }

  id<KryptonLoaderService> loader = [app_ getService:@protocol(KryptonLoaderService)];
  if (loader == nil) {
    KRYPTON_LOGW("loader service not found");
    callback(nullptr);
    return;
  }

  NSString* url = [NSString stringWithCString:path.c_str() encoding:NSUTF8StringEncoding];
  if (stream_load_callback && [loader respondsToSelector:@selector(loadURL:
                                                             withStreamLoadDelegate:)]) {
    KRYPTON_LOGI("loader service load with delegate");
    auto delegate = [[KryptonStreamLoadDelegateImpl alloc] init];
    delegate.callback = stream_load_callback;
    [loader loadURL:url withStreamLoadDelegate:delegate];
  } else {
    KRYPTON_LOGI("loader service load with callback");
    [loader loadURL:url
           callback:^(NSString* _Nullable err, NSData* _Nullable data) {
             callback(data);
           }];
  }
}

std::string ResourceLoaderIOS::RedirectUrl(const std::string& path) {
  id<KryptonLoaderService> loader = [app_ getService:@protocol(KryptonLoaderService)];
  if (!loader) {
    return path;
  }
  NSString* url = [NSString stringWithUTF8String:path.c_str()];
  NSString* redirect = [loader redirectURL:url];
  if (redirect != nil) {
    url = redirect;
  }
  return std::string([url UTF8String]);
}

}  // namespace canvas
}  // namespace lynx
