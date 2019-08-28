//
//  FZUserEventReminder.h
//  FZReminding
//
//  Created by 吴福增 on 2019/8/27.
//

#import "FZUserEventBase.h"

NS_ASSUME_NONNULL_BEGIN

@interface FZUserEventReminder : FZUserEventBase

/**
 *  指定标识提醒事件
 *
 *  @param eventIdentifier  事件ID(标识符)
 */
+ (EKCalendarItem *)eventWithIdentifier:(NSString *)eventIdentifier;

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
                 completion:(void(^)(NSArray<EKReminder *> * reminders))completion;

/**
 *  添加提醒事项，实现闹铃提醒的功能
 *
 *  @param eventIdentifier     事件ID(标识符，用于区分日历)
 *  @param calendarIdentifier  事件源(无，则为默认)
 *  @param title      事件标题
 *  @param location   事件位置
 *  @param notes      事件备注(传nil，则没有)
 *  @param startDate  提醒日期
 *  @param alarmArray 闹钟集合 (提醒时间数组，这个数组是按照秒计算的。相对开始时间间隔(单位秒))
 *  @param completion  回调方法
 */
+ (void)addEventWithIdentifier:(NSString * _Nullable)eventIdentifier
            calendarIdentifier:(NSString * _Nullable)calendarIdentifier
                         title:(NSString *)title
                      location:(NSString * _Nullable)location
                         notes:(NSString * _Nullable)notes
                          date:(NSDate *)date
                    alarmArray:(NSArray<NSNumber *> *)alarmArray
                    completion:(void(^)(BOOL granted, NSError *error))completion;

/**
 *  更新提醒事项
 *
 *  @param eventIdentifier 事件ID(标识符)
 *  @param title      修改事件标题
 *  @param location   修改事件位置
 *  @param date       提醒日期
 *  @param alarmArray 修改闹钟集合
 *  @param notes      修改事件备注
 *  @param calendarIdentifier 修改事件源(传nil，则为默认)
 *  @param completion 回调方法
 */
+ (void)updateEventIdentifier:(NSString * _Nullable)eventIdentifier
           calendarIdentifier:(NSString * _Nullable)calendarIdentifier
                        title:(NSString *)title
                     location:(NSString * _Nullable)location
                        notes:(NSString * _Nullable)notes
                         date:(NSDate *)date
                   alarmArray:(NSArray<NSNumber *> *)alarmArray
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
+ (void)removeEventsWithStartDate:(NSDate *)startDate
                          endDate:(NSDate *)endDate
                            title:(NSString *)title
               calendarIdentifier:(NSString *)calendarIdentifier
                       completion:(void(^)(BOOL granted, NSError *error))completion;


@end

NS_ASSUME_NONNULL_END
