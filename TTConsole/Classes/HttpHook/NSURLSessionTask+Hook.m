//
//  NSURLSessionTask+Hook.m
//  TTConsole-Resource
//
//  Created by 打不死的强丿 on 2019/6/8.
//

#import "NSURLSessionTask+Hook.h"
#import <objc/runtime.h>
#import "NSURLRequest+DataExt.h"
#import "TTURLRequestKey.h"
#import "TTHttpHelper.h"

NSString * const TTURLRequestRequestIdKey       = @"requestId";

@implementation NSURLSessionTask (Hook)

+ (void)load {
    
    Method oriMethod = class_getInstanceMethod([NSURLSession class], @selector(dataTaskWithRequest:));
    Method newMethod = class_getInstanceMethod([NSURLSession class], @selector(dataTaskWithRequest_swizzling:));
    method_exchangeImplementations(oriMethod, newMethod);
    
    const SEL selectors_data[] = {
        @selector(URLSession:dataTask:didReceiveResponse:completionHandler:),
        @selector(URLSession:dataTask:didBecomeDownloadTask:),
        @selector(URLSession:dataTask:didBecomeStreamTask:),
        @selector(URLSession:dataTask:didReceiveData:),
        @selector(URLSession:dataTask:willCacheResponse:completionHandler:)
    };
    
    const int numSelectors_data = sizeof(selectors_data) / sizeof(SEL);
    
    Class *classes = NULL;
    int numClasses = objc_getClassList(NULL, 0);
    classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    for (NSInteger classIndex = 0; classIndex < numClasses; ++classIndex) {
        Class class = classes[classIndex];
        
        unsigned int methodCount = 0;
        Method *methods = class_copyMethodList(class, &methodCount);
        BOOL matchingSelectorFound = NO;
        for (unsigned int methodIndex = 0; methodIndex < methodCount; methodIndex++) {
            for (int selectorIndex = 0; selectorIndex < numSelectors_data; ++selectorIndex) {
                if (method_getName(methods[methodIndex]) == selectors_data[selectorIndex]) {
                    [self swizzling_selectors_task:class];
                    [self swizzling_selectors_data:class];
                    matchingSelectorFound = YES;
                    break;
                }
            }
            if (matchingSelectorFound) {
                break;
            }
        }
    }
}

#pragma mark - NSURLSession task delegate with swizzling
+ (void)swizzling_selectors_task:(Class)cls {
    [self swizzling_TaskWillPerformHTTPRedirectionIntoDelegateClass:cls];
    [self swizzling_TaskDidSendBodyDataIntoDelegateClass:cls];
    [self swizzling_TaskDidReceiveChallengeIntoDelegateClass:cls];
    [self swizzling_TaskNeedNewBodyStreamIntoDelegateClass:cls];
    [self swizzling_TaskDidCompleteWithErrorIntoDelegateClass:cls];
}

+ (void)swizzling_TaskWillPerformHTTPRedirectionIntoDelegateClass:(Class)cls {
    SEL selector = @selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:);
    SEL swizzledSelector = @selector(URLSession_swizzling:task:willPerformHTTPRedirection:newRequest:completionHandler:);
    Protocol *protocol = @protocol(NSURLSessionTaskDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription];
}

+ (void)swizzling_TaskDidSendBodyDataIntoDelegateClass:(Class)cls {
    SEL selector = @selector(URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:);
    SEL swizzledSelector = @selector(URLSession_swizzling:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:);
    Protocol *protocol = @protocol(NSURLSessionTaskDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription];
}

+ (void)swizzling_TaskDidReceiveChallengeIntoDelegateClass:(Class)cls {
    SEL selector = @selector(URLSession:task:didReceiveChallenge:completionHandler:);
    SEL swizzledSelector = @selector(URLSession_swizzling:task:didReceiveChallenge:completionHandler:);
    Protocol *protocol = @protocol(NSURLSessionTaskDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription];
}

+ (void)swizzling_TaskNeedNewBodyStreamIntoDelegateClass:(Class)cls {
    SEL selector = @selector(URLSession_swizzling:task:needNewBodyStream:);
    SEL swizzledSelector = @selector(URLSession_swizzling:task:needNewBodyStream:);
    Protocol *protocol = @protocol(NSURLSessionTaskDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription];
}

+ (void)swizzling_TaskDidCompleteWithErrorIntoDelegateClass:(Class)cls {
    SEL selector = @selector(URLSession:task:didCompleteWithError:);
    SEL swizzledSelector = @selector(URLSession_swizzling:task:didCompleteWithError:);
    Protocol *protocol = @protocol(NSURLSessionTaskDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription];
}
#pragma mark - NSURLSession task delegate
- (void)URLSession_swizzling:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * __nullable))completionHandler {
    [self URLSession_swizzling:session task:task willPerformHTTPRedirection:response newRequest:request completionHandler:completionHandler];
}

- (void)URLSession_swizzling:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    NSURLRequest* req = task.originalRequest;
    req.requestId = [[NSUUID UUID] UUIDString];
//    req.startTime = @([[NSDate date] timeIntervalSince1970]);
    [self URLSession_swizzling:session task:task didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalBytesExpectedToSend];
}

- (void)URLSession_swizzling:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler {
    [self URLSession_swizzling:session task:task didReceiveChallenge:challenge completionHandler:completionHandler];
}

- (void)URLSession_swizzling:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream * __nullable bodyStream))completionHandler {
    [self URLSession_swizzling:session task:task needNewBodyStream:completionHandler];
}

- (void)URLSession_swizzling:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    [self URLSession_swizzling:session task:task didCompleteWithError:error];
    NSURLRequest* req = task.originalRequest;
    req.requestId = [NSString stringWithFormat:@"%p",task.originalRequest];
    if ([[[TTHttpHelper helper] requestIds] containsObject:req.requestId]) {
        return;
    }
    
    NSURLResponse* resp = task.response;
    NSMutableDictionary* model = [NSMutableDictionary dictionary];
    model[TTURLRequestRequestIdKey] = req.requestId;
    model[TTURLRequestUrlKey] = req.URL;
    model[TTURLRequestMethodKey] = req.HTTPMethod;
    model[TTURLRequestMineTypeKey] = resp.MIMEType;
    
    if (req.HTTPBody) {
        NSData *data = req.HTTPBody;
        model[TTURLRequestRequestBodyKey] = [[TTHttpHelper helper] jsonStrFromData:data];
    }
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)resp;
    if ([resp isKindOfClass:[NSHTTPURLResponse class]]) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:httpResponse.allHeaderFields options:NSJSONWritingPrettyPrinted error:nil];
        NSString * str = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        model[TTURLRequestHeaderKey] = str;
    }
    BOOL isImage = [task.response.MIMEType rangeOfString:@"image"].location != NSNotFound;
    model[TTURLRequestStatusCodeKey] = [@(httpResponse.statusCode) stringValue];
    model[TTURLRequestResponseDataKey] = isImage?nil:[[TTHttpHelper helper] jsonStrFromData:task.responseDatas];
    model[TTURLRequestImageDataKey] = isImage?task.responseDatas:nil;
    model[TTURLRequestIsImageKey] = @(isImage);
    [[TTHttpHelper helper] addHttpRequset:model];
    if ([TTHttpHelper helper].requestHookHandler) {
        [TTHttpHelper helper].requestHookHandler();
    }
}

#pragma mark - NSUrlSession data delegate with swizzling
+ (void)swizzling_selectors_data:(Class)cls {
    [self swizzling_TaskDidReceiveResponseIntoDelegateClass:cls];
    [self swizzling_TaskDidReceiveDataIntoDelegateClass:cls];
    [self swizzling_TaskDidBecomeDownloadTaskIntoDelegateClass:cls];
    [self swizzling_TaskDidBecomeStreamTaskIntoDelegateClass:cls];
    //    [self swizzling_TaskWillCacheResponseIntoDelegateClass:cls];
}

+ (void)swizzling_TaskDidReceiveResponseIntoDelegateClass:(Class)cls {
    SEL selector = @selector(URLSession:dataTask:didReceiveResponse:completionHandler:);
    SEL swizzledSelector = @selector(URLSession_swizzling:dataTask:didReceiveResponse:completionHandler:);
    Protocol *protocol = @protocol(NSURLSessionDataDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription];
}

+ (void)swizzling_TaskDidReceiveDataIntoDelegateClass:(Class)cls {
    SEL selector = @selector(URLSession:dataTask:didReceiveData:);
    SEL swizzledSelector = @selector(URLSession_swizzling:dataTask:didReceiveData:);
    Protocol *protocol = @protocol(NSURLSessionDataDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription];
}

+ (void)swizzling_TaskDidBecomeDownloadTaskIntoDelegateClass:(Class)cls {
    SEL selector = @selector(URLSession:dataTask:didBecomeDownloadTask:);
    SEL swizzledSelector = @selector(URLSession_swizzling:dataTask:didBecomeDownloadTask:);
    Protocol *protocol = @protocol(NSURLSessionDataDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription];
}
+ (void)swizzling_TaskDidBecomeStreamTaskIntoDelegateClass:(Class)cls {
    SEL selector = @selector(URLSession:dataTask:didBecomeStreamTask:);
    SEL swizzledSelector = @selector(URLSession_swizzling:dataTask:didBecomeStreamTask:);
    Protocol *protocol = @protocol(NSURLSessionDataDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription];
}

+ (void)swizzling_TaskWillCacheResponseIntoDelegateClass:(Class)cls {
    SEL selector = @selector(URLSession:dataTask:willCacheResponse:completionHandler:);
    SEL swizzledSelector = @selector(URLSession_swizzling:dataTask:willCacheResponse:completionHandler:);
    Protocol *protocol = @protocol(NSURLSessionDataDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    [self replaceImplementationOfSelector:selector withSelector:swizzledSelector forClass:cls withMethodDescription:methodDescription];
}

+ (void)replaceImplementationOfSelector:(SEL)selector withSelector:(SEL)swizzledSelector forClass:(Class)cls withMethodDescription:(struct objc_method_description)methodDescription
{
    IMP implementation = class_getMethodImplementation([self class], swizzledSelector);
    Method oldMethod = class_getInstanceMethod(cls, selector);
    if (oldMethod) {
        class_addMethod(cls, swizzledSelector, implementation, methodDescription.types);
        Method newMethod = class_getInstanceMethod(cls, swizzledSelector);
        method_exchangeImplementations(oldMethod, newMethod);
    } else {
        class_addMethod(cls, selector, implementation, methodDescription.types);
    }
}

#pragma mark - NSUrlSession delegate
- (NSURLSessionDataTask *)dataTaskWithRequest_swizzling:(NSURLRequest *)request {
    return [self dataTaskWithRequest_swizzling:request];
}

- (void)URLSession_swizzling:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    [self URLSession_swizzling:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}

- (void)URLSession_swizzling:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if(!dataTask.responseDatas) {
        dataTask.responseDatas = [NSMutableData data];
        dataTask.taskDataIdentify = NSStringFromClass([self class]);
    }
    if ([dataTask.taskDataIdentify isEqualToString:NSStringFromClass([self class])])
        [dataTask.responseDatas appendData:data];
    [self URLSession_swizzling:session dataTask:dataTask didReceiveData:data];
}

- (void)URLSession_swizzling:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    [self URLSession_swizzling:session dataTask:dataTask didBecomeDownloadTask:downloadTask];
}

- (void)URLSession_swizzling:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeStreamTask:(NSURLSessionStreamTask *)streamTask  API_AVAILABLE(ios(9.0)){
    [self URLSession_swizzling:session dataTask:dataTask didBecomeStreamTask:streamTask];
}

- (void)URLSession_swizzling:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * __nullable cachedResponse))completionHandler {
    [self URLSession_swizzling:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
}
@end
