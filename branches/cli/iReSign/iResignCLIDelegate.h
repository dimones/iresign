//
//  iResignCLIDelegate.h
//  iReSign
//
//  Created by Patrick Blitz on 1/15/12.
//  Copyright (c) 2012 Weptun GmbH. 
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import "iResignResponder.h"
#import "IResignLogic.h"
@interface iResignCLIDelegate : NSObject <iResignResponder,NSApplicationDelegate> {
        IResignLogic * resignLogic;
}

@property (nonatomic, retain) NSString *ipaPath;
@property (nonatomic, retain) NSString *provisioningPath;
@property (nonatomic, retain) NSString *codeSigningName;
@property (nonatomic, retain) IResignLogic * resignLogic;
@property BOOL verbose;

@end
