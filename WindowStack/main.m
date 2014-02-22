//
//  main.m
//  WindowStack
//
//  Created by Chris Dzombak on 2/20/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZCLIApplication.h"

#import "CDZWindowStackApplication.h"

static const NSTimeInterval CDZCLIApplicationRunLoopInterval = 1.0;

int main(int argc, const char * argv[]) {
    NSRunLoop *runLoop;
    CDZCLIApplication *main;
    
    @autoreleasepool {
        runLoop = [NSRunLoop currentRunLoop];
        main = [CDZWindowStackApplication new];
        
        [main start];
        
        while(!(main.isFinished) && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:CDZCLIApplicationRunLoopInterval]]);
    };
    
    return(main.exitCode);
}
