//
//  GPRequestModel.h
//  VideoTemplate
//
//  Created by bytedance on 2021/8/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GPMutipartFormData : NSObject

@property (nonatomic, strong) NSData *data;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *mimeType;

- (instancetype)initWithData:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType;

@end

@interface GPRequestModel : NSObject

// common
@property (nonatomic,   copy) NSString *urlString;       // Interface
@property (nonatomic,   copy) NSDictionary *params;      // Parameters
@property (nonatomic, assign) BOOL needCommonParams;     // Common parameters
@property (nonatomic, copy) NSDictionary *headerField; // header
@property (nonatomic, assign) NSTimeInterval timeout;    // Time out
@property (nonatomic, strong) Class objectClass;         // response model class
// upload
@property (nonatomic, strong) NSURL * fileURL;           // File path
@property (nonatomic,   copy) NSString * fileName;       // File name
// If the requested body needs to have a file name and file, it need to
@property (nonatomic, strong) GPMutipartFormData *formData;

@end

NS_ASSUME_NONNULL_END
