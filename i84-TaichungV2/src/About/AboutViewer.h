//
//  AboutViewer.h
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/3/7.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SilderMenuView.h"

@interface AboutViewer : UIViewController<UITableViewDelegate,UITableViewDataSource,SilderMenuDelegate>
{
    IBOutlet UIButton * LeftMenuBtn;
    
    
    IBOutlet UIView * ContentV;
    IBOutlet UILabel * VersionLbl;
    IBOutlet UILabel * AttractionVersionLbl;
    IBOutlet UITableView * AboutTv;
}
@property (nonatomic,retain)    IBOutlet UIButton * LeftMenuBtn;
@property (nonatomic,retain)    IBOutlet UIView * ContentV;
@property (nonatomic,retain)    IBOutlet UILabel * VersionLbl;
@property (nonatomic,retain)    IBOutlet UILabel * AttractionVersionLbl;
@property (nonatomic,retain)    IBOutlet UITableView * AboutTv;
@property (strong, nonatomic) IBOutlet UILabel *AboutTitle;


- (IBAction) LeftMenuBtnClickEvent:(id)sender;


@end
@interface AboutRow : NSObject
{
    NSString * Background;
    NSString * Image;
    NSString * qname;
    NSString * Text;
}
@property (nonatomic,retain) NSString * Background;
@property (nonatomic,retain) NSString * Image;
@property (nonatomic,retain) NSString * qname;
@property (nonatomic,retain) NSString * Text;

@end