//
//  FavoritesViewer.h
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/3/3.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SilderMenuView.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>
#import <CFNetwork/CFNetwork.h>
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "CoreLocation/CoreLocation.h"
#import "CoreLocation/CLLocationManagerDelegate.h"
#import <MapKit/MapKit.h>
#import "RequestManager.h"

@interface FavoritesViewer : UIViewController
<UITableViewDataSource,UITableViewDelegate,SilderMenuDelegate,RequestManagerDelegate>
{
    IBOutlet UIView * ContentV;
    
    IBOutlet UIView * ListV;
    IBOutlet UITableView * FavoritesTv;
    IBOutlet UILabel * EmptyLabel;
    
    IBOutlet UIView * MapV;
    IBOutlet MKMapView * MapView;
    
    IBOutlet UIView * HeadV;
    IBOutlet UIButton * EditBtn;
    IBOutlet UIButton * LeftMenuBtn;
    IBOutlet UILabel *LabelTitle;
    
}
#define NewFavoriteAPI @"http://citybus.taichung.gov.tw/itravel/itravelAPI/ExpoAPI/FavoriteStop.aspx?RouteId=%@&StopId=%@&GoBack=%d&Type=%d"
@property (nonatomic,retain) IBOutlet UIView * ContentV;

@property (nonatomic,retain) IBOutlet UIView * ListV;
@property (nonatomic,retain) IBOutlet UITableView * FavoritesTv;
@property (nonatomic,retain) IBOutlet UILabel * EmptyLabel;

@property (nonatomic,retain) IBOutlet UIView * MapV;
@property (nonatomic,retain) IBOutlet MKMapView * MapView;

@property (nonatomic,retain) IBOutlet UIView * HeadV;
@property (nonatomic,retain) IBOutlet UIButton * EditBtn;
@property (nonatomic,retain) IBOutlet UIButton * LeftMenuBtn;
@property (strong, nonatomic) IBOutlet UILabel *LabelTitle;


-(IBAction) LeftMenuBtnClickEvent:(id)sender;
-(IBAction) EditBtnClickEvent:(id)sender;


@end
