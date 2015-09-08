//
//  MainViewController.h
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/2/26.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController
{
    
    IBOutlet UIView * MarqueeV;
    
    IBOutlet UIButton * DynamicBusBtn;
    IBOutlet UIButton * RoutePlanBtn;
    IBOutlet UIButton * TravelTimeBtn;
    IBOutlet UIButton * NearStopBtn;
    IBOutlet UIButton * QuestionReportBtn;
    IBOutlet UIButton * FavoritesBtn;
    IBOutlet UIButton * AboutBtn;
    IBOutlet UIButton * PushBtn;
    IBOutlet UIImageView *backgroundImg;
    IBOutlet UIButton * LanguageBtn;
    
}

@property (nonatomic,retain) IBOutlet UIView * MarqueeV;

@property (strong, nonatomic) IBOutlet UIImageView *backgroundImg;
@property (nonatomic,retain) IBOutlet UIButton * DynamicBusBtn;
@property (nonatomic,retain) IBOutlet UIButton * RoutePlanBtn;
@property (nonatomic,retain) IBOutlet UIButton * TravelTimeBtn;
@property (nonatomic,retain) IBOutlet UIButton * NearStopBtn;
@property (nonatomic,retain) IBOutlet UIButton * QuestionReportBtn;
@property (nonatomic,retain) IBOutlet UIButton * FavoritesBtn;
@property (nonatomic,retain) IBOutlet UIButton * AboutBtn;
@property (nonatomic,retain) IBOutlet UIButton * PushBtn;
@property (strong, nonatomic) IBOutlet UIButton *LanguageBtn;

- (IBAction) MainBtnClickEvent:(id)sender;

@end
