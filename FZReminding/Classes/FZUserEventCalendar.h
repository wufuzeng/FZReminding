//
//  FZUserEventCalendar.h
//  FZReminding
//
//  Created by 吴福增 on 2019/8/27.
//

#import "FZUserEventBase.h"

NS_ASSUME_NONNULL_BEGIN

@interface FZUserEventCalendar : FZUserEventBase

+(void)openSystemEventEdit;

/**
 *  添加日历源
 *
 *  @param identifier 日历源ID(标识符，用于区分日历源)
 *  @param title      日历源标题
 *  @param completion 回调方法
 */
+ (void)addCalendarWithIdentifier:(NSString * _Nullable)identifier
                            title:(NSString *)title
                       completion:(void(^)(BOOL granted, NSError *error))completion;

/**
 *  指定标识日历事件
 *
 *  @param eventIdentifier  事件ID(标识符)
 */
+ (EKEvent *)eventWithIdentifier:(NSString *)eventIdentifier;

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
                         calendarIdentifier:(NSString * _Nullable)calendarIdentifier;

/**
 *  将App事件添加到系统日历提醒事项，实现闹铃提醒的功能
 *
 *  @param eventIdentifier     事件ID(标识符，用于区分日历)
 *  @param calendarIdentifier  事件源(无，则为默认)
 *  @param title       事件标题
 *  @param notes       事件备注(传nil，则没有)
 *  @param url         事件url(传nil，则没有)
 *  @param location    事件位置
 *  @param startDate   开始时间
 *  @param endDate     结束时间
 *  @param allDay      是否全天
 *  @param alarmArray  闹钟集合 (传nil，则没有)(提醒时间数组，这个数组是按照秒计算的。相对开始时间间隔(单位秒))
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
                    completion:(void(^)(BOOL granted, NSError *error))completion;

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
                          URL:(NSURL * _Nullable)url
                    startDate:(NSDate *)startDate
                      endDate:(NSDate *)endDate
                       allDay:(BOOL)allDay
                   alarmArray:(NSArray<NSNumber *> * _Nullable)alarmArray
                   completion:(void(^)(BOOL granted, NSError *error))completion;

/**
 *  删除日历事件(删除单个)
 *
 *  @param identifier    事件ID(标识符)
 */
+ (BOOL)removeEventWithIdentifier:(NSString *)identifier;

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
               calendarIdentifier:(NSString * _Nullable)calendarIdentifier;


@end

NS_ASSUME_NONNULL_END
