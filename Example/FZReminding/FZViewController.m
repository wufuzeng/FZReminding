//
//  FZViewController.m
//  FZReminding
//
//  Created by wufuzeng on 08/27/2019.
//  Copyright (c) 2019 wufuzeng. All rights reserved.
//

#import "FZViewController.h"

#import "FZReminding.h"

@interface FZViewController ()

@end

@implementation FZViewController

- (void)viewDidLoad{
    [super viewDidLoad];
}


-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    
    /*
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDate *date = [formatter dateFromString:@"2019-08-28 14:28:00"];
    */
    //  开始
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:120];
    // 提前一分钟结束
    NSDate *endDate = [NSDate dateWithTimeInterval:180 sinceDate:startDate];
    
    NSURL *url = [NSURL URLWithString:@"www.baidu.com"];
    
    /*
     添加事件提醒
     
    [FZUserEventReminder addEventWithIdentifier:nil
                             calendarIdentifier:nil
                                          title:@"标题222"
                                       location:@"地点"
                                          notes:@"备注"
                                           date:startDate
                                     alarmArray:@[@(-70),@(-50),@(-30),@(-10)]
                                     completion:^(BOOL granted, NSError * _Nonnull error) {

                                     }];
     */
    
    /**
     添加事件日历
     */
    [FZUserEventCalendar addEventWithIdentifier:nil
                             calendarIdentifier:nil
                                          title:@"标题222"
                                       location:@"地点"
                                          notes:@"备注"
                                            url:url
                                      startDate:startDate
                                        endDate:endDate
                                         allDay:NO
                                     alarmArray:@[@(-70),@(-50),@(-30),@(-10)]
                                     completion:^(BOOL granted, NSError * _Nonnull error) {

    }];
    
    
}




- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
