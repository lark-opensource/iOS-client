//
//  TTHttpMultipartFormDataChromium.m
//  Pods
//
//  Created by gaohaidong on 11/16/16.
//
//

#import "TTHttpMultipartFormDataChromium.h"

#import "TTHttpRequestChromium.h"

#pragma mark -

static NSString * TTCreateMultipartFormBoundary() {
    return [NSString stringWithFormat:@"Boundary+%08X%08X", arc4random(), arc4random()];
}

static NSString * const kTTMultipartFormCRLF = @"\r\n";

static inline NSString * TTMultipartFormInitialBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"--%@%@", boundary, kTTMultipartFormCRLF];
}

static inline NSString * TTMultipartFormEncapsulationBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"%@--%@%@", kTTMultipartFormCRLF, boundary, kTTMultipartFormCRLF];
}

static inline NSString * TTMultipartFormFinalBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"%@--%@--%@", kTTMultipartFormCRLF, boundary, kTTMultipartFormCRLF];
}

@interface TTHttpMultipartFormDataChromium ()
@property (nonatomic, assign) BOOL isFinal;
@end

@interface TTHTTPBodyPart : NSObject
@property (nonatomic, assign) NSStringEncoding stringEncoding;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, copy) NSString *boundary;
@property (nonatomic, strong) id body;
@property (nonatomic, assign) unsigned long long bodyContentLength;

@property (nonatomic, assign) BOOL hasInitialBoundary;
@property (nonatomic, assign) BOOL hasFinalBoundary;

- (NSData *)getData;

@end

@implementation TTHTTPBodyPart

- (NSString *)stringForHeaders_ {
    NSMutableString *headerString = [NSMutableString string];
    for (NSString *field in [self.headers allKeys]) {
        [headerString appendString:[NSString stringWithFormat:@"%@: %@%@", field, [self.headers valueForKey:field], kTTMultipartFormCRLF]];
    }
    [headerString appendString:kTTMultipartFormCRLF];
    
    return [NSString stringWithString:headerString];
}

- (NSData *)getData {
    NSMutableData *fullData = [[NSMutableData alloc] init];
    
    NSData *encapsulationBoundaryData = [(self.hasInitialBoundary ? TTMultipartFormInitialBoundary(self.boundary) : TTMultipartFormEncapsulationBoundary(self.boundary)) dataUsingEncoding:self.stringEncoding];
    
    NSData *headersData = [[self stringForHeaders_] dataUsingEncoding:self.stringEncoding];
    
    
    NSData *closingBoundaryData = (self.hasFinalBoundary ? [TTMultipartFormFinalBoundary(self.boundary) dataUsingEncoding:self.stringEncoding] : [NSData data]);
    
    [fullData appendData:encapsulationBoundaryData];
    [fullData appendData:headersData];
    [fullData appendData:(NSData *)self.body];
    [fullData appendData:closingBoundaryData];
    
    return fullData;
}

@end

@interface TTHttpMultipartFormDataChromium ()

@property (nonatomic, strong) NSMutableArray *HTTPBodyParts;
@property (nonatomic, assign) NSStringEncoding stringEncoding;
@property (nonatomic, copy) NSString *boundary;

@end

@implementation TTHttpMultipartFormDataChromium

#pragma mark - lifecycle functions

- (instancetype)init {
    if (self = [super init]) {
        self.boundary = TTCreateMultipartFormBoundary();
        self.HTTPBodyParts = [[NSMutableArray alloc] init];
        self.stringEncoding = NSUTF8StringEncoding;
        self.isFinal = NO;
    }
    return self;
}


#pragma mark - override functions

- (void)appendPartWithFileData:(NSData *)data
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType {
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];
    
    [self appendPartWithHeaders:mutableHeaders body:data];
}

- (void)appendPartWithFormData:(NSData *)data
                          name:(NSString *)name {
    NSParameterAssert(name);
    
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"", name] forKey:@"Content-Disposition"];
    
    [self appendPartWithHeaders:mutableHeaders body:data];
}

- (NSData *)finalFormDataWithHttpRequest:(TTHttpRequestChromium *)request {
    
    if (self.isFinal) {
        return request.HTTPBody;
    }
    
    self.isFinal = YES;
    
    if (request.params.count > 0) {
        
        for (NSString *key in [request.params allKeys]) {
            NSString *name = [key description];
            id value = request.params[key];
                        
            NSData *data = nil;
            if ([value isKindOfClass:[NSData class]]) {
                data = (NSData *)value;
            } else if ([value isEqual:[NSNull null]]) {
                data = [NSData data];
            } else {
                data = [[value description] dataUsingEncoding:self.stringEncoding];
            }
            
            if (data) {
                [self appendPartWithFormData:data name:name];
            }

        }
    }
    
    if ([self.HTTPBodyParts count] > 0) {
        
        [[self.HTTPBodyParts objectAtIndex:0] setHasInitialBoundary:YES];
        [[self.HTTPBodyParts lastObject] setHasFinalBoundary:YES];
        
        //construct body
        
        NSMutableData *body =  [NSMutableData data];
        
        for (TTHTTPBodyPart *bodyPart in self.HTTPBodyParts) {
            [body appendData:[bodyPart getData]];
        }
        [request setHTTPBodyNoCopy:body];
        
        //set request headers
        
        //[request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.boundary] forHTTPHeaderField:@"Content-Type"];
        //[request setValue:[NSString stringWithFormat:@"%llu", [body length]] forHTTPHeaderField:@"Content-Length"];
        
        return body;
    }
    return nil;
}

- (NSString *)getContentType {
    return [NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.boundary];
}

#pragma mark - helpers

- (void)appendPartWithHeaders:(NSDictionary *)headers
                         body:(NSData *)body
{
    NSParameterAssert(body);
    
    TTHTTPBodyPart *bodyPart = [[TTHTTPBodyPart alloc] init];
    bodyPart.stringEncoding = self.stringEncoding;
    bodyPart.headers = headers;
    bodyPart.boundary = self.boundary;
    bodyPart.bodyContentLength = [body length];
    bodyPart.body = body;
    bodyPart.hasInitialBoundary = NO;
    bodyPart.hasFinalBoundary = NO;
    
    [self.HTTPBodyParts addObject:bodyPart];
}

@end
