//
//  main.m
//  iResignCLI
//
//  Created by Patrick Blitz on 2/22/12.
//  Copyright (c) 2012 Weptun GmbH.
//

#import <Foundation/Foundation.h>
#import "iReSignAppDelegate.h"
#import "iResignCLIDelegate.h"
int main (int argc, const char * argv[])
{
    
    @autoreleasepool {
        NSUserDefaults *args = [NSUserDefaults standardUserDefaults];
        // now we have the three main files
        
        iResignCLIDelegate * delegate = [[iResignCLIDelegate alloc] init];
        delegate.codeSigningName=[args stringForKey:@"certName"];
        delegate.provisioningPath=[args stringForKey:@"provisioningProfile"];
        delegate.ipaPath=[args stringForKey:@"ipa"];
        BOOL verbose = [args boolForKey:@"v"];
        delegate.verbose=verbose;
        NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
        
        NSApplication * application = [NSApplication sharedApplication];
        
        [application setDelegate:delegate];
        
        [NSApp run];
        
        [pool drain];
        
        
        
    }
    return 0;
}
