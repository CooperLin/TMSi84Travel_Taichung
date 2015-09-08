//
//  TakeTimeViewController.m
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/4/29.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "TakeTimeViewController.h"
#import "AppDelegate.h"

@interface TakeTimeViewController ()<StopsTakeTimeDelegate,SilderMenuDelegate>
{
    //sliderMenu Table obj
    SilderMenuView * SilderMenu;
    NSMutableDictionary * LeftMenu_BackBtn;
}
@property (nonatomic, strong) UIView *viewCover;
@end

@implementation TakeTimeViewController
@synthesize stopsTakeTimeViewController;

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
    [self actShowChildViewController];
    [self _showViewCover:NO];
    [self actSetSliderMenu];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.titleLabel.text = NSLocalizedStringFromTable(@"旅行時間", appDelegate.LocalizedTable, nil);
}

-(void)actSetSliderMenu
{
    SilderMenu = [[SilderMenuView alloc] initWithFrame:CGRectMake(0, 0, 135, self.view.frame.size.height)];
    [SilderMenu setSilderDelegate:self];
    [self.viewMatrix addSubview:SilderMenu];
    [SilderMenu setItemsByPlistName:@"LeftMenu"];
    [self actSetSliderMenuBackBtn];

}
-(void)actSetSliderMenuBackBtn
{
    //設定返回鍵
    LeftMenu_BackBtn = [[NSMutableDictionary alloc] init];
    [LeftMenu_BackBtn setObject:@"back" forKey:@"item"];
    [LeftMenu_BackBtn setObject:@"leftmenu_back.png" forKey:@"icon"];
    [LeftMenu_BackBtn setObject:@"返回" forKey:@"title"];
    
}
-(void)actShowChildViewController
{
    if (!stopsTakeTimeViewController)
    {
        stopsTakeTimeViewController = [[StopsTakeTimeViewController alloc]initWithNibName:@"StopsTakeTimeViewController" bundle:nil];
        stopsTakeTimeViewController.view.frame = self.viewContainer.frame;
    }
    [self addChildViewController:stopsTakeTimeViewController];
    
    stopsTakeTimeViewController.view.frame = self.viewContainer.bounds;
    [self.viewContainer addSubview:stopsTakeTimeViewController.view];

    stopsTakeTimeViewController.delegate = self;

}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - SilderMenu
- (void) ItemSelectedEvent:(NSString *) SelectedItem
{
    AppDelegate * appdelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if([SelectedItem compare:@"dynamicbus"] == 0)
    {
        [appdelegate SwitchViewer:1];
    }
    else if([SelectedItem compare:@"routeplan"] == 0)
    {
        [appdelegate SwitchViewer:6];
    }
    else if([SelectedItem compare:@"nearstop"] == 0)
    {
        [appdelegate SwitchViewer:4];
    }
    else if([SelectedItem compare:@"traveltime"] == 0)
    {
        [appdelegate SwitchViewer:5];
    }
    else if([SelectedItem compare:@"questionreport"] == 0)
    {
        [appdelegate SwitchViewer:9];
    }
    else if([SelectedItem compare:@"favorites"] == 0)
    {
        [appdelegate SwitchViewer:7];
    }
    else if([SelectedItem compare:@"push"] == 0)
    {
        [appdelegate SwitchViewer:8];
    }
    else if([SelectedItem compare:@"about"] == 0)
    {
        [appdelegate SwitchViewer:10];
    }
    else if([SelectedItem compare:@"home"] == 0)
    {
        [appdelegate SwitchViewer:0];
    }
    else if([SelectedItem compare:@"language"] == 0)
    {
        [appdelegate SwitchViewer:11];
    }
    else if([SelectedItem compare:@"back"] == 0)
    {
        //返回快選
        [stopsTakeTimeViewController actRemoveSearchView];
        [self actBtnSlideMenuTouchUpInside:self.btnSlideMenu];
    }
}
- (void) SilderMenuHiddenedEvent
{
    //NSLog(@"SilderMenu is Hiddened");
}
- (void) SilderMenuShowedEvent
{
    //NSLog(@"SilderMenu is Showed");
}

- (IBAction)actBtnSlideMenuTouchUpInside:(id)sender
{
    /*
     edit Cooper 2015/08/20
     0807buglist 台中第四項
     台中用額外的lib，所以只好一頁一頁改…
     */
    if([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        [SilderMenu SilderHidden];
        [self _showViewCover:NO];
        return;
    }
    if(![sender isSelected])
    {
        [SilderMenu SilderShow];
        [self _showViewCover:YES];
    }
    else
    {
        [SilderMenu SilderHidden];
        [self _showViewCover:NO];
    }
    [sender setSelected:![sender isSelected]];
}
/*
 edit Cooper 2015/08/20
 0807buglist 台中第四項
 台中用額外的lib，所以只好一頁一頁改…
 */
-(void)_showViewCover:(BOOL)bb
{
    if(!self.viewCover){
        self.viewCover = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        self.viewCover.backgroundColor = [UIColor grayColor];
        self.viewCover.alpha = 0.4;
        [self.viewCover addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actBtnSlideMenuTouchUpInside:)]];
        [self.viewMatrix addSubview:self.viewCover];
    }
    [self.viewCover setHidden:!bb];
}
#pragma mark - StopsTakeTimeDelegate
-(void)addHeaderBackButton
{
    [SilderMenu insertItem:LeftMenu_BackBtn];
}
-(void)removeHeaderBackButton
{
    [SilderMenu removeItem:LeftMenu_BackBtn];
}
-(void)startActivityIndicator
{
    [self.activityIndicator startAnimating];
}
-(void)stopActivityIndicator
{
    [self.activityIndicator stopAnimating];
}
@end
