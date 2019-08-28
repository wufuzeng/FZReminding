//
//  FZUserEventBase.h
//  FZReminding
//
//  Created by 吴福增 on 2019/8/27.
//

/**
 Localized resources can be mixed        YES //表示是否允许应用程序获取框架库内语言。
 Localization native development region  $(DEVELOPMENT_LANGUAGE) //默认语言
 Privacy - Calendars Usage Description   //日历隐私权限
 Privacy - Reminders Usage Description   //提醒事项隐私权限
 
 
 <key>CFBundleAllowMixedLocalizations</key><true/>
 <key>CFBundleDevelopmentRegion</key><string>$(DEVELOPMENT_LANGUAGE)</string>
 <key>NSCalendarsUsageDescription</key><string>调用日历权限</string>
 <key>NSRemindersUsageDescription</key><string>调用提醒事件</string>
 */

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
NS_ASSUME_NONNULL_BEGIN

@interface FZUserEventBase : NSObject
/**
 * 操作系统日历的Store实例
 */
@property (nonatomic, strong) EKEventStore* eventStore;
/** 单例 */
+ (instancetype)sharedHelper;

/**
 * 获取权限状态
 *
 * @param type 事件类型，EKEntityTypeEvent 或者 EKEntityTypeReminder
 * @param result 是否有权限
 */
+ (void)accessForEventKitType:(EKEntityType)type
                       result:(void(^)(BOOL granted,NSError *error))result;

/**
 * 获取类型的Source
 *
 * @param type 事件类型
 * @return Source
 */
+ (EKSource*)sourceWithType:(EKSourceType)type;

/**
 * 获取某个类型全部的日历
 *
 * @param type 事件类型
 * @return 日历数组
 */
+ (NSArray<EKCalendar *> *)calendarWithType:(EKEntityType)type;

/**
 * 通过UserDefault获取日历的id
 *
 * @param key 键
 * @return id
 */
+ (nullable NSString *)identifierWithKey:(NSString *)key;

/**
 * 通过UserDefault保存日历的id
 *
 * @param identifier id
 * @param key 键
 */
+ (BOOL)setIdentifier:(NSString *)identifier forKey:(NSString *)key;

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
                                      createBlock:(void (^)(EKCalendar* calendar))createBlock;


+(void)presentEventEditViewController;

+(void)showAlert:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
