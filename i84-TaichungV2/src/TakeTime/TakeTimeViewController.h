//
//  TakeTimeViewController.h
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/4/29.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StopsTakeTimeViewController.h"
#import "SilderMenuView.h"

@interface TakeTimeViewController : UIViewController<SilderMenuDelegate>
@property (strong, nonatomic) IBOutlet UIView *viewMatrix;
@property (strong, nonatomic) IBOutlet UIView *viewContainer;
@property (strong, nonatomic) StopsTakeTimeViewController * stopsTakeTimeViewController;
- (IBAction)actBtnSlideMenuTouchUpInside:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *btnSlideMenu;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;


@end
