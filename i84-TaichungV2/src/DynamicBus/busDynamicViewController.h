//
//  busDynamicViewController.h
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/3/11.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SilderMenuView.h"
#import "PushViewer.h"
#import "webViewController.h"
typedef enum _BusDynamicRequestType
{
    DynamicTime = 1,
} BusDynamicRequestType;

@interface busDynamicViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,SilderMenuDelegate,WebViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *ContentV;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UILabel *labelTitle;
@property (strong, nonatomic) IBOutlet UILabel *labelBusName;
@property (strong, nonatomic) IBOutlet UIButton *btnForward;
@property (strong, nonatomic) IBOutlet UIButton *btnBackward;
@property (strong, nonatomic) IBOutlet UITableView *tableViewMain;
@property (strong, nonatomic) IBOutlet UIView *viewCellSelectedMenu;
@property (strong, nonatomic) IBOutlet UILabel *labelUpdateTime;
@property (strong, nonatomic) IBOutlet UIButton *reflashBtn;

@property (strong, nonatomic) IBOutlet UIButton *addToRemind;
@property (strong, nonatomic) IBOutlet UIButton *addToFavorite;
@property (strong, nonatomic) IBOutlet UIButton *passRoute;


@property (assign, nonatomic) BOOL boolFromFavorite;
- (IBAction)actBtnTowardTouchUpInside:(id)sender;
- (IBAction)actBtnSlideMenuTouchUpInside:(id)sender;
- (IBAction)actBtnMenuTouchUpInside:(id)sender;
- (IBAction)actBtnUpdateTouchUpInside:(id)sender;
- (IBAction)actBtnStaticBusTouchUpInside:(id)sender;

@end
