//
//  SearchBusViewController.h
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/3/3.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SilderMenuView.h"

@interface SearchBusViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UIPickerViewDataSource,UIPickerViewDelegate,SilderMenuDelegate>
@property (strong, nonatomic) IBOutlet UIView *ContentV;
@property (strong, nonatomic) IBOutlet UITableView *tableViewSearch;
@property (strong, nonatomic) IBOutlet UILabel *labelInput;
@property (strong, nonatomic) IBOutlet UILabel *labelProvider;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UILabel *labelTitle;
@property (strong, nonatomic) IBOutlet UIButton *clearBtn;

@property (strong, nonatomic) IBOutlet UIView *viewPicker;
- (IBAction)actBtnPickerTouchUpInside:(id)sender;
- (IBAction)actBtnSlideMenuTouchUpInside:(id)sender;
- (IBAction)actBtnNumbersTouchUpInside:(id)sender;

@end
