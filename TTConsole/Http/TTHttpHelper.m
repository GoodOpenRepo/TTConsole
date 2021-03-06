//
//  TTHttpHelper.m
//  AFNetworking
//
//  Created by 打不死的强丿 on 2019/6/9.
//

#import "TTHttpHelper.h"
#import "TTURLProtocol.h"

NSString * const TTURLRequestRequestIdKey       = @"requestId";
NSString * const TTURLRequestUrlKey             = @"url";
NSString * const TTURLRequestMethodKey          = @"method";
NSString * const TTURLRequestMineTypeKey        = @"mineType";
NSString * const TTURLRequestStatusCodeKey      = @"statusCode";
NSString * const TTURLRequestHeaderKey          = @"header";
NSString * const TTURLRequestRequestBodyKey     = @"requestBody";
NSString * const TTURLRequestResponseDataKey    = @"responseData";
NSString * const TTURLRequestIsImageKey         = @"isImage";
NSString * const TTURLRequestImageDataKey       = @"imageData";

@interface TTHttpHelper ()

@property (nonatomic,strong) NSMutableArray *requestArr;
@property (nonatomic,strong) NSMutableArray *requestIds;

@end

@implementation TTHttpHelper

+ (instancetype)helper {
    static TTHttpHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
        instance.requestArr = [NSMutableArray array];
        instance.requestIds = [NSMutableArray array];
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return [TTHttpHelper helper];
}

- (void)start
{
    [NSURLProtocol registerClass:[TTURLProtocol class]];
}

- (void)addHttpRequset:(NSDictionary *)model {
    @synchronized(self.requestArr) {
        [self.requestArr insertObject:model atIndex:0];
    }
    @synchronized(self.requestIds) {
        if (model[TTURLRequestRequestIdKey] && [model[TTURLRequestRequestIdKey] length] > 0) {
            [self.requestIds addObject:model[TTURLRequestRequestIdKey]];
        }
    }
}

- (void)clear {
    @synchronized(self.requestArr) {
        [self.requestArr removeAllObjects];
    }
}

- (NSString *)jsonStrFromData:(NSData *)data
{
    if (!data) {
        return @"";
    }
    NSString *prettyString = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    if ([NSJSONSerialization isValidJSONObject:jsonObject]) {
        prettyString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:NULL] encoding:NSUTF8StringEncoding];
        // NSJSONSerialization escapes forward slashes. We want pretty json, so run through and unescape the slashes.
        prettyString = [prettyString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
    } else {
        prettyString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return prettyString;
}

@end
