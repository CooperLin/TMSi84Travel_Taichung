//
//  PushViewer.m
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/3/4.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "PushViewer.h"

#import "DataTypes.h"
#import "PushCell.h"
#import "MBProgressHUD.h"
#import "RegexKitLite.h"
#import "AppDelegate.h"
#import "ShareTools.h"
#import "PushManager.h"
#import "DataManager+Route.h"

//#define APISelect @"/itravel/ItravelAPI/ExpoAPI/GetOrderStop.aspx?Did=%@&Phone=iPhone&City=Taichung"
#define APISelect NSLocalizedStringFromTable(@"APISelect",appDelegate.LocalizedTable,nil)

#define APIPush @"%@/itravel/ItravelAPI/ExpoAPI/UploadOrderStop.aspx?Did=%@&Phone=iPhone&city=Taichung&Action=%d&Path=%@&stop=%@&GoBack=%d&Stime=%@&Etime=%@&Btime=%d&Type=%d&IsOpen=%d&Days=%@"

@interface PushViewer ()
{
    SilderMenuView * SilderMenu;
    NSMutableArray * PushDatas;
    
    PushData * SelectedPushData;
    NSIndexPath * SelectedIndex;
    
    MBProgressHUD * HUD;
    NSArray * WeekStrs;
    
    
    int ChangedPushEnable;
    NSString * ChangedStartPushTime;
    NSString * ChangedEndPushTime;
    int ChangedArrival;
    int ChangedWeekMon;
    int ChangedWeekTue;
    int ChangedWeekWed;
    int ChangedWeekThu;
    int ChangedWeekFri;
    int ChangedWeekSat;
    int ChangedWeekSun;
    
    int SelectedSetTimeKind;
    int AlertKind;
    ASINetworkQueue * queueASIRequests;
    int intQueryFail;
    
    FavoritesManager * fm;
    /*
     edit Cooper 2015/08/28
     0807buglist 台中第二項
     把原本的砍掉，重做
     */
    UITextField *textFieldSender;
    NSInteger textField1SelectNum_group1;
//    NSDictionary * dictionaryAPI;
//    NSMutableDictionary * dictionarySelectedStop;
}
@property (nonatomic, strong) UIView *viewCover;
/*
 edit Cooper 2015/08/28
 0807buglist 台中第二項
 把原本的砍掉，重做
 */
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) UIToolbar *toolbar;
@end

@implementation PushViewer

@synthesize HeadV,LeftMenuBtn,EditBtn;
@synthesize ContentV;

@synthesize ListV, PushTv, EmptyLbl;

@synthesize PushEditV, RouteLbl, StopLbl, TripLbl, PushSwitch, PushStartTf, PushEndTf, PushArrivalTf,  PushWeek1Btn, PushWeek2Btn, PushWeek3Btn, PushWeek4Btn, PushWeek5Btn, PushWeek6Btn, PushWeek0Btn;

@synthesize boolFromBusDynamic;

#define DefaultPushStartTime @"07:00"
#define DefaultPushEndTime @"09:00"
#define DefaultPushArrivalMin 5
#define DefaultPushWeekMon 1
#define DefaultPushWeekTue 1
#define DefaultPushWeekWed 1
#define DefaultPushWeekThu 1
#define DefaultPushWeekFri 1
#define DefaultPushWeekSat 0
#define DefaultPushWeekSun 0
#define DefaultPushEnable 1

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
    
    if (self.boolFromBusDynamic)
    {
        //從動態公車進入
        [self actInitializeStopInfo];
        [ContentV addSubview:PushEditV];
    }
    else
    {
        //從到站提醒進入
        [ContentV addSubview:ListV];
        ListV.frame = ContentV.bounds;
        [ContentV addSubview:PushEditV];
        CGRect EditFrame = PushEditV.frame;
        EditFrame.origin.x = EditFrame.size.width;
        [PushEditV setFrame:EditFrame];
    }
    [self _showViewCover:NO];
    WeekStrs = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"WeekStrs" ofType:@"plist"]];

    SilderMenu = [[SilderMenuView alloc] initWithFrame:CGRectMake(0, 0, 135, self.view.frame.size.height)];
    [SilderMenu setSilderDelegate:self];
    [ContentV addSubview:SilderMenu];
    [SilderMenu setItemsByPlistName:@"LeftMenu"];
    
//    TimeSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil, nil];
    
    [self actSetASIQueue];
    
    fm = [[FavoritesManager alloc] init];
    [fm setDelegate:self];
}
/*
-(void)actGetSelectedStop
{
    AppDelegate * delegate = [[UIApplication sharedApplication]delegate];
    dictionarySelectedStop = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary*)delegate.selectedStop];
    
}*/


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

-(void)_showI18N
{
    self.EmptyLbl.text = NSLocalizedStringFromTable(@"請先從公車動態加入站牌到到站提醒", appDelegate.LocalizedTable, nil);
    self.GetStopsRemind.text = NSLocalizedStringFromTable(@"到站提醒", appDelegate.LocalizedTable, nil);
    [self.PushWeek1Btn setTitle:NSLocalizedStringFromTable(@"星期一", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    self.PushWeek1Btn.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.PushWeek2Btn setTitle:NSLocalizedStringFromTable(@"星期二", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    self.PushWeek2Btn.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.PushWeek3Btn setTitle:NSLocalizedStringFromTable(@"星期三", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    self.PushWeek3Btn.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.PushWeek4Btn setTitle:NSLocalizedStringFromTable(@"星期四", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    self.PushWeek4Btn.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.PushWeek5Btn setTitle:NSLocalizedStringFromTable(@"星期五", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    self.PushWeek5Btn.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.PushWeek6Btn setTitle:NSLocalizedStringFromTable(@"星期六", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    self.PushWeek6Btn.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.PushWeek0Btn setTitle:NSLocalizedStringFromTable(@"星期日", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    self.PushWeek0Btn.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.PushStartTf.text = NSLocalizedStringFromTable(@"上午 07:00", appDelegate.LocalizedTable, nil);
    self.PushEndTf.text = NSLocalizedStringFromTable(@"下午 07:00", appDelegate.LocalizedTable, nil);
    self.PushArrivalTf.text = NSLocalizedStringFromTable(@"下午 07:00", appDelegate.LocalizedTable, nil);
    self.RouteLbl.text = NSLocalizedStringFromTable(@"1111台北到臺中", appDelegate.LocalizedTable, nil);
    self.StopLbl.text = NSLocalizedStringFromTable(@"高鐵臺中公車站", appDelegate.LocalizedTable, nil);
    self.TripLbl.text = NSLocalizedStringFromTable(@"1111台北到臺中", appDelegate.LocalizedTable, nil);
    [self.pushOkBtn setTitle:NSLocalizedStringFromTable(@"確定", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    [self.cancelBtn setTitle:NSLocalizedStringFromTable(@"取消", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    self.LabelRoute.text = NSLocalizedStringFromTable(@"路線:", appDelegate.LocalizedTable, nil);
    self.LabelStopsName.text = NSLocalizedStringFromTable(@"站名:", appDelegate.LocalizedTable, nil);
    self.LabelForward.text = NSLocalizedStringFromTable(@"往:", appDelegate.LocalizedTable, nil);
    self.LabelSwitch.text = NSLocalizedStringFromTable(@"提醒開關:", appDelegate.LocalizedTable, nil);
    self.LabelStartRemind.text = NSLocalizedStringFromTable(@"提醒開始時間:", appDelegate.LocalizedTable, nil);
    self.LabelEndRemind.text = NSLocalizedStringFromTable(@"提醒結束時間:", appDelegate.LocalizedTable, nil);
    self.LabelRemindTime.text = NSLocalizedStringFromTable(@"提醒時間:", appDelegate.LocalizedTable, nil);
    self.LabelRemindCycle.text = NSLocalizedStringFromTable(@"設定提醒週期:", appDelegate.LocalizedTable, nil);
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _showI18N];
    if (self.boolFromBusDynamic)
    {
        //從動態公車進入
        [self actInitializeStopInfo];
    }
    else
    {
        //從到站提醒進入
        PushDatas = [FavoritesManager GetPushes];
        if(PushDatas == nil || [PushDatas count] == 0)
        {
            [EmptyLbl setHidden:NO];
            [PushTv setHidden:YES];
        }
        else
        {
            for(PushData * onePush in PushDatas)
            {
                NSArray * SearchResultRoute =
                [onePush.RouteId length] != 0 ?
                [DataManager selectRouteDataKeyWord:onePush.RouteId byColumnTitle:RouteDataColumnTypeRouteID fromTableType:onePush.RouteKind == 0? RouteDataTypeCityRoutes : RouteDataTypeHighwayRoutes ]
                :[DataManager selectRouteDataKeyWord:onePush.RouteName byColumnTitle:RouteDataColumnTypeRouteName fromTableType:onePush.RouteKind == 0? RouteDataTypeCityRoutes : RouteDataTypeHighwayRoutes];
                
                if(SearchResultRoute != nil && [SearchResultRoute count] > 0)
                {
                    NSDictionary * firstResult = [SearchResultRoute objectAtIndex:0];
                    if(onePush.GoBack == 1)
                    {
                        [onePush setDestination:[firstResult objectForKey:@"destinationZh"]];
                    }
                    else
                    {
                        [onePush setDestination:[firstResult objectForKey:@"departureZh"]];
                    }
                    
                }
            }
            
            [EmptyLbl setHidden:YES];
            [PushTv setHidden:NO];
            [PushTv reloadData];
        }
        fm.intQueryFail = 0;
        [fm SendSynchronousRequest];
    }
    /*
     edit Cooper 2015/08/28
     0807buglist 台中第二項
     把原本的砍掉，重做
     */
    self.pickerView = [[UIPickerView alloc] init];
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    self.pickerView.showsSelectionIndicator = YES;
    
    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.datePickerMode = UIDatePickerModeTime;
    
    self.toolbar = [[UIToolbar alloc] init];
    self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    self.toolbar.backgroundColor = [UIColor grayColor];
    UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBtn:)];
    UIBarButtonItem *flexibleSpaceBarButton = [[UIBarButtonItem alloc]
                                               initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                               target:nil
                                               action:nil];
    [self.toolbar setItems:[NSArray arrayWithObjects:flexibleSpaceBarButton, btn, nil]];
    self.PushStartTf.inputView = self.datePicker;
    self.PushStartTf.inputAccessoryView = self.toolbar;
    self.PushEndTf.inputView = self.datePicker;
    self.PushEndTf.inputAccessoryView = self.toolbar;
    self.PushArrivalTf.inputView = self.pickerView;
    self.PushArrivalTf.inputAccessoryView = self.toolbar;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.boolFromBusDynamic)
    {
        //從動態公車進入
    }
    else
    {
        //從到站提醒進入
        intQueryFail = 0;

    }
}
- (IBAction) LeftMenuBtnClickEvent:(id)sender
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
    UIButton * Btn = (UIButton *)sender;
    if(![Btn isSelected])
    {
        [SilderMenu SilderShow];
        [self _showViewCover:YES];
    }
    else
    {
        [SilderMenu SilderHidden];
        [self _showViewCover:NO];
    }
    [Btn setSelected:![Btn isSelected]];
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

- (IBAction) EditBtnClickEvent:(id)sender
{
    if([LeftMenuBtn isSelected])
    {
        [SilderMenu SilderHidden];
    }
    if(![EditBtn isSelected])
    {
        [PushTv setEditing:YES animated:YES];
        [PushTv setAllowsSelectionDuringEditing:NO];
        [PushTv beginUpdates];
        [PushTv setAllowsSelection:NO];
    }
    else
    {
        [PushTv endUpdates];
        [PushTv setEditing:NO animated:YES];
        [PushTv setAllowsSelection:YES];
    }
    
    [EditBtn setSelected:![EditBtn isSelected]];
}

- (IBAction) WeekBtnClickEvent:(id)sender
{
    UIButton * WeekBtn = (UIButton *)sender;
    [WeekBtn setSelected:![WeekBtn isSelected]];
    
    if(sender == PushWeek1Btn)
    {
        ChangedWeekMon = [WeekBtn isSelected] ? 1:0;
    }
    else if(sender == PushWeek2Btn)
    {
        ChangedWeekTue = [WeekBtn isSelected] ? 1:0;
    }
    else if(sender == PushWeek3Btn)
    {
        ChangedWeekWed = [WeekBtn isSelected] ? 1:0;
    }
    else if(sender == PushWeek4Btn)
    {
        ChangedWeekThu = [WeekBtn isSelected] ? 1:0;
    }
    else if(sender == PushWeek5Btn)
    {
        ChangedWeekFri = [WeekBtn isSelected] ? 1:0;
    }
    else if(sender == PushWeek6Btn)
    {
        ChangedWeekSat = [WeekBtn isSelected] ? 1:0;
    }
    else if(sender == PushWeek0Btn)
    {
        ChangedWeekSun = [WeekBtn isSelected] ? 1:0;
    }
}
- (IBAction) PushSetEnableBtnClickEvent:(id)sender
{
    if (self.boolFromBusDynamic)
    {
        intQueryFail = 0;
        [self SendQueryRequest:1];
    }
    else
    {
        BOOL isChange = NO;
        if(ChangedPushEnable != -1 && ChangedPushEnable != SelectedPushData.Enable){isChange = YES;}
        if(ChangedStartPushTime != nil && [ChangedStartPushTime compare:SelectedPushData.StartTime] != 0){isChange = YES;}
        if(ChangedEndPushTime != nil && [ChangedEndPushTime compare:SelectedPushData.Endtime] != 0){isChange = YES;}
        if(ChangedArrival != -1 && ChangedArrival != SelectedPushData.Arrival){isChange =YES;}
        if(ChangedWeekMon != -1 && ChangedWeekMon != SelectedPushData.WeekMon){isChange =YES;}
        if(ChangedWeekTue != -1 && ChangedWeekTue != SelectedPushData.WeekTue){isChange =YES;}
        if(ChangedWeekWed != -1 && ChangedWeekWed != SelectedPushData.WeekWed){isChange =YES;}
        if(ChangedWeekThu != -1 && ChangedWeekThu != SelectedPushData.WeekThu){isChange =YES;}
        if(ChangedWeekFri != -1 && ChangedWeekFri != SelectedPushData.WeekFri){isChange =YES;}
        if(ChangedWeekSat != -1 && ChangedWeekSat != SelectedPushData.WeekSat){isChange =YES;}
        if(ChangedWeekSun != -1 && ChangedWeekSun != SelectedPushData.WeekSun){isChange =YES;}
        if(isChange)
        {

            intQueryFail = 0;
            [self SendQueryRequest:2];
            //[PushTv reloadData];
        }
        else
        {
            [self HiddenPushDesc];
        }
        
    }
}
- (IBAction) PushSetCancelBtnClickEvent:(id)sender
{
    if (self.boolFromBusDynamic)
    {
        FavoriteResult Result = [FavoritesManager DeletePushsByRouteId:SelectedPushData.RouteId
                        RouteName:SelectedPushData.RouteName
                        StopId:SelectedPushData.StopId
                        StopName:SelectedPushData.StopName
                        GoBack:SelectedPushData.GoBack
                        StartTime:SelectedPushData.StartTime
                        EndTime:SelectedPushData.Endtime
                        WeekSun:SelectedPushData.WeekSun
                        WeekMon:SelectedPushData.WeekMon
                        WeekTue:SelectedPushData.WeekTue
                        WeekWed:SelectedPushData.WeekWed
                        WeekThu:SelectedPushData.WeekThu
                        WeekFri:SelectedPushData.WeekFri
                        WeekSat:SelectedPushData.WeekSat
                        RouteKind:SelectedPushData.RouteKind ];
        if(Result == fail)
        {
            NSLog(@"刪除推播失敗");
        }
        
        [self dismissViewControllerAnimated:YES completion:^{}];
    }
    else
    {
        [self HiddenPushDesc];
    }
}

- (IBAction)TextFieldDatePicker:(UITextField *)sender {
    
}

- (IBAction)TextFieldPicker:(UITextField *)sender {

}

-(void)doneBtn:(UIButton *)sender
{
    [textFieldSender resignFirstResponder];
    if(textFieldSender == self.PushArrivalTf){
        [_pickerView selectRow:textField1SelectNum_group1 inComponent:0 animated:NO];
    }else{
        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setDateFormat:@"a hh點 mm分"];
        textFieldSender.text = [NSString stringWithFormat:@"%@",[format stringFromDate:_datePicker.date]];
    }
}
- (IBAction) PushSwitchEvent:(id)sender
{
    ChangedPushEnable = [PushSwitch isOn];
}
- (void) ShowPushEdit
{
    CGRect Listframe = ListV.frame;
    CGRect Editframe = PushEditV.frame;
    Listframe.origin.x = Listframe.size.width * -1;
    Editframe.origin.x = 0;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.6];
    [UIView setAnimationDelegate:self];
    [ListV setFrame:Listframe];
    [PushEditV setFrame:Editframe];
    [EditBtn setAlpha:0.0f];
    [UIView commitAnimations];
    
}
- (void) HiddenPushDesc
{
    CGRect Listframe = ListV.frame;
    CGRect Editframe = PushEditV.frame;
    Listframe.origin.x = 0;
    Editframe.origin.x = Editframe.size.width;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.6];
    [UIView setAnimationDelegate:self];
    [ListV setFrame:Listframe];
    [PushEditV setFrame:Editframe];
    [EditBtn setAlpha:1.0f];
    [UIView commitAnimations];
    
}
-(void)actInitializeStopInfo
{
//    [self.RouteLbl setText:[dictionarySelectedStop objectForKey:@"nameZh"]];
//    [self.StopLbl setText:[dictionarySelectedStop objectForKey:@"StopName"]];
//    [self.TripLbl setText:[dictionarySelectedStop objectForKey:@"destinationZh"]];
//    [self.PushSwitch setOn:YES];
//    
//    [self.PushStartTf setText:[self GetChtTimeStr:@"07:00"]];
//    [dictionarySelectedStop setObject:@"07:00" forKey:@"PushStartTime"];
//    
//    [self.PushEndTf setText:[self GetChtTimeStr:@"09:00"]];
//    [dictionarySelectedStop setObject:@"09:00" forKey:@"PushEndTime"];
//    
//    [self.PushArrivalTf setText:@"5分"];
//    [dictionarySelectedStop setObject:@"5" forKey:@"PushShiftMinute"];
    
    NSDictionary * SelectedStop = (NSDictionary *) appDelegate.selectedStop;
    
    
    SelectedPushData = [[PushData alloc] init];
    [SelectedPushData setRouteId:[SelectedStop objectForKey:@"ID"]];
    [SelectedPushData setRouteName:[SelectedStop objectForKey:@"nameZh"]];
    [SelectedPushData setStopId:[SelectedStop objectForKey:@"StopID"]];
    [SelectedPushData setStopName:[SelectedStop objectForKey:@"StopName"]];
    [SelectedPushData setDestination:[SelectedStop objectForKey:@"destinationZh"]];
    [SelectedPushData setGoBack:[[SelectedStop objectForKey:@"GoBack"] intValue]];
    [SelectedPushData setEnable:DefaultPushEnable];
    [SelectedPushData setStartTime:DefaultPushStartTime];
    [SelectedPushData setEndtime:DefaultPushEndTime];
    [SelectedPushData setArrival:DefaultPushArrivalMin];
    [SelectedPushData setWeekSun:DefaultPushWeekSun];
    [SelectedPushData setWeekMon:DefaultPushWeekMon];
    [SelectedPushData setWeekThu:DefaultPushWeekThu];
    [SelectedPushData setWeekTue:DefaultPushWeekTue];
    [SelectedPushData setWeekWed:DefaultPushWeekWed];
    [SelectedPushData setWeekFri:DefaultPushWeekFri];
    [SelectedPushData setWeekSat:DefaultPushWeekSat];
    
    [RouteLbl setText:SelectedPushData.RouteName];
    [StopLbl setText:SelectedPushData.StopName];
    [TripLbl setText:SelectedPushData.Destination];
    [PushSwitch setOn:YES];
    [PushStartTf setText:[self GetChtTimeStr:DefaultPushStartTime]];
    [PushEndTf setText:[self GetChtTimeStr:DefaultPushEndTime]];
    [PushArrivalTf setText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"%d分",appDelegate.LocalizedTable,nil),DefaultPushArrivalMin]];
    [PushWeek0Btn setSelected:DefaultPushWeekSun == 1 ? YES:NO];
    [PushWeek1Btn setSelected:DefaultPushWeekMon == 1 ? YES:NO];
    [PushWeek2Btn setSelected:DefaultPushWeekTue == 1 ? YES:NO];
    [PushWeek3Btn setSelected:DefaultPushWeekWed == 1 ? YES:NO];
    [PushWeek4Btn setSelected:DefaultPushWeekThu == 1 ? YES:NO];
    [PushWeek5Btn setSelected:DefaultPushWeekFri == 1 ? YES:NO];
    [PushWeek6Btn setSelected:DefaultPushWeekSat == 1 ? YES:NO];
    
    
    ChangedPushEnable = -1;
    ChangedStartPushTime = nil;
    ChangedEndPushTime = nil;
    ChangedArrival = -1;
    ChangedWeekSun = -1;
    ChangedWeekMon = -1;
    ChangedWeekThu = -1;
    ChangedWeekTue = -1;
    ChangedWeekWed = -1;
    ChangedWeekFri = -1;
    ChangedWeekSat = -1;
    
    
    
    [SelectedPushData setRouteKind:[(NSString *)[SelectedStop objectForKey:@"type"] compare:@"city"] == 0?0:1];
    
    
}
- (NSString *) GetChtTimeStr:(NSString *) TimeStr
{
    NSMutableString * Sb = [[NSMutableString alloc] init];
    NSArray * ms = [TimeStr arrayOfCaptureComponentsMatchedByRegex:@"(\\d{1,2}):(\\d{1,2})"];
    if([ms count] > 0)
    {
        ms = [ms objectAtIndex:0];
        int Hour = [[ms objectAtIndex:1] intValue];
        int Min = [[ms objectAtIndex:2] intValue];
        if(Hour < 12)
        {
            [Sb appendString:NSLocalizedStringFromTable(@"上午",appDelegate.LocalizedTable,nil)];
        }
        else if(Hour == 12)
        {
            [Sb appendString:NSLocalizedStringFromTable(@"中午",appDelegate.LocalizedTable,nil)];
        }
        else if(Hour < 18)
        {
            [Sb appendString:NSLocalizedStringFromTable(@"下午",appDelegate.LocalizedTable,nil)];
        }
        else
        {
            [Sb appendString:NSLocalizedStringFromTable(@"晚上",appDelegate.LocalizedTable,nil)];
        }
        [Sb appendFormat:NSLocalizedStringFromTable(@" %02d點",appDelegate.LocalizedTable,nil),Hour];
        
        [Sb appendFormat:NSLocalizedStringFromTable(@" %02d分",appDelegate.LocalizedTable,nil),Min];
    }
    return [NSString stringWithString:Sb];
}
//ASIQueue設定
-(void)actSetASIQueue
{
    queueASIRequests = [[ASINetworkQueue alloc] init];
    [queueASIRequests setMaxConcurrentOperationCount:2];
    
    // ASIHTTPRequest 默認的情況下，queue 中只要有一個 request fail 了，整個 queue 裡的所有 requests 也都會被 cancel 掉
    [queueASIRequests setShouldCancelAllRequestsOnFailure:NO];
    
    // go 只需要執行一次
    //    [queueASIRequests go];
}
/*
-(void)actSetAPIPushAdd:(NSInteger)intCase;
{
    NSString * stringHHStart = [[[dictionarySelectedStop objectForKey:@"PushStartTime"] componentsSeparatedByString:@":"]objectAtIndex:0];
    NSString * stringHHEnd = [[[dictionarySelectedStop objectForKey:@"PushEndTime"] componentsSeparatedByString:@":"]objectAtIndex:0];
    
    //判斷 星期按鈕按下?是 再判斷 字串是否已有資料,若無則爲第一筆 不需加|
    NSMutableString * stringWeekSelected = [NSMutableString new];
    [stringWeekSelected appendString:[PushWeek1Btn isSelected]?@"1":@""];
    [stringWeekSelected appendString:[PushWeek2Btn isSelected]?(stringWeekSelected.length?@"|2":@"2"):@""];
    [stringWeekSelected appendString:[PushWeek3Btn isSelected]?(stringWeekSelected.length?@"|3":@"3"):@""];
    [stringWeekSelected appendString:[PushWeek4Btn isSelected]?(stringWeekSelected.length?@"|4":@"4"):@""];
    [stringWeekSelected appendString:[PushWeek5Btn isSelected]?(stringWeekSelected.length?@"|5":@"5"):@""];
    [stringWeekSelected appendString:[PushWeek6Btn isSelected]?(stringWeekSelected.length?@"|6":@"6"):@""];
    [stringWeekSelected appendString:[PushWeek0Btn isSelected]?(stringWeekSelected.length?@"|7":@"7"):@""];
#ifdef LogOut
    NSLog(@"week string %@",stringWeekSelected);
#endif
    //intCase 1:新增 2:修改 3:刪除
    NSDictionary * dictionaryTmp = @{
                                     @(intCase):[NSString stringWithFormat:APIPush,
                                                 [PushManager GetToken],//token
                                                 [NSString stringWithFormat:@"%d",intCase],//功能 1:加 2:更新 3:刪除
                                                 [dictionarySelectedStop objectForKey:@"ID"],//路線ID
                                                 [dictionarySelectedStop objectForKey:@"StopID"],//車站ID
                                                 [dictionarySelectedStop objectForKey:@"GoBack"],//1往,2返
                                                 stringHHStart,//開始時間HH:mm
                                                 stringHHEnd,//結束時間HH:mm
                                                 [dictionarySelectedStop objectForKey:@"PushShiftMinute"],//提醒時間(分)
                                                 ([[dictionarySelectedStop objectForKey:@"type"]isEqualToString:@"city"]?@"0":@"1"),//種類 0市區1公總
                                                 ([PushSwitch isOn]?@"1":@"0") ,//是否提醒
                                                 stringWeekSelected],//星期幾提醒
                                     @"server":APIServer
                                     };
    if (dictionaryAPI)
    {
        [dictionaryAPI setValuesForKeysWithDictionary:dictionaryTmp];
    }
    else
    {
        dictionaryAPI = [NSMutableDictionary dictionaryWithDictionary:dictionaryTmp];
    }
}*/

#pragma mark - UITextFieldDelegate
- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    /*
     edit Cooper 2015/08/28
     0807buglist 台中第二項
     把原本的砍掉，重做
     */
    NSDateFormatter * formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"HH:mm"];
 
    textFieldSender = textField;
    if(textField == PushArrivalTf)
    {
        [self.pickerView reloadAllComponents];
        SelectedSetTimeKind = 3;
    }
}
#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{

    if(AlertKind == 1)
    {
        //刪除Push
        if(buttonIndex == 0)
        {
            //取消
            //            NSLog(@"取消");
        }
        else
        {
            //刪除
            //            NSLog(@"刪除");
            
            FavoriteResult result = [FavoritesManager DeletePushsByRouteId:SelectedPushData.RouteId RouteName:SelectedPushData.RouteName StopId:SelectedPushData.StopId StopName:SelectedPushData.StopName GoBack:SelectedPushData.GoBack StartTime:SelectedPushData.StartTime EndTime:SelectedPushData.Endtime WeekSun:SelectedPushData.WeekSun WeekMon:SelectedPushData.WeekMon WeekTue:SelectedPushData.WeekTue WeekWed:SelectedPushData.WeekWed WeekThu:SelectedPushData.WeekThu WeekFri:SelectedPushData.WeekFri WeekSat:SelectedPushData.WeekSat RouteKind:SelectedPushData.RouteKind];
            if(result == success)
            {
                [PushDatas removeObject:SelectedPushData];
                [PushTv deleteRowsAtIndexPaths:[NSArray arrayWithObject:SelectedIndex] withRowAnimation:UITableViewRowAnimationFade];
                [PushTv endUpdates];
                [PushTv beginUpdates];
                [self SendQueryRequest:3];
            }
            else
            {
                UIAlertView * Alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"刪除失敗",appDelegate.LocalizedTable,nil) message:NSLocalizedStringFromTable(@"請再試一次或提交問題回報",appDelegate.LocalizedTable,nil) delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確定",appDelegate.LocalizedTable,nil) otherButtonTitles:nil, nil];
                [Alert show];
            }
            
            
        }
    }
    else if(AlertKind == 2)
    {
        //到站提醒是否覆蓋
        if(buttonIndex == 1)
        {
            intQueryFail = 0;
            [self SendQueryRequest:2];//更新到站提醒
        }
    }
    
}

#pragma mark - SilderMenu

- (void) ItemSelectedEvent:(NSString *) SelectedItem
{
//    AppDelegate * appdelegate = [[UIApplication sharedApplication] delegate];
    if([SelectedItem compare:@"dynamicbus"] == 0)
    {
        [appDelegate SwitchViewer:1];
    }
    else if([SelectedItem compare:@"routeplan"] == 0)
    {
        [appDelegate SwitchViewer:6];
    }
    else if([SelectedItem compare:@"nearstop"] == 0)
    {
        [appDelegate SwitchViewer:4];
    }
    else if([SelectedItem compare:@"traveltime"] == 0)
    {
        [appDelegate SwitchViewer:5];
    }
    else if([SelectedItem compare:@"questionreport"] == 0)
    {
        [appDelegate SwitchViewer:9];
    }
    else if([SelectedItem compare:@"favorites"] == 0)
    {
        [appDelegate SwitchViewer:7];
    }
    else if([SelectedItem compare:@"push"] == 0)
    {
        [appDelegate SwitchViewer:8];
    }
    else if([SelectedItem compare:@"about"] == 0)
    {
        [appDelegate SwitchViewer:10];
    }
    else if([SelectedItem compare:@"home"] == 0)
    {
        [appDelegate SwitchViewer:0];
    }
    else if([SelectedItem compare:@"language"] == 0)
    {
        [appDelegate SwitchViewer:11];
    }
}

- (void) SilderMenuHiddenedEvent
{
}
- (void) SilderMenuShowedEvent
{
}
#pragma mark PushSynchronousDelegate
- (void) PushSynchronousFinish
{
    PushDatas = [FavoritesManager GetPushes];
    if(PushDatas == nil || [PushDatas count] == 0)
    {
        [EmptyLbl setHidden:NO];
        [PushTv setHidden:YES];
    }
    else
    {
        for(PushData * onePush in PushDatas)
        {
            NSArray * SearchResultRoute =
            [onePush.RouteId length] != 0 ?
            [DataManager selectRouteDataKeyWord:onePush.RouteId byColumnTitle:RouteDataColumnTypeRouteID fromTableType:onePush.RouteKind == 0? RouteDataTypeCityRoutes : RouteDataTypeHighwayRoutes ]
            :[DataManager selectRouteDataKeyWord:onePush.RouteName byColumnTitle:RouteDataColumnTypeRouteName fromTableType:onePush.RouteKind == 0? RouteDataTypeCityRoutes : RouteDataTypeHighwayRoutes];
            
            if(SearchResultRoute != nil && [SearchResultRoute count] > 0)
            {
                NSDictionary * firstResult = [SearchResultRoute objectAtIndex:0];
                if(onePush.GoBack == 1)
                {
                    [onePush setDestination:[firstResult objectForKey:@"destinationZh"]];
                }
                else
                {
                    [onePush setDestination:[firstResult objectForKey:@"departureZh"]];
                }
                
            }
        }
        
        [EmptyLbl setHidden:YES];
        [PushTv setHidden:NO];
        [PushTv reloadData];
    }
    
}
#pragma mark HUD
-(void)ShowHUD:(NSString *)Message
{
    if([[NSThread currentThread] isMainThread])
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if(HUD == nil)
        {
            HUD = [[MBProgressHUD alloc] initWithWindow:window];
        }
        [window addSubview:HUD];
        [HUD setLabelText:Message];
        
        [HUD show:YES];
    }
    else
    {
        [self performSelectorOnMainThread:@selector(ShowHUD:) withObject:Message waitUntilDone:YES];
        return;
    }
	
}
-(void)CloseHUD
{
    if([[NSThread currentThread] isMainThread])
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [HUD hide:YES];
        [HUD removeFromSuperview];
    }
    else
    {
        [self performSelectorOnMainThread:@selector(CloseHUD) withObject:nil waitUntilDone:YES];
        return;
    }
}
#pragma mark TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 88.0f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(PushDatas == nil)
    {
        return 0;
    }
    else
    {
        return [PushDatas count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PushCell * cell = [tableView dequeueReusableCellWithIdentifier:@"PushCell"];
    if (cell == nil)
    {
        NSArray *nib=[[NSBundle mainBundle] loadNibNamed:@"PushCell" owner:self options:nil];
        cell = (PushCell *)[nib objectAtIndex:0];
    }
    PushData * onePush = [PushDatas objectAtIndex:[indexPath row]];
    [cell.RouteLbl setText:onePush.RouteName];
    [cell.StopLbl setText:onePush.StopName];
    if(onePush.Destination != nil && [onePush.Destination length] > 0)
    {
        [cell.TripLbl setText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"往:%@",appDelegate.LocalizedTable,nil),onePush.Destination]];
    }
    else
    {
        [cell.TripLbl setText:@""];
    }
    if(onePush.Enable == 1)
    {
        [cell.SwitchIv setImage:[UIImage imageNamed:@"push_enable.png"]];
    }
    else
    {
        [cell.SwitchIv setImage:[UIImage imageNamed:@"push_disable.png"]];
    }
    
    
    NSMutableString * ArrivalSb = [[NSMutableString alloc] initWithString:NSLocalizedStringFromTable(@"提醒時間:",appDelegate.LocalizedTable,nil)];
    NSMutableString * WeekSb = [[NSMutableString alloc] init];
    
    if(onePush.StartTime != nil)
    {
        [ArrivalSb appendString:onePush.StartTime];
    }
    [ArrivalSb appendFormat:@"~"];
    
    if(onePush.Endtime != nil)
    {
        [ArrivalSb appendString:onePush.Endtime];
    }
    [ArrivalSb appendFormat:NSLocalizedStringFromTable(@" 到站前%d分提醒",appDelegate.LocalizedTable,nil),onePush.Arrival];
    [cell.TimeLbl setText:ArrivalSb];
    
    NSMutableArray * Weeks = [[NSMutableArray alloc] init];
    [Weeks addObject:[NSNumber numberWithInt:onePush.WeekMon]];
    [Weeks addObject:[NSNumber numberWithInt:onePush.WeekTue]];
    [Weeks addObject:[NSNumber numberWithInt:onePush.WeekWed]];
    [Weeks addObject:[NSNumber numberWithInt:onePush.WeekThu]];
    [Weeks addObject:[NSNumber numberWithInt:onePush.WeekFri]];
    [Weeks addObject:[NSNumber numberWithInt:onePush.WeekSat]];
    [Weeks addObject:[NSNumber numberWithInt:onePush.WeekSun]];
    
    for(int i=0;i<[Weeks count];i++)
    {
        if([[Weeks objectAtIndex:i] integerValue] == 1)
        {
            [WeekSb appendFormat:@"%@、",NSLocalizedStringFromTable([[WeekStrs objectAtIndex:i] objectForKey:@"Full"],appDelegate.LocalizedTable,nil)];
        }
    }
    if([WeekSb length] > 0)
    {
        NSRange delragne;
        delragne.location = [WeekSb length] -1;
        delragne.length = 1;
        [WeekSb deleteCharactersInRange:delragne];
    }
    if([WeekSb length] > 13)
    {
        NSRange range = [WeekSb rangeOfString:NSLocalizedStringFromTable(@"週",appDelegate.LocalizedTable,nil)];
        while (range.length == 1)
        {
            [WeekSb deleteCharactersInRange:range];
            range = [WeekSb rangeOfString:NSLocalizedStringFromTable(@"週",appDelegate.LocalizedTable,nil)];
        }
    }
    [WeekSb insertString:NSLocalizedStringFromTable(@"提醒週期:",appDelegate.LocalizedTable,nil) atIndex:0];
    [cell.WeekLbl setText:WeekSb];
    
//    int weekcount = 0;
//    
//    if(onePush.WeekMon == 1){weekcount +=1;}
//    if(onePush.WeekTue == 1){weekcount +=1;}
//    if(onePush.WeekWed == 1){weekcount +=1;}
//    if(onePush.WeekThu == 1){weekcount +=1;}
//    if(onePush.WeekFri == 1){weekcount +=1;}
//    if(onePush.WeekSat == 1){weekcount +=1;}
//    if(onePush.WeekSun == 1){weekcount +=1;}
//    if(weekcount > 4)
//    {
//        for(int i=0;i<[Weeks count];i++)
//        {
//            
//        }
//    }
    
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SelectedPushData = [PushDatas objectAtIndex:[indexPath row]];
    SelectedIndex = indexPath;
    
    ChangedPushEnable = -1;
    ChangedStartPushTime = nil;
    ChangedEndPushTime = nil;
    ChangedArrival = -1;
    ChangedWeekMon = -1;
    ChangedWeekTue = -1;
    ChangedWeekWed = -1;
    ChangedWeekThu = -1;
    ChangedWeekFri = -1;
    ChangedWeekSat = -1;
    ChangedWeekSun = -1;
    
    [RouteLbl setText:SelectedPushData.RouteName];
    [StopLbl setText:SelectedPushData.StopName];
    
    if(SelectedPushData.GoBack == 0)
    {
        
    }
    else
    {
        
    }
    if(SelectedPushData.Enable == 1)
    {
        [PushSwitch setOn:YES];
    }
    else
    {
        [PushSwitch setOn:NO];
    }
    if(SelectedPushData.StartTime != nil)
    {
        [PushStartTf setText:[self GetChtTimeStr:SelectedPushData.StartTime] ];
        
    }
    if(SelectedPushData.Endtime != nil)
    {
        [PushEndTf setText:[self GetChtTimeStr:SelectedPushData.Endtime] ];
    }
    [PushArrivalTf setText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"%d分",appDelegate.LocalizedTable,nil),SelectedPushData.Arrival]];
    if(SelectedPushData.WeekMon == 1)
    {
        [PushWeek1Btn setSelected:YES];
    }
    else
    {
        [PushWeek1Btn setSelected:NO];
    }
    if(SelectedPushData.WeekMon == 1){[PushWeek1Btn setSelected:YES];}
    else{[PushWeek1Btn setSelected:NO];}
    if(SelectedPushData.WeekTue == 1){[PushWeek2Btn setSelected:YES];}
    else{[PushWeek2Btn setSelected:NO];}
    if(SelectedPushData.WeekWed == 1){[PushWeek3Btn setSelected:YES];}
    else{[PushWeek3Btn setSelected:NO];}
    if(SelectedPushData.WeekThu == 1){[PushWeek4Btn setSelected:YES];}
    else{[PushWeek4Btn setSelected:NO];}
    if(SelectedPushData.WeekFri == 1){[PushWeek5Btn setSelected:YES];}
    else{[PushWeek5Btn setSelected:NO];}
    if(SelectedPushData.WeekSat == 1){[PushWeek6Btn setSelected:YES];}
    else{[PushWeek6Btn setSelected:NO];}
    if(SelectedPushData.WeekSun == 1){[PushWeek0Btn setSelected:YES];}
    else{[PushWeek0Btn setSelected:NO];}
    
    if(SelectedPushData.Destination != nil && [SelectedPushData.Destination length] > 0)
    {
        [TripLbl setText:[NSString stringWithFormat:@"%@",SelectedPushData.Destination]];
    }
    else
    {
        [TripLbl setText:@""];
    }
    
    [self ShowPushEdit];
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        
        SelectedPushData = [PushDatas objectAtIndex:[indexPath row]];
        SelectedIndex = indexPath;
        AlertKind = 1;
        UIAlertView * Alert = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:NSLocalizedStringFromTable(@"確定刪除 %@[%@]?",appDelegate.LocalizedTable,nil),SelectedPushData.RouteName,SelectedPushData.StopName] delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"取消",appDelegate.LocalizedTable,nil) otherButtonTitles:NSLocalizedStringFromTable(@"確定刪除",appDelegate.LocalizedTable,nil), nil];
        [Alert show];
    }
    
}
#pragma mark UIPickerSource
- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}
- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 60;
}
- (NSString *) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [NSString stringWithFormat:NSLocalizedStringFromTable(@"%d分",appDelegate.LocalizedTable,nil),row+1];
}
/*
 edit Cooper 2015/08/28
 0807buglist 台中第二項
 把原本的砍掉，重做
 */
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    textField1SelectNum_group1 = row;
    textFieldSender.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%d分",appDelegate.LocalizedTable,nil),row+1];
}

#pragma mark - Query API
/*
 tag 用來分辨request是取得什麼資料
 1:到站提醒加入,
 2:到站提醒更新,
 3:到站提醒刪除
 */
- (void) SendQueryRequest:(NSInteger)integerTag
{
    if ( ![ShareTools connectedToNetwork] )
    {
        UIAlertView * Alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"請先開啟網路，才能同步伺服器",appDelegate.LocalizedTable,nil) delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確定",appDelegate.LocalizedTable,nil) otherButtonTitles:nil, nil];
        [Alert show];
		return;
	}
    
    if([queueASIRequests isSuspended])
    {
        [queueASIRequests go];
    }
    
    
//    [self actSetAPIPushAdd:integerTag];
    [self ShowHUD:NSLocalizedStringFromTable(@"更新到伺服器...",appDelegate.LocalizedTable,nil)];
    
    NSMutableString * WeekStrSb = [[NSMutableString alloc] init];
    if(ChangedWeekSun == 1 || (ChangedWeekSun == -1 && SelectedPushData.WeekSun == 1))
    {
        [WeekStrSb appendString:@"0|"];
    }
    if(ChangedWeekMon == 1 || (ChangedWeekMon == -1 && SelectedPushData.WeekMon == 1))
    {
        [WeekStrSb appendString:@"1|"];
    }
    if(ChangedWeekTue == 1 || (ChangedWeekTue == -1 && SelectedPushData.WeekTue == 1))
    {
        [WeekStrSb appendString:@"2|"];
    }
    if(ChangedWeekWed == 1 || (ChangedWeekWed == -1 && SelectedPushData.WeekWed == 1))
    {
        [WeekStrSb appendString:@"3|"];
    }
    if(ChangedWeekThu == 1 || (ChangedWeekThu == -1 && SelectedPushData.WeekThu == 1))
    {
        [WeekStrSb appendString:@"4|"];
    }
    if(ChangedWeekFri == 1 || (ChangedWeekFri == -1 && SelectedPushData.WeekFri == 1))
    {
        [WeekStrSb appendString:@"5|"];
    }
    if(ChangedWeekSat == 1 || (ChangedWeekSat == -1 && SelectedPushData.WeekSat == 1))
    {
        [WeekStrSb appendString:@"6|"];
    }
    if([WeekStrSb length] > 0)
    {
        [WeekStrSb deleteCharactersInRange:NSMakeRange([WeekStrSb length]-1, 1)];
    }
    
//    NSString *UrlStr = [NSString stringWithFormat:@"%@%@",[dictionaryAPI objectForKey:@"server"],[dictionaryAPI objectForKey:@(integerTag)]];
    
    NSString * UrlStr = [NSString stringWithFormat:APIPush,APIServer
                         ,[PushManager GetToken]
                         ,integerTag
                         ,SelectedPushData.RouteId
                         ,SelectedPushData.StopId
                         ,SelectedPushData.GoBack
                         ,ChangedStartPushTime == nil?SelectedPushData.StartTime:ChangedStartPushTime
                         ,ChangedEndPushTime == nil ? SelectedPushData.Endtime:ChangedEndPushTime
                         ,ChangedArrival == -1 ? SelectedPushData.Arrival : ChangedArrival
                         ,SelectedPushData.RouteKind
                         ,ChangedPushEnable == -1 ? SelectedPushData.Enable : ChangedPushEnable
                         ,WeekStrSb];
#ifdef LogOut
    NSLog(@"Push APIUrl:%@",UrlStr);
#endif
    
	ASIHTTPRequest * QueryRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[UrlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    [QueryRequest setDelegate:self];
    [QueryRequest setDidFinishSelector:@selector(QueryRequestFinish:)];
    [QueryRequest setDidFailSelector:@selector(QueryRequestFail:)];
    [QueryRequest setTimeOutSeconds:30.0];
    QueryRequest.tag = integerTag;
    
    [queueASIRequests addOperation:QueryRequest];

}

-(void) QueryRequestFinish :(ASIHTTPRequest *)request
{
    NSString * ResponseTxt = [request responseString];
    
    if([ResponseTxt compare:@"1"] == 0)
    {
        //[self actQueryOK:[NSNumber numberWithInt:request.tag ] ];
        if(self.boolFromBusDynamic)
        {
            FavoriteResult result = [FavoritesManager UpdatePushByRouteId:SelectedPushData.RouteId
                RouteName:SelectedPushData.RouteName
                StopId:SelectedPushData.StopId
                StopName:SelectedPushData.StopName
                GoBack:SelectedPushData.GoBack
                Enable:ChangedPushEnable != -1 ? ChangedPushEnable : SelectedPushData.Enable
                StartTime:ChangedStartPushTime != nil ? ChangedStartPushTime : SelectedPushData.StartTime
                EndTime:ChangedEndPushTime != nil ? ChangedEndPushTime : SelectedPushData.Endtime
                ArrivalTime:ChangedArrival != -1 ? ChangedArrival : SelectedPushData.Arrival
                WeekSun:ChangedWeekSun != -1 ? ChangedWeekSun : SelectedPushData.WeekSun
                WeekMon:ChangedWeekMon != -1 ? ChangedWeekMon : SelectedPushData.WeekMon
                WeekTue:ChangedWeekTue != -1 ? ChangedWeekTue : SelectedPushData.WeekTue
                WeekWed:ChangedWeekWed != -1 ? ChangedWeekWed : SelectedPushData.WeekWed
                WeekThu:ChangedWeekThu != -1 ? ChangedWeekThu : SelectedPushData.WeekThu
                WeekFri:ChangedWeekFri != -1 ? ChangedWeekFri : SelectedPushData.WeekFri
                WeekSat:ChangedWeekSat != -1 ? ChangedWeekSat : SelectedPushData.WeekSat
                RouteKind:SelectedPushData.RouteKind ];
            if(result == success)
            {
                NSLog(@"更新推播成功");
            }
            else
            {
                NSLog(@"更新推播失敗");
            }
            [self dismissViewControllerAnimated:YES completion:^{}];
        }
        else
        {
            if(ChangedPushEnable != -1){ SelectedPushData.Enable = ChangedPushEnable;}
            if(ChangedStartPushTime != nil){ SelectedPushData.StartTime = ChangedStartPushTime;}
            if(ChangedEndPushTime != nil){ SelectedPushData.Endtime = ChangedEndPushTime;}
            if(ChangedArrival != -1){ SelectedPushData.Arrival = ChangedArrival;}
            if(ChangedWeekMon != -1){ SelectedPushData.WeekMon = ChangedWeekMon;}
            if(ChangedWeekTue != -1){ SelectedPushData.WeekTue = ChangedWeekTue;}
            if(ChangedWeekWed != -1){ SelectedPushData.WeekWed = ChangedWeekWed;}
            if(ChangedWeekThu != -1){ SelectedPushData.WeekThu = ChangedWeekThu;}
            if(ChangedWeekFri != -1){ SelectedPushData.WeekFri = ChangedWeekFri;}
            if(ChangedWeekSat != -1){ SelectedPushData.WeekSat = ChangedWeekSat;}
            if(ChangedWeekSun != -1){ SelectedPushData.WeekSun = ChangedWeekSun;}
            
            FavoriteResult result = [FavoritesManager UpdatePushByRouteId:SelectedPushData.RouteId RouteName:SelectedPushData.RouteName
                StopId:SelectedPushData.StopId
                StopName:SelectedPushData.StopName
                GoBack:SelectedPushData.GoBack
                Enable:ChangedPushEnable == -1 ? SelectedPushData.Enable : ChangedPushEnable
                StartTime:ChangedStartPushTime == nil ? SelectedPushData.StartTime : ChangedStartPushTime
                EndTime:ChangedEndPushTime == nil ? SelectedPushData.Endtime : ChangedEndPushTime
                ArrivalTime:ChangedArrival == -1 ? SelectedPushData.Arrival : ChangedArrival
                WeekSun:ChangedWeekSun == -1 ? SelectedPushData.WeekSun : ChangedWeekSun
                WeekMon:ChangedWeekMon == -1 ? SelectedPushData.WeekMon : ChangedWeekMon
                WeekTue:ChangedWeekTue == -1 ? SelectedPushData.WeekTue : ChangedWeekTue
                WeekWed:ChangedWeekWed == -1 ? SelectedPushData.WeekWed : ChangedWeekWed
                WeekThu:ChangedWeekThu == -1 ? SelectedPushData.WeekThu : ChangedWeekThu
                WeekFri:ChangedWeekFri == -1 ? SelectedPushData.WeekFri : ChangedWeekFri
                WeekSat:ChangedWeekSat == -1 ? SelectedPushData.WeekSat : ChangedWeekSat
                RouteKind:SelectedPushData.RouteKind];
            
            if(result == success)
            {
                NSLog(@"更新推播成功");
            }
            else
            {
                NSLog(@"更新推播失敗");
            }
            if (request.tag != 3)
            {
                [PushTv reloadData];
            }
            [self HiddenPushDesc];
        }
    }
    else if([ResponseTxt compare:@"2"] == 0)
    {
        AlertKind = 2;
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:NSLocalizedStringFromTable(@"此路線站牌",appDelegate.LocalizedTable,nil) message:NSLocalizedStringFromTable(@"請確認是否覆蓋原資料",appDelegate.LocalizedTable,nil) delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"取消",appDelegate.LocalizedTable,nil) otherButtonTitles:NSLocalizedStringFromTable(@"確認",appDelegate.LocalizedTable,nil),nil];
        
        [alert show];
    }
    else
    {
        //err03查無資料,err01參數錯誤
        if ([ResponseTxt hasPrefix:@"err"])
        {
            NSString * stringMessage = nil;//[NSString stringWithFormat:@"查無%@資料",[dictionarySelectedRoute objectForKey:@"RouteName"]];
            UIAlertView * alert = [[UIAlertView alloc]initWithTitle:NSLocalizedStringFromTable(@"資料錯誤",appDelegate.LocalizedTable,nil) message:stringMessage delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確認",appDelegate.LocalizedTable,nil) otherButtonTitles:nil];
            [alert show];
            //            [self actSetArrayForTableView:nil];//清空tableview資料
        }
        else
        {
            [self QueryRequestFail:request];
            return;
        }
    }
    
    if (queueASIRequests.operationCount==0)
    {
        [queueASIRequests setSuspended:YES];
        //        [NSThread detachNewThreadSelector:@selector(stopActivityIndicator) toTarget:self withObject:nil];
    }
    [self CloseHUD];
}
-(void)QueryRequestFail:(ASIHTTPRequest *)request
{
    
    if (intQueryFail<5)
    {
        intQueryFail++;
        [self SendQueryRequest:request.tag];
        [self CloseHUD];
        return;
    }
    else
    {
#ifdef LogOut
        NSLog(@"Query fail Action:%ld",(long)request.tag);
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
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:NSLocalizedStringFromTable(@"無法連接伺服器",appDelegate.LocalizedTable,nil) message:@"" delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK",appDelegate.LocalizedTable,nil) otherButtonTitles:nil];
        [alert show];
    }
}
-(void)actQueryOK:(NSNumber *)intTag
{
    if([[NSThread currentThread] isMainThread])
    {
        
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"" message:@"" delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"確認",appDelegate.LocalizedTable,nil) otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        [self performSelectorOnMainThread:@selector(actQueryOK:) withObject:intTag waitUntilDone:YES];
        return;
    }
}
@end
