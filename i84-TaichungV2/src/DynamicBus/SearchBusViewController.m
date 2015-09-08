//
//  SearchBusViewController.m
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/3/3.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "SearchBusViewController.h"
#import "GDataXMLNode.h"
#import "ShareTools.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "AppDelegate.h"
#import "DataManager+Route.h"

////市區客運
//#define APICityRoutesPath @"/xmlbus3/StaticData/GetRoute.xml"
//#define APICityProvidersPath @"/xmlbus3/StaticData/GetProvider.xml"
//
////國道客運
//#define APIHighwayRoutesPath @"/xmlbusgz/StaticData/GetRoute.xml"
//#define APIHighwayProvidersPath @"/xmlbusgz/StaticData/GetProvider.xml"

//
#define KeyDataBaseRoutes @"Routes"
#define KeyHighwayRoutes @"HighwayRoutes"
#define KeyHighwayProviders @"HighwayProviders"
#define KeyCityRoutes @"CityRoutes"
#define KeyCityProviders @"CityProviders"

@interface SearchBusViewController ()
{
    ASINetworkQueue * queueASIRequests;
    NSMutableArray * arrayProvidersCity;
    NSMutableArray * arrayRoutesCity;
    NSMutableArray * arrayRoutesAll;
    NSMutableArray * arrayRoutesFiltered;
    NSMutableArray * arrayRoutesCityFiltered;
    NSMutableArray * arrayRoutesHighwayFiltered;
    NSMutableArray * arrayProvidersHighway;
    NSMutableArray * arrayRoutesHighway;
    NSMutableArray * arrayTableviewRoutes;
    NSMutableArray * arrayPickerviewProviders;
    NSMutableArray * arrayProvidersAll;
    NSMutableDictionary * dictionaryPickerProviders;
//    NSDictionary * dictionaryAPI;
    NSInteger intSelectedProvider;
    NSString * stringProviderID;
    NSInteger intQueryFailCount;
    SilderMenuView * SilderMenu;
}
@property (nonatomic, strong) UIView *viewCover;
@end

@implementation SearchBusViewController

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

    [self actsetEnvironment];
    [self actSetASIEnvironment];

    
    [self actQueryData];
}
-(void)actsetEnvironment
{
//    arrayRoutesCity = [NSMutableArray new];
//    arrayRoutesHighway = [NSMutableArray new];
//    arrayProvidersCity  = [NSMutableArray new];
//    arrayProvidersHighway = [NSMutableArray new];
    dictionaryPickerProviders = [NSMutableDictionary new];

}
-(void)actSetSliderMenu
{
    CGRect ContentFrame = self.ContentV.bounds;
    SilderMenu = [[SilderMenuView alloc] initWithFrame:CGRectMake(0, 0, 135, self.view.frame.size.height)];
    [self.ContentV addSubview:SilderMenu];
    [SilderMenu setSilderDelegate:self];
    [SilderMenu setItemsByPlistName:@"LeftMenu"];
}
-(void)viewWillAppear:(BOOL)animated
{
    if (SilderMenu.frame.size.height != self.ContentV.bounds.size.height)
    {
        CGRect frameNew = SilderMenu.frame;
        frameNew.size.height = self.ContentV.bounds.size.height;
        SilderMenu.frame = frameNew;
    }
    [self.clearBtn setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"routesearch_clean.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    self.labelTitle.text = NSLocalizedStringFromTable(@"公車動態", appDelegate.LocalizedTable, nil);
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)actQueryData
{
//    dictionaryAPI = @{
//                      @(RouteDataTypeCityRoutes): APICityRoutesPath,
//                      @(RouteDataTypeHighwayRoutes): APIHighwayRoutesPath,
//                      @(RouteDataTypeCityProviders): APICityProvidersPath,
//                      @(RouteDataTypeHighwayProviders): APIHighwayProvidersPath,
//                      @"server": APIServer
//                      };
    
//    NSDateFormatter * dateFormatter = [NSDateFormatter new];
//    [dateFormatter setDateFormat:@"YYYYMMdd"];
//    NSString * stringDate = [dateFormatter stringFromDate:[NSDate date]];
    
//    BOOL boolRequest = NO;
    

    arrayRoutesCity = [DataManager getDataByType:RouteDataTypeCityRoutes];
//    if (!arrayRoutesCity)
//    {
//        arrayRoutesCity = [NSMutableArray new];
//        [self SendQueryRequest:RouteDataTypeCityRoutes];
//        boolRequest = YES;
//    }
    

    arrayRoutesHighway = [DataManager getDataByType:RouteDataTypeHighwayRoutes];
//    if (!arrayRoutesHighway)
//    {
//        arrayRoutesHighway = [NSMutableArray new];
//        [self SendQueryRequest:RouteDataTypeHighwayRoutes];
//        boolRequest = YES;
//    }
    
    arrayProvidersCity = [DataManager getDataByType:RouteDataTypeCityProviders];
//    if (!arrayProvidersCity)
//    {
//        arrayProvidersCity = [NSMutableArray new];
//        [self SendQueryRequest:RouteDataTypeCityProviders];
//        boolRequest = YES;
//    }
    

    
    arrayProvidersHighway = [DataManager getDataByType:RouteDataTypeHighwayProviders];
//    if (!arrayProvidersHighway)
//    {
//        arrayProvidersHighway = [NSMutableArray new];
//        [self SendQueryRequest:RouteDataTypeHighwayProviders];
//        boolRequest = YES;
//    }

    //request全完成就建立list
//    if (!boolRequest)
//    {
        [self actBuildList];
//    }
}
#pragma mark - setting

-(void)actSetASIEnvironment
{
    queueASIRequests = [[ASINetworkQueue alloc] init];
    queueASIRequests.maxConcurrentOperationCount = 5;
    
    // ASIHTTPRequest 默認的情況下，queue 中只要有一個 request fail 了，整個 queue 裡的所有 requests 也都會被 cancel 掉
    [queueASIRequests setShouldCancelAllRequestsOnFailure:NO];
    
    // go 只需要執行一次
//    [queueASIRequests go];
}

-(void)actGetRoutes
{
    [NSThread detachNewThreadSelector:@selector(startActivityIndicator) toTarget:self withObject:nil];

    NSString * stringTargetRouteName = self.labelInput.text;
//    NSString * stringProviderTmp = self.labelProvider.text;
    
    if (!arrayTableviewRoutes)
    {
        arrayTableviewRoutes = [NSMutableArray new];
    }
    else
    {
        [arrayTableviewRoutes removeAllObjects];
    }
    
    //確認 picker選擇 業者
    NSString * stringProviderName;
    if (intSelectedProvider>0)
    {
        stringProviderName = self.labelProvider.text;
    }
    NSMutableArray * arrayRoutesBase;
    NSMutableArray * arrayRoutesBaseAll;
    NSMutableArray * arrayRoutesBaseFiltered;

    //判斷 picker選擇 市區或是國道
    if (arrayPickerviewProviders == arrayProvidersCity)
    {
        if ((!arrayRoutesCityFiltered||arrayRoutesCityFiltered.count<=0)&&arrayRoutesCity.count>0)
        {
            arrayRoutesBaseFiltered = [self actFilterRoutes:arrayRoutesCity];
        }
        arrayRoutesBaseAll = arrayRoutesCity;
    }
    else
        if (arrayPickerviewProviders == arrayProvidersHighway)
        {
            if ((!arrayRoutesHighwayFiltered||arrayRoutesHighwayFiltered.count<=0)&&arrayRoutesHighway.count>0)
            {
                arrayRoutesBaseFiltered = [self actFilterRoutes:arrayRoutesHighway];
            }
            arrayRoutesBaseAll = arrayRoutesHighway;
        }
        else
            {
                if ((!arrayRoutesFiltered||arrayRoutesFiltered.count<=0)&&arrayRoutesAll.count>0)
                {
                    arrayRoutesBaseFiltered = [self actFilterRoutes:arrayRoutesAll];
                }
                arrayRoutesBaseAll = arrayRoutesAll;
            }
    //判斷 路線 及 客運公司
    if (arrayRoutesBaseAll.count && arrayRoutesBaseFiltered.count)
    {
        if (!(stringProviderName.length > 0))
        {
            arrayRoutesBase = [NSMutableArray arrayWithArray:arrayRoutesBaseFiltered];
        }
        else
        {
            arrayRoutesBase = [NSMutableArray arrayWithArray:arrayRoutesBaseAll];
        }
        
        if (!(stringTargetRouteName>0))
        {
            arrayTableviewRoutes = arrayRoutesBaseFiltered;
        }
        else
        {
            for (NSDictionary * dictionaryBase in arrayRoutesBase)
            {
                NSString * stringNameBase = [dictionaryBase objectForKey:@"nameZh"];
                
                if (!stringProviderName||[stringProviderName isEqualToString:[dictionaryPickerProviders objectForKey:[NSString stringWithFormat:@"%@%@",[dictionaryBase objectForKey:@"type"],[dictionaryBase objectForKey:@"ProviderId"]]]])
                {
                    if (stringTargetRouteName.length > 0)
                    {
                        NSRange range = [stringNameBase rangeOfString:stringTargetRouteName];
                        
                        if (range.length>0 && (range.location==0 || [stringTargetRouteName isEqualToString:@"藍"]))
                        {
                            [arrayTableviewRoutes addObject:dictionaryBase];
                        }
                    }
                    else
                    {
                        [arrayTableviewRoutes addObject:dictionaryBase];
                    }
                }
            }
        }

        [self.tableViewSearch reloadData];
    }
    
    [NSThread detachNewThreadSelector:@selector(stopActivityIndicator) toTarget:self withObject:nil];
}

-(NSMutableArray*)actFilterRoutes:(NSMutableArray*)arrayOriginal
{
    NSMutableArray * arrayFiltered = [NSMutableArray new];
//    if (arrayRoutesCity.count > 0 && arrayRoutesHighway.count > 0)
//    {
    [arrayFiltered addObject:[arrayOriginal objectAtIndex:0]];
        for (int i = 0;i < arrayOriginal.count;i++)
        {
            NSMutableDictionary * dictionaryRouteOne = [arrayOriginal objectAtIndex:i];
            NSString * stringCheck1 = [dictionaryRouteOne objectForKey:@"ID"];
            
            BOOL boolExist = NO;
            int j=0;
            while (j<arrayFiltered.count)
            {
                if( [stringCheck1 isEqualToString:[[arrayFiltered objectAtIndex:j]objectForKey:@"ID"]])
                {
                    boolExist = YES;
                }
                    j++;
            }
            if (!boolExist)
            {
                [arrayFiltered addObject:dictionaryRouteOne];
            }
            
//            for (int j = 0 ;j<arrayFiltered.count;j++)
//            {
//                NSMutableDictionary * dictionaryCheck2 = [arrayFiltered objectAtIndex:j];
//                if ([[dictionaryCheck1 objectForKey:@"nameZh"]isEqualToString:[dictionaryCheck2 objectForKey:@"nameZh"]])
//                {
//                    [arrayFiltered removeObject:dictionaryCheck2];
//                    j--;
//                }
//            }
        }
//    }
    return arrayFiltered;
}
#pragma mark - IBAction
- (IBAction)actBtnNumbersTouchUpInside:(id)sender
{
    //tag 10:數字0 11:客運業者 12:清除
    NSInteger intTag = ((UIButton*)sender).tag;

    if (intTag <=10 && intTag>0)
    {
        if (intTag == 10)
        {
            intTag = 0;
        }
        NSString * stringTmp = [NSString stringWithFormat:@"%@%ld",self.labelInput.text,(long)intTag];
        [self.labelInput setText:stringTmp];
    }
    else
    {
        if (intTag==11)
        {
            [self showPicker];
            return;
        }
        else
        {
            [self.labelInput setText:@""];
        }
    }
    [self actGetRoutes];
}
//picker內Ok按鈕
- (IBAction)actBtnPickerTouchUpInside:(id)sender
{
    [self.viewPicker removeFromSuperview];
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
#pragma mark - UI control
-(void)showPicker
{
    if (!arrayPickerviewProviders)
    {
        arrayPickerviewProviders = arrayProvidersAll;
    }
    
    [self.view insertSubview:self.viewPicker belowSubview:SilderMenu];
    CGRect frame = self.viewPicker.frame;
    frame.origin.y = self.view.frame.size.height-self.viewPicker.bounds.size.height;
    self.viewPicker.frame = frame;
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
#pragma mark - Query API
//-(void)QueryRequestFail:(ASIHTTPRequest *)request
//{
//    if (intQueryFailCount<5)
//    {
//        intQueryFailCount++;
//        [self SendQueryRequest:request.tag];
//        return;
//    }
//    else
//    {
//#ifdef LogOut
//        NSLog(@"Query fail %ld",(long)request.tag);
//#endif
//        intQueryFailCount = 0;
//        if (queueASIRequests.operationCount==0)
//        {
//            [queueASIRequests setSuspended:YES];
//            [NSThread detachNewThreadSelector:@selector(stopActivityIndicator) toTarget:self withObject:nil];
//
//        }
//        switch (request.tag)
//        {
//            case 10:
//                
//                break;
//                
//            default:
//                break;
//        }
//        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"無法連接伺服器" message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//        [alert show];
//    }
//    
//    
//}
/*
 tag 用來分辨request是取得什麼資料
 1:route 1,
 2:route 2,
 3:provider 1,
 4:provider 2
 */
//- (void) SendQueryRequest:(RouteDataType)requestType
//{
//    if ( ![ShareTools connectedToNetwork] )
//    {
//		return;
//	}
//    //queue裡面確認,避免重複送request
//    if (queueASIRequests.operationCount)
//    {
//        for (ASIHTTPRequest *requestTmp in queueASIRequests.operations)
//        {
//            if (requestTmp.tag == requestType)
//            {
//                return;
//            }
//        }
//    }
//    else if([queueASIRequests isSuspended])
//    {
//        [queueASIRequests go];
//    }
//    
//    [NSThread detachNewThreadSelector:@selector(startActivityIndicator) toTarget:self withObject:nil];
//
//    NSString *UrlStr = [NSString stringWithFormat:@"%@%@",[dictionaryAPI objectForKey:@"server"],[dictionaryAPI objectForKey:[NSNumber numberWithInteger:requestType]]];
//	NSURL *url = [NSURL URLWithString:UrlStr];
//
//	ASIHTTPRequest * QueryRequest = [ASIHTTPRequest requestWithURL:url];
//    [QueryRequest setDelegate:self];
//    [QueryRequest setDidFinishSelector:@selector(QueryXMLRequestFinish:)];
//    [QueryRequest setDidFailSelector:@selector(QueryRequestFail:)];
//    [QueryRequest setTimeOutSeconds:30.0];
//    //queue裡面確認,避免重複送request
//    QueryRequest.tag = requestType;
//
//    [queueASIRequests addOperation:QueryRequest];
//#ifdef LogOut
//    NSLog(@"RequestStr:%@",UrlStr);
//#endif
//}

//-(void) QueryXMLRequestFinish :(ASIHTTPRequest *)request
//{
//    NSString * ResponseTxt = [request responseString];
//    
//    if([ResponseTxt hasPrefix:@"<?xml"])
//    {
//        GDataXMLDocument * XmlDoc = [[GDataXMLDocument alloc] initWithData:request.responseData options:0 error:nil];
//        if(XmlDoc == nil)
//        {
//            [self QueryRequestFail:request];
//            return;
//        }
//        else
//        {
//            [self actParseXmlDoc:XmlDoc byType:request.tag];
//        }
//    }
//    else
//    {
//        [self QueryRequestFail:request];
//    }
//    
//    if (queueASIRequests.operationCount==0)
//    {
//        [queueASIRequests setSuspended:YES];
//        [NSThread detachNewThreadSelector:@selector(stopActivityIndicator) toTarget:self withObject:nil];
//    }
//}
-(void)actAddToProvidersDictionary:(id)dictionaryOne byProviderType:(RouteDataType)providerType
{
    switch(providerType)
    {
        case RouteDataTypeHighwayProviders:
            [dictionaryPickerProviders setObject:[dictionaryOne objectForKey:@"nameZh"] forKey:[NSString stringWithFormat:@"highway%@",[dictionaryOne objectForKey:@"ID"]]];
            break;
        case RouteDataTypeCityProviders:
            
            [dictionaryPickerProviders setObject:[dictionaryOne objectForKey:@"nameZh"] forKey:[NSString stringWithFormat:@"city%@",[dictionaryOne objectForKey:@"ID"]]];
            break;
        default:
            break;
    }
}
-(void)actBuildProvidersAllList
{
    if (!arrayProvidersAll)
    {
        arrayProvidersAll = [NSMutableArray new];
    }
    else
    {
        [arrayProvidersAll removeAllObjects];
    }

    if (!dictionaryPickerProviders)
    {
        dictionaryPickerProviders = [NSMutableDictionary new];
    }
    
    //    [arrayPickerviewProviders addObject:@"請選擇客運業者"];

    [arrayProvidersAll addObjectsFromArray:arrayProvidersCity];
    for (id dictionaryProvider in arrayProvidersCity)
    {
        [self actAddToProvidersDictionary:dictionaryProvider byProviderType:RouteDataTypeCityProviders];
    }
    
    for (id dictionaryProvider in arrayProvidersHighway)
    {
        [self actAddToProvidersDictionary:dictionaryProvider byProviderType:RouteDataTypeHighwayProviders];
        
        NSString * stringProviderHighway = [dictionaryProvider objectForKey:@"nameZh"];
        NSArray * arrayTmp = [NSArray arrayWithArray:arrayProvidersAll];
        for (NSDictionary * dictionaryTmp in arrayTmp)
        {
            NSString * stringName = [dictionaryTmp objectForKey:@"nameZh"];
            
            if ([stringProviderHighway compare:stringName] == 0)
            {
                [arrayProvidersAll removeObject:dictionaryTmp];
            }
        }
        [arrayProvidersAll addObject:dictionaryProvider];
        
    }
    [self actGetRoutes];
}

-(void)actParseXmlDoc:(GDataXMLDocument*)XmlDoc byType:(RouteDataType)requestType
{

    NSMutableArray *arrayDataCollected;
    NSString * stringNodeName;
    NSString * stringKey = nil;
    
    switch (requestType)
    {
        case RouteDataTypeCityRoutes:
        {
            arrayDataCollected = arrayRoutesCity;
            stringNodeName = @"Route";
            stringKey = KeyCityRoutes;
        }
            break;
        case RouteDataTypeHighwayRoutes:
        {
            arrayDataCollected = arrayRoutesHighway;
            stringNodeName = @"Route";
            stringKey = KeyHighwayRoutes;
        }
            break;
        case RouteDataTypeCityProviders:
        {
            arrayDataCollected = arrayProvidersCity;
            stringNodeName = @"Provider";
            stringKey = KeyCityProviders;
        }
            break;
        case RouteDataTypeHighwayProviders:
        {
            arrayDataCollected = arrayProvidersHighway;
            stringNodeName = @"Provider";
            stringKey = KeyHighwayProviders;
        }
            break;
        default:
            break;
    }
    
            if (!arrayDataCollected.count)
            {
                [arrayDataCollected removeAllObjects];
            }
    
        NSArray * arrayElementTmp = [XmlDoc.rootElement elementsForName:@"BusInfo"];

        NSArray * arrayElementOnes = [[arrayElementTmp objectAtIndex:0] elementsForName:stringNodeName];
        for(GDataXMLElement * elementOne in arrayElementOnes)
        {
            NSArray * arrayElementAttributes = [elementOne attributes];
            NSMutableDictionary * dictionaryDataCache = [NSMutableDictionary new];
            for (GDataXMLNode * node in arrayElementAttributes)
            {
                [dictionaryDataCache setObject:[[elementOne attributeForName:[node name]]stringValue] forKey:[node name]];
            }
            switch (requestType)
            {
                case RouteDataTypeHighwayProviders:
                {

                    [dictionaryDataCache setObject:[[[dictionaryDataCache objectForKey:@"nameZh"] componentsSeparatedByString:@"-"]objectAtIndex:0] forKey:@"nameZh"];
                    if ([[dictionaryDataCache objectForKey:@"ID"]integerValue]<100)
                    {
                        [arrayDataCollected addObject:dictionaryDataCache];
                    }
                    
                }
                    break;
                case RouteDataTypeCityProviders:
                {

                    if ([[dictionaryDataCache objectForKey:@"ID"]integerValue]<100)
                    {
                        [arrayDataCollected addObject:dictionaryDataCache];


                    }
                }
                    break;
                case RouteDataTypeCityRoutes:
                {
                    [dictionaryDataCache setObject:@"city" forKey:@"type"];
                    [arrayDataCollected addObject:dictionaryDataCache];
                    
                }
                    break;
                case RouteDataTypeHighwayRoutes:
                {
                    [dictionaryDataCache setObject:@"highway" forKey:@"type"];
                    [arrayDataCollected addObject:dictionaryDataCache];
                }
                    break;
                default:
                    
                    break;
            }
        }
#ifdef LogOut
//        NSLog(@"%@:\n%@",stringNodeName,arrayTarget);
#endif
    [DataManager updateTableFromArray:arrayDataCollected byType:requestType];
    
    if (queueASIRequests.operationCount==0)
    {
        [self actBuildList];
    }
}

#pragma mark - 資料存取
//顯示資料建立
-(void)actBuildList
{
    [self actBuildProvidersAllList];
    if (!arrayRoutesAll)
    {
        arrayRoutesAll = [NSMutableArray new];
    }
    else
    {
        [arrayRoutesAll removeAllObjects];
    }
    [arrayRoutesAll addObjectsFromArray:arrayRoutesCity];
    [arrayRoutesAll addObjectsFromArray:arrayRoutesHighway];
    [self actGetRoutes];
}

#pragma mark - tableview Delegate&DataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return arrayTableviewRoutes.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];

    [cell.textLabel setText:[[arrayTableviewRoutes objectAtIndex:indexPath.row] objectForKey:@"nameZh"]];
    [cell.detailTextLabel setText:[[arrayTableviewRoutes objectAtIndex:indexPath.row] objectForKey:@"ddesc"]];
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    appDelegate.selectedRoute = arrayTableviewRoutes[indexPath.row];
    [appDelegate SwitchViewer:2];
}

#pragma mark - pickerView Delegate
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    switch (component)
    {
        case 0:
        {
            return 3;
        }
            break;
        case 1:
        {
            return arrayPickerviewProviders.count+1;
        }
            break;
        default:
            return 1;
            break;
    }
}
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    switch (component)
    {
        case 0:
        {
            NSArray * arrayTypeShown = @[NSLocalizedStringFromTable(@"全部種類",appDelegate.LocalizedTable,nil),NSLocalizedStringFromTable(@"市區客運業者",appDelegate.LocalizedTable,nil),NSLocalizedStringFromTable(@"國道客運業者",appDelegate.LocalizedTable,nil)];
            return [arrayTypeShown objectAtIndex:row];
        }
            break;
        case 1:
        {
            NSString * stringPickerTitle = NSLocalizedStringFromTable(@"全部路線",appDelegate.LocalizedTable,nil);
            if (row>0)
            {
                stringPickerTitle = [[arrayPickerviewProviders objectAtIndex:row-1]objectForKey:@"nameZh"];
            }
            return stringPickerTitle;
        }
            break;
        default:
            return @"error";
            break;
    }
}
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    switch (component)
    {
        case 0:
        {
            switch (row)
            {
                case 0:
                {
                    arrayPickerviewProviders = arrayProvidersAll;
                }
                    break;
                case 1:
                {
                    arrayPickerviewProviders = arrayProvidersCity;
                }
                    break;
                case 2:
                {
                    arrayPickerviewProviders = arrayProvidersHighway;
                }
                    break;
                default:
                    break;
            }
            if ([pickerView selectedRowInComponent:1] > arrayPickerviewProviders.count)
            {
                intSelectedProvider = [arrayPickerviewProviders count];
            }
            [pickerView reloadComponent:1];
        }
            break;
            
        case 1:
            intSelectedProvider = row;
            break;
        default:
            break;
    }
    [self actSetProvidersByPicker];
}

-(void)actSetProvidersByPicker
{
    if (intSelectedProvider == 0)
    {
        [self.labelProvider setText:@""];
    }
    else
    {
        NSString * stringTitle = [[arrayPickerviewProviders objectAtIndex:intSelectedProvider-1] objectForKey:@"nameZh"];
        if (stringTitle)
        {
            [self.labelProvider setText:stringTitle];
        }
    }
    [self actGetRoutes];
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

}
- (void) SilderMenuHiddenedEvent
{
    //NSLog(@"SilderMenu is Hiddened");
}
- (void) SilderMenuShowedEvent
{
    //NSLog(@"SilderMenu is Showed");
}
@end
