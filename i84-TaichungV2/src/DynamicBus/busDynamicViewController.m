
//
//  busDynamicViewController.m
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/3/11.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "busDynamicViewController.h"
#import "GDataXMLNode.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "AppDelegate.h"
#import "ShareTools.h"
#import "busDynamicCell.h"
#import "stopNearLinesViewController.h"
#import "SilderMenuView.h"
#import "FavoritesManager.h"

#define APIRouteStops NSLocalizedStringFromTable(@"iTravelEstimateTime", appDelegate.LocalizedTable, nil)
#define APIStaticRoute @"%@/tcbus2/GetTimeTable.php?useXno=1&route=%@"

@interface busDynamicViewController ()
<
UpdateTimerDelegate
>
{
    ASINetworkQueue * queueASIRequests;
    NSMutableArray * arrayTableviewStops;
    NSMutableArray * arrayForwardStops;
    NSMutableArray * arrayBackwardStops;
    NSMutableDictionary * dictionarySelectedRoute;
    NSMutableDictionary * dictionaryAPI;
    
    SilderMenuView * SilderMenu;
    NSMutableDictionary * LeftMenu_BackBtn;

    NSInteger intQueryFail;
    NSInteger integerUpdateTime;
    
    webViewController * webViewControllerRoute;
    
    UISwipeGestureRecognizer *swipeToLeft;
    UISwipeGestureRecognizer *swipeToRight;
}
@property (strong, nonatomic) UIView *viewCover;
//@property (strong,nonatomic) stopNearLinesViewController * viewControllerStopNearLine;
@end

@implementation busDynamicViewController

#pragma mark - updateTimer delegate
-(void)updateTimerTick:(NSUInteger)updateTime
{
    [self performSelectorOnMainThread:@selector(actUpdateTimeLabel) withObject:nil waitUntilDone:NO];
    
    integerUpdateTime++;

    if (integerUpdateTime%UpdateTime == 0)
    {
        [self SendQueryRequest:DynamicTime];
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
    [self actSetEnviroment];
    [self actQueryData];
    [self actSetCellSeletedMenu];
    [self actSliderForwardAndBackward];
    [self _showViewCover:NO];
    [self actSetSliderMenu];//此View需放置在最上面(最後)
}

-(void)viewWillAppear:(BOOL)animated
{
    appDelegate.updateTimer.delegate = self;
    self.labelTitle.text = NSLocalizedStringFromTable(@"公車動態",appDelegate.LocalizedTable,nil);
    [self.reflashBtn setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"32.png",appDelegate.LocalizedTable,nil)] forState:UIControlStateNormal];
    [self.addToRemind setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"22.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    [self.addToFavorite setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"23.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    [self.passRoute setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"24.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    [self actHideFunctionMenu];
}
-(void)viewWillDisappear:(BOOL)animated
{
    if (appDelegate.updateTimer.delegate == self)
    {
        appDelegate.updateTimer.delegate = nil;
    }
    [SilderMenu SilderHidden];
}
-(void)actSetCellSeletedMenu
{
    [self.ContentV addSubview:self.viewCellSelectedMenu];
    [self actHideFunctionMenu];
}
-(void)actSetSliderMenu
{
    SilderMenu = [[SilderMenuView alloc] initWithFrame:CGRectMake(0, 0, 135, self.view.frame.size.height)];
    [SilderMenu setSilderDelegate:self];
    [self.ContentV addSubview:SilderMenu];
    [SilderMenu setItemsByPlistName:@"LeftMenu"];
    [self actSetSliderMenuBackBtn];
}
/*
 edit Cooper 2015/08/06
 0803_buglist
 台中 第三項 左右滑動可切換去返程
 */
-(void)actSliderForwardAndBackward
{
    swipeToLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_swipeHandler:)];
    swipeToRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_swipeHandler:)];
    swipeToLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    swipeToRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.tableViewMain addGestureRecognizer:swipeToRight];
    [self.tableViewMain addGestureRecognizer:swipeToLeft];
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
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)actSetAPI1
{
    NSString *str = NSLocalizedStringFromTable(@"iTravelEstimateTime", appDelegate.LocalizedTable, nil);
    NSString * stringAPI = [NSString stringWithFormat:str,
                            [dictionarySelectedRoute objectForKey:@"ID"],
                            [[dictionarySelectedRoute objectForKey:@"type"] isEqualToString:@"city"]?@"0":@"1"];
    if (dictionaryAPI)
    {
        [dictionaryAPI setObject:stringAPI forKey:@1];
    }
    dictionaryAPI = [NSMutableDictionary dictionaryWithDictionary:
                     @{
                       @1:stringAPI,
                       @"server":APIServer
                       }];
}

-(void)actQueryData
{
    [self actSetAPI1];
    if (!arrayTableviewStops)
    {
        [self SendQueryRequest:DynamicTime];
    }
}
/*
 edit Cooper 2015/08/06
 0803_buglist
 台中 第二項 單向公車路線不應該有返程標籤
 */
-(NSInteger)_objLength:(id)sender
{
    NSString *str = [NSString stringWithFormat:@"%@",sender];
    return str.length;
}
-(void)actSetEnviroment
{
    //接收上個View的參數
    dictionarySelectedRoute = [NSMutableDictionary dictionaryWithDictionary: appDelegate.selectedRoute];
    
    //設定各Title
    /*
     edit Cooper 2015/08/06
     0803_buglist
     台中 第二項 單向公車路線不應該有返程標籤
     */
    [self.labelBusName setText:[dictionarySelectedRoute objectForKey:@"nameZh"]];
    self.btnForward.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.btnForward setTitle:[NSString stringWithFormat:@"%@%@",[self _objLength:[dictionarySelectedRoute objectForKey:@"destinationZh"]]?NSLocalizedStringFromTable(@"往",appDelegate.LocalizedTable,nil):@"",[dictionarySelectedRoute objectForKey:@"destinationZh"]] forState:UIControlStateNormal];
    self.btnBackward.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.btnBackward setTitle:[NSString stringWithFormat:@"%@%@",[self _objLength:[dictionarySelectedRoute objectForKey:@"departureZh"]]?NSLocalizedStringFromTable(@"往",appDelegate.LocalizedTable,nil):@"",[dictionarySelectedRoute objectForKey:@"departureZh"]] forState:UIControlStateNormal];
    
    /*
     edit Cooper 2015/08/06
     0803_buglist
     台中 第三項 左右滑動可切換去返程
     */
    self.btnForward.layer.borderWidth = 1.0f;
    self.btnForward.layer.borderColor = [UIColor whiteColor].CGColor;
    
    //ASIQueue設定
    {
        queueASIRequests = [[ASINetworkQueue alloc] init];
        queueASIRequests.maxConcurrentOperationCount = 2;
        
        // ASIHTTPRequest 默認的情況下，queue 中只要有一個 request fail 了，整個 queue 裡的所有 requests 也都會被 cancel 掉
        [queueASIRequests setShouldCancelAllRequestsOnFailure:NO];
        
        // go 只需要執行一次
        //    [queueASIRequests go];
    }
}

#pragma mark - Query API
-(void)QueryRequestFail:(ASIHTTPRequest *)request
{
    
    if (intQueryFail<5)
    {
        intQueryFail++;
        [self SendQueryRequest:request.tag];
        return;
    }
    else
    {
#ifdef LogOut
        NSLog(@"Query fail %ld",(long)request.tag);
#endif
        intQueryFail = 0;
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
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:NSLocalizedStringFromTable(@"無法連接伺服器",appDelegate.LocalizedTable,nil) message:nil delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK",appDelegate.LocalizedTable,nil) otherButtonTitles:nil];
        [alert show];
    }
}
/*
 tag 用來分辨request是取得什麼資料
 1:route 1,

 */
- (void) SendQueryRequest:(BusDynamicRequestType)intType
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
            if (requestTmp.tag == intType)
            {
                return;
            }
        }
    }
    else if([queueASIRequests isSuspended])
    {
        [queueASIRequests go];
    }
    
//    [NSThread detachNewThreadSelector:@selector(startActivityIndicator) toTarget:self withObject:nil];
    
    NSString *UrlStr = [NSString stringWithFormat:@"%@%@",[dictionaryAPI objectForKey:@"server"],[dictionaryAPI objectForKey:[NSNumber numberWithInteger:intType]]];
	NSURL *url = [NSURL URLWithString:UrlStr];
    
	ASIHTTPRequest * QueryRequest = [ASIHTTPRequest requestWithURL:url];
    [QueryRequest setDelegate:self];
    [QueryRequest setDidFinishSelector:@selector(QueryJSONRequestFinish:)];
    [QueryRequest setDidFailSelector:@selector(QueryRequestFail:)];
    [QueryRequest setTimeOutSeconds:30.0];
    //queue裡面確認,避免重複送request
    QueryRequest.tag = intType;
    
    [queueASIRequests addOperation:QueryRequest];
//#ifdef LogOut
    NSLog(@"RequestStr:%@",UrlStr);
//#endif
}

-(void) QueryJSONRequestFinish :(ASIHTTPRequest *)request
{
    NSString * ResponseTxt = [request responseString];
    
    if([ResponseTxt hasPrefix:@"err"])
    {
        //err03查無資料,err01參數錯誤
        if ([ResponseTxt hasPrefix:@"err03"]||[ResponseTxt hasPrefix:@"err01"])
        {
            NSString * stringMessage = [NSString stringWithFormat:NSLocalizedStringFromTable(@"查無%@資料",appDelegate.LocalizedTable,nil),[dictionarySelectedRoute objectForKey:@"RouteName"]];
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
            //Quary成功
            [self actSeparateArrayByTowards:arrayFromJSON];
        }
    }
    
    if (queueASIRequests.operationCount==0)
    {
        [queueASIRequests setSuspended:YES];
//        [NSThread detachNewThreadSelector:@selector(stopActivityIndicator) toTarget:self withObject:nil];
    }
}
-(void)actSeparateArrayByTowards:(NSArray*)arrayTobeSeparated
{
    if (arrayForwardStops)
    {
        [arrayForwardStops removeAllObjects];
    }
    else
    {
        arrayForwardStops = [NSMutableArray new];
    }
    if (arrayBackwardStops)
    {
        [arrayBackwardStops removeAllObjects];
    }
    else
    {
        arrayBackwardStops = [NSMutableArray new];
    }
    
    for(NSMutableDictionary * dictionaryStop in arrayTobeSeparated)
    {
        NSString * stringToward = [dictionaryStop objectForKey:@"GoBack"];
        if (stringToward.intValue == 1)
        {
            [arrayForwardStops addObject:dictionaryStop];
        }
        else if (stringToward.intValue == 2)
        {
            [arrayBackwardStops addObject:dictionaryStop];
        }
    }
    integerUpdateTime = 0;

    if ([self.btnForward isSelected])
    {
        [self actSetArrayForTableView:arrayForwardStops];
    }
    else
        if ([self.btnBackward isSelected])
    {
        [self actSetArrayForTableView:arrayBackwardStops];
    }
}
//過濾資料
-(void)actSetArrayForTableView:(NSMutableArray*)array
{
    arrayTableviewStops = array;
    [self.tableViewMain reloadData];
}



#pragma mark - tableview Delegate&DataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return arrayTableviewStops.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //尋找tableview可回收Cell(需注意cell.xib要設定identifier,回收機制才有用)
    busDynamicCell * cell = (busDynamicCell*)[tableView dequeueReusableCellWithIdentifier:@"busDynamicCell"];
    
    //若無可回收Cell則由Bundle取得
    if (cell == nil)
    {
        NSArray *nib=[[NSBundle mainBundle]loadNibNamed:@"busDynamicCell" owner:self options:nil];
        for (id object in nib)
        {
            if ([object isKindOfClass:[busDynamicCell class]])
            {
                cell = (busDynamicCell*)object;
                break;
            }
        }
    }
    NSDictionary * dictionaryRouteStop = [arrayTableviewStops objectAtIndex:indexPath.row];
    
    //站序
    [cell.labelSequence setText:[NSString stringWithFormat:@"%ld",(long)indexPath.row+1]];
    
    //站名
    [cell.labelStopName setText:[dictionaryRouteStop objectForKey:@"StopName"]];
    
    //到站時間及底色
    NSString * stringTime1tmp = [dictionaryRouteStop objectForKey:@"ComeTime"];
    NSString * stringTime2tmp = [dictionaryRouteStop objectForKey:@"ComeTime2"];
    
    if (stringTime1tmp.intValue >=2)
    {
        if (stringTime1tmp.intValue>=3)
        {
            [cell.imageTimeBackground setImage:[UIImage imageNamed:@"realarrival_arrivalbg2"]];
        }
        else
        {
            [cell.imageTimeBackground setImage:[UIImage imageNamed:@"realarrival_arrivalbg3"]];
        }
        [cell.labelTime setText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"%@分",appDelegate.LocalizedTable,nil),stringTime1tmp]];
    }
    else
        if (stringTime1tmp.intValue == -3)
        {
            [cell.labelTime setText:NSLocalizedStringFromTable(@"末班已過",appDelegate.LocalizedTable,nil)];
            [cell.imageTimeBackground setImage:[UIImage imageNamed:@"realarrival_arrivalbg1"]];
        }
    else
        if ([stringTime1tmp isEqualToString:@"0"] || stringTime1tmp.intValue>0)
        {
            [cell.labelTime setText:NSLocalizedStringFromTable(@"進站中",appDelegate.LocalizedTable,nil)];
            [cell.imageTimeBackground setImage:[UIImage imageNamed:@"realarrival_arrivalbg4"]];
        }
    else
        if ([stringTime2tmp isEqualToString:@"null"]||[stringTime2tmp isEqualToString:@""])
        {
            [cell.labelTime setText:NSLocalizedStringFromTable(@"未發車",appDelegate.LocalizedTable,nil)];
            [cell.imageTimeBackground setImage:[UIImage imageNamed:@"realarrival_arrivalbg1"]];
        }
        else
        {
            [cell.labelTime setText:[dictionaryRouteStop objectForKey:@"ComeTime2"]];
            [cell.imageTimeBackground setImage:[UIImage imageNamed:@"realarrival_arrivalbg1"]];
        }
    
    //車牌
    NSString * stringBusPlate = [dictionaryRouteStop objectForKey:@"CarID"];
    if (![stringBusPlate isEqualToString:@""]) //濾掉重複顯示車牌(比對上一個Cell的車牌若是相同就不顯示)
    {
        NSString * stringBusPlatePrevious;
        if (indexPath.row>0)
        {
            stringBusPlatePrevious = [[arrayTableviewStops objectAtIndex:(indexPath.row-1)]objectForKey:@"CarID"];
        }
        if ([stringBusPlatePrevious isEqualToString:stringBusPlate])
        {
            stringBusPlate = @"";
        }
    }
    [cell.labelBusPlate setText:stringBusPlate];
    
    //車牌底圖
    if ([stringBusPlate isEqualToString:@""])
    {
        [cell.imageBusPlateBackground setImage:nil];;
    }
    else
    {
        [cell.imageBusPlateBackground setImage:[UIImage imageNamed:@"57"]];
    }
    
    //車種
    NSString * stringCarType =[dictionaryRouteStop objectForKey:@"CarType"];
    if (stringBusPlate&&![stringBusPlate isEqualToString:@""])
    {
        if ([stringCarType isEqualToString:@"dual_s"])
        {
            [cell.imageBusType setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"29",appDelegate.LocalizedTable,nil)]];
        }
        else
            if ([stringCarType isEqualToString:@"dual"])
            {
                [cell.imageBusType setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"30",appDelegate.LocalizedTable,nil)]];
            }
            else
                if ([stringCarType isEqualToString:@"lfv"])
                {
                    [cell.imageBusType setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"31",appDelegate.LocalizedTable,nil)]];
                }
                else
                    if ([stringCarType isEqualToString:@"ev"])
                    {
                        [cell.imageBusType setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"28",appDelegate.LocalizedTable,nil)]];
                    }
                    else
                        if ([stringCarType isEqualToString:@"3d"])
                        {
                            [cell.imageBusType setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"3d",appDelegate.LocalizedTable,nil)]];
                        }
                        else
                            if ([stringCarType isEqualToString:@"hyv"])
                            {
                                [cell.imageBusType setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"hyv",appDelegate.LocalizedTable,nil)]];
                            }
                            else
                            {
                                [cell.imageBusType setImage:nil];
                            }
    }
    else
    {
        [cell.imageBusType setImage:nil];
    }
    
    
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSMutableDictionary * dictionaryStopTmp = [NSMutableDictionary dictionaryWithDictionary:[arrayTableviewStops objectAtIndex:indexPath.row]];
    [dictionaryStopTmp setValuesForKeysWithDictionary:appDelegate.selectedRoute];
    
    appDelegate.selectedStop = dictionaryStopTmp;
    
    //animation
    [self.viewCellSelectedMenu setAlpha:0.1];
    [self actShowFunctionMenu];
    [UIView beginAnimations:@"showMenu" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [self.viewCellSelectedMenu setAlpha:1.0];
    [UIView commitAnimations];  
    
    
}
#pragma mark - UI control
-(void)actUpdateTimeLabel
{
    [self.labelUpdateTime setText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"於 %d 秒前更新",appDelegate.LocalizedTable,nil),integerUpdateTime]];
}
-(void)stopActivityIndicator
{
    [self.activityIndicator stopAnimating];
    [self.tableViewMain setUserInteractionEnabled:YES];
}
-(void)startActivityIndicator
{
    [self.tableViewMain setUserInteractionEnabled:NO];
    [self.activityIndicator startAnimating];
}
//我的最愛,到站提醒menu
-(void)actShowFunctionMenu
{
    if (self.viewCellSelectedMenu.frame.origin.x >= self.ContentV.frame.size.width)
    {
        CGRect frame = self.ContentV.bounds;
        [self.viewCellSelectedMenu setFrame:frame];
    }
}
-(void)actHideFunctionMenu
{
    if (self.viewCellSelectedMenu.frame.origin.x <= self.ContentV.frame.size.width)
    {
        //設定menu的Frame與ContainV同大小 並放置於右側畫面外
        CGRect frameNew = self.ContentV.bounds;
        frameNew.origin.x = self.ContentV.frame.size.width;
        [self.viewCellSelectedMenu setFrame:frameNew];
    }
}
/*
 edit Cooper 2015/08/06
 0803_buglist
 台中 第三項 左右滑動可切換去返程
 */
-(void)_swipeHandler:(UIGestureRecognizer *)gesture
{
    if([self.btnBackward isSelected]){
        if(gesture == swipeToLeft)return;
        self.btnBackward.backgroundColor = [UIColor blackColor];
        self.btnForward.layer.borderWidth = 1.0f;
        self.btnForward.layer.borderColor = [UIColor whiteColor].CGColor;
        self.btnBackward.layer.borderWidth = 1.0f;
        self.btnBackward.layer.borderColor = [UIColor blackColor].CGColor;

        [self.btnForward setSelected:YES];
        [self.btnBackward setSelected:NO];
        [self actSetArrayForTableView:arrayForwardStops];
    }else {
        if(![self _objLength:[dictionarySelectedRoute objectForKey:@"departureZh"]])return;
        if(gesture == swipeToRight)return;
        self.btnForward.backgroundColor = [UIColor blackColor];
        self.btnBackward.layer.borderWidth = 1.0f;
        self.btnBackward.layer.borderColor = [UIColor whiteColor].CGColor;
        self.btnForward.layer.borderWidth = 1.0f;
        self.btnForward.layer.borderColor = [UIColor blackColor].CGColor;
        [self.btnForward setSelected:NO];
        [self.btnBackward setSelected:YES];
        [self actSetArrayForTableView:arrayBackwardStops];
    }
}
#pragma mark - IBAction
- (IBAction)actBtnTowardTouchUpInside:(id)sender
{
     UIButton* btnSelect =(UIButton*)sender;
    if (![btnSelect isSelected])
    {
        if (btnSelect == self.btnForward)
        {
            /*
             edit Cooper 2015/08/06
             0803_buglist
             將按鈕變動的動作集中在_swipeHandler: 裡面
             */
            [self _swipeHandler:swipeToRight];
        }
        else
        {
            /*
             edit Cooper 2015/08/06
             0803_buglist
             將按鈕變動的動作集中在_swipteHandler: 裡面
             */
            [self _swipeHandler:swipeToLeft];
        }
    }

}
- (IBAction)actBtnMenuTouchUpInside:(id)sender
{
    UIButton * buttonSelected = (UIButton*)sender;
    
    //animation
    [UIView beginAnimations:@"hide Menu" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [self.viewCellSelectedMenu setAlpha:0.1];
    [UIView commitAnimations];
    [self actHideFunctionMenu];
    
    NSString * stringRouteName = [appDelegate.selectedStop objectForKey:@"nameZh"];
    NSString * stringStopName = [appDelegate.selectedStop objectForKey:@"StopName"];
    NSString * stringStopID = [appDelegate.selectedStop objectForKey:@"StopID"];
    NSString * stringRouteID = [appDelegate.selectedStop objectForKey:@"ID"];
    int intBusToward = [[appDelegate.selectedStop objectForKey:@"GoBack"] intValue];
    int intBusType = [[appDelegate.selectedStop objectForKey:@"Type"] intValue];
    
    NSString * stringStopCoorTmp = [appDelegate.selectedStop objectForKey:@"StopCoor"];
    float floatLatitude = [[[stringStopCoorTmp componentsSeparatedByString:@","]objectAtIndex:1] floatValue];
    float floatLongitude = [[[stringStopCoorTmp componentsSeparatedByString:@","]objectAtIndex:0] floatValue];
    
    NSString * stringAlertTitle = nil;
    NSString * stringAlertMessage = nil;
    NSString * stringAlertCancelBtn = NSLocalizedStringFromTable(@"確認",appDelegate.LocalizedTable,nil);
    NSString * stringAlertOtherBtn = nil;
    
    switch (buttonSelected.tag)
    {
        case 1:
        {
            //加入到站提醒
            FavoriteResult addPushResult = [FavoritesManager
                                            AddToPushsByRouteId:stringRouteID
                                            RouteName:stringRouteName
                                            StopId:stringStopID
                                            StopName:stringStopName
                                            GoBack:intBusToward
                                            RouteKind:intBusType];
            switch (addPushResult)
            {
                case success:
                {
                    PushViewer * pushViewer = [[PushViewer alloc]initWithNibName:@"PushView" bundle:nil];
                    pushViewer.boolFromBusDynamic = YES;
                    [self presentViewController:pushViewer animated:YES completion:^{}];
                }
                    break;
                case fail:
                {
                    stringAlertTitle = NSLocalizedStringFromTable(@"到站提醒加入失敗",appDelegate.LocalizedTable,nil);
                    stringAlertMessage = NSLocalizedStringFromTable(@"請重新操作一遍",appDelegate.LocalizedTable,nil);
                    
                    UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:stringAlertTitle message:stringAlertMessage delegate:self cancelButtonTitle:stringAlertCancelBtn otherButtonTitles:stringAlertOtherBtn, nil];
                    [alertView show];
                }
                    break;
                case hased:
                {
                    stringAlertTitle = NSLocalizedStringFromTable(@"此站已加入過提醒",appDelegate.LocalizedTable,nil);
                    stringAlertMessage = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@%@已在到站提醒列表中",appDelegate.LocalizedTable,nil),stringRouteName,stringStopName];
                    
                    UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:stringAlertTitle message:stringAlertMessage delegate:self cancelButtonTitle:stringAlertCancelBtn otherButtonTitles:stringAlertOtherBtn, nil];
                    [alertView show];
                }
                    break;
                    
                default:
                    break;
            }

        }
            break;
        case 2:
        {
            //加入我的最愛
            
            FavoriteResult addFavoriteResult = [FavoritesManager
                                                AddToFavoritesByRouteId:stringRouteID
                                                RouteName:stringRouteName
                                                StopId:stringStopID
                                                StopName:stringStopName
                                                GoBack:intBusToward
                                                RouteKind:intBusType
                                                Lon:floatLongitude
                                                Lat:floatLatitude];
            
            switch (addFavoriteResult)
            {
                case success:
                {
                    stringAlertTitle = @"我的最愛加入成功";
                    stringAlertMessage = [NSString stringWithFormat:@"路線:%@ 站別:%@已加入我的最愛",stringRouteName,stringStopName];
                }
                    break;
                case fail:
                {
                    stringAlertTitle = NSLocalizedStringFromTable(@"我的最愛加入失敗",appDelegate.LocalizedTable,nil);
                    stringAlertMessage = NSLocalizedStringFromTable(@"請重新操作一遍",appDelegate.LocalizedTable,nil);
                }
                    break;
                case hased:
                {
                    stringAlertTitle = NSLocalizedStringFromTable(@"我的最愛資料重複",appDelegate.LocalizedTable,nil);
                    stringAlertMessage = [NSString stringWithFormat:NSLocalizedStringFromTable(@"路線:%@ 站別:%@ 已在我的最愛列表中",appDelegate.LocalizedTable,nil),stringRouteName,stringStopName];
                }
                    break;
                    
                default:
                    break;
            }
            UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:stringAlertTitle message:stringAlertMessage delegate:self cancelButtonTitle:stringAlertCancelBtn otherButtonTitles:stringAlertOtherBtn, nil];
            [alertView show];
        }
            break;
        case 3:
        {
            stopNearLinesViewController * nearViewController = [[stopNearLinesViewController alloc]initWithNibName:@"stopNearLinesViewController" bundle:nil];
            [self presentViewController:nearViewController animated:YES completion:^{}];
        }
            break;
        case 4:
        {
        }
            break;
            
        default:
            break;
    }

}

- (IBAction)actBtnUpdateTouchUpInside:(id)sender
{
    [self SendQueryRequest:DynamicTime];
}

- (IBAction)actBtnStaticBusTouchUpInside:(id)sender
{
    UIButton * btnStaticBus = (UIButton*)sender;
    
    [btnStaticBus setSelected:!btnStaticBus.selected];
    
    if ([sender isSelected])
    {
        [self actInsertWebView];
    }
    else
    {
        [self actRemoveWebView];
    }
}
-(void)actInsertWebView
{
    if (!webViewControllerRoute)
    {
        webViewControllerRoute = [[webViewController alloc]initWithNibName:@"webViewController" bundle:nil];
        webViewControllerRoute.view.frame = self.ContentV.bounds;
    }
    webViewControllerRoute.delegate = self;
    [self addChildViewController:webViewControllerRoute];
    [self.ContentV insertSubview:webViewControllerRoute.view belowSubview:SilderMenu];
//    NSLog(@"\ncontentV frame %@\nwebView frame %@",NSStringFromCGRect(self.ContentV.frame),NSStringFromCGRect(webViewControllerRoute.view.frame));
}
-(void)actRemoveWebView
{
    if (webViewControllerRoute.parentViewController == self)
    {
    webViewControllerRoute.delegate = nil;
    [webViewControllerRoute.view removeFromSuperview];
    [webViewControllerRoute removeFromParentViewController];
    }
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
        if (self.boolFromFavorite)
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
        //返回快選
        [appdelegate SwitchViewer:1];
        }
    }
    [SilderMenu SilderHidden];
}
- (void) SilderMenuHiddenedEvent
{
    //NSLog(@"SilderMenu is Hiddened");
}
- (void) SilderMenuShowedEvent
{
    //NSLog(@"SilderMenu is Showed");
}
#pragma mark - WebViewDelegate
-(NSString *)webViewStartUrlOnWebViewController:(id)webViewController
{
    NSString * stringUrl = nil;
    NSDictionary * dictionaryRoute = appDelegate.selectedRoute;
    NSString * stringRoute = [dictionaryRoute objectForKey:@"ID"];
    stringUrl = [NSString stringWithFormat:APIStaticRoute,APIServer,stringRoute];
    return stringUrl;
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self actHideFunctionMenu];
}
@end
