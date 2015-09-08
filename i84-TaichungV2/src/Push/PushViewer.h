//
//  PushViewer.h
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/3/4.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SilderMenuView.h"
#import "ASINetworkQueue.h"
#import "ASIHTTPRequest.h"
#import "FavoritesManager.h"

@interface PushViewer : UIViewController<UITableViewDataSource,UITableViewDelegate,SilderMenuDelegate,UITextFieldDelegate,UIAlertViewDelegate,UIPickerViewDataSource,UIPickerViewDelegate,PushSynchronousDelegate>
{
    IBOutlet UIView * HeadV;
    IBOutlet UIButton * LeftMenuBtn;
    IBOutlet UIButton * EditBtn;
    
    IBOutlet UIView * ContentV;
    
    IBOutlet UIView * ListV;
    IBOutlet UITableView * PushTv;
    IBOutlet UILabel * EmptyLbl;
    
    IBOutlet UIView * PushEditV;
    IBOutlet UILabel * RouteLbl;
    IBOutlet UILabel * StopLbl;
    IBOutlet UILabel * TripLbl;
    IBOutlet UISwitch * PushSwitch;
    IBOutlet UITextField * PushStartTf;
    IBOutlet UITextField * PushEndTf;
    IBOutlet UITextField * PushArrivalTf;
    IBOutlet UIButton * PushWeek1Btn;
    IBOutlet UIButton * PushWeek2Btn;
    IBOutlet UIButton * PushWeek3Btn;
    IBOutlet UIButton * PushWeek4Btn;
    IBOutlet UIButton * PushWeek5Btn;
    IBOutlet UIButton * PushWeek6Btn;
    IBOutlet UIButton * PushWeek0Btn;
}
@property (nonatomic,retain)     IBOutlet UIView * HeadV;
@property (strong, nonatomic) IBOutlet UILabel *GetStopsRemind;
@property (nonatomic,retain)     IBOutlet UIButton * LeftMenuBtn;
@property (nonatomic,retain)     IBOutlet UIButton * EditBtn;

@property (nonatomic,retain)     IBOutlet UIView * ContentV;

@property (nonatomic,retain)     IBOutlet UIView * ListV;
@property (nonatomic,retain)     IBOutlet UITableView * PushTv;
@property (nonatomic,retain)     IBOutlet UILabel * EmptyLbl;

@property (nonatomic,retain)     IBOutlet UIView * PushEditV;
@property (nonatomic,retain)     IBOutlet UILabel * RouteLbl;
@property (nonatomic,retain)     IBOutlet UILabel * StopLbl;
@property (nonatomic,retain)     IBOutlet UILabel * TripLbl;
@property (nonatomic,retain)     IBOutlet UISwitch * PushSwitch;
@property (nonatomic,retain)     IBOutlet UITextField * PushStartTf;
@property (nonatomic,retain)     IBOutlet UITextField * PushEndTf;
@property (nonatomic,retain)     IBOutlet UITextField * PushArrivalTf;
@property (strong, nonatomic) IBOutlet UILabel *LabelRoute;
@property (strong, nonatomic) IBOutlet UILabel *LabelStopsName;
@property (strong, nonatomic) IBOutlet UILabel *LabelForward;
@property (strong, nonatomic) IBOutlet UILabel *LabelSwitch;
@property (strong, nonatomic) IBOutlet UILabel *LabelStartRemind;
@property (strong, nonatomic) IBOutlet UILabel *LabelEndRemind;
@property (strong, nonatomic) IBOutlet UILabel *LabelRemindTime;
@property (strong, nonatomic) IBOutlet UILabel *LabelRemindCycle;
@property (nonatomic,retain)     IBOutlet UIButton * PushWeek1Btn;
@property (nonatomic,retain)     IBOutlet UIButton * PushWeek2Btn;
@property (nonatomic,retain)     IBOutlet UIButton * PushWeek3Btn;
@property (nonatomic,retain)     IBOutlet UIButton * PushWeek4Btn;
@property (nonatomic,retain)     IBOutlet UIButton * PushWeek5Btn;
@property (nonatomic,retain)     IBOutlet UIButton * PushWeek6Btn;
@property (nonatomic,retain)     IBOutlet UIButton * PushWeek0Btn;
@property (strong, nonatomic) IBOutlet UIButton *pushOkBtn;
@property (strong, nonatomic) IBOutlet UIButton *cancelBtn;

@property (nonatomic,assign)    BOOL boolFromBusDynamic;

- (IBAction) LeftMenuBtnClickEvent:(id)sender;
- (IBAction) EditBtnClickEvent:(id)sender;
- (IBAction) PushSwitchEvent:(id)sender;
- (IBAction) WeekBtnClickEvent:(id)sender;
- (IBAction) PushSetEnableBtnClickEvent:(id)sender;
- (IBAction) PushSetCancelBtnClickEvent:(id)sender;
- (IBAction)TextFieldDatePicker:(UITextField *)sender;
- (IBAction)TextFieldPicker:(UITextField *)sender;




@end
