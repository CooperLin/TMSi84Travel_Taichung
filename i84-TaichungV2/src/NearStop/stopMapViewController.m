//
//  stopMapViewController.m
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/4/16.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "stopMapViewController.h"

@interface stopMapViewController ()
{
    PinAnnotation * annotationUser;
    PinAnnotation * annotationStop;
}
@end

@implementation stopMapViewController

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
    // Do any additional setup after loading the view from its nib.
}
-(void)viewWillAppear:(BOOL)animated
{
    [self.mapView setDelegate:self];
}
-(void)viewWillDisappear:(BOOL)animated
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView setDelegate:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    [self actSetMap];
}
-(void)actSetMap
{
    NSDictionary * dictionaryStop = [NSDictionary dictionaryWithDictionary:self.idSelectedStop];
    NSString * stringCoordinate = [dictionaryStop objectForKey:@"StopCoor"];
    NSString * stringLatitude = [[stringCoordinate componentsSeparatedByString:@","]objectAtIndex:1];
    NSString * stringLongtitude = [[stringCoordinate componentsSeparatedByString:@","]objectAtIndex:0];
 
    //設定圖標並加入
    PinAnnotation * annotation = [[PinAnnotation alloc]initWithCoordinate:CLLocationCoordinate2DMake(stringLatitude.doubleValue, stringLongtitude.doubleValue)];
    annotation.title = [NSString stringWithFormat:@"%@ %@",[dictionaryStop objectForKey:@"RouteName"],[dictionaryStop objectForKey:@"StopName"]];
//    annotation.subtitle = [NSString stringWithFormat:@"%@",[dictionaryStop objectForKey:@"RouteName"]];
    MKCoordinateSpan theSpan = MKCoordinateSpanMake(0.07, 0.07);
    MKCoordinateRegion theRegion = MKCoordinateRegionMake(annotation.coordinate,theSpan);
    [self.mapView setRegion:theRegion];
    
    [self.mapView addAnnotation:annotation];
}
-(void)actSetMapRegion
{
    //將圖標設為地圖中心
    CLLocationDegrees differenceLongitude = fabs(annotationUser.coordinate.longitude - annotationStop.coordinate.longitude);
    CLLocationDegrees differenceLatitude = fabs(annotationUser.coordinate.latitude - annotationStop.coordinate.latitude);
    CLLocationDegrees centerLongitude = (annotationUser.coordinate.longitude + annotationStop.coordinate.longitude)/2;
    CLLocationDegrees centerLatitude = (annotationUser.coordinate.latitude + annotationStop.coordinate.latitude)/2;
    
    MKCoordinateSpan theSpan = MKCoordinateSpanMake(differenceLatitude*1.2, differenceLongitude*1.2);
    MKCoordinateRegion theRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(centerLatitude, centerLongitude),theSpan);
    
    [self.mapView setRegion:theRegion animated:YES];
    
    [self.mapView selectAnnotation:annotationStop animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKPinAnnotationView * annotationView;
        //判斷Pin如果是目前位置就不修改
        if ([annotation isKindOfClass:[MKUserLocation class]])
        {
            annotationUser = annotation;
            annotationView = nil;
        }
        else
        {
            annotationStop = annotation;
            annotationView = [[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"annotationStop"];
        }

//    if (annotationStop && annotationUser)
//    {
//        [self actSetMapRegion];
//    }
    
//        MKPinAnnotationView *pinView = [[MKPinAnnotationView alloc]
//                                        initWithAnnotation:annotation reuseIdentifier:@"annotation"];
//        UIImage *image = [UIImage imageNamed:@"MapPin.png"];
//        UIImageView  *imageView = [[UIImageView alloc] initWithImage:image];
    
        //重設圖片大小與座標
//        imageView.frame = CGRectMake(0, 0, 30, 30);
    
        //設定PinView圖片
//        pinView.image = [UIImage imageNamed:@"MapPin.png"];
    
        //設定註解內的圖片
//        pinView.rightCalloutAccessoryView = imageView;
    
        //點擊時是否出現註解
        annotationView.canShowCallout = YES;
    return annotationView;
}
@end
