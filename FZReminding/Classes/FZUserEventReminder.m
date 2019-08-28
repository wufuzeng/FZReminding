//
//  FZUserEventReminder.m
//  FZReminding
//
//  Created by 吴福增 on 2019/8/27.
//

#import "FZUserEventReminder.h"

@implementation FZUserEventReminder

/**
 *  指定标识提醒事件
 *
 *  @param eventIdentifier  事件ID(标识符)
 */
+ (EKCalendarItem *)eventWithIdentifier:(NSString *)eventIdentifier{
    NSString *eIdentifier = [FZUserEventBase identifierWithKey:eventIdentifier];
    if (eIdentifier.length) {
        EKCalendarItem *item = [[FZUserEventBase sharedHelper].eventStore calendarItemWithIdentifier:eIdentifier];
        return item;
    }
    return nil;
}

/**
 *  查提醒事件(可查询一段时间内的事件)
 *
 *  @param startDate   开始时间
 *  @param endDate     结束时间
 *  @param title 标题，为空则都要查询
 *  @param calendarIdentifier  事件源(无，则为默认)
 */
+ (void)eventsWithStartDate:(NSDate *)startDate
                    endDate:(NSDate *)endDate
                      title:(NSString *)title
         calendarIdentifier:(NSString *)calendarIdentifier
                 completion:(void(^)(NSArray<EKReminder *> * reminders))completion{
    
    EKEventStore *eventStore = [FZUserEventBase sharedHelper].eventStore;
    /** 查询到所有的事件提醒事项 */
    NSArray<EKCalendar *> *calendars = [eventStore calendarsForEntityType:EKEntityTypeReminder];
    
    NSMutableArray *only3D = [NSMutableArray array];
    for (EKCalendar *calendar in calendars) {
        EKCalendarType type = calendar.type;
        // 工作、家庭和本地提醒事项
        if (type == EKCalendarTypeLocal || type == EKCalendarTypeCalDAV)  {
            if (calendarIdentifier.length) {
                NSString *cIdentifier = [FZUserEventBase identifierWithKey:calendarIdentifier];
                if ([calendar.calendarIdentifier isEqualToString:cIdentifier]){
                    [only3D addObject:calendar];
                }
            }else{
                [only3D addObject:calendar];
            }
        }
    }
    /** 过滤条件 */
    NSPredicate *predicate = [eventStore predicateForCompletedRemindersWithCompletionDateStarting:startDate ending:endDate calendars:only3D];
    /** 获取到范围内的所有提醒事件 */
    [eventStore fetchRemindersMatchingPredicate:predicate completion:^(NSArray<EKReminder *> * _Nullable reminders) {
        /** 按开始事件进行排序 */
        reminders = [reminders sortedArrayUsingSelector:@selector(compareStartDateWithEvent:)];
        if (title.length == 0) {
            NSMutableArray *onlyRequest = [NSMutableArray array];
            for (int i = 0; i < reminders.count; i++) {
                EKReminder *reminder = reminders[i];
                if (reminder.title && [reminder.title isEqualToString:title]) {
                    [onlyRequest addObject:reminder];
                }
            }
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(onlyRequest);
                });
            }
        }else{
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(reminders);
                });
            }
        }
    }];
}


/**
 *  添加提醒事项，实现闹铃提醒的功能
 *
 *  @param eventIdentifier     事件ID(标识符，用于区分提醒事项)
 *  @param calendarIdentifier  事件源(无，则为默认)
 *  @param title      事件标题
 *  @param location   事件位置
 *  @param notes      事件备注(传nil，则没有)
 *  @param date  提醒日期
 *  @param alarmArray 闹钟集合 (提醒时间数组，这个数组是按照秒计算的。相对开始时间间隔(单位秒))
 *  @param completion 回调方法
 */
+ (void)addEventWithIdentifier:(NSString * _Nullable )eventIdentifier
            calendarIdentifier:(NSString * _Nullable )calendarIdentifier
                         title:(NSString *)title
                      location:(NSString * _Nullable )location
                         notes:(NSString * _Nullable )notes
                          date:(NSDate *)date
                    alarmArray:(NSArray<NSNumber *> *)alarmArray
                    completion:(void(^)(BOOL granted, NSError *error))completion{
    
    EKEventStore * refetchStore = [FZUserEventBase sharedHelper].eventStore;
    __weak __typeof(refetchStore) weakStore = refetchStore;
    /** 申请提醒权限 */
    [FZUserEventBase accessForEventKitType:EKEntityTypeReminder
                                  result:^(BOOL granted,NSError *error) {
       __strong __typeof(weakStore) strongStore = weakStore;
       if (error) {
           [FZUserEventBase showAlert:@"添加失败，请稍后重试"];
           if (completion) {
               completion(granted,error);
           }
       }else{
           if (granted) {
               //创建一个提醒功能
               EKReminder *reminder = [EKReminder reminderWithEventStore:strongStore];
               //标题
               reminder.title = title;
               /** 地点 */
               reminder.location = location;
               /** 事件备注 */
               reminder.notes = notes;
               /**
                * 事件url
                * 提醒事项不能设置该属性，否则iPhone没有闹铃通知
                */
               //reminder.URL = url;
               
               /** EKSpanThisEvent 表示只影响当前事件。 */
               NSInteger flags = NSCalendarUnitYear |
                                 NSCalendarUnitMonth |
                                 NSCalendarUnitDay |
                                 NSCalendarUnitHour |
                                 NSCalendarUnitMinute |
                                 NSCalendarUnitSecond ;
               
               /** 日历系统时区 */
               NSCalendar *calendar = [NSCalendar currentCalendar];
               [calendar setTimeZone:[NSTimeZone systemTimeZone]];
               /** 日期系统时区 */
               NSDateComponents* dateComp = [calendar components:flags
                                                             fromDate:date];
               dateComp.timeZone = [NSTimeZone systemTimeZone];
               /** 提醒任务开始日期 */
               reminder.startDateComponents = dateComp;
               /** 提醒任务截止日期 */
               reminder.dueDateComponents = dateComp;
               /** 优先级 1...9 (高->低) */
               reminder.priority = 1;
               /** 添加日历 */
               EKCalendar *eventCalendar;
               NSString *cIdentifier = [FZUserEventBase identifierWithKey:calendarIdentifier];
               if (cIdentifier.length) {
                   NSArray *calendars = [strongStore calendarsForEntityType:EKEntityTypeEvent];
                   for (EKCalendar *calendar in calendars) {
                       if ([calendar.calendarIdentifier isEqualToString:cIdentifier]) {
                           eventCalendar = calendar;
                       }
                   }
               }
               if (eventCalendar) {
                   /** 指定时间日历 */
                   [reminder setCalendar:eventCalendar];
               }else{
                   //添加默认提醒日历
                   [reminder setCalendar:[strongStore defaultCalendarForNewReminders]];
               }
               
               
               /*
                * 创建重复需要用到 EKRecurrenceRule
                * EKRecurrenceFrequencyDaily,  周期为天
                * EKRecurrenceFrequencyWeekly, 周期为周
                * EKRecurrenceFrequencyMonthly,周期为月
                * EKRecurrenceFrequencyYearly  周期为年
                */
               
               /** 指定日提醒 */
               /*
               NSMutableArray *weekArr = [NSMutableArray array];
               NSArray *weeks = @[@1,@2,@3,@4,@5,@6,@7];//1代表周日以此类推
                */
               /*
                * 也可以写成
                * NSArray *weekArr = @[@(EKWeekdaySunday),@(EKWeekdayMonday),@(EKWeekdayTuesday)];
                */
               /*
               [weeks enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                   EKRecurrenceDayOfWeek *daysOfWeek = [EKRecurrenceDayOfWeek dayOfWeek:obj.integerValue];
                   [weekArr addObject:daysOfWeek];
               }];
               */
               
               /*
                EKRecurrenceRule *rule = [[EKRecurrenceRule alloc]initRecurrenceWithFrequency:EKRecurrenceFrequencyWeekly
                interval:1 daysOfTheWeek:weekArr daysOfTheMonth:nil monthsOfTheYear:nil weeksOfTheYear:nil daysOfTheYear:nil setPositions:nil end:nil];
                */
               /** 添加重复规则：每天 */
               //EKRecurrenceEnd *end= [EKRecurrenceEnd recurrenceEndWithEndDate:endDate];
               //EKRecurrenceEnd *end= [EKRecurrenceEnd recurrenceEndWithOccurrenceCount:1];
               EKRecurrenceRule *rule =
               [[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyDaily
                                                            interval:1
                                                                 end:nil];
               [reminder addRecurrenceRule:rule];
               
               /** 添加相对日期：闹钟提醒 */
               if (alarmArray && alarmArray.count > 0) {
                   for (NSNumber *time in alarmArray) {
                       //相对时间提醒
                       EKAlarm *alarm = [EKAlarm alarmWithRelativeOffset:time.integerValue];
                       [reminder addAlarm:alarm];
                   }
               }else{
                   /** 添加绝对日期：闹钟提醒 */
                   EKAlarm *alarm = [EKAlarm alarmWithAbsoluteDate:date];
                   [reminder addAlarm:alarm];
               }
               
               /** 提交事件 */
               NSError *error;
               [strongStore saveReminder:reminder commit:YES error:&error];
               
               /** 保存 */
               if (error) {
                   [FZUserEventBase showAlert:error.userInfo[NSLocalizedDescriptionKey]];
                   if (completion) {
                       completion(NO,error);
                   }
               } else {
                   BOOL isGranted = NO;
                   [FZUserEventBase showAlert:@"已添加到系统提醒事项中"];
                   if (reminder.calendarItemIdentifier.length && eventIdentifier.length) {
                       //存储事件ID
                       isGranted = [FZUserEventBase setIdentifier:reminder.calendarItemIdentifier forKey:eventIdentifier];
                       if (!isGranted) {
                           error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{NSLocalizedDescriptionKey : @"存储失败"}];
                       }
                   }else{
                       error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{NSLocalizedDescriptionKey : @"eventIdentifier不存在"}];
                   }
                   if (completion) {
                       completion(isGranted,error);
                   }
               }
               
           }else{
               [FZUserEventBase showAlert:@"不允许使用提醒事项,请在设置中允许此App使用提醒事项"];
               NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{NSLocalizedDescriptionKey:@"不允许使用提醒事项,请在设置中允许此App使用提醒事项"}];
               if (completion) {
                   completion(NO,error);
               }
           }
       }
    }];
}

/**
 *  更新提醒事项
 *
 *  @param eventIdentifier 事件ID(标识符)
 *  @param title      修改事件标题
 *  @param location   修改事件位置
 *  @param date       修改提醒时间
 *  @param alarmArray 修改闹钟集合
 *  @param notes      修改事件备注
 *  @param calendarIdentifier 修改事件源(传nil，则为默认)
 *  @param completion 回调方法
 */
+ (void)updateEventIdentifier:(NSString * _Nullable )eventIdentifier
           calendarIdentifier:(NSString * _Nullable )calendarIdentifier
                        title:(NSString *)title
                     location:(NSString * _Nullable )location
                        notes:(NSString * _Nullable )notes
                         date:(NSDate *)date
                   alarmArray:(NSArray<NSNumber *> *)alarmArray
                   completion:(void(^)(BOOL granted, NSError *error))completion{
    /** 获取到此事件 */
    EKCalendarItem *item = [self eventWithIdentifier:eventIdentifier];
    if (item) {
        /** 移除旧事件 */
        [self removeEventWithIdentifier:eventIdentifier];
        /** 新建事件 */
        [self addEventWithIdentifier:eventIdentifier calendarIdentifier:calendarIdentifier title:title location:location notes:notes date:date alarmArray:alarmArray completion:completion];
    }else{
        /** 没有此条提醒事项 */
        [self addEventWithIdentifier:eventIdentifier calendarIdentifier:calendarIdentifier title:title location:location notes:notes date:date alarmArray:alarmArray completion:completion];
    }
}



/**
 *  删除提醒事项事件(删除单个)
 *
 *  @param identifier    事件ID(标识符)
 */
+ (BOOL)removeEventWithIdentifier:(NSString *)identifier{
    EKEventStore * eventStore = [FZUserEventBase sharedHelper].eventStore;
    NSString *eIdentifier = [FZUserEventBase identifierWithKey:identifier];
    NSError*error;
    if (eIdentifier && ![eIdentifier isEqualToString:@""]) {
        EKCalendarItem *item = [eventStore calendarItemWithIdentifier:eIdentifier];
        EKReminder *reminder = (EKReminder *)item;
        return [eventStore removeReminder:reminder commit:YES error:&error];
    }
    return NO;
}

/**
 *  删除提醒事项事件(可删除一段时间内的事件)
 *
 *  @param startDate  开始时间
 *  @param endDate    结束时间
 *  @param title    标题，为空则都要删除
 *  @param calendarIdentifier  事件源(无，则为默认)
 */
+ (void)removeEventsWithStartDate:(NSDate *)startDate
                          endDate:(NSDate *)endDate
                            title:(NSString *)title
               calendarIdentifier:(NSString *)calendarIdentifier
                       completion:(void(^)(BOOL granted, NSError *error))completion{
    EKEventStore * eventStore = [FZUserEventBase sharedHelper].eventStore;
    /** 获取所有相关提醒事项事件 */
    [self eventsWithStartDate:startDate endDate:endDate title:title calendarIdentifier:calendarIdentifier completion:^(NSArray<EKReminder *> *reminders) {
        for (EKReminder *reminder in reminders) {
            // 删除这一条事件
            NSError *error;
            // commit:NO：最后再一次性提交
            [eventStore removeReminder:reminder commit:NO error:&error];
        }
        //一次提交所有操作到事件库
        NSError *errored;
        BOOL commitSuccess= [eventStore commit:&errored];
        if (completion) {
            completion(commitSuccess,errored);
        }
    }];
}



@end
