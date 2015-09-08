//
//  ShareTools.m
//  TTravel
//
//  Created by ＴＭＳ 景翊科技 on 13/8/10.
//
//

#import "ShareTools.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#import <CFNetwork/CFNetwork.h>
#include <netinet/in.h>

@implementation ShareTools


+ (UIImage *) setImage:(UIImage *)image withAlpha:(CGFloat)alpha{
    
    // Create a pixel buffer in an easy to use format
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    UInt8 * m_PixelBuf = malloc(sizeof(UInt8) * height * width * 4);
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(m_PixelBuf, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    //alter the alpha
    unsigned long length = height * width * 4;
    for (int i=0; i<length; i+=4)
    {
        m_PixelBuf[i+3] =  255*alpha;
    }
    
    
    //create a new image
    CGContextRef ctx = CGBitmapContextCreate(m_PixelBuf, width, height,
                                             bitsPerComponent, bytesPerRow, colorSpace,
                                             kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGImageRef newImgRef = CGBitmapContextCreateImage(ctx);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(ctx);
    free(m_PixelBuf);
    
    UIImage *finalImage = [UIImage imageWithCGImage:newImgRef];
    CGImageRelease(newImgRef);
    
    return finalImage;
}
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
+ (NSString *) GetUTF8Encode:(NSString *)SourceStr
{
    NSMutableString * sb=[[[NSMutableString alloc]init ] autorelease];
    
    NSData * data = [SourceStr dataUsingEncoding:NSUTF8StringEncoding];
    char * UTF8Bs = (char *)[data bytes];
    for(int i=0;i<[data length];i++){
        [sb appendFormat:@"%d,",UTF8Bs[i]  ];
    }
    return [NSString stringWithFormat:@"%@",sb];
}
+ (NSString *) GetUTF8Dncode:(NSString *)SourceStr
{
    
    NSArray * BytesArray = [SourceStr componentsSeparatedByString:@","];
    char * UTF8Bs = malloc(sizeof(char) * [BytesArray count] -1);
    for(int i=0;i<[BytesArray count];i++)
    {
        NSString * oneByte = [BytesArray objectAtIndex:i];
        int b = [oneByte intValue];
        UTF8Bs[i] = b;
    }
    NSString * DecodeStr = [[NSString alloc] initWithUTF8String:UTF8Bs];
    free(UTF8Bs);
    return DecodeStr;
    
}
+ (void) setViewToFullScreen:(UIView *)view
{
    double SystemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if(SystemVersion > 7.0)
    {
        [view setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    }
    else
    {
        [view setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] applicationFrame].size.width, [[UIScreen mainScreen] applicationFrame].size.height)];
    }
}
+ (BOOL) connectedToNetwork
{
    // Create zero addy
	struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;
	// Recover reachability flags
	SCNetworkReachabilityRef defaultRouteReachability =SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
	SCNetworkReachabilityFlags flags;
	BOOL didRetrieveFlags =SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
	CFRelease(defaultRouteReachability);
	if (!didRetrieveFlags)
	{
		printf("Error. Could not recover network reachability flags\n");
		return 0;
	}
	BOOL isReachable = flags & kSCNetworkFlagsReachable;
	BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
	return (isReachable && !needsConnection) ? YES : NO;
}

@end
