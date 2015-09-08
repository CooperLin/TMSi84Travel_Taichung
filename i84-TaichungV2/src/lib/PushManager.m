//
//  PushManager.m
//  TTravelPad
//
//  Created by ＴＭＳ 景翊科技 on 13/8/2.
//  Copyright (c) 2013年 ycgisMini2. All rights reserved.
//

#import "PushManager.h"
#import "AppDelegate.h"

#import "ASIHTTPRequest.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>
#import <CFNetwork/CFNetwork.h>

#ifdef OnlyEng
#define AppLang @"eng"
#else
#define AppLang @"cht"
#endif

#define AppKind @"iPhone"
@implementation PushManager
{

}

- (id) initWithToken:(NSString *)Token
{
    self = [super init];
    if(self)
    {
        if(Token != nil)
        {
            NSUserDefaults  * userDefault = [NSUserDefaults standardUserDefaults];
            NSString * hasToken = [userDefault objectForKey:@"PushToken"];
            if (hasToken && [hasToken compare:Token] == 0 )
            {
                
            }
            else
            {
                [userDefault setObject:Token forKey:@"PushToken"];
                [userDefault synchronize];
            }
        }
    }
    return self;
}

- (NSString *) GetModel
{
    NSString * Model = [[UIDevice currentDevice] model];
    NSRange Range = [Model rangeOfString:@"iPad"];
    if(Range.length > 0)
    {
        return @"ipad";
    }
    else
    {
        return @"iphone";
    }
}
+ (NSString *) GetToken
{
    NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
    NSString * Token = [userDefault objectForKey:@"PushToken"];
    if(Token == nil)
    {
       // return @"f73f619105e96efca2fc88d3e8718444e8b8a31892b2ecdb7bbe8cc5bb74f75b";
        return nil;
    }
    else
    {
        return Token;
    }
}

@end
