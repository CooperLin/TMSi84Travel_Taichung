//
//  StopsTakeTimeViewController.h
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/4/29.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum _StopsTakeTimeDataType
{
    StopsTakeTimeDataTypeSearchStops = 1,
    StopsTakeTimeDataTypeGetPathTime = 2,
} StopsTakeTimeDataType;
@protocol StopsTakeTimeDelegate <NSObject>
@required

@optional
-(void)addHeaderBackButton;
-(void)removeHeaderBackButton;
-(void)startActivityIndicator;
-(void)stopActivityIndicator;

@end
@interface StopsTakeTimeViewController : UIViewController<UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableViewList;
@property (strong, nonatomic) IBOutlet UITableView *tableViewSearchStops;
@property (strong, nonatomic) IBOutlet UIView *viewContent;
@property (strong, nonatomic) IBOutlet UITextField *textFieldDeparture;
@property (strong, nonatomic) IBOutlet UITextField *textFieldDestination;
@property (strong, nonatomic) IBOutlet UIView *viewSearch;
@property (strong, nonatomic) IBOutlet UITextField *textFieldSearch;
@property (strong, nonatomic) IBOutlet UILabel *startPoint;
@property (strong, nonatomic) IBOutlet UILabel *endPoint;
@property (strong, nonatomic) IBOutlet UIButton *searchRouteTime;

@property (strong, nonatomic) id<StopsTakeTimeDelegate> delegate;
- (IBAction)actBtnCancelSearchTouchUpInside:(id)sender;
- (IBAction)actBtnSwapTouchUpInside:(id)sender;
- (IBAction)actBtnCheckTimeTouchUpInside:(id)sender;
-(void)actRemoveSearchView;

@end
