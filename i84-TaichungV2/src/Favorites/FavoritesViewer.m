//
//  FavoritesViewer.m
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/3/3.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "FavoritesViewer.h"
#import "FavoritesManager.h"
#import "FavoriteCell.h"
#import "DataTypes.h"
#import "AppDelegate.h"

#import "ShareTools.h"

#import "JSONKit.h"
#import "RegexKitLite.h"
#import "DataManager+Route.h"
#import "PinAnnotation.h"
#import "stopNearLinesViewController.h"
#import "busDynamicViewController.h"

@interface FavoritesViewer ()
<RequestManagerDelegate>
{
    SilderMenuView * SilderMenu;
    NSMutableArray * FavoritesDatas;
//    ASINetworkQueue * Queue;
    NSThread * UpdateArrivalT;
    NSMutableDictionary * LeftMenu_BackBtn;
    FavoritData * favoriteSelected;
}
@property (strong, nonatomic) IBOutlet UIView *viewMenu;
@property (strong, nonatomic) UIView *viewCover;
- (IBAction)actBtnMenuTouchUpInside:(id)sender;

@end

@implementation FavoritesViewer
@synthesize ContentV,FavoritesTv,EmptyLabel,ListV,MapV,MapView;
@synthesize HeadV,EditBtn,LeftMenuBtn,LabelTitle;

#define OldFavoriteAPI @"http://citybus.taichung.gov.tw/itravel/itravelAPI/ExpoAPI/FavoriteStop.aspx?RouteName=%@&StopName=%@&GoBack=%d&Type=%d"

#define EvenUpdateSec 60

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
    CGRect ContentFrame = ContentV.frame;
    
    CGRect ListFrame = ListV.frame,MapFrame = MapV.frame;
    ListFrame.size.height = ContentFrame.size.height;
    MapFrame.size.height = ContentFrame.size.height;
    MapFrame.origin.x = ContentFrame.size.width;
    [ListV setFrame:ListFrame];
    [MapV setFrame:MapFrame];
    
    [ContentV addSubview:ListV];
    [ContentV addSubview:MapV];
    
    [MapView setShowsUserLocation:YES];
    
    LeftMenu_BackBtn = [[NSMutableDictionary alloc] init];
    [LeftMenu_BackBtn setObject:@"back" forKey:@"item"];
    [LeftMenu_BackBtn setObject:@"leftmenu_back.png" forKey:@"icon"];
    [LeftMenu_BackBtn setObject:@"返回" forKey:@"title"];
    
    [self _showViewCover:NO];
    
    SilderMenu = [[SilderMenuView alloc] initWithFrame:CGRectMake(0, 0, 135, self.view.frame.size.height)];
    [SilderMenu setSilderDelegate:self];
    [ContentV addSubview:SilderMenu];
    [SilderMenu setItemsByPlistName:@"LeftMenu"];
    
    self.viewMenu.frame = self.ContentV.bounds;
    [self.ContentV insertSubview:self.viewMenu belowSubview:SilderMenu];
    [self.viewMenu setHidden:YES];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    LabelTitle.text = NSLocalizedStringFromTable(@"我的最愛", appDelegate.LocalizedTable, nil);
    FavoritesDatas = [FavoritesManager GetFavorites];
    if(FavoritesDatas == nil || [FavoritesDatas count] == 0)
    {
        [FavoritesTv setHidden:YES];
        [EmptyLabel setHidden:NO];
    }
    else
    {
        for (FavoritData * oneFav in FavoritesDatas)
        {
            NSArray * SearchResultRoute =
            [oneFav.RouteId length] != 0 ?
            [DataManager selectRouteDataKeyWord:oneFav.RouteId byColumnTitle:RouteDataColumnTypeRouteID fromTableType:oneFav.RouteKind == 0? RouteDataTypeCityRoutes : RouteDataTypeHighwayRoutes ]
            :[DataManager selectRouteDataKeyWord:oneFav.RouteName byColumnTitle:RouteDataColumnTypeRouteName fromTableType:oneFav.RouteKind == 0? RouteDataTypeCityRoutes : RouteDataTypeHighwayRoutes];
            
            if(SearchResultRoute != nil && [SearchResultRoute count] > 0)
            {
                NSDictionary * firstResult = [SearchResultRoute objectAtIndex:0];
                //舊資料GoBack 0:去程 1:返程 新資料 1:去程 2:返程
                int intGoBack = -1;
                if (![oneFav.RouteId length])
                {
                    intGoBack = oneFav.GoBack + 1;
                }
                else
                {
                    intGoBack = oneFav.GoBack;
                }
                switch (intGoBack)
                {
                    case 1:
                    {
                        [oneFav setDestination:[firstResult objectForKey:@"destinationZh"]];
                        [oneFav setDeparture:[firstResult objectForKey:@"departureZh"]];
                    }
                        break;
                    case 2:
                    {
                        [oneFav setDestination:[firstResult objectForKey:@"departureZh"]];
                        [oneFav setDeparture:[firstResult objectForKey:@"destinationZh"]];

                    }
                        break;
                        
                    default:
                        break;
                }
            }
        }
        [FavoritesTv setHidden:NO];
        [EmptyLabel setHidden:YES];
        [FavoritesTv reloadData];
    }

//    Queue = [[ASINetworkQueue alloc] init];
//    [Queue setDelegate:self];
//    [Queue setRequestDidFinishSelector:@selector(ArrivalRequestFinish:)];
//    [Queue go];
    appDelegate.requestManager.delegate = self;
}
- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self UpdateArrival];
    UpdateArrivalT = [[NSThread alloc] initWithTarget:self selector:@selector(UpdateWork) object:nil];
    [UpdateArrivalT start];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [Queue cancelAllOperations];
//    Queue = nil;
    if(UpdateArrivalT)
    {
        [UpdateArrivalT cancel];
        UpdateArrivalT = nil;
    }
    if (appDelegate.requestManager.delegate == self)
    {
        appDelegate.requestManager.delegate = nil;
    }
}

- (void) UpdateWork
{
    while (![[NSThread currentThread] isCancelled])
    {
        [self UpdateArrival];
        [NSThread sleepForTimeInterval:EvenUpdateSec];
    }
}
- (void) UpdateArrival
{
    if(![ShareTools connectedToNetwork])
    {
        if([[NSThread currentThread] isMainThread])
        {
            UIAlertView * AlertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"請確定網路是否啟用", appDelegate.LocalizedTable, nil) delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"確定", appDelegate.LocalizedTable, nil) otherButtonTitles:nil, nil];
            [AlertView show];
        }
        return;
    }
    for(FavoritData * oneBus in FavoritesDatas)
    {
        if([oneBus.RouteId length] == 0 && [oneBus.StopId length] == 0)
        {
            //舊式資料
            [self SendArrivalRequestbyRouteName:oneBus.RouteName
                                StopName:oneBus.StopName
                                GoBack:oneBus.GoBack
                                Type:oneBus.RouteKind ];
        }
        else
        {
            [self SendArrivalRequestbyRouteId:oneBus.RouteId
                                       StopId:oneBus.StopId
                                         GoBack:oneBus.GoBack
                                           Type:oneBus.RouteKind ];
        }
    }
}

-(IBAction) LeftMenuBtnClickEvent:(id)sender
{
    /*
     edit Cooper 2015/08/20
     0807buglist 台中第四項
     台中用額外的lib，所以只好一頁一頁改…
     */
    if(![LeftMenuBtn isSelected])
    {
        [SilderMenu SilderShow];
        [self _showViewCover:YES];
    }
    else
    {
        [SilderMenu SilderHidden];
        [self _showViewCover:NO];
    }
    [LeftMenuBtn setSelected:![LeftMenuBtn isSelected]];
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
        [self.viewCover addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(LeftMenuBtnClickEvent:)]];
        [ContentV addSubview:self.viewCover];
    }
    [self.viewCover setHidden:!bb];
}
-(IBAction) EditBtnClickEvent:(id)sender
{
    if([LeftMenuBtn isSelected])
    {
        [SilderMenu SilderHidden];
    }
    if(![EditBtn isSelected])
    {
        [FavoritesTv setEditing:YES animated:YES];
        [FavoritesTv setAllowsSelectionDuringEditing:NO];
//        [FavoritesTv beginUpdates];
        [FavoritesTv setAllowsSelection:NO];
    }
    else
    {
//        [FavoritesTv endUpdates];
        [FavoritesTv setEditing:NO animated:YES];
        [FavoritesTv setAllowsSelection:YES];
        NSThread * UpdataT = [[NSThread alloc] initWithTarget:self selector:@selector(WriteFavSeqToSqlite) object:nil];
        [UpdataT start];
    }
    [EditBtn setSelected:![EditBtn isSelected]];
}
#pragma mark View Change
- (void) ShowListV
{
    if([[NSThread currentThread] isMainThread])
    {
        CGRect MapVframe = MapV.frame;
        CGRect ListVframe = ListV.frame;
        
        MapVframe.origin.x = MapVframe.size.width;
        ListVframe.origin.x = 0;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.6];
        [UIView setAnimationDelegate:self];
        [MapV setFrame:MapVframe];
        [ListV setFrame:ListVframe];
        [EditBtn setAlpha:1.0f];
        [UIView commitAnimations];
        
        [SilderMenu removeItem:LeftMenu_BackBtn];
    }
    else
    {
        [self performSelectorOnMainThread:@selector(ShowListV) withObject:nil waitUntilDone:YES];
        return;
    }
}
- (void) ShowMapV
{
    if([[NSThread currentThread] isMainThread])
    {
        CGRect MapVframe = MapV.frame;
        CGRect ListVframe = ListV.frame;
        
        MapVframe.origin.x = 0;
        ListVframe.origin.x = -1 * ListVframe.size.width;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.6];
        [UIView setAnimationDelegate:self];
        [MapV setFrame:MapVframe];
        [ListV setFrame:ListVframe];
        [EditBtn setAlpha:0.0f];
        [UIView commitAnimations];
        
        [SilderMenu insertItem:LeftMenu_BackBtn];
    }
    else
    {
        [self performSelectorOnMainThread:@selector(ShowMapV) withObject:nil waitUntilDone:YES];
        return;
    }
}
#pragma mark 排序寫入資料庫
- (void) WriteFavSeqToSqlite
{
    for(int i=0;i<[FavoritesDatas count];i++)
    {
        FavoritData * oneFavData = [FavoritesDatas objectAtIndex:i];
        [FavoritesManager UpdateFavoritesByRouteId:oneFavData.RouteId RouteName:oneFavData.RouteName StopId:oneFavData.StopId StopName:oneFavData.StopName GoBack:oneFavData.GoBack RouteKind:oneFavData.RouteKind Seq:i Lon:oneFavData.Lon Lat:oneFavData.Lat];
    }
}

#pragma mark SilderMenu

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
    else if([SelectedItem compare:@"back"] == 0)
    {
        [self ShowListV];
        [SilderMenu SilderHidden];
    }
    else if([SelectedItem compare:@"language"] == 0)
    {
        [appdelegate SwitchViewer:11];
    }
}

- (void) SilderMenuHiddenedEvent
{
}
- (void) SilderMenuShowedEvent
{
    [LeftMenuBtn setSelected:YES];
}
#pragma mark TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //return 44.0f;
    float Height = 44.0;
//    FavoritData * oneFav = [FavoritesDatas objectAtIndex:[indexPath row]];
//    CGSize maxStopSize = CGSizeMake(100,42);
//    CGSize StopSize = [oneFav.StopName sizeWithFont:[UIFont systemFontOfSize:14.0f] constrainedToSize:maxStopSize lineBreakMode:UILineBreakModeClip];

    return Height;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(FavoritesDatas == nil)
    {
        return 0;
    }
    else
    {
        return [FavoritesDatas count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FavoriteCell * cell = [tableView dequeueReusableCellWithIdentifier:@"FavoriteCell"];
    if (cell == nil)
    {
        NSArray *nib=[[NSBundle mainBundle] loadNibNamed:@"FavoriteCell" owner:self options:nil];
        cell = (FavoriteCell *)[nib objectAtIndex:0];
    }
    FavoritData * oneFav = [FavoritesDatas objectAtIndex:[indexPath row]];
    [cell.RouteLbl setText:oneFav.RouteName];
    [cell.StopLbl setText:oneFav.StopName];
    
    //目的 "往xx"
    if(oneFav.Destination != nil && [oneFav.Destination length] > 0)
    {
        [cell.GotoLbl setText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"往:%@", appDelegate.LocalizedTable, nil),oneFav.Destination ]];
    }
    else
    {
        [cell.GotoLbl setText:@""];
    }

    //顯示車種
    switch (oneFav.RouteKind)
    {
        case 0:
            [cell.IconIv setImage:[UIImage imageNamed:@"routekind_city.png"]];
            break;
        case 1:
            [cell.IconIv setImage:[UIImage imageNamed:@"routekind_highway.png"]];
            break;
    }
    
    //顯示時間
    if(oneFav.Arrival < 3)
    {
        switch (oneFav.Arrival)
        {
            case -5:
                [cell.ArrivalLbl setText:NSLocalizedStringFromTable(@"更新中", appDelegate.LocalizedTable, nil)];
                break;
            case -3:
                [cell.ArrivalLbl setText:NSLocalizedStringFromTable(@"末班駛離", appDelegate.LocalizedTable, nil)];
                break;
            case 0:
                [cell.ArrivalLbl setText:NSLocalizedStringFromTable(@"進站中", appDelegate.LocalizedTable, nil)];
                break;
            case 1:
            case 2:
            case 3:
                [cell.ArrivalLbl setText:NSLocalizedStringFromTable(@"將進站", appDelegate.LocalizedTable, nil)];
                break;
            case -1:
            default:
                if(oneFav.Arrival2 != nil && [oneFav.Arrival2 length] > 0 && ![oneFav.Arrival2 isEqualToString:@"null"])
                {
                    [cell.ArrivalLbl setText:oneFav.Arrival2];
                }
                else
                {
                    [cell.ArrivalLbl setText:NSLocalizedStringFromTable(@"未發車", appDelegate.LocalizedTable, nil)];
                }
                
                break;
        }
    }
    else
    {
        [cell.ArrivalLbl setText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"%d分", appDelegate.LocalizedTable, nil),oneFav.Arrival]];
    }

//    if(oneFav.Arrival < 3)
//    {
//        switch (oneFav.Arrival)
//        {
//                break;
//            case -5:
//                [cell.ArrivalLbl setText:@"更新中"];
//                break;
//            case -3:
//                [cell.ArrivalLbl setText:@"末班駛離"];
//                break;
//            case 0:
//                [cell.ArrivalLbl setText:@"進站中"];
//                break;
//            case 1:
//            case 2:
//            case 3:
//                [cell.ArrivalLbl setText:@"將進站"];
//                break;
//            case -1:
//            default:
//                if(oneFav.Arrival2 != nil && [oneFav.Arrival2 length] > 0)
//                {
//                    [cell.ArrivalLbl setText:oneFav.Arrival2];
//                }
//                else
//                {
//                    [cell.ArrivalLbl setText:@"已離站"];
//                }
//                
//                break;
//        }
//    }
//    else
//    {
//        [cell.ArrivalLbl setText:[NSString stringWithFormat:@"%d分",oneFav.Arrival]];
//    }
    
    return cell;
}
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    FavoritData * insertObj = [FavoritesDatas objectAtIndex:[fromIndexPath row ]];
    [FavoritesDatas removeObjectAtIndex:[fromIndexPath row]];
    [FavoritesDatas insertObject:insertObj atIndex:[toIndexPath row]];
}

//- (NSIndexPath *) tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
//{
//    
//}
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSDictionary * oneItem = (NSDictionary *) [Items objectAtIndex:[indexPath row]];
//    if(SilderDelegate != nil)
//    {
//        [SilderDelegate ItemSelectedEvent:(NSString *)[oneItem objectForKey:@"item"]];
//    }
    if([LeftMenuBtn isSelected])
    {
        [SilderMenu SilderHidden];
    }
    favoriteSelected = (FavoritData *)[FavoritesDatas objectAtIndex:[indexPath row]];
        [self actFadeInView:self.viewMenu];
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        FavoritData * deldata = [FavoritesDatas objectAtIndex:[indexPath row]];
        
        FavoriteResult result = [FavoritesManager DeleteFavoritesByRouteId:deldata.RouteId RouteName:deldata.RouteName StopId:deldata.StopId StopName:deldata.StopName GoBack:deldata.GoBack RouteKind:deldata.RouteKind];
        if(result == success)
        {
            [FavoritesDatas removeObject:deldata];
            [FavoritesTv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            [FavoritesTv endUpdates];
            [FavoritesTv beginUpdates];
//            [FavoritesTv reloadData];
        }
        else
        {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"刪除失敗", appDelegate.LocalizedTable, nil) message:NSLocalizedStringFromTable(@"請再試一次或提交問題回報", appDelegate.LocalizedTable, nil) delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確定", appDelegate.LocalizedTable, nil) otherButtonTitles:nil, nil];
            [alert show];
        }
    }
    
    if([FavoritesDatas count] == 0)
    {
        [FavoritesTv setHidden:YES];
        [EmptyLabel setHidden:NO];
    }
}
#pragma mark ASIHTTP
- (void) SendArrivalRequestbyRouteName:(NSString *)Route StopName:(NSString *)Stop GoBack:(int)GoBack Type:(int)Type
{
    NSString * stringUrl = [NSString stringWithFormat:OldFavoriteAPI,[ShareTools GetUTF8Encode:Route],[ShareTools GetUTF8Encode:Stop],GoBack,Type];
    [appDelegate.requestManager addRequestWithKey:[NSString stringWithFormat:@"arrive-|old-|%@-|%@-|%ld",Route,Stop,(long)GoBack] andUrl:stringUrl byType:RequestDataTypeJson];
    
//    if(![ShareTools connectedToNetwork])
//    {
//        return;
//    }
//    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:OldFavoriteAPI,[ShareTools GetUTF8Encode:Route],[ShareTools GetUTF8Encode:Stop],GoBack,Type]];
//    NSLog(@"Url:%@",url);
//    ASIHTTPRequest * Request = [[ASIHTTPRequest alloc] initWithURL:url];
//    [Request setTimeOutSeconds:30.0];
//    [Request setDelegate:self];
//    [Request setDidFinishSelector:@selector(ArrivalRequestFinish:)];
//    [Queue addOperation:Request];
//    [Queue go];
}
- (void) SendArrivalRequestbyRouteId:(NSString *)Route StopId:(NSString *)Stop GoBack:(int)GoBack Type:(int)Type
{
    NSString * stringUrl = [NSString stringWithFormat:NewFavoriteAPI,Route,Stop,GoBack,Type];
    [appDelegate.requestManager addRequestWithKey:[NSString stringWithFormat:@"arrive-|new-|%@-|%@-|%ld",Route,Stop,(long)GoBack] andUrl:stringUrl byType:RequestDataTypeJson];
    
//    if(![ShareTools connectedToNetwork])
//    {
//        return;
//    }
//    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:NewFavoriteAPI,Route,Stop,GoBack,Type]];
//    NSLog(@"Url:%@",url);
//    ASIHTTPRequest * Request = [[ASIHTTPRequest alloc] initWithURL:url];
//    [Request setTimeOutSeconds:30.0];
//    [Request setDelegate:self];
//    [Request setDidFinishSelector:@selector(ArrivalRequestFinish:)];
//    [Queue addOperation:Request];
//    [Queue go];
}

#pragma mark - RequestManager
-(void)requestManager:(id)requestManager returnInputErrorWithKey:(NSString *)key
{
    
}
-(void)requestManager:(id)requestManager returnNoDataWithKey:(NSString *)key
{
    
}
-(void)requestManager:(id)requestManager returnJSONSerialization:(NSJSONSerialization *)jsonSerialization withKey:(NSString *)key
{
    if ([key hasPrefix:@"arrive"])
    {
        NSString * RouteName = nil,* StopName = nil;
        int GoBack = -1;
        int RouteKind = -1;
        
        NSArray * arrayKey = [key componentsSeparatedByString:@"-|"];
        if ([[arrayKey objectAtIndex:1]isEqualToString:@"old"])
        {
            RouteName = [arrayKey objectAtIndex:2];
            StopName = [arrayKey objectAtIndex:3];
            GoBack = [[arrayKey objectAtIndex:4]intValue];
        }
        NSArray * Results = (NSArray*)jsonSerialization;
        for(NSDictionary * oneResult in Results)
        {
            NSString * RouteId = (NSString *)[oneResult objectForKey:@"RouteID"];
            NSString * StopId = (NSString *)[oneResult objectForKey:@"StopID"];
            if(GoBack == -1)
            {
                GoBack = [(NSString *)[oneResult objectForKey:@"GoBack"] intValue];
            }
            NSString * stringArrivalTime = [oneResult objectForKey:@"ArrivalTime"];
            if ([stringArrivalTime isEqualToString:@""]||[stringArrivalTime isEqualToString:@"null"])
            {
                stringArrivalTime = @"-99";
            }
            int ArrivalTime = [stringArrivalTime intValue];
            NSString * ArrivalTime2 = (NSString *)[oneResult objectForKey:@"ArrivalTime2"];
            if(RouteKind == -1)
            {
                RouteKind = [(NSString *)[oneResult objectForKey:@"Type"] intValue];
            }
            FavoritData * UpdateBus = nil;
            int Seq = -1;
            
            for(int i=0;i<[FavoritesDatas count];i++)
            {
                FavoritData * oneBus = [FavoritesDatas objectAtIndex:i];
                
                if([oneBus.RouteId length] == 0 || [oneBus.StopId length] == 0)
                {
                    
                    //舊資料
                    if([oneBus.RouteName compare:RouteName] == 0
                       && [oneBus.StopName compare:StopName] == 0
                       && oneBus.GoBack == GoBack
                       && oneBus.RouteKind == RouteKind)
                    {
                        UpdateBus = oneBus;
                        Seq = i;
                        break;
                    }
                }
                else
                {
                    //新資料
                    if([oneBus.RouteId compare:RouteId] == 0
                       && [oneBus.StopId compare:StopId] == 0
                       && oneBus.GoBack == GoBack
                       && oneBus.RouteKind == RouteKind)
                    {
                        UpdateBus = oneBus;
                        Seq = i;
                        break;
                    }
                }
            }
            if(UpdateBus != nil)
            {
                if([UpdateBus.RouteId length] == 0 || [UpdateBus.StopId length] == 0)
                {
                    [FavoritesManager UpdateFavoritesByRouteId:RouteId RouteName:UpdateBus.RouteName StopId:StopId StopName:UpdateBus.StopName GoBack:UpdateBus.GoBack+1 RouteKind:UpdateBus.RouteKind Seq:Seq Lon:UpdateBus.Lon Lat:UpdateBus.Lat];
                    [UpdateBus setRouteId:RouteId];
                    [UpdateBus setStopId:StopId];
                }
                [UpdateBus setArrival:ArrivalTime];
                [UpdateBus setArrival2:ArrivalTime2];
                [FavoritesTv reloadData];
            }
        }

    }
}

-(void)ArrivalRequestFinish:(ASIHTTPRequest *)Request
{
    NSString * Response = [Request responseString];
    
//    NSLog(@"Response:%@",Response);
    if([Request responseStatusCode] == 200 && ![Response hasPrefix:@"err"])
    {
        NSString * fixedUrl = [[Request url] relativeString];
        NSString * RouteName = nil,* StopName = nil;
        int GoBack = -1;
        int RouteKind = -1;
        NSArray * matchs = [fixedUrl arrayOfCaptureComponentsMatchedByRegex:@"RouteName=([^&]+)&StopName=([^&]+)&GoBack=(\\d+)&Type=(\\d+)"];
        if(matchs != nil && [matchs count] > 0)
        {
            matchs = [matchs objectAtIndex:0];
            if([matchs count] >= 4)
            {
                RouteName = [ShareTools GetUTF8Dncode:[matchs objectAtIndex:1]];
                StopName =  [ShareTools GetUTF8Dncode:[matchs objectAtIndex:2]];
                GoBack = [[matchs objectAtIndex:3] intValue];
                RouteKind = [[matchs objectAtIndex:4] intValue];
            }
        }
        
        JSONDecoder * Parser = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
        NSArray * Results = [Parser objectWithData:[Request responseData]];
        
        for(NSDictionary * oneResult in Results)
        {
            NSString * RouteId = (NSString *)[oneResult objectForKey:@"RouteID"];
            NSString * StopId = (NSString *)[oneResult objectForKey:@"StopID"];
            if(GoBack == -1)
            {
                GoBack = [(NSString *)[oneResult objectForKey:@"GoBack"] intValue];
            }
            int ArrivalTime = [(NSString *)[oneResult objectForKey:@"ArrivalTime"] intValue];
            NSString * ArrivalTime2 = (NSString *)[oneResult objectForKey:@"ArrivalTime2"];
            if(RouteKind == -1)
            {
                RouteKind = [(NSString *)[oneResult objectForKey:@"Type"] intValue];
            }
            FavoritData * UpdateBus = nil;
            int Seq = -1;

            for(int i=0;i<[FavoritesDatas count];i++)
            {
                FavoritData * oneBus = [FavoritesDatas objectAtIndex:i];

                if([oneBus.RouteId length] == 0 || [oneBus.StopId length] == 0)
                {
                    if([oneBus.RouteName compare:RouteName] == 0
                       && [oneBus.StopName compare:StopName] == 0
                       && oneBus.GoBack == GoBack
                       && oneBus.RouteKind == RouteKind)
                    {
                        UpdateBus = oneBus;
                        Seq = i;
                        break;
                    }
                }
                else
                {
                    if([oneBus.RouteId compare:RouteId] == 0
                       && [oneBus.StopId compare:StopId] == 0
                       && oneBus.GoBack == GoBack
                       && oneBus.RouteKind == RouteKind)
                    {
                        UpdateBus = oneBus;
                        Seq = i;
                        break;
                    }
                }
            }
            if(UpdateBus != nil)
            {
                if([UpdateBus.RouteId length] == 0 || [UpdateBus.StopId length] == 0)
                {
                    [FavoritesManager UpdateFavoritesByRouteId:RouteId RouteName:UpdateBus.RouteName StopId:StopId StopName:UpdateBus.StopName GoBack:UpdateBus.GoBack RouteKind:UpdateBus.RouteKind Seq:Seq Lon:UpdateBus.Lon Lat:UpdateBus.Lat];
                    [UpdateBus setRouteId:RouteId];
                    [UpdateBus setStopId:StopId];
                }
                [UpdateBus setArrival:ArrivalTime];
                [UpdateBus setArrival2:ArrivalTime2];

                [FavoritesTv reloadData];
//                @try {
//                    if(![EditBtn isSelected])
//                    {
//                        [FavoritesTv beginUpdates];
//                        [FavoritesTv reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:Seq inSection:0 ]] withRowAnimation:UITableViewRowAnimationNone];
//                        [FavoritesTv endUpdates];
//                    }
//                    else
//                    {
//                        [FavoritesTv reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:Seq inSection:0 ]] withRowAnimation:UITableViewRowAnimationNone];
//                    }
//                }
//                @catch (NSException *exception) {
//
//                }
//                @finally {
//
//                }
                
//                [FavoritesTv reloadData];
            }

            
        }

        
        
    }
}
-(void)actFadeInView:(UIView*)view
{
    if (view.hidden == YES)
    {
        view.alpha = 0.0;
        view.hidden = NO;
        [UIView animateWithDuration:0.5 animations:^{
            view.alpha = 1.0;
        }];
    }
}

-(void)actFadeOutView:(UIView*)view
{
    if (view.hidden == NO)
    {
        [UIView animateWithDuration:0.5 animations:^{
            view.alpha = 0.0;
        } completion:^(BOOL finished){
            view.alpha = 1.0;
            view.hidden = YES;
        }];
    }
}
- (IBAction)actBtnMenuTouchUpInside:(UIButton*)sender
{

    
    switch (sender.tag)
    {
        case 2://地圖
        {
            if(favoriteSelected.Lon > 0 && favoriteSelected.Lat > 0)
            {
                [MapView setShowsUserLocation:NO];
                [self ShowMapV];
                
                [MapView removeAnnotations:MapView.annotations];
                
                PinAnnotation * StopPin = [[PinAnnotation alloc] initWithCoordinate:CLLocationCoordinate2DMake(favoriteSelected.Lat, favoriteSelected.Lon)];
                [StopPin setTitle:favoriteSelected.RouteName];
                [StopPin setSubtitle:favoriteSelected.StopName];
                [MapView addAnnotation:StopPin];
                
                MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(StopPin.coordinate, 500, 500);
                MKCoordinateRegion adjustedRegion = [MapView regionThatFits:viewRegion];
                [MapView setRegion:adjustedRegion animated:YES];
                [MapView setShowsUserLocation:YES];
                
            }
            else
            {
                UIAlertView * alert = [[UIAlertView alloc]initWithTitle:NSLocalizedStringFromTable(@"舊版我的最愛不支援地圖功能", appDelegate.LocalizedTable, nil) message:NSLocalizedStringFromTable(@"請重新加入我的最愛", appDelegate.LocalizedTable, nil) delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"OK", appDelegate.LocalizedTable, nil) otherButtonTitles:nil];
                [alert show];
            }
            
        }
            break;
        case 0://公車動態
        {
            NSMutableDictionary * dictionaryRoute = [NSMutableDictionary new];
            [dictionaryRoute setObject:favoriteSelected.StopName forKey:@"StopName"];
            [dictionaryRoute setObject:favoriteSelected.RouteName forKey:@"nameZh"];
            [dictionaryRoute setObject:favoriteSelected.RouteId forKey:@"ID"];
            [dictionaryRoute setObject:[NSString stringWithFormat:@"%d",favoriteSelected.GoBack] forKey:@"GoBack"];

            if (favoriteSelected.GoBack==1)
            {
                [dictionaryRoute setObject:favoriteSelected.Destination forKey:@"departureZh"];
                [dictionaryRoute setObject:favoriteSelected.Departure forKey:@"destinationZh"];

            }
            else
            {
                [dictionaryRoute setObject:favoriteSelected.Destination forKey:@"destinationZh"];
                [dictionaryRoute setObject:favoriteSelected.Departure forKey:@"departureZh"];
            }
            [dictionaryRoute setObject:favoriteSelected.RouteId forKey:@"ID"];
            [dictionaryRoute setObject:favoriteSelected.RouteKind?@"highway":@"city" forKey:@"type"];
            
            appDelegate.selectedRoute = dictionaryRoute;

            busDynamicViewController * viewControllerBusDynamic = [[busDynamicViewController alloc]initWithNibName:@"busDynamicViewController" bundle:nil];
            viewControllerBusDynamic.boolFromFavorite = YES;
            [self presentViewController:viewControllerBusDynamic animated:YES completion:^{}];

        }
            break;
        case 1://經過路線
        {
            NSMutableDictionary * dictionaryStop = [NSMutableDictionary new];
            [dictionaryStop setObject:favoriteSelected.StopName forKey:@"StopName"];
            [dictionaryStop setObject:favoriteSelected.RouteName forKey:@"nameZh"];
            stopNearLinesViewController * viewControllerStopNearLines = [[stopNearLinesViewController alloc]initWithNibName:@"stopNearLinesViewController" bundle:nil];
            appDelegate.selectedStop = dictionaryStop;
            [self presentViewController:viewControllerStopNearLines animated:YES completion:^{}];
        }
            break;
            
        default:
            break;
    }

    [self actFadeOutView:self.viewMenu];
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.viewMenu.hidden == NO)
    {
        [self actFadeOutView:self.viewMenu];
    }
}
@end
