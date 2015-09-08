//
//  QuestionReportViewer.m
//  i84TC
//
//  Created by ＴＭＳ 景翊科技 on 2013/11/21.
//
//

#import "QuestionReportViewer.h"
#import "AppDelegate.h"

#import "ShareTools.h"

#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>
#import <CFNetwork/CFNetwork.h>
#import "ASIFormDataRequest.h"

#import <CoreLocation/CoreLocation.h>
#import "MBProgressHUD.h"

@interface QuestionReportViewer ()
{
//    UIImagePickerController * imgPicker;
    int SelectKind;
    UIScrollView * ReportSv;
    UITapGestureRecognizer * recognizer;
    
    CLLocation * location ;
    
    MBProgressHUD * HUD;
    
    SilderMenuView * SilderMenu;
    CLLocationManager *locmanager;
}
@property (nonatomic, strong) UIView *viewCover;
@end

@implementation QuestionReportViewer

@synthesize HeadV,TitleLbl,LeftMenuBtn,ContentV,BackBtn;

@synthesize MainBtnView,InfoErrorBtn,StopCrashBtn,LedNoLightBtn,OtherBtn;
@synthesize ReportView,PhotoView,PhotoIv,ReportNameTf,ReportEMailTf,ReportStopTf,ReportContentTv;
@synthesize ReportSuccessV;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if(SystemVersion > 7.0)
    {
        [self.view setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    }
    else
    {
        [self.view setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] applicationFrame].size.width, [[UIScreen mainScreen] applicationFrame].size.height)];
    }
    
    CGRect MainBtnViewFrame = MainBtnView.frame;
    CGRect ContentVFrame = ContentV.frame;
    
    MainBtnViewFrame.origin.y = (ContentVFrame.size.height - MainBtnViewFrame.size.height)/2;
    [MainBtnView setFrame:MainBtnViewFrame];
    
    [ContentV addSubview:MainBtnView];
    ContentVFrame.origin.x = 0;
    ContentVFrame.origin.y = 0;
    CGRect ReportViewFrame = ReportView.frame;
    ReportViewFrame.size.height = ReportViewFrame.size.height + 30;
    
    [ReportView setFrame:ReportViewFrame];
    
    ReportSv = [[UIScrollView alloc] initWithFrame:ContentVFrame];
    [ReportSv setShowsHorizontalScrollIndicator:NO];
    [ReportSv setShowsVerticalScrollIndicator:NO];
    [ReportSv setContentSize:ReportView.frame.size];
    [ReportSv addSubview:ReportView];
    
    [ContentV addSubview:ReportSv];
    [ReportSv setHidden:YES];
    
    [ContentV addSubview:ReportSuccessV];
    [ReportSuccessV setHidden:YES];
    
    NSUserDefaults  * userDefault = [NSUserDefaults standardUserDefaults];
    NSString * Name = [userDefault objectForKey:@"QuestionReportName"];
    NSString * EMail = [userDefault objectForKey:@"QuestionReportEMail"];
    NSString * StopName = [userDefault objectForKey:@"QuestionReportStopName"];
    NSString * Content = [userDefault objectForKey:@"QuestionReportContent"];
    NSString * LastPhotoDate = [userDefault objectForKey:@"QuestionReportPhotoDate"];
    if(Name != nil)
    {
        [ReportNameTf setText:Name];
    }
    if(EMail != nil)
    {
        [ReportEMailTf setText:EMail];
    }
    if(StopName != nil)
    {
        [ReportStopTf setText:StopName];
    }
    if(Content != nil)
    {
        [ReportContentTv setText:Content];
    }
    if(LastPhotoDate != nil)
    {
        NSFileManager * fileManage = [[NSFileManager alloc] init];
        if([fileManage fileExistsAtPath:TmpQuestionImage])
        {
            NSDate * ToDay = [[NSDate alloc] init];
            NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyyMMdd"];
            NSString * ToDayStr = [formatter stringFromDate:ToDay];
            if([ToDayStr compare:LastPhotoDate] != 0)
            {
                [fileManage removeItemAtPath:TmpQuestionImage error:nil];
            }

        }

        
    }
    recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ReportSuccessVClickEvent:)] ;
    [recognizer setNumberOfTapsRequired:1];
    [recognizer setNumberOfTouchesRequired:1];
    [ReportSuccessV addGestureRecognizer:recognizer];
    
    [self _showViewCover:NO];

    SilderMenu = [[SilderMenuView alloc] initWithFrame:CGRectMake(0, 0, 135, self.view.frame.size.height)];
    [SilderMenu setSilderDelegate:self];
    [ContentV addSubview:SilderMenu];
    [SilderMenu setItemsByPlistName:@"LeftMenu"];
    
    [BackBtn setAlpha:0.0f];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSFileManager * fileManage = [[NSFileManager alloc] init];
    [self _showI18N];
    if([fileManage fileExistsAtPath:TmpQuestionImage])
    {
        [PhotoIv setImage:[UIImage imageWithData:[NSData dataWithContentsOfFile:TmpQuestionImage]]];
    }
    
    locmanager = [[CLLocationManager alloc] init];
    [locmanager setDelegate:self];
    [locmanager setDesiredAccuracy:kCLLocationAccuracyBest];
    [locmanager startUpdatingLocation];

}

-(void)_showI18N
{
    [self.InfoErrorBtn setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"question_Inaccurate_btn.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    [self.StopCrashBtn setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"question_damage_btn.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    [self.LedNoLightBtn setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"question_led_btn.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    [self.OtherBtn setImage:[UIImage imageNamed:NSLocalizedStringFromTable(@"question_other_btn.png", appDelegate.LocalizedTable, nil)] forState:UIControlStateNormal];
    TitleLbl.text = NSLocalizedStringFromTable(@"問題回報", appDelegate.LocalizedTable, nil);
    self.ReportNameTf.placeholder = NSLocalizedStringFromTable(@"請輸入通報者", appDelegate.LocalizedTable, nil);
    self.ReportEMailTf.placeholder = NSLocalizedStringFromTable(@"請輸入E-Mail", appDelegate.LocalizedTable, nil);
    self.ReportStopTf.placeholder = NSLocalizedStringFromTable(@"請輸入站牌名稱", appDelegate.LocalizedTable, nil);
    self.LabelReporter.text = NSLocalizedStringFromTable(@"● 通報者", appDelegate.LocalizedTable, nil);
    self.LabelReporterEMail.text = NSLocalizedStringFromTable(@"● 通報者E-Mail", appDelegate.LocalizedTable, nil);
    self.LabelStopName.text = NSLocalizedStringFromTable(@"● 站牌名稱", appDelegate.LocalizedTable, nil);
    self.LabelContent.text = NSLocalizedStringFromTable(@"● 通報內容概述", appDelegate.LocalizedTable, nil);
    self.LabelTakePic.text = NSLocalizedStringFromTable(@"拍照", appDelegate.LocalizedTable, nil);
    self.LabelTakePic.adjustsFontSizeToFitWidth = YES;
    [self.BtnTakePic setTitle:NSLocalizedStringFromTable(@"拍照", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    self.BtnTakePic.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.BtnChoosePic setTitle:NSLocalizedStringFromTable(@"選擇照片", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    self.BtnChoosePic.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.BtnReport setTitle:NSLocalizedStringFromTable(@"回報", appDelegate.LocalizedTable, nil) forState:UIControlStateNormal];
    self.BtnReport.titleLabel.adjustsFontSizeToFitWidth = YES;
    
}

- (IBAction) LeftMenuBtnClickEvent:(id)sender
{
    /*
     edit Cooper 2015/08/20
     0807buglist 台中第四項
     台中用額外的lib，所以只好一頁一頁改…
     */
    if([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        [SilderMenu SilderHidden];
        [self _showViewCover:NO];
        return;
    }
    UIButton * Btn = (UIButton *)sender;
    if(![Btn isSelected])
    {
        [SilderMenu SilderShow];
        [self _showViewCover:YES];
    }
    else
    {
        [SilderMenu SilderHidden];
        [self _showViewCover:NO];
    }
    [Btn setSelected:![Btn isSelected]];
}
/*
 edit Cooper 2015/08/20
 0807buglist 台中第四項
 台中用額外的lib，所以只好一頁一頁改…
 */
-(void)_showViewCover:(BOOL)bb
{
    if(!self.viewCover){
        self.viewCover = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        self.viewCover.backgroundColor = [UIColor grayColor];
        self.viewCover.alpha = 0.4;
        [self.viewCover addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(LeftMenuBtnClickEvent:)]];
        [ContentV addSubview:self.viewCover];
    }
    [self.viewCover setHidden:!bb];
}
-(IBAction) MainBtnsClickEvent:(id)sender
{
    [MainBtnView setHidden:YES];
    [ReportSv setHidden:NO];
    NSString * Title = nil;
    if(sender == InfoErrorBtn)
    {
        Title = NSLocalizedStringFromTable(@"資訊不準確",appDelegate.LocalizedTable,nil);
        SelectKind =  0;
    }
    else if(sender == StopCrashBtn)
    {
        Title = NSLocalizedStringFromTable(@"站牌毀損",appDelegate.LocalizedTable,nil);
        SelectKind = 1;
    }
    else if(sender == LedNoLightBtn)
    {
        Title = NSLocalizedStringFromTable(@"LED燈不亮",appDelegate.LocalizedTable,nil);
        SelectKind = 2;
    }
    else if(sender == OtherBtn)
    {
        Title = NSLocalizedStringFromTable(@"其他",appDelegate.LocalizedTable,nil);
        SelectKind = 4;
    }
    [TitleLbl setText:Title];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.6];
    [UIView setAnimationDelegate:self];
    [BackBtn setAlpha:1.0f];
    [UIView commitAnimations];


}
-(IBAction) SelectPhotoLibraryBtnClickEvent:(id)sender
{
    UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init] ;
    imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imgPicker.delegate = self;
    imgPicker.allowsEditing = NO;
    [self presentModalViewController:imgPicker animated:YES];
}
-(IBAction) BackMainBtnVBtnClickEvent:(id)sender
{
    [MainBtnView setHidden:NO];
    [ReportSv setHidden:YES];
    
    [TitleLbl setText:NSLocalizedStringFromTable(@"問題回報",appDelegate.LocalizedTable,nil)];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.6];
    [UIView setAnimationDelegate:self];
    [BackBtn setAlpha:0.0f];
    [UIView commitAnimations];
    [ReportNameTf resignFirstResponder];
    [ReportStopTf resignFirstResponder];
    [ReportEMailTf resignFirstResponder];
    [ReportContentTv resignFirstResponder];
}

- (IBAction) PhotoClickEvent:(id) sender
{
    
    UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init] ;
    imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imgPicker.showsCameraControls = YES;
    imgPicker.delegate = self;
    imgPicker.allowsEditing = NO;
    

    [self presentModalViewController:imgPicker animated:YES];
}
-(IBAction) SendBtnClickEvent:(id)sender
{
    NSString * Stop = [ReportStopTf text];
    NSString * Name = [ReportNameTf text];
    NSString * Email = [ReportEMailTf text];
    NSString * Content = [ReportContentTv text];
    
    NSMutableString * ErrorSb = [[NSMutableString alloc] init];
    if(Stop == nil || [Stop length] == 0)
    {
        [ErrorSb appendString:NSLocalizedStringFromTable(@"尚未填寫回報站牌!\n",appDelegate.LocalizedTable,nil)];
    }
    if(Name == nil || [Name length] == 0)
    {
        [ErrorSb appendString:NSLocalizedStringFromTable(@"尚未填寫回報人!\n",appDelegate.LocalizedTable,nil)];
    }
    if(Email == nil || [Email length] == 0)
    {
        [ErrorSb appendString:NSLocalizedStringFromTable(@"尚未填寫回報EMail!\n",appDelegate.LocalizedTable,nil)];
    }
    if(Content == nil || [Content length] == 0)
    {
        [ErrorSb appendString:NSLocalizedStringFromTable(@"尚未填寫回報內容!\n",appDelegate.LocalizedTable,nil)];
    }
    NSFileManager * fileManage = [[NSFileManager alloc] init];
    if([ErrorSb length] > 0)
    {
        UIAlertView * Alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"請先填寫欄位",appDelegate.LocalizedTable,nil) message:ErrorSb delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確定",appDelegate.LocalizedTable,nil) otherButtonTitles:nil, nil] ;
        [Alert show];
        return;
    }
    else
        if
        (![fileManage fileExistsAtPath:TmpQuestionImage])
    {
        UIAlertView * Alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"請提供照片",appDelegate.LocalizedTable,nil) message:NSLocalizedStringFromTable(@"請協助使用拍照功能記錄問題相片",appDelegate.LocalizedTable,nil) delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確定",appDelegate.LocalizedTable,nil) otherButtonTitles:nil, nil] ;
        [Alert show];
    }
    else
    {
        [self SendReportRequest];
    }
    
}
-(void) ReportSuccessVClickEvent:(UITapGestureRecognizer *)recognizer
{
    NSUserDefaults  * userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault removeObjectForKey:@"QuestionReportStopName"];
    [userDefault removeObjectForKey:@"QuestionReportContent"];
    [userDefault removeObjectForKey:@"QuestionReportPhotoDate"];
    [userDefault synchronize];
    NSFileManager * fileManage = [[NSFileManager alloc] init];
    if([fileManage fileExistsAtPath:TmpQuestionImage])
    {
        [fileManage removeItemAtPath:TmpQuestionImage error:nil];
    }
    ReportStopTf.text = @"";
    ReportContentTv.text = @"";
    [ReportSuccessV setHidden:YES];
    [ReportSv setHidden:YES];
    [MainBtnView setHidden:NO];
}
- (void) ShowReportSuccessV
{
    [ReportSuccessV setHidden:NO];

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
    [LeftMenuBtn setSelected:YES];
}
#pragma mark Alert

- (void) ShowAlert:(NSString *)Message
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"發生錯誤，請稍後再試",appDelegate.LocalizedTable,nil) message:Message delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確定",appDelegate.LocalizedTable,nil) otherButtonTitles:nil, nil] ;
    [alert show];
}

#pragma mark HUD
-(void)ShowHUD{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	HUD = [[MBProgressHUD alloc] initWithWindow:window];
	[window addSubview:HUD];
    HUD.labelText = NSLocalizedStringFromTable(@"回報上傳中...",appDelegate.LocalizedTable,nil);

	[HUD show:YES];
	
}
-(void)CloseHUD{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[HUD hide:YES];
	[HUD removeFromSuperview];
	
}
#pragma mark UITextFieldDelegate
-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [ReportNameTf resignFirstResponder];
    [ReportEMailTf resignFirstResponder];
    [ReportStopTf resignFirstResponder];

    NSUserDefaults  * userDefault = [NSUserDefaults standardUserDefaults];
    if([ReportNameTf.text length] > 0)
    {
        [userDefault setObject:ReportNameTf.text forKey:@"QuestionReportName"];
    }
    if([ReportEMailTf.text length] > 0)
    {
        [userDefault setObject:ReportEMailTf.text forKey:@"QuestionReportEMail"];
    }
    if([ReportStopTf.text length] > 0)
    {
        [userDefault setObject:ReportStopTf.text forKey:@"QuestionReportStopName"];
    }
    [userDefault synchronize];
    return YES;
}
#pragma mark UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    CGRect ReportVFrame = ReportView.frame;
    ReportVFrame.size.height = ReportVFrame.size.height + 400;
    [ReportView setFrame:ReportVFrame];
    [ReportSv setContentSize:ReportVFrame.size];
    CGPoint point = ReportSv.contentOffset;
    point.y = point.y + 250;
    [ReportSv setContentOffset:point animated:YES];
}
-(void) textViewDidEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];
    CGRect ReportVFrame = ReportView.frame;
    ReportVFrame.size.height = ReportVFrame.size.height - 400;
    [ReportView setFrame:ReportVFrame];
    [ReportSv setContentSize:ReportVFrame.size];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if([text isEqualToString:@"\n"])
    {
        [ReportContentTv resignFirstResponder];
        NSUserDefaults  * userDefault = [NSUserDefaults standardUserDefaults];
        if([ReportContentTv.text length] > 0)
        {
            [userDefault setObject:ReportContentTv.text forKey:@"QuestionReportContent"];
        }
        [userDefault synchronize];
    }
    return YES;
}

#pragma mark ImagePicker
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage * image = [info objectForKey:UIImagePickerControllerOriginalImage];
    UIGraphicsBeginImageContext(CGSizeMake(720,960));
    [image drawInRect:CGRectMake(0, 0, 720, 960)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(image != nil)
    {
        [UIImageJPEGRepresentation(image, 1.0) writeToFile:TmpQuestionImage atomically:YES];
        
        [PhotoIv setImage:image];
        
        [picker dismissModalViewControllerAnimated:YES];
        
        NSDate * ToDay = [[NSDate alloc] init];
        NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyyMMdd"];
        NSString * ToDayStr = [formatter stringFromDate:ToDay];
        
        NSUserDefaults  * userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault setObject:ToDayStr forKey:@"QuestionReportPhotoDate"];
        [userDefault synchronize];

    }
}
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    //[picker dismissModalViewControllerAnimated:YES];
}
#pragma mark Location

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    location = [newLocation copy];
    [locmanager stopUpdatingLocation];
}
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if([error code] == kCLErrorDenied)
    {
        NSString *errorMessage = [error localizedDescription];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"請打開GPS",appDelegate.LocalizedTable,nil) message:errorMessage delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"OK",appDelegate.LocalizedTable,nil) otherButtonTitles:nil];
        [alertView show];
    }
    else
    {
        NSLog(@"GPS Error Code %d",[error code]);
        NSLog(@"%@",[error localizedDescription]);
    }
}
#pragma mark 網路
- (void) SendReportRequest
{
    if(![ShareTools connectedToNetwork])
    {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"請先檢查網路狀態",appDelegate.LocalizedTable,nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"確定",appDelegate.LocalizedTable,nil) otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    [self performSelectorOnMainThread:@selector(ShowHUD) withObject:nil waitUntilDone:NO];
    NSString * Stop = [ReportStopTf text];
    NSString * Name = [ReportNameTf text];
    NSString * Email = [ReportEMailTf text];
    NSString * Content = [ReportContentTv text];
    float Lon = 0.0,Lat = 0.0;
    if(location != nil)
    {
        Lon = [location coordinate].longitude;
        Lat = [location coordinate].latitude;
    }
    
//    
//    NSString * UrlStr = [NSString stringWithFormat:QuestionReportAPI
//                         ,[ShareTools GetUTF8Encode:Stop]
//                         ,[ShareTools GetUTF8Encode:Name]
//                         ,[ShareTools GetUTF8Encode:Email]
//                         ,[ShareTools GetUTF8Encode:Content]
//                         ,Lon,Lat];
//    NSString * DataStr = [ShareTools GetUTF8Encode: [NSString stringWithFormat:@"%@,_%@,_%@,_%d,_%@,_%.6f,_%.6f",Stop,Name,Email,SelectKind,Content,Lon,Lat]];
    
    NSString * DataStr = [NSString stringWithFormat:@"%@,_%@,_%@,_%@,_%@,_%@,_%@"
                          ,[ShareTools GetUTF8Encode:Stop]
                          ,[ShareTools GetUTF8Encode:Name]
                          ,[ShareTools GetUTF8Encode:Email]
                          ,[ShareTools GetUTF8Encode:[NSString stringWithFormat:@"%d",SelectKind]]
                          ,[ShareTools GetUTF8Encode:Content]
                          ,[ShareTools GetUTF8Encode:[NSString stringWithFormat:@"%.6f",Lon]]
                          ,[ShareTools GetUTF8Encode:[NSString stringWithFormat:@"%.6f",Lat]]
                          ];
//
//    NSString * UrlStr = [NSString stringWithFormat:QuestionReportAPI,DataStr];
#ifdef LogOut
    NSLog(@"Report Url:%@",QuestionReportAPI);
#endif
    
    ASIFormDataRequest * Request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:QuestionReportAPI]];
    [Request setDelegate:self];
    [Request setDidFinishSelector:@selector(ReportRequestFinsih:)];
    [Request setDidFailSelector:@selector(ReportRequestFail:)];
    [Request setTimeOutSeconds:60.0f*5];
    [Request setPostValue:DataStr forKey:@"Data"];
    //[Request addRequestHeader:@"Data" value:DataStr];
    NSFileManager * fileManage = [[NSFileManager alloc] init];
    if([fileManage fileExistsAtPath:TmpQuestionImage])
    {
        [Request setFile:TmpQuestionImage forKey:@"Image"];
    }
    [Request startAsynchronous];

}
-(void) ReportRequestFinsih:(ASIFormDataRequest *) Request
{
#ifdef LogOut
    NSLog(@"Response:%@",[Request responseString]);
#endif
    if([[Request responseString] hasPrefix:@"error"])
    {
        [self performSelectorOnMainThread:@selector(ShowAlert:) withObject:[[Request responseString] copy] waitUntilDone:NO];
        [self ReportRequestFail:Request];
        return;
    }
    else
    {
        [self performSelectorOnMainThread:@selector(ShowReportSuccessV) withObject:nil waitUntilDone:NO];
        NSFileManager * fileManage = [[NSFileManager alloc] init];
        if([fileManage fileExistsAtPath:TmpQuestionImage])
        {
        [fileManage removeItemAtPath:TmpQuestionImage error:nil];
        }
        [PhotoIv setImage:nil];
    }
    [self performSelectorOnMainThread:@selector(CloseHUD) withObject:nil waitUntilDone:NO];
}
-(void) ReportRequestFail:(ASIFormDataRequest *) Request
{
    [self performSelectorOnMainThread:@selector(CloseHUD) withObject:nil waitUntilDone:NO];
}
@end
