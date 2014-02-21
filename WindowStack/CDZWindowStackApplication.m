//
//  CDZWindowStackApplication.m
//  WindowStack
//
//  Created by Chris Dzombak on 2/20/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZWindowStackApplication.h"
#import "CDZCLIPrint.h"
#import <IOKit/ps/IOPowerSources.h>


static const NSTimeInterval CDZWindowStackCheckIntervalFrequent = 0.5;
static const NSTimeInterval CDZWindowStackCheckIntervalBattery = 2.0;
static const NSTimeInterval CDZWindowStackLargeBreakTimeInterval = 4.0 * 60.0;


@interface CDZWindowStackApplication ()

@property (nonatomic, strong) NSTimer *windowCheckTimer;
@property (nonatomic, copy) NSString *lastWindowString;
@property (nonatomic, copy) NSDate *lastChangeDate;

@property (nonatomic, readonly) NSAppleScript *windowTitleScript;
@property (nonatomic, readonly) NSDateFormatter *timeFormatter;

- (void)reconfigureTimer;

@end


void CDZPowerSourceCallback(void *context) {
    NSCParameterAssert(context != NULL);
    
    CDZWindowStackApplication *app = (__bridge CDZWindowStackApplication *)(context);
    [app reconfigureTimer];
}


@implementation CDZWindowStackApplication

@synthesize windowTitleScript = _windowTitleScript,
            timeFormatter = _timeFormatter;

- (void)start {
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
    NSDictionary *error;
    NSAppleEventDescriptor *result = [self.windowTitleScript executeAndReturnError:&error];
    
    if (!result) {
        CDZCLILog(@"Error executing AppleScript: %@", error);
        [self exitWithCode:CDZWindowStackReturnCodeAppleScriptError];
        return nil;
    }
    else {
        NSAssert([result numberOfItems] == 2, @"AppleScript result must have 2 descriptors");
        // of course they're not zero-indexed. ಠ_ಠ @Apple
        return [NSString stringWithFormat:@"%@: %@", [[result descriptorAtIndex:1] stringValue], [[result descriptorAtIndex:2] stringValue]];
    }
}

- (NSAppleScript *)windowTitleScript {
    if (!_windowTitleScript) {
        NSString *script = @"global frontApp, frontAppName, windowTitle\n"
        "set windowTitle to \"\"\n"
        "tell application \"System Events\"\n"
        "set frontApp to first application process whose frontmost is true\n"
        "set frontAppName to name of frontApp\n"
        "tell process frontAppName\n"
        "tell (1st window whose value of attribute \"AXMain\" is true)\n"
        "set windowTitle to value of attribute \"AXTitle\"\n"
        "end tell\n"
        "end tell\n"
        "end tell\n"
        "return {frontAppName, windowTitle}\n";
        
        _windowTitleScript = [[NSAppleScript alloc] initWithSource:script];
        NSDictionary *compileError;
        BOOL compiled = [_windowTitleScript compileAndReturnError:&compileError];
        if (!compiled) {
            CDZCLILog(@"Error compiling AppleScript: %@", compileError);
            [self exitWithCode:CDZWindowStackReturnCodeAppleScriptError];
        }
    }
    return _windowTitleScript;
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
