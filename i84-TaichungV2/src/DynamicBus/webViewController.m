//
//  webViewController.m
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/5/9.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "webViewController.h"

@interface webViewController ()

@end

@implementation webViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

}
-(void)viewWillAppear:(BOOL)animated
{
    [self actLoadURL];
}
-(void)actLoadURL
{
    NSString * stringUrl = [self actGetUrl];

    [self.webViewMain loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:stringUrl]]];
}
-(NSString*)actGetUrl
{
    return (self.delegate?[self.delegate webViewStartUrlOnWebViewController:self]:nil);
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
