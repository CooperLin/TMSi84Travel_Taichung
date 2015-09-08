//
//  SilderMenuView.m
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/3/3.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "SilderMenuView.h"
#import "AppDelegate.h"

#define kDefaultHeightTW 33
#define kDefaultHeightUS 40

@implementation SilderMenuView

@synthesize SilderDelegate;

- (id) init
{
    self = [super init];
    if (self) {
        [self setBackgroundColor:[UIColor grayColor]];
        [self setDataSource:self];
        [self setDelegate:self];
        [self setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        CGRect frame = CGRectMake(-120, 0, 120, 568);
        [self setFrame:frame];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor grayColor]];
        [self setDataSource:self];
        [self setDelegate:self];
        [self setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        frame.origin.x = -1 * frame.size.width ;
        [self setFrame:frame];
    }
    return self;
}

- (void) insertItem:(NSDictionary *) insertItem
{
    if([insertItem objectForKey:@"icon"] != nil
       &&[insertItem objectForKey:@"title"] != nil
       && [insertItem objectForKey:@"item"] != nil)
    {
        [Items addObject:insertItem];
        if([[NSThread currentThread] isMainThread])
        {
            [self reloadData];
        }
        else
        {
            [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
        }
    }
    
}
- (void) removeItem:(NSDictionary *) removeItem
{
    [Items removeObject:removeItem];
    if([[NSThread currentThread] isMainThread])
    {
        [self reloadData];
    }
    else
    {
        [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
    }
}
- (void) setItemsByPlistName:(NSString *)PlistName
{
    NSArray * Source = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:PlistName ofType:@"plist"]];
    if(Items == nil)
    {
        Items = [[NSMutableArray alloc] init];
    }
    for(NSDictionary * oneDict in Source)
    {
        if([oneDict objectForKey:@"icon"] != nil
           && [oneDict objectForKey:@"title"] != nil
           && [oneDict objectForKey:@"item"] != nil)
        {
            [Items addObject:oneDict];
        }
    }
    if([[NSThread currentThread] isMainThread])
    {
        [self reloadData];
    }
    else
    {
        [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
    }
}
- (void) SilderShow
{
    if([[NSThread currentThread] isMainThread])
    {
        CGRect frame = self.frame;
        if(frame.origin.x == frame.size.width * -1)
        {
            frame.origin.x = 0;
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.6];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(ShowFinish:finished:context:)];
            [self setFrame:frame];
            [UIView commitAnimations];
        }
    }
    else
    {
        [self performSelectorOnMainThread:@selector(SilderShow) withObject:nil waitUntilDone:YES];
        return;
    }
}
- (void) SilderHidden
{
    if([[NSThread currentThread] isMainThread])
    {
        CGRect frame = self.frame;
        if(frame.origin.x == 0 )
        {
            frame.origin.x = -1 * frame.size.width;
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.6];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(HiddenFinish:finished:context:)];
            [self setFrame:frame];
            [UIView commitAnimations];
        }
    }
    else
    {
        [self performSelectorOnMainThread:@selector(SilderHidden) withObject:nil waitUntilDone:YES];
        return;
    }
}
- (void) ShowFinish:(NSString *)animationID finished:(NSNumber *)finished context:(void *) context
{
    if(SilderDelegate != nil)
    {
        [SilderDelegate SilderMenuShowedEvent];
    }
}
- (void) HiddenFinish:(NSString *)animationID finished:(NSNumber *)finished context:(void *) context
{
    if(SilderDelegate != nil)
    {
        [SilderDelegate SilderMenuHiddenedEvent];
    }
}

#pragma mark TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 33.0f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(Items == nil)
    {
        return 0;
    }
    else
    {
        return [Items count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SilderMenuCell"];
    UIImageView * Iv;
    UILabel * TitleLbl;
    
    NSInteger cellLabelHeight;
    
    NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"US"];
    NSRange range = [appDelegate.LocalizedTable rangeOfCharacterFromSet:cset];
    if (range.location == NSNotFound) {
        // no ( or ) in the string
        cellLabelHeight = kDefaultHeightTW;
    } else {
        // ( or ) are present
        cellLabelHeight = kDefaultHeightUS;
    }
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SilderMenuCell"] ;
        CGRect cellframe = cell.frame;
        cellframe.size.height = cellLabelHeight;
        cellframe.size.height = 33;
        cellframe.size.width = tableView.frame.size.width;
        [cell setFrame:cellframe];
        [cell setBackgroundColor:[UIColor clearColor]];
        Iv = [[UIImageView alloc] initWithFrame:CGRectMake(2, 2, 29, 29)];
        [Iv setTag:7];
        
        TitleLbl = [[UILabel alloc] initWithFrame:CGRectMake(33, 0,cellframe.size.width-33,cellLabelHeight)];
        [TitleLbl setFont:[UIFont systemFontOfSize:15.0f]];
        [TitleLbl setTextColor:[UIColor whiteColor]];
        [TitleLbl setBackgroundColor:[UIColor clearColor]];
        [TitleLbl setTag:8];
        [cell.contentView addSubview:Iv];
        [cell.contentView addSubview:TitleLbl];
    }
    else
    {
        for(UIView * oneView in cell.contentView.subviews)
        {
            if(oneView.tag == 7)
            {
                Iv = (UIImageView *)oneView;
            }
            if(oneView.tag == 8)
            {
                TitleLbl = (UILabel *)oneView;
            }
        }
    }
    
    NSDictionary * oneItem = (NSDictionary *) [Items objectAtIndex:[indexPath row]];
    [Iv setImage:[UIImage imageNamed:(NSString *)[oneItem objectForKey:@"icon"]]];
    [TitleLbl setText:(NSString *)[oneItem objectForKey:@"title"]];
    
    NSString *keyValue = [NSString stringWithFormat:@"%@",[oneItem objectForKey:@"title"]];
    keyValue = [keyValue stringByAppendingString:@"_title"];
    [TitleLbl setText:NSLocalizedStringFromTable(keyValue, appDelegate.LocalizedTable, nil)];
    TitleLbl.textAlignment = NSTextAlignmentCenter;
//    [cell.imageView setImage:[UIImage imageNamed:(NSString *)[oneItem objectForKey:@"icon"]]];
//    [cell.textLabel setText:(NSString *)[oneItem objectForKey:@"title"]];
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary * oneItem = (NSDictionary *) [Items objectAtIndex:[indexPath row]];
    if(SilderDelegate != nil)
    {
        [SilderDelegate ItemSelectedEvent:(NSString *)[oneItem objectForKey:@"item"]];
    }
}

@end
