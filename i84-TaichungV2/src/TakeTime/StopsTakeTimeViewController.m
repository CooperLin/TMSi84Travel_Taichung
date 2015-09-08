//
//  StopsTakeTimeViewController.m
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/4/29.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "StopsTakeTimeViewController.h"
#import "ShareTools.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "AppDelegate.h"
#import "JSONKit.h"
#import "TakeTimeTableViewCell.h"

#define APISearchStops @"/iTravel/iTravelAPI/ExpoAPI/LocationInfo.ashx?Type=5&keyword=%@"
//#define APIGetPathTime @"/itravel/itravelAPI/ExpoAPI/TravelTime.aspx?Departure=%@&Destination=%@&Time=%@"
#define APIGetPathTime NSLocalizedStringFromTable(@"GetPathTime",appDelegate.LocalizedTable,nil)

@interface StopsTakeTimeViewController ()
{
    ASINetworkQueue * queueASIRequests;
    NSInteger intQueryFail;
    
    NSMutableDictionary * dictionaryAPI;
    UITextField * textFieldSelected;
    
    NSMutableArray * arraySearchStops;
    NSMutableArray * arrayPathTime;
    
//    NSMutableDictionary * dictionaryDeparture;
//    NSMutableDictionary * dictionaryDestination;
}

@end

@implementation StopsTakeTimeViewController

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
    [self actSetASIEnvironment];
}
-(void)actSetASIEnvironment
{
    //ASIQueue設定
    {
        queueASIRequests = [[ASINetworkQueue alloc] init];
        queueASIRequests.maxConcurrentOperationCount = 2;
        
        // ASIHTTPRequest 默認的情況下，queue 中只要有一個 request fail 了，整個 queue 裡的所有 requests 也都會被 cancel 掉
        [queueASIRequests setShouldCancelAllRequestsOnFailure:NO];
        
        // go 只需要執行一次
        //    [queueASIRequests go];
    }
    dictionaryAPI = [NSMutableDictionary dictionaryWithDictionary:
                     @{
                       @"server":APIServer
                       }];
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.startPoint.text = NSLocalizedStringFromTable(@"起點", appDelegate.LocalizedTable, nil);
    self.endPoint.text = NSLocalizedStringFromTable(@"訖點", appDelegate.LocalizedTable, nil);
    self.textFieldSearch.placeholder = NSLocalizedStringFromTable(@"請鍵入關鍵字", appDelegate.LocalizedTable, nil);
    [self.searchRouteTime setTitle:NSLocalizedStringFromTable(@"查詢路線時間", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    [self.searchRouteTime.titleLabel setAdjustsFontSizeToFitWidth:YES];
}
-(void)actSetAPIbyType:(StopsTakeTimeDataType)requestType
{
    NSString * stringAPI;
    switch (requestType)
    {
        case StopsTakeTimeDataTypeGetPathTime:
        {
            NSString * stringDeparture = self.textFieldDeparture.text;
            NSString * stringDestination = self.textFieldDestination.text;
            NSString * stringEncodedDeparture = [ShareTools GetUTF8Encode:stringDeparture];
            NSString * stringEncodedDestination = [ShareTools GetUTF8Encode:stringDestination];

//            stringEncodedDeparture = @"228,184,173,232,136,136,229,160,130,";
//            stringEncodedDestination = @"229,140,151,229,177,175,229,156,139,229,176,143,40,229,140,151,229,177,175,232,183,175,41,";
            NSDateFormatter * dateFormatter = [NSDateFormatter new];
            [dateFormatter setDateFormat:@"HH:mm:ss"];
            NSString * stringDateNow = [dateFormatter stringFromDate:[NSDate date]];
            stringAPI = [NSString stringWithFormat:APIGetPathTime,stringEncodedDeparture,stringEncodedDestination,stringDateNow];
            
            //for test
//            stringAPI = @"/itravel/itravelAPI/ExpoAPI/TravelTime.aspx?Departure=228,184,173,232,136,136,229,160,130,&Destination=229,140,151,229,177,175,229,156,139,229,176,143,40,229,140,151,229,177,175,232,183,175,41,&Time=19:57:00";
        }
            break;
            
        case StopsTakeTimeDataTypeSearchStops:
        {
            NSString * stringStopsSearchKeyWords = self.textFieldSearch.text;
            stringAPI = [NSString stringWithFormat:APISearchStops,stringStopsSearchKeyWords];
        }
            break;
            
        default:
            break;
    }

    if (dictionaryAPI)
    {
        [dictionaryAPI setObject:stringAPI forKey:@(requestType)];
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - UITableView Delegate & Datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableViewList)
    {
        return arrayPathTime.count;
    }
    else
        if (tableView == self.tableViewSearchStops)
        {
        return arraySearchStops.count;
    }
    return 0;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableViewList)
    {
        //尋找tableview可回收Cell(需注意cell.xib要設定identifier,回收機制才有用)
        TakeTimeTableViewCell * cell = (TakeTimeTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"takeTimeCell"];
        
        //若無可回收Cell則由Bundle取得
        if (cell == nil)
        {
            NSArray *nib=[[NSBundle mainBundle]loadNibNamed:@"TakeTimeTableViewCell" owner:self options:nil];
            for (id object in nib)
            {
                if ([object isKindOfClass:[TakeTimeTableViewCell class]])
                {
                    cell = (TakeTimeTableViewCell*)object;
                    break;
                }
            }
        }
        NSDictionary * dictionaryOne = [arrayPathTime objectAtIndex:indexPath.row];
        NSString * stringRouteName = [dictionaryOne objectForKey:@"RouteName"];
        NSString * stringStopsCount = [dictionaryOne objectForKey:@"StopCount"];
        
        //計算"HH:mm:ss"
        NSString * stringTakeSeconds = [dictionaryOne objectForKey:@"TravelTime"];
        NSInteger integerTakeSeconds = [stringTakeSeconds integerValue];
        NSInteger integerTmp = integerTakeSeconds;
        NSInteger integerSecond = integerTmp%60;
        
//        integerTmp = integerTmp/60;
         NSInteger integerMinute = integerTmp/60;
//        NSInteger integerMinute = integerTmp%60;
        
//        integerTmp = integerTmp/60;
//        NSInteger integerHour = integerTmp;
        
//        NSString * stringHour = integerHour?[NSString stringWithFormat:@"%d時",integerHour]:@"";
//        NSString * stringHour = integerHour?[NSString stringWithFormat:@"%d分",integerHour]:@"";
//        NSString * stringSecond = integerSecond?[NSString stringWithFormat:@"%d秒",integerSecond]:@"";

        [cell.labelName setText:stringRouteName];
        [cell.labelStopsCount setText:stringStopsCount];
        [cell.labelTime setText:(integerMinute||integerSecond)?[NSString stringWithFormat:NSLocalizedStringFromTable(@"%d分%d秒", appDelegate.LocalizedTable, nil),integerMinute,integerSecond]:NSLocalizedStringFromTable(@"無系統時間", appDelegate.LocalizedTable, nil)];
        [cell.stopLabel setText:NSLocalizedStringFromTable(@"站", appDelegate.LocalizedTable, nil)];
//        [cell.textLabel setText:[NSString stringWithFormat:@"%@ %@ %dH%dM%dS",stringRouteName,stringStopsCount,integerHour,integerMinute,integerSecond]];
        return cell;
    }
    else
        if (tableView == self.tableViewSearchStops)
    {
        UITableViewCell * cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"listCell"];
        if (cell==nil)
        {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"listCell"];
        }
        NSDictionary * dictionaryOne = [arraySearchStops objectAtIndex:indexPath.row];
        NSString * stringStopName = [dictionaryOne objectForKey:@"Name"];

        [cell.textLabel setText:[NSString stringWithFormat:@"%@",stringStopName]];
        return cell;

    }
    
        return nil;
    
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableViewList)
    {
        
    }
    else
        if (tableView == self.tableViewSearchStops)
        {
            NSMutableDictionary * dictionaryOne = [NSMutableDictionary dictionaryWithDictionary:[arraySearchStops objectAtIndex:indexPath.row]];
//            if (textFieldSelected == self.textFieldDeparture)
//            {
//                dictionaryDeparture = dictionaryOne;
//            }
//            else
//            {
//                dictionaryDestination = dictionaryOne;
//            }
            [textFieldSelected setText:[dictionaryOne objectForKey:@"Name"]];
            [self actRemoveSearchView];
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
            [NSThread detachNewThreadSelector:@selector(actStopActivityIndicator) toTarget:self withObject:nil];
            
        }
        switch (request.tag)
        {
            case 10:
                
                break;
                
            default:
                break;
        }
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:NSLocalizedStringFromTable(@"無法連接伺服器", appDelegate.LocalizedTable, nil) message:nil delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", appDelegate.LocalizedTable, nil) otherButtonTitles:nil];
        [alert show];
    }
}

- (void) SendQueryRequest:(StopsTakeTimeDataType)requestType
{
    if ( ![ShareTools connectedToNetwork] )
    {
		return;
	}
    //queue裡面確認取消前面未完成的request,避免重複送request
    if (queueASIRequests.operationCount)
    {
        for (ASIHTTPRequest *requestTmp in queueASIRequests.operations)
        {
            if (requestTmp.tag == requestType)
            {
                [requestTmp cancel];
            }
        }
    }
    else if([queueASIRequests isSuspended])
    {
        [queueASIRequests go];
    }
    [self actSetAPIbyType:requestType];
    [NSThread detachNewThreadSelector:@selector(actStartActivityIndicator) toTarget:self withObject:nil];
    
    NSString *UrlStr = [NSString stringWithFormat:@"%@%@",[dictionaryAPI objectForKey:@"server"],[dictionaryAPI objectForKey:[NSNumber numberWithInteger:requestType]]];
    
	NSURL *url = [NSURL URLWithString:[UrlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
	ASIHTTPRequest * QueryRequest = [ASIHTTPRequest requestWithURL:url];
    [QueryRequest setDelegate:self];
    [QueryRequest setDidFinishSelector:@selector(QueryJSONRequestFinish:)];
    [QueryRequest setDidFailSelector:@selector(QueryRequestFail:)];
    [QueryRequest setTimeOutSeconds:30.0];
    //queue裡面確認,避免重複送request
    QueryRequest.tag = requestType;
    
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
            NSString * stringMessage ;//= [NSString stringWithFormat:@"查無%@資料",nil];//[dictionarySelectedRoute objectForKey:@"RouteName"]];
            UIAlertView * alert = [[UIAlertView alloc]initWithTitle:NSLocalizedStringFromTable(@"查無資料", appDelegate.LocalizedTable, nil) message:stringMessage delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確認", appDelegate.LocalizedTable, nil) otherButtonTitles:nil];
                [alert show];
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
        
//        JSONDecoder * Parser = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
//        NSArray * arrayFromJSON = [Parser objectWithData:[request responseData]];
        
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
            [self actSetRequestData:arrayFromJSON byType:request.tag];
        }
    }
    
    if (queueASIRequests.operationCount==0)
    {
        [queueASIRequests setSuspended:YES];
        [NSThread detachNewThreadSelector:@selector(actStopActivityIndicator) toTarget:self withObject:nil];
    }
}
-(void)actSetRequestData:(NSArray*)arrayFromRequest byType:(StopsTakeTimeDataType)dataType
{
    NSMutableArray * arrayData = [NSMutableArray arrayWithArray:arrayFromRequest];
    switch (dataType)
    {
        case StopsTakeTimeDataTypeSearchStops:
            arraySearchStops = arrayData;
            [self.tableViewSearchStops reloadData];
            
            break;
        case StopsTakeTimeDataTypeGetPathTime:
            arrayPathTime = arrayData;
            [self.tableViewList reloadData];
            break;
            
        default:
            break;
    }
}
#pragma mark - UITextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.textFieldSearch)
    {
        [self SendQueryRequest:StopsTakeTimeDataTypeSearchStops];
    }
    [textField resignFirstResponder];
    return YES;
}
- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    if(textField == self.textFieldDeparture || textField == self.textFieldDestination)
    {
        textFieldSelected = textField;
        [textFieldSelected resignFirstResponder];
        [textFieldSelected setBackgroundColor:[UIColor lightGrayColor]];
        if(textField == self.textFieldDeparture)
        {
            [self.textFieldDestination setBackgroundColor:[UIColor clearColor]];
        }
        else
        {
            [self.textFieldDeparture setBackgroundColor:[UIColor clearColor]];
        }
        [self actShowSearchView];
    }
}
-(void)actShowSearchView
{
    [self.view addSubview:self.viewSearch];
//    CGRect frame = self.view.bounds;
//    frame.origin.y = self.view.bounds.origin.y;
//    [self.viewSearch setFrame:frame];
//    [UIView beginAnimations:@"SearchViewShow" context:nil];
////    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
//    [UIView setAnimationDelay:1];
//    [UIView setAnimationDelegate:self];
    [self.viewSearch setFrame:self.view.bounds];
//    [UIView commitAnimations];
    if (self.delegate)
    {
        [self.delegate addHeaderBackButton];
    }
}

-(void)actRemoveSearchView
{
    [self.viewSearch removeFromSuperview];

    if (self.delegate)
    {
        [self.delegate removeHeaderBackButton];
    }
}

#pragma mark - IBAction
- (IBAction)actBtnCheckTimeTouchUpInside:(id)sender
{
    NSString * stringMessage = nil;
    if (!self.textFieldDeparture.text||[self.textFieldDeparture.text isEqualToString:@""])
    {
        stringMessage = NSLocalizedStringFromTable(@"請輸入起點", appDelegate.LocalizedTable, nil);
    }
    else
        if (!self.textFieldDestination.text||[self.textFieldDestination.text isEqualToString:@""])
        {
            stringMessage = NSLocalizedStringFromTable(@"請輸入訖點", appDelegate.LocalizedTable, nil);
        }
        else
        {
            [self SendQueryRequest:StopsTakeTimeDataTypeGetPathTime];
        }
    if (stringMessage)
    {
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:NSLocalizedStringFromTable(@"資料有誤", appDelegate.LocalizedTable, nil) message:stringMessage delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"OK", appDelegate.LocalizedTable, nil) otherButtonTitles:nil];
        [alert show];
    }
}
-(void)actStartActivityIndicator
{
    if (self.delegate)
    {
        [self.delegate startActivityIndicator];
    }
}
-(void)actStopActivityIndicator
{
    if (self.delegate)
    {
        [self.delegate stopActivityIndicator];
    }
}
- (IBAction)actBtnCancelSearchTouchUpInside:(id)sender
{
    [self actRemoveSearchView];
}

- (IBAction)actBtnSwapTouchUpInside:(id)sender
{
    NSString * stringTmp = self.textFieldDeparture.text;
//    NSMutableDictionary * dictionaryTmp = dictionaryDeparture;
    [self.textFieldDeparture setText:self.textFieldDestination.text];
//    dictionaryDeparture = dictionaryDestination;
    [self.textFieldDestination setText:stringTmp];
//    dictionaryDestination = dictionaryTmp;
}
@end
