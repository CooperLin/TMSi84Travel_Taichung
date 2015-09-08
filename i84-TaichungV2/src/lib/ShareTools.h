//
//  ShareTools.h
//  TTravel
//
//  Created by ＴＭＳ 景翊科技 on 13/8/10.
//
//

#import <Foundation/Foundation.h>

@interface ShareTools : NSObject


+ (UIImage *) setImage:(UIImage *)image withAlpha:(CGFloat)alpha;
+ (UIImage *) imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
+ (NSString *) GetUTF8Encode:(NSString *)SourceStr;
+ (NSString *) GetUTF8Dncode:(NSString *)SourceStr;
+ (void) setViewToFullScreen:(UIView *)view;

+ (BOOL) connectedToNetwork;
@end
