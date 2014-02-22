//
//  CDZWindowStackApplication.h
//  WindowStack
//
//  Created by Chris Dzombak on 2/20/14.
//  Copyright (c) 2014 Chris Dzombak. All rights reserved.
//

#import "CDZCLIApplication.h"

typedef NS_ENUM(int, CDZWindowStackReturnCode) {
    CDZWindowStackReturnCodeNormal = 0,
    CDZWindowStackReturnCodeAccessibilityAPIError = 1,
    CDZWindowStackReturnCodeAccessibilityAPISetup = 2,
};

@interface CDZWindowStackApplication : CDZCLIApplication
@end
