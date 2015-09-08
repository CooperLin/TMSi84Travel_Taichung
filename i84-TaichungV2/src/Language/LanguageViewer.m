//
//  AboutViewer.m
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/3/7.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "LanguageViewer.h"
#import "GDataXMLNode.h"
#import "AboutCell.h"
#import "AppDelegate.h"
#import "AttractionManager.h"
#import "ShareTools.h"

@interface LanguageViewer ()
{
    NSMutableArray * XmlRows;
    SilderMenuView * SilderMenu;
}
@property (strong, nonatomic) UIView *viewCover;
@property (strong, nonatomic) UIButton *m_btnCht;
@property (strong, nonatomic) UIButton *m_btnEng;
@end

@implementation LanguageViewer
@synthesize LeftMenuBtn;
@synthesize ContentV,VersionLbl,AboutTv,AttractionVersionLbl;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [ShareTools setViewToFullScreen:self.view];
    NSDictionary *infoDict=[[NSBundle mainBundle]infoDictionary];
    [VersionLbl setText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"版本序號:%@  %@",appDelegate.LocalizedTable,nil),[infoDict objectForKey:@"CFBundleShortVersionString"],[infoDict objectForKey:@"CFBundleVersion"]]];
    [AboutTv reloadData];
    [self _showViewCover:NO];
//    CGRect ContentFrame = ContentV.frame;
    SilderMenu = [[SilderMenuView alloc] initWithFrame:CGRectMake(0, 0, 135, self.view.frame.size.height)];
    [SilderMenu setSilderDelegate:self];
    [ContentV addSubview:SilderMenu];
    [SilderMenu setItemsByPlistName:@"LeftMenu"];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.AboutTitle.text = NSLocalizedStringFromTable(@"語系切換",appDelegate.LocalizedTable,nil);
    [AttractionVersionLbl setText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"熱門景點版本:%@",appDelegate.LocalizedTable,nil),[AttractionManager GetVerStr]]];
    [self _createBtnMethod:self.m_btnCht withTitle:@"中文" andFrame:CGRectMake(90, 200, 140, 40)];
    [self _createBtnMethod:self.m_btnEng withTitle:@"English" andFrame:CGRectMake(90, 308, 140, 40)];
}

-(void)_createBtnMethod:(UIButton *)sender withTitle:(NSString *)title andFrame:(CGRect)frame
{
    sender = [UIButton buttonWithType:UIButtonTypeCustom];
    [sender setBackgroundImage:[UIImage imageNamed:@"LanguageChangeBtnBG.png"] forState:UIControlStateNormal];
    [sender setTitle:title forState:UIControlStateNormal];
    [sender addTarget:self action:@selector(btnHandler:) forControlEvents:UIControlEventTouchUpInside];
    [sender setFrame:frame];
    [self.view addSubview:sender];
}

-(void)btnHandler:(id)sender
{
    UIButton *btn;
    NSString *str;
    if([sender isKindOfClass:[UIButton class]]){
        btn = (UIButton *)sender;
    }else {
        return;
    }
    if(btn == self.m_btnCht){
        str = kDefaultTW;
    }else if(btn == self.m_btnEng){
        str = kDefaultUS;
    }
    appDelegate.LocalizedTable = str;
//    [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultKey];
    [[NSUserDefaults standardUserDefaults] setObject:str forKey:kUserDefaultKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //切換語系後，如果要重讀資料庫裡的資料，則可在此做
    
    [appDelegate SwitchViewer:0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(IBAction) LeftMenuBtnClickEvent:(id)sender
{
    /*
     edit Cooper 2015/08/20
     0807buglist 台中第四項
     台中用額外的lib，所以只好一頁一頁改…
     */
    if(![LeftMenuBtn isSelected])
    {
        [SilderMenu SilderShow];
        [self _showViewCover:YES];
    }
    else
    {
        [SilderMenu SilderHidden];
        [self _showViewCover:NO];
        
    }
    [LeftMenuBtn setSelected:![LeftMenuBtn isSelected]];
}
/*
 edit Cooper 2015/08/20
 0807buglist 台中第四項
 台中用額外的lib，所以只好一頁一頁改…
 */
-(void)_showViewCover:(BOOL)bb
{
    if(!self.viewCover){
        self.viewCover = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width , self.view.frame.size.height)];
        self.viewCover.backgroundColor = [UIColor grayColor];
        self.viewCover.alpha = 0.4;
        [self.viewCover addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(LeftMenuBtnClickEvent:)]];
        [ContentV addSubview:self.viewCover];
    }
    [self.viewCover setHidden:!bb];
}
#pragma mark SilderMenu

- (void) ItemSelectedEvent:(NSString *) SelectedItem
{
    if([SelectedItem compare:@"dynamicbus"] == 0)
    {
        [appDelegate SwitchViewer:1];
    }
    else if([SelectedItem compare:@"routeplan"] == 0)
    {
        [appDelegate SwitchViewer:6];
    }
    else if([SelectedItem compare:@"nearstop"] == 0)
    {
        [appDelegate SwitchViewer:4];
    }
    else if([SelectedItem compare:@"traveltime"] == 0)
    {
        [appDelegate SwitchViewer:5];
    }
    else if([SelectedItem compare:@"questionreport"] == 0)
    {
        [appDelegate SwitchViewer:9];
    }
    else if([SelectedItem compare:@"favorites"] == 0)
    {
        [appDelegate SwitchViewer:7];
    }
    else if([SelectedItem compare:@"push"] == 0)
    {
        [appDelegate SwitchViewer:8];
    }
    else if([SelectedItem compare:@"about"] == 0)
    {
        [appDelegate SwitchViewer:10];
    }
    else if([SelectedItem compare:@"home"] == 0)
    {
        [appDelegate SwitchViewer:0];
    }
    else if([SelectedItem compare:@"language"] == 0)
    {
        [appDelegate SwitchViewer:11];
    }
}
- (void) SilderMenuHiddenedEvent
{
}
- (void) SilderMenuShowedEvent
{
}
#pragma mark TableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(XmlRows == nil)return 0;
    else return [XmlRows count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    AboutCell * cell = (AboutCell *)[tableView dequeueReusableCellWithIdentifier:@"AboutCell"];
    if(cell == nil)
    {
        NSArray *nib=[[NSBundle mainBundle]loadNibNamed:@"AboutCell" owner:self options:nil];
        cell = (AboutCell *)[nib objectAtIndex:0];
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

@end
