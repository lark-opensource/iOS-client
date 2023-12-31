//
//  RequestModelTests.m
//  IESPrefetch-Unit-Tests
//
//  Created by yuanyiyang on 2019/12/4.
//

#import <Specta/Specta.h>
#import <Expecta/Expecta.h>
#import <IESPrefetch/IESPrefetchJSNetworkRequestModel.h>

SpecBegin(RequestModel)
describe(@"initWithDictionary", ^{
         it(@"correctDict", ^{
    NSDictionary *dict = @{
        @"url": @"https://httpbin.org/get",
        @"method": @"GET",
        @"headers": @{
                @"Content-Type": @"application/json"
        },
        @"params": @{
                @"key1": @"value1"
        },
        @"data": @{
                @"key2": @"value2",
                @"key3": [NSNull null],
                @"key4": @4,
                @"key5": @""
        }
    };
    IESPrefetchJSNetworkRequestModel *model = [[IESPrefetchJSNetworkRequestModel alloc] initWithDictionary:dict];
    expect(model.url).equal(dict[@"url"]);
    expect(model.method).equal(dict[@"method"]);
    expect(model.headers[@"Content-Type"]).equal(@"application/json");
    expect(model.params[@"key1"]).equal(@"value1");
    expect(model.data[@"key2"]).equal(@"value2");
    expect(model.data[@"key3"]).to.beNil();
    expect(model.data[@"key4"]).equal(@4);
    expect(model.data[@"key5"]).equal(@"");
});
         });
describe(@"hashValue", ^{
         it(@"sameModelSameHash", ^{
    IESPrefetchJSNetworkRequestModel *model1 = [[IESPrefetchJSNetworkRequestModel alloc] init];
    model1.url = @"https://httpbin.org/get";
    model1.method = @"GET";
    model1.headers = @{@"header1": @"value1"};
    model1.params = @{@"key1": @"value1"};
    model1.data = @{@"key2": @"value2", @"key3": @"value3"};
    NSString *hash1 = model1.hashValue;
    
    IESPrefetchJSNetworkRequestModel *model2 = [IESPrefetchJSNetworkRequestModel new];
    model2.url = @"https://httpbin.org/get";
    model2.method = @"GET";
    model2.headers = @{@"header1": @"value1"};
    model2.params = @{@"key1": @"value1"};
    model2.data = @{@"key3": @"value3", @"key2": @"value2"};
    NSString *hash2 = model2.hashValue;
    
    expect(hash1).equal(hash2);
});
                  it(@"differentHash", ^{
             IESPrefetchJSNetworkRequestModel *model1 = [[IESPrefetchJSNetworkRequestModel alloc] init];
             model1.url = @"https://httpbin.org/get";
             model1.method = @"GET";
             model1.headers = @{@"header1": @"value2"};
             model1.params = @{@"key1": @"value1"};
             model1.data = @{@"key2": @"value2", @"key3": @"value3"};
             NSString *hash1 = model1.hashValue;
             
             IESPrefetchJSNetworkRequestModel *model2 = [IESPrefetchJSNetworkRequestModel new];
             model2.url = @"https://httpbin.org/get";
             model2.method = @"GET";
             model2.headers = @{@"header1": @"value1"};
             model2.params = @{@"key1": @"value1"};
             model2.data = @{@"key3": @"value3", @"key2": @"value2"};
             NSString *hash2 = model2.hashValue;
             
             expect(hash1).notTo.equal(hash2);
         });
    it(@"sameHashWithQueryInURL", ^{
        IESPrefetchJSNetworkRequestModel *model1 = [[IESPrefetchJSNetworkRequestModel alloc] init];
        model1.url = @"https://httpbin.org/get?key1=value1";
        model1.method = @"GET";
        NSString *hash1 = model1.hashValue;
        
        IESPrefetchJSNetworkRequestModel *model2 = [IESPrefetchJSNetworkRequestModel new];
        model2.url = @"https://httpbin.org/get";
        model2.method = @"GET";
        model2.params = @{@"key1": @"value1"};
        NSString *hash2 = model2.hashValue;
        expect(hash1).equal(hash2);
        
        
    });
    it(@"sameHashWithStringParamsNoValue", ^{
        IESPrefetchJSNetworkRequestModel *model3 = [[IESPrefetchJSNetworkRequestModel alloc] init];
        model3.url = @"https://httpbin.org/get?key2=value2&key1";
        model3.method = @"GET";
        NSString *hash3 = model3.hashValue;
        
        IESPrefetchJSNetworkRequestModel *model4 = [IESPrefetchJSNetworkRequestModel new];
        model4.url = @"https://httpbin.org/get?key2=value2";
        model4.method = @"GET";
        model4.params = @"key1";
        NSString *hash4 = model4.hashValue;
        expect(hash3).equal(hash4);
    });
    it(@"sameHashWithStringParams", ^{
        IESPrefetchJSNetworkRequestModel *model3 = [[IESPrefetchJSNetworkRequestModel alloc] init];
        model3.url = @"https://httpbin.org/get?key2=value2&key1=value1";
        model3.method = @"GET";
        NSString *hash3 = model3.hashValue;
        
        IESPrefetchJSNetworkRequestModel *model4 = [IESPrefetchJSNetworkRequestModel new];
        model4.url = @"https://httpbin.org/get";
        model4.method = @"GET";
        model4.params = @"key1=value1&key2=value2";
        NSString *hash4 = model4.hashValue;
        expect(hash3).equal(hash4);
    });
    it(@"differentHashWithDiffStringParams", ^{
        IESPrefetchJSNetworkRequestModel *model3 = [[IESPrefetchJSNetworkRequestModel alloc] init];
        model3.url = @"https://httpbin.org/get?key2=value2&key1=value1";
        model3.method = @"GET";
        NSString *hash3 = model3.hashValue;
        
        IESPrefetchJSNetworkRequestModel *model4 = [IESPrefetchJSNetworkRequestModel new];
        model4.url = @"https://httpbin.org/get";
        model4.method = @"GET";
        model4.params = @"key1=value1&key2=value3";
        NSString *hash4 = model4.hashValue;
        expect(hash3).notTo.equal(hash4);
    });
    it(@"sameHashWithDiffParamsValueType", ^{
        IESPrefetchJSNetworkRequestModel *model3 = [[IESPrefetchJSNetworkRequestModel alloc] init];
        model3.url = @"https://httpbin.org/get?key2=2&key1=value1";
        model3.method = @"GET";
        NSString *hash3 = model3.hashValue;
        
        IESPrefetchJSNetworkRequestModel *model4 = [IESPrefetchJSNetworkRequestModel new];
        model4.url = @"https://httpbin.org/get";
        model4.method = @"GET";
        model4.params = @{@"key1": @"value1", @"key2": @2};
        NSString *hash4 = model4.hashValue;
        expect(hash3).equal(hash4);
    });
    it(@"sameHashWithNoParams", ^{
        IESPrefetchJSNetworkRequestModel *model3 = [[IESPrefetchJSNetworkRequestModel alloc] init];
        model3.url = @"https://httpbin.org/get?";
        model3.method = @"GET";
        NSString *hash3 = model3.hashValue;
        
        IESPrefetchJSNetworkRequestModel *model4 = [IESPrefetchJSNetworkRequestModel new];
        model4.url = @"https://httpbin.org/get";
        model4.method = @"GET";
        model4.params = @{};
        NSString *hash4 = model4.hashValue;
        expect(hash3).equal(hash4);
    });
         });
SpecEnd
