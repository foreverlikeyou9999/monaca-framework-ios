//
//  Utility.m
//  Template
//
//  Created by Hiroki Nakagawa on 11/06/07.
//  Copyright 2011 ASIAL CORPORATION. All rights reserved.
//

#import "Utility.h"

@implementation Utility

+ (MonacaTabBarController *)currentTabBarController {
    return (MonacaTabBarController *)((MonacaDelegate *)[UIApplication sharedApplication].delegate).viewController.tabBarController;
}

+ (UIInterfaceOrientation)currentInterfaceOrientation {
    MonacaDelegate *delegate = ((MonacaDelegate *)[UIApplication sharedApplication].delegate);
    return [delegate currentInterfaceOrientation];
}

+ (BOOL)getAllowOrientationFromPlist:(UIInterfaceOrientation)interfaceOrientation {
    NSDictionary *orientationkv = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:UIInterfaceOrientationPortrait],@"UIInterfaceOrientationPortrait",
                                   [NSNumber numberWithInt:UIInterfaceOrientationPortraitUpsideDown],@"UIInterfaceOrientationPortraitUpsideDown",
                                   [NSNumber numberWithInt:UIInterfaceOrientationLandscapeRight],@"UIInterfaceOrientationLandscapeRight",
                                   [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft],@"UIInterfaceOrientationLandscapeLeft",nil];
    NSString *key = @"UISupportedInterfaceOrientations";
    NSArray *values = [[[NSBundle mainBundle] infoDictionary] objectForKey:key];
    for (NSString *value in values){
        NSNumber *num = (NSNumber *)[orientationkv objectForKey:value];
        if(interfaceOrientation == (UIInterfaceOrientation)[num intValue]){
            return YES;
        }
    }
    return NO;
}

/*
 * 4.3と5.1の互換性を保ちつつ、MonacaViewControllerをセットアップする
 */
+ (void) setupMonacaViewController:(MonacaViewController *)monacaViewController{
    if ([Device iOSVersionMajor] < 5) {
    }else{
        BOOL forceStartupRotation = YES;
        UIDeviceOrientation curDevOrientation = [[UIDevice currentDevice] orientation];
        if (UIDeviceOrientationUnknown == curDevOrientation) {
            curDevOrientation = (UIDeviceOrientation)[[UIApplication sharedApplication] statusBarOrientation];
        }
        if (UIDeviceOrientationIsValidInterfaceOrientation(curDevOrientation)) {
            for (NSNumber *orient in monacaViewController.cdvViewController.supportedOrientations) {
                if ([orient intValue] == curDevOrientation) {
                    forceStartupRotation = NO;
                    break;
                }
            }
        }
        if (forceStartupRotation) {
            UIInterfaceOrientation newOrient = [[monacaViewController.cdvViewController.supportedOrientations objectAtIndex:0] intValue];
            [[UIApplication sharedApplication] setStatusBarOrientation:newOrient];
        }
    }
}

/*
 * 表示される時のレイアウトを修正する
 */
+ (void) fixedLayout:(MonacaViewController *)monacaViewController interfaceOrientation:(UIInterfaceOrientation)aInterfaceOrientation{
    if (aInterfaceOrientation == UIInterfaceOrientationPortrait || aInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown){
        monacaViewController.view.frame = [[UIScreen mainScreen] bounds];
        UIViewController *vc = [monacaViewController.tabBarController.viewControllers objectAtIndex:0];
        [vc setWantsFullScreenLayout:YES];
    }
}

/*
 * 404 page
 */
+ (void) show404PageWithWebView:(UIWebView *)webView path:(NSString *)aPath {
    NSString *pathFor404 = [[NSBundle mainBundle] pathForResource:@"404/index" ofType:@"html"];
    NSString *html = [NSString stringWithContentsOfFile:pathFor404 encoding:NSUTF8StringEncoding error:nil];

    html = [html stringByReplacingOccurrencesOfString:@"%%%urlPlaceHolder%%%" withString:[Utility getWWWShortPath:aPath]];
    [webView loadHTMLString:html baseURL:[NSURL fileURLWithPath:pathFor404]];
    [[Utility currentTabBarController] applyUserInterface:nil];
}

/*
 *  convert path (ex 1234/xxxx/www/yyy.html -> www/yyy.html)
 */
+ (NSString *)getWWWShortPath:(NSString *)path{
    if([path rangeOfString:@"www/"].location == NSNotFound){
        return @"";
    }else{
        NSMutableArray *array = [NSMutableArray arrayWithArray:[path componentsSeparatedByString:@"www/"]];
        if(array.count > 0) [array removeObjectAtIndex:0];
        return [@"www" stringByAppendingPathComponent:[array objectAtIndex:0]];
    }
}

/*
 * build url Moaca query params
 */
+ (NSString *)insertMonacaQueryParams:(NSString *)html query:(NSString *)aQuery {
    if (aQuery){
        NSArray *pairs = [aQuery componentsSeparatedByString:@"&"];
        NSMutableArray *keyValues = [NSMutableArray array];

        for (NSString *pair in pairs) {
            NSArray *elements = [pair componentsSeparatedByString:@"="];
            NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            key = [key stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
            key = [key stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            NSString *value;
            if (elements.count>1){
                value = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                value = [value stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
                value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
                [keyValues addObject:[NSString stringWithFormat:@"\"%@\":\"%@\"", key, value]];
            }else {
                [keyValues addObject:[NSString stringWithFormat:@"\"%@\":null", key]];
            }
        }
        NSString *keyValuesString = [keyValues componentsJoinedByString:@","];
        NSString *queryScriptTag = [NSString stringWithFormat:@"<script>window.monaca = window.monaca || {};window.monaca.queryParams = {%@};</script>", keyValuesString];
        NSRange replaceRange = [html rangeOfString:@"<head>"];
        if(replaceRange.location == NSNotFound){
            html = [queryScriptTag stringByAppendingString:html];
        }else {
            html = [html stringByReplacingCharactersInRange:replaceRange withString:[NSString stringWithFormat:@"<head>%@", queryScriptTag]];
        }
    }
    return html;
}

+ (NSString *)urlEncode:(NSString *)text{
    CFStringRef cfString = CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                   (CFStringRef)text,
                                                                   NULL,
                                                                   (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                   kCFStringEncodingUTF8);
    NSString *string = [NSString stringWithString:(NSString *)cfString];
    CFRelease(cfString);
    return string;
}

+ (NSString *)urlDecode:(NSString *)text{
    CFStringRef cfString = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                   (CFStringRef)text,
                                                                                   CFSTR(""),
                                                                                   kCFStringEncodingUTF8);
    NSString *string = [NSString stringWithString:(NSString *)cfString];
    CFRelease(cfString);
    return string;
}

+ (MonacaDelegate *)getAppDelegate
{
    return ((MonacaDelegate *)[[UIApplication sharedApplication] delegate]);
}

@end