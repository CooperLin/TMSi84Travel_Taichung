//
//  RoutePlanViewer.m
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/3/10.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "RoutePlanViewer.h"
#import "AppDelegate.h"
#import "PlanSchemeView.h"
#import "PlanResultCell.h"
#import "DataTypes.h"
#import "MBProgressHUD.h"
#import <QuartzCore/QuartzCore.h>
#import "AttractionManager.h"

#import "DataManager+Route.h"

#import "ShareTools.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>
#import <CFNetwork/CFNetwork.h>
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "JSONKit.h"
#import "FavoritesViewer.h"

#define APISearchKeyWord @"http://citybus.taichung.gov.tw/iTravel/iTravelAPI/ExpoAPI/LocationInfo.ashx?keyword=%@"
#define SearchAddressAPI @"https://maps.googleapis.com/maps/api/geocode/json?address=%@,臺中&region=tw&language=Zh-Tw&sensor=true"
#define RoutePlanAPI NSLocalizedStringFromTable(@"iTravelRoutePlan", appDelegate.LocalizedTable, nil)
//#define RoutePlanAPI @"http://citybus.taichung.gov.tw/iTravel/iTravel_WS/Service.asmx/JsonTravelPlan?SPx=%.6f&SPy=%.6f&EPx=%.6f&EPy=%.6f&GoDay=%@&GoTime=%@&Lang=%@&Mode=%@&UserPickPlace=&source=I&SName=%@&EName=%@&SType=%@&EType=%@"


#define CellRouteMaxSize CGSizeMake(42,105)
#define CellDescMaxSize CGSizeMake(217,105)
typedef enum
{
    Void = 0
    ,NowLocation = 1
    ,Home = 2
    ,Company = 3
    ,SelectedLandmark
} RoutePlanKind;
typedef enum
{
    RoutePlanTableKindLandmarks = 0
    ,RoutePlanTableKindHotSpots = 1
    ,RoutePlanTableKindCollections = 2
    ,RoutePlanTableKindPlanResults = 3
} RoutePlanTableKind;

typedef enum
{
    RoutePlanTimeTypeSetting = 2
    ,RoutePlanTimeTypeNow = 0
    ,RoutePlanTimeTypeNoTime = 1
} RoutePlanTimeType;

@interface RoutePlanViewer ()
{
    SilderMenuView * SilderMenu;
    
    int EditLandmarkTfKind;
    RoutePlanTableKind TableDataKind;//0搜尋地標1熱門2收藏3規劃結果
    NSIndexPath * SelectedIndexPath;
    LandMark * SelectedLm;
    
    RoutePlanKind StartPlanKind;
    RoutePlanKind EndPlanKind;
    
    PlanSchemeView * schemeview;
    
    NSMutableArray * SearchLms;
    NSMutableArray * HotLms;
    NSMutableArray * CollectLms;
    NSMutableArray * PlanResults;//規劃結果
    
    NSThread * SearchT; //搜尋Thread
    
    MBProgressHUD * hud;
    UITapGestureRecognizer * OutSideTapRecognizer;
    
    CLLocation * nowLocation;
    CLLocationManager * locmanager;
    
    LandMark * HomeLm,* CompanyLm,* StartLm,* EndLm;
    
    NSMutableDictionary * LeftMenu_BackBtn;
    
    NSThread * ArrivalUpdataT; //規劃結果到站時間更新Thread
    
    //用來判斷選擇路徑規劃的時間, cell用來判斷要不要顯示即時公車到站時間
    RoutePlanTimeType routhPlanTimeType;
    
}
@property (strong, nonatomic) IBOutlet UILabel *labelDatePickerResult;
@property (strong, nonatomic) IBOutlet UIView *viewTimeMenu;
@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (strong, nonatomic) IBOutlet UIView *viewDatePicker;
@property (strong, nonatomic) UIView *viewCover;
- (IBAction)actBtnTimeMenuTouchUpInside:(id)sender;
- (IBAction)actBtnDatePickerTouchUpInside:(id)sender;
- (IBAction)actDatePickerDidScrolled:(id)sender;


@end

@implementation RoutePlanViewer
@synthesize ContentV, StartLandmarkTf, EndLandmarkTf, SubContentV,BackToHotVBtn,SearchToHotVBtn;
@synthesize HeadV, SetBtn, LeftMenuBtn, ListTitle, SetTitle, ListStartPoint, ListEndPoint, ListSearchBtn;
@synthesize HotV;
@synthesize ListV, ListTv,EmptyLbl,MenuNoTime,MenuTimeNow,MenuTimeCustom;
@synthesize LandmarkSubV,LandmarkSubV1,LandmarkSubV2;
@synthesize SearchV,SearchLayout,SearchTf,SearchTv,SearchEmptyLbl,SearchTitle,HideSearchBtn,HideSetBtn;
@synthesize SetV,SetLayout,AddressTf,LocationSeg,LocationMapV,SaveSetBtn;
@synthesize NowLocationImg,HomeImg,CompanyImg,HotLandmark,MyCollect;
@synthesize LandmarkStart,LandmarkEnd,LandmarkAddCollect;



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
    
    [SearchTf addTarget:self action:@selector(textfieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
//    SearchTf.delegate = self;
    
    CGRect SubContentVFrame = SubContentV.frame;
    if(IS_WIDESCREEN)
    {
        SubContentVFrame.size.height = self.view.frame.size.height - 115;
        [SubContentV setFrame:SubContentVFrame];
    }
    
    CGRect HotVFrame = HotV.frame;
    if(IS_WIDESCREEN)
    {
        HotVFrame.origin.y = (SubContentVFrame.size.height - HotVFrame.size.height)/2;
    }
    else
    {
        HotVFrame.origin.y = HotVFrame.origin.y - 10;
    }
    [HotV setFrame:HotVFrame];
    [SubContentV addSubview:HotV];
    
    CGRect ListVFrame = ListV.frame;
    ListVFrame.origin.x = ListVFrame.size.width;
    ListVFrame.origin.y = 0;
    ListVFrame.size.height =SubContentV.frame.size.height;
    [ListV setFrame:ListVFrame];
    [SubContentV addSubview:ListV];

    CGRect ListTvFrame = ListTv.frame;
    ListTvFrame.size.height =ListVFrame.size.height-22;
    [ListTv setFrame:ListTvFrame];
    
    //設定搜尋子頁面圓角
    [self.view addSubview:SearchV];
    [SearchLayout.layer setCornerRadius:15.0f];
    for(int i = 0;i<2;i++)
    {
        UIView * onev = [SearchLayout.subviews objectAtIndex:i];
        if([onev isKindOfClass:[UIImageView class]])
        {
            UIImageView * oneIv = (UIImageView *) onev;
            oneIv.layer.masksToBounds = YES;
        }
        [onev.layer setCornerRadius:15.0f];
    }
    
    CGRect frame = self.view.frame;
    CGRect searchframe = SearchV.frame;
    searchframe.origin.y = frame.size.height;
    searchframe.size.height = frame.size.height;
    [SearchV setFrame:searchframe];
    
    [self.view addSubview:SetV];
    [SetLayout.layer setCornerRadius:15.0f];
    for(int i = 0;i<2;i++)
    {
        UIView * onev = [SetLayout.subviews objectAtIndex:i];
        if([onev isKindOfClass:[UIImageView class]])
        {
            UIImageView * oneIv = (UIImageView *) onev;
            oneIv.layer.masksToBounds = YES;
        }
        [onev.layer setCornerRadius:15.0f];
    }
    
    [SetV setFrame:searchframe];
    
    SearchLms = [[NSMutableArray alloc] init];
    HotLms = [[NSMutableArray alloc] init];
    CollectLms = [[NSMutableArray alloc] init];
    PlanResults = [[NSMutableArray alloc] init];
    
    [self _showViewCover:NO];
    
    SilderMenu = [[SilderMenuView alloc] initWithFrame:CGRectMake(0, 0, 135, self.view.frame.size.height)];
    [SilderMenu setSilderDelegate:self];
    [ContentV addSubview:SilderMenu];
    [SilderMenu setItemsByPlistName:@"LeftMenu"];
    
    OutSideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(TapOutSide:)];
    EditLandmarkTfKind = -1;
    
    [self ReadHomeCompanySetting];
    
    HotLms = [AttractionManager ReadHopLandmark];
    
    LeftMenu_BackBtn = [[NSMutableDictionary alloc] init];
    [LeftMenu_BackBtn setObject:@"back" forKey:@"item"];
    [LeftMenu_BackBtn setObject:@"leftmenu_back.png" forKey:@"icon"];
    [LeftMenu_BackBtn setObject:@"返回" forKey:@"title"];
    
    self.viewTimeMenu.frame = self.ContentV.bounds;
    [self.ContentV insertSubview:self.viewTimeMenu belowSubview:self.viewTimeMenu];
    [self.viewTimeMenu setHidden:YES];
    self.viewDatePicker.frame = self.ContentV.bounds;
    [self.ContentV insertSubview:self.viewDatePicker belowSubview:self.viewTimeMenu];
    [self.viewDatePicker setHidden:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _showI18N];
    if(locmanager == nil)
    {
        locmanager = [[CLLocationManager alloc] init];
        [locmanager setDelegate:self];
        [locmanager setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
    }
    [locmanager startUpdatingLocation];
    if(![CLLocationManager locationServicesEnabled])
    {

        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:NSLocalizedStringFromTable(@"需使用GPS裝置",appDelegate.LocalizedTable,nil)
                                             message:NSLocalizedStringFromTable(@"若欲使用完整功能, 請允許使用GPS",appDelegate.LocalizedTable,nil)
                                            delegate:nil
                                   cancelButtonTitle:NSLocalizedStringFromTable(@"OK",appDelegate.LocalizedTable,nil)
                                   otherButtonTitles:nil];
        [alert show];
    }
    if(ListV.frame.origin.x == 0
       && TableDataKind == RoutePlanTableKindPlanResults && [PlanResults count] > 0)
    {
        ArrivalUpdataT = [[NSThread alloc] initWithTarget:self selector:@selector(UpdataArrivalWork) object:nil];
        [ArrivalUpdataT start];
    }
    appDelegate.requestManager.delegate = self;
}
-(void)_showI18N
{
    SearchTf.placeholder = NSLocalizedStringFromTable(@"請鍵入關鍵字", appDelegate.LocalizedTable, nil);
    SearchEmptyLbl.text = NSLocalizedStringFromTable(@"沒有相符結果", appDelegate.LocalizedTable, nil);
    SearchTitle.text = NSLocalizedStringFromTable(@"搜尋地標", appDelegate.LocalizedTable, nil);
    [HideSearchBtn setTitle:NSLocalizedStringFromTable(@"隱藏鍵盤", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    [HideSearchBtn.titleLabel setAdjustsFontSizeToFitWidth:YES];
    [HideSetBtn setTitle:NSLocalizedStringFromTable(@"隱藏鍵盤", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    [HideSetBtn.titleLabel setAdjustsFontSizeToFitWidth:YES];
    EmptyLbl.text = NSLocalizedStringFromTable(@"無相符結果", appDelegate.LocalizedTable, nil);
    ListTitle.text = NSLocalizedStringFromTable(@"路線規劃", appDelegate.LocalizedTable, nil);
    ListStartPoint.text = NSLocalizedStringFromTable(@"起點", appDelegate.LocalizedTable, nil);
    ListEndPoint.text = NSLocalizedStringFromTable(@"訖點", appDelegate.LocalizedTable, nil);
    [ListSearchBtn setTitle:NSLocalizedStringFromTable(@"查詢", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    AddressTf.placeholder = NSLocalizedStringFromTable(@"請鍵入地址或關鍵字", appDelegate.LocalizedTable, nil);
    [LandmarkEndPoint setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"routeplan_setend.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    [LandmarkAdd setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"routeplan_addcollect.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    [LandmarkStartPoint setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"routeplan_setstart.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    [LandmarkCollect setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"routeplan_addcollect.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    [LandmarkStart setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"routeplan_setstart.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    [LandmarkEnd setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"routeplan_setend.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    [LandmarkAddCollect setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"routeplan_addcollect.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    [MenuTimeCustom setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"自訂時間.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    [MenuTimeNow setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"現在時間.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    [MenuNoTime setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"無時間.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    [NowLocationImg setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"routeplan_nowlocation.png", appDelegate.LocalizedTable, nil)]];
    [HomeImg setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"routeplan_home.png", appDelegate.LocalizedTable, nil)]];
    [CompanyImg setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"routeplan_company.png", appDelegate.LocalizedTable, nil)]];
    [HotLandmark setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"routeplan_hotlandmark.png", appDelegate.LocalizedTable, nil)]];
    [MyCollect setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"routeplan_collect.png", appDelegate.LocalizedTable, nil)]];
    SetTitle.text = NSLocalizedStringFromTable(@"設定", appDelegate.LocalizedTable, nil);
    [LocationSeg setTitle:NSLocalizedStringFromTable(@"家_seg", appDelegate.LocalizedTable, nil) forSegmentAtIndex:0];
    [LocationSeg setTitle:NSLocalizedStringFromTable(@"公司_seg", appDelegate.LocalizedTable, nil) forSegmentAtIndex:1];
    [BackToHotVBtn setTitle:NSLocalizedStringFromTable(@"快選", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    BackToHotVBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    [SearchToHotVBtn setTitle:NSLocalizedStringFromTable(@"搜尋", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    
}
- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    
    if(ArrivalUpdataT != nil)
    {
        [ArrivalUpdataT cancel];
    }
    if (appDelegate.requestManager.delegate == self)
    {
        appDelegate.requestManager.delegate = nil;
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
-(IBAction) SetBtnClickEvent:(id)sender
{
    if([LeftMenuBtn isSelected])
    {
        [SilderMenu SilderHidden];
    }

    
    [SaveSetBtn setEnabled:NO];
    LocationSeg.selectedSegmentIndex = 0;
    [self LocationSegSelectedEvent:LocationSeg];
    
    [self ShowSetV];
    
}
-(IBAction) SwitchBtnClickEvent:(id)sender
{
    RoutePlanKind tmp = StartPlanKind;
    LandMark * tmplm = StartLm;
    NSString * tmpstr = [StartLandmarkTf text];
    
    StartPlanKind = EndPlanKind;
    StartLm = EndLm;
    [StartLandmarkTf setText:[EndLandmarkTf text]];
    
    EndPlanKind = tmp;
    EndLm = tmplm;
    [EndLandmarkTf setText:tmpstr];
}
-(IBAction) QueryBtnClickEvent:(id)sender
{
    NSMutableString * AlertSb= [[NSMutableString alloc] init];
    if(StartPlanKind == Void)
    {
        [AlertSb appendString:NSLocalizedStringFromTable(@"起點尚未設定\n",appDelegate.LocalizedTable,nil)];
    }
    if(EndPlanKind == Void)
    {
        [AlertSb appendString:NSLocalizedStringFromTable(@"訖點尚未設定\n",appDelegate.LocalizedTable,nil)];
    }
    [locmanager startUpdatingLocation];
    if([locmanager location] != nil)
    {
        nowLocation = [[locmanager location] copy];
    }
    [locmanager stopUpdatingLocation];
    if((StartPlanKind == NowLocation || EndPlanKind == NowLocation) && nowLocation == nil)
    {
        [AlertSb appendString:NSLocalizedStringFromTable(@"請先啟用GPS功能",appDelegate.LocalizedTable,nil)];
    }
    if([AlertSb length] > 0)
    {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:AlertSb delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確定",appDelegate.LocalizedTable,nil) otherButtonTitles:nil, nil];
        [alert show];
        
        return;
    }
    
    TableDataKind = RoutePlanTableKindPlanResults;
    SelectedIndexPath = nil;

    
    [self actFadeInView:self.viewTimeMenu];
//    [ListTv reloadData];
//    [ListTv setAlpha:1.0f];
//    [EmptyLbl setAlpha:0.0f];
//    [self ShowListV];
    
    
    
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

-(IBAction) BackToHotVBtnClickEvent:(id)sender
{
    if(HotV.frame.origin.x != 0)
    {
//        [self ShowEmptyLbl:@""];
        [EmptyLbl setAlpha:0.0f];
        [self ShowHotV];
        if(ArrivalUpdataT != nil)
        {
            ArrivalUpdataT  = [[NSThread alloc] initWithTarget:self selector:@selector(UpdataArrivalWork) object:nil];
            [ArrivalUpdataT cancel];
        }
    }
    
}
-(IBAction) ShowSearchVBtnClickEvent:(id)sender
{
    [self ShowSearchV];
}
-(IBAction) HomeBtnClickEvent:(id)sender
{
    NSMutableString * ErrorSb = [[NSMutableString alloc] init];
    if(HomeLm == nil)
    {
        [ErrorSb appendString:NSLocalizedStringFromTable(@"尚未設定家的位置\n",appDelegate.LocalizedTable,nil)];
    }
    if (nowLocation == nil)
    {
        [ErrorSb appendString:NSLocalizedStringFromTable(@"請先開啟GPS功能\n",appDelegate.LocalizedTable,nil)];
    }
    if([ErrorSb length] > 0)
    {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"錯誤",appDelegate.LocalizedTable,nil) message:ErrorSb delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確定",appDelegate.LocalizedTable,nil) otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    [locmanager startUpdatingLocation];
    if([locmanager location] != nil)
    {
        nowLocation = [[locmanager location] copy];
    }
    [locmanager stopUpdatingLocation];
    

    [StartLandmarkTf setBackgroundColor:[UIColor clearColor]];
    [EndLandmarkTf setBackgroundColor:[UIColor clearColor]];
    EditLandmarkTfKind = -1;
    StartPlanKind = NowLocation;
    EndPlanKind = Home;
    [StartLandmarkTf setText:NSLocalizedStringFromTable(@"目前位置",appDelegate.LocalizedTable,nil)];
    [EndLandmarkTf setText:NSLocalizedStringFromTable(@"家",appDelegate.LocalizedTable,nil)];
    
    if(HotV.frame.origin.x != 0)
    {
        [self ShowHotV];
    }
    
}
-(IBAction) CompanyBtnClickEvent:(id)sender
{
    NSMutableString * ErrorSb = [[NSMutableString alloc] init];
    if(CompanyLm == nil)
    {
        [ErrorSb appendString:NSLocalizedStringFromTable(@"尚未設定公司的位置\n",appDelegate.LocalizedTable,nil)];
    }
    if (nowLocation == nil)
    {
        [ErrorSb appendString:NSLocalizedStringFromTable(@"請先開啟GPS功能\n",appDelegate.LocalizedTable,nil)];
    }
    if([ErrorSb length] > 0)
    {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"錯誤",appDelegate.LocalizedTable,nil) message:ErrorSb delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確定",appDelegate.LocalizedTable,nil) otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    [locmanager startUpdatingLocation];
    if([locmanager location] != nil)
    {
        nowLocation = [[locmanager location] copy];
    }
    [locmanager stopUpdatingLocation];
    
    [StartLandmarkTf setBackgroundColor:[UIColor clearColor]];
    [EndLandmarkTf setBackgroundColor:[UIColor clearColor]];
    EditLandmarkTfKind = -1;
    StartPlanKind = NowLocation;
    EndPlanKind = Company;
    [StartLandmarkTf setText:NSLocalizedStringFromTable(@"目前位置",appDelegate.LocalizedTable,nil)];
    [EndLandmarkTf setText:NSLocalizedStringFromTable(@"公司",appDelegate.LocalizedTable,nil)];
    if(HotV.frame.origin.x != 0)
    {
        [self ShowHotV];
    }
    
}
-(IBAction) HotLandmarkBtnClickEvent:(id)sender
{
    [StartLandmarkTf resignFirstResponder];
    [EndLandmarkTf resignFirstResponder];
    TableDataKind = RoutePlanTableKindHotSpots;
    
    [ListTv setAlpha:1.0];
    [ListTv setHidden:NO];
//    [self ShowEmptyLbl:@""];

    if(ListV.frame.origin.x != 0)
    {
        [self ShowListV];
        [self ShowListTv];
    }

    [ListTv reloadData];

}
-(IBAction) CollectBtnClickEvent:(id)sender
{
    TableDataKind = RoutePlanTableKindCollections;
    CollectLms = [AttractionManager ReadStoreLandmark];
    if([CollectLms count] == 0)
    {
        [ListTv setAlpha:0.0];
//        [EmptyLbl setAlpha:1.0f];
        [ListTv setHidden:YES];
//        [EmptyLbl setHidden:NO];
        [self ShowEmptyLbl:NSLocalizedStringFromTable(@"先請加入地標",appDelegate.LocalizedTable,nil)];
    }
    else
    {
        [ListTv setAlpha:1.0];
        [EmptyLbl setAlpha:0.0f];
        [ListTv setHidden:NO];
//        [EmptyLbl setHidden:YES];
        [ListTv reloadData];
    }
    [self ShowListV];
}
-(IBAction) NowLocationBtnClickEvent:(id)sender
{
//    if(EditLandmarkTfKind == -1)
//    {
//        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:@"請先選擇起點或迄點" delegate:nil cancelButtonTitle:@"確定" otherButtonTitles:nil, nil];
//        [alert show];
//    }
//    else if(EditLandmarkTfKind == 1)
//    {
        [StartLandmarkTf setText:NSLocalizedStringFromTable(@"目前位置",appDelegate.LocalizedTable,nil)];
        [StartLandmarkTf setBackgroundColor:[UIColor clearColor]];
        StartPlanKind = NowLocation;
        EditLandmarkTfKind = -1;
//    }
//    else if(EditLandmarkTfKind == 2)
//    {
//        [EndLandmarkTf setText:@"目前位置"];
//        [EndLandmarkTf setBackgroundColor:[UIColor clearColor]];
//        EndPlanKind = NowLocation;
//        EditLandmarkTfKind = -1;
//    }
}

-(IBAction) SetToStartBtnClickEvent:(id)sender
{
    EditLandmarkTfKind = -1;
    StartPlanKind = SelectedLandmark;
    StartLm = SelectedLm;
    [StartLandmarkTf setText:SelectedLm.Name];
    [StartLandmarkTf setBackgroundColor:[UIColor clearColor]];
    
    [hud hide:YES];
    [hud removeFromSuperview];
    [self.view removeGestureRecognizer:OutSideTapRecognizer];
    [self HiddenSearchVBtnClick:nil];

}
-(IBAction) SetToEndBtnClickEvent:(id)sender
{
    EditLandmarkTfKind = -1;
    EndPlanKind = SelectedLandmark;
    EndLm = SelectedLm;
    [EndLandmarkTf setText:SelectedLm.Name];
    [EndLandmarkTf setBackgroundColor:[UIColor clearColor]];
    
    
    [hud hide:YES];
    [hud removeFromSuperview];
    [self.view removeGestureRecognizer:OutSideTapRecognizer];
    [self HiddenSearchVBtnClick:nil];

}
-(IBAction) AddToCollectBtnClickEvent:(id)sender
{
    AttractionResult result = [AttractionManager AddStoreLandmarkByName:SelectedLm.Name Address:SelectedLm.Address Lon:SelectedLm.Lon Lat:SelectedLm.Lat];
    
    NSString * ErrMessage = nil;
    
    if(result == AttractionSuccess)
    {
        ErrMessage = NSLocalizedStringFromTable(@"加入成功",appDelegate.LocalizedTable,nil);
    }
    else if(result == AttractionFail)
    {
        ErrMessage = NSLocalizedStringFromTable(@"加入失敗，請重新再試!",appDelegate.LocalizedTable,nil);
    }
    else if(result == AttractionHased)
    {
        ErrMessage = NSLocalizedStringFromTable(@"已經加入到收藏過了",appDelegate.LocalizedTable,nil);
    }
    
    if(ErrMessage != nil)
    {
        UIAlertView * Alert = [[UIAlertView alloc] initWithTitle:nil message:ErrMessage delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確定",appDelegate.LocalizedTable,nil) otherButtonTitles:nil, nil];
        [Alert show];
    }
    
    [hud hide:YES];
    [hud removeFromSuperview];
    [self.view removeGestureRecognizer:OutSideTapRecognizer];
}

-(IBAction) HiddenSearchVBtnClick:(id)sender
{
    [SearchTf resignFirstResponder];
    [self HiddenSearchV];
}
-(IBAction) HiddenKeyboardBtnClick:(id)sender
{
    [SearchTf resignFirstResponder];
    [AddressTf resignFirstResponder];
    
}
-(IBAction) SaveLocationSetBtnClick:(id)sender
{
    [AddressTf resignFirstResponder];
    [self HiddenSetV];
    NSUserDefaults  * userDefault = [NSUserDefaults standardUserDefaults];
    if(HomeLm != nil)
    {
        if(HomeLm.Address != nil)
        {
            [userDefault removeObjectForKey:@"HomeAddress"];
            [userDefault setObject:HomeLm.Address forKey:@"HomeAddress"];
        }
        else
        {
            [userDefault removeObjectForKey:@"HomeAddress"];
        }
        [userDefault removeObjectForKey:@"HomeLon"];
        [userDefault setObject:[NSNumber numberWithFloat:HomeLm.Lon] forKey:@"HomeLon"];
        [userDefault removeObjectForKey:@"HomeLat"];
        [userDefault setObject:[NSNumber numberWithFloat:HomeLm.Lat] forKey:@"HomeLat"];
    }
    if(CompanyLm != nil)
    {
        if(CompanyLm.Address != nil)
        {
            [userDefault removeObjectForKey:@"CompanyAddress"];
            [userDefault setObject:CompanyLm.Address forKey:@"CompanyAddress"];
        }
        else
        {
            [userDefault removeObjectForKey:@"CompanyAddress"];
        }
        [userDefault removeObjectForKey:@"CompanyLon"];
        [userDefault setObject:[NSNumber numberWithFloat:HomeLm.Lon] forKey:@"CompanyLon"];
        [userDefault removeObjectForKey:@"CompanyLat"];
        [userDefault setObject:[NSNumber numberWithFloat:HomeLm.Lat] forKey:@"CompanyLat"];
    }
    [userDefault synchronize];
    
    
    
}
-(IBAction) LocationSegSelectedEvent:(id)sender
{
    LandMark * Lm;
    if(LocationSeg.selectedSegmentIndex == 0)
    {
        //家
        Lm = HomeLm;
    }
    else
    {
        //公司
        Lm = CompanyLm;
    }
    [LocationMapV setShowsUserLocation:NO];
    [LocationMapV removeAnnotations:LocationMapV.annotations];
    [LocationMapV setShowsUserLocation:YES];
    if(Lm != nil)
    {
        [LocationMapV addAnnotation:Lm];
    }
    
    if(Lm == nil || Lm.Address == nil)
    {
        [AddressTf setText:@""];
    }
    else
    {
        [AddressTf setText:Lm.Address];
    }
    
    
}
-(IBAction) HiddenSetVBtnClick:(id)sender
{
    [AddressTf resignFirstResponder];
    [self HiddenSetV];
}
#pragma 其它事件
- (void) TapOutSide :(UITapGestureRecognizer *) sender
{
    [hud hide:YES];
    [hud removeFromSuperview];
    [self.view removeGestureRecognizer:OutSideTapRecognizer];
}


#pragma mark 讀取設定
-(void) ReadHomeCompanySetting
{
    NSUserDefaults  * userDefault = [NSUserDefaults standardUserDefaults];
    if([userDefault objectForKey:@"HomeAddress"] != nil)
    {
        if(HomeLm == nil)
        {
            HomeLm = [[LandMark alloc] init];
        }
        HomeLm.Name = NSLocalizedStringFromTable(@"家",appDelegate.LocalizedTable,nil);
        HomeLm.Address = [userDefault objectForKey:@"HomeAddress"];
        HomeLm.Lon = [userDefault floatForKey:@"HomeLon"];
        HomeLm.Lat = [userDefault floatForKey:@"HomeLat"];
    }
    else
    {
        HomeLm = nil;
    }
    if([userDefault objectForKey:@"CompanyAddress"] != nil)
    {
        if(CompanyLm == nil)
        {
            CompanyLm = [[LandMark alloc] init];
        }
        CompanyLm.Name = NSLocalizedStringFromTable(@"公司",appDelegate.LocalizedTable,nil);
        CompanyLm.Address = [userDefault objectForKey:@"CompanyAddress"];
        CompanyLm.Lon = [userDefault floatForKey:@"CompanyLon"];
        CompanyLm.Lat = [userDefault floatForKey:@"CompLat"];
    }
    else
    {
        CompanyLm = nil;
    }
    
}
#pragma mark 切換視圖
- (void) ShowHotV;
{
    [StartLandmarkTf resignFirstResponder];
    [EndLandmarkTf resignFirstResponder];
    if([[NSThread currentThread] isMainThread])
    {
        CGRect HotVframe = HotV.frame;
        CGRect ListVframe = ListV.frame;

        HotVframe.origin.x = 0;
        ListVframe.origin.x = ListVframe.size.width;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.6];
        [UIView setAnimationDelegate:self];
        [HotV setFrame:HotVframe];
        [ListV setFrame:ListVframe];
        [BackToHotVBtn setAlpha:0.0f];
        [UIView commitAnimations];
        [SilderMenu removeItem:LeftMenu_BackBtn];
    }
    else
    {
        [self performSelectorOnMainThread:@selector(ShowHotV) withObject:nil waitUntilDone:YES];
        return;
    }
}
- (void) ShowListV
{
    if([[NSThread currentThread] isMainThread])
    {
        CGRect HotVframe = HotV.frame;
        CGRect ListVframe = ListV.frame;
        
        HotVframe.origin.x = -1* HotVframe.size.width;
        ListVframe.origin.x = 0;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.6];
        [UIView setAnimationDelegate:self];
        [HotV setFrame:HotVframe];
        [ListV setFrame:ListVframe];
        [BackToHotVBtn setAlpha:1.0f];
        [UIView commitAnimations];
        
        [SilderMenu insertItem:LeftMenu_BackBtn];
    }
    else
    {
        [self performSelectorOnMainThread:@selector(ShowListV) withObject:nil waitUntilDone:YES];
        return;
    }
}
- (void) ShowListTv
{
    if([[NSThread currentThread] isMainThread])
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.6];
        [UIView setAnimationDelegate:self];
        [ListTv setAlpha:1.0f];
        [EmptyLbl setAlpha:0.0f];
        [UIView commitAnimations];
        
    }
    else
    {
        [self performSelectorOnMainThread:@selector(ShowListTv) withObject:nil waitUntilDone:YES];
        return;
    }
}
- (void) ShowEmptyLbl:(NSString *)EmptyStr
{
    if([[NSThread currentThread] isMainThread])
    {
        [EmptyLbl setText:EmptyStr];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:1.2];
        [UIView setAnimationDelegate:self];
        [ListTv setAlpha:0.0f];
        [EmptyLbl setAlpha:1.0f];
        [UIView commitAnimations];
    }
    else
    {
        [self performSelectorOnMainThread:@selector(ShowEmptyLbl:) withObject:EmptyStr waitUntilDone:YES];
        return;
    }
}
- (void) ShowSearchTv
{
    if([[NSThread currentThread] isMainThread])
    {
        if(SearchTv.alpha != 0)
        {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.6];
            [UIView setAnimationDelegate:self];
            [SearchTv setAlpha:1.0f];
            [SearchEmptyLbl setAlpha:0.0f];
            [UIView commitAnimations];
        }
        
    }
    else
    {
        [self performSelectorOnMainThread:@selector(ShowSearchTv) withObject:nil waitUntilDone:YES];
        return;
    }
}
- (void) ShowSearchEmptyLbl
{
    if([[NSThread currentThread] isMainThread])
    {
        if(SearchEmptyLbl.alpha != 0)
        {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.6];
            [UIView setAnimationDelegate:self];
            [SearchTv setAlpha:0.0f];
            [SearchEmptyLbl setAlpha:1.0f];
            [UIView commitAnimations];
        }
        
    }
    else
    {
        [self performSelectorOnMainThread:@selector(ShowSearchEmptyLbl) withObject:nil waitUntilDone:YES];
        return;
    }
}
- (void) ShowSearchV
{
    if([[NSThread currentThread] isMainThread])
    {
        CGRect frame = SearchV.frame;
        frame.origin.y = 0;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.6];
        [UIView setAnimationDelegate:self];
        [SearchV setFrame:frame];
        [UIView commitAnimations];
    }
    else
    {
        [self performSelectorOnMainThread:@selector(ShowSearchV) withObject:nil waitUntilDone:YES];
        return;
    }
}
- (void) HiddenSearchV
{
    if([[NSThread currentThread] isMainThread])
    {
        CGRect frame =self.view.frame;
        CGRect Searchframe = SearchV.frame;
        Searchframe.origin.y = frame.size.height;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.6];
        [UIView setAnimationDelegate:self];
        [SearchV setFrame:Searchframe];
        [UIView commitAnimations];
        
    }
    else
    {
        [self performSelectorOnMainThread:@selector(HiddenSearchV) withObject:nil waitUntilDone:YES];
        return;
    }
}
- (void) ShowSetV
{
    if([[NSThread currentThread] isMainThread])
    {
        CGRect frame = SetV.frame;
        frame.origin.y = 0;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.6];
        [UIView setAnimationDelegate:self];
        [SetV setFrame:frame];
        [UIView commitAnimations];
        
    }
    else
    {
        [self performSelectorOnMainThread:@selector(ShowSetV) withObject:nil waitUntilDone:YES];
        return;
    }
}
- (void) HiddenSetV
{
    if([[NSThread currentThread] isMainThread])
    {
        CGRect frame =self.view.frame;
        CGRect Setframe = SetV.frame;
        Setframe.origin.y = frame.size.height;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.6];
        [UIView setAnimationDelegate:self];
        [SetV setFrame:Setframe];
        [UIView commitAnimations];
        
    }
    else
    {
        [self performSelectorOnMainThread:@selector(HiddenSetV) withObject:nil waitUntilDone:YES];
        return;
    }
}
#pragma mark 搜尋工作
-(void)actSendKeyWordSearchRequest
{
    NSString * stringKeyword = SearchTf.text;
    if (stringKeyword.length>0)
    {
//        appDelegate.requestManager.delegate = self;
        [appDelegate.requestManager addRequestWithKey:@"RoutePlanKeyword" andUrl:[NSString stringWithFormat:APISearchKeyWord,stringKeyword] byType:RequestDataTypeJson];
    }
}
- (void) SearchWork
{
//    [SearchLms removeAllObjects];
//    [self performSelectorOnMainThread:@selector(ReloadListTv) withObject:nil waitUntilDone:YES];
    
//    for(int i=0;i<10;i++)
//    {
//        if([[NSThread currentThread] isCancelled])
//        {
//            break;
//        }
//        LandMark * oneLm = [[LandMark alloc] init];
//        oneLm.Name = [NSString stringWithFormat:@"搜尋結果%d",i+1];
//        [SearchLms addObject:oneLm];
//        [self performSelectorOnMainThread:@selector(InsertNewResultRow:) withObject:[NSIndexPath indexPathForRow:i inSection:0] waitUntilDone:YES];
//    }
    
    NSString * KeyWord = SearchTf.text;
    [SearchLms removeAllObjects];
    
    SearchLms = [AttractionManager SearchLandMark:KeyWord];
    [self performSelectorOnMainThread:@selector(ReloadListTv) withObject:nil waitUntilDone:YES];
    if([SearchLms count] == 0)
    {
        [self ShowSearchEmptyLbl];
    }
}
- (void) ReloadListTv
{
    [SearchTv reloadData];
}
- (void) InsertNewSearchResultRow: (id) insertPath
{
    [self ShowSearchTv];
    if([insertPath class] == [NSIndexPath class])
    {
        if(((NSIndexPath *)insertPath).row < [SearchLms count])
        {
            [SearchTv insertRowsAtIndexPaths:[NSArray arrayWithObject:insertPath] withRowAnimation:UITableViewRowAnimationTop];
        }
    }
    else if([insertPath class] == [NSArray class])
    {
        NSMutableArray * newSearchArray = [[NSMutableArray alloc] init];
        for(NSIndexPath * onepath in ((NSArray *)insertPath))
        {
            if(onepath.row < [SearchLms count])
            {
                [newSearchArray addObject:onepath];
            }
        }
        
        
        [SearchTv insertRowsAtIndexPaths:newSearchArray withRowAnimation:UITableViewRowAnimationTop];
    }
}
#pragma mark 更新到站時間
- (void) UpdataArrivalWork
{
    while (![[NSThread currentThread] isCancelled])
    {
        if(PlanResults != nil && [PlanResults count] > 0)
        {
            for(PlanScheme * onePlan in PlanResults)
            {

                for (int i= 0; i < 2 && i < [onePlan.Trips count]; i++)
                {
                    Trip * oneTrip = (Trip *)[onePlan.Trips objectAtIndex:i];
                    if(oneTrip.TripKind == ByBus)
                    {
                        [self SendArrivalRequestbyRouteId:oneTrip.RouteId StopId:oneTrip.FromStopId GoBack:oneTrip.FromStopGoBack Type:oneTrip.RouteKind];
                        
                        break;
                    }
                }
                
            }
        }
        [NSThread sleepForTimeInterval:UpdateTime];
    }
}
#pragma mark 更新位置

#pragma mark - Location Manager
//  */
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if(locations != nil && [locations count] > 0)
    {
        nowLocation = [[locations objectAtIndex:0] copy];
    }
    [locmanager stopUpdatingLocation];
    
}
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSString * stringAlertTitle = nil;
    NSString * stringAlertMessage = nil;
    NSString * stringAlertCancelButton = NSLocalizedString(@"OK",@"OK");
    NSString * stringAlertOtherButton = nil;
    if([error code] == kCLErrorDenied)
    {
        stringAlertTitle = NSLocalizedStringFromTable(@"需使用GPS裝置",appDelegate.LocalizedTable,nil);
        stringAlertMessage = NSLocalizedStringFromTable(@"若欲使用完整功能, 請允許使用GPS",appDelegate.LocalizedTable,nil);
    }
    else
    {
        stringAlertTitle = NSLocalizedStringFromTable(@"GPS更新失敗",appDelegate.LocalizedTable,nil);
        stringAlertMessage = NSLocalizedStringFromTable(@"無法接收到GPS訊號",appDelegate.LocalizedTable,nil);
    }
    UIAlertView * alert = [[UIAlertView alloc]initWithTitle:stringAlertTitle
                                         message:stringAlertMessage
                                        delegate:nil
                               cancelButtonTitle:stringAlertCancelButton
                               otherButtonTitles:stringAlertOtherButton, nil];
    [alert show];
    NSLog(@"GPS Error Code %d",[error code]);
    NSLog(@"%@",[error localizedDescription]);
}

#pragma mark UITextFieldDelegate
- (void)textfieldDidChange:(UITextField*)textField
{
    if (textField == SearchTf)
    {
        if (textField.text.length > 0)
        {
//            [self actSearchKeyWords];
            [self actSendKeyWordSearchRequest];
        }
        else
        {
            if (SearchLms.count>0)
            {
                [SearchLms removeAllObjects];
                [SearchTv reloadData];
            }
        }
    }
}

//-(void) textfieldDidChange:(UITextField *)textField
//{

//    NSString * Text = textField.text;
//    if(textField == StartLandmarkTf)
//    {
//        EditLandmarkTfKind = 1;
//    }
//    else
//    {
//        EditLandmarkTfKind = 2;
//    }
//    if([Text length] == 0 && HotV.frame.origin.x != 0)
//    {
//        [self ShowHotV];
//    }
//    
//    if([Text length] > 0 && ListV.frame.origin.x != 0)
//    {
//        [self ShowListV];
//    }

//}
- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    if(textField == StartLandmarkTf || textField == EndLandmarkTf)
    {
        [textField resignFirstResponder];
        if(textField == StartLandmarkTf)
        {
            EditLandmarkTfKind = 1;
            [StartLandmarkTf setBackgroundColor:[UIColor lightGrayColor]];
            [EndLandmarkTf setBackgroundColor:[UIColor clearColor]];
        }
        else
        {
            EditLandmarkTfKind = 2;
            [StartLandmarkTf setBackgroundColor:[UIColor clearColor]];
            [EndLandmarkTf setBackgroundColor:[UIColor lightGrayColor]];
        }
        if (HotV.frame.origin.x == 0)
        {
            [self ShowSearchV];
        }
    }
}
//-(void) textFieldDidEndEditing:(UITextField *)textField
//{
//    if(textField == SearchTf)
//        [self actSendKeyWordSearchRequest];
//}
- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
     NSString * Text = textField.text;
    if([Text length] > 0)
    {
        if(textField == SearchTf)
        {
//            [self planSearch];
        }
        else
        {
            [self SendSearchRequest:Text];
        }
    }
    return YES;
}
//-(void)actSearchKeyWords
//{
//    if(SearchT != nil)
//    {
//        [SearchT cancel];
//        [SearchLms removeAllObjects];
//        [SearchTv reloadData];
//    }
////            SearchT = [[NSThread alloc] initWithTarget:self selector:@selector(SearchWork) object:nil];
//    SearchT = [[NSThread alloc] initWithTarget:self selector:@selector(actSendKeyWordSearchRequest) object:nil];
//    [SearchT start];
//}
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
    else if([SelectedItem compare:@"language"] == 0)
    {
        [appdelegate SwitchViewer:11];
    }
    else if([SelectedItem compare:@"back"] == 0)
    {
        //返回快選
        [self BackToHotVBtnClickEvent:BackToHotVBtn];
        [SilderMenu SilderHidden];
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
//    float Height = 44.0;
//    FavoritData * oneFav = [FavoritesDatas objectAtIndex:[indexPath row]];
//    CGSize maxStopSize = CGSizeMake(100,42);
//    CGSize StopSize = [oneFav.StopName sizeWithFont:[UIFont systemFontOfSize:14.0f] constrainedToSize:maxStopSize lineBreakMode:UILineBreakModeClip];
//    return Height;
    if(tableView == ListTv)
    {
        
        if(TableDataKind == RoutePlanTableKindLandmarks || TableDataKind == RoutePlanTableKindHotSpots || TableDataKind == RoutePlanTableKindCollections)
        {
            return 22.0f;
        }
        else if(TableDataKind == 3)
        {
            PlanScheme * oneScheme = [PlanResults objectAtIndex:indexPath.row];
            float Height = 44.0f;
            if(oneScheme.SchemeKind == FootDirect)
            {
                return Height;
            }
            else
            {
                NSMutableString * RouteSb = [[NSMutableString alloc] init];
                NSMutableString * DestinationSb = [[NSMutableString alloc] init];
                
                for(int i=0;i < [oneScheme.Trips count];i++)
                {
                    Trip * onetrip = [oneScheme.Trips objectAtIndex:i];
                    if(onetrip.TripKind == ByBus)
                    {
                        if([RouteSb length] > 0)
                        {
                            [RouteSb appendString:@"\n"];
                        }
                        [RouteSb appendString:onetrip.RouteName];
                        
                        if([DestinationSb length] > 0)
                        {
                            [DestinationSb appendString:@"\n"];
                        }
                        [DestinationSb appendString:onetrip.Destination != nil ? onetrip.Destination:@"" ];
                        
                    }
                }
                CGSize RouteSize = [RouteSb sizeWithFont:[UIFont systemFontOfSize:17.0f] constrainedToSize:CellRouteMaxSize lineBreakMode:NSLineBreakByWordWrapping];
                CGSize DescSize = [DestinationSb sizeWithFont:[UIFont systemFontOfSize:16.0f] constrainedToSize:CellDescMaxSize lineBreakMode:NSLineBreakByWordWrapping];
                if(MAX(RouteSize.height, DescSize.height)  > (Height - 23))
                {
                    Height = MAX(RouteSize.height, DescSize.height) + 23.0f;
                }
                
            }
            if(SelectedIndexPath != nil && SelectedIndexPath.row == indexPath.row)
            {
                Height += [schemeview CalculateSumHeight];
            }
            return Height;
        }
    }
    else if(tableView == SearchTv)
    {
        
        return 22.0f;
        
    }
    return 22.0f;
    
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView == ListTv)
    {
        if(TableDataKind == RoutePlanTableKindLandmarks)
        {
            //搜尋結果
            return [SearchLms count];
        }
        else if(TableDataKind == RoutePlanTableKindHotSpots)
        {
            //熱門
            return [HotLms count];
        }
        else if(TableDataKind == RoutePlanTableKindCollections)
        {
            //收藏
            return [CollectLms count];
        }
        else if(TableDataKind == RoutePlanTableKindPlanResults)
        {
            return [PlanResults count];
        }
        
    }
    else if(tableView == SearchTv)
    {
        //搜尋結果
        return [SearchLms count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView == ListTv)//規劃結果
    {
        if(TableDataKind == RoutePlanTableKindLandmarks || TableDataKind == RoutePlanTableKindHotSpots || TableDataKind == RoutePlanTableKindCollections)
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"defaultcell"];
            if(cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"defaultcell"] ;
            }
            LandMark * onelm = nil;
            if(TableDataKind == RoutePlanTableKindLandmarks)
            {
                onelm = [SearchLms objectAtIndex:[indexPath row]];
            }
            else if(TableDataKind == RoutePlanTableKindHotSpots)
            {
                onelm = [HotLms objectAtIndex:[indexPath row]];
            }
            else if(TableDataKind == RoutePlanTableKindCollections)
            {
                onelm = [CollectLms objectAtIndex:[indexPath row]];
            }
            [cell.textLabel setText:onelm.Name];
            [cell.textLabel setAdjustsFontSizeToFitWidth:YES];
            
            return cell;
        }
        else if(TableDataKind == RoutePlanTableKindPlanResults)//未展開的Cell
        {
            
            PlanResultCell * cell = (PlanResultCell *)[tableView dequeueReusableCellWithIdentifier:@"PlanResultCell"];
            if(cell == nil)
            {
                NSArray *nib=[[NSBundle mainBundle]loadNibNamed:@"PlanResultCell" owner:self options:nil];
                cell = (PlanResultCell *)[nib objectAtIndex:0];
            }
            PlanScheme * oneScheme = [PlanResults objectAtIndex:[indexPath row]];
            [cell.SchemeLbl setText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"方案 %ld",appDelegate.LocalizedTable,nil),(long)[indexPath row]+1]];
            int hour = oneScheme.SumTravelMins / 60;
            int min = oneScheme.SumTravelMins % 60;
            NSMutableString * SumTravelSb = [[NSMutableString alloc] initWithString:NSLocalizedStringFromTable(@"總旅行時間：",appDelegate.LocalizedTable,nil)];
            if(hour > 0)
            {
                [SumTravelSb appendFormat:NSLocalizedStringFromTable(@"%d小時",appDelegate.LocalizedTable,nil),hour];
            }
            if(min > 0)
            {
                [SumTravelSb appendFormat:NSLocalizedStringFromTable(@"%d分鍾",appDelegate.LocalizedTable,nil),min];
            }
            if(hour > 0 || min >0)
            {
                [cell.SumTravelTimeLbl setText:SumTravelSb];
            }
            else
            {
                [cell.SumTravelTimeLbl setText:@""];
            }
            if(oneScheme.Arrival2 != nil && [oneScheme.Arrival2 compare:@"null"] != 0)
            {
                NSRange range = [oneScheme.Arrival2 rangeOfString:@":"];
                if(range.length > 0)
                {
                    [cell.ArrivalLbl setText:oneScheme.Arrival2];
                }
                else
                {
                    [cell.ArrivalLbl setText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"%@分",appDelegate.LocalizedTable,nil),oneScheme.Arrival2]];
                }
            }
            else
            {
                [cell.ArrivalLbl setText:NSLocalizedStringFromTable(@"未發車",appDelegate.LocalizedTable,nil)];
            }
            
            
            
            //cell 路線名稱
            if(oneScheme.SchemeKind == FootDirect)
            {
                [cell.RouteLbl setText:NSLocalizedStringFromTable(@"步行直達",appDelegate.LocalizedTable,nil)];
                [cell.DescLbl setText:@""];
            }
            else if(oneScheme.SchemeKind == OneStepBus)
            {
                Trip * bustrip = nil;
                for(int i=0;i<[oneScheme.Trips count];i++)
                {
                    Trip * oneTrip = [oneScheme.Trips objectAtIndex:i];
                    if(oneTrip.TripKind == ByBus)
                    {
                        bustrip = oneTrip;
                        break;
                    }
                }
                if(bustrip != nil)
                {
                    [cell.RouteLbl setText:bustrip.RouteName];
                    [cell.DescLbl setText:bustrip.Destination != nil ? bustrip.Destination:@""];
                    
                }
                else
                {
                    [cell.RouteLbl setText:@""];
                    [cell.DescLbl setText:@""];
                }
            }
            else
                if(oneScheme.SchemeKind == TwoStepBus)
                {
                    Trip * firsttrip = nil,* secondtrip = nil;
                    for(int i=0;i<[oneScheme.Trips count];i++)
                    {
                        Trip * oneTrip = [oneScheme.Trips objectAtIndex:i];
                        if(oneTrip.TripKind == ByBus)
                        {
                            if(firsttrip == nil)
                            {
                                firsttrip = oneTrip;
                            }
                            else
                            {
                                secondtrip = oneTrip;
                                break;
                            }
                        }
                    }
                    if(firsttrip != nil && secondtrip != nil)
                    {
                        [cell.RouteLbl setText:[NSString stringWithFormat:@"%@\n%@",firsttrip.RouteName,secondtrip.RouteName]];
                        [cell.DescLbl setText:[NSString stringWithFormat:@"%@\n%@"
                                               ,firsttrip.Destination != nil ? firsttrip.Destination : @""
                                               ,secondtrip.Destination != nil ? secondtrip.Destination : @"" ]];
                        
                    }
                    else
                    {
                        [cell.RouteLbl setText:@""];
                        [cell.DescLbl setText:@""];
                    }
            }
            else if(oneScheme.SchemeKind == OneStepTrain)
            {
                Trip * trainTrip = nil;
                for(int i=0;i<[oneScheme.Trips count];i++)
                {
                    Trip * oneTrip = [oneScheme.Trips objectAtIndex:i];
                    if(oneTrip.TripKind == ByTrain)
                    {
                        trainTrip = oneTrip;
                        break;
                    }
                }
                if(trainTrip != nil)
                {
                    [cell.RouteLbl setText:trainTrip.RouteName];
                    [cell.DescLbl setText:[NSString stringWithFormat:@"%@-%@",trainTrip.FromStop,trainTrip.ToStop]];
                    [cell.ArrivalLbl setText:@"--"];
                }
                else
                {
                    [cell.RouteLbl setText:@""];
                    [cell.DescLbl setText:@""];
                }
            }
            
            CGRect cellframe = cell.frame;
            CGRect Routeframe = cell.RouteLbl.frame;
            CGRect Descframe = cell.DescLbl.frame;
            
            if (routhPlanTimeType != RoutePlanTimeTypeNoTime)
            {
                [cell.ArrivalLbl setText:@"--"];
            }
            
            
            if(SelectedIndexPath != nil && SelectedIndexPath.row == indexPath.row)
            {
                [cell.TitleBgIv setImage:[UIImage imageNamed:@"routeplan_titlebg2.png"]];
                float RowHeight = [self tableView:tableView heightForRowAtIndexPath:indexPath];
                float DescHeight = [schemeview CalculateSumHeight];
                cellframe.size.height = RowHeight;
                RowHeight -= DescHeight;
                Routeframe.size.height = RowHeight - 23;
                Descframe.size.height = RowHeight - 23;
                CGRect Descframe = schemeview.frame;
                Descframe.origin.y = RowHeight;
                Descframe.size.height = DescHeight;
                [schemeview setFrame:Descframe];
                
                [schemeview removeFromSuperview];
                [cell.contentView addSubview:schemeview];
                
            }
            else
            {
                [cell.TitleBgIv setImage:[UIImage imageNamed:@"routeplan_titlebg1.png"]];
                float RowHeight = [self tableView:tableView heightForRowAtIndexPath:indexPath];
                Routeframe.size.height = RowHeight - 23;
                Descframe.size.height = RowHeight - 23;
                cellframe.size.height = RowHeight;
            }
            
            [cell setFrame:cellframe];
            [cell.RouteLbl setFrame:Routeframe];
            [cell.DescLbl setFrame:Descframe];
            
            return cell;
        }
    }
    else if(tableView == SearchTv)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"defaultcell"];
        if(cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"defaultcell"] ;
        }
        LandMark * onelm = nil;
        
        onelm = [SearchLms objectAtIndex:[indexPath row]];
        
        [cell.textLabel setText:onelm.Name];
        
        return cell;
    }
    
    
    return nil;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(tableView == ListTv)
    {
        
        if(TableDataKind == RoutePlanTableKindLandmarks  )
        {
            SelectedIndexPath = indexPath;
            SelectedLm = [SearchLms objectAtIndex:[indexPath row]];
            
            if(hud == nil)
            {
                
                hud = [[MBProgressHUD alloc] initWithView:self.view];
                
                hud.labelText = nil;
                hud.detailsLabelText = nil;
                
            }
            hud.mode = MBProgressHUDModeCustomView;
            hud.customView = LandmarkSubV;
            [self.view addGestureRecognizer:OutSideTapRecognizer];
            [self.view addSubview:hud];
            [hud show:YES];
            
        }
        else if(TableDataKind == RoutePlanTableKindHotSpots)
        {
            SelectedIndexPath = indexPath;
//            if(EditLandmarkTfKind == -1)
//            {
//                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:@"請先選擇起點或迄點" delegate:nil cancelButtonTitle:@"確定" otherButtonTitles:nil, nil];
//                [alert show];
//                return;
//            }

            SelectedLm = [HotLms objectAtIndex:[indexPath row]];
            if(hud == nil)
            {
                
                hud = [[MBProgressHUD alloc] initWithView:self.view];
                hud.labelText = nil;
                hud.detailsLabelText = nil;
            }
            hud.mode = MBProgressHUDModeCustomView;
            if(EditLandmarkTfKind == 1)
            {
                hud.customView = LandmarkSubV1;
            }
            else if(EditLandmarkTfKind == 2)
            {
                hud.customView = LandmarkSubV2;
            }
            else
            {
                hud.customView = LandmarkSubV;
            }
            [self.view addGestureRecognizer:OutSideTapRecognizer];
            [self.view addSubview:hud];
            [hud show:YES];
        }
        else if(TableDataKind == RoutePlanTableKindCollections)
        {
            SelectedIndexPath = indexPath;
            LandMark * oneLm = [CollectLms objectAtIndex:[indexPath row]];
            if(EditLandmarkTfKind == -1)
            {
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"請先選擇起點或訖點",appDelegate.LocalizedTable,nil) delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確定",appDelegate.LocalizedTable,nil) otherButtonTitles:nil, nil];
                [alert show];
                return;
            }
            else if(EditLandmarkTfKind == 1)
            {
                StartPlanKind = SelectedLandmark;
                StartLm = oneLm;
                
                [StartLandmarkTf setText:oneLm.Name];
                [StartLandmarkTf setBackgroundColor:[UIColor clearColor]];
                StartPlanKind = SelectedLandmark;
                EditLandmarkTfKind = -1;
            }
            else if(EditLandmarkTfKind == 2)
            {
                EndPlanKind = SelectedLandmark;
                EndLm = oneLm;
                
                [EndLandmarkTf setText:oneLm.Name];
                [EndLandmarkTf setBackgroundColor:[UIColor clearColor]];
                EndPlanKind = SelectedLandmark;
                EditLandmarkTfKind = -1;
                
            }
        }
        else if(TableDataKind == RoutePlanTableKindPlanResults)
        {
            if(SelectedIndexPath == nil || SelectedIndexPath.row != indexPath.row)
            {
                SelectedIndexPath = indexPath;
                PlanScheme * oneScheme = [PlanResults objectAtIndex:[indexPath row]];
                if(schemeview == nil)
                {
                    schemeview = [[PlanSchemeView alloc] init];
                }
                else
                {
                    [schemeview removeFromSuperview];
                }
                [schemeview SetSchemeSource:oneScheme];
                [ListTv reloadData];
            }
            else
            {
                SelectedIndexPath = nil;
                [schemeview removeFromSuperview];
                [ListTv reloadData];
            }
        }
    }
    else if(tableView == SearchTv)
    {
        SelectedIndexPath = indexPath;
        SelectedLm = [SearchLms objectAtIndex:[indexPath row]];
        
        if(hud == nil)
        {
            hud = [[MBProgressHUD alloc] initWithView:self.view];
            hud.labelText = nil;
            hud.detailsLabelText = nil;
        }
        hud.mode = MBProgressHUDModeCustomView;
        hud.customView = LandmarkSubV;
        [self.view addGestureRecognizer:OutSideTapRecognizer];
        [self.view addSubview:hud];
        [hud show:YES];
    }
}

#pragma mark ASIHTTP
- (void) SendSearchRequest:(NSString *)SearchValue
{
    if(![ShareTools connectedToNetwork])
    {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"請先開啟網路或網路狀態不穩",appDelegate.LocalizedTable,nil) delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確定",appDelegate.LocalizedTable,nil) otherButtonTitles:nil, nil];
        [alert show];
    }
    
    if(SearchValue == nil || [SearchValue length] == 0 )
    {
        return;
    }
    if(hud == nil)
    {
        
        hud = [[MBProgressHUD alloc] initWithView:self.view];
        hud.labelText = nil;
        hud.detailsLabelText = nil;
    }
    hud.mode = MBProgressHUDModeIndeterminate;
    [self.view addSubview:hud];
    [hud show:YES];

    NSString * urlstr = [[NSString alloc] initWithFormat:SearchAddressAPI,SearchValue];
    
    NSURL * url = [NSURL URLWithString:[urlstr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//    NSLog(@"Search Address Url:%@",url);
    
    ASIHTTPRequest * SearchRequest = [ASIHTTPRequest requestWithURL:url];
    [SearchRequest setDelegate:self];
    [SearchRequest setDidFinishSelector:@selector(SearchRequestFinish:)];
    [SearchRequest startAsynchronous];
}
- (void) SendRoutePlanRequestByMode:(NSString*)stringMode onDate:(NSString*)stringDay atTime:(NSString *)stringTime
{
    if(![ShareTools connectedToNetwork])
    {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"請先開啟網路或網路狀態不穩",appDelegate.LocalizedTable,nil) delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確定",appDelegate.LocalizedTable,nil) otherButtonTitles:nil, nil];
        [alert show];
    }
    if(hud == nil)
    {
        hud = [[MBProgressHUD alloc] initWithView:self.view];
        hud.labelText = nil;
        hud.detailsLabelText = nil;
    }
    hud.mode = MBProgressHUDModeIndeterminate;
    [self.view addSubview:hud];
    [hud show:YES];
    float slon=0.0f,slat = 0.0f,elon= 0.0f,elat = 0.0f;
    NSString * sname = StartLandmarkTf.text ,* ename = EndLandmarkTf.text,* stype = @"UserPick",* etype = @"UserPick";
    if(StartPlanKind == NowLocation)
    {
        slon = nowLocation.coordinate.longitude;
        slat = nowLocation.coordinate.latitude;
    }
    else if(StartPlanKind == Home)
    {
        slon = HomeLm.Lon;
        slat = HomeLm.Lat;
    }
    else if(StartPlanKind == Company)
    {
        slon = CompanyLm.Lon;
        slat = CompanyLm.Lat;
    }
    else
    {
        slon = StartLm.Lon;
        slat = StartLm.Lat;
        stype = @"LandMark";
    }
    if(EndPlanKind == NowLocation)
    {
        elon = nowLocation.coordinate.longitude;
        elat = nowLocation.coordinate.latitude;
    }
    else if(EndPlanKind == Home)
    {
        elon = HomeLm.Lon;
        elat = HomeLm.Lat;
    }
    else if(EndPlanKind == Company)
    {
        elon = CompanyLm.Lon;
        elat = CompanyLm.Lat;
    }
    else
    {
        elon = EndLm.Lon;
        elat = EndLm.Lat;
        etype = @"LandMark";
    }
    
    
    NSString * urlstr = [[NSString alloc] initWithFormat:RoutePlanAPI,slon,slat,elon,elat,stringDay,stringTime,@"cht",stringMode,sname,ename,stype,etype];
    
    NSURL * url = [NSURL URLWithString:[urlstr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
#ifdef LogOut
    NSLog(@"RoutePlan Address Url:%@",url);
#endif
    
    ASIHTTPRequest * RoutePlanRequest = [ASIHTTPRequest requestWithURL:url];
    [RoutePlanRequest setDelegate:self];
    [RoutePlanRequest setDidFinishSelector:@selector(RoutePlanRequestFinish:)];
    [RoutePlanRequest setDidFailSelector:@selector(RoutePlanRequestFail:)];
    [RoutePlanRequest startAsynchronous];
}
- (void) SendArrivalRequestbyRouteId:(NSString *)Route StopId:(NSString *)Stop GoBack:(int)GoBack Type:(int)Type
{
    if(![ShareTools connectedToNetwork])
    {
        return;
    }
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:NewFavoriteAPI,Route,Stop,GoBack,Type]];
    NSLog(@"Url:%@",url);
    ASIHTTPRequest * Request = [[ASIHTTPRequest alloc] initWithURL:url];
    [Request setTimeOutSeconds:30.0];
    [Request setDelegate:self];
    [Request setDidFinishSelector:@selector(ArrivalRequestFinish:)];
    [Request startAsynchronous];
}


- (void) SearchRequestFinish:(ASIHTTPRequest *)request
{
    @try {
        NSData * content = [request responseData];
//        NSLog(@"Response:%@",[request responseString]);
        
        JSONDecoder * Parser = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
        NSDictionary * dict = [Parser objectWithData:content];
        NSArray * results = (NSArray *)[dict objectForKey:@"results"];
        

        if([results count] > 0)
        {
            
            NSDictionary * firstresult = [results objectAtIndex:0];
            NSString * fulladdress = [firstresult objectForKey:@"formatted_address"];
            NSDictionary * geo = (NSDictionary *)[firstresult objectForKey:@"geometry"];
            NSDictionary * viewport = (NSDictionary *)[geo objectForKey:@"viewport"];
            NSDictionary * ne = (NSDictionary *)[viewport objectForKey:@"northeast"];
            NSDictionary * sw = (NSDictionary *)[viewport objectForKey:@"southwest"];
            
            NSDictionary * slocation = [geo objectForKey:@"location"];
            
            NSNumber * lat = [slocation valueForKey:@"lat"];
            NSNumber * lon = [slocation valueForKey:@"lng"];
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake([lat floatValue], [lon floatValue]);
            
            [LocationMapV setShowsUserLocation:NO];
            [LocationMapV removeAnnotations:LocationMapV.annotations];
            [LocationMapV setShowsUserLocation:YES];
            if(LocationSeg.selectedSegmentIndex == 0)
            {
                if(HomeLm == nil)
                {
                    HomeLm = [[LandMark alloc] init];
                    HomeLm.Name = NSLocalizedStringFromTable(@"家",appDelegate.LocalizedTable,nil);
                    HomeLm.title = NSLocalizedStringFromTable(@"家",appDelegate.LocalizedTable,nil);
                }
                HomeLm.coordinate = location;
                HomeLm.Lat = location.latitude;
                HomeLm.Lon = location.longitude;
                HomeLm.Address = fulladdress;
                [LocationMapV addAnnotation:HomeLm];
            }
            else if(LocationSeg.selectedSegmentIndex == 1)
            {
                if(CompanyLm == nil)
                {
                    CompanyLm = [[LandMark alloc] init];
                    CompanyLm.Name = NSLocalizedStringFromTable(@"公司",appDelegate.LocalizedTable,nil);
                    CompanyLm.title= NSLocalizedStringFromTable(@"公司",appDelegate.LocalizedTable,nil);
                }
                CompanyLm.coordinate = location;
                CompanyLm.Lat = location.latitude;
                CompanyLm.Lon = location.longitude;
                CompanyLm.Address = fulladdress;
                [LocationMapV addAnnotation:CompanyLm];
            }
            [AddressTf setText:fulladdress];
            CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake([[sw objectForKey:@"lat"] floatValue], [[sw objectForKey:@"lng"] floatValue])
                ,northEast = CLLocationCoordinate2DMake([[ne objectForKey:@"lat"] floatValue], [[ne objectForKey:@"lng"] floatValue]);
            MKMapPoint pSW = MKMapPointForCoordinate(southWest)
            ,pNE = MKMapPointForCoordinate(northEast);
            double antimeridianOverflow = (northEast.longitude > southWest.longitude) ? 0 : MKMapSizeWorld.width;
            
            MKMapRect rect = MKMapRectMake(pSW.x, pNE.y, (pNE.x - pSW.x) + antimeridianOverflow, pSW.y-pNE.y);
            
            [LocationMapV setVisibleMapRect:rect animated:YES];
            
            
            [SaveSetBtn setEnabled:YES];

        }
        else
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"搜尋失敗",appDelegate.LocalizedTable,nil)
                                                                message:NSLocalizedStringFromTable(@"無法搜尋到相關地點，請輸入其它關鍵字",appDelegate.LocalizedTable,nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedStringFromTable(@"OK",appDelegate.LocalizedTable,@"OK")
                                                      otherButtonTitles:nil];
            [alertView show];
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
    @finally {
        
    }
    [hud hide:YES];
    [hud removeFromSuperview];
    
}
-(void) RoutePlanRequestFinish:(ASIHTTPRequest *)Request
{
#ifdef LogOut
    NSString * Response = [Request responseString];
    NSLog(@"Response:%@",Response);
#endif
    if(PlanResults == nil)
    {
        PlanResults = [[NSMutableArray alloc] init];
    }
    else
    {
        [PlanResults removeAllObjects];
    }
    float slon=0.0f,slat = 0.0f,elon= 0.0f,elat = 0.0f;
    NSString * sname = StartLandmarkTf.text ,* ename = EndLandmarkTf.text;
    if(StartPlanKind == NowLocation)
    {
        slon = nowLocation.coordinate.longitude;
        slat = nowLocation.coordinate.latitude;
    }
    else if(StartPlanKind == Home)
    {
        slon = HomeLm.Lon;
        slat = HomeLm.Lat;
    }
    else if(StartPlanKind == Company)
    {
        slon = CompanyLm.Lon;
        slat = CompanyLm.Lat;
    }
    else
    {
        slon = StartLm.Lon;
        slat = StartLm.Lat;
    }
    if(EndPlanKind == NowLocation)
    {
        elon = nowLocation.coordinate.longitude;
        elat = nowLocation.coordinate.latitude;
    }
    else if(EndPlanKind == Home)
    {
        elon = HomeLm.Lon;
        elat = HomeLm.Lat;
    }
    else if(EndPlanKind == Company)
    {
        elon = CompanyLm.Lon;
        elat = CompanyLm.Lat;
    }
    else
    {
        elon = EndLm.Lon;
        elat = EndLm.Lat;
    }
    /*
    @try {
        NSData * content = [Request responseData];

        
        JSONDecoder * Parser = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
        NSArray * Infos = [Parser objectWithData:content];
        if([Infos count] > 0)
        {
            for(NSDictionary * oneInfo in Infos)
            {
                int P1Provider = [[oneInfo objectForKey:@"P1Provider"] isKindOfClass:[NSNull class]] ? -1 : [[oneInfo objectForKey:@"P1Provider"] intValue];
                int P2Provider = [[oneInfo objectForKey:@"P2Provider"] isKindOfClass:[NSNull class]]  ? -1 : [[oneInfo objectForKey:@"P2Provider"] intValue];
                PlanScheme * newScheme = [[PlanScheme alloc] init];
                Trip * oneTrip;
                if([[oneInfo objectForKey:@"SName"] isKindOfClass:[NSNull class]])
                {
                    //沒有起站，步行可達
                    newScheme.SchemeKind = FootDirect;
                }
                else if([[oneInfo objectForKey:@"MSName"] isKindOfClass:[NSNull class]])
                {
                    //單程
                    if(P1Provider == 0 || P1Provider == 2)
                    {
                        //公車客運直達
                        newScheme.SchemeKind = OneStepBus;
                    }
                    else
                    {
                        //火車直達
                        newScheme.SchemeKind = OneStepTrain;
                    }
                    
                }
                else
                {
                    //轉程
                    if((P1Provider == 0 || P1Provider == 2) && (P2Provider == 0 || P2Provider == 2))
                    {
                        //公車轉公車
                        newScheme.SchemeKind = TwoStepBus;
                    }
                    else if((P1Provider == 0 || P1Provider == 2) && P2Provider == 1)
                    {
                        //公車轉火車
                        newScheme.SchemeKind = BusToTrain;
                    }
                    else
                    {
                        //火車轉公車
                        newScheme.SchemeKind = TrainToBus;
                    }
                }
                newScheme.SumTravelMins = [[oneInfo objectForKey:@"TravelTime"] intValue];
                if([[oneInfo objectForKey:@"SDist"] intValue] > 5)
                {
                    oneTrip = [[Trip alloc] init];
                    oneTrip.TripKind = Foot;
                    oneTrip.StopName = [StartLandmarkTf.text copy];
                    oneTrip.FootDistance = [[oneInfo objectForKey:@"SDist"] intValue];
//                    footTrip.ArrivalStopId = [oneInfo objectForKey:@"SID"];
//                    footTrip.ArrivalStopName = [oneInfo objectForKey:@"SName"];
                    [newScheme.Trips addObject:oneTrip];
                }
                if(![[oneInfo objectForKey:@"SName"] isKindOfClass:[NSNull class]])
                {
                    oneTrip = [[Trip alloc] init];
                    if(P1Provider == 0)
                    {
                        oneTrip.TripKind = ByBus;
                        oneTrip.RouteKind = 1;
                    }
                    else if(P1Provider == 1)
                    {
                        oneTrip.TripKind = ByTrain;
                    }
                    else if(P1Provider == 2)
                    {
                        oneTrip.TripKind = ByBus;
                        oneTrip.RouteKind = 2;
                    }
                    oneTrip.GoBack = [[oneInfo objectForKey:@"P1GoBack"] intValue];
                    oneTrip.TravelStopCount = [[oneInfo objectForKey:@"P1Num"] intValue];
                    oneTrip.StopId = [[oneInfo objectForKey:@"SID"] copy];
                    oneTrip.StopName = [[oneInfo objectForKey:@"SName"] copy];
                    oneTrip.Lon = [[oneInfo objectForKey:@"SLon"] isKindOfClass:[NSNull class]] ? 0.0f : [[oneInfo objectForKey:@"SLon"] floatValue];
                    oneTrip.Lat = [[oneInfo objectForKey:@"SLat"] isKindOfClass:[NSNull class]] ? 0.0f : [[oneInfo objectForKey:@"SLat"] floatValue];
                    oneTrip.RouteName = [[oneInfo objectForKey:@"P1Route"] copy];
                    newScheme.Arrival2 = [[oneInfo objectForKey:@"P1ATime"] copy];
                    if(![[oneInfo objectForKey:@"MSID"] isKindOfClass:[NSNull class]] )
                    {
                        oneTrip.ArrivalStopId = [[oneInfo objectForKey:@"MSID"] copy];
                        oneTrip.ArrivalStopName = [[oneInfo objectForKey:@"MSName"] copy];
                        oneTrip.ArrivalLon = [[oneInfo objectForKey:@"MSLon"] isKindOfClass:[NSNull class]] ? 0.0f : [[oneInfo objectForKey:@"MSLon"] floatValue];
                        oneTrip.ArrivalLat = [[oneInfo objectForKey:@"MSLat"] isKindOfClass:[NSNull class]] ? 0.0f : [[oneInfo objectForKey:@"MSLat"] floatValue];
                    }
                    else
                    {
                        oneTrip.ArrivalStopId = [[oneInfo objectForKey:@"EID"] copy];
                        oneTrip.ArrivalStopName = [[oneInfo objectForKey:@"EName"] copy];
                        oneTrip.ArrivalLon =  [[oneInfo objectForKey:@"ELon"] isKindOfClass:[NSNull class]] ? 0.0f : [[oneInfo objectForKey:@"ELon"] floatValue];
                        oneTrip.ArrivalLat = [[oneInfo objectForKey:@"ELat"] isKindOfClass:[NSNull class]] ? 0.0f : [[oneInfo objectForKey:@"ELat"] floatValue];
                    }
                    [newScheme.Trips addObject:oneTrip];
                }
                if([[oneInfo objectForKey:@"MDist"] intValue] > 5)
                {
                    oneTrip = [[Trip alloc] init];
                    oneTrip.TripKind = Foot;
                    oneTrip.FootDistance = [[oneInfo objectForKey:@"MDist"] intValue];
                    oneTrip.StopName = [[oneInfo objectForKey:@"MSName"] copy];
                    [newScheme.Trips addObject:oneTrip];
                }
                
                if (![[oneInfo objectForKey:@"MEID"] isKindOfClass:[NSNull class]])
                {
                    oneTrip = [[Trip alloc] init];
                    oneTrip.StopId =[[oneInfo objectForKey:@"MEID"] copy];
                    oneTrip.StopName =[[oneInfo objectForKey:@"MEName"] copy];
                    oneTrip.RouteName = [[oneInfo objectForKey:@"P2Route"] copy];
                    oneTrip.Lon = [[oneInfo objectForKey:@"MELon"] isKindOfClass:[NSNull class]] ? 0.0f : [[oneInfo objectForKey:@"MELon"] floatValue];
                    oneTrip.Lat =  [[oneInfo objectForKey:@"MELat"] isKindOfClass:[NSNull class]] ? 0.0f : [[oneInfo objectForKey:@"MELat"] floatValue];
                    oneTrip.GoBack = [[oneInfo objectForKey:@"P2GoBack"] intValue];
                    if(P2Provider == 0)
                    {
                        oneTrip.RouteKind = 1;
                        oneTrip.TripKind = ByBus;
                    }
                    else if(P2Provider == 1)
                    {
                        oneTrip.TripKind = ByTrain;
                    }
                    else if(P2Provider == 2)
                    {
                        oneTrip.RouteKind = 2;
                        oneTrip.TripKind = ByBus;
                    }
                    oneTrip.ArrivalStopId = [[oneInfo objectForKey:@"EID"] copy];
                    oneTrip.ArrivalStopName = [[oneInfo objectForKey:@"EName"] copy];
                    oneTrip.ArrivalLon =  [[oneInfo objectForKey:@"ELon"] isKindOfClass:[NSNull class]] ? 0.0f : [[oneInfo objectForKey:@"ELon"] floatValue];
                    oneTrip.ArrivalLat =  [[oneInfo objectForKey:@"ELat"] isKindOfClass:[NSNull class]] ? 0.0f : [[oneInfo objectForKey:@"ELat"] floatValue];
                    oneTrip.TravelStopCount = [[oneInfo objectForKey:@"P2Num"] isKindOfClass:[NSNull class]] ? 0 : [[oneInfo objectForKey:@"P2Num"] intValue];
                    [newScheme.Trips addObject:oneTrip];
                }
                if([[oneInfo objectForKey:@"EDist"] intValue] > 5)
                {
                    oneTrip = [[Trip alloc] init];
                    oneTrip.TripKind = Foot;
                    oneTrip.FootDistance = [[oneInfo objectForKey:@"EDist"] isKindOfClass:[NSNull class]] ? 0 : [[oneInfo objectForKey:@"EDist"] intValue];
                    oneTrip.StopName = [[oneInfo objectForKey:@"EName"] copy];
                    
                    [newScheme.Trips addObject:oneTrip];
                }
                oneTrip = [[Trip alloc] init];
                oneTrip.TripKind = EPoint;
                oneTrip.StopName = [EndLandmarkTf.text copy];
                [newScheme.Trips addObject:oneTrip];
                [PlanResults addObject:newScheme];
                if([PlanResults count] >= 6)
                {
                    break;
                }
            }

        }
        else
        {
            
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
    @finally {
        
    }*/
    @try {
        NSData * content = [Request responseData];
        
        JSONDecoder * Parser = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
        NSArray * Infos = [Parser objectWithData:content];

            for(NSDictionary * oneInfo in Infos)
            {
                if([oneInfo objectForKey:@"SEgeomWalk"] != nil)
                {}
                else
                {
                    int take1 = -1,take2 = -1;
                    if([(NSString *) [oneInfo objectForKey:@"take1"] length] > 0)
                    {
                        take1 = [(NSString *) [oneInfo objectForKey:@"take1"] intValue];
                    }
                    if([(NSString *) [oneInfo objectForKey:@"take2"] length] > 0)
                    {
                        take2 = [(NSString *) [oneInfo objectForKey:@"take2"] intValue];
                    }
                    PlanScheme * newScheme = [[PlanScheme alloc] init];
                    Trip * oneTrip;
                    if (take1 == -1 && take2 == -1)
                    {
                        //步行直達
                        newScheme.SchemeKind = FootDirect;
                    }
                    else if(take1 != -1 && take2 == -1)
                    {
                        if(take1 == 0 || take1 == 2)
                        {
                            //公車客運直達
                            newScheme.SchemeKind = OneStepBus;
                        }
                        else if(take1 == 1)
                        {
                            //火車直達
                            newScheme.SchemeKind = OneStepTrain;
                        }
                    }
                    else
                    {
                        if(take1 == 0 || take1 == 2)
                        {
                            if(take2 == 0 || take2 == 2)
                            {
                                //公車客運轉乘
                                newScheme.SchemeKind = TwoStepBus;
                            }
                            else
                            {
                                //公車轉乘火車
                                newScheme.SchemeKind = BusToTrain;
                            }
                        }
                        else
                        {
                            if(take2 == 0 || take2 == 2)
                            {
                                //火車轉公車
                                newScheme.SchemeKind = TrainToBus;
                            }
                            else
                            {
                                //火車轉乘
                                
                            }
                        }
                        
                    }
                    NSArray * startPoints = nil,* relay1s = nil,* relay2s = nil
                    ,* endPoints = nil,* travelStops = nil;
                    if([(NSString *)[oneInfo objectForKey:@"startPoint"] length] > 0)
                    {
                        startPoints =[(NSString *)[oneInfo objectForKey:@"startPoint"] componentsSeparatedByString:@"_,"];
                    }
                    if([(NSString *)[oneInfo objectForKey:@"relay1"] length] > 0)
                    {
                        relay1s =[(NSString *)[oneInfo objectForKey:@"relay1"] componentsSeparatedByString:@"_,"];
                    }
                    if([(NSString *)[oneInfo objectForKey:@"relay2"] length] > 0)
                    {
                        relay2s =[(NSString *)[oneInfo objectForKey:@"relay2"] componentsSeparatedByString:@"_,"];
                    }
                    if([(NSString *)[oneInfo objectForKey:@"endPoint"] length] > 0)
                    {
                        endPoints =[(NSString *)[oneInfo objectForKey:@"endPoint"] componentsSeparatedByString:@"_,"];
                    }
                    if([(NSString *)[oneInfo objectForKey:@"travelStop"] length] > 0)
                    {
                        travelStops =[(NSString *)[oneInfo objectForKey:@"travelStop"] componentsSeparatedByString:@"_,"];
                    }
                    else if([(NSString *)[oneInfo objectForKey:@"travelStop1"] length] > 0)
                    {
                        travelStops =[(NSString *)[oneInfo objectForKey:@"travelStop1"] componentsSeparatedByString:@"_,"];
                    }
                    
                    
                    newScheme.SumTravelMins = [[oneInfo objectForKey:@"travelTime"] intValue];
                    if([(NSString *)[oneInfo objectForKey:@"walk1"] length]> 0)
                    {
                        oneTrip = [[Trip alloc] init];
                        oneTrip.TripKind = Foot;
                        NSMutableString * DescSb = [[NSMutableString alloc] initWithString:[oneInfo objectForKey:@"walk1"]];
                        NSRange range = [DescSb rangeOfString:@"{from}"];
                        [DescSb deleteCharactersInRange:range];
                        [DescSb insertString:sname atIndex:range.location];
                        range = [DescSb rangeOfString:@"{start}"];
                        [DescSb deleteCharactersInRange:range];
                        [DescSb insertString:[startPoints objectAtIndex:0] atIndex:range.location];
                        oneTrip.FromStop = sname;
                        oneTrip.FromLon = slon;
                        oneTrip.FromLat = slat;
                        oneTrip.ToStop = [startPoints objectAtIndex:0];
                        oneTrip.ToLon = [[startPoints objectAtIndex:1] floatValue];
                        oneTrip.ToLat = [[startPoints objectAtIndex:2] floatValue];
                        oneTrip.Desc = [NSString stringWithString:DescSb];
                        [newScheme.Trips addObject:oneTrip];
                    }
                    if([(NSString *)[oneInfo objectForKey:@"route"] length]> 0
                       || [(NSString *)[oneInfo objectForKey:@"route1"] length]> 0)
                    {
                        oneTrip = [[Trip alloc] init];
                        if(take1 == 0)
                        {
                            oneTrip.TripKind = ByBus;
                            oneTrip.RouteKind = 0;
                        }
                        else if(take1 == 2)
                        {
                            oneTrip.TripKind = ByBus;
                            oneTrip.RouteKind = 1;
                        }
                        else if(take1 ==1)
                        {
                            oneTrip.TripKind = ByTrain;
                            oneTrip.RouteKind = -1;
                        }
                        
                        NSMutableString * DescSb = nil;
                        if([(NSString *)[oneInfo objectForKey:@"route"] length]> 0)
                        {
                            DescSb = [[NSMutableString alloc] initWithString:(NSString *)[oneInfo objectForKey:@"route"]];
                        }
                        else
                        {
                            DescSb = [[NSMutableString alloc] initWithString:(NSString *)[oneInfo objectForKey:@"route1"]];
                        }
                        
                        NSArray * RouteInfoValues = nil;
                        if([(NSString *)[oneInfo objectForKey:@"travelPath"] length] > 0)
                        {
                            RouteInfoValues = [(NSString *)[oneInfo objectForKey:@"travelPath"] componentsSeparatedByString:@"_,"];
                        }
                        else if([(NSString *)[oneInfo objectForKey:@"travelPath1"] length] > 0)
                        {
                            RouteInfoValues = [(NSString *)[oneInfo objectForKey:@"travelPath1"] componentsSeparatedByString:@"_,"];
                        }
                        
                        if(RouteInfoValues != nil)
                        {
                            oneTrip.RouteId = [RouteInfoValues objectAtIndex:1];
                        }
                        
                        
                        NSRange RouteS = [DescSb rangeOfString:@"("],RouteE = [DescSb rangeOfString:@")"];
                        oneTrip.RouteName = [DescSb substringWithRange:NSMakeRange(RouteS.location+1,RouteE.location - RouteS.location-1) ];
                        
                        NSArray * RouteSearchResult = [DataManager selectRouteDataKeyWord:oneTrip.RouteName byColumnTitle:RouteDataColumnTypeRouteName fromTableType:oneTrip.RouteKind == 0? RouteDataTypeCityRoutes : RouteDataTypeHighwayRoutes ];
                        
                        if(RouteSearchResult != nil && [RouteSearchResult count] > 0)
                        {
                            NSDictionary * oneRoute = [RouteSearchResult objectAtIndex:0];
                            [oneTrip setDestination:[NSString stringWithFormat:@"%@-%@",[oneRoute objectForKey:@"departureZh"],[oneRoute objectForKey:@"destinationZh"] ]];
                        }
                        
                        NSRange range = [DescSb rangeOfString:@"{start}"];
                        [DescSb deleteCharactersInRange:range];
                        [DescSb insertString:[startPoints objectAtIndex:0] atIndex:range.location];
                        range = [DescSb rangeOfString:@"{relay1}"];
                        if(range.location != NSNotFound)
                        {
                            [DescSb deleteCharactersInRange:range];
                            [DescSb insertString:[relay1s objectAtIndex:0] atIndex:range.location];
                            oneTrip.ToStop = [relay1s objectAtIndex:0];
                            oneTrip.ToLon = [[relay1s objectAtIndex:1] floatValue] ;
                            oneTrip.ToLat = [[relay1s objectAtIndex:2] floatValue];
                        }
                        range = [DescSb rangeOfString:@"{end}"];
                        if(range.location != NSNotFound)
                        {
                            [DescSb deleteCharactersInRange:range];
                            [DescSb insertString:[endPoints objectAtIndex:0] atIndex:range.location];
                            oneTrip.ToStop = [endPoints objectAtIndex:0];
                            oneTrip.ToLon = [[endPoints objectAtIndex:1] floatValue];
                            oneTrip.ToLat = [[endPoints objectAtIndex:2] floatValue];
                        }
                        
                        
                        
                        oneTrip.FromStop = [startPoints objectAtIndex:0];
                        oneTrip.FromLon = [[startPoints objectAtIndex:1] floatValue];
                        oneTrip.FromLat = [[startPoints objectAtIndex:2] floatValue];
                        oneTrip.FromStopId = [travelStops objectAtIndex:0];
                        oneTrip.FromStopGoBack = [[travelStops objectAtIndex:1] intValue];
                        
                        oneTrip.Desc = [NSString stringWithString:DescSb];
                        [newScheme.Trips addObject:oneTrip];
                    }
                    if([(NSString *)[oneInfo objectForKey:@"walk2"] length]> 0)
                    {
                        oneTrip = [[Trip alloc] init];
                        oneTrip.TripKind = Foot;
                        NSMutableString * DescSb = [[NSMutableString alloc] initWithString:[oneInfo objectForKey:@"walk2"]];
                        NSRange range = [DescSb rangeOfString:@"{relay1}"];
                        [DescSb deleteCharactersInRange:range];
                        [DescSb insertString:sname atIndex:range.location];
                        range = [DescSb rangeOfString:@"{relay2}"];
                        [DescSb deleteCharactersInRange:range];
                        [DescSb insertString:[startPoints objectAtIndex:0] atIndex:range.location];
                        oneTrip.FromStop = [relay1s objectAtIndex:0];
                        oneTrip.FromLon = [[relay1s objectAtIndex:1] floatValue] ;
                        oneTrip.FromLat = [[relay1s objectAtIndex:2] floatValue];
                        oneTrip.ToStop = [relay2s objectAtIndex:0];
                        oneTrip.ToLon = [[relay2s objectAtIndex:1] floatValue] ;
                        oneTrip.ToLat = [[relay2s objectAtIndex:2] floatValue];
                        oneTrip.Desc = [NSString stringWithString:DescSb];
                        [newScheme.Trips addObject:oneTrip];
                    }
                    if([(NSString *)[oneInfo objectForKey:@"route2"] length]> 0)
                    {
                        oneTrip = [[Trip alloc] init];
                        if(take2 == 0)
                        {
                            oneTrip.TripKind = ByBus;
                            oneTrip.RouteKind = 0;
                        }
                        else if(take2 == 2)
                        {
                            oneTrip.TripKind = ByBus;
                            oneTrip.RouteKind = 1;
                        }
                        else if(take2 == 1)
                        {
                            oneTrip.TripKind = ByTrain;
                            oneTrip.RouteKind = -1;
                        }
                        
                        NSMutableString * DescSb = [[NSMutableString alloc] initWithString:(NSString *)[oneInfo objectForKey:@"route2"]];
                        NSRange RouteS = [DescSb rangeOfString:@"("],RouteE = [DescSb rangeOfString:@")"];
                        oneTrip.RouteName = [DescSb substringWithRange:NSMakeRange(RouteS.location+1,RouteE.location - RouteS.location-1) ];
                        
                        
                        NSArray * RouteSearchResult = [DataManager selectRouteDataKeyWord:oneTrip.RouteName byColumnTitle:RouteDataColumnTypeRouteName fromTableType:oneTrip.RouteKind == 0? RouteDataTypeCityRoutes : RouteDataTypeHighwayRoutes ];
                        
                        if(RouteSearchResult != nil && [RouteSearchResult count] > 0)
                        {
                            NSDictionary * oneRoute = [RouteSearchResult objectAtIndex:0];
                            [oneTrip setDestination:[NSString stringWithFormat:@"%@-%@",[oneRoute objectForKey:@"departureZh"],[oneRoute objectForKey:@"destinationZh"] ]];
                        }
                        
                        NSRange range = [DescSb rangeOfString:@"{relay2}"];
                        [DescSb deleteCharactersInRange:range];
                        [DescSb insertString:[relay2s objectAtIndex:0] atIndex:range.location];
                        range = [DescSb rangeOfString:@"{end}"];
                        if(range.location != NSNotFound)
                        {
                            [DescSb deleteCharactersInRange:range];
                            [DescSb insertString:[endPoints objectAtIndex:0] atIndex:range.location];
                            
                        }
                        
                        
                        oneTrip.FromStop = [relay2s objectAtIndex:0];
                        oneTrip.FromLon = [[relay2s objectAtIndex:1] floatValue];
                        oneTrip.FromLat = [[relay2s objectAtIndex:2] floatValue];
                        oneTrip.ToStop = [endPoints objectAtIndex:0];
                        oneTrip.ToLon = [[endPoints objectAtIndex:1] floatValue] ;
                        oneTrip.ToLat = [[endPoints objectAtIndex:2] floatValue];
                        
                        oneTrip.Desc = [NSString stringWithString:DescSb];
                        [newScheme.Trips addObject:oneTrip];
                    }
                    if([(NSString *)[oneInfo objectForKey:@"walk3"] length]> 0
                       || [(NSString *)[oneInfo objectForKey:@"onlyWalk"] length]> 0)
                    {
                        oneTrip = [[Trip alloc] init];
                        oneTrip.TripKind = Foot;
                        NSMutableString * DescSb = nil;
                        if([(NSString *)[oneInfo objectForKey:@"walk3"] length]> 0)
                        {
                            DescSb = [[NSMutableString alloc] initWithString:[oneInfo objectForKey:@"walk3"]];
                        }
                        else
                        {
                            DescSb = [[NSMutableString alloc] initWithString:[oneInfo objectForKey:@"onlyWalk"]];
                        }
                        NSRange range = [DescSb rangeOfString:@"{from}"];
                        if(range.location != NSNotFound)
                        {
                            [DescSb deleteCharactersInRange:range];
                            [DescSb insertString:sname atIndex:range.location];
                            oneTrip.FromStop = sname;
                            oneTrip.FromLon = slon;
                            oneTrip.FromLat = slat;
                        }
                        range = [DescSb rangeOfString:@"{end}"];
                        if(range.location != NSNotFound)
                        {
                            [DescSb deleteCharactersInRange:range];
                            [DescSb insertString:[endPoints objectAtIndex:0] atIndex:range.location];
                            oneTrip.FromStop = [endPoints objectAtIndex:0];
                            oneTrip.FromLon = [[endPoints objectAtIndex:1] floatValue];
                            oneTrip.FromLat = [[endPoints objectAtIndex:2] floatValue];
                        }
                        
                        range = [DescSb rangeOfString:@"{relay2}"];
                        if(range.location != NSNotFound)
                        {
                            [DescSb deleteCharactersInRange:range];
                            [DescSb insertString:[relay2s objectAtIndex:0] atIndex:range.location];
                            oneTrip.FromStop = [relay2s objectAtIndex:0];
                            oneTrip.FromLon = [[relay2s objectAtIndex:1] floatValue];
                            oneTrip.FromLat = [[relay2s objectAtIndex:2] floatValue];
                        }
                        
                        
                        range = [DescSb rangeOfString:@"{to}"];
                        if(range.location != NSNotFound)
                        {
                            [DescSb deleteCharactersInRange:range];
                            [DescSb insertString:ename atIndex:range.location];
                            oneTrip.ToStop = ename;
                            oneTrip.ToLon = elon;
                            oneTrip.ToLat = elat;
                        }
                        oneTrip.Desc = [NSString stringWithString:DescSb];
                        [newScheme.Trips addObject:oneTrip];
                    }
                    
                    oneTrip = [[Trip alloc] init];
                    oneTrip.TripKind = EPoint;
                    oneTrip.FromStop = ename;
                    [newScheme.Trips addObject:oneTrip];
                    
                    [PlanResults addObject:newScheme];
                }
                
                //            if([PlanResults count] >= 6)
                //            {
                //                break;
                //            }
                
            }
        }
    
    @catch (NSException *exception)
    {
        NSLog(@"%@",exception);
    }
    @finally {
        
    }
    
    if([PlanResults count] > 0)
    {
        //[ListTv reloadData];
        //[ListTv setAlpha:1.0f];
//        [ListTv reloadData];
//        [ListTv setHidden:NO];
//        [EmptyLbl setHidden:YES];
        [ListTv reloadData];
        [self ShowListTv];
        if(ArrivalUpdataT != nil)
        {
            [ArrivalUpdataT cancel];
        }
        ArrivalUpdataT = [[NSThread alloc] initWithTarget:self selector:@selector(UpdataArrivalWork) object:nil];
        [ArrivalUpdataT start];
    }
    else
    {
        [self ShowEmptyLbl:NSLocalizedStringFromTable(@"沒有相符的行程",appDelegate.LocalizedTable,nil)];
        
//        [EmptyLbl setText:@"沒有相符的行程"];
        
    }
    [self ShowListV];

    
    [hud hide:YES];
    [hud removeFromSuperview];
}
-(void) RoutePlanRequestFail:(ASIHTTPRequest *)Request
{
    [hud hide:YES];
    [hud removeFromSuperview];
}
-(void)ArrivalRequestFinish:(ASIHTTPRequest *)Request
{
    NSString * Response = [Request responseString];
    
    //    NSLog(@"Response:%@",Response);
    if([Request responseStatusCode] == 200 && ![Response hasPrefix:@"err"])
    {
        JSONDecoder * Parser = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
        NSArray * Results = [Parser objectWithData:[Request responseData]];
        for(NSDictionary * oneResult in Results)
        {
            /*
             edit Cooper 2015/07/28
             將與解讀json 有關的部份加上防呆
             */
            NSString * RouteId = [self _checkTheCorrectValue:oneResult keyValue:@"RouteID"];
            NSString * StopId = [self _checkTheCorrectValue:oneResult keyValue:@"StopID"];
            int GoBack = [[self _checkTheCorrectValue:oneResult keyValue:@"GoBack"] intValue];
            
            int ArrivalTime = [[self _checkTheCorrectValue:oneResult keyValue:@"ArrivalTime"] intValue];
            NSString * ArrivalTime2 = [self _checkTheCorrectValue:oneResult keyValue:@"ArrivalTime2"];
            
            int RouteKind = [[self _checkTheCorrectValue:oneResult keyValue:@"Type"] intValue];
            
            for(int i=0;i<[PlanResults count]; i++)
            {
                PlanScheme * oneScheme = [PlanResults objectAtIndex:i];
                for(int j=0;j<2&&j<[oneScheme.Trips count];j++)
                {
                    Trip * oneTrip = [oneScheme.Trips objectAtIndex:j];
                    if(oneTrip.TripKind == ByBus
                       && oneTrip.RouteKind == RouteKind
                       && [oneTrip.RouteId compare:RouteId] == 0
                       && [oneTrip.FromStopId compare:StopId] == 0
                       && oneTrip.FromStopGoBack == GoBack)
                    {
                        
                        oneScheme.Arrival = ArrivalTime;
                        oneScheme.Arrival2 = ArrivalTime2;
                        break;
                    }
                }
            }
        }
        [ListTv reloadData];
        
    }
}
#pragma mark - RequestManagerDelegate
-(void)requestManager:(id)requestManager returnJSONSerialization:(NSJSONSerialization *)jsonSerialization withKey:(NSString *)key
{
    if ([key isEqualToString:@"RoutePlanKeyword"])
    {
        

        NSMutableArray * arrayTmp = [NSMutableArray new];
        NSArray * arrayFronJson = (NSArray*)jsonSerialization;
        for (NSDictionary* dictionaryLandmark in arrayFronJson)
        {
            LandMark * lanmarkOne = [LandMark new];
            /*
             edit Cooper 2015/07/28 part_One
             當Type 為Crossroad 的時候Name 必須改用 「CrossStreet1與CrossStreet2」為其名稱
             而地址的部份也做個檢查以免發生crash 的問題
             補充：將與解讀json 有關的部份加上防呆
             */
            
            lanmarkOne.Name = [self _checkTheCorrectValue:dictionaryLandmark keyValue:@"Name"];
            lanmarkOne.Lat = [[self _checkTheCorrectValue:dictionaryLandmark keyValue:@"Lat"]floatValue];
            lanmarkOne.Lon = [[self _checkTheCorrectValue:dictionaryLandmark keyValue:@"Lon"]floatValue];
            lanmarkOne.Address = [self _checkTheCorrectValue:dictionaryLandmark keyValue:@"Address"];
//            lanmarkOne.Id = [dictionaryLandmark objectForKey:@"Id"];
            [arrayTmp addObject:lanmarkOne];
        }
        SearchLms = arrayTmp;
        [self performSelectorOnMainThread:@selector(ReloadListTv) withObject:nil waitUntilDone:YES];
    }
}

/*
 edit Cooper 2015/07/28 part_Two
 */
-(NSString *)_checkTheCorrectValue:(NSDictionary *)dict keyValue:(NSString *)str
{
    NSString *returnedStr;
    if([@"Name" isEqualToString:str]){
        if([dict[@"Type"] isEqualToString:@"Crossroad"]){
            returnedStr = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@與%@",appDelegate.LocalizedTable,nil),dict[@"CrossStree1"],dict[@"CroosStree2"]];
        }else{
            returnedStr = dict[str];
        }
    }else if([@"Address" isEqualToString:str]){
        returnedStr = dict[str];
    }else if([@"Lat" isEqualToString:str] || [@"Lon" isEqualToString:str]){
        returnedStr = dict[str];
        if(!returnedStr) returnedStr = @"0";
    }else {
        returnedStr = dict[str];
    }
    
    if(!returnedStr) returnedStr = @"";
        
    return returnedStr;
}
- (IBAction)actBtnTimeMenuTouchUpInside:(UIButton*)sender
{
    NSString * stringMode = @"2";
    NSString * stringDay = @"";
    NSString * stringTime = @"";
    
    routhPlanTimeType = sender.tag;
    
    switch (routhPlanTimeType)
    {
        case RoutePlanTimeTypeNow:
        {
            [self SendRoutePlanRequestByMode:stringMode onDate:stringDay atTime:stringTime];
        }
            break;
        case RoutePlanTimeTypeNoTime:
        {
            stringMode = @"5";
            [self SendRoutePlanRequestByMode:stringMode onDate:stringDay atTime:stringTime];
        }
            break;
        case RoutePlanTimeTypeSetting:
        {
            [self actFadeInView:self.viewDatePicker];
//            NSDate * dateNow = [NSDate new];
//            NSDateFormatter * formatterDay = [NSDateFormatter new];
//            NSDateFormatter * formatterTime = [NSDateFormatter new];
//            [formatterDay setDateFormat:@"yyyyMMdd"];
//            [formatterTime setDateFormat:@"HHmm"];
//            stringDay = [formatterDay stringFromDate:dateNow];
//            stringTime = [formatterTime stringFromDate:dateNow];
//            [self SendRoutePlanRequestByMode:stringMode onDate:stringDay atTime:stringTime];
            
        }
            break;
            
        default:
            break;
    }
    [self actFadeOutView:self.viewTimeMenu];
}

- (IBAction)actBtnDatePickerTouchUpInside:(id)sender
{
    NSString * stringDate = self.labelDatePickerResult.text;
    if (!stringDate || [stringDate isEqualToString:@""])
    {
        stringDate = [self actGetStringDate:[NSDate date]];
    }
    
    //刪除"/"和":"
    stringDate = [stringDate stringByReplacingOccurrencesOfString:@"/" withString:@""];
    stringDate = [stringDate stringByReplacingOccurrencesOfString:@":" withString:@""];
    
    NSArray * arrayDate = [stringDate componentsSeparatedByString:@"-"];
    [self SendRoutePlanRequestByMode:@"2" onDate:[arrayDate objectAtIndex:0] atTime:[arrayDate objectAtIndex:1]];
    [self actFadeOutView:self.viewDatePicker];
}

- (IBAction)actDatePickerDidScrolled:(id)sender
{
    self.labelDatePickerResult.text = [self actGetStringDate:self.datePicker.date];
}
-(NSString*)actGetStringDate:(NSDate*)date
{
    NSDateFormatter * formatterDate = [NSDateFormatter new];
    [formatterDate setDateFormat:@"yyyy/MM/dd-HH:mm"];
    NSString* stringDate = [formatterDate stringFromDate:date];
    return stringDate;
}
@end
