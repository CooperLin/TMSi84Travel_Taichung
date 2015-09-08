//
//  RoutePlanViewer.h
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/3/10.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SilderMenuView.h"
#import "CoreLocation/CoreLocation.h"
#import "CoreLocation/CLLocationManagerDelegate.h"
#import <MapKit/MapKit.h>
#import "AppDelegate.h"
#import "RequestManager.h"

@interface RoutePlanViewer : UIViewController<
    UITableViewDataSource
    ,UITableViewDelegate
    ,SilderMenuDelegate
    ,UITextFieldDelegate
    ,MKMapViewDelegate
    ,CLLocationManagerDelegate
    ,RequestManagerDelegate>
{
    
    IBOutlet UIView * ContentV;
    IBOutlet UITextField * StartLandmarkTf;
    IBOutlet UITextField * EndLandmarkTf;
    IBOutlet UIButton * BackToHotVBtn;
    IBOutlet UIView * SubContentV;
    
    IBOutlet UIView * HeadV;
    IBOutlet UILabel *ListTitle;
    IBOutlet UILabel *ListStartPoint;
    IBOutlet UILabel *ListEndPoint;
    IBOutlet UIButton *ListSearchBtn;
    IBOutlet UIButton * SetBtn;
    IBOutlet UIButton * LeftMenuBtn;
    
    IBOutlet UIView * HotV;
    
    IBOutlet UIView * ListV;
    IBOutlet UITableView * ListTv;
    IBOutlet UILabel * EmptyLbl;
    
    IBOutlet UIView * LandmarkSubV;
    IBOutlet UIView * LandmarkSubV1;
    IBOutlet UIView * LandmarkSubV2;
    
    IBOutlet UIView * SearchV;
    IBOutlet UIView * SearchLayout;
    IBOutlet UITextField * SearchTf;
    IBOutlet UITableView * SearchTv;
    IBOutlet UILabel * SearchEmptyLbl;
    IBOutlet UILabel *SearchTitle;
    IBOutlet UIButton *HideSearchBtn;
    
    IBOutlet UIView * SetV;
    IBOutlet UIView * SetLayout;
    IBOutlet UITextField * AddressTf;
    IBOutlet UISegmentedControl * LocationSeg;
    IBOutlet MKMapView * LocationMapV;
    IBOutlet UILabel *SetTitle;
    IBOutlet UIButton *HideSetBtn;
    IBOutlet UIButton * SaveSetBtn;
    
    IBOutlet UIButton *LandmarkEndPoint;
    IBOutlet UIButton *LandmarkAdd;
    
    IBOutlet UIButton *LandmarkStartPoint;
    IBOutlet UIButton *LandmarkCollect;
    
    IBOutlet UIButton *LandmarkStart;
    IBOutlet UIButton *LandmarkEnd;
    IBOutlet UIButton *LandmarkAddCollect;
    
    IBOutlet UIButton *MenuTimeCustom;
    IBOutlet UIButton *MenuTimeNow;
    IBOutlet UIButton *MenuNoTime;
    

    IBOutlet UIImageView *NowLocationImg;
    IBOutlet UIImageView *HomeImg;
    IBOutlet UIImageView *CompanyImg;
    IBOutlet UIImageView *HotLandmark;
    IBOutlet UIImageView *MyCollect;
    
    
}



@property (nonatomic,retain) IBOutlet UIView * ContentV;
@property (nonatomic,retain) IBOutlet UITextField * StartLandmarkTf;
@property (nonatomic,retain) IBOutlet UITextField * EndLandmarkTf;
@property (nonatomic,retain) IBOutlet UIButton * BackToHotVBtn;
@property (strong, nonatomic) IBOutlet UIButton *SearchToHotVBtn;
@property (nonatomic,retain) IBOutlet UIView * SubContentV;

@property (nonatomic,retain) IBOutlet UIView * HeadV;
@property (strong, nonatomic) IBOutlet UILabel *ListTitle;
@property (strong, nonatomic) IBOutlet UILabel *ListStartPoint;
@property (strong, nonatomic) IBOutlet UILabel *ListEndPoint;
@property (strong, nonatomic) IBOutlet UIButton *ListSearchBtn;
@property (nonatomic,retain) IBOutlet UIButton * SetBtn;
@property (nonatomic,retain) IBOutlet UIButton * LeftMenuBtn;

@property (nonatomic,retain) IBOutlet UIView * HotV;

@property (nonatomic,retain) IBOutlet UIView * ListV;
@property (nonatomic,retain) IBOutlet UITableView * ListTv;
@property (nonatomic,retain) IBOutlet UILabel * EmptyLbl;

@property (nonatomic,retain) IBOutlet UIView * LandmarkSubV;
@property (nonatomic,retain) IBOutlet UIView * LandmarkSubV1;
@property (nonatomic,retain) IBOutlet UIView * LandmarkSubV2;

@property (nonatomic,retain) IBOutlet UIView * SearchV;

@property (nonatomic,retain) IBOutlet UIView * SearchLayout;
@property (nonatomic,retain) IBOutlet UITextField * SearchTf;
@property (nonatomic,retain) IBOutlet UITableView * SearchTv;
@property (nonatomic,retain) IBOutlet UILabel * SearchEmptyLbl;
@property (strong, nonatomic) IBOutlet UILabel *SearchTitle;
@property (strong, nonatomic) IBOutlet UIButton *HideSearchBtn;
@property (nonatomic,retain) IBOutlet UIView * SetV;
@property (nonatomic,retain) IBOutlet UIView * SetLayout;
@property (nonatomic,retain) IBOutlet UITextField * AddressTf;
@property (nonatomic,retain) IBOutlet UISegmentedControl * LocationSeg;
@property (nonatomic,retain) IBOutlet MKMapView * LocationMapV;
@property (strong, nonatomic) IBOutlet UILabel *SetTitle;
@property (strong, nonatomic) IBOutlet UIButton *HideSetBtn;
@property (nonatomic,retain) IBOutlet UIButton * SaveSetBtn;

@property (strong, nonatomic) IBOutlet UIButton *LandmarkEndPoint;
@property (strong, nonatomic) IBOutlet UIButton *LandmarkAdd;

@property (strong, nonatomic) IBOutlet UIButton *LandmarkStartPoint;
@property (strong, nonatomic) IBOutlet UIButton *LandmarkCollect;

@property (strong, nonatomic) IBOutlet UIButton *LandmarkStart;
@property (strong, nonatomic) IBOutlet UIButton *LandmarkEnd;
@property (strong, nonatomic) IBOutlet UIButton *LandmarkAddCollect;

@property (strong, nonatomic) IBOutlet UIButton *MenuTimeCustom;
@property (strong, nonatomic) IBOutlet UIButton *MenuTimeNow;
@property (strong, nonatomic) IBOutlet UIButton *MenuNoTime;

@property (strong, nonatomic) IBOutlet UIImageView *NowLocationImg;
@property (strong, nonatomic) IBOutlet UIImageView *HomeImg;
@property (strong, nonatomic) IBOutlet UIImageView *CompanyImg;
@property (strong, nonatomic) IBOutlet UIImageView *HotLandmark;
@property (strong, nonatomic) IBOutlet UIImageView *MyCollect;

-(IBAction) LeftMenuBtnClickEvent:(id)sender;
-(IBAction) SetBtnClickEvent:(id)sender;
-(IBAction) SwitchBtnClickEvent:(id)sender;
-(IBAction) QueryBtnClickEvent:(id)sender;
-(IBAction) BackToHotVBtnClickEvent:(id)sender;
-(IBAction) ShowSearchVBtnClickEvent:(id)sender;

-(IBAction) HomeBtnClickEvent:(id)sender;
-(IBAction) CompanyBtnClickEvent:(id)sender;
-(IBAction) HotLandmarkBtnClickEvent:(id)sender;
-(IBAction) CollectBtnClickEvent:(id)sender;
-(IBAction) NowLocationBtnClickEvent:(id)sender;

-(IBAction) SetToStartBtnClickEvent:(id)sender;
-(IBAction) SetToEndBtnClickEvent:(id)sender;
-(IBAction) AddToCollectBtnClickEvent:(id)sender;

-(IBAction) HiddenSearchVBtnClick:(id)sender;
-(IBAction) HiddenKeyboardBtnClick:(id)sender;
-(IBAction) SaveLocationSetBtnClick:(id)sender;
-(IBAction) LocationSegSelectedEvent:(id)sender;
-(IBAction) HiddenSetVBtnClick:(id)sender;


@end
