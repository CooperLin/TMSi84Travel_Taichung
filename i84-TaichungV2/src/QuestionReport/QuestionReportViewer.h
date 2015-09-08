//
//  QuestionReportViewer.h
//  i84TC
//
//  Created by ＴＭＳ 景翊科技 on 2013/11/21.
//
//

#import <UIKit/UIKit.h>
#import "CoreLocation/CoreLocation.h"
#import "CoreLocation/CLLocationManagerDelegate.h"
#import "SilderMenuView.h"

@interface QuestionReportViewer : UIViewController<
    UITextFieldDelegate
    ,UITextViewDelegate
    ,UIImagePickerControllerDelegate
    ,CLLocationManagerDelegate
    ,SilderMenuDelegate>
{
    IBOutlet UIView * HeadV;
    IBOutlet UILabel * TitleLbl;
    IBOutlet UIButton * LeftMenuBtn;
    IBOutlet UIButton * BackBtn;
    
    IBOutlet UIView * ContentV;
    
    IBOutlet UIView * MainBtnView;
    IBOutlet UIButton * InfoErrorBtn;
    IBOutlet UIButton * StopCrashBtn;
    IBOutlet UIButton * LedNoLightBtn;
    IBOutlet UIButton * OtherBtn;
    
    IBOutlet UIView * ReportView;
    IBOutlet UIView * PhotoView;
    IBOutlet UIImageView * PhotoIv;
    IBOutlet UITextField * ReportNameTf;
    IBOutlet UITextField * ReportEMailTf;
    IBOutlet UITextField * ReportStopTf;
    IBOutlet UITextView * ReportContentTv;
    
    IBOutlet UIView * ReportSuccessV;
}
#define TmpQuestionImage [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"QuestionReport.jpg"]
#define QuestionReportAPI @"http://citybus.taichung.gov.tw/ibus/TCCG_StopSys/ajaxProcess/phoneAPI.aspx"

@property (nonatomic,retain) IBOutlet UIView * HeadV;
@property (nonatomic,retain) IBOutlet UILabel * TitleLbl;
@property (nonatomic,retain) IBOutlet UIButton * LeftMenuBtn;
@property (nonatomic,retain) IBOutlet UIButton * BackBtn;

@property (nonatomic,retain) IBOutlet UIView * ContentV;

@property (nonatomic,retain) IBOutlet UIView * MainBtnView;
@property (nonatomic,retain) IBOutlet UIButton * InfoErrorBtn;
@property (nonatomic,retain) IBOutlet UIButton * StopCrashBtn;
@property (nonatomic,retain) IBOutlet UIButton * LedNoLightBtn;
@property (nonatomic,retain) IBOutlet UIButton * OtherBtn;

@property (nonatomic,retain) IBOutlet UIView * ReportView;
@property (nonatomic,retain) IBOutlet UIView * PhotoView;
@property (nonatomic,retain) IBOutlet UIImageView * PhotoIv;
@property (nonatomic,retain) IBOutlet UITextField * ReportNameTf;
@property (nonatomic,retain) IBOutlet UITextField * ReportEMailTf;
@property (nonatomic,retain) IBOutlet UITextField * ReportStopTf;
@property (nonatomic,retain) IBOutlet UITextView * ReportContentTv;
@property (strong, nonatomic) IBOutlet UILabel *LabelReporter;
@property (strong, nonatomic) IBOutlet UILabel *LabelReporterEMail;
@property (strong, nonatomic) IBOutlet UILabel *LabelStopName;
@property (strong, nonatomic) IBOutlet UILabel *LabelContent;
@property (strong, nonatomic) IBOutlet UILabel *LabelTakePic;
@property (strong, nonatomic) IBOutlet UIButton *BtnTakePic;
@property (strong, nonatomic) IBOutlet UIButton *BtnChoosePic;
@property (strong, nonatomic) IBOutlet UIButton *BtnReport;

@property (nonatomic,retain) IBOutlet UIView * ReportSuccessV;

- (IBAction) LeftMenuBtnClickEvent:(id)sender;

-(IBAction) MainBtnsClickEvent:(id)sender;
-(IBAction) SelectPhotoLibraryBtnClickEvent:(id)sender;
-(IBAction) BackMainBtnVBtnClickEvent:(id)sender;
-(IBAction) PhotoClickEvent:(id) sender;
-(IBAction) SendBtnClickEvent:(id)sender;
@end
