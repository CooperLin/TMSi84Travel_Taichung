//
//  nearStopViewController.m
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/3/5.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "nearStopViewController.h"
#import "AppDelegate.h"
#import "ShareTools.h"
#import "ASINetworkQueue.h"
#import "ASIHTTPRequest.h"
#import "stopNearLineCell.h"
#import "stopMapViewController.h"
#import "DataManager+Route.h"
//http://citybus.taichung.gov.tw/itravel/itravelAPI/ExpoAPI/NearByStop.aspx?Lon=120.686956&Lat=24.187241&Range=1000
//#define APIRouteByCoordinate @"/itravel/itravelAPI/ExpoAPI/NearByStop.aspx?Lon=%0.6f&Lat=%0.6f&Range=%ld"
#define APIRouteByCoordinate NSLocalizedStringFromTable(@"RouteByCoordinate",appDelegate.LocalizedTable,nil)

@interface nearStopViewController ()
<
UpdateTimerDelegate
>
{
    SilderMenuView * SilderMenu;
    NSMutableDictionary * LeftMenu_BackBtn;

    ASINetworkQueue * queueASIRequests;
    NSDictionary * dictionaryAPI;
    NSInteger intQueryFailCount;
    CLLocation * cllocationHere;//目前取得的座標
    CLLocation * cllocationQuery;//傳入API時的座標,用來判斷若距離太近不重新send query,避免loading過大
    NSInteger integerSelectedDistance;
    CLLocationManager * locationManager;
    NSMutableArray * arrayData;
    stopMapViewController * mapViewController;
    NSInteger integerUpdateTime;
    
    NSMutableArray * arrayRoutesCity;
    NSMutableArray * arrayRoutesHighway;

}
@property (nonatomic, strong) UIView *viewCover;
@end

@implementation nearStopViewController
#pragma mark - updatetimerDelegate
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
    [self _showViewCover:NO];
    [self actSetSliderMenu];
    [self actSetASIQueue];
    [self actSetCLLocationManager];
}
-(void)viewWillAppear:(BOOL)animated
{
    appDelegate.updateTimer.delegate = self;
    [self.btn100 setTitle:NSLocalizedStringFromTable(@"100公尺", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    [self.btn300 setTitle:NSLocalizedStringFromTable(@"300公尺", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    [self.btn500 setTitle:NSLocalizedStringFromTable(@"500公尺", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    [self.reflashBtn setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"32.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    self.NearStopTitle.text = NSLocalizedStringFromTable(@"附近站牌", appDelegate.LocalizedTable, nil);
    [self.labelUpdateTime setText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"於 %d 秒前更新",appDelegate.LocalizedTable,nil),integerUpdateTime]];
}
-(void)viewWillDisappear:(BOOL)animated
{
    [self actHideMap];
    [locationManager stopUpdatingLocation];
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
-(void)actSetCLLocationManager
{
    locationManager = [[CLLocationManager alloc] init];
    [locationManager setDelegate:self];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [locationManager startUpdatingLocation];
}
-(void)actSetASIQueue
{
    queueASIRequests = [[ASINetworkQueue alloc] init];
    queueASIRequests.maxConcurrentOperationCount = 5;
    
    // ASIHTTPRequest 默認的情況下，queue 中只要有一個 request fail 了，整個 queue 裡的所有 requests 也都會被 cancel 掉
    [queueASIRequests setShouldCancelAllRequestsOnFailure:NO];
    
    // go 只需要執行一次
    //    [queueASIRequests go];
}
-(void)actQueryData
{
    arrayRoutesCity =[DataManager getDataByType:RouteDataTypeCityRoutes];
    arrayRoutesHighway = [DataManager getDataByType:RouteDataTypeHighwayRoutes];
    if (integerSelectedDistance<=0)//初始時距離按鈕未選擇過
    {
        for (id sender in self.viewDistanceButtons.subviews)
        {
            if ([sender isKindOfClass:[UIButton class]] && [sender isSelected])
            {
                integerSelectedDistance = [sender tag];
                break;
            }
        }
    }
    //臺中市交通局 24.139902, 120.677596
//    cllocationHere = [[CLLocation alloc]initWithLatitude:24.1399  longitude:120.6776];

    dictionaryAPI = @{
                      @1:[NSString stringWithFormat:APIRouteByCoordinate,cllocationHere.coordinate.longitude,cllocationHere.coordinate.latitude,(long)integerSelectedDistance],
                      @"server":APIServer
                      };
    [self SendQueryRequest:1];
}
-(void)actSetSliderMenu
{
//    CGRect ContentFrame = self.ContentV.frame;
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
    
}
#pragma mark - UI Control
-(void)actShowMapAtStop:(id)idStop
{
    if (!mapViewController)
    {
        mapViewController = [[stopMapViewController alloc]initWithNibName:@"stopMapViewController" bundle:nil];
        mapViewController.view.frame = self.ContentV.bounds;
    }
    mapViewController.idSelectedStop = idStop;
    [self addChildViewController:mapViewController];
    [self.ContentV insertSubview:mapViewController.view belowSubview:SilderMenu];
    
    //左側選單加入返回鍵
    [SilderMenu insertItem:LeftMenu_BackBtn];

}
-(void)actHideMap
{
    if (mapViewController)
    {
        [mapViewController.view removeFromSuperview];
        [mapViewController removeFromParentViewController];
    }
    
    //選單刪除返回鍵
    [SilderMenu removeItem:LeftMenu_BackBtn];
    
}
-(void)actUpdateTimeLabel
{
    [self.labelUpdateTime setText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"於 %d 秒前更新",appDelegate.LocalizedTable,nil),integerUpdateTime]];
}
-(void)stopActivityIndicator
{
    [self.activityIndicator stopAnimating];
    [self.view setUserInteractionEnabled:YES];
}
-(void)startActivityIndicator
{
    [self.view setUserInteractionEnabled:NO];
    [self.activityIndicator startAnimating];
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
        [self actHideMap];
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
#pragma mark - IBAction
- (IBAction)actBtnSlideMenuTouchUpInside:(id)sender
{
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

- (IBAction)actBtnDistanceTouchUpInside:(id)sender
{
    for (id button in self.viewDistanceButtons.subviews)
    {
        [(UIButton*)button setSelected                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              :NO];
    }
    [sender setSelected:YES];
    integerSelectedDistance = [sender tag];
    [self actQueryData];
}

- (IBAction)actBtnUpdateTouchUpInside:(id)sender
{
    [self SendQueryRequest:1];
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
            [NSThread detachNewThreadSelector:@selector(stopActivityIndicator) toTarget:self withObject:nil];

        }
        switch (request.tag)
        {
            case 10:
                
                break;
                
            default:
                break;
        }
//        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"無法連接伺服器" message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//        [alert show];
        [self actGroupArray:nil];
    }
}
/*
 tag 用來分辨request是取得什麼資料
 1:
 
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
                if (integerTag == 1)
                {
                    [queueASIRequests cancelAllOperations];
                }
                else
                {
                    return;
                }
            }
        }
    }
    else if([queueASIRequests isSuspended])
    {
        [queueASIRequests go];
    }
    
    [NSThread detachNewThreadSelector:@selector(startActivityIndicator) toTarget:self withObject:nil];
    
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
        if ([ResponseTxt hasPrefix:@"err03"])
        {
//            NSString * stringMessage = [NSString stringWithFormat:@"%ld%@",(long)integerSelectedDistance,NSLocalizedStringFromTable(@"公尺內無站牌資料",appDelegate.LocalizedTable,nil)];
            NSString *stringMessage = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%ld公尺內無站牌資料", appDelegate.LocalizedTable, nil),(long)integerSelectedDistance];
            
            UIAlertView * alert = [[UIAlertView alloc]initWithTitle:NSLocalizedStringFromTable(@"查無資料",appDelegate.LocalizedTable,nil) message:stringMessage delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確認",appDelegate.LocalizedTable,nil) otherButtonTitles:nil];
            [alert show];
            [self actGroupArray:nil];
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
            //query 成功
            integerUpdateTime = 0;
            [self actGroupArray:arrayFromJSON];
        }
    }
    
    if (queueASIRequests.operationCount==0)
    {
        [queueASIRequests setSuspended:YES];
        [NSThread detachNewThreadSelector:@selector(stopActivityIndicator) toTarget:self withObject:nil];
    }
}

//將資料依站牌分
-(void)actGroupArray:(NSArray*)arrayJSON
{
    NSMutableArray * arrayOriginal = [NSMutableArray arrayWithArray:arrayJSON];
    
    if (!arrayData)
    {
        arrayData = [[NSMutableArray alloc]init];
    }
    else
        if (arrayData>0)
        {
            [arrayData removeAllObjects];
        }
    
    //將接到的array(API路線)依站牌區分dictionary[[站牌1array],[站牌2array],.....]
    while (arrayOriginal.count>0)
    {
//        NSString * stringRoute0StopID = [[arrayOriginal objectAtIndex:0]objectForKey:@"StopID"];
        NSString * stringRoute0Type = [[arrayOriginal objectAtIndex:0]objectForKey:@"Type"];
        NSString * stringRoute0Location = [[arrayOriginal objectAtIndex:0]objectForKey:@"StopCoor"];
        NSString * stringRoute0StopName = [[arrayOriginal objectAtIndex:0]objectForKey:@"StopName"];
        CLLocation * cllocationStop = [[CLLocation alloc]
                                       initWithLatitude:[[[stringRoute0Location componentsSeparatedByString:@","] objectAtIndex:1] doubleValue]
                                       longitude:[[[stringRoute0Location componentsSeparatedByString:@","] objectAtIndex:0] doubleValue]];
        CLLocationDistance distance = [cllocationQuery distanceFromLocation:cllocationStop];


        NSMutableArray * arraySub = [NSMutableArray new];
        int i = 0;
        while (i<arrayOriginal.count)
        {
            NSString * stringRouteStopName = [[arrayOriginal objectAtIndex:i]objectForKey:@"StopName"];
            NSString * stringRouteType = [[arrayOriginal objectAtIndex:i]objectForKey:@"Type"];
            if ([stringRouteType isEqualToString:stringRoute0Type] && [stringRouteStopName isEqualToString:stringRoute0StopName])
            {
                id dictionaryJSONRoute = [arrayOriginal objectAtIndex:i];
                [arrayOriginal removeObject:dictionaryJSONRoute];
                
                [arraySub addObject:dictionaryJSONRoute];
            }
            else
            {
                i++;
            }
        }
        NSMutableDictionary * dictionaryGroupByStop = [NSMutableDictionary new];
        
        [dictionaryGroupByStop setObject:[NSString stringWithFormat:@"%f",distance]forKey:@"distance"];
        
        [dictionaryGroupByStop setObject:stringRoute0StopName forKey:@"StopName"];

        [dictionaryGroupByStop setObject:arraySub forKey:@"routesData"];
        [arrayData addObject:dictionaryGroupByStop];
    }
    
    //將array依距離排序
    NSSortDescriptor *sortDescriptor=[[NSSortDescriptor alloc]initWithKey:@"distance" ascending:YES comparator:^(id obj1, id obj2)
                                      {
                                          return [obj1 compare:obj2 options:NSNumericSearch];
                                      }];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    [arrayData sortedArrayUsingDescriptors:sortDescriptors ];
    
    [self.tableViewMain reloadData];
}
#pragma mark - CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    cllocationHere = [locations lastObject];
//    cllocationHere = [[CLLocation alloc]initWithLatitude:24.179  longitude:120.645];
    if (!cllocationQuery )
    {
        cllocationQuery = cllocationHere;
    }
    else
        if ([cllocationQuery distanceFromLocation:cllocationHere]>15.0)
        {
            cllocationQuery = cllocationHere;

        }

    
    if(cllocationQuery == cllocationHere && cllocationQuery.coordinate.latitude>0 && cllocationQuery.coordinate.longitude>0)
    {
        [self actQueryData];
    }
}
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if([error code] == kCLErrorDenied)
    {
//        self.EmptyLbl.text = @"請開啓GPS權限";
    }
    else
    {
//        self.EmptyLbl.text = @"GPS接收訊號失敗";
    }
    NSLog(@"GPS Error Code %ld",(long)[error code]);
    NSLog(@"%@",[error localizedDescription]);
}

#pragma mark - tableview Delegate&DataSource

//-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//    return 44.0;
//}
//-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 44.0;
//}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return arrayData.count;
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString * stringStopName = [[arrayData objectAtIndex:section]objectForKey:@"StopName"];
//    NSString * stringDistance = [[arrayData objectAtIndex:section]objectForKey:@"distance"];
    
    NSString * stringTitle = [NSString stringWithFormat:NSLocalizedStringFromTable(@"車站 - %@",appDelegate.LocalizedTable,nil),stringStopName];
//    NSString * stringTitle = [NSString stringWithFormat:@"%@ - 距離%.1f公尺",stringStopName,stringDistance.doubleValue];
    return stringTitle;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[arrayData objectAtIndex:section]objectForKey:@"routesData"] count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    stopNearLineCell * cell = (stopNearLineCell*)[tableView dequeueReusableCellWithIdentifier:@"stopNearLineCell"];
    
    //若無可回收Cell則由Bundle取得
    if (cell == nil)
    {
        NSArray *nib=[[NSBundle mainBundle]loadNibNamed:@"stopNearLineCell" owner:self options:nil];
        for (id object in nib)
        {
            if ([object isKindOfClass:[stopNearLineCell class]])
            {
                cell = (stopNearLineCell*)object;
                break;
            }
        }
    }
    
    NSDictionary * dictionaryRoute //= [arrayTableviewRoutes objectAtIndex:indexPath.row];
    /*id dictionaryRoute*/ = (NSDictionary*)[[[arrayData objectAtIndex:indexPath.section]objectForKey:@"routesData"]objectAtIndex:indexPath.row];
    RouteDataType routeType = [[dictionaryRoute objectForKey:@"Type"]isEqualToString:@"0"]?RouteDataTypeCityRoutes:RouteDataTypeHighwayRoutes;
    
    NSString * stringKey = [dictionaryRoute objectForKey:@"RouteID"];
    
    NSDictionary *dictionaryPath = [[DataManager selectRouteDataKeyWord:stringKey byColumnTitle:RouteDataColumnTypeRouteID fromTableType:routeType]objectAtIndex:0];
//    if (dictionaryPath)
    {
        NSString * stringDeparture = [dictionaryPath objectForKey:@"departureZh"];
        NSString * stringDestination = [dictionaryPath objectForKey:@"destinationZh"];
        NSString * stringPath;
        NSString * stringDirectionSymbol = @" -> ";
        if (!stringDeparture||!stringDestination)
        {
            stringDeparture = @"";
            stringDestination = @"";
            stringDirectionSymbol = @"";
        }
        if ([[dictionaryRoute objectForKey:@"GoBack"]isEqualToString:@"1"])
        {
            stringPath = [NSString stringWithFormat:NSLocalizedStringFromTable(@"去程: %@%@%@",appDelegate.LocalizedTable,nil),stringDeparture,stringDirectionSymbol,stringDestination];
        }
        else
        {
            stringPath = [NSString stringWithFormat:NSLocalizedStringFromTable(@"返程: %@%@%@",appDelegate.LocalizedTable,nil),stringDestination,stringDirectionSymbol,stringDeparture];
        }
        [cell.labelRouteToward setText:stringPath];
//        [cell.labelRouteToward setHidden:NO];
    }
//    else
//    {
//        [cell.labelRouteToward setHidden:YES];
//    }

    [cell.labelRouteName setText:[dictionaryRoute objectForKey:@"RouteName"]];
    [cell.labelSerialNumber setText:[NSString stringWithFormat:@"%d",indexPath.row]];
    
    //到站時間判斷
    NSString * stringTime1 = [dictionaryRoute objectForKey:@"ComeTime0"];
    NSString * stringTime2 = [dictionaryRoute objectForKey:@"ComeTime1"];
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
    
//    UITableViewCell * cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
//    id dictionaryRoute = [[[arrayData objectAtIndex:indexPath.section]objectForKey:@"routesData"]objectAtIndex:indexPath.row];
//    NSString *stringComeTime0 =[dictionaryRoute objectForKey:@"ComeTime0"];
//    NSString *stringComeTime1 =[dictionaryRoute objectForKey:@"ComeTime1"];
//
//    NSString * stringToward = [[dictionaryRoute objectForKey:@"GoBack"] intValue] == 1?@"去程":@"返程";
//    NSString * stringTime = (!stringComeTime0||![stringComeTime0 isEqualToString:@"null" ])? [NSString stringWithFormat:@"%@分鐘後到站", stringComeTime0]:[NSString stringWithFormat:@"%@到站", stringComeTime1];
//    
//    [cell.textLabel setText:[NSString stringWithFormat:@"%@ %@ %@",[dictionaryRoute objectForKey:@"RouteName"],stringToward,stringTime]];
    
//    [cell.detailTextLabel setText:[NSString stringWithFormat:@"%@ %@",[dictionaryRoute objectForKey:@"RouteName"],stringToward]];
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self actShowMapAtStop:[[[arrayData objectAtIndex:indexPath.section]objectForKey:@"routesData"]objectAtIndex:indexPath.row]];
    

    
}
@end
