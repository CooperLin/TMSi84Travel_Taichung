//
//  stopNearLinesViewController.m
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/3/5.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "stopNearLinesViewController.h"
#import "GDataXMLNode.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "AppDelegate.h"
#import "SilderMenuView.h"
#import "ShareTools.h"
#import "stopNearLineCell.h"

#define APINearRoute @"/iTravel/ItravelAPI/ExpoAPI/CrossRoutes.aspx?stopName=%@&routeID=%@&Type=%@&Lang=En"

@interface stopNearLinesViewController ()
<
UpdateTimerDelegate
>
{
    SilderMenuView * SilderMenu;
    NSMutableDictionary * LeftMenu_BackBtn;

    NSDictionary * dictionaryAPI;
    ASINetworkQueue * queueASIRequests;
    NSInteger intQueryFailCount;
    NSDictionary * dictionarySelectedStop;
    NSMutableArray * arrayTableviewRoutes;
    NSInteger integerUpdateTime;

}
@property (nonatomic, strong) UIView *viewCover;
@end

@implementation stopNearLinesViewController

#pragma mark - Set Timer
-(void)updateTimerTick:(NSUInteger)updateTime
{
    [self performSelectorOnMainThread:@selector(actUpdateTimeLabel) withObject:nil waitUntilDone:NO];
    
    integerUpdateTime++;
    
    if (integerUpdateTime%UpdateTime == 0)
    {
        [self SendQueryRequest:1];
    }
}

#pragma mark - Life Cycle
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
    // Do any additional setup after loading the view from its nib.
    
    [self actSetASIQueue];
    
    [self actSetQueryAPI];
    
    [self _showViewCover:NO];

    [self actSetSliderMenu];

    [self SendQueryRequest:1];
    
    [self actSetTitle];
}
-(void)viewWillAppear:(BOOL)animated
{
    appDelegate.updateTimer.delegate = self;
    self.labelSubTitle.text = NSLocalizedStringFromTable(@"經過路線",appDelegate.LocalizedTable,nil);
    [self.reflashBtn setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"32.png",appDelegate.LocalizedTable,nil)] forState:UIControlStateNormal];
}
-(void)viewWillDisappear:(BOOL)animated
{
    if (appDelegate.updateTimer.delegate == self)
    {
        appDelegate.updateTimer.delegate = nil;
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Env Setting
-(void)actSetTitle
{
    [self.labelTitle setText:[NSString stringWithFormat:@"%@(%@)",[appDelegate.selectedStop objectForKey:@"StopName"],[appDelegate.selectedStop objectForKey:@"nameZh"]]];
}
//ASIQueue設定
-(void)actSetASIQueue
{
    queueASIRequests = [[ASINetworkQueue alloc] init];
    queueASIRequests.maxConcurrentOperationCount = 2;
    
    // ASIHTTPRequest 默認的情況下，queue 中只要有一個 request fail 了，整個 queue 裡的所有 requests 也都會被 cancel 掉
    [queueASIRequests setShouldCancelAllRequestsOnFailure:NO];
    
    // go 只需要執行一次
    // [queueASIRequests go];
}
-(void)actSetQueryAPI
{
    NSString *s = @"Some string";
    const char *c = [s UTF8String];
    NSLog(@"%s",c);
    
    dictionarySelectedStop = (NSDictionary*)appDelegate.selectedStop;
    dictionaryAPI = @{
                      @1: [NSString stringWithFormat:APINearRoute,[ShareTools GetUTF8Encode:[dictionarySelectedStop objectForKey:@"StopName"]],appDelegate.selectedStop[@"ID"],appDelegate.selectedStop[@"Type"]],
//                      @1: [NSString stringWithFormat:APINearRoute,[[dictionarySelectedStop objectForKey:@"StopName"]dataUsingEncoding:NSUTF8StringEncoding] ,appDelegate.selectedStop[@"ID"],appDelegate.selectedStop[@"Type"]],
                      @"server":APIServer
                      };
}
-(void)actSetSliderMenu
{
    CGRect ContentFrame = self.ContentV.frame;
    SilderMenu = [[SilderMenuView alloc] initWithFrame:CGRectMake(0, 0, 135, self.view.frame.size.height)];
    [SilderMenu setSilderDelegate:self];
    [self.ContentV addSubview:SilderMenu];
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
    
    //加入返回鍵
    [SilderMenu insertItem:LeftMenu_BackBtn];
}
#pragma mark - UI Control
-(void)actUpdateTimeLabel
{
    [self.labelUpdateTime setText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"於 %d 秒前更新",appDelegate.LocalizedTable,nil),integerUpdateTime]];
}
-(void)stopActivityIndicator
{
    [self.activityIndicator stopAnimating];
    [self.ContentV setUserInteractionEnabled:YES];
}
-(void)startActivityIndicator
{
    [self.ContentV setUserInteractionEnabled:NO];
    [self.activityIndicator startAnimating];
}
#pragma mark - IBAction
- (IBAction)actBtnUpdateTouchUpInside:(id)sender
{
    [self SendQueryRequest:1];
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
        [self.ContentV addSubview:self.viewCover];
    }
    [self.viewCover setHidden:!bb];
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
        [self dismissViewControllerAnimated:YES completion:^{}];
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
#pragma mark - Query API
-(void)QueryRequestFail:(ASIHTTPRequest *)request
{
    if (intQueryFailCount<5)
    {
        intQueryFailCount++;
        [self SendQueryRequest:request.tag];
        return;
    }
    else
    {
#ifdef LogOut
        NSLog(@"Query fail %ld",(long)request.tag);
#endif
        intQueryFailCount = 0;
        if (queueASIRequests.operationCount==0)
        {
            [queueASIRequests setSuspended:YES];
//            [NSThread detachNewThreadSelector:@selector(stopActivityIndicator) toTarget:self withObject:nil];
            
        }
        switch (request.tag)
        {
            case 10:
                
                break;
                
            default:
                break;
        }
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:NSLocalizedStringFromTable(@"無法連接伺服器",appDelegate.LocalizedTable,nil) message:@"" delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK",appDelegate.LocalizedTable,nil) otherButtonTitles:nil];
        [alert show];
    }
    
    
}
/*
 tag 用來分辨request是取得什麼資料
 1:車站名查詢經過路線
 */
- (void) SendQueryRequest:(NSInteger)integerTag
{
    if ( ![ShareTools connectedToNetwork] )
    {
		return;
	}
    //queue裡面確認,避免重複送request
    if (queueASIRequests.operationCount)
    {
        for (ASIHTTPRequest *requestTmp in queueASIRequests.operations)
        {
            if (requestTmp.tag == integerTag)
            {
                return;
            }
        }
    }
    else
        if([queueASIRequests isSuspended])
        {
            [queueASIRequests go];
        }
    
//    [NSThread detachNewThreadSelector:@selector(startActivityIndicator) toTarget:self withObject:nil];
    
    NSString *UrlStr = [NSString stringWithFormat:@"%@%@",[dictionaryAPI objectForKey:@"server"],[dictionaryAPI objectForKey:[NSNumber numberWithInteger:integerTag]]];
	NSURL *url = [NSURL URLWithString:UrlStr];
    
	ASIHTTPRequest * QueryRequest = [ASIHTTPRequest requestWithURL:url];
    [QueryRequest setDelegate:self];
    [QueryRequest setDidFinishSelector:@selector(QueryJSONRequestFinish:)];
    [QueryRequest setDidFailSelector:@selector(QueryRequestFail:)];
    [QueryRequest setTimeOutSeconds:30.0];
    //queue裡面確認,避免重複送request
    QueryRequest.tag = integerTag;
    
    [queueASIRequests addOperation:QueryRequest];
#ifdef LogOut
    NSLog(@"RequestStr:%@",UrlStr);
#endif
}
-(void) QueryJSONRequestFinish :(ASIHTTPRequest *)request
{
    NSString * ResponseTxt = [request responseString];
    
    if([ResponseTxt hasPrefix:@"err"])
    {
        //err03查無資料,err01參數錯誤
        if ([ResponseTxt hasPrefix:@"err03"]||[ResponseTxt hasPrefix:@"err01"])
        {
            NSString * stringMessage = [NSString stringWithFormat:NSLocalizedStringFromTable(@"查無%@資料",appDelegate.LocalizedTable,nil),[dictionarySelectedStop objectForKey:@"StopName"]];
            UIAlertView * alert = [[UIAlertView alloc]initWithTitle:NSLocalizedStringFromTable(@"查無資料",appDelegate.LocalizedTable,nil) message:stringMessage delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確認",appDelegate.LocalizedTable,nil) otherButtonTitles:nil];
            [alert show];
            [self actSetArrayForTableView:nil];//清空tableview資料
        }
        else
        {
            [self QueryRequestFail:request];
            return;
        }
    }
    else
    {
        NSError * error;
        NSArray * arrayFromJSON = [NSJSONSerialization JSONObjectWithData:[request responseData] options:NSJSONReadingMutableLeaves error:&error];
#ifdef LogOut
        NSLog(@"error msg %@",error);
#endif
        if (error)
        {
            [self QueryRequestFail:request];
            return;
        }
        else
        {
            //query ok
            integerUpdateTime = 0;
            [self actSetArrayForTableView:arrayFromJSON];
        }
    }
    
    if (queueASIRequests.operationCount==0)
    {
        [queueASIRequests setSuspended:YES];
//        [NSThread detachNewThreadSelector:@selector(stopActivityIndicator) toTarget:self withObject:nil];
    }
}
-(void)actSetArrayForTableView:(NSArray*)array
{
    arrayTableviewRoutes = [NSMutableArray arrayWithArray:array];
    [self.tableViewRoutes reloadData];
}
#pragma mark - tableview Delegate&DataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return arrayTableviewRoutes.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    UITableViewCell * cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    //尋找tableview可回收Cell(需注意cell.xib要設定identifier,回收機制才有用)
    stopNearLineCell * cell = (stopNearLineCell*)[tableView dequeueReusableCellWithIdentifier:@"stopNearLineCell"];
    
    //若無可回收Cell則由Bundle取得
    if (cell == nil)
    {
        NSArray * nib = [[NSBundle mainBundle]loadNibNamed:@"stopNearLineCell" owner:self options:nil];
        for (id object in nib)
        {
            if ([object isKindOfClass:[stopNearLineCell class]])
            {
                cell = (stopNearLineCell*)object;
                break;
            }
        }
    }
    NSDictionary * dictionaryRoute = [arrayTableviewRoutes objectAtIndex:indexPath.row];
    
    NSString * stringPath;
    if ([[dictionaryRoute objectForKey:@"GoBack"]isEqualToString:@"1"])
    {
        stringPath = [NSString stringWithFormat:NSLocalizedStringFromTable(@"去程: %@ -> %@",appDelegate.LocalizedTable,nil),[dictionaryRoute objectForKey:@"Dept"],[dictionaryRoute objectForKey:@"Dest"]];
    }
    else
    {
        stringPath = [NSString stringWithFormat:NSLocalizedStringFromTable(@"返程: %@ -> %@",appDelegate.LocalizedTable,nil),[dictionaryRoute objectForKey:@"Dest"],[dictionaryRoute objectForKey:@"Dept"]];
    }
    
    
    
    [cell.labelRouteName setText:[dictionaryRoute objectForKey:@"RouteName"]];
    [cell.labelSerialNumber setText:[NSString stringWithFormat:@"%ld",(long)indexPath.row]];
    [cell.labelRouteToward setText:stringPath];
    
    //到站時間判斷
    NSString * stringTime1 = [dictionaryRoute objectForKey:@"Time1"];
    NSString * stringTime2 = [dictionaryRoute objectForKey:@"Time2"];
    NSString * stringTime;

    if ([stringTime1 isEqualToString:@"null"]||[stringTime1 isEqualToString:@""])
    {
        if ([stringTime2 isEqualToString:@"null"]||[stringTime2 isEqualToString:@""])
        {
            stringTime = NSLocalizedStringFromTable(@"未發車",appDelegate.LocalizedTable,nil);
        }
        else
        {
            stringTime = stringTime2;
        }
    }
    else
        if (stringTime1.intValue >= 2)
        {
            stringTime = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ 分",appDelegate.LocalizedTable,nil),stringTime1];
            
        }
    else
    {
        stringTime = NSLocalizedStringFromTable(@"進站中",appDelegate.LocalizedTable,nil);
    }
        
    
    [cell.labelRouteArriveTime setText:stringTime];

    return cell;
}
//-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    AppDelegate * delegate = [[UIApplication sharedApplication] delegate];
//    delegate.selectedRoute = arrayTableviewRoutes[indexPath.row];
//    [delegate SwitchViewer:2];
//}

@end
