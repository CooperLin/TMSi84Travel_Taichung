//
//  stopNearLinesViewController.h
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/3/5.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SilderMenuView.h"

@interface stopNearLinesViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,SilderMenuDelegate>
@property (strong, nonatomic) IBOutlet UIView *ContentV;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UITableView *tableViewRoutes;
@property (strong, nonatomic) IBOutlet UILabel *labelTitle;
@property (strong, nonatomic) IBOutlet UILabel *labelSubTitle;
@property (strong, nonatomic) IBOutlet UIButton *reflashBtn;

@property (strong, nonatomic) IBOutlet UILabel *labelUpdateTime;
- (IBAction)actBtnSlideMenuTouchUpInside:(id)sender;
- (IBAction)actBtnUpdateTouchUpInside:(id)sender;

@end
