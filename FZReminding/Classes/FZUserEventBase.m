//
//  FZUserEventBase.m
//  FZReminding
//
//  Created by 吴福增 on 2019/8/27.
//

#import "FZUserEventBase.h"

@interface FZUserEventBase ()
<EKEventEditViewDelegate>

@end

@implementation FZUserEventBase


+ (instancetype)sharedHelper{
    static dispatch_once_t onceToken;
    static FZUserEventBase *eventHelper;
    dispatch_once(&onceToken, ^{
        eventHelper = [[self alloc] init];
    });
    return eventHelper;
}


/**
 * 获取权限状态
 *
 * @param type 事件类型，EKEntityTypeEvent 或者 EKEntityTypeReminder
 * @param result 是否有权限
 */
+ (void)accessForEventKitType:(EKEntityType)type
                       result:(void(^)(BOOL granted,NSError *error))result{
    EKAuthorizationStatus eventStatus = [EKEventStore  authorizationStatusForEntityType:EKEntityTypeEvent];
    if (eventStatus == EKAuthorizationStatusAuthorized) {
        // 已授权，可使用
        if (result) {
            result(YES, nil);
            return;
        }
    }else if(eventStatus == EKAuthorizationStatusNotDetermined){
        // 未进行授权选择
        [[FZUserEventBase sharedHelper].eventStore requestAccessToEntityType:type completion:result];
    }else{
         //这里是用户拒绝授权的返回，这个方法应该给一个block回掉，来更具用户授权状态来处理不同的操作，我这里为方便直接写个跳转到系统设置页
        //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        // 未授权
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:@{NSLocalizedDescriptionKey : @"未授权"}];
        if (result) {
            result(NO, error);
            return;
        }
    }
}

/**
 * 获取类型的Source
 *
 * @param type 事件类型
 * @return Source
 */
+ (EKSource*)sourceWithType:(EKSourceType)type {
    
/**
 * EKCalendarTypeLocal,   //使用模拟器使用
 * EKCalendarTypeCalDAV,  //iCloud，真机一般使用这个
 * EKCalendarTypeExchange,//这个应该是能使用其他操作，比如邮件，Siri，对应截图中的Siri found in Apps
 * EKCalendarTypeSubscription,//带标题，对应截图中的US Holidays
 * EKCalendarTypeBirthday //对应截图中的生日
 */
    
    EKSource *localSource = nil;
    NSLog(@"source %@",[FZUserEventBase sharedHelper].eventStore.sources);
    for (EKSource *source in [FZUserEventBase sharedHelper].eventStore.sources){
        if (source.sourceType == type){
            localSource = source;
            break;
        }
    }
    return localSource;
}

/**
 * 获取某个类型全部的日历
 *
 * @param type 事件类型
 * @return 日历数组
 */
+ (NSArray<EKCalendar *> *)calendarWithType:(EKEntityType)type{
    return [[FZUserEventBase sharedHelper].eventStore calendarsForEntityType:type];
}


/**
 * 通过UserDefault获取日历的id
 *
 * @param key 键
 * @return id
 */
+ (nullable NSString *)identifierWithKey:(NSString *)key{
    if (key.length == 0) {
        return nil;
    }
    NSUserDefaults * def = [NSUserDefaults standardUserDefaults];
    NSString* calendarIdentifier = [def valueForKey:key];
    return calendarIdentifier;
}

/**
 * 通过UserDefault保存日历的id
 *
 * @param identifier id
 * @param key 键
 */
+ (BOOL)setIdentifier:(NSString *)identifier forKey:(NSString *)key {
    NSUserDefaults * def = [NSUserDefaults standardUserDefaults];
    [def setValue:identifier forKey:key];
    return [def synchronize];
}

/**
 * 通过id创建或者获取日历
 *
 * @param identifier id
 * @param type 日历类型
 * @param createBlock 新日历配置block
 * @return 日历实例
 */
- (EKCalendar *)createOrGetCalendarWithIdentifier:(NSString *)identifier
                                             type:(EKEntityType)type
                                      createBlock:(void (^)(EKCalendar* calendar))createBlock;{
    if (identifier) {
        EKCalendar* calendar = [[FZUserEventBase sharedHelper].eventStore calendarWithIdentifier:identifier];
        if (calendar) {
            return calendar;
        }
    }
    EKCalendar* calendar = [EKCalendar calendarForEntityType:type eventStore:[FZUserEventBase sharedHelper].eventStore];
    if(createBlock){
        createBlock(calendar);
    }
    return calendar;
}


+(void)presentEventEditViewController{
    
    EKEventStore *eventStore = [FZUserEventBase sharedHelper].eventStore;
    EKEvent *event = [EKEvent eventWithEventStore:eventStore];
    EKEventEditViewController *vc = [[EKEventEditViewController alloc] init];
    vc.event = event;
    vc.eventStore = eventStore;
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:vc animated:YES completion:nil];
    vc.editViewDelegate = [FZUserEventBase sharedHelper];
}

 

+(void)showAlert:(NSString *)message{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

#pragma mark -- EKEventEditViewDelegate --


- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action{
 
    NSError *error = nil;
    EKEvent *thisEvent = controller.event;
    
    switch (action) {
        case EKEventEditViewActionCanceled:
            // Edit action canceled, do nothing.
            break;
            
        case EKEventEditViewActionSaved:
            // When user hit "Done" button, save the newly created event to the event store,
            // and reload table view.
            // If the new event is being added to the default calendar, then update its
            // eventsList.
        
            [controller.eventStore saveEvent:controller.event span:EKSpanFutureEvents error:&error];
            
            break;
            
        case EKEventEditViewActionDeleted:
            // When deleting an event, remove the event from the event store,
            // and reload table view.
            // If deleting an event from the currenly default calendar, then update its
            // eventsList.
            [controller.eventStore removeEvent:thisEvent span:EKSpanFutureEvents error:&error];
            break;
            
        default:
            break;
    }
    // Dismiss the modal view controller
    [controller dismissViewControllerAnimated:YES completion:nil];
    
}



//- (EKCalendar *)eventEditViewControllerDefaultCalendarForNewEvents:(EKEventEditViewController *)controller{
//
//    EKEventStore *eventStore = [FZUserEventBase sharedHelper].eventStore;
//
//    EKCalendar* calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:eventStore];
//
//    NSError* error;
//    [eventStore saveCalendar:calendar commit:YES error:&error];
//
//    return calendar;
//
//}

#pragma mark -- Lazy Func --

- (EKEventStore *)eventStore{
    if (!_eventStore) {
        _eventStore = [[EKEventStore alloc] init];
    }
    return _eventStore;
}

@end
