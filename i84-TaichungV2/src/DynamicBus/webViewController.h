//
//  webViewController.h
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/5/9.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol WebViewDelegate <NSObject>
@required
//ask for start url NSString instance
-(NSString*)webViewStartUrlOnWebViewController:(id)webViewController;

@optional

@end
@interface webViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIWebView *webViewMain;
@property (strong, nonatomic) id <WebViewDelegate>delegate;
@end
