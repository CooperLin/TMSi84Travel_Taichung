//
//  MainViewController.m
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/2/26.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "MainViewController.h"
#import "MarqueeView.h"
#import "AppDelegate.h"
#import "ShareTools.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>
#import <CFNetwork/CFNetwork.h>
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "JSONKit.h"

@interface MainViewController ()
{
    MarqueeView * Marquee;
}

@end

@implementation MainViewController

@synthesize MarqueeV;
@synthesize DynamicBusBtn,RoutePlanBtn,TravelTimeBtn,NearStopBtn,QuestionReportBtn,FavoritesBtn,AboutBtn,PushBtn,LanguageBtn,backgroundImg;
#define MarqueeAPIUrl @"http://citybus.taichung.gov.tw/itravel/itravelAPI/ExpoAPI/news.aspx"

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [ShareTools setViewToFullScreen:self.view];
    Marquee = [[MarqueeView alloc] init];
    CGRect frame =MarqueeV.frame;
    frame.origin.y = 0;
    [Marquee setFrame:frame];
    [MarqueeV addSubview:Marquee];
    if(IS_IPHONE_5)
    {
        CGRect frame = MarqueeV.frame;
        frame.origin.y = 110;
        [MarqueeV setFrame:frame];
    }
    
//    MarqueeContent * content = [[MarqueeContent alloc] init];
//    content.Content = @"跑馬燈";
//    [Marquee.Contents addObject:content];
    
//    [Marquee StartMarquee];

}
- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self SendMarqueeRequest];
    [self _showI18N];
}

-(void)_showI18N
{
    [backgroundImg setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"background_img", appDelegate.LocalizedTable, nil)]];
    [DynamicBusBtn setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"dynamic_btn",appDelegate.LocalizedTable,nil)] forState:UIControlStateNormal];
    [RoutePlanBtn setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"routeplan_btn",appDelegate.LocalizedTable,nil)] forState:UIControlStateNormal];
    [TravelTimeBtn setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"traveltime_btn",appDelegate.LocalizedTable,nil)] forState:UIControlStateNormal];
    [NearStopBtn setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"nearstop_btn",appDelegate.LocalizedTable,nil)] forState:UIControlStateNormal];
    [QuestionReportBtn setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"question_btn",appDelegate.LocalizedTable,nil)] forState:UIControlStateNormal];
    [FavoritesBtn setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"favorite_btn",appDelegate.LocalizedTable,nil)] forState:UIControlStateNormal];
    [AboutBtn setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"about_btn",appDelegate.LocalizedTable,nil)] forState:UIControlStateNormal];
    [PushBtn setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"push_btn",appDelegate.LocalizedTable,nil)] forState:UIControlStateNormal];
    [LanguageBtn setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"language_btn",appDelegate.LocalizedTable,nil)] forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

-(IBAction)MainBtnClickEvent:(id)sender
{
    AppDelegate * delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if(sender == DynamicBusBtn)
    {
        [delegate SwitchViewer:1];
    }
    else if(sender == RoutePlanBtn)
    {
        [delegate SwitchViewer:6];
    }
    else if(sender == TravelTimeBtn)
    {
        [delegate SwitchViewer:5];
    }
    else if(sender == NearStopBtn)
    {
        [delegate SwitchViewer:4];
    }
    else if(sender == FavoritesBtn)
    {
        [delegate SwitchViewer:7];
    }
    else if(sender == PushBtn)
    {
        [delegate SwitchViewer:8];
    }
    else if(sender == QuestionReportBtn)
    {
        [delegate SwitchViewer:9];
    }
    else if(sender == AboutBtn)
    {
        [delegate SwitchViewer:10];
    }
    else if(sender == LanguageBtn)
    {
        [delegate SwitchViewer:11];
    }
}
#pragma mark ASIHTTP
- (void) SendMarqueeRequest
{
    if(![ShareTools connectedToNetwork])
    {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"請先開啟網路或網路狀態不穩",appDelegate.LocalizedTable,nil) delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確定",appDelegate.LocalizedTable,nil) otherButtonTitles:nil, nil];
        [alert show];
    }

    NSURL * url = [NSURL URLWithString:[MarqueeAPIUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    //    NSLog(@"Search Address Url:%@",url);
    
    ASIHTTPRequest * MarqueeRequest = [ASIHTTPRequest requestWithURL:url];
    [MarqueeRequest setDelegate:self];
    [MarqueeRequest setDidFinishSelector:@selector(MarqueeRequestFinish:)];
    [MarqueeRequest startAsynchronous];
}
- (void) MarqueeRequestFinish:(ASIHTTPRequest *)request
{
    [Marquee StopMarquee];
    [Marquee.Contents removeAllObjects];
    @try {
        NSData * content = [request responseData];
        //        NSLog(@"Response:%@",[request responseString]);
        
        JSONDecoder * Parser = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
        NSArray * news = [Parser objectWithData:content];
        for(NSDictionary * oneNew in news)
        {
            MarqueeContent * newM = [[MarqueeContent alloc] init];
            newM.Content = [[oneNew objectForKey:@"Content"] copy];
            newM.color = [UIColor colorWithRed:0.96f green:0.01f blue:0.01f alpha:1.0f];
            [Marquee.Contents addObject:newM];
            
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
    @finally {
        
    }
    [Marquee StartMarquee];
}

@end
