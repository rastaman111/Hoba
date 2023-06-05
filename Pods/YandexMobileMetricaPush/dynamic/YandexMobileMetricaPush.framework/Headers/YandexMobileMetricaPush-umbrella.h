#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "YandexMobileMetricaPush.h"
#import "YMPDefines.h"
#import "YMPUserNotificationCenterDelegate.h"
#import "YMPUserNotificationCenterHandling.h"
#import "YMPVersion.h"
#import "YMPYandexMetricaPush.h"
#import "YMPYandexMetricaPushEnvironment.h"

FOUNDATION_EXPORT double YandexMobileMetricaPushVersionNumber;
FOUNDATION_EXPORT const unsigned char YandexMobileMetricaPushVersionString[];

