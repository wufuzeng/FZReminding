//
//  FZUserEventCalendar.m
//  FZReminding
//
//  Created by 吴福增 on 2019/8/27.
//

#import "FZUserEventCalendar.h"

@implementation FZUserEventCalendar




+(void)openSystemEventEdit{
    EKEventStore *eventStore = [FZUserEventBase sharedHelper].eventStore;
    
    [FZUserEventBase accessForEventKitType:EKEntityTypeEvent result:^(BOOL granted, NSError * _Nonnull error) {
        if (error) {
            [FZUserEventBase showAlert:@"添加失败，请稍后重试"];
//            if (completion) {
//                completion(granted,error);
//            }
        }else{
            if (granted == NO) {
                [FZUserEventBase showAlert:@"不允许使用日历,请在设置中允许此App使用日历"];
                NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{NSLocalizedDescriptionKey:@"不允许使用日历,请在设置中允许此App使用日历"}];
//                if (completion) {
//                    completion(NO,error);
//                }
            }else{
                [self presentEventEditViewController];
            }
        }
    }];
    
    
    if([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        //EKEntityTypeEvent 事件页面
        //EKEntityTypeReminder 提醒页面
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted,NSError* error){
            if(!granted){
                dispatch_async(dispatch_get_main_queue(), ^{
                    //TODO: 提示需要权限
                });
            }else{
                
                
            }
        }];
    }
}

/**
 *  添加日历源
 *
 *  @param identifier  日历源ID(标识符，用于区分日历源)
 *  @param title      日历源标题
 *  @param completion 回调方法
 */
+ (void)addCalendarWithIdentifier:(NSString * _Nullable)identifier
                            title:(NSString *)title
                       completion:(void(^)(BOOL granted, NSError *error))completion {
    NSError *error;
    BOOL isSuccess = NO;
    EKSource *localSource;
    for (EKSource *source in [FZUserEventBase sharedHelper].eventStore.sources){
        //获取iCloud源
        if (source.sourceType == EKSourceTypeCalDAV && [source.title isEqualToString:@"iCloud"]){
            localSource = source;
            break;
        }
    }
    if (localSource == nil){
        for (EKSource *source in [FZUserEventBase sharedHelper].eventStore.sources){
            //获取本地Local源(就是上面说的模拟器中名为的Default的日历源)
            if (source.sourceType == EKSourceTypeLocal){
                localSource = source;
                break;
            }
        }
    }
    /** 新建日历 */
    EKCalendar *eventCalendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent
                                                       eventStore:[FZUserEventBase sharedHelper].eventStore];
    eventCalendar.title = title;
    eventCalendar.source = localSource;
    /** 保存日历 */
    isSuccess = [[FZUserEventBase sharedHelper].eventStore saveCalendar:eventCalendar commit:YES error:&error];
    if (error == nil) {
        if (eventCalendar.calendarIdentifier &&
            eventCalendar.calendarIdentifier.length &&
            identifier &&
            identifier.length) {
            /** 存储日历ID */
            isSuccess = [FZUserEventBase setIdentifier:eventCalendar.calendarIdentifier forKey:identifier];
            if (isSuccess == NO) {
                error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{NSLocalizedDescriptionKey : @"存储失败"}];
            }
        }else{
            error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{NSLocalizedDescriptionKey : @"eventIdentifier不存在"}];
        }
    }
    if (completion) {
        completion(isSuccess, error);
    }
}
/**
 *  指定标识日历事件
 *
 *  @param eventIdentifier  事件ID(标识符)
 */
+ (EKEvent *)eventWithIdentifier:(NSString *)eventIdentifier{
    NSString *eIdentifier = [FZUserEventBase identifierWithKey:eventIdentifier];
    if (eIdentifier.length) {
        EKEvent *event = [[FZUserEventBase sharedHelper].eventStore eventWithIdentifier:eIdentifier];
        return event;
    }
    return nil;
}

/**
 *  查日历事件(可查询一段时间内的事件)
 *
 *  @param startDate   开始时间
 *  @param endDate     结束时间
 *  @param title 标题，为空则都要查询
 *  @param calendarIdentifier  事件源(无，则为默认)
 */
+ (NSArray<EKEvent *> *)eventsWithStartDate:(NSDate *)startDate
                                    endDate:(NSDate *)endDate
                                      title:(NSString * _Nullable)title
                         calendarIdentifier:(NSString *)calendarIdentifier{
    
    EKEventStore *eventStore = [FZUserEventBase sharedHelper].eventStore;
    /** 查询到所有的事件日历 */
    NSArray<EKCalendar *> *calendars = [eventStore calendarsForEntityType:EKEntityTypeEvent];
    
    NSMutableArray *only3D = [NSMutableArray array];
    for (EKCalendar *calendar in calendars) {
        EKCalendarType type = calendar.type;
        // 工作、家庭和本地日历
        if (type == EKCalendarTypeLocal || type == EKCalendarTypeCalDAV)  {
            if (calendarIdentifier && ![calendarIdentifier isEqualToString:@""]) {
                NSString *cIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:calendarIdentifier];
                if ([calendar.calendarIdentifier isEqualToString:cIdentifier]){
                    [only3D addObject:calendar];
                }
            }else{
                [only3D addObject:calendar];
            }
        }
    }
    /** 过滤条件 */
    NSPredicate *predicate = [eventStore predicateForEventsWithStartDate:startDate endDate:endDate calendars:only3D];
    /** 获取到范围内的所有事件 */
    NSArray<EKEvent *> *request = [eventStore eventsMatchingPredicate:predicate];
    /** 按开始事件进行排序 */
    request = [request sortedArrayUsingSelector:@selector(compareStartDateWithEvent:)];
    if (title.length == 0) {
        NSMutableArray *onlyRequest = [NSMutableArray array];
        for (int i = 0; i < request.count; i++) {
            EKEvent *event = request[i];
            if (event.title && [event.title isEqualToString:title]) {
                [onlyRequest addObject:event];
            }
        }
        return onlyRequest;
    }else{
        return request;
    }
}

/**
 *  将App事件添加到系统日历提醒事项，实现闹铃提醒的功能
 *
 *  @param eventIdentifier     事件ID(标识符，用于区分日历)
 *  @param calendarIdentifier  事件源(无，则为默认)
 *  @param title      事件标题
 *  @param notes      事件备注(传nil，则没有)
 *  @param url        事件url(传nil，则没有)
 *  @param location   事件位置
 *  @param startDate  开始时间
 *  @param endDate    结束时间
 *  @param allDay     是否全天
 *  @param alarmArray 闹钟集合 (传nil，则没有)(提醒时间数组，这个数组是按照秒计算的。相对开始时间间隔(单位秒))
 *  @param completion  回调方法
 */
+ (void)addEventWithIdentifier:(NSString * _Nullable)eventIdentifier
            calendarIdentifier:(NSString * _Nullable)calendarIdentifier
                         title:(NSString *)title
                      location:(NSString * _Nullable)location
                         notes:(NSString * _Nullable)notes
                           url:(NSURL * _Nullable)url
                     startDate:(NSDate *)startDate
                       endDate:(NSDate *)endDate
                        allDay:(BOOL)allDay
                    alarmArray:(NSArray<NSNumber *>* _Nullable)alarmArray
                    completion:(void(^)(BOOL granted, NSError *error))completion{
    
    EKEventStore * refetchStore = [FZUserEventBase sharedHelper].eventStore;
    __weak __typeof(refetchStore) weakStore = refetchStore;
    [FZUserEventBase accessForEventKitType:EKEntityTypeEvent
                                  result:^(BOOL granted,NSError *error) {
        __strong __typeof(weakStore) strongStore = weakStore;
       if(error){
          [FZUserEventBase showAlert:@"添加失败，请稍后重试"];
           if (completion) {
               completion(granted,error);
           }
       }else{
           if (granted) {
               //NSDateFormatter *tempFormatter = [[NSDateFormatter alloc]init];
               //[tempFormatter setDateFormat:@"dd.MM.yyyy HH:mm"];
               /** 创建一个事件日历功能 */
               EKEvent *event = [EKEvent eventWithEventStore:strongStore];
               /** 标题 */
               event.title    = title;
               /** 地点 */
               event.location = location;
               /** 事件备注 */
               event.notes = notes;
               /** 事件url */
               event.URL = url;
               /** 开始日期 */
               event.startDate = startDate;
               /** 结束日期 */
               event.endDate   = endDate;
               /**
                是否全天
                全天，开始日期是昨天23：59 - 今天23：59
                */
               event.allDay = allDay;
               
               /** 添加相对日期：闹钟提醒 */
               if (alarmArray && alarmArray.count > 0) {
                   for (NSNumber *time in alarmArray) {
                       //相对时间提醒
                       EKAlarm *alarm = [EKAlarm alarmWithRelativeOffset:time.integerValue];
                       [event addAlarm:alarm];
                   }
               }else{
                   /** 添加绝对日期：闹钟提醒 */
                   EKAlarm *alarm = [EKAlarm alarmWithAbsoluteDate:startDate];
                   [event addAlarm:alarm];
               }
               
               /** 存储到源中 */
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
                   [event setCalendar:eventCalendar];
               }else{
                   /** 默认事件日历 */
                   [event setCalendar:[strongStore defaultCalendarForNewEvents]];
               }
               NSError *error;
               /**
                * EKSpanThisEvent 表示只影响当前事件。
                * EKSpanFutureEvents 表示影响当前和以后的所有事件。
                * 比如某条重复任务修改后保存时，
                * 传EKSpanThisEvent表示值修改这一条重复事件。
                * 传EKSpanFutureEvents表示修改这一条和以后的所有重复事件。
                * 删除事件时，分别表示删除这一条；
                * 删除这一条和以后的所有。
                */
               [strongStore saveEvent:event span:EKSpanThisEvent error:&error];
               
               if (error) {
                   [FZUserEventBase showAlert:error.userInfo[NSLocalizedDescriptionKey]];
                   if (completion) {
                       completion(NO,error);
                   }
               }else{
                   BOOL isGranted = NO;
                   [FZUserEventBase showAlert:@"已添加到系统日历中"];
                   if (event.eventIdentifier.length && eventIdentifier.length) {
                       //存储事件ID
                       isGranted = [FZUserEventBase setIdentifier:event.eventIdentifier forKey:eventIdentifier];
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
               [FZUserEventBase showAlert:@"不允许使用日历,请在设置中允许此App使用日历"];
               NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{NSLocalizedDescriptionKey:@"不允许使用日历,请在设置中允许此App使用日历"}];
               if (completion) {
                   completion(NO,error);
               }
           }
       }
    }];
}

/**
 *  修改日历
 *
 *  @param eventIdentifier 事件ID(标识符)
 *  @param title      修改事件标题
 *  @param location   修改事件位置
 *  @param notes      修改事件备注
 *  @param url        修改事件url
 *  @param startDate  修改开始时间
 *  @param endDate    修改结束时间
 *  @param allDay     修改是否全天
 *  @param alarmArray 修改闹钟集合
 *  @param calendarIdentifier 修改事件源(传nil，则为默认)
 *  @param completion 回调方法
 */
+ (void)updateEventIdentifier:(NSString * _Nullable)eventIdentifier
           calendarIdentifier:(NSString * _Nullable)calendarIdentifier
                        title:(NSString *)title
                     location:(NSString * _Nullable)location
                        notes:(NSString * _Nullable)notes
                          URL:(NSURL *)url
                    startDate:(NSDate *)startDate
                      endDate:(NSDate *)endDate
                       allDay:(BOOL)allDay
                   alarmArray:(NSArray<NSNumber *> * _Nullable)alarmArray

                   completion:(void(^)(BOOL granted, NSError *error))completion{
    /** 获取到此事件 */
    EKEvent *event = [self eventWithIdentifier:eventIdentifier];
    if (event) {
        /** 移除旧事件 */
        [self removeEventWithIdentifier:eventIdentifier];
        /** 新建事件 */
        [self addEventWithIdentifier:eventIdentifier calendarIdentifier:calendarIdentifier title:title location:location notes:notes url:url startDate:startDate endDate:endDate allDay:allDay alarmArray:alarmArray completion:completion];
    }else{
        /** 没有此条日历 */
        [self addEventWithIdentifier:eventIdentifier calendarIdentifier:calendarIdentifier title:title location:location notes:notes url:url startDate:startDate endDate:endDate allDay:allDay alarmArray:alarmArray completion:completion];
    }
}



/**
 *  删除日历事件(删除单个)
 *
 *  @param identifier    事件ID(标识符)
 */
+ (BOOL)removeEventWithIdentifier:(NSString *)identifier{
    EKEventStore * eventStore = [FZUserEventBase sharedHelper].eventStore;
    NSString *eIdentifier = [FZUserEventBase identifierWithKey:identifier];
    NSError*error;
    if (eIdentifier && ![eIdentifier isEqualToString:@""]) {
        EKEvent *event = [eventStore eventWithIdentifier:eIdentifier];
        return [eventStore removeEvent:event span:EKSpanThisEvent error:&error];
    }
    return NO;
}

/**
 *  删除日历事件(可删除一段时间内的事件)
 *
 *  @param startDate  开始时间
 *  @param endDate    结束时间
 *  @param title    标题，为空则都要删除
 *  @param calendarIdentifier  事件源(无，则为默认)
 */
+ (BOOL)removeEventsWithStartDate:(NSDate *)startDate
                          endDate:(NSDate *)endDate
                            title:(NSString * _Nullable)title
               calendarIdentifier:(NSString * _Nullable)calendarIdentifier{
    EKEventStore * eventStore = [FZUserEventBase sharedHelper].eventStore;
    /** 获取所有相关日历事件 */
    NSArray<EKEvent *> *events = [self eventsWithStartDate:startDate endDate:endDate title:title calendarIdentifier:calendarIdentifier];
    for (EKEvent *event in events) {
        // 删除这一条事件
        NSError*error;
        // commit:NO：最后再一次性提交
        [eventStore removeEvent:event span:EKSpanThisEvent commit:NO error:&error];
    }
    //一次提交所有操作到事件库
    NSError *errored;
    BOOL commitSuccess= [eventStore commit:&errored];
    return commitSuccess;
}


@end
