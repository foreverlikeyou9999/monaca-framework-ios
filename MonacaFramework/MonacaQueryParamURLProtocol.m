//
//  MonacaQueryParamURLProtocol.m
//  MonacaDebugger
//
//  Created by yasuhiro on 12/12/20.
//  Copyright (c) 2012年 ASIAL CORPORATION. All rights reserved.
//

#import "MonacaQueryParamURLProtocol.h"
#import "MonacaViewController.h"
#import "Utility.h"

@implementation MonacaQueryParamURLProtocol

static BOOL isWork = YES;

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    // targets are html file with file protocol.
    if (isWork && request.URL.port==nil && [request.URL.scheme isEqualToString:@"file"] &&
        [request.URL.pathExtension isEqualToString:@"html"]) {
        return YES;
    }
    return NO;
}

- (void)startLoading
{
    NSString *html = [self InsertMonacaQueryParams:self.request];
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];

    // create header for no-cache, because of UIWebView has cache on file protocol.
    NSHTTPURLResponse *response = [self responseWithNonCacheHeader:self.request Data:data];

    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];

    // Display Contents
    [self.client URLProtocol:self didLoadData:data];
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading
{
	// do any cleanup here
}

- (NSString *)InsertMonacaQueryParams:(NSURLRequest *)request
{
    NSString *html = [NSString stringWithContentsOfFile:request.URL.path encoding:NSUTF8StringEncoding error:nil];
    html = [Utility insertMonacaQueryParams:html query:request.URL.query];
    return html;
}

@end
