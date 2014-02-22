//
//  CDZWindowStackApplication.m
//  WindowStack
//
//  Created by Chris Dzombak on 2/20/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZWindowStackApplication.h"
#import "CDZCLIPrint.h"

#import <ApplicationServices/ApplicationServices.h>
#import <IOKit/ps/IOPowerSources.h>


static const NSTimeInterval CDZWindowStackCheckIntervalFrequent = 1.0;
static const NSTimeInterval CDZWindowStackCheckIntervalBattery = 2.5;
static const NSTimeInterval CDZWindowStackLargeBreakTimeInterval = 4.0 * 60.0;


@interface CDZWindowStackApplication ()

@property (nonatomic, strong) NSTimer *windowCheckTimer;
@property (nonatomic, copy) NSString *lastWindowString;
@property (nonatomic, copy) NSDate *lastChangeDate;

@property (nonatomic, readonly) NSDateFormatter *timeFormatter;

- (void)reconfigureTimer;

@end

CFTypeRef CopyValueOfAttributeOfUIElement(CFStringRef attribute, AXUIElementRef element) {
    CFTypeRef result = nil;
    
    AXError err = AXUIElementCopyAttributeValue(element, attribute, &result);
    if (err != kAXErrorSuccess) CDZCLILog(@"AXError %d for attribute %@", err, attribute);
    
    return result;
}

void CDZPowerSourceCallback(void *context) {
    NSCParameterAssert(context != NULL);
    
    CDZWindowStackApplication *app = (__bridge CDZWindowStackApplication *)(context);
    [app reconfigureTimer];
}


@implementation CDZWindowStackApplication

@synthesize timeFormatter = _timeFormatter;

- (void)start {
    if (!AXIsProcessTrusted()) {
        CDZCLIPrint(@"You must allow this app to control your computer, in System Preferences -> Security & Privacy -> Accessibility");
        [self exitWithCode:CDZWindowStackReturnCodeAccessibilityAPISetup];
    }
    
    CFRunLoopSourceRef runLoopSource = IOPSCreateLimitedPowerNotification(CDZPowerSourceCallback, (__bridge void *)(self));
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);
    CFRelease(runLoopSource);
    
    [self reconfigureTimer];
}

- (void)reconfigureTimer {
    [self.windowCheckTimer invalidate];
    self.windowCheckTimer = nil;
    
    NSTimeInterval checkInterval = CDZWindowStackCheckIntervalBattery;
    
    CFDictionaryRef externalAdapter = IOPSCopyExternalPowerAdapterDetails();
    if (externalAdapter != NULL) {
        checkInterval = CDZWindowStackCheckIntervalFrequent;
        CFRelease(externalAdapter);
    }
    
    self.windowCheckTimer = [NSTimer scheduledTimerWithTimeInterval:checkInterval target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
}

- (void)timerFired:(NSTimer *)timer {
    NSParameterAssert(timer == self.windowCheckTimer);
    
    NSString *currentWindowString = [self currentWindowString];
    if (currentWindowString && ![currentWindowString isEqualToString:self.lastWindowString]) {
        NSDate *now = [NSDate date];
        
        NSString *separatorIfNecessary = [now timeIntervalSinceDate:self.lastChangeDate] > CDZWindowStackLargeBreakTimeInterval ? @"---\n" : @"";
        CDZCLIPrint(@"%@%@: %@", separatorIfNecessary, [self.timeFormatter stringFromDate:now], currentWindowString);
        
        self.lastChangeDate = now;
        self.lastWindowString = currentWindowString;
    }
}

- (NSString *)currentWindowString {
    AXUIElementRef systemWide = AXUIElementCreateSystemWide();
//    AXUIElementSetMessagingTimeout(systemWide, 10.0);
    
    CFArrayRef names;
    AXUIElementCopyAttributeNames(systemWide, &names);
    CDZCLILog(@"available names in system wide: %@", names);
    CFRelease(names);
    
    AXUIElementRef focusedApp = CopyValueOfAttributeOfUIElement(kAXFocusedApplicationAttribute, systemWide);
    AXUIElementRef focusedWindow = CopyValueOfAttributeOfUIElement(kAXFocusedWindowAttribute, focusedApp);
    
    if (focusedWindow) CFRelease(focusedWindow);
    if (focusedApp) CFRelease(focusedApp);
    if (systemWide) CFRelease(systemWide);
    
    return nil;
}

- (NSString *)lastWindowString {
    if (!_lastWindowString) {
        _lastWindowString = @"";
    }
    return _lastWindowString;
}

- (NSDate *)lastChangeDate {
    if (!_lastChangeDate) {
        _lastChangeDate = [NSDate date];
    }
    return _lastChangeDate;
}

- (NSDateFormatter *)timeFormatter {
    if (!_timeFormatter) {
        _timeFormatter = [[NSDateFormatter alloc] init];
        _timeFormatter.dateFormat = @"HH:mm";
    }
    return _timeFormatter;
}

@end
