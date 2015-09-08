//
//  nearStopViewController.h
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/3/5.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SilderMenuView.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLLocationManagerDelegate.h>

@interface nearStopViewController : UIViewController<SilderMenuDelegate,CLLocationManagerDelegate,UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *ContentV;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIView *viewDistanceButtons;
@property (strong, nonatomic) IBOutlet UITableView *tableViewMain;
@property (strong, nonatomic) IBOutlet UILabel *labelUpdateTime;
@property (strong, nonatomic) IBOutlet UIButton *btn100;
@property (strong, nonatomic) IBOutlet UIButton *btn300;
@property (strong, nonatomic) IBOutlet UIButton *btn500;
@property (strong, nonatomic) IBOutlet UIButton *reflashBtn;
@property (strong, nonatomic) IBOutlet UILabel *NearStopTitle;

- (IBAction)actBtnSlideMenuTouchUpInside:(id)sender;
- (IBAction)actBtnDistanceTouchUpInside:(id)sender;
- (IBAction)actBtnUpdateTouchUpInside:(id)sender;

@end
