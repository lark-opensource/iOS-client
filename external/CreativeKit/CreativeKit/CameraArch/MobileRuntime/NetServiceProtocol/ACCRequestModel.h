//
//  ACCRequestModel.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCRequestType) {
    ACCRequestTypeGET,      // The get method requests a representation of the specified resource. Requests using get should only be used to get data
    ACCRequestTypeHEAD,     // The head method requests the same response as the get request, but there is no response body
    ACCRequestTypePOST,     // The post method is used to submit an entity to a specified resource, which usually results in state changes or side effects on the server
    ACCRequestTypePUT,      // The put method replaces all current representations of the target resource with the request payload
    ACCRequestTypeDELETE,   // The delete method deletes the specified resource
    ACCRequestTypeCONNECT,  // The connect method establishes a tunnel to the server identified by the target resource
    ACCRequestTypeOPTIONS,  // The options method is used to describe the communication options of the target resource
    ACCRequestTypeTRACE,    // The trace method performs a message loopback test along the path to the target resource
    ACCRequestTypePATCH     // The patch method is used to apply partial modifications to resources
};

@protocol ACCRequestModelProtocol <NSObject>
// common
@property (nonatomic, assign) ACCRequestType requestType;// Request type
@property (nonatomic,   copy) NSString *urlString;       // Interface
@property (nonatomic,   copy) NSDictionary *params;      // Parameters
@property (nonatomic, assign) BOOL needCommonParams;     // Common parameters
@property (nonatomic, strong) NSDictionary *headerField; // header
@property (nonatomic, assign) NSTimeInterval timeout;    // Time out
@property (nonatomic, strong) Class objectClass;         // response model class
// upload
@property (nonatomic, strong) NSURL * fileURL;           // File path
@property (nonatomic,   copy) NSString * fileName;       // File name
// If the requested body needs to have a file name and file, it needs to be set through the block
@property (nonatomic,   copy) id bodyBlock; // type is TTConstructingBodyBlock, but depend on TTNetwork
// downlaod
@property (nonatomic,   copy) NSString * targetPath;     // Download path
@end



@interface ACCRequestModel : NSObject<ACCRequestModelProtocol>

@end

NS_ASSUME_NONNULL_END
