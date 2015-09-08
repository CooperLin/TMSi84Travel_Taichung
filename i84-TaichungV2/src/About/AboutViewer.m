//
//  AboutViewer.m
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/3/7.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "AboutViewer.h"
#import "GDataXMLNode.h"
#import "AboutCell.h"
#import "AppDelegate.h"
#import "AttractionManager.h"
#import "ShareTools.h"

@interface AboutViewer ()
{
    NSMutableArray * XmlRows;
    SilderMenuView * SilderMenu;
}
@property (strong, nonatomic) UIView *viewCover;
@end
@implementation AboutRow

@synthesize Background;
@synthesize Image;
@synthesize qname;
@synthesize Text;

@end

@implementation AboutViewer
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
    [self ReadAboutXml];
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
    self.AboutTitle.text = NSLocalizedStringFromTable(@"關於",appDelegate.LocalizedTable,nil);
    [AttractionVersionLbl setText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"熱門景點版本:%@",appDelegate.LocalizedTable,nil),[AttractionManager GetVerStr]]];
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
    AppDelegate * appdelegate = [[UIApplication sharedApplication] delegate];
    if([SelectedItem compare:@"dynamicbus"] == 0)
    {
        [appdelegate SwitchViewer:1];
    }
    else if([SelectedItem compare:@"routeplan"] == 0)
    {
        [appdelegate SwitchViewer:6];
    }
    else if([SelectedItem compare:@"nearstop"] == 0)
    {
        [appdelegate SwitchViewer:4];
    }
    else if([SelectedItem compare:@"traveltime"] == 0)
    {
        [appdelegate SwitchViewer:5];
    }
    else if([SelectedItem compare:@"questionreport"] == 0)
    {
        [appdelegate SwitchViewer:9];
    }
    else if([SelectedItem compare:@"favorites"] == 0)
    {
        [appdelegate SwitchViewer:7];
    }
    else if([SelectedItem compare:@"push"] == 0)
    {
        [appdelegate SwitchViewer:8];
    }
    else if([SelectedItem compare:@"about"] == 0)
    {
        [appdelegate SwitchViewer:10];
    }
    else if([SelectedItem compare:@"home"] == 0)
    {
        [appdelegate SwitchViewer:0];
    }
    else if([SelectedItem compare:@"language"] == 0)
    {
        [appdelegate SwitchViewer:11];
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
    AboutRow * oneRow = [XmlRows objectAtIndex:[indexPath row]];
    bool hasimage= NO;
    if(oneRow.Background != nil
       &&[oneRow.Background  length] > 0)
    {
        if([oneRow.Background  compare:@"itembg"] == 0)
            [cell.BgV setBackgroundColor:[[UIColor alloc] initWithRed:1.0 green:0.5 blue:0.0 alpha:0.8]];
        else if([oneRow.Background compare:@"Line"] == 0)
            [cell.BgV setBackgroundColor:[UIColor grayColor]];
        else [cell.BgV setBackgroundColor:[UIColor clearColor]];
        
        [cell.TopLine setHidden:NO];
        [cell.BottomLine setHidden:NO];
    }
    else
    {
        [cell.BgV setBackgroundColor:[UIColor clearColor]];
        [cell.TopLine setHidden:YES];
        [cell.BottomLine setHidden:YES];
    }
    
    if(oneRow.Image != nil
       && [oneRow.Image length] > 0)
    {
        hasimage = YES;
        NSString * ResFile = [[NSBundle mainBundle] pathForResource: oneRow.Image ofType: @"png"];
        [cell.Iv setImage:[[UIImage alloc] initWithContentsOfFile:ResFile]];
    }
    CGRect Frame = cell.TitleLbl.frame;
    Frame.origin.x = hasimage ? 40 : 4;
    Frame.origin.y = 0;
    Frame.size.width = hasimage ? 276: 312;
    
    NSMutableString * TextValue = [[NSMutableString alloc] initWithString: oneRow.Text ? oneRow.Text:@""];
    
    NSRange range = [TextValue rangeOfString:@"[Version]"];
    if(range.length > 0)
    {
        NSDictionary *infoDict=[[NSBundle mainBundle]infoDictionary];
        [TextValue deleteCharactersInRange:range];
        [TextValue insertString:[infoDict objectForKey:@"CFBundleShortVersionString"] atIndex:range.location];
    }
    range = [TextValue rangeOfString:@"[BuildDate]"];
    if(range.length > 0)
    {
        NSDictionary *infoDict=[[NSBundle mainBundle]infoDictionary];
        [TextValue deleteCharactersInRange:range];
        [TextValue insertString:[infoDict objectForKey:@"CFBundleVersion"] atIndex:range.location];
    }
    range = [TextValue rangeOfString:@"[AppName]"];
    if(range.length > 0)
    {
        NSDictionary *infoDict=[[NSBundle mainBundle]infoDictionary];
        [TextValue deleteCharactersInRange:range];
        [TextValue insertString:[infoDict objectForKey:@"CFBundleDisplayName"] atIndex:range.location];
    }
    float rowh  = [self tableView:tableView heightForRowAtIndexPath:indexPath];
    Frame.size.height = rowh;
    
    [cell.TitleLbl setText:TextValue];
    
    cell.TitleLbl.numberOfLines = ceil( rowh / 21);
    [cell.TitleLbl setFrame:Frame];
    
    Frame = cell.frame;
    Frame.size.height = rowh;
    [cell setFrame:Frame];
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    float rowh  = 1.0f;
    AboutRow * oneRow = [XmlRows objectAtIndex:[indexPath row]];
    
    bool hasimage= NO;
    
    if(oneRow.Image != nil
       && [oneRow.Image length] > 0)
        hasimage = YES;
    CGRect Frame;
    Frame.origin.x = hasimage ? 40 : 4;
    Frame.size.width = hasimage ? 276: 312;
    NSString * TextValue = oneRow.Text ? oneRow.Text:@"";
    
    CGSize maximumLabelSize = CGSizeMake(Frame.size.width,300);
    
    CGSize expectedLabelSize = [TextValue sizeWithFont:[UIFont boldSystemFontOfSize:17.0f] constrainedToSize:maximumLabelSize lineBreakMode:UILineBreakModeTailTruncation];
    rowh = expectedLabelSize.height < rowh ? rowh:expectedLabelSize.height;
    
    
    return rowh;
}

- (void) ReadAboutXml
{
    NSString * XmlFile = [[NSBundle mainBundle] pathForResource: NSLocalizedStringFromTable(@"about",appDelegate.LocalizedTable,nil) ofType: @"XML"];
    NSData * xmlData = [[NSData alloc] initWithContentsOfFile:XmlFile];
    XmlRows = [[NSMutableArray alloc] init];
    GDataXMLDocument * XmlDoc = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:nil];
    if(XmlDoc != nil)
    {
        //XmlRows = [XmlDoc.rootElement elementsForName:@"Row"];
        NSArray * Rows = [XmlDoc.rootElement elementsForName:@"Row"];
        for(GDataXMLElement * oneXmlRow in Rows)
        {
            AboutRow * newRow = [[AboutRow alloc] init];
            GDataXMLNode * BgNode = [oneXmlRow attributeForName:@"Background"];
            [newRow setBackground:[BgNode stringValue]];
            GDataXMLNode * ImageNode = [oneXmlRow attributeForName:@"Image"];
            [newRow setImage:[ImageNode stringValue]];
            GDataXMLNode * qnameNode = [oneXmlRow attributeForName:@"qname"];
            [newRow setQname:[qnameNode stringValue]];
            GDataXMLNode * TextNode = [oneXmlRow attributeForName:@"Text"];
            [newRow setText:[TextNode stringValue]];
            [XmlRows addObject:newRow];
            //NSLog(@"Bg:%@,Image:%@,qname:%@,Text:%@",newRow.Background,newRow.Image,newRow.qname,newRow.Text);
        }
        
        
    }
    
}

@end
